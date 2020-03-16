{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Object Unit                            *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssObjects;

interface                                            

uses
  Windows, Messages, SysUtils, Classes, MMSystem, IniFiles, Math,
  Direct3D8, D3DX8, D3DApp, D3DFont, D3DUtil, DXUtil, DirectInput8, DX8DI,
  TssUtils, TssTextures, TssFiles, TssControls, TssAlpha, TssShadows,
  TssConsole, TssAnim, fmod, fmodtypes;

const
  DETAILS_LOW  = 1;  // Maximun Number of Low Detail Versions
  DETAILS_HIGH = 1;  // Maximun Number of High Detail Versions

type
  TTssObjectList = class;

  //PMeshData = ^TMeshData;
  TMeshData = class(TObject)//array[0..0] of record
  public
   DataIndex: Byte;

   StartVertex, StartIndex: Word;
   VertexCount, IndexCount: Word;

   Material: TTssMaterial;
   ShadowData: TShadowData;
   PolyIndices: PIndices;

   MinPos, MaxPos: TD3DXVector3;
  end;

  TPointerData = packed record
    Name: string[10];
    Matrix: TD3DMatrix;
  end;

  PTssMesh = ^TTssMesh;
  TTssMesh = packed record
    MeshName: TString32;
    GroupCount: Word;
    MeshData: TList;
    VertexCount, IndexCount: Word;
    Vertices: PObjDataVertices;
    PreCalculated: TD3DMatrix;
    Indices: PIndices;
    Bits: TBitArray;
    BitsFrom, BitsTo: Word;
    VB: IDirect3DVertexBuffer8;
    IB: IDirect3DIndexBuffer8;
  end;

  TTssLight = packed record
    Enabled: Boolean;
    Pos: TD3DXVector3;
    Dir: TD3DXVector3;
    Color: DWord;
  end;

  PColorMap = ^TColorMap;
  TColorMap = array[0..65535] of TColor24Bit;

  string64 = string[64];
  TTssObjHitStyle = (hsNone, hsBox, hsSphere, hsRay, hsMeshLow1, hsMesh, hsMeshHigh1);
  TTssObject = class(TVirtualObject)
  protected
    FParent: TTssObject;
    procedure SetParent(Value: TTssObject); virtual;
    procedure LoadPointerObj(Obj: TTssObject; const Data: TPointerData);
    procedure ExtraLoad(Data: Pointer; Size: Word); virtual;
    procedure PointerLoad(const Data: TPointerData); virtual;
    procedure DataItemLoad(Data: Pointer; Size: Word); virtual;
    procedure LightLoad(Data: Pointer); virtual;
    function ChildLoad(ObjType: Byte; Data: Pointer): Pointer; virtual;
    function GetColor: TD3DColor; virtual;

    procedure FillBuffers; virtual;
  public
    FRemove: Boolean;
    AutoHandle: Boolean;
    Children: TTssObjectList;
    Details: array[-DETAILS_LOW-2..DETAILS_HIGH] of TTssMesh;
    Matrix: TD3DMatrix;
    DrawNeedsConfirmation, DrawNow, FastDraw: Boolean;
    DrawDistance, DrawDistanceChild: Single;
    CollDetails: PTssMesh;
    PPointer: Pointer;
    SharedBuffers: Boolean;
    ScriptCreated: Boolean;
    FAnimation: TAnimation;
    AnimPos, AnimSpeed: Single;
    Track: TAnimTrack;
    FVisible: Boolean;
    FAlpha: Single;
    FKillTimer: Single;
    FRefObject: TTssObject;
    FRefCount: integer;
    FNoRot: Boolean;
    FDisabled: Boolean;

    HitStyle: TTssObjHitStyle;                  // How collisions are detected
    HitTo: Boolean;                             // This object can collide to another
    HitFrom: Boolean;                           // Other objects can collide to this
    IgnoreObj: Boolean;
    DontFree: Boolean;
    BreakStrength: Single;

    MinPos, MaxPos: TD3DXVector3;               // Used to Optimize Physics
    AMinPos, AMaxPos: TD3DXVector3;             // --
    Range: integer;                             // --

    OrigRot, RRot: TD3DMatrix;
    RRot2: TD3DXQuaternion; RPos, OrigPos: TD3DXVector3; // Relative (Object Space)
    ARot: TD3DMatrix; APos: TD3DXVector3;       // Absolute (World Space)
    WindRot: TD3DMatrix;

    Force, Moment: TD3DXVector3;                // Physic Variables
    PosMove, RotMove, WindMove: TD3DXVector3;   // --
    Static, Stopped, Manual: Boolean;           // --
    LastMove: Single;                           // --
    Gravitation: Single;                        // --
    TotMass, OwnMass: Single;                   // --
    FAirResistance, SpringConstant: Single;     // --
    Distance: Single;                           // from camera

    Model: packed record                        // Model Information
      ObjType: Word;                            // --
      Name: string64;                           // --
    end;                                        // --

    OldData, NewData: Pointer;

    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); virtual;
    destructor Destroy; override;
    procedure Move(TickCount: Single); virtual;
    procedure Draw; virtual;
    procedure Remove;
    procedure Crash(const Pos, Impact: TD3DXVector3); virtual;
    function Centralize: TD3DXVector3;

    procedure LoadData(FileName: string); virtual;
    function LoadFromBuffer(Data: Pointer; Shared: Boolean = False): Pointer; virtual;
    procedure UnLoadData; virtual;

    procedure MakeBuffers; virtual;
    procedure FreeBuffers; virtual;

    function CollectGroups(const X1, Y1, Z1, Range: Single; Level: integer): Boolean;

    function TopObj: TTssObject;
    procedure SetAnimation(Value: TAnimation);
    //function GetObjects: TObjectArray;
    procedure CalculateWind(TickCount: Single);
    procedure VirtualData(AId: Cardinal; AData: Pointer; ASize: Cardinal); override;
  published
    property Name: string64 read Model.Name write Model.Name;
    property Parent: TTssObject read FParent write SetParent;
    property Mass: Single read OwnMass write OwnMass;
    property AirResistance: Single read FAirResistance write FAirResistance;
    property Objects: TTssObjectList read Children;
    property X: Single read RPos.X write RPos.X;
    property Y: Single read RPos.Y write RPos.Y;
    property Z: Single read RPos.Z write RPos.Z;
    property Animation: TAnimation read FAnimation write SetAnimation;
  end;

  TTssObjectClass = class of TTssObject;

  TTssObjectList = class(TList)
  private
    FAutoFree: Boolean;
    function GetObj(Index: integer): TTssObject;
  public
    constructor Create(AutoFree: Boolean); overload;
    destructor Destroy; override;
    property Obj[Index: integer]: TTssObject read GetObj;
  end;

  TTssLink = class(TPersistent)
  private
    procedure SetObj1(const Value: TTssObject);
    procedure SetObj2(const Value: TTssObject);
  public
    FObj1, FObj2: TTssObject;
    FRPos1, FRPos2: TD3DXVector3;
    FAPos1, FAPos2: TD3DXVector3;
    FStrength: Single;
    FEasyStop: Boolean;
  public
    procedure Move(TickCount: Single);
    destructor Destroy; override;
  published
    property Object1: TTssObject read FObj1 write SetObj1;
    property Object2: TTssObject read FObj2 write SetObj2;
    property Pos1X: Single read FRPos1.X write FRPos1.X;
    property Pos1Y: Single read FRPos1.Y write FRPos1.Y;
    property Pos1Z: Single read FRPos1.Z write FRPos1.Z;
    property Pos2X: Single read FRPos2.X write FRPos2.X;
    property Pos2Y: Single read FRPos2.Y write FRPos2.Y;
    property Pos2Z: Single read FRPos2.Z write FRPos2.Z;
    property Strength: Single read FStrength write FStrength;
  end;

