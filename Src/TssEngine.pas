{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Engine Unit                            *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssEngine;

interface

uses
  Windows, Messages, SysUtils, Classes, MMSystem, IniFiles, Math, DateUtils,
  Direct3D8, D3DX8, D3DApp, D3DFont, D3DUtil, DXUtil, DirectInput8, DX8DI,
  fmod, fmodtypes, fmoderrors, fmodpresets, G2Script,

  TssUtils, TssTextures, TssFiles, TssControls, TssObjects, TssMap, TssSky,
  TssCars, TssPhysics, TssAlpha, TssShadows, TssMenus, TssCredits,
  TssLog, TssParticles, TssSurface, TssWeapons, TssLights, TssAnim,
  TssEffects, TssAI, TssConsole, TssScript, TssEditor, TssReplay, TssSounds;

const
  // TssEngine Version Information
  Engine_Version_Name  = 'TssEngine'  ;
  Engine_Version_Major = '2'          ;
  Engine_Version_Minor = '2'          ;
  Engine_Version_Build = '048'        ;
  Engine_Version_Date  = '3.8.2004'   ;

  Default_FOV = 1.04719755; // 1.04719755 rad = 60 Degrees

type
  TEngineMode = (emMenu, emGame, emEdit);
  TTssEngine = class(TPersistent)
    procedure ScriptError(Sender: TObject; const Error: string);
    procedure ScriptOutput(Sender: TObject; const Text: string);
    function ScriptGetData(Sender: TObject; var Name: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean;
    procedure ScriptCompiled(Sender: TObject; const Name: string; const Data: Pointer; const DataLen: integer);
  private
    FMusicName: string;
    FMusicStream: Pointer;
    FMusicChannel: integer;
    procedure SetClockDate(const Value: TDateTime);
    procedure SetClockTime(const Value: TDateTime);
    procedure SetMusicName(const Value: string);
  public
    FObjects: TTssObjectList;
    Textures: TTextureSystem;
    ObjectFile: TTssFilePack;
    MiscFile: TTssFilePack;
    SoundFile: TTssFilePack;
    FScriptFile: TTssFilePack;
    Controls: TTssControls;
    FSky: TTssSky;
    //Hud: TTssHud;
    Camera: TTssCamera;
    GameMap: TTssMap;
    AlphaSystem: TAlphaSystem;
    Shadows: TShadowPainter;
    Logger: TTssLogger;
    Particles: TParticleEngine;
    Surfaces: TSurfaceSystem;
    FLights: TLightSystem;
    FReplay: TTssReplay;
    FAISystem: TAISystem;
    Console: TTssConsole;
    FAnimations: TAnimations;
    FScript: TG2Script;
    FMainWindow: TTssWindow;
    FLinks: TList;
    FTimers: TList;
    FSounds: TTssSounds;

    DynVBTC: IDirect3DVertexBuffer8;
    DynIB: IDirect3DIndexBuffer8;

    FPlayer: TTssPlayer;

    FilePath: string;
    MainWindow: CD3DApplication;

    VirtualEngine: TCustomVirtualEngine;
    Terminated, FPaused: Boolean;

    AmbientLight: DWord;
    IdentityMatrix: TD3DMatrix;
    ScreenMat: TD3DMatrix;
    CameraView, CameraProj: TD3DMatrix;
    Material: TTssMaterial;
    FMusicVol: Single;

    CarColorMap: PColorMap;
    CarColorSize: Cardinal;

    FTestValue: string;
    TickCount: Single;
    PrimCount, CallCount: integer;
    m_pd3dDevice: PDirect3DDevice8;
    Caps: D3DCaps8;
    vp: TD3DViewport8;
    FKeyDown: TKeyDown;

    FTimeSpeed: Single;
    FGameSpeed: Single;
    FUptime: integer;
    FSecondTimer: Single;
    ClockDate, ClockTime: TDateTime;

    constructor Create(FilePath: string; MainWnd: CD3DApplication);
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
    procedure Initialize;
    procedure IncPolyCounter(PrimitiveCount: integer);
    procedure CalculateCamera;
    procedure UpdateCamera;
    procedure SetFiltering(Value: integer);
    
    procedure CollectGroups(AList: TList; Exclude: TTssObject; const X1, Y1, Z1, ARange: Single);

    procedure DrawShadow;

    function Exit: Boolean;
    function GetEngine: TTssEngine;
    //function GetObjects: TObjectArray;
    property KeyDown: TKeyDown read FKeyDown write FKeyDown;
  published
    property Player: TTssPlayer read FPlayer write FPlayer;
    property Engine: TTssEngine read GetEngine;
    property Map: TTssMap read GameMap;
    property Objects: TTssObjectList read FObjects;
    property Sky: TTssSky read FSky;
    property Paused: Boolean read FPaused write FPaused;
    {property CamFloating: Boolean read Camera.Floating write Camera.Floating;
    property CamX: Single read Camera.RPos.X write Camera.RPos.X;
    property CamY: Single read Camera.RPos.Y write Camera.RPos.Y;
    property CamZ: Single read Camera.RPos.Z write Camera.RPos.Z;}
    property Cam: TTssCam read Camera.Cam write Camera.Cam;
    property Cameras: TList read Camera.Cams write Camera.Cams;
    property TestValue: string read FTestValue write FTestValue;
    property TimeSpeed: Single read FTimeSpeed write FTimeSpeed;
    property GameSpeed: Single read FGameSpeed write FGameSpeed;
    property Replay: TTssReplay read FReplay;
    property GameDate: TDateTime read ClockDate write SetClockDate;
    property GameTime: TDateTime read ClockTime write SetClockTime;
    property Uptime: integer read FUptime write FUptime;
    property Path: string read FilePath;
    property Lights: TLightSystem read FLights;
    property MusicName: string read FMusicName write SetMusicName;
    property MusicVolume: Single read FMusicVol write FMusicVol;
    property Script: TG2Script read FScript;
    property MainWnd: TTssWindow read FMainWindow;
    property Animations: TAnimations read FAnimations;
    property Links: TList read FLinks write FLinks;
  end;

var
  Engine: TTssEngine;

procedure CreateTssEngine(FilePath: string; MainWnd: CD3DApplication);
procedure FreeTssEngine;

//procedure IniJutska;

implementation

procedure CreateTssEngine(FilePath: string; MainWnd: CD3DApplication);
begin
 TTssEngine.Create(FilePath, MainWnd);
end;

procedure FreeTssEngine;
begin
 Engine.Free;
 Engine:=nil;
end;

{procedure IniJutska;
var IniFilu: TIniFile;
begin
 IniFilu:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'inijutska.ini');
 Engine.IJ_DefaultCar:=StrToFloat(IniFilu.ReadString('Inijutska','DefaultCar','0'));

 Engine.IJ_AsphaltBumps:=StrToFloat(IniFilu.ReadString('Inijutska','AsphaltBumps','0,0001'));
 Engine.IJ_GrassBumbs:=StrToFloat(IniFilu.ReadString('Inijutska','GrassBumbs','0,0007'));

 Engine.IJ_SteeringSpeed:=StrToFloat(IniFilu.ReadString('Inijutska','SteeringSpeed','0,002857'));

 Engine.IJ_NextGearRPM:=StrToFloat(IniFilu.ReadString('Inijutska','NextGearRPM','5500'));
 Engine.IJ_PrevGearRPM:=StrToFloat(IniFilu.ReadString('Inijutska','PrevGearRPM','2500'));
 Engine.IJ_GearChangeDelay:=StrToFloat(IniFilu.ReadString('Inijutska','GearChangeDelay','300'));

 Engine.IJ_DownForce:=StrToFloat(IniFilu.ReadString('Inijutska','DownForce','75'));

 Engine.IJ_Rotation:=StrToFloat(IniFilu.ReadString('Inijutska','Rotation','0,998999'));
 Engine.IJ_AntiRotate:=StrToFloat(IniFilu.ReadString('Inijutska','AntiRotate','0,0002'));

 Engine.IJ_MaxSteerDiv:=StrToFloat(IniFilu.ReadString('Inijutska','MaxSteerDiv','1,0'));
 Engine.IJ_SteeringSpeedAdjust:=StrToFloat(IniFilu.ReadString('Inijutska','SteeringSpeedAdjust','0,04'));

 Engine.IJ_SuspensionMaxM:=StrToFloat(IniFilu.ReadString('Inijutska','SuspensionMaxM','20'));
 Engine.IJ_SusForce:=StrToFloat(IniFilu.ReadString('Inijutska','SusForce','3000000'));
 Engine.IJ_SusAntiBounce:=StrToFloat(IniFilu.ReadString('Inijutska','SusAntiBounce','1500'));

 Engine.IJ_GripRelation:=StrToFloat(IniFilu.ReadString('Inijutska','GripRelation','1000'));

 Engine.IJ_HandBrakeForce:=StrToFloat(IniFilu.ReadString('Inijutska','HandBrakeForce','1,0'));
 Engine.IJ_HandBrakeAddition:=StrToFloat(IniFilu.ReadString('Inijutska','HandBrakeAddition','4000'));
 Engine.IJ_HandBrakeGripEffect:=StrToFloat(IniFilu.ReadString('Inijutska','HandBrakeGripEffect','0,01'));
 Engine.IJ_HandBrakeGripReturnSpeed:=StrToFloat(IniFilu.ReadString('Inijutska','HandBrakeGripReturnSpeed','8'));

 Engine.IJ_SideGripForce:=StrToFloat(IniFilu.ReadString('Inijutska','SideGripForce','0.30'));
 Engine.IJ_SideGripAddition:=StrToFloat(IniFilu.ReadString('Inijutska','SideGripAddition','750'));
 Engine.IJ_MaxSideGrip:=StrToFloat(IniFilu.ReadString('Inijutska','MaxSideGrip','0,2'));
 Engine.IJ_RearSideGrip:=StrToFloat(IniFilu.ReadString('Inijutska','RearSideGrip','0,95'));
 Engine.IJ_GripReturnSpeed:=StrToFloat(IniFilu.ReadString('Inijutska','GripReturnSpeed','0,5'));

 Engine.IJ_EngineMax:=StrToFloat(IniFilu.ReadString('Inijutska','EngineMax','4000'));
 Engine.IJ_EngineForce:=StrToFloat(IniFilu.ReadString('Inijutska','EngineForce','0,0095'));
 Engine.IJ_PeakRPM:=StrToFloat(IniFilu.ReadString('Inijutska','PeakRPM','4500'));

 Engine.IJ_AccForce:=StrToFloat(IniFilu.ReadString('Inijutska','AccForce','1,0'));
 Engine.IJ_AccAddition:=StrToFloat(IniFilu.ReadString('Inijutska','AccAddition','10000'));
 Engine.IJ_AccGripOver:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripOver','0,25'));
 Engine.IJ_BurnOutGripEffect:=StrToFloat(IniFilu.ReadString('Inijutska','BurnOutGripEffect','165'));
 Engine.IJ_BurnOutGripSpeedAdjust:=StrToFloat(IniFilu.ReadString('Inijutska','BurnOutGripSpeedAdjust','2'));
 Engine.IJ_AccGripEffectSlip:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripEffectSlip','150'));
 Engine.IJ_AccGripEffectFractionControl:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripEffectFractionControl','70'));
 Engine.IJ_AccGripEffectFractionControlSpeedAdjust:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripEffectFractionControlSpeedAdjust','0,5'));
 Engine.IJ_AccGripEffect:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripEffect','75'));
 Engine.IJ_AccGripEffectSpeedAdjust:=StrToFloat(IniFilu.ReadString('Inijutska','AccGripEffectSpeedAdjust','1'));

 Engine.IJ_BrakeForce:=StrToFloat(IniFilu.ReadString('Inijutska','BrakeForce','20'));

 Engine.IJ_AirGripEffect:=StrToFloat(IniFilu.ReadString('Inijutska','AirGripEffect','200'));
 Engine.IJ_AirResistance:=StrToFloat(IniFilu.ReadString('Inijutska','AirResistance','60'));
 IniFilu.Free;
end;}

constructor TTssEngine.Create(FilePath: string; MainWnd: CD3DApplication);
//var Car: TTssCar;
begin
 inherited Create;
 TssEngine.Engine:=Self;
 Randomize;
 MainWindow:=MainWnd;
 Self.FilePath:=FilePath;
 m_pd3dDevice:=@(MainWindow.m_pd3dDevice);
 Terminated:=False;
 vp.Width:=MainWnd.m_dwCreationWidth;
 vp.Height:=MainWnd.m_dwCreationHeight;

 Logger:=TTssLogger.Create(Options.UseLogging);
 Logger.Log('Engine_Create_Begin');

 ObjectFile:=TTssFilePack.Create(FilePath+'Data\', 'Objects.tss', Options.LockData, Options.PreferPacked);
 MiscFile:=TTssFilePack.Create(FilePath+'Data\', 'Misc.tss', Options.LockData, Options.PreferPacked);
 SoundFile:=TTssFilePack.Create(FilePath+'Data\', 'Sounds.tss', Options.LockData, Options.PreferPacked);
 FScriptFile:=TTssFilePack.Create(FilePath+'Data\', 'Scripts.tss', Options.LockData, Options.PreferPacked);
 Console:=TTssConsole.Create;
 FScript:=TG2Script.Create(nil);
 FScript.OnNeedSource:=ScriptGetData;
 FScript.OnError:=ScriptError;
 FScript.OnOutput:=ScriptOutput;
 FScript.OnCompiled:=ScriptCompiled;
 FScript.SetEvents(ScriptEvents);
 FScript.SetVariable(G2Var(Self), 'engine');
 FMainWindow:=TTssWindow.Create(nil);
 FMainWindow.Width:=1.0;
 FMainWindow.Height:=Engine.vp.Height/Engine.vp.Width;
 Controls:=TTssControls.Create(FilePath+'Controls.ini');
 FAnimations:=TAnimations.Create(FilePath+'Data\', 'Animations.tss');
 Textures:=TTextureSystem.Create(FilePath+'Data\', 'Textures.tss');
 Textures.InitFonts(FilePath+'Data\', 'Fonts.tss');
 FLights:=TLightSystem.Create;
 Surfaces:=TSurfaceSystem.Create;
 GameMap:=TTssMap.Create;
 FSky:=TTssSky.Create;
 //Hud:=TTssHud.Create;
 FAISystem:=TAISystem.Create;
 FObjects:=TTssObjectList.Create(True);
 AlphaSystem:=TAlphaSystem.Create;
 Shadows:=TShadowPainter.Create;
 Particles:=TParticleEngine.Create;
 FReplay:=TTssReplay.Create;
 FLinks:=TList.Create;
 FTimers:=TList.Create;

 VirtualEngine:=Replay;

 CarColorSize:=MiscFile.LoadToMemByName('CarColor.dat', Pointer(CarColorMap)) div 3;

 AmbientLight:=$80808080;
 D3DXMatrixIdentity(IdentityMatrix);

 D3DXMatrixLookAtLH(CameraView, MakeD3DVector(0,2,-5), MakeD3DVector(0,0,0), MakeD3DVector(0,1,0));
 D3DXMatrixPerspectiveFovLH(CameraProj, Default_FOV, 4/3, {1.01}0.33, Map_MaxDistance*Options.VisibleDepth);

 Camera.Cams:=TList.Create;
 Camera.Rot:=IdentityMatrix;
 D3DXQuaternionRotationYawPitchRoll(Camera.XAngle, 0, 0, 0);
 D3DXQuaternionRotationYawPitchRoll(Camera.YAngle, 0, 0, 0);

 FMusicVol:=1.0;

 Material.Name:='None';

 TimeSpeed:=1.0;
 FGameSpeed:=1.0;
 FSecondTimer:=Random(1000);
 //ClockDate:=EncodeDate(1967, 7, 11);
 //ClockTime:=EncodeTime(8, 0, 0, 0);

 D3DXQuaternionRotationYawPitchRoll(Engine.Camera.Orientation, 0, 0, 0);

 FSOUND_SetOutput(FSOUND_OUTPUT_DSOUND);
 FSOUND_SetHWND(MainWnd.m_hWndFocus);
 FSOUND_SetDriver(Options.SoundDriver);
 FSOUND_Init(44100, 32, 0);
 case Options.SpeakerMode of
  0: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_MONO));
  1: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_STEREO));
  2: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_HEADPHONES));
  3: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_SURROUND));
  4: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_QUAD));
  5: FSOUND_SetSpeakerMode(Cardinal(FSOUND_SPEAKERMODE_DOLBYDIGITAL));
 end;
 FSOUND_SetSFXMasterVolume(Options.SoundVolume*256 div 100);
 FSounds:=TTssSounds.Create;

 if Options.EditorMode then begin
  FPlayer:=TTssEditPlayer.Create(nil, True);
  FPlayer.LoadData('Human1.obj');
  FPlayer.Car:=nil;
 end;

 //Console.AddCommand('Exit', Exit);
 FScript.RunCommand(Options.ScriptInit);

 CalculateCamera;

 Logger.Log('Engine_Create_End');
