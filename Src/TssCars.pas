{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Cars and Humans Unit                   *
 *  (C) Aukiogames 2003                    *
(*-----------------------------------------*}

unit TssCars;

interface

uses
  Windows, TssObjects, TssControls, Direct3D8, D3DX8, TssUtils, Math, DirectInput8, TssAlpha,
  TssShadows, SysUtils, TssParticles, TssWeapons, TssMap, TssTextures,
  TssLights, TssScript, G2Script, Classes,  fmod, fmodtypes, fmoderrors, fmodpresets,
  TssAnim;

const
  Car_Max_Humans = 16;
  Car_Max_Tyres = 16;

type
  TTssCam = class(TPersistent)
  private
    FAngle: Single;
    FFloating: Boolean;
    FPos: TD3DXVector3;
    FObj: TTssObject;
  published
    property Floating: Boolean read FFloating write FFloating;
    property X: Single read FPos.X write FPos.X;
    property Y: Single read FPos.Y write FPos.Y;
    property Z: Single read FPos.Z write FPos.Z;
    property Obj: TTssObject read FObj write FObj;
    property Angle: Single read FAngle write FAngle;
  end;

  TTssCamera = record
    //Floating: Boolean;
    Rot: TD3DMatrix;
    Orientation, YAngle, XAngle: TD3DXQuaternion;
    Move, AMove: TD3DXVector3;
    OldPos, Pos{, RPos}: TD3DXVector3;
    //Rads: Double;
    Vectors1, Vectors2: array[0..3] of TD3DXVector3;
    Cam: TTssCam;
    Cams: TList;
  end;
  
  TTssCar = class;
  TTssCarControls = record
    Steering: Single;
    Accelerate: Single;
    Brake: Single;
    HandBrake: Boolean;
    ExitCar: Boolean;
  end;
  TTssHumanControls = record
    WalkZ: Single; // Forward > 0, Backward < 0
    WalkX: Single; // Right > 0, Left < 0
    TurnY: Single; // Right > 0, Left < 0
    TurnX: Single; // Up > 0, Down < 0
  end;

  TTssHuman = class(TTssObject)   // Base class for all humans. Do not create instances of TTssHuman
  private
    FCar: TTssCar;
    procedure SetFightMode(Value: Boolean);
  protected
    procedure SetCar(Value: TTssCar); virtual;
    procedure DataItemLoad(Data: Pointer; Size: Word); override;
    procedure FillBuffers; override;
  public
    CarPos: Byte;
    Controls: TTssHumanControls;
    FFightMode: Boolean;
    Hitting: Boolean;
    ExittingCar: Boolean;
    LookAngle: Single;

    Weapons: TTssObjectList;
    ObjRight, ObjLeft: TTssObject;

    FStandAni: TAnimation;
    FWalkAni: TAnimation;
    FRunAni: TAnimation;
    FJumpAni: TAnimation;

    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    //procedure Draw; override;
    //procedure MakeBuffers; override;
    procedure Crash(const Pos, Impact: TD3DXVector3); override;

    procedure CarCtrl(TickCount: Single; var Ctrl: TTssCarControls); virtual;
  published
    property Car: TTssCar read FCar write SetCar;
    property FightMode: Boolean read FFightMode write SetFightMode;
  end;

  TTssPlayer = class(TTssHuman)
  private
    LookBackKey: Boolean;
  protected
    procedure SetCar(Value: TTssCar); override;
  public
    FLookBack, FWasLookBack: Boolean;
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure CarCtrl(TickCount: Single; var Ctrl: TTssCarControls); override;
    procedure Crash(const Pos, Impact: TD3DXVector3); override;
  published
    property LookBack: Boolean read FLookBack write FLookBack;
  end;

  TTssSteeringWheel = class(TTssObject)
  protected
    procedure ExtraLoad(Data: Pointer; Size: Word); override;
  public
    Axis: TD3DXVector3;
  end;

  TTssTyre = class(TTssObject)
  protected
    procedure SetParent(Value: TTssObject); override;
    procedure ExtraLoad(Data: Pointer; Size: Word); override;
  public
    Grip: array[0..255] of Byte;
    Steer, Accelerate, Brake: Boolean;
    HandBrakeBadGrip, BadGrip: Single;
    OrigY: Single;
    WasPos: TD3DXVector3;
    Rotation, RotPos: Single;
    Smoke: TTyreSmoke;
    Sand: TFlyingSand;

    LastSlide: record
      Pos, PrevPos: TD3DXVector3;
      rC, rD: TD3DXVector2;
      Time, NextRandom: Single;
      VCount, ICount: Word;
      Color: DWord;
      MatType: Byte;
    end;
    MatType: Byte;
    Sliding: Single;
    RubberGroup: TMapGroup;
    OnGround: Boolean;
    SlideChannel: Cardinal;
    SlideVolume: Single;
    PunchChannel: Cardinal;

    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure SetSliding(Value, TickCount: Single);
    function GetGrip(Material: Byte): Single;
  published
    property Steering: Boolean read Steer write Steer;
    property Accelerating: Boolean read Accelerate write Accelerate;
    property Braking: Boolean read Brake write Brake;
  end;

  TTssCar = class(TTssObject)
  private
    FLight: TLight;
    function GetSpeedAddress: Cardinal;
    function GetRPMAddress: Cardinal;
  protected
    procedure ExtraLoad(Data: Pointer; Size: Word); override;
    procedure PointerLoad(const Data: TPointerData); override;
    procedure LightLoad(Data: Pointer); override;
    function ChildLoad(ObjType: Byte; Data: Pointer): Pointer; override;
    function GetColor: TD3DColor; override;
  public
    FHuman_Pos: array[0..Car_Max_Humans-1] of TD3DXVector3;

    FSteering_Speed: Single;
    FSteering_MaxInv: Single;
    FSteering_Adjust: Single;

    FGears_NextRPM: Single;
    FGears_PrevRPM: Single;
    FGears_ChangeDelay: Single;
    FGears_Count: integer;
    FGears_Ratio: array[-2..13] of Single;

    FSuspension_MaxM: Single;
    FSuspension_Strength: Single;
    FSuspension_AntiBounce: Single;

    FEngine_EngineMax: Single;
    FEngine_EngineForce: Single;
    FEngine_PeakRPM: Single;

    FAccelerate_Force: Single;
    FAccelerate_Addition: Single;
    FAccelerate_GripOver: Single;
    FAccelerate_BurnOutGripEffect: Single;
    FAccelerate_BurnOutGripSpeedAdjust: Single;
    FAccelerate_GripEffectSlip: Single;
    FAccelerate_GripEffectFC: Single;
    FAccelerate_GripEffectFCSpeedAdjust: Single;
    FAccelerate_GripEffect: Single;
    FAccelerate_GripEffectSpeedAdjust: Single;

    FBrake_Force: Single;
    FBrake_HBForce: Single;
    FBrake_HBAddition: Single;
    FBrake_HBGripEffect: Single;
    FBrake_HBGripReturnSpeed: Single;

    FGrip_SideForce: Single;
    FGrip_SideAddition: Single;
    FGrip_MaxSide: Single;
    FGrip_RearSide: Single;
    FGrip_ReturnSpeed: Single;
    FGrip_AirEffect: Single;
    FGrip_Relation: Single;

    FMisc_DownForce: Single;
    FMisc_Rotation: Single;
    FMisc_AntiRotate: Single;

    Gear: integer;
    GearDelay: Single;
    GearChanged: Single;
    CarSpeed: Single;
    RPM: Single;
    WasRot: TD3DMatrix;
    Forw: Boolean;
    BackLight0, BackLight1, FrontLight0, FrontLight1, FrontLight2, FrontLight3: TTssLight;

    Controls: TTssCarControls;
    
    EngineChannel: integer;
    TyreChannel: integer;
    
    TyreCount: Byte;
    Humans: array[0..Car_Max_Humans-1] of TTssHuman;
    Tyres: array[0..Car_Max_Tyres-1] of TTssTyre;
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure Draw; override;
  published
    property Steering_Speed: Single read FSteering_Speed write FSteering_Speed;
    property Steering_MaxInv: Single read FSteering_MaxInv write FSteering_MaxInv;
    property Steering_Adjust: Single read FSteering_Adjust write FSteering_Adjust;

    property Gears_NextRPM: Single read FGears_NextRPM write FGears_NextRPM;
    property Gears_PrevRPM: Single read FGears_PrevRPM write FGears_PrevRPM;
    property Gears_ChangeDelay: Single read FGears_ChangeDelay write FGears_ChangeDelay;
    property Gears_Count: integer read FGears_Count write FGears_Count;
    property Gears_RBack1: Single read FGears_Ratio[-1] write FGears_Ratio[-1];
    property Gears_R1: Single read FGears_Ratio[1] write FGears_Ratio[1];
    property Gears_R2: Single read FGears_Ratio[2] write FGears_Ratio[2];
    property Gears_R3: Single read FGears_Ratio[3] write FGears_Ratio[3];
    property Gears_R4: Single read FGears_Ratio[4] write FGears_Ratio[4];
    property Gears_R5: Single read FGears_Ratio[5] write FGears_Ratio[5];
    property Gears_R6: Single read FGears_Ratio[6] write FGears_Ratio[6];
    property Gears_R7: Single read FGears_Ratio[7] write FGears_Ratio[7];
    property Gears_R8: Single read FGears_Ratio[8] write FGears_Ratio[8];

    property Suspension_MaxM: Single read FSuspension_MaxM write FSuspension_MaxM;
    property Suspension_Strength: Single read FSuspension_Strength write FSuspension_Strength;
    property Suspension_AntiBounce: Single read FSuspension_AntiBounce write FSuspension_AntiBounce;

    property Engine_EngineMax: Single read FEngine_EngineMax write FEngine_EngineMax;
    property Engine_EngineForce: Single read FEngine_EngineForce write FEngine_EngineForce;
    property Engine_PeakRPM: Single read FEngine_PeakRPM write FEngine_PeakRPM;

    property Accelerate_Force: Single read FAccelerate_Force write FAccelerate_Force;
    property Accelerate_Addition: Single read FAccelerate_Addition write FAccelerate_Addition;
    property Accelerate_GripOver: Single read FAccelerate_GripOver write FAccelerate_GripOver;
    property Accelerate_BurnOutGripEffect: Single read FAccelerate_BurnOutGripEffect write FAccelerate_BurnOutGripEffect;
    property Accelerate_BurnOutGripSpeedAdjust: Single read FAccelerate_BurnOutGripSpeedAdjust write FAccelerate_BurnOutGripSpeedAdjust;
    property Accelerate_GripEffectSlip: Single read FAccelerate_GripEffectSlip write FAccelerate_GripEffectSlip;
    property Accelerate_GripEffectFC: Single read FAccelerate_GripEffectFC write FAccelerate_GripEffectFC;
    property Accelerate_GripEffectFCSpeedAdjust: Single read FAccelerate_GripEffectFCSpeedAdjust write FAccelerate_GripEffectFCSpeedAdjust;
    property Accelerate_GripEffect: Single read FAccelerate_GripEffect write FAccelerate_GripEffect;
    property Accelerate_GripEffectSpeedAdjust: Single read FAccelerate_GripEffectSpeedAdjust write FAccelerate_GripEffectSpeedAdjust;

    property Brake_Force: Single read FBrake_Force write FBrake_Force;
    property Brake_HBForce: Single read FBrake_HBForce write FBrake_HBForce;
    property Brake_HBAddition: Single read FBrake_HBAddition write FBrake_HBAddition;
    property Brake_HBGripEffect: Single read FBrake_HBGripEffect write FBrake_HBGripEffect;
    property Brake_HBGripReturnSpeed: Single read FBrake_HBGripReturnSpeed write FBrake_HBGripReturnSpeed;

    property Grip_SideForce: Single read FGrip_SideForce write FGrip_SideForce;
    property Grip_SideAddition: Single read FGrip_SideAddition write FGrip_SideAddition;
    property Grip_MaxSide: Single read FGrip_MaxSide write FGrip_MaxSide;
    property Grip_RearSide: Single read FGrip_RearSide write FGrip_RearSide;
    property Grip_ReturnSpeed: Single read FGrip_ReturnSpeed write FGrip_ReturnSpeed;
    property Grip_AirEffect: Single read FGrip_AirEffect write FGrip_AirEffect;
    property Grip_Relation: Single read FGrip_Relation write FGrip_Relation;

    property Misc_DownForce: Single read FMisc_DownForce write FMisc_DownForce;
    property Misc_Rotation: Single read FMisc_Rotation write FMisc_Rotation;
    property Misc_AntiRotate: Single read FMisc_AntiRotate write FMisc_AntiRotate;

    property Light: TLight read FLight write FLight;
    property SpeedAddress: Cardinal read GetSpeedAddress;
    property RPMAddress: Cardinal read GetRPMAddress;
  end;


implementation

uses
  TssEngine, TssPhysics, TssEffects, TssAI;

constructor TTssCar.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 OwnMass:=900;
 TotMass:=900;
 Gear:=1;
 Range:=3000;
 RPM:=2000;
 {Light:=TLight.Create;
 Light.LightType:=D3DLIGHT_SPOT;
 Light.Color:=D3DCOLOR_ARGB(255, 255, 240, 224);
 Light.Enabled:=True;
 Light.Range:=100.0;}
 DrawDistance:=80.0;
 DrawDistanceChild:=80.0;
 EngineChannel:=-1;
 TyreChannel:=-1;
end;

destructor TTssCar.Destroy;
begin
 FSOUND_StopSound(EngineChannel);
 FSOUND_StopSound(TyreChannel);
 //Light.Free;
 inherited;
end;

procedure TTssCar.Move(TickCount: Single);
var NewCtrl: TTssCarControls;
    I, J: integer;
    //M: TD3DXMatrix;
    //V: TD3DXVector3;
    Distance: Single;
begin
 NewCtrl:=Controls;
 if Humans[0]<>nil then with Humans[0] do begin
  CarCtrl(TickCount, NewCtrl);
  if NewCtrl.ExitCar then begin
   ExittingCar:=True;
   //Car:=nil;
   //RPos:=D3DXVector3(Self.RPos.X-1.0, Self.RPos.Y+1.0, Self.RPos.Z);
  end;
 end;
 if Stopped then
  if (NewCtrl.Steering<>Controls.Steering) or (NewCtrl.Accelerate<>Controls.Accelerate) or (NewCtrl.Brake<>Controls.Brake) or (NewCtrl.HandBrake<>Controls.HandBrake) or (NewCtrl.ExitCar<>Controls.ExitCar) then begin
   Stopped:=False;
   LastMove:=0;
  end;
 Controls:=NewCtrl;
 {for I:=0 to Children.Count-1 do
  if Children.Obj[I].Model.ObjType=4 then with TTssSteeringWheel(Children.Obj[I]) do begin
   D3DXMatrixRotationAxis(M, Axis, Controls.Steering);
   D3DXMatrixMultiply(RRot, M, OrigRot);
  end;}
 inherited;
 {Light.Pos:=D3DXVector3(APos.X, APos.Y+1.0, APos.Z);
 D3DXVec3TransformCoord(V, D3DXVector3(0.0, -0.05, 1.0), ARot);
 Light.Dir:=V;
 Light.Enabled:=Abs(Engine.GameTime-0.5)>0.25;}
 Matrix:=ARot;
 Matrix._41:=APos.X; Matrix._42:=APos.Y; Matrix._43:=APos.Z;
 J:=0;
 for I:=0 to TyreCount-1 do
  if Tyres[I]<>nil then begin
   Tyres[I].SetSliding(Tyres[I].Sliding, TickCount);
   Inc(J, Ord(Tyres[I].OnGround));
  end;
 Distance:=D3DXVec3LengthSq(VectorSubtract(APos, Engine.Player.APos));
 if Distance<256.0 then begin
  if EngineChannel=-1 then begin
   if Random(2)=0 then EngineChannel:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Eng1, nil, True)
    else EngineChannel:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Eng2, nil, True);
   TyreChannel:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Tyre, nil, True);
  end;
  FSOUND_3D_SetAttributes(EngineChannel, @APos, @PosMove);
  FSOUND_SetFrequency(EngineChannel, Round(RPM*15));
  FSOUND_SetVolume(EngineChannel, Min(255, Round(100+Ord(Controls.Accelerate>Controls.Brake)*50+0.4*Sqrt(RPM))));
  FSOUND_SetPaused(EngineChannel, False);
  FSOUND_3D_SetAttributes(TyreChannel, @APos, @PosMove);
  FSOUND_SetFrequency(TyreChannel, Round(Sqrt(CarSpeed)*2000));
  FSOUND_SetVolume(TyreChannel, Round(Sqrt(Sqrt(CarSpeed*(J+1)/(TyreCount+1)))*75.0));
  FSOUND_SetPaused(TyreChannel, False);
 end else if EngineChannel>-1 then begin
  FSOUND_StopSound(EngineChannel);
  EngineChannel:=-1;
  FSOUND_StopSound(TyreChannel);
  TyreChannel:=-1;
 end;