implementation

uses
  TssEngine, TssPhysics;

constructor TTssObject.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited Create;
 FParent:=AParent;
 AutoHandle:=AAutoHandle;
 Children:=TTssObjectList.Create(True);
 if FParent<>nil then FParent.Children.Add(Self)
  else if AutoHandle then Engine.FObjects.Add(Self);
 DrawDistance:=70.0;
 DrawDistanceChild:=70.0;
 RRot:=Engine.IdentityMatrix;
 OrigRot:=RRot;
 RPos:=MakeD3DVector(0,0,0);
 ARot:=Engine.IdentityMatrix;
 APos:=MakeD3DVector(0,0,0);
 WindMove:=MakeD3DVector(Random(1000)*0.0001-0.00005,0,Random(1000)*0.0001-0.00005);
 D3DXMatrixRotationYawPitchRoll(WindRot, 0.00, Random(1000)*0.0001-0.00005, Random(1000)*0.0001-0.00005);
 SpringConstant:=Random(1000)*0.00005+0.075;
 PosMove:=MakeD3DVector(0.0, 0.0, 0.0);
 RotMove:=MakeD3DVector(0.0, 0.0, 0.0);
 MinPos:=MakeD3DVector(16384, 16384, 16384);
 MaxPos:=MakeD3DVector(-16384, -16384, -16384);
 HitStyle:=hsBox;
 HitTo:=True;
 HitFrom:=True;
 TotMass:=1;
 Gravitation:=11.0;
 Static:=False;
 Stopped:=True;
 FAlpha:=1.0;
 BreakStrength:=1.0;
 FVisible:=True;
 DrawNeedsConfirmation:=False;
end;

procedure TTssObject.SetParent(Value: TTssObject);
var N: integer;
    M1, M2: TD3DMatrix;
begin
 if Value<>FParent then begin
  if FParent=nil then begin
   if AutoHandle then Engine.FObjects.Remove(Self)
  end else begin
   //PosMove:=FParent.PosMove;
   Physics_CalculateOrientation(Self);
   FParent.Children.Remove(Self);
   if SharedBuffers then begin
    SharedBuffers:=False;
    DontFree:=True;
    for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do begin
     Vertices:=FParent.Details[N].Vertices;
     Indices:=FParent.Details[N].Indices;
     VB:=FParent.Details[N].VB;
     IB:=FParent.Details[N].IB;
     Bits:=Bits;
    end;
   end;
  end;
  FParent:=Value;
  if FParent<>nil then begin
   FParent.Children.Add(Self);
   Matrix:=ARot;
   Matrix._41:=APos.X; Matrix._42:=APos.Y; Matrix._43:=APos.Z;
   M1:=FParent.ARot;
   M1._41:=FParent.APos.X; M1._42:=FParent.APos.Y; M1._43:=FParent.APos.Z;
   D3DXMatrixInverse(M2, nil, M1);
   D3DXMatrixMultiply(RRot, Matrix, M2);
   RPos.X:=RRot._41; RPos.Y:=RRot._42; RPos.Z:=RRot._43;
   RRot._41:=0.0; RRot._42:=0.0; RRot._43:=0.0;
  end else begin
   RRot:=ARot;
   RPos:=APos;
   if AutoHandle then Engine.FObjects.Add(Self);
  end;
 end;
end;

function TTssObject.TopObj: TTssObject;
begin
 if FParent=nil then Result:=Self
  else Result:=FParent.TopObj;
end;

destructor TTssObject.Destroy;
begin
 if Parent<>nil then Parent.Children.Remove(Self)
  else if AutoHandle then Engine.FObjects.Remove(Self);
 Children.Free;
 FreeBuffers;
 UnLoadData;
 if FRefObject<>nil then Dec(FRefObject.FRefCount);
 //for I:=-DETAILS_LOW to DETAILS_HIGH do
 // for J:=0 to Details[I].GroupCount-1 do
 //  TMeshData(Details[I].MeshData.Items[J]).Free;
  //FreeMem(Details[I].MeshData);
end;

procedure TTssObject.CalculateWind(TickCount: Single);
var WindChange, OldWind: TD3DXMatrix;
    Vector: TD3DXVector3;