end;

procedure TTssEngine.CalculateCamera;           
begin
 D3DXMatrixPerspectiveFovLH(CameraProj, Default_FOV, 4/3, {1.01}0.33, Map_MaxDistance*Options.VisibleDepth);
 Camera.Vectors1[0]:=MakeD3DVector(-4/3*Tan(Default_FOV/2), 1.0*Tan(Default_FOV/2), 1.0);
 Camera.Vectors1[1]:=MakeD3DVector( 4/3*Tan(Default_FOV/2), 1.0*Tan(Default_FOV/2), 1.0);
 Camera.Vectors1[2]:=MakeD3DVector(-4/3*Tan(Default_FOV/2),-1.0*Tan(Default_FOV/2), 1.0);
 Camera.Vectors1[3]:=MakeD3DVector( 4/3*Tan(Default_FOV/2),-1.0*Tan(Default_FOV/2), 1.0);
end;

procedure TTssEngine.UpdateCamera;
var V2, V3: TD3DXVector3;
begin
 D3DXVec3TransformCoord(Camera.Vectors2[0], Camera.Vectors1[0], Camera.Rot);
 D3DXVec3TransformCoord(Camera.Vectors2[1], Camera.Vectors1[1], Camera.Rot);
 D3DXVec3TransformCoord(Camera.Vectors2[2], Camera.Vectors1[2], Camera.Rot);
 D3DXVec3TransformCoord(Camera.Vectors2[3], Camera.Vectors1[3], Camera.Rot);
 D3DXVec3TransformCoord(V2, MakeD3DVECTOR(0,0,1), Camera.Rot);
 D3DXVec3TransformCoord(V3, MakeD3DVECTOR(0,1,0), Camera.Rot);
 V2.X:=V2.X+Camera.Pos.X;
 V2.Y:=V2.Y+Camera.Pos.Y;
 V2.Z:=V2.Z+Camera.Pos.Z;
 D3DXMatrixLookAtLH(CameraView, Camera.Pos, V2, V3);
 m_pd3dDevice.SetTransform(D3DTS_VIEW, CameraView);
 m_pd3dDevice.SetTransform(D3DTS_PROJECTION, CameraProj);
 D3DXMatrixMultiply(ScreenMat, CameraView, CameraProj);