end;

procedure TTssCar.Draw;
var Vector: TD3DXVector3;
begin
 //if Light.Enabled then begin
 // Light.Enabled:=False;
  inherited;
 // Light.Enabled:=True;
 //end else inherited;
 if BackLight0.Enabled then begin
  D3DXVec3TransformCoord(Vector, BackLight0.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.2+Max(0.0, -Engine.Sky.SunPos.Y*0.25)+Ord(Controls.Brake>0)*0.15, Vector.X, Vector.Y, Vector.Z, BackLight0.Color), 2);
 end;
 if BackLight1.Enabled then begin
  D3DXVec3TransformCoord(Vector, BackLight1.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.2+Max(0.0, -Engine.Sky.SunPos.Y*0.25)+Ord(Controls.Brake>0)*0.15, Vector.X, Vector.Y, Vector.Z, BackLight1.Color), 2);
 end;

 if FrontLight0.Enabled then begin
  D3DXVec3TransformCoord(Vector, FrontLight0.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.4+Max(0.0, -Engine.Sky.SunPos.Y*0.25), Vector.X, Vector.Y, Vector.Z, FrontLight0.Color), 2);
 end;
 if FrontLight1.Enabled then begin
  D3DXVec3TransformCoord(Vector, FrontLight1.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.4+Max(0.0, -Engine.Sky.SunPos.Y*0.25), Vector.X, Vector.Y, Vector.Z, FrontLight1.Color), 2);
 end;
 if FrontLight2.Enabled then begin
  D3DXVec3TransformCoord(Vector, FrontLight2.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.4+Max(0.0, -Engine.Sky.SunPos.Y*0.25), Vector.X, Vector.Y, Vector.Z, FrontLight2.Color), 2);
 end;
 if FrontLight3.Enabled then begin
  D3DXVec3TransformCoord(Vector, FrontLight3.Pos, Matrix);
  Engine.AlphaSystem.NewAlpha(AlphaData2(0.4+Max(0.0, -Engine.Sky.SunPos.Y*0.25), Vector.X, Vector.Y, Vector.Z, FrontLight3.Color), 2);
 end;