begin
 D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 1.0, 0.0), WindRot);
 WindMove.X:=(WindMove.X-Vector.Z*SpringConstant+Engine.Sky.WindZ*Random(1000)*100*Power(1.002, TickCount))*Power(0.9995, TickCount);
 WindMove.Z:=(WindMove.Z+Vector.X*SpringConstant-Engine.Sky.WindX*Random(1000)*100*Power(1.002, TickCount))*Power(0.9995, TickCount);
 OldWind:=WindRot;
 D3DXMatrixRotationYawPitchRoll(WindChange, WindMove.Y*TickCount*0.001, WindMove.X*TickCount*0.001, WindMove.Z*TickCount*0.001);
 D3DXMatrixMultiply(WindRot, WindChange, OldWind);
end;

procedure TTssObject.Move(TickCount: Single);
var I: integer;
    NewRot, mat: TD3DXMatrix;
    NewPos: TD3DXVector3;
    V1, V2: PD3DXVector3;
begin
 if Engine.VirtualEngine.Playing then begin
  if (OldData<>nil) and (NewData<>nil) then begin
   D3DXQuaternionSlerp(RRot2, TD3DXQuaternion(OldData^), TD3DXQuaternion(NewData^), Engine.VirtualEngine.FrameSlerpP);
   D3DXMatrixRotationQuaternion(RRot, RRot2);
   V1:=PD3DXVector3(Cardinal(OldData)+SizeOf(RRot2));
   V2:=PD3DXVector3(Cardinal(NewData)+SizeOf(RRot2));
   D3DXVec3Lerp(NewPos, V1^, V2^, Engine.VirtualEngine.FrameSlerpP);
   PosMove:=D3DXVector3((V2.X-V1.X)/Engine.VirtualEngine.FrameLength, (V2.Y-V1.Y)/Engine.VirtualEngine.FrameLength, (V2.Z-V1.Z)/Engine.VirtualEngine.FrameLength);
   RPos:=NewPos;
   if Parent=nil then begin
    ARot:=RRot;
    APos:=RPos;
   end else Physics_CalculateOrientation(Self);
   for I:=Children.Count-1 downto 0 do
    Children.Obj[I].Move(TickCount);
  end else if Parent<>nil then Physics_CalculateOrientation(Self);
 end else begin
  if not Engine.VirtualEngine.Playing then begin
   OldData:=nil;
   NewData:=nil;
  end;
  if FAnimation<>nil then begin
   AnimPos:=AnimPos+TickCount*0.001*AnimSpeed;
   FAnimation.SetPosition(AnimPos);
  end;
  if Track<>nil then begin
   RRot:=Track.Matrix;
   RPos.X:=RRot._41;
   RPos.Y:=RRot._42;
   RPos.Z:=RRot._43;
   RRot._41:=0.0;
   RRot._42:=0.0;
   RRot._43:=0.0;
  end;
  if FParent=nil then begin
   if not ScriptCreated then if D3DXVec3LengthSq(VectorSubtract(RPos, Engine.Player.TopObj.RPos))>10000.0 then begin
    FKillTimer:=FKillTimer+TickCount;
    if FKillTimer>3000.0 then Remove; // 3 sec
   end else FKillTimer:=0.0;

   if (not Static) and (not Stopped) then begin   //  Calculate new orientation and position and do
    Physics_MoveObject(Self, TickCount);          //  collision detection (toplevel-object only)
    if Engine.VirtualEngine.Recording then begin
     D3DXMatrixRotationYawPitchRoll(mat, -RotMove.Y*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength, -RotMove.X*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength, -RotMove.Z*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength);
     D3DXMatrixMultiply(NewRot, RRot, mat);
     D3DXQuaternionRotationMatrix(RRot2, NewRot);
     NewPos:=RPos;
     RPos.X:=RPos.X-PosMove.X*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength;
     RPos.Y:=RPos.Y-PosMove.Y*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength;
     RPos.Z:=RPos.Z-PosMove.Z*Engine.VirtualEngine.FrameSlerpR*Engine.VirtualEngine.FrameLength;
     Engine.VirtualEngine.AddData(False, Self, 0, @RRot2, SizeOf(RRot2)+SizeOf(RPos));
     RPos:=NewPos;
    end;
   end;
   ARot:=RRot;
   APos:=RPos;
   if Model.ObjType=100 then CalculateWind(TickCount);
   if RPos.Y<-25.0 then begin
    RPos:=OrigPos;
    RRot:=Engine.IdentityMatrix;
    PosMove:=MakeD3DVector(0,0,0);
    RotMove:=MakeD3DVector(0,0,0);
   end;
  end else begin
   {mat:=RRot;
   D3DXMatrixRotationYawPitchRoll(NewRot, Random(1000)*0.00001, Random(1000)*0.00001, Random(1000)*0.0001);
   D3DXMatrixMultiply(RRot, NewROt, mat);}
   {if Engine.VirtualEngine.Recording then if (not Parent.Static) and (not Parent.Stopped) then begin
    D3DXQuaternionRotationMatrix(RRot2, RRot);
    Engine.VirtualEngine.AddData(False, Self, 0, @RRot2, SizeOf(RRot2)+SizeOf(RPos));
   end;}
   Physics_CalculateOrientation(Self);
  end;
  TotMass:=OwnMass;
  if FVisible then
   for I:=Children.Count-1 downto 0 do begin
    Children.Obj[I].Move(TickCount);               //  Move sub-objects
    if Children.Count>I then TotMass:=TotMass+Children.Obj[I].TotMass;
   end;
 end;
end;