end;

destructor TTssEngine.Destroy;
var I: integer;
begin
 Logger.Enabled:=Options.UseLogging;
 Logger.Log('Engine_Destroy_Begin');

 FreeMem(CarColorMap);
 MusicName:='';
 for I:=0 to Camera.Cams.Count-1 do
  TTssCam(Camera.Cams.Items[I]).Free;
 for I:=0 to FTimers.Count-1 do
  TObject(FTimers[I]).Free;
 for I:=0 to FLinks.Count-1 do
  TObject(FLinks[I]).Free;
 FSounds.Free;
 FAISystem.Free;
 FTimers.Free;
 FLinks.Free;
 Replay.Free;
 Surfaces.Free;
 GameMap.Free;
 FObjects.Free;
 FAnimations.Free;
 Textures.Free;
 Controls.Free;
 Sky.Free;
 //Hud.Free;
 AlphaSystem.Free;
 Shadows.Free;
 Particles.Free;
 Lights.Free;
 FMainWindow.Free;
 FScript.Free;
 Console.Free;
 ObjectFile.Free;
 MiscFile.Free;
 SoundFile.Free;
 FScriptFile.Free;
 FSOUND_Close();

 Logger.Log('Engine_Destroy_End');
 Logger.Free;

 Terminated:=True;
 inherited Destroy;