end;

procedure TTssCar.ExtraLoad(Data: Pointer; Size: Word);
begin
 CopyMemory(@FHuman_Pos, Data, Size);
end;

function TTssCar.ChildLoad(ObjType: Byte; Data: Pointer): Pointer;
begin     
 case ObjType of
  1: begin
   Tyres[TyreCount]:=TTssTyre.Create(Self, True);
   Result:=Tyres[TyreCount].LoadFromBuffer(Data, True);
   Tyres[TyreCount].RPos.Y:=Tyres[TyreCount].RPos.Y-Sqrt(OwnMass*0.001)*0.1;
   Tyres[TyreCount].OrigY:=Tyres[TyreCount].RPos.Y;
   Inc(TyreCount);
  end;
  4: begin
   Result:=TTssSteeringWheel.Create(Self, True).LoadFromBuffer(Data);
  end;
  else Result:=inherited ChildLoad(ObjType, Data);
 end;
end;

procedure TTssCar.PointerLoad(const Data: TPointerData);
begin
 if Pos('Ty', Data.Name)>0 then begin
  Tyres[TyreCount]:=TTssTyre.Create(Self, True);
  LoadPointerObj(Tyres[TyreCount], Data);
  Tyres[TyreCount].OrigY:=Tyres[TyreCount].RPos.Y;
  if Data.Name[Length(Data.Name)]='S' then begin
   Tyres[TyreCount].Steer:=True;
   Tyres[TyreCount].Brake:=True;
   //Tyres[TyreCount].Accelerate:=True;
  end else begin
   Tyres[TyreCount].Accelerate:=True;
   Tyres[TyreCount].Brake:=True;
  end;
  Inc(TyreCount);
 end else inherited;
end;

procedure TTssCar.LightLoad(Data: Pointer);
var Name: string[10];
    Light: ^TTssLight;
begin
 CopyMemory(@Name, Data, 11);
 Inc(Integer(Data), 11);
 Light:=nil;
 if Name='Back01' then Light:=@BackLight0 else if Name='Back02' then Light:=@BackLight1
  else if Name='Front01' then Light:=@FrontLight0 else if Name='Front02' then Light:=@FrontLight1
   else if Name='Front03' then Light:=@FrontLight2 else if Name='Front04' then Light:=@FrontLight3;
 Light.Enabled:=True;
 CopyMemory(@(Light.Pos), Data, 12);
 Inc(Integer(Data), 12);
 CopyMemory(@(Light.Color), Data, 4);
end;

constructor TTssTyre.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 FParent:=AParent;
 HitTo:=False;
 Manual:=True;
 OwnMass:=20;
 BreakStrength:=40.0;
 SlideChannel:=$FFFFFFFF;
 PunchChannel:=$FFFFFFFF;
end;

destructor TTssTyre.Destroy;
begin
 if PunchChannel<>$FFFFFFFF then FSOUND_StopSound(PunchChannel);
 if SlideChannel<>$FFFFFFFF then FSOUND_StopSound(SlideChannel);
 if Smoke<>nil then Smoke.Free;
 if Sand<>nil then Sand.Free;
 inherited;
end;


procedure TTssTyre.SetParent(Value: TTssObject);
var I: integer;                                                 
begin
 if Parent<>nil then if Parent is TTssCar then begin
  for I:=0 to TTssCar(Parent).TyreCount-1 do
   if TTssCar(Parent).Tyres[I]=Self then TTssCar(Parent).Tyres[I]:=nil;
  if PunchChannel<>$FFFFFFFF then FSOUND_StopSound(PunchChannel);
  if SlideChannel<>$FFFFFFFF then FSOUND_StopSound(SlideChannel);
  SlideChannel:=$FFFFFFFF;
  PunchChannel:=$FFFFFFFF; 
 end;  
 inherited;
 if Parent<>nil then if Parent is TTssCar then
  for I:=0 to High(TTssCar(Parent).Tyres) do
   if TTssCar(Parent).Tyres[I]=nil then begin
    TTssCar(Parent).Tyres[I]:=Self;
    if TTssCar(Parent).TyreCount<=I then TTssCar(Parent).TyreCount:=I+1;
    Break;
   end;
end;

procedure TTssTyre.Move(TickCount: Single);
var Distance: Single;
begin
 inherited;
 if Parent=nil then Exit;
 Distance:=D3DXVec3LengthSq(VectorSubtract(APos, Engine.Player.APos));
 if Parent<>nil then if (PunchChannel=$FFFFFFFF) and (Distance<2500) and (D3DXVec3LengthSq(Force)>Sqr(TopObj.Mass*TopObj.Gravitation)) then begin
  PunchChannel:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Punch, nil, False);
 end;
 if PunchChannel<$FFFFFFFF then
  if FSOUND_IsPlaying(PunchChannel) then begin
   FSOUND_3D_SetAttributes(PunchChannel, @APos, @TopObj.PosMove);
   FSOUND_SetVolume(PunchChannel, Round(Sqrt(D3DXVec3Length(Force)/TopObj.Mass*TopObj.Gravitation)*12));
  end else PunchChannel:=$FFFFFFFF;
end;

procedure TTssTyre.ExtraLoad(Data: Pointer; Size: Word);
var I: integer;
begin
 Brake:=True;
 Steer:=Boolean(Data^);
 Inc(Integer(Data));
 Accelerate:=Boolean(Data^);
 Inc(Integer(Data));
 Inc(Integer(Data), 2);
 for I:=0 to 255 do begin
  Grip[I]:=Byte(Data^);
  Inc(Integer(Data));
 end;
 Grip[2]:=Grip[3];
end;