procedure TTssObject.Draw;
var Temp: Single;
    DoHide: Boolean;
  procedure DoDraw(DetailLevel: integer; Alpha: Single);
  var I: integer;
  begin
   with Details[DetailLevel] do if VertexCount>0 then begin
    if Alpha<1.0 then begin
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
     Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
     Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
     Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, Round(Alpha*255) shl 24);
    end else begin
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
     Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    end;
    if not SharedBuffers then begin
     if (VB=nil) or (IB=nil) then MakeBuffers;
     Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex2TxColor));
     Engine.m_pd3dDevice.SetIndices(IB, 0);
     Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TXCOLOR);
    end;
    for I:=0 to GroupCount-1 do with TMeshData(MeshData[I]) do if (VertexCount>0) and (not (DoHide and Material.CanHide)) then begin
     if {(}(Material.Opacity=98){ and (Alpha=1.0) and (Distance<Temp*0.5))} or (FAlpha<1.0) then Engine.AlphaSystem.NewAlpha(AlphaData1(Self, I, @Matrix), 0)
      else begin
       Engine.Textures.SetMaterial(Material, 0);
       Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, StartVertex, VertexCount, StartIndex, IndexCount div 3);
       Engine.IncPolyCounter(IndexCount div 3);
      end;
    end;
   end;
  end;
var I: integer;
begin
 if FastDraw then begin
  Engine.Lights.EnableLights(D3DXVector3(APos.X-Range*0.001, APos.Y-Range*0.001, APos.Z-Range*0.001), D3DXVector3(APos.X+Range*0.001, APos.Y+Range*0.001, APos.Z+Range*0.001));
  Matrix:=ARot;
  Matrix._41:=Matrix._41+APos.X;
  Matrix._42:=Matrix._42+APos.Y;
  Matrix._43:=Matrix._43+APos.Z;
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Matrix);
  with Details[0] do begin
   if (VB=nil) or (IB=nil) then MakeBuffers;
   Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex2TxColor));
   Engine.m_pd3dDevice.SetIndices(IB, 0);
   Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TXCOLOR);
   for I:=0 to GroupCount-1 do with TMeshData(MeshData[I]) do if VertexCount>0 then begin
    Engine.Textures.SetMaterial(Material, 0);
    Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, StartVertex, VertexCount, StartIndex, IndexCount div 3);
    Engine.IncPolyCounter(IndexCount div 3);
   end;
  end;
 end else if (not DrawNeedsConfirmation) or DrawNow then begin
  Engine.Lights.EnableLights(D3DXVector3(APos.X-Range*0.001, APos.Y-Range*0.001, APos.Z-Range*0.001), D3DXVector3(APos.X+Range*0.001, APos.Y+Range*0.001, APos.Z+Range*0.001));
  DrawNow:=False;
  if Model.ObjType=100 then D3DXMatrixMultiply(Matrix, ARot, WindRot)
   else Matrix:=ARot;
  Matrix._41:=Matrix._41+APos.X;
  Matrix._42:=Matrix._42+APos.Y;
  Matrix._43:=Matrix._43+APos.Z;
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Matrix);

  Distance:=Max(0.0, D3DXVec3Length(VectorSubtract(APos, Engine.Camera.Pos))-Range*0.001);
  if Parent=nil then Temp:=DrawDistance else Temp:=DrawDistanceChild;
  Engine.Textures.AlphaRef:=Max(8,Round(224-2.4*Distance));
  if FAlpha<1.0 then FAlpha:=Min(1.0, FAlpha+0.02);
  if Engine.Player<>nil then if AMinPos.Y>Engine.Player.APos.Y+1.0 then
   if AMinPos.X<Engine.Player.APos.X then
    if AMaxPos.X>Engine.Player.APos.X then
     if AMinPos.Z<Engine.Player.APos.Z then
      if AMaxPos.Z>Engine.Player.APos.Z then FAlpha:=Max(0.0, FAlpha-0.04);
  if Distance<Temp then begin
   DoHide:=Distance>80.0;
   if FAlpha>0.0 then DoDraw(0, 1.0);
  end else if Distance<Temp*1.1 then DoDraw(0, (Temp*1.1-Distance)*10.0/Temp);
  {if Distance<=Temp then begin
   if Distance>Temp*0.9 then DoDraw(-1, (Distance-Temp*0.9)*10.0/Temp);
   DoDraw(0, 1.0);
  end else if Distance<=Temp*2.5 then begin
   DoDraw(-1, 1.0);
   if Distance<Temp*1.1 then DoDraw(0, (Temp*1.1-Distance)*10.0/Temp);
  end else if Distance<Temp*2.6 then
   DoDraw(-1, (Temp*2.6-Distance)*10.0/Temp);}
  for I:=Children.Count-1 downto 0 do
   if Children.Obj[I].DrawDistanceChild*1.1>Distance then Children.Obj[I].Draw;
 end else begin
  with Details[0] do
   for I:=0 to GroupCount-1 do with TMeshData(MeshData.Items[I]) do if VertexCount>0 then
    Engine.Textures.DelayedLoad(Material);
 end;
end;

type
  TObjFileHeader = packed record
    ofhType: Word;
    ofhMass: Single;
    ofhAirResistance: Single;
    OnSeSemmostaJuu: array[0..247] of Byte;
    ofhName: string[64];
    ofhExtraSize: DWord;
  end;
  TObjBytes = packed record
    B: array[0..255] of Byte;
  end;

procedure TTssObject.LoadData(FileName: string);
var Data: Pointer;
begin
 inherited Create;
 Engine.ObjectFile.LoadToMemByName(FileName, Data);
 Model.Name:=ChangeFileExt(FileName, '');
 LoadFromBuffer(Data);
 FreeMem(Data);
end;

var ObjColor: array[MATTYPE_COLORED1..MATTYPE_COLORED3] of TD3DColor;

function HideTexture(const Name: string): Boolean;
const TextureNames: array[0..23] of string = ('floor_01', 'plasticmat_01',
      'plasticmat_02', 'plasticmat_03', 'roomdoors_01', 'tatamiceiling_01',
      'tatamimat_green', 'toiletfloor_01', 'toiletwall_01', 'wallpaper01',
      'wallpaper02', 'woodfloor_01', 'metalwall', 'rainpipe', 'grass_01',
      'fakestairs', 'dirtyfloor_01', 'brokenglass', 'airconditioner',
      'woodwall_dark', 'stairs_01', 'dirtypavement', 'building_base',
      'brickwall'
      );
var I: integer;
begin
 for I:=Low(TextureNames) to High(TextureNames) do
  if TextureNames[I]=Name then begin
   Result:=True;
   Exit;
  end;
 Result:=False;