end;

procedure TTssEngine.Move(TickCount: Single);
var I: integer;
begin
 //Logger.Log('Engine_Move_Begin');
 Self.TickCount:=Max(0.0, TickCount*FGameSpeed);
 Inc(FUptime, Round(TickCount*10.0));
 try

 Textures.Move(Self.TickCount);
 if Options.UseDynamicSurfaces then Surfaces.Move(Self.TickCount);
 Controls.Move(Self.TickCount);

 if not FPaused then begin

  FSecondTimer:=FSecondTimer+Self.TickCount*0.001;

  ClockTime:=ClockTime+Self.TickCount/1000/60/60/24*FTimeSpeed;
  while ClockTime>=1 do begin
   ClockDate:=ClockDate+1;
   ClockTime:=ClockTime-1;
  end;

  Console.MoveScripts(Self.TickCount);

  VirtualEngine.Move(Self.TickCount);
  if VirtualEngine.Recording then VirtualEngine.RecordMove(Self.TickCount);
  if VirtualEngine.Playing then VirtualEngine.PlayMove(Self.TickCount);

  Sky.Move(Self.TickCount);
  //Hud.Move(Self.TickCount);

  for I:=FLinks.Count-1 downto 0 do
   TTssLink(FLinks[I]).Move(Self.TickCount);

  FAISystem.Move(Self.TickCount);
  for I:=FObjects.Count-1 downto 0 do
   with FObjects.Obj[I] do begin
    if FRemove then Free else if not FDisabled then Move(Self.TickCount) else if FRefCount=0 then Free;
   end;

  Particles.Move(Self.TickCount);
  //Hud.HudAlpha:=255;
 end;

 FMainWindow.Move(Self.TickCount);
 Console.Move(Self.TickCount);

 if Controls.DIKKeyDown(DIK_ESCAPE, -1) then FScript.Event(Integer(seEsc), []);

 D3DXVec3Subtract(Camera.Move, Camera.Pos, Camera.OldPos);
 D3DXVec3Scale(Camera.AMove, Camera.Move, 1/(Self.TickCount*0.001));
 if D3DXVec3LengthSq(Camera.AMove)>40000 then Camera.AMove:=D3DXVector3(0.0, 0.0, 0.0);
 Camera.OldPos:=Camera.Pos;
 if FMusicChannel=-1 then if FSOUND_Stream_GetOpenState(FMusicStream)=0 then begin
  FMusicChannel:=FSOUND_Stream_Play(FSOUND_FREE, FMusicStream);
  FSOUND_SetVolumeAbsolute(FMusicChannel, Round(Options.MusicVolume*255*FMusicVol/100));
 end;
 FSOUND_Update();

 except
  on Exception do
   raise Exception.Create('No nyt se otti ja kaatu. Saatana perkele! (Move)');
 end;

 //Logger.Log('Engine_Move_End');