function TTssTyre.GetGrip(Material: Byte): Single;
begin
 Result:=Grip[Material]*(1-Max(0, (Engine.Sky.RainAmount-128))*0.002);
end;

procedure TTssTyre.SetSliding(Value, TickCount: Single);
var CurPos: TD3DXVector3;
    CurColor: DWord;
    NewGroup: Boolean;
    temp1, temp2: TD3DXVector2;
    List: TList;
    I, J, X, Z: integer;
    Distance: Single;
begin
 if Value<0.05 then Value:=0.0;
 if Parent<>nil then if (TTssCar(Parent).CarSpeed<0.1) then Value:=0.0;
 Distance:=D3DXVec3LengthSq(VectorSubtract(APos, Engine.Player.APos));
 if ((Value=0.0) or (Distance>256.0) or (MatType=MATTYPE_SAND) or (MatType=MATTYPE_GRASS)) and (SlideChannel<>$FFFFFFFF) then begin
  FSOUND_StopSound(SlideChannel);
  SlideChannel:=$FFFFFFFF;
  SlideVolume:=0.0;
 end else if (Value>0.0) and (SlideChannel=$FFFFFFFF) and (Parent<>nil) and (Distance<=2500.0) and (MatType<>MATTYPE_SAND) and (MatType<>MATTYPE_GRASS) then begin
  SlideChannel:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Slide, nil, False);
  SlideVolume:=0.0;
 end;
 if (Value>0.0) or (SlideVolume>0.01) and (Parent<>nil) and (MatType<>MATTYPE_SAND) and (MatType<>MATTYPE_GRASS) then begin
  SlideVolume:=SlideVolume*0.9+0.1;
  FSOUND_3D_SetAttributes(SlideChannel, @APos, @Parent.PosMove);
  FSOUND_SetFrequency(SlideChannel, Round(Sqrt(TTssCar(Parent).CarSpeed+BadGrip*0.1)*1000+4000));
  FSOUND_SetVolume(SlideChannel, Round(Sqrt(Value)*SlideVolume*200.0));
 end;
 
 NewGroup:=False;
 if (RubberGroup=nil) and (Value>0.0) then begin
  RubberGroup:=TMapGroup.Create;
  if (MatType=MATTYPE_SAND) or (MatType=MATTYPE_GRASS) then RubberGroup.Material.Name:='SandLn1'
   else RubberGroup.Material.Name:='RubberLn1';
  RubberGroup.Material.MatType:=MATTYPE_NONEUP;
  RubberGroup.Material.Opacity:=98;
  RubberGroup.MaxDistance:=50;
  RubberGroup.DynamicBuffers:=True;
  RubberGroup.NeedVertexColor:=True;
  Engine.GameMap.Groups.Add(RubberGroup);
  if LastSlide.Color shr 24=0 then begin
   LastSlide.Time:=0.0;
   LastSlide.rC.X:=-1;
   LastSlide.Pos:=D3DXVector3(0.0, 0.0, 0.0);
   LastSlide.PrevPos:=LastSlide.Pos;
   if (MatType<>MATTYPE_SAND) and (MatType<>MATTYPE_GRASS) then LastSlide.NextRandom:=(Random(1000)+1)*0.001
    else LastSlide.NextRandom:=Random(1000)*0.00025+0.75;
   LastSlide.MatType:=MatType;
   NewGroup:=True;
   Value:=0.0;
  end;
  LastSlide.VCount:=0;
  LastSlide.ICount:=0;
 end;
 Value:=Min(1.0, Value*LastSlide.NextRandom);
 if RubberGroup<>nil then begin
  if ((LastSlide.MatType=MATTYPE_SAND) or (LastSlide.MatType=MATTYPE_GRASS))<>((MatType=MATTYPE_SAND) or (MatType=MATTYPE_GRASS)) then Value:=0.0;
  D3DXVec3TransformCoord(CurPos, D3DXVector3(RPos.X, RPos.Y+Min(MinPos.X, Min(MinPos.Y, MinPos.Z)), RPos.Z), Parent.Matrix);
  CurColor:=D3DCOLOR_ARGB(Round(Value*255), 255, 255, 255);
  LastSlide.Time:=LastSlide.Time+TickCount*0.001;
  RubberGroup.VertexCount:=LastSlide.VCount;
  RubberGroup.IndexCount:=LastSlide.ICount;
  Distance:=D3DXVec2Length(D3DXVector2(LastSlide.Pos.X-CurPos.X, LastSlide.Pos.Z-CurPos.Z));
  D3DXVec2Normalize(temp1, D3DXVector2(LastSlide.Pos.X-CurPos.X, LastSlide.Pos.Z-CurPos.Z));
  D3DXVec2Normalize(temp2, D3DXVector2(LastSlide.PrevPos.X-LastSlide.Pos.X, LastSlide.PrevPos.Z-LastSlide.Pos.Z));
  if (((LastSlide.Time>=0.5) or (D3DXVec2Dot(temp1, temp2)<0.99+Min(0.0098, Distance*0.003))) and (Distance>0.2)) or NewGroup then begin
   LastSlide.Time:=0.0;
   if (not NewGroup) and (RubberGroup.VertexCount<=200) then begin
    PaintTyreRect(RubberGroup, TopObj, LastSlide.Pos, CurPos, Abs(Min(MaxPos.X-MinPos.X, Min(MaxPos.Y-MinPos.Y, MaxPos.Z-MinPos.Z))*0.5)+Ord((LastSlide.MatType=MATTYPE_SAND) or (LastSlide.MatType=MATTYPE_GRASS))*0.05, LastSlide.Color, CurColor, LastSlide.rC, LastSlide.rD);
    LastSlide.VCount:=RubberGroup.VertexCount;
    LastSlide.ICount:=RubberGroup.IndexCount;
   end;
   LastSlide.PrevPos:=LastSlide.Pos;
   LastSlide.Pos:=CurPos;
   LastSlide.Color:=CurColor;
   if (LastSlide.MatType<>MATTYPE_SAND) and (LastSlide.MatType<>MATTYPE_GRASS) then LastSlide.NextRandom:=(Random(500)+500)*0.001
    else LastSlide.NextRandom:=Random(1000)*0.00025+0.75;
   if ((Value=0.0) or (RubberGroup.VertexCount>=100)) and (not NewGroup) then begin
    if RubberGroup.VertexCount=0 then begin
     for X:=Max(0, Trunc(RubberGroup.MinPos.X/64)-1) to Min(255, Trunc(RubberGroup.MaxPos.X/64)+1) do
      for Z:=Max(0, Trunc(RubberGroup.MinPos.Z/64)-1) to Min(255, Trunc(RubberGroup.MaxPos.Z/64)+1) do begin
       J:=Engine.GameMap.Tiles[X,Z].IndexOf(RubberGroup);
       if J>=0 then Engine.GameMap.Tiles[X,Z].Delete(J);
      end;
     Engine.GameMap.Groups.Remove(RubberGroup);
     RubberGroup.Free;
    end else begin
     RubberGroup.Material.MatType:=MATTYPE_NONE;
     List:=TList.Create;
     Engine.GameMap.CollectItems(List, CurPos.X-16, CurPos.Z-16, CurPos.X+16, CurPos.Z+16);
     for I:=0 to List.Count-1 do
      if List.Items[I]<>RubberGroup then if TMapItem(List.Items[I]).IType=0 then
       with TMapGroup(List.Items[I]) do
        if (Material.Name=RubberGroup.Material.Name) and (Material.MatType=MATTYPE_NONE) and (VertexCount<1024) then begin
         ReAllocMem(Vertices, (VertexCount+RubberGroup.VertexCount)*SizeOf(TMapDataVertex));
         ReAllocMem(Indices, (IndexCount+RubberGroup.IndexCount)*SizeOf(TIndex));
         Bits.Count:=(IndexCount+RubberGroup.IndexCount) div 3;
         CopyMemory(@(Vertices[VertexCount]), @(RubberGroup.Vertices[0]), RubberGroup.VertexCount*SizeOf(TMapDataVertex));
         for J:=0 to RubberGroup.IndexCount-1 do
          Indices[IndexCount+J]:=RubberGroup.Indices[J]+VertexCount;
         Inc(VertexCount, RubberGroup.VertexCount);
         Inc(IndexCount, RubberGroup.IndexCount);
         if VertexCount>=1024 then DynamicBuffers:=False;
         MinPos.X:=Min(MinPos.X, RubberGroup.MinPos.X); MaxPos.X:=Max(MaxPos.X, RubberGroup.MaxPos.X);
         MinPos.Y:=Min(MinPos.Y, RubberGroup.MinPos.Y); MaxPos.Y:=Max(MaxPos.Y, RubberGroup.MaxPos.Y);
         MinPos.Z:=Min(MinPos.Z, RubberGroup.MinPos.Z); MaxPos.Z:=Max(MaxPos.Z, RubberGroup.MaxPos.Z);
         VB:=nil;
         IB:=nil;
         for X:=Max(0, Trunc(RubberGroup.MinPos.X/64)-1) to Min(255, Trunc(RubberGroup.MaxPos.X/64)+1) do
          for Z:=Max(0, Trunc(RubberGroup.MinPos.Z/64)-1) to Min(255, Trunc(RubberGroup.MaxPos.Z/64)+1) do begin
           J:=Engine.GameMap.Tiles[X,Z].IndexOf(RubberGroup);
           if J>=0 then
            if Engine.GameMap.Tiles[X,Z].IndexOf(List.Items[I])=-1 then Engine.GameMap.Tiles[X,Z].List[J]:=List.Items[I]
             else Engine.GameMap.Tiles[X,Z].Delete(J);
          end;
         Engine.GameMap.Groups.Remove(RubberGroup);
         RubberGroup.Free;
         Break;
        end;
     List.Free;
    end;
    RubberGroup:=nil;
   end;
  end else if (not NewGroup) and (RubberGroup.VertexCount<=200) then begin
   temp1:=LastSlide.rC;
   temp2:=LastSlide.rD;
   PaintTyreRect(RubberGroup, TopObj, LastSlide.Pos, CurPos, Abs(Min(MaxPos.X-MinPos.X, Min(MaxPos.Y-MinPos.Y, MaxPos.Z-MinPos.Z))*0.5)+Ord((LastSlide.MatType=MATTYPE_SAND) or (LastSlide.MatType=MATTYPE_GRASS))*0.05, LastSlide.Color, CurColor, temp1, temp2);
  end;
 end else LastSlide.Color:=D3DCOLOR_ARGB(0, 255, 255, 255);