end;

function TTssObject.LoadFromBuffer(Data: Pointer; Shared: Boolean = False): Pointer;
var I, J, K, Index: integer;
    P: Pointer;
    ItemCount: Word;
    VCount, ICount: integer;
    ItemType: Byte;
    DSize: DWord;
    PData: TPointerData;
    Mesh: TMeshData;
    Obj: TTssObject;
    M1, M2: TD3DXMatrix;
    Vector: TD3DXVector3;
begin
 //UnLoadData;   
 SharedBuffers:=Shared;
 if not Shared then begin
  ObjColor[MATTYPE_COLORED1]:=GetColor;
  ObjColor[MATTYPE_COLORED2]:=GetColor;
  ObjColor[MATTYPE_COLORED3]:=GetColor;
 end;
 MinPos:=MakeD3DVector(16384,16384,16384);
 MaxPos:=MakeD3DVector(-16384,-16384,-16384);

 with TObjFileHeader(Data^) do begin
  P:=Pointer(Integer(Data)+SizeOf(TObjFileHeader));
  Model.ObjType:=ofhType;
  if ofhMass>0 then begin OwnMass:=ofhMass; TotMass:=ofhMass; end;
  AirResistance:=ofhAirResistance;
  if ofhName<>'Unnamed' then Model.Name:=ofhName
   else begin

   end;
  if ofhExtraSize>0 then begin
   ExtraLoad(P, ofhExtraSize);
   Inc(Integer(P), ofhExtraSize);
  end;
 end;

 ItemCount:=Word(P^);
 Inc(Integer(P), 2);

 for I:=0 to ItemCount-1 do begin
  ItemType:=Byte(P^);
  Inc(Integer(P));
  case ItemType of
   0, 11..18, 21..28, 31..38, 100, 111..118, 121..128, 131..138: begin
       case ItemType of
        11..18, 111..118: Index:=-(ItemType mod 100-10);
        21..28, 121..128: Index:=ItemType mod 100-20;
        31..38, 131..138: Index:=ItemType mod 100-31+Low(Details);
        else Index:=0;
       end;
       if ItemType>=100 then Obj:=TTssObject.Create(Self, False)
        else Obj:=Self;
       if Index=-1 then Obj.HitStyle:=hsMeshLow1;
       with Obj.Details[Index] do begin
        MeshName:=TString32(P^);
        if Obj.Model.Name='' then Obj.Model.Name:=MeshName;
        Inc(Integer(P), 32);
        M1:=TD3DXMatrix(P^); 
        Inc(Integer(P), 64);
        if ItemType>=100 then begin
         Obj.RRot:=M1;
         Obj.RRot._41:=0; Obj.RRot._42:=0; Obj.RRot._43:=0;
         Obj.OrigRot:=Obj.RRot;
         Obj.RPos:=D3DXVector3(M1._41, M1._42, M1._43);
         Obj.OrigPos:=Obj.RPos;
         D3DXMatrixInverse(M2, nil, M1);
        end;
        if (ItemType=0) and (Parent<>nil) then begin
         RRot:=M1;
         RRot._41:=0.0;
         RRot._42:=0.0;
         RRot._43:=0.0;
         OrigRot:=RRot;
         RPos.X:=M1._41;
         RPos.Y:=M1._42;
         RPos.Z:=M1._43;
         Physics_CalculateOrientation(Self);
        end;
        GroupCount:=Word(P^);
        Inc(Integer(P), 2);
        VCount:=Word(P^);
        Inc(Integer(P), 2);
        ICount:=Word(P^);
        Inc(Integer(P), 2);

        MeshData:=TList.Create;

        if Shared then begin
         VertexCount:=VCount;
         IndexCount:=ICount;
         Inc(FParent.Details[Index].VertexCount, VCount);
         Inc(FParent.Details[Index].IndexCount, ICount);
         if FParent.Details[Index].Bits=nil then FParent.Details[Index].Bits:=TBitArray.Create(FParent.Details[Index].IndexCount div 3)
          else FParent.Details[Index].Bits.Count:=FParent.Details[Index].IndexCount div 3;
         ReAllocMem(FParent.Details[Index].Vertices, FParent.Details[Index].VertexCount*SizeOf(TObjDataVertex));
         ReAllocMem(FParent.Details[Index].Indices, FParent.Details[Index].IndexCount*SizeOf(TIndex));
         for J:=FParent.Details[Index].VertexCount-VCount to FParent.Details[Index].VertexCount-1 do with TObjBytes(P^) do begin
          if ItemType>=100 then D3DXVec3TransformCoord(FParent.Details[Index].Vertices[J].V1, D3DXVector3(Single((@B[0])^), Single((@B[4])^), Single((@B[8])^)), M2)
           else begin
            FParent.Details[Index].Vertices[J].V1.X:=Single((@B[0])^);
            FParent.Details[Index].Vertices[J].V1.Y:=Single((@B[4])^);
            FParent.Details[Index].Vertices[J].V1.Z:=Single((@B[8])^);
           end;
          FParent.Details[Index].Vertices[J].nX:=B[12];
          FParent.Details[Index].Vertices[J].nY:=B[13];
          FParent.Details[Index].Vertices[J].nZ:=B[14];
          FParent.Details[Index].Vertices[J].tU:=Word((@B[15])^);
          FParent.Details[Index].Vertices[J].tV:=Word((@B[17])^);
          FParent.Details[Index].Vertices[J].Color:=D3DCOLOR_ARGB(255, 128, 128, 128);
          MinPos.X:=Min(MinPos.X, FParent.Details[Index].Vertices[J].V1.X);
          MinPos.Y:=Min(MinPos.Y, FParent.Details[Index].Vertices[J].V1.Y);
          MinPos.Z:=Min(MinPos.Z, FParent.Details[Index].Vertices[J].V1.Z);
          MaxPos.X:=Max(MaxPos.X, FParent.Details[Index].Vertices[J].V1.X);
          MaxPos.Y:=Max(MaxPos.Y, FParent.Details[Index].Vertices[J].V1.Y);
          MaxPos.Z:=Max(MaxPos.Z, FParent.Details[Index].Vertices[J].V1.Z);
          if Model.ObjType<>1 then begin
           D3DXVec3TransformCoord(Vector, FParent.Details[Index].Vertices[J].V1, M1);
           FParent.MinPos.X:=Min(FParent.MinPos.X, Vector.X);
           FParent.MinPos.Y:=Min(FParent.MinPos.Y, Vector.Y);
           FParent.MinPos.Z:=Min(FParent.MinPos.Z, Vector.Z);
           FParent.MaxPos.X:=Max(FParent.MaxPos.X, Vector.X);
           FParent.MaxPos.Y:=Max(FParent.MaxPos.Y, Vector.Y);
           FParent.MaxPos.Z:=Max(FParent.MaxPos.Z, Vector.Z);
           FParent.Range:=Max(FParent.Range, Round(D3DXVec3Length(Vector)*1000));
          end;
          Range:=Max(Range, Round(D3DXVec3Length(FParent.Details[Index].Vertices[J].V1)*1000));
          Inc(Integer(P),19);
         end;
         CopyMemory(@FParent.Details[Index].Indices[FParent.Details[Index].IndexCount-ICount], P, ICount*2);
         for J:=FParent.Details[Index].IndexCount-ICount to FParent.Details[Index].IndexCount-1 do begin
          Inc(FParent.Details[Index].Indices[J], FParent.Details[Index].VertexCount-VCount);
         end;
         Inc(Integer(P), ICount*2);
        end else begin
         Bits:=TBitArray.Create(ICount div 3);
         VertexCount:=VCount;
         IndexCount:=ICount;
         GetMem(Vertices, VertexCount*SizeOf(TObjDataVertex));
         GetMem(Indices, IndexCount*SizeOf(TIndex));
         for J:=0 to VertexCount-1 do with TObjBytes(P^) do begin
          if ItemType>=100 then D3DXVec3TransformCoord(Vertices[J].V1, D3DXVector3(Single((@B[0])^), Single((@B[4])^), Single((@B[8])^)), M2)
           else begin
            Vertices[J].V1.X:=Single((@B[0])^);
            Vertices[J].V1.Y:=Single((@B[4])^);
            Vertices[J].V1.Z:=Single((@B[8])^);
           end;
          Vertices[J].nX:=B[12];
          Vertices[J].nY:=B[13];
          Vertices[J].nZ:=B[14];
          Vertices[J].tU:=Word((@B[15])^);
          Vertices[J].tV:=Word((@B[17])^);
          Vertices[J].Color:=D3DCOLOR_ARGB(255, 128, 128, 128);
          MinPos.X:=Min(MinPos.X, Vertices[J].V1.X);
          MinPos.Y:=Min(MinPos.Y, Vertices[J].V1.Y);
          MinPos.Z:=Min(MinPos.Z, Vertices[J].V1.Z);
          MaxPos.X:=Max(MaxPos.X, Vertices[J].V1.X);
          MaxPos.Y:=Max(MaxPos.Y, Vertices[J].V1.Y);
          MaxPos.Z:=Max(MaxPos.Z, Vertices[J].V1.Z);
          Range:=Max(Range, Round(D3DXVec3Length(Vertices[J].V1)*1000));
          Inc(Integer(P),19);
         end;
         CopyMemory(@Indices[0], P, IndexCount*2);
         Inc(Integer(P), IndexCount*2);
        end;

        for K:=0 to GroupCount-1 do begin
         Mesh:=TMeshData.Create;
         MeshData.Add(Mesh);
         with Mesh do begin
          MinPos:=MakeD3DVector(16777.216,16777.216,16777.216);
          MaxPos:=MakeD3DVector(-16777.216,-16777.216,-16777.216);
          DataIndex:=K;
          
          CopyMemory(@Material.Name, P, 32);
          Inc(Integer(P), 32);
          Material.CanHide:=HideTexture(Material.Name);
          Material.Reflection:=Byte(P^);
          Inc(Integer(P), 1);
          Material.Opacity:=Byte(P^);
          Inc(Integer(P), 1);
          Material.MatType:=Byte(P^);
          Inc(Integer(P), 1);
          Material.NoWrapU:=Boolean(P^);
          Inc(Integer(P), 1);
          Material.NoWrapV:=Boolean(P^);
          Inc(Integer(P), 1);
          StartVertex:=Word(P^);
          if Shared then Inc(StartVertex, FParent.Details[Index].VertexCount-VCount);
          Inc(Integer(P), 2);
          VertexCount:=Word(P^);
          Inc(Integer(P), 2);
          StartIndex:=Word(P^);
          if Shared then Inc(StartIndex, FParent.Details[Index].IndexCount-ICount);
          Inc(Integer(P), 2);
          IndexCount:=Word(P^);
          Inc(Integer(P), 2);

          if (Material.MatType=MATTYPE_COLORED1) or (Material.MatType=MATTYPE_COLORED2) or (Material.MatType=MATTYPE_COLORED3) then begin
           if Shared then begin
            for J:=StartVertex to StartVertex+VertexCount-1 do
             FParent.Details[Index].Vertices[J].Color:=ObjColor[Material.MatType];
           end else begin
            for J:=StartVertex to StartVertex+VertexCount-1 do
             Vertices[J].Color:=ObjColor[Material.MatType];
           end;
          end;

          if Material.Opacity<100 then begin
           PolyIndices:=AllocMem((ICount div 3)*SizeOf(TIndex));
           for J:=0 to ICount div 3-1 do
            PolyIndices[J]:=StartIndex+J*3;
          end;
         end;
        end;
       end;
   end;
   1: begin
        CopyMemory(@PData, P, SizeOf(TPointerData));
        Inc(Integer(P), SizeOf(TPointerData));
        PointerLoad(PData);
   end;
   2: begin
        DSize:=DWord(P^);
        Inc(Integer(P), 4);
        DataItemLoad(P, DSize);
        Inc(Integer(P), DSize);
   end;
   3: begin
        LightLoad(P);
        Inc(Integer(P), 27);
   end;       
   200: begin
        P:=ChildLoad(Byte(P^), P);
   end;
  end;
 end;
 if D3DXVector3Equal(MinPos, MakeD3DVector(16384,16384,16384)) then MinPos:=MakeD3DVector(0.0, 0.0, 0.0);
 if D3DXVector3Equal(MaxPos, MakeD3DVector(16384,16384,16384)) then MaxPos:=MakeD3DVector(0.0, 0.0, 0.0);
 Result:=P;