end;

procedure TTssEngine.Draw;
var I: integer;
    mtrl: TD3DMaterial8;
    Vector: TD3DXVector3;
begin
 Logger.Log('Engine_Draw_Begin');

 //try

 m_pd3dDevice.GetDeviceCaps(Caps);
 m_pd3dDevice.GetViewport(vp);
 Logger.Log('Engine_Draw_SetStates');
 m_pd3dDevice.SetRenderState(D3DRS_DITHERENABLE, Ord(Options.Dithering));
 m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 m_pd3dDevice.SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
 //m_pd3dDevice.SetRenderState(D3DRS_FILLMODE, D3DFILL_WIREFRAME);
 m_pd3dDevice.SetRenderState(D3DRS_SPECULARENABLE, iFalse);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_TEXCOORDINDEX, 0);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);

 //m_pd3dDevice.SetRenderState(D3DRS_COLORWRITEENABLE, D3DCOLORWRITEENABLE_RED);

 m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPMAPLODBIAS, FloatAsInt(Options.MipMapBias));
 if Options.UseMultiTx then m_pd3dDevice.SetTextureStageState(1, D3DTSS_MIPMAPLODBIAS, FloatAsInt(Options.MipMapBias));

 m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 0); 
 m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
 m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_WRAP);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_WRAP);
 //Textures.LastMaterial.NoWrapU:=False;
 //Textures.LastMaterial.NoWrapV:=False;

 m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE, iFalse);
 m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, D3DZB_TRUE);
 m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);

 //m_pd3dDevice.SetRenderState(D3DRS_SPECULARMATERIALSOURCE, D3DMCS_MATERIAL);
 //m_pd3dDevice.SetRenderState(D3DRS_AMBIENTMATERIALSOURCE, D3DMCS_MATERIAL);
 //m_pd3dDevice.SetRenderState(D3DRS_EMISSIVEMATERIALSOURCE, D3DMCS_MATERIAL);

 m_pd3dDevice.SetTransform(D3DTS_WORLD, IdentityMatrix);
 m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);
 //m_pd3dDevice.SetRenderState(D3DRS_SPECULARENABLE, iFalse);
 m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, AmbientLight);

 Logger.Log('Engine_Draw_SetCamera');
 UpdateCamera;

 Logger.Log('Engine_Draw_SetMaterial');
 m_pd3dDevice.GetMaterial(mtrl);
 ZeroMemory(@mtrl, Sizeof(mtrl));
 mtrl.Diffuse.a:=1.0;                               
 mtrl.Diffuse.r:=1.0;
 mtrl.Diffuse.g:=1.0;
 mtrl.Diffuse.b:=1.0;
 mtrl.Ambient.a:=1.0;
 mtrl.Ambient.r:=1.0;
 mtrl.Ambient.g:=1.0;
 mtrl.Ambient.b:=1.0;
 mtrl.Specular:=mtrl.Diffuse;
 m_pd3dDevice.SetMaterial(mtrl);

 if Options.Filtering>=3 then SetFiltering(0)
  else SetFiltering(Max(Options.Filtering, 0));
 if Options.Antialiasing>0 then m_pd3dDevice.SetRenderState(D3DRS_MULTISAMPLEANTIALIAS, iFalse);

 Lights.Draw;

 Logger.Log('Engine_Draw_Init');
 Textures.FastLoad(Material);
 if Options.UseCubeMap then Textures.CubeTx;

 PrimCount:=0;
 CallCount:=0;

 Logger.Log('Engine_Draw_RenderBG');
 Sky.Draw;

 SetFiltering(Options.Filtering);
 if Options.Antialiasing>0 then m_pd3dDevice.SetRenderState(D3DRS_MULTISAMPLEANTIALIAS, iTrue);

 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE4X);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
 Logger.Log('Engine_Draw_RenderMap');
 GameMap.Draw;

 Logger.Log('Engine_Draw_RenderObjects');
 D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 0.0, Options.VisibleDepth*50), Camera.Rot);
 Vector.X:=Vector.X+Camera.Pos.X; Vector.Y:=Vector.Y+Camera.Pos.Y; Vector.Z:=Vector.Z+Camera.Pos.Z;
 if Options.UseStencil then begin
  m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE, iTrue);
  m_pd3dDevice.SetRenderState(D3DRS_STENCILFUNC, D3DCMP_ALWAYS);
  m_pd3dDevice.SetRenderState(D3DRS_STENCILREF, $2);
  m_pd3dDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_REPLACE);
 end;
 for I:=FObjects.Count-1 downto 0 do with FObjects.Obj[I] do if not FDisabled then begin
  FVisible:=D3DXVec3LengthSq(VectorSubtract(APos, Vector))<=Sqr(Options.VisibleDepth*50+Range*0.001);
  if FVisible then Draw;
 end;
 if Options.UseStencil then begin
  m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE, iFalse);
 end;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);

 if Options.UseDynamicSurfaces then begin
  Logger.Log('Engine_Draw_RenderSurfaces');
  Surfaces.Draw;
 end;

 Logger.Log('Engine_Draw_RenderAlpha');
 AlphaSystem.Draw;

 if Options.Filtering>=3 then SetFiltering(0)
  else SetFiltering(Max(Options.Filtering, 0));
 if Options.Antialiasing>0 then m_pd3dDevice.SetRenderState(D3DRS_MULTISAMPLEANTIALIAS, iFalse);
 Particles.Draw;

 m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, AmbientLight);
 m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 1);
 Sky.Draw2;
 m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 0);

 m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFFFF);

 Logger.Log('Engine_Draw_RenderShadows');
 if Options.UseStencil then DrawShadow;

 m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, iFalse);
 m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
 m_pd3dDevice.SetRenderState(D3DRS_FOGENABLE, iFalse);

 Logger.Log('Engine_Draw_RenderHUD');
 //Hud.Draw;

 m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 Logger.Log('Engine_Draw_RenderMenu');
 FMainWindow.Draw;

 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
 Console.Draw;

 //Textures.FastMode:=False;

 {except
  on Exception do
   raise Exception.Create('No nyt se otti ja kaatu. Saatana perkele! (Draw)');
 end;}

 Logger.Log('Engine_Draw_End');
 Logger.Enabled:=False;