end;


constructor TTssHuman.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 LoadData('human_collision.obj');
 OwnMass:=80;
 TotMass:=80;
 Range:=1000;
 Manual:=True;
 Weapons:=TTssObjectList.Create(True);
 DrawDistanceChild:=0.0;
 BreakStrength:=10000.0;
 {Weapons.Add(TTssPistol.Create(Self, True));
 Weapons.Obj[0].DrawNeedsConfirmation:=True;
 Weapons.Obj[0].LoadData('TestGun.obj');
 ObjRight:=Weapons.Obj[0];}
end;

destructor TTssHuman.Destroy;
begin
 Weapons.Free;
 inherited;
end;

procedure TTssHuman.Move(TickCount: Single);
begin
 //if not FVisible then Exit;
 if Car=nil then begin
  //Stopped:=False;
  //LookAngle:=Max(-g_PI_DIV_2*0.7, Min(g_PI_DIV_2*0.7, LookAngle+Controls.TurnX*5));
 end else begin
  //LookAngle:=LookAngle*Power(0.99, TickCount);
  if ExittingCar then begin
   //RPos:=D3DXVector3(Car.RPos.X-2.0, Car.RPos.Y+1.0, Car.RPos.Z);
   ExittingCar:=False;
   with Car do begin
    Self.Car:=nil;
    D3DXVec3TransformCoord(Self.RPos, D3DXVector3(MaxPos.X-Self.MinPos.X+0.1, 0.5, 0.0), Matrix);
   end;
  end;
 end;
 //if D3DXVec3LengthSq(VectorSubtract(TopObj.RPos, Engine.Camera.Pos))<Sqr(DrawDistance*1.1) then
  inherited;
end;

{procedure TTssHuman.Draw;
var I: integer;
    //M: TD3DMatrix;
begin
 for I:=0 to Children.Count-1 do
  if Copy(Children.Obj[I].Name, 1, 4)='+Box' then begin
   //D3DXVec3TransformCoord(Children.Obj[I].RPos, Children.Obj[I].OrigPos, AnimData.Skeleton[StrToIntDef(Copy(Children.Obj[I].Name, 5, 2), 0)].Transform);
   //D3DXMatrixMultiply(Children.Obj[I].RRot, Children.Obj[I].OrigRot, AnimData.Skeleton[StrToIntDef(Copy(Children.Obj[I].Name, 8, 2), 0)].Orientation);
  end;
 inherited;
end;}

procedure TTssHuman.DataItemLoad(Data: Pointer; Size: Word);
begin

end;

{procedure TTssHuman.MakeBuffers;
var N: integer;
begin
 FreeBuffers;
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
   Engine.m_pd3dDevice.CreateVertexBuffer(VertexCount*SizeOf(T3DVertex2TxColor), D3DUSAGE_WRITEONLY, D3DFVF_TSSVERTEX2TXCOLOR, D3DPOOL_DEFAULT, VB);
   Engine.m_pd3dDevice.CreateIndexBuffer(IndexCount*SizeOf(TIndex), D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_DEFAULT, IB);
 end;
 FillBuffers;
end;}

procedure TTssHuman.SetCar(Value: TTssCar);
var I: integer;
begin
 //if Value<>FCar then begin
  if FCar<>nil then begin
   if FCar.Humans[0]=Self then begin
    FCar.Controls.Accelerate:=0.0;
    FCar.Controls.Brake:=0.0;
   end;
   for I:=0 to Car_Max_Humans-1 do
    if FCar.Humans[I]=Self then FCar.Humans[I]:=nil;
   Engine.Script.Event(Integer(seCarExit), [G2Var(Self)]);
  end;
  FCar:=Value;
  Parent:=Value;
  if FCar<>nil then begin
   for I:=0 to Car_Max_Humans-1 do
    if (FCar.Humans[I]=nil) or (FCar.Humans[I]=Self) then begin FCar.Humans[I]:=Self; Break; end;
   FightMode:=False;
   RPos:=D3DXVector3(0, 0, 0);//FCar.FHuman_Pos[I];//MakeD3DVector(-0.35, -0.05, -0.1);
   RRot:=Engine.IdentityMatrix;
   PosMove:=D3DXVector3(0, 0, 0);
   RotMove:=D3DXVector3(0, 0, 0);
   Engine.Script.Event(Integer(seCarEnter), [G2Var(Self)]);
  end else begin
  end;
  //Engine.Console.ScriptEvent('OnCar', True, [TGVObject.Create(False, False, Self)]);
 //end;
end;

procedure TTssHuman.SetFightMode(Value: Boolean);
begin
 if FFightMode<>Value then begin

  FFightMode:=Value;
 end;
end;

procedure TTssHuman.CarCtrl(TickCount: Single; var Ctrl: TTssCarControls);
begin
 // used only in descendant classes
end;


constructor TTssPlayer.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 //Engine.Console.AddCommand('Restore', Restore);
 //Engine.Console.AddCommand('Say', Say);
 hitStyle:=hsMeshLow1;
 FNoRot:=True;
 OwnMass:=15.0;
 Gravitation:=20.0;
 FStandAni:=Engine.Animations.GetAnim('chr_player_stand.ani');
 FWalkAni:=Engine.Animations.GetAnim('chr_player_walk.ani');
 FRunAni:=Engine.Animations.GetAnim('chr_player_run.ani');
 FJumpAni:=Engine.Animations.GetAnim('chr_player_jump.ani');
end;

destructor TTssPlayer.Destroy;
begin
 //Engine.Console.RemoveCommand('Restore');
 //Engine.Console.RemoveCommand('Say');
 inherited;
end;

procedure TTssPlayer.SetCar(Value: TTssCar);
begin
 //if Value=nil then Engine.Camera.Cam.FPos:=D3DXVector3(0.0, 1.0, -2.5)
 // else Engine.Camera.Cam.FPos:=D3DXVector3(0.0, Value.MaxPos.Y*1.5+0.8, Value.MinPos.Z-Value.MaxPos.Y*3-2.2);
 inherited;
end;