end;

procedure TTssObject.ExtraLoad(Data: Pointer; Size: Word);
begin
 // Descendant Classes only
end;

procedure TTssObject.DataItemLoad(Data: Pointer; Size: Word);
begin
 // Descendant Classes only
end;

procedure TTssObject.PointerLoad(const Data: TPointerData); // Default handler for pointer-objects
begin
 LoadPointerObj(TTssObject.Create(Self, True), Data);
end;

procedure TTssObject.LoadPointerObj(Obj: TTssObject; const Data: TPointerData);
var S: string;
begin
 with Obj do begin
  S:=Data.Name;
  Delete(S, Pos('#', S), 8);
  LoadData(S+'.obj');
  RRot:=Data.Matrix;
  RPos.X:=RRot._41;
  RPos.Y:=RRot._42;
  RPos.Z:=RRot._43;
  RRot._41:=0;
  RRot._42:=0;
  RRot._43:=0;
  OrigRot:=RRot;
 end;
end;

procedure TTssObject.LightLoad(Data: Pointer);
begin
 // Under construction...
end;

procedure TTssObject.MakeBuffers;
var N: integer;
begin
 FreeBuffers;
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
   Engine.m_pd3dDevice.CreateVertexBuffer(VertexCount*SizeOf(T3DVertex2TxColor), D3DUSAGE_WRITEONLY, D3DFVF_TSSVERTEX2TXCOLOR, D3DPOOL_DEFAULT, VB);
   Engine.m_pd3dDevice.CreateIndexBuffer(IndexCount*SizeOf(TIndex), D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_DEFAULT, IB);
 end;
 FillBuffers;