end;

procedure TTssEngine.IncPolyCounter(PrimitiveCount: integer);
begin
 Inc(PrimCount, PrimitiveCount);
 Inc(CallCount);
end;

procedure TTssEngine.Initialize;
begin

end;

procedure TTssEngine.DrawShadow;
  procedure DrawList(List: TTssObjectList);
  var I, J: integer;
  begin
   for I:=List.Count-1 downto 0 do
    with List.Obj[I] do if not SharedBuffers then if Sqr(APos.X-Camera.Pos.X)+Sqr(APos.Y-Camera.Pos.Y)+Sqr(APos.Z-Camera.Pos.Z)<Sqr(50) then
    {if (List.Obj[I] is TTssCar) or (List.Obj[I] is TTssTyre) then} with Details[{Low(Details)}0] do begin
     for J:=0 to GroupCount-1 do with TMeshData(MeshData.Items[J]) do if VertexCount>0 then
      Shadows.DrawDirectional(ShadowData, StartVertex, VertexCount, StartIndex, IndexCount, Vertices, Indices, D3DXVector3(-Sky.SunPos.X, -Sky.SunPos.Y, -Sky.SunPos.Z), Matrix);
     DrawList(Children);
    end;
  end;
begin
 {if Options.UseStencil then begin
  m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 0);
  DrawList(FObjects);
  m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE, iFalse);
 end;}