procedure TTssPlayer.Move(TickCount: Single);
var Vector, Vector2,{ Vector3,} NewPos: TD3DXVector3;
    Temp, Temp2, Temp3: Single;
    TObj: TTssObject;
    I, J: integer;
    OldQ, TargetQ: TD3DXQuaternion;
    M1{, M2}: TD3DXMatrix;
    List: TList;
begin
 if Car=nil then begin
  Controls.WalkZ:=Ord(Engine.Controls.GameKeyDown(keyWalkForward, Key_NoWait))-0.5*Ord(Engine.Controls.GameKeyDown(keyWalkBackward, Key_NoWait));
  //Controls.WalkX:=0.5*Ord(Engine.Controls.GameKeyDown(keyWalkRight, Key_NoWait))-0.5*Ord(Engine.Controls.GameKeyDown(keyWalkLeft, Key_NoWait));
  //Controls.TurnY:=Engine.Controls.MouseMoveX;
  //Controls.TurnX:=(1-2*Ord(Options.InvertMouse))*Engine.Controls.MouseMoveY;
  Controls.TurnY:=(0.0007*Ord(Engine.Controls.GameKeyDown(keyWalkRight, Key_NoWait))-0.0007*Ord(Engine.Controls.GameKeyDown(keyWalkLeft, Key_NoWait)))*TickCount;
  if Engine.Controls.MouseRightClicked>0 then if (not FightMode) or (not Hitting) then FightMode:=not FightMode;
  if FightMode and (not Hitting) then if Engine.Controls.MouseLeftClicked>0 then
   if ObjRight=nil then begin
    Hitting:=True;
   end else if ObjRight is TTssWeapon then begin
    Hitting:=True;
    TTssWeapon(ObjRight).Fire;
   end;
  if Engine.Controls.GameKeyDown(keyDoorOpen, Key_WaitForever) then begin
   Temp2:=3.0;
   for I:=0 to Engine.FObjects.Count-1 do
    if Engine.FObjects.Obj[I] is TTssCar then if TTssCar(Engine.FObjects.Obj[I]).CarSpeed<5.0 then begin
     D3DXVec3TransformCoord(Vector, D3DXVector3(MaxPos.X-Self.MinPos.X+0.1, 0.5, 0.0), Engine.FObjects.Obj[I].Matrix);
     if D3DXVec3LengthSq(VectorSubtract(Vector, RPos))<Temp2 then begin
      Temp2:=D3DXVec3LengthSq(VectorSubtract(Vector, RPos));
      FCar:=TTssCar(Engine.FObjects.Obj[I]);
     end;
     D3DXVec3TransformCoord(Vector, D3DXVector3(MinPos.X-Self.MaxPos.X-0.1, 0.5, 0.0), Engine.FObjects.Obj[I].Matrix);
     if D3DXVec3LengthSq(VectorSubtract(Vector, RPos))<Temp2 then begin
      Temp2:=D3DXVec3LengthSq(VectorSubtract(Vector, RPos));
      FCar:=TTssCar(Engine.FObjects.Obj[I]);
     end;
    end;
   if FCar<>nil then begin
    if FCar.Humans[0]<>nil then with FCar.Humans[0] do begin
     if FCar.Humans[0] is TTssAI then TTssAI(FCar.Humans[0]).FUnTouched:=False;
     Car:=nil;
     D3DXVec3TransformCoord(RPos, D3DXVector3(Self.FCar.MaxPos.X-MinPos.X+0.1, 0.5, 0.0), Self.FCar.Matrix);
     D3DXVec3TransformCoord(Vector, D3DXVector3(-3.5, 0.0, 0.0), Self.FCar.RRot);
     Crash(RPos, Vector);
    end;
    SetCar(FCar);
   end;
  end;
 end;
 //if (Car=nil) and FightMode and (not LookBack) then Engine.Hud.AimVisibility:=Min(1.0, Engine.Hud.AimVisibility+TickCount*0.005)
 // else Engine.Hud.AimVisibility:=Max(0.0, Engine.Hud.AimVisibility-TickCount*0.005);
 
 inherited;

 Stopped:=False;
 Manual:=False;

 if LookBackKey<>Engine.Controls.GameKeyDown(keyLookBack, Key_NoWait) then begin
  LookBackKey:=Engine.Controls.GameKeyDown(keyLookBack, Key_NoWait);
  LookBack:=LookBackKey;
 end;
 TObj:=TopObj;

 if Engine.Controls.GameKeyDown(keyChangeCam, Key_WaitForever) then begin
  I:=Engine.Cameras.IndexOf(Engine.Camera.Cam);
  Engine.Camera.Cam:=TTssCam(Engine.Cameras.Items[(I+1) mod Engine.Cameras.Count]);
 end;

 if Engine.Camera.Cam.Floating then begin

   {if LookBack then begin
    M2:=Engine.Camera.Rot;
    D3DXMatrixRotationY(M1, g_PI);
    D3DXMatrixMultiply(Engine.Camera.Rot, M2, M1);
   end;}
   {M2:=Engine.Camera.Rot;
   D3DXMatrixRotationX(M1, g_PI*0.225);
   D3DXMatrixMultiply(Engine.Camera.Rot, M1, M2);}
  //end;
  Temp:=D3DXVec3Length(TObj.RotMove);
  if Temp<2 then D3DXQuaternionRotationYawPitchRoll(TargetQ, GetYAngle(TObj.RRot)+Ord(LookBack)*g_PI, 0.0, 0.0)
   else D3DXQuaternionRotationYawPitchRoll(TargetQ, GetYAngle(Engine.Camera.Rot)+Ord(LookBack)*g_PI, 0.0, 0.0);
  D3DXMatrixRotationQuaternion(M1, TargetQ);
  Temp2:=1.0;//+D3DXVec3Length(Obj.PosMove)*0.02;
  D3DXVec3TransformCoord(Vector, D3DXVector3(Engine.Cam.X, 0.0, Engine.Cam.Z*Temp2), M1);

  D3DXVec3Add(NewPos, TObj.RPos, Vector);

  D3DXVec3Subtract(Vector, TObj.RPos, NewPos);
  List:=TList.Create;
  Engine.Map.CollectItems(List, NewPos.X, NewPos.Z, TObj.RPos.X, TObj.RPos.Z, TStaticItem);
  Temp2:=Engine.Cam.Angle;
  Temp3:=1.0;
  for I:=0 to List.Count-1 do
   with TStaticItem(List[I]) do begin
    if Obj=nil then MakeObject;
    with Obj do for J:=0 to Children.Count-1 do with Children.Obj[J] do begin if Pos('top', Name)>0 then
    if (AMaxPos.X-AMinPos.X>5.0) and (AMaxPos.Y-AMinPos.Y>5.0) and (AMaxPos.Z-AMinPos.Z>5.0) then
     if (AMinPos.X<TObj.RPos.X) and {(AMinPos.Y<TObj.RPos.Y) and} (AMinPos.Z<TObj.RPos.Z) and (AMaxPos.X>TObj.RPos.X) and (AMaxPos.Y>TObj.RPos.Y) and (AMaxPos.Z>TObj.RPos.Z) then begin
      Temp2:=g_PI_DIV_2;
      Temp3:=0.75;
     end else begin
      Temp:=VectorRectIntersect(D3DXVector3(AMinPos.X, AMinPos.Y-10.0, AMinPos.Z), D3DXVector3(0.0, AMaxPos.Y-AMinPos.Y+10.0, 0.0), D3DXVector3(AMaxPos.X-AMinPos.X, 0.0, 0.0), NewPos, Vector);
      if (Temp>=0.0) and (Temp<=1.0) then begin
       D3DXVec3Lerp(Vector2, NewPos, TObj.RPos, Temp);
       Temp2:=Max(Temp2, Min(g_PI_DIV_2, g_PI_DIV_2-ArcCos((AMaxPos.Y-TObj.RPos.Y)/D3DXVec3Length(D3DXVector3(Vector2.X-TObj.RPos.X, AMaxPos.Y-TObj.RPos.Y, Vector2.Z-TObj.RPos.Z)))));
      end;
      Temp:=VectorRectIntersect(D3DXVector3(AMinPos.X, AMinPos.Y-10.0, AMinPos.Z), D3DXVector3(0.0, AMaxPos.Y-AMinPos.Y+10.0, 0.0), D3DXVector3(0.0, 0.0, AMaxPos.Z-AMinPos.Z), NewPos, Vector);
      if (Temp>=0.0) and (Temp<=1.0) then begin
       D3DXVec3Lerp(Vector2, NewPos, TObj.RPos, Temp);
       Temp2:=Max(Temp2, Min(g_PI_DIV_2, g_PI_DIV_2-ArcCos((AMaxPos.Y-TObj.RPos.Y)/D3DXVec3Length(D3DXVector3(Vector2.X-TObj.RPos.X, AMaxPos.Y-TObj.RPos.Y, Vector2.Z-TObj.RPos.Z)))));
      end;
      Temp:=VectorRectIntersect(AMaxPos, D3DXVector3(0.0, AMinPos.Y-10.0-AMaxPos.Y, 0.0), D3DXVector3(AMinPos.X-AMaxPos.X, 0.0, 0.0), NewPos, Vector);
      if (Temp>=0.0) and (Temp<=1.0) then begin
       D3DXVec3Lerp(Vector2, NewPos, TObj.RPos, Temp);
       Temp2:=Max(Temp2, Min(g_PI_DIV_2, g_PI_DIV_2-ArcCos((AMaxPos.Y-TObj.RPos.Y)/D3DXVec3Length(D3DXVector3(Vector2.X-TObj.RPos.X, AMaxPos.Y-TObj.RPos.Y, Vector2.Z-TObj.RPos.Z)))));
      end;
      Temp:=VectorRectIntersect(AMaxPos, D3DXVector3(0.0, AMinPos.Y-10.0-AMaxPos.Y, 0.0), D3DXVector3(0.0, 0.0, AMinPos.Z-AMaxPos.Z), NewPos, Vector);
      if (Temp>=0.0) and (Temp<=1.0) then begin
       D3DXVec3Lerp(Vector2, NewPos, TObj.RPos, Temp);
       Temp2:=Max(Temp2, Min(g_PI_DIV_2, g_PI_DIV_2-ArcCos((AMaxPos.Y-TObj.RPos.Y)/D3DXVec3Length(D3DXVector3(Vector2.X-TObj.RPos.X, AMaxPos.Y-TObj.RPos.Y, Vector2.Z-TObj.RPos.Z)))));
      end;
     end;
    end;
   end;
  List.Free;

  D3DXVec3TransformCoord(Vector2, D3DXVector3(0.0, 0.0, 1.0), Engine.Camera.Rot);
  Temp:=D3DXVec3Length(TObj.RotMove);
  {if Temp<2 then D3DXQuaternionRotationYawPitchRoll(TargetQ, GetYAngle(TObj.RRot)+Ord(LookBack)*g_PI, Temp2, 0.0)
   else D3DXQuaternionRotationYawPitchRoll(TargetQ, GetYAngle(Engine.Camera.Rot)+Ord(LookBack)*g_PI, Temp2, 0.0);
  D3DXQuaternionNormalize(OldQ, Engine.Camera.Orientation);}
  if Temp<2 then begin
   D3DXQuaternionNormalize(OldQ, Engine.Camera.YAngle);
   D3DXQuaternionRotationYawPitchRoll(TargetQ, GetYAngle(TObj.RRot)+Ord(LookBack)*g_PI, 0.0, 0.0);
   if FWasLookBack<>FLookBack then Engine.Camera.YAngle:=TargetQ
    else D3DXQuaternionSlerp(Engine.Camera.YAngle, OldQ, TargetQ, TickCount*0.002*(1.0-Temp*0.5));
  end;                                                                    
  D3DXQuaternionNormalize(OldQ, Engine.Camera.XAngle);
  D3DXQuaternionRotationYawPitchRoll(TargetQ, 0.0, Temp2, 0.0);
  if FWasLookBack<>FLookBack then Engine.Camera.XAngle:=TargetQ
   else D3DXQuaternionSlerp(Engine.Camera.XAngle, OldQ, TargetQ, TickCount*0.003);
  D3DXQuaternionMultiply(Engine.Camera.Orientation, Engine.Camera.XAngle, Engine.Camera.YAngle);
  //D3DXQuaternionSlerp(Engine.Camera.Orientation, OldQ, TargetQ, TickCount*({Ord(Car=nil)*0.008+}0.002)*(1-Temp*0.5));
  D3DXMatrixRotationQuaternion(Engine.Camera.Rot, Engine.Camera.Orientation);

  //Temp3:=1.0+D3DXVec3Length(Obj.PosMove)*0.02;
  D3DXVec3TransformCoord(Vector, D3DXVector3(Engine.Cam.X, 0.0, Engine.Cam.Z*Temp3), Engine.Camera.Rot);
  D3DXVec3Add(Engine.Camera.Pos, D3DXVector3(TObj.RPos.X, TObj.RPos.Y+Engine.Cam.Y, TObj.RPos.Z), Vector);
  {D3DXVec3TransformCoord(Vector3, D3DXVector3(0.0, 0.0, 1.0), Engine.Camera.Rot);
  Engine.Camera.Pos.X:=(Engine.Camera.Pos.X+TObj.PosMove.X*TickCount*0.001+(Vector3.X-Vector2.X)*Engine.Camera.Cam.Z*Temp2)*(1.0-0.0015*TickCount)+(TObj.RPos.X+Vector.X)*0.0015*TickCount;
  Engine.Camera.Pos.Y:=(Engine.Camera.Pos.Y+TObj.PosMove.Y*TickCount*0.001+(Vector3.Y-Vector2.Y)*Engine.Camera.Cam.Z*Temp2)*(1.0-0.0015*TickCount)+(TObj.RPos.Y+Vector.Y+Engine.Camera.Cam.Y)*0.0015*TickCount;
  Engine.Camera.Pos.Z:=(Engine.Camera.Pos.Z+TObj.PosMove.Z*TickCount*0.001+(Vector3.Z-Vector2.Z)*Engine.Camera.Cam.Z*Temp2)*(1.0-0.0015*TickCount)+(TObj.RPos.Z+Vector.Z)*0.0015*TickCount;
  }
  FWasLookBack:=FLookBack;
 end else begin
  Engine.Camera.Rot:=TObj.RRot;
  if LookBack then begin
   Engine.Camera.Rot._31:=-Engine.Camera.Rot._31;
   Engine.Camera.Rot._32:=-Engine.Camera.Rot._32;
   Engine.Camera.Rot._33:=-Engine.Camera.Rot._33;
   {M2:=Engine.Camera.Rot;
   D3DXMatrixRotationY(M1, g_PI);
   D3DXMatrixMultiply(Engine.Camera.Rot, M2, M1);}
  end;
  D3DXVec3TransformCoord(Engine.Camera.Pos, D3DXVector3(Engine.Camera.Cam.X, Engine.Camera.Cam.Y, (1-2*Ord(LookBack))*Engine.Camera.Cam.Z), Engine.Camera.Rot);
  Engine.Camera.Pos.X:=Engine.Camera.Pos.X+TObj.RPos.X;
  Engine.Camera.Pos.Y:=Engine.Camera.Pos.Y+TObj.RPos.Y;
  Engine.Camera.Pos.Z:=Engine.Camera.Pos.Z+TObj.RPos.Z;
 end;

 D3DXVec3TransformCoord(Vector, MakeD3DVECTOR(0.0, 0.0, 1.0), TObj.RRot);
 D3DXVec3TransformCoord(Vector2, MakeD3DVECTOR(0.0, 1.0, 0.0), TObj.RRot);
 FSOUND_3D_Listener_SetAttributes(@APos, @TObj.PosMove, Vector.X, Vector.Y, Vector.Z, Vector2.X, Vector2.Y, Vector2.Z);