end;

procedure TTssObject.FillBuffers;
var J, N: integer;
    PVB: P3DVertex2TxColor;
    PIB: PIndex;
begin
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
   VB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
   for J:=0 to VertexCount-1 do begin
    PVB.V:=Vertices[J].V1;
    PVB.nX:=(Vertices[J].nX-128)*0.007874015748031496;
    PVB.nY:=(Vertices[J].nY-128)*0.007874015748031496;
    PVB.nZ:=(Vertices[J].nZ-128)*0.007874015748031496;
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

procedure TTssObject.UnLoadData;
var I, N: integer;
begin
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
  if not DontFree then begin
   FreeMem(Vertices);
   FreeMem(Indices);
   Bits.Free;
  end;
  for I:=0 to GroupCount-1 do with TMeshData(MeshData.Items[I]) do begin
   if VertexCount>0 then begin
    Engine.Shadows.FreeData(ShadowData);
    if Material.Opacity<100 then
     FreeMem(PolyIndices);
   end;
   Free;     
  end;
  MeshData.Free;
 end;
end;

procedure TTssObject.FreeBuffers;
var N: integer;
begin
 for N:=-DETAILS_LOW to DETAILS_HIGH do with Details[N] do if VertexCount>0 then begin
  VB:=nil;
  IB:=nil;
 end;
end;

function TTssObject.CollectGroups(const X1, Y1, Z1, Range: Single; Level: integer): Boolean;
var I, J: integer;
    V0, V1, V2: PD3DXVector3;
begin
 Result:=False;
 if (AMinPos.X<X1+Range) and (AMinPos.Y<Y1+Range) and (AMinPos.Z<Z1+Range) and (AMaxPos.X>X1-Range) and (AMaxPos.Y>Y1-Range) and (AMaxPos.Z>Z1-Range) then with Details[Level] do begin
  Bits.Clear;
  BitsFrom:=65535;
  BitsTo:=0;
  for J:=0 to MeshData.Count-1 do with TMeshData(MeshData.Items[J]) do
   if Material.Opacity<>99 then
  for I:=StartIndex div 3 to (StartIndex+IndexCount-1) div 3 do begin
   V0:=@(Vertices[Indices[I*3+0]].V2);
   V1:=@(Vertices[Indices[I*3+1]].V2);
   V2:=@(Vertices[Indices[I*3+2]].V2);
   if Min3Singles(V0.X, V1.X, V2.X)<X1+Range then
    if Min3Singles(V0.Y, V1.Y, V2.Y)<Y1+Range then
     if Min3Singles(V0.Z, V1.Z, V2.Z)<Z1+Range then
      if Max3Singles(V0.X, V1.X, V2.X)>X1-Range then
       if Max3Singles(V0.Y, V1.Y, V2.Y)>Y1-Range then
        if Max3Singles(V0.Z, V1.Z, V2.Z)>Z1-Range then begin
         Result:=True;
         if I<BitsFrom then BitsFrom:=I;
         if I>BitsTo then BitsTo:=I;
         Bits[I]:=True;
        end;
  end;
 end;
end;

{function TTssObject.GetObjects: TObjectArray;
var I: integer;
begin
 Result:=TObjectArray.Create;
 Result.SetSize(Children.Count);
 for I:=0 to Children.Count-1 do
  Result.Add(Children.Obj[I].Model.Name, Children.Obj[I]);
end;}


function TTssObjectList.GetObj(Index: integer): TTssObject;
begin
 Result:=TTssObject(Items[Index]);
end;

constructor TTssObjectList.Create(AutoFree: Boolean);
begin
 inherited Create;
 FAutoFree:=AutoFree;
end;

destructor TTssObjectList.Destroy;
var I: integer;
begin
 if FAutoFree then
  for I:=Count-1 downto 0 do
   Obj[I].Free;
 inherited;
end;

procedure TTssObject.VirtualData(AId: Cardinal; AData: Pointer; ASize: Cardinal);
begin
 OldData:=NewData;
 NewData:=AData;