end;

procedure TTssEngine.CollectGroups(AList: TList; Exclude: TTssObject; const X1, Y1, Z1, ARange: Single);
var I, Level: integer;
begin
 AList.Clear;
 GameMap.CollectGroups(AList, X1, Y1, Z1, ARange);
 for I:=0 to FObjects.Count-1 do
  if (FObjects.Obj[I]<>Exclude) and (not FObjects.Obj[I].IgnoreObj) and (not FObjects.Obj[I].FDisabled) then
   with FObjects.Obj[I] do if Sqr(APos.X-X1)+Sqr(APos.Y-Y1)+Sqr(APos.Z-Z1)<=Sqr(ARange+Range*0.001) then begin
    Matrix:=ARot;
    Matrix._41:=Matrix._41+APos.X;
    Matrix._42:=Matrix._42+APos.Y;
    Matrix._43:=Matrix._43+APos.Z;
    case HitStyle of
     hsMeshLow1: Level:=-1;
     hsMeshHigh1: Level:=1;
     else Level:=0;
    end;
    CollDetails:=@Details[Level];
    if HitStyle<>hsBox then begin
     if not D3DXMatrixEqual(CollDetails.PreCalculated, Matrix) then Physics_CalculateVertices(FObjects.Obj[I], Level, nil);
     if CollectGroups(X1, Y1, Z1, ARange, Level) then AList.Add(FObjects.Obj[I]);
    end else begin
     AList.Add(FObjects.Obj[I]);
    end;
   end;