end;

procedure TTssPlayer.CarCtrl(TickCount: Single; var Ctrl: TTssCarControls);
var Right, Left: Boolean;
    Temp: Cardinal;
begin
 if not ExittingCar then begin
 if Engine.Controls.GameKeyDown(keyCarHorn, -1) then begin
  Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Horn, nil, False);
  FSOUND_3D_SetAttributes(Temp, @Car.RPos, @Car.PosMove);
  FSOUND_SetVolume(Temp, 255);
 end;
 Right:=Engine.Controls.GameKeyDown(keyCarSteerRight, 0);
 Left:=Engine.Controls.GameKeyDown(keyCarSteerLeft, 0);
 if Right and (not Left) then Ctrl.Steering:=Max(-1, Ctrl.Steering-TickCount*Car.Steering_Speed)
  else if Left and (not Right) then Ctrl.Steering:=Min(1, Ctrl.Steering+TickCount*Car.Steering_Speed);
 if (Ctrl.Steering>0) and (not Left) then Ctrl.Steering:=Max(0, Ctrl.Steering-TickCount*Car.Steering_Speed);
 if (Ctrl.Steering<0) and (not Right) then Ctrl.Steering:=Min(0, Ctrl.Steering+TickCount*Car.Steering_Speed);

 if Car.Gear<0 then begin
  Ctrl.Brake:=Ord(Engine.Controls.GameKeyDown(keyCarAcc, 0))*0.99;
  if Engine.Controls.GameKeyDown(keyCarBrake, 0) then Ctrl.Accelerate:=Min(0.99, Ctrl.Accelerate+TickCount*0.004)
   else Ctrl.Accelerate:=Max(0.0, Ctrl.Accelerate-TickCount*0.004);
 end else begin
  if Engine.Controls.GameKeyDown(keyCarAcc, 0) then Ctrl.Accelerate:=Min(0.99, Ctrl.Accelerate+TickCount*0.004)
   else Ctrl.Accelerate:=Max(0.0, Ctrl.Accelerate-TickCount*0.004);
  Ctrl.Brake:=Ord(Engine.Controls.GameKeyDown(keyCarBrake, 0))*0.99;
 end;
 if Engine.Controls.GameKeyDown(keyCarBurnOut, 0) then begin
  Ctrl.Accelerate:=Min(1.0, Ctrl.Accelerate+TickCount*0.008);
  if Car.Gear<1 then begin Car.Gear:=1; Car.GearDelay:=300; end;
 end;

 if (Ctrl.Accelerate=0.0) and (Car.GearDelay=0.0) then
  if (Ctrl.Brake>0.0) and ((Car.CarSpeed<1.0) or (Car.Forw and (Car.Gear<0)) or (not Car.Forw and (Car.Gear>0))) then begin
   if Car.Gear>0 then Car.Gear:=-1 else Car.Gear:=1;
   Car.GearDelay:=300;
  end;

 if (not Ctrl.HandBrake) and Engine.Controls.GameKeyDown(keyCarHandBrake, 0) then begin
  Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.HBrake, nil, False);
  FSOUND_3D_SetAttributes(Temp, @Car.RPos, @Car.PosMove);
  FSOUND_SetVolume(Temp, 160);
 end;
 Ctrl.HandBrake:=Engine.Controls.GameKeyDown(keyCarHandBrake, 0);
 end;
 Ctrl.ExitCar:=Engine.Controls.GameKeyDown(keyDoorOpen, -1);