end;

function TTssObject.ChildLoad(ObjType: Byte; Data: Pointer): Pointer;
var Obj: TTssObject;
begin
 Obj:=TTssObject.Create(Self, True);
 Result:=Obj.LoadFromBuffer(Data, True);
end;

procedure TTssObject.Remove;
begin
 if FRefCount=0 then FRemove:=True;
 FDisabled:=True;
end;

procedure TTssObject.SetAnimation(Value: TAnimation);
var I: integer;
begin
 if Value=FAnimation then Exit;
 FAnimation:=Value;
 for I:=0 to Children.Count-1 do
  with Children.Obj[I] do
   if Value<>nil then Track:=Value.GetTrack(Model.Name)
end;

{ TTssLink }

destructor TTssLink.Destroy;
begin
 if FObj1<>nil then Dec(FObj1.FRefCount);
 if FObj2<>nil then Dec(FObj2.FRefCount);
 inherited;
end;

procedure TTssLink.Move(TickCount: Single);
var Force: TD3DXVector3;
    ForceLength: Single;
begin
 if FObj1.Stopped and FObj2.Stopped then Exit;
 if FObj1.FDisabled or FObj2.FDisabled then begin
  Engine.Links.Remove(Self);
  Free;
  Exit;
 end;
 D3DXVec3TransformCoord(FAPos1, FRPos1, FObj1.Matrix);
 D3DXVec3TransformCoord(FAPos2, FRPos2, FObj2.Matrix);
 Force:=VectorAdd(
  VectorScale(VectorSubtract(GetMove(FObj1.PosMove, FObj1.RotMove, VectorSubtract(FAPos1, FObj1.APos), TickCount), GetMove(FObj2.PosMove, FObj2.RotMove, VectorSubtract(FAPos2, FObj2.APos), TickCount)), FStrength*0.5/(TickCount*0.001)),
  VectorScale(VectorSubtract(FAPos1, FAPos2), FStrength/(TickCount*0.001))
 );
 ForceLength:=D3DXVec3Length(Force);
 if ForceLength>FStrength*500.0 then begin
  Engine.Links.Remove(Self); //Force:=VectorScale(Force, 500000.0/ForceLength);
  Free;
  Exit;
 end;
 Physics_AddForce(FObj1, VectorInvert(Force), VectorSubtract(FAPos1, FObj1.APos));
 Physics_AddForce(FObj2, Force, VectorSubtract(FAPos2, FObj2.APos));

 if FEasyStop then begin
  if FObj1.Stopped or FObj2.Stopped then begin
   FObj1.Stopped:=True;
   FObj2.Stopped:=True;
   Engine.Links.Remove(Self);
   Free;
  end;
 end else begin
  FObj1.LastMove:=Min(FObj1.LastMove, FObj2.LastMove);
  FObj2.LastMove:=FObj1.LastMove;
  FObj1.Stopped:=FObj1.LastMove>1000.0;
  FObj2.Stopped:=FObj2.LastMove>1000.0;
 end;
end;

function TTssObject.GetColor: TD3DColor;
begin
 Result:=D3DCOLOR_ARGB(255, 128, 128, 128);
end;

procedure TTssObject.Crash(const Pos, Impact: TD3DXVector3);
var I, J: integer;
    Temp2: Single;
    Temp: integer;
begin
 Temp2:=D3DXVec3LengthSq(Impact);
 J:=0;
 for I:=Children.Count-1 downto 0 do
  with Children.Obj[I] do
   if (D3DXVec3LengthSq(VectorSubtract(APos, Pos))<Sqr(Range*0.001+Temp2*0.0025)) and (Temp2>BreakStrength*5.0) then begin
    Inc(J);
    PosMove:=GetMove(Self.PosMove, Self.RotMove, RPos, 1.0);
    PosMove.X:=PosMove.X+RPos.X*0.5-Impact.X;
    PosMove.Y:=PosMove.Y+RPos.Y*0.5+5.0-Impact.Y;
    PosMove.Z:=PosMove.Z+RPos.Z*0.5-Impact.Z;
    RotMove:=D3DXVector3((Random(2000)-1000)*0.005, (Random(2000)-1000)*0.005, (Random(2000)-1000)*0.005);
    Parent:=nil;
    Stopped:=False;
    Manual:=False;
    IgnoreObj:=True;
    Mass:=100.0;
    TotMass:=100.0;
    Track:=nil;
    FRefObject:=Self;
    Inc(Self.FRefCount);
   end;
 Temp:=0;
 if J=1 then Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Crash1, nil, False)
 else if J=2 then Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Crash2, nil, False)
 else if J>2 then Temp:=FSOUND_PlaySoundEx(FSOUND_FREE, Engine.FSounds.Crash3, nil, False);
 if J>0 then begin
  FSOUND_3D_SetAttributes(Temp, @RPos, @PosMove);
  FSOUND_SetVolume(Temp, 255);
 end;
end;

procedure TTssLink.SetObj1(const Value: TTssObject);
begin
 FObj1:=Value;
 Inc(FObj1.FRefCount);
end;

procedure TTssLink.SetObj2(const Value: TTssObject);
begin
 FObj2:=Value;
 Inc(FObj2.FRefCount);
end;

function TTssObject.Centralize: TD3DXVector3;
var I, J: integer;
begin
 Result.X:=-0.5*(MinPos.X+MaxPos.X);
 Result.Y:=-0.5*(MinPos.Y+MaxPos.Y);
 Result.Z:=-0.5*(MinPos.Z+MaxPos.Z);
 D3DXVec3Add(MinPos, MinPos, Result);
 D3DXVec3Add(MaxPos, MaxPos, Result);
 with Details[0] do
  for I:=0 to GroupCount-1 do
   with TMeshData(MeshData[I]) do
    for J:=StartVertex to StartVertex+VertexCount-1 do
     with Parent.Details[0].Vertices[J] do D3DXVec3Add(V1, V1, Result);
end;

initialization
RegisterClass(TTssLink);
end.
 