end;

function TTssEngine.Exit: Boolean;
begin
 Terminated:=True;
 Result:=True;
end;

function TTssEngine.GetEngine: TTssEngine;
begin
 Result:=Self;
end;

{function TTssEngine.GetObjects: TObjectArray;
var I: integer;
begin
 Result:=TObjectArray.Create;
 Result.SetSize(FObjects.Count);
 for I:=0 to FObjects.Count-1 do
  Result.Add(FObjects.Obj[I].Model.Name, FObjects.Obj[I]);
end;}

procedure TTssEngine.SetFiltering(Value: integer);
begin
 if (Caps.MaxAnisotropy=0) and (Value>=3) then Value:=0;
 case Value of
  0: begin // Trilinear
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_LINEAR);
   if Options.UseMultiTx then begin
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MIPFILTER, D3DTEXF_LINEAR);
   end;
  end;
  1: begin // Bilinear
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   if Options.UseMultiTx then begin
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   end;
  end;
  2: begin // None
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_POINT);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_POINT);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   if Options.UseMultiTx then begin
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MINFILTER, D3DTEXF_POINT);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MAGFILTER, D3DTEXF_POINT);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   end;
  end;
  3..1000: begin // Anisotropic
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAXANISOTROPY, Min(Round(Power(2, Value-2)), Caps.MaxAnisotropy));
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_ANISOTROPIC);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_ANISOTROPIC);
   m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   if Options.UseMultiTx then begin
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MAXANISOTROPY, Caps.MaxAnisotropy);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MINFILTER, D3DTEXF_ANISOTROPIC);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MAGFILTER, D3DTEXF_ANISOTROPIC);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_MIPFILTER, D3DTEXF_POINT);
   end;
  end;
 end;
end;

procedure TTssEngine.SetClockDate(const Value: TDateTime);
begin
 ClockDate:=Round(Value);
end;

procedure TTssEngine.SetClockTime(const Value: TDateTime);
begin
 ClockTime:=Value;
 while (ClockTime>1) do begin
  ClockDate:=ClockDate+1;
  ClockTime:=ClockTime-1;
 end;
 while (ClockTime<0) do begin
  ClockDate:=ClockDate-1;
  ClockTime:=ClockTime+1;
 end;
end;

procedure TTssEngine.SetMusicName(const Value: string);
begin
 if Value<>FMusicName then begin
  FMusicName:=Value;
  if FMusicStream<>nil then begin
   FSOUND_Stream_Stop(FMusicStream);
   FSOUND_Stream_Close(FMusicStream);
  end;
  FMusicChannel:=-1;
  if Value<>'' then FMusicStream:=FSOUND_Stream_Open(PChar(FilePath+'Music\'+Value), FSOUND_HW2D or FSOUND_LOOP_NORMAL or FSOUND_NONBLOCKING, 0, 0)
   else FMusicStream:=nil;
 end;
end;

procedure TTssEngine.ScriptError(Sender: TObject; const Error: string);
begin
 Console.Add(Error);
 //raise Exception.Create(Error);
end;

function TTssEngine.ScriptGetData(Sender: TObject; var Name: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean;
begin
 DataLen:=FScriptFile.LoadToMemByName(Name+'.tsl', Data);
 FreeData:=True;
 Result:=DataLen>0;
end;

procedure TTssEngine.ScriptOutput(Sender: TObject; const Text: string);
var S: string;
    I: integer;
begin
 S:=Text;
 I:=Pos(#13, S);
 while I>0 do begin
  Console.Add(Copy(S, 1, I-1));
  Delete(S, 1, I);
  I:=Pos(#13, S);
 end;
 Console.Add(S);
end;

procedure TTssEngine.ScriptCompiled(Sender: TObject; const Name: string; const Data: Pointer; const DataLen: integer);
begin
end;

end.