end;

{ TTssSteeringWheel }

procedure TTssSteeringWheel.ExtraLoad(Data: Pointer; Size: Word);
begin
 Axis:=TD3DXVector3(Data^);
end;

function TTssCar.GetSpeedAddress: Cardinal;
begin
 Result:=Cardinal(@CarSpeed);
end;

function TTssCar.GetRPMAddress: Cardinal;
begin
 Result:=Cardinal(@RPM);
end;

function TTssCar.GetColor: TD3DColor;
begin
 Result:=GetD3DColor(Engine.CarColorMap[Random(Engine.CarColorSize)]);
end;

procedure TTssHuman.Crash(const Pos, Impact: TD3DXVector3);
var I, J: integer;
    Link: TTssLink;
    M: TD3DMatrix;
    S1, S2: string;
    Obj: TTssObject;
    Vector: TD3DXVector3;
    Temp: integer;
begin
 if D3DXVec3Length(Impact)<3.0 then begin
  IgnoreObj:=True;
  Animation:=FStandAni;
  Exit;
 end;
 if D3DXVec3Length(Impact)<4.0 then Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.PedCrash1, nil, False)
  else Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.PedCrash2, nil, False);
 Vector:=VectorInvert(Impact);
 //FSOUND_3D_SetAttributes(Temp, @Pos, {@Vector}nil);
 FSOUND_SetVolume(Temp, 255);
 for I:=0 to Children.Count-1 do begin
  S1:='';
  S2:='';
  with Children.Obj[I] do begin
   if (Name='pelvis') or (Name='arm_left') or (Name='arm_right') or (Name='head') then S1:='back';
   if Name='hand_left' then S1:='arm_left';
   if Name='hand_right' then S1:='arm_right';
   if (Name='leg_left') or (Name='leg_right') then S1:='pelvis';
   if Name='foot_left' then begin S1:='leg_left'; S2:='pelvis'; end;
   if Name='foot_right' then begin S1:='leg_right'; S2:='pelvis'; end;
  end;
  Obj:=nil;
  if S1<>'' then for J:=0 to Children.Count-1 do if Children.Obj[J].Name=S1 then Obj:=Children.Obj[J];
  if S2<>'' then for J:=0 to Children.Count-1 do if Children.Obj[J].Name=S2 then Obj:=Children.Obj[J];
  Vector:=Children.Obj[I].Centralize;
  if Obj<>nil then begin
   Link:=TTssLink.Create;
   Link.Object1:=Children[I];
   Link.Object2:=Obj;
   Link.FRPos1:=Vector;
   D3DXVec3TransformCoord(Vector, Vector, Link.FObj1.Matrix);
   D3DXMatrixInverse(M, nil, Obj.Matrix);
   D3DXVec3TransformCoord(Link.FRPos2, Vector, M);
   Link.FStrength:=4.0;
   Link.FEasyStop:=True;
   Engine.Links.Add(Link);
  end;
 end;
 RotMove.X:=RotMove.X+Moment.X/TotMass*Engine.TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
 RotMove.Y:=RotMove.Y+Moment.Y/TotMass*Engine.TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
 RotMove.Z:=RotMove.Z+Moment.Z/TotMass*Engine.TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
 Moment:=MakeD3DVector(0,0,0);      
 FreeBuffers;
 MakeBuffers;
 for I:=Children.Count-1 downto 0 do
  with Children.Obj[I] do begin
   PosMove:=GetMove(Self.PosMove, VectorScale(Self.RotMove, 2.0), RPos, 1.0);
   PosMove.X:=PosMove.X-Impact.X;
   PosMove.Y:=PosMove.Y-Impact.Y+D3DXVec3Length(Impact)*0.2;
   PosMove.Z:=PosMove.Z-Impact.Z;
   RotMove:=D3DXVector3((Random(2000)-1000)*0.001, (Random(2000)-1000)*0.001, (Random(2000)-1000)*0.001);
   Parent:=nil;
   Stopped:=False;
   Manual:=False;
   IgnoreObj:=True;
   Mass:=10.0;
   TotMass:=10.0;
   Track:=nil;
   FRefObject:=Self;
   Inc(Self.FRefCount);
  end;
 Remove;
end;

procedure TTssPlayer.Crash(const Pos, Impact: TD3DXVector3);
begin
end;

procedure TTssHuman.FillBuffers;
var J, N: integer;
    PVB: P3DVertex2TxColor;
    PIB: PIndex;
begin
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
   VB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
   for J:=0 to VertexCount-1 do begin
    PVB.V:=Vertices[J].V1;
    PVB.nX:=-(Vertices[J].nX-128)*0.007874015748031496;
    PVB.nY:=-(Vertices[J].nY-128)*0.007874015748031496;
    PVB.nZ:=-(Vertices[J].nZ-128)*0.007874015748031496;
    PVB.tU1:=(Vertices[J].tU-32768)*0.0009765625;
    PVB.tV1:=(Vertices[J].tV-32768)*0.0009765625;
    PVB.Color:=Vertices[J].Color;// D3DCOLOR_ARGB(255, 128, 128, 128);
    Inc(PVB);
   end;
   VB.Unlock;
   IB.Lock(0, 0, PByte(PIB), D3DLOCK_DISCARD);
   for J:=0 to IndexCount-1 do begin
    PIB^:=Indices[J];
    Inc(PIB);
   end;
   IB.Unlock;
 end;
end;

initialization
RegisterClass(TTssPlayer);
RegisterClass(TTssCar);
RegisterClass(TTssTyre);
RegisterClass(TTssCam);
finalization
UnregisterClass(TTssCam);
UnregisterClass(TTssTyre);
UnregisterClass(TTssCar);
UnregisterClass(TTssPlayer);
end.
