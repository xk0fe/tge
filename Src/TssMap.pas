{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Map Unit                               *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssMap;

interface

uses
  Windows, Messages, SysUtils, Classes, MMSystem, IniFiles, Math,
  Direct3D8, D3DX8, D3DApp, D3DFont, D3DUtil, DXUtil, DirectInput8, DX8DI,
  TssUtils, TssTextures, TssFiles, TssObjects, zlib, TssAlpha, Contnrs;

const
  Map_Load_Buffer = 65536;     // Bytes
  Map_MaxDistance = 125;    // Meters
  Map_ShadowLength = 0.04;
  Map_UpdateCount = 200;
  Map_UpdateSpeed = 1.0;
  Map_MaxChecksFrame = 5000;

type
  TVertexLightMap = array[0..15] of Byte;
  PLightMap = ^TLightMap;
  TLightMap = array[0..0] of TVertexLightMap;


TTLPointerHeader = packed record
  Enab1From: Byte;
  Enab1To: Byte;
  Enab2From: Byte;
  Enab2To: Byte;
  RoundLength: Byte;
end;

  TMapItem = class(TObject)
  public
    IType: Byte;
    OnList: Boolean; // Don't change to True unless it's changed back to False before any collect calls.
    LightMap: PLightMap;
    destructor Destroy; override;
  end;
  TMapItemClass = class of TMapItem;
  TStaticItem = class(TMapItem)
  public
    Name: string[31];
    Matrix: TD3DMatrix;
    MinPos: TD3DXVector3;
    MaxPos: TD3DXVector3;
    Obj: TTssObject;
    TLHeader: TTLPointerHeader;
    constructor Create; 
    destructor Destroy; override;
    procedure MakeObject;
  end;

  TTrafficLane = class;
  TTrafficLaneRec = packed record
    Lane: TTrafficLane;
    Start: Boolean;
  end;
  PTrafficLanes = ^TTrafficLanes;
  TTrafficLanes = array[0..0] of TTrafficLaneRec;
  TTrafficLane = class(TMapItem)
  public
    PCount, CCount, C2Count: integer;
    Points: PVectors;
    Connections, Connections2: PTrafficLanes;
    Length: Single;
    SpeedLimit: Single;
    RoundTime: Single;
    EnabFrom: Single;
    EnabTo: Single;
    EnabFrom2: Single;
    EnabTo2: Single;
    Walk: Boolean;
    constructor Create(Stream: TStream);
    destructor Destroy; override;
    procedure Connect(const Lane: TTrafficLane; const Start: Boolean);
    procedure Connect2(const Lane: TTrafficLane; const Start: Boolean);
    function First: TD3DXVector3;
    function Last: TD3DXVector3;
  end;

  TMapDataVertex = packed record
    V: TD3DXVector3;
    nX, nY, nZ: Byte;
    Color: DWord;
    tU, tV: Word;
  end;
  PMapDataVertices = ^TMapDataVertices;
  TMapDataVertices = array[0..0] of TMapDataVertex;
  TMapGroup = class(TMapItem)
  public
    Material: TTssMaterial;
    VertexCount: Word;
    IndexCount: Word;
    Vertices: PMapDataVertices;
    Indices: PIndices;
    Bits: TBitArray;
    BitsFrom, BitsTo: Word;
    Surfaces: PPointerList;
    DynamicBuffers: Boolean;
    NeedVertexColor: Boolean;
    MaxDistance: Byte;
    VB: IDirect3DVertexBuffer8;
    IB: IDirect3DIndexBuffer8;
    MinPos, MaxPos: TD3DXVector3;
    LastUse: integer;
    constructor Create;
    destructor Destroy; override;
    procedure MakeBuffer;
    procedure UpdateBuffer;
    procedure QuickUpdateBuffer(const t: Single);
    procedure FreeBuffer;
  end;

  TTssMap = class(TPersistent)
  private
    FFileName: string;
    MapString: string[31];
    //Items: TList;
    ToUpdate: TQueue;
    procedure LoadData(const FileName: string);
    procedure ConnectTraffic;
  public
    Groups: TList;
    Tiles: array[0..255,0..255] of TList;
    constructor Create;
    destructor Destroy; override;
    procedure Draw;
    procedure CollectItems(AList: TList; const X1, Z1, X2, Z2: Single); overload;
    procedure CollectItems(AList: TList; const X1, Z1, X2, Z2: Single; Include: TMapItemClass); overload;
    procedure CollectGroups(AList: TList; const X1, Y1, Z1, Range: Single);
    procedure CollectGroupsMap(AList: TList; const X1, Y1, Z1, Range: Single);
    procedure MakeIndividual(StaticObj: TTssObject);
    //function MakeSlideVertices(Poly: TMapPoly; NewPos: TD3DVector; Width: Single): Boolean;
  published
    property FileName: string read FFileName write LoadData;
  end;

  TTrafficLight = class(TTssObject)
  private
    Green: Boolean;
    Yellow: Boolean;
    Red: Boolean;
    GreenPos: TD3DXVector3;
    YellowPos: TD3DXVector3;
    RedPos: TD3DXVector3;
    Enab1From, Enab1To: Single;
    Enab2From, Enab2To: Single;
    RoundLength: Single;
  protected
    procedure ExtraLoad(Data: Pointer; Size: Word); override;
  public
    procedure Draw; override;
  end;

implementation

uses
  TssEngine, TssPhysics;

var FFirstFrame: Boolean;

constructor TMapGroup.Create;
begin
 inherited;
 MinPos:=D3DXVector3(16384, 16384, 16384);
 MaxPos:=D3DXVector3(0, 0, 0);
 IType:=0;
 Bits:=TBitArray.Create;
end;

destructor TMapGroup.Destroy;
begin
 if Vertices<>nil then FreeMem(Vertices);
 if Indices<>nil then FreeMem(Indices);
 if Surfaces<>nil then FreeMem(Surfaces);
 Bits.Free;
 FreeBuffer;
 inherited;
end;

procedure TMapGroup.UpdateBuffer;
var PVB: P3DVertex2TxColor;
    I: integer;
    Vector: TD3DXVector3;
    Lightness: Single;
begin
 D3DXVec3Normalize(Vector, Engine.Sky.SunPos);
 VB.Lock(0, 0, PByte(PVB), 0);
 for I:=0 to VertexCount-1 do begin
  if LightMap<>nil then Lightness:=(
   LightMap[I][Floor(Engine.GameTime*16-0.5) and $F]*(1+Floor(Engine.GameTime*16-0.5)-Engine.GameTime*16)+
   LightMap[I][Ceil(Engine.GameTime*16-0.5) and $F]*(Engine.GameTime*16-Floor(Engine.GameTime*16-0.5))+
   LightMap[I][Floor(Engine.GameTime*16+0.5) and $F]*(1+Floor(Engine.GameTime*16+0.5)-Engine.GameTime*16)+
   LightMap[I][Ceil(Engine.GameTime*16+0.5) and $F]*(Engine.GameTime*16-Floor(Engine.GameTime*16+0.5))
  )/512
   else Lightness:=Max(0.0, D3DXVec3Dot(PVB.N, Vector));
  Vertices[I].Color:=D3DCOLOR_ARGB(Vertices[I].Color shr 24, Min(255, Round(Lightness*256*Engine.Sky.Light.Diffuse.R)+(Engine.AmbientLight shr 16) and $000000FF),
                                   Min(255, Round(Lightness*256*Engine.Sky.Light.Diffuse.G)+(Engine.AmbientLight shr 8) and $000000FF),
                                   Min(255, Round(Lightness*256*Engine.Sky.Light.Diffuse.B)+Engine.AmbientLight and $000000FF));
  PVB.Color:=Vertices[I].Color;
  Inc(PVB);
 end;
 VB.Unlock;
end;

procedure TMapGroup.QuickUpdateBuffer(const t: Single);
var PVB: P3DVertex2TxColor;
    I: integer;
begin
 VB.Lock(0, 0, PByte(PVB), 0);
 for I:=0 to VertexCount-1 do begin
  PVB.Color:=BlendColor(PVB.Color, Vertices[I].Color, t);
  Inc(PVB);
 end;
 VB.Unlock;
end;

procedure TMapGroup.MakeBuffer;
var PVB: P3DVertex2TxColor;
    PIB: PIndex;
    I: integer;
    Vector: TD3DXVector3;
    Lightness: Single;
begin
 FreeBuffer;
 if DynamicBuffers then begin
  Engine.m_pd3dDevice.CreateVertexBuffer(VertexCount*SizeOf(T3DVertex2TxColor), D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX2TXCOLOR, D3DPOOL_DEFAULT, VB);
  Engine.m_pd3dDevice.CreateIndexBuffer(IndexCount*SizeOf(TIndex), D3DUSAGE_DYNAMIC, D3DFMT_INDEX16, D3DPOOL_DEFAULT, IB);
 end else begin
  Engine.m_pd3dDevice.CreateVertexBuffer(VertexCount*SizeOf(T3DVertex2TxColor), D3DUSAGE_WRITEONLY, D3DFVF_TSSVERTEX2TXCOLOR, D3DPOOL_DEFAULT, VB);
  Engine.m_pd3dDevice.CreateIndexBuffer(IndexCount*SizeOf(TIndex), D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_DEFAULT, IB);
 end;
 D3DXVec3Normalize(Vector, Engine.Sky.SunPos);
 VB.Lock(0, 0, PByte(PVB), 0);
 for I:=0 to VertexCount-1 do begin
  PVB.V:=Vertices[I].V;
  PVB.nX:=(Vertices[I].nX-128)*0.007874015748031496; // 8bit -> 32bit
  PVB.nY:=(Vertices[I].nY-128)*0.007874015748031496;
  PVB.nZ:=(Vertices[I].nZ-128)*0.007874015748031496;
  if LightMap<>nil then Lightness:=(
   LightMap[I][Floor(Engine.GameTime*16-0.5) and $F]*(1+Floor(Engine.GameTime*16-0.5)-Engine.GameTime*16)+
   LightMap[I][Ceil(Engine.GameTime*16-0.5) and $F]*(Engine.GameTime*16-Floor(Engine.GameTime*16-0.5))+
   LightMap[I][Floor(Engine.GameTime*16+0.5) and $F]*(1+Floor(Engine.GameTime*16+0.5)-Engine.GameTime*16)+
   LightMap[I][Ceil(Engine.GameTime*16+0.5) and $F]*(Engine.GameTime*16-Floor(Engine.GameTime*16+0.5))
  )/512
   else Lightness:=Max(0.0, D3DXVec3Dot(PVB.N, Vector));

  Vertices[I].Color:=D3DCOLOR_ARGB(Vertices[I].Color shr 24, Min(255, Round(2*((Vertices[I].Color shr 16) and $FF)*Lightness*Engine.Sky.Light.Diffuse.R)+(Engine.AmbientLight shr 16) and $000000FF),
                                   Min(255, Round(2*((Vertices[I].Color shr 8) and $FF)*Lightness*Engine.Sky.Light.Diffuse.G)+(Engine.AmbientLight shr 8) and $000000FF),
                                   Min(255, Round(2*(Vertices[I].Color and $FF)*Lightness*Engine.Sky.Light.Diffuse.B)+Engine.AmbientLight and $000000FF));
  PVB.Color:=Vertices[I].Color;
  PVB.tU1:=(Vertices[I].tU-32768)*0.0078125; // 16bit -> 32bit
  PVB.tV1:=(Vertices[I].tV-32768)*0.0078125; 
  PVB.tU2:=(Vertices[I].tU-32768)*0.0078125*8; //Detail-texture coordinates
  PVB.tV2:=(Vertices[I].tV-32768)*0.0078125*8; // -- || --
  Inc(PVB);
 end;
 VB.Unlock;
 IB.Lock(0, 0, PByte(PIB), 0);
 CopyMemory(PIB, @(Indices[0]), IndexCount*2);
 IB.Unlock;
end;

procedure TMapGroup.FreeBuffer;
begin
 VB:=nil;
 IB:=nil;
end;

{ TTrafficLane }

type
  TTssTrafficHeader = packed record
    Count: Word;
    SpeedLimit: Byte;
    EnabFrom: Byte;
    EnabTo: Byte;
    RoundLength: Byte;
    Walk: ByteBool;
    EnabFrom2: Byte;
    EnabTo2: Byte;
    Reserved: array[0..6] of Byte;
  end;
procedure TTrafficLane.Connect(const Lane: TTrafficLane; const Start: Boolean);
begin
 ReAllocMem(Connections, (CCount+1)*SizeOf(TTrafficLaneRec));
 Connections[CCount].Lane:=Lane;
 Connections[CCount].Start:=Start;
 Inc(CCount);
end;

procedure TTrafficLane.Connect2(const Lane: TTrafficLane; const Start: Boolean);
begin
 ReAllocMem(Connections2, (C2Count+1)*SizeOf(TTrafficLaneRec));
 Connections2[C2Count].Lane:=Lane;
 Connections2[C2Count].Start:=Start;
 Inc(C2Count);
end;

function TTrafficLane.First: TD3DXVector3;
begin
 Result:=Points[0];
end;

function TTrafficLane.Last: TD3DXVector3;
begin
 Result:=Points[PCount-1];
end;

constructor TTrafficLane.Create(Stream: TStream);
var Header: TTssTrafficHeader;
    I: integer;
    Tile: TList;
begin
 IType:=2;
 Stream.Read(Header, SizeOf(Header));
 SpeedLimit:=Header.SpeedLimit/3.6;
 RoundTime:=Header.RoundLength;
 EnabFrom:=Header.EnabFrom;
 EnabTo:=Header.EnabTo;
 EnabFrom2:=Header.EnabFrom2;
 EnabTo2:=Header.EnabTo2;
 PCount:=Header.Count;
 Walk:=Header.Walk;
 CCount:=0;
 Points:=AllocMem(PCount*SizeOf(TD3DXVector3));
 Stream.Read(Points[0], PCount*SizeOf(TD3DXVector3));
 for I:=0 to PCount-1 do begin
  Tile:=Engine.Map.Tiles[Floor(Points[I].X/64) and $FF, Floor(Points[I].Z/64) and $FF];
  if Tile.Count>0 then if Tile.Last<>Self then Tile.Add(Self);
 end;
 Length:=0.0;
 for I:=1 to PCount-1 do
  Length:=Length+D3DXVec3Length(VectorSubtract(Points[I], Points[I-1]));
end;

destructor TTrafficLane.Destroy;
begin
 FreeMem(Points);
 FreeMem(Connections);
 FreeMem(Connections2);
 inherited;
end;

constructor TStaticItem.Create;
begin
 inherited;
 IType:=1;
end;

destructor TStaticItem.Destroy;
begin
 if Obj<>nil then Obj.Free;
 inherited;
end;

procedure TStaticItem.MakeObject;
var S: string;
    I: integer;  //V: TD3DXVector3;
begin
 if Obj<>nil then Obj.Free;
 if TLHeader.RoundLength>0 then begin
  Obj:=TTrafficLight.Create(nil, False);
  TTrafficLight(Obj).Enab1From:=TLHeader.Enab1From;
  TTrafficLight(Obj).Enab1To:=TLHeader.Enab1To;
  TTrafficLight(Obj).Enab2From:=TLHeader.Enab2From;
  TTrafficLight(Obj).Enab2To:=TLHeader.Enab2To;
  TTrafficLight(Obj).RoundLength:=TLHeader.RoundLength;
 end else Obj:=TTssObject.Create(nil, False);
 S:=Name;
 I:=Pos('#', S);
 if I>0 then Delete(S, I, Length(S)-I+1);
 Obj.LoadData(S+'.obj');
 if (Copy(Name, 1, 6)='sidead') or (Copy(Name, 1, 7)='frontad') or (S='maintrafficlightrail') then Obj.DrawDistance:=150.0
  else Obj.DrawDistance:=Min(300.0, Sqrt((Obj.MaxPos.X-Obj.MinPos.X)*(Obj.MaxPos.Y-Obj.MinPos.Y)*(Obj.MaxPos.Z-Obj.MinPos.Z))*20.0+50.0);
 Obj.DrawDistanceChild:=Obj.DrawDistance;
 Obj.Model.Name:=Name;
 Obj.PPointer:=Self;
 Obj.HitStyle:=hsMesh;
 Obj.Static:=True;
 Obj.Stopped:=True;
 Obj.DrawNeedsConfirmation:=True;
 Obj.RRot:=Matrix;
 Obj.RPos.X:=Obj.RRot._41; Obj.RRot._41:=0;
 Obj.RPos.Y:=Obj.RRot._42; Obj.RRot._42:=0;
 Obj.RPos.Z:=Obj.RRot._43; Obj.RRot._43:=0;
 {if (S='crosswalktrafficlight') and (strtointdef(Copy(Name, I+1, 2), 0) in TurnThese) then begin
  D3DXVec3TransformCoord(V, D3DXVector3(0.0, 0.0, 2.0), Obj.RRot);
  Obj.RPos:=VectorAdd(Obj.RPos, V);
 end;}
 Obj.OrigPos:=Obj.RPos;
 Obj.CollDetails:=@Obj.Details[0];
 Physics_CalculateVertices(Obj, 0, nil);
 for I:=0 to Obj.Children.Count-1 do begin
  Physics_CalculateVertices(Obj.Children[I], 0, nil);
  if Copy(Obj.Children.Obj[I].Name, 1, 3)='top' then Obj.Children.Obj[I].DrawDistance:=Obj.DrawDistance
  else if Copy(Obj.Children.Obj[I].Name, 1, 4)='door' then Obj.Children.Obj[I].DrawDistance:=Obj.DrawDistance*0.5
  else Obj.Children.Obj[I].DrawDistance:=Obj.Range*0.002;
  //with Obj.Children.Obj[I] do DrawDistance:=Sqrt((MaxPos.X-MinPos.X)*(MaxPos.Y-MinPos.Y)*(MaxPos.Z-MinPos.Z))*6.0+40.0;
  Obj.Children.Obj[I].DrawDistanceChild:=Obj.Children.Obj[I].DrawDistance;
 end;
end;

constructor TTssMap.Create;
var I, J: integer;
begin
 inherited Create;
 //Items:=TList.Create;
 Groups:=TList.Create;
 ToUpdate:=TQueue.Create;
 for I:=0 to 255 do
  for J:=0 to 255 do
   Tiles[I,J]:=TList.Create;
end;

destructor TTssMap.Destroy;
var I, J: integer;
begin
 for I:=0 to 255 do
  for J:=0 to 255 do
   Tiles[I,J].Free;
 //for I:=0 to Items.Count-1 do
 // TMapItem(Items.Items[I]).Free;
 //Items.Free;
 for I:=0 to Groups.Count-1 do
  TMapItem(Groups.Items[I]).Free;
 Groups.Free;
 ToUpdate.Free;
 inherited Destroy;
end;

{function MapPolySortAlpha(Item1, Item2: Pointer): Integer;
begin
 Result:=Ord(TMapPoly(Item1).Style=3)-Ord(TMapPoly(Item2).Style=3);
end;}

function MapGroupsSortAlpha(Item1, Item2: Pointer): Integer;
begin
 if TMapItem(Item1).IType=0 then Result:=Ord(TMapGroup(Item1).Material.Opacity=98)*2
  else Result:=1;
 if TMapItem(Item2).IType=0 then Result:=Result-Ord(TMapGroup(Item2).Material.Opacity=98)*2
  else Result:=Result-1;
 {if Result=0 then
  if (TMapItem(Item1).IType=0) and (TMapItem(Item2).IType=0) then
   Result:=Cardinal(TMapGroup(Item1).Material.Texture)-Cardinal(TMapGroup(Item2).Material.Texture);}
 //if (TMapItem(Item1).IType=0) and (TMapItem(Item2).IType=0) then Result:=Ord(TMapGroup(Item1).Material.Opacity=98)-Ord(TMapGroup(Item2).Material.Opacity=98)
 // else Result:=(TMapItem(Item1).IType-TMapItem(Item2).IType);
end;
procedure TTssMap.Draw;
var MinX, MinZ, MaxX, MaxZ: integer;
    CornerInView: array[0..24,0..24] of Boolean;
 procedure CalculateCorners;
 var X, Z: integer;
     X2, Z2: Single;
     V1, V2, V3: TD3DVector;
 begin
  for X:=0 to MaxX-MinX do
   for Z:=0 to MaxZ-MinZ do if (X>=0) and (Z>=0) and (X<=24) and (Z<=24) then begin
    CornerInView[X,Z]:=False;
    X2:=(MinX+X)*64;
    Z2:=(MinZ+Z)*64;
    if (Engine.Camera.Pos.X>X2-64) and (Engine.Camera.Pos.X<X2+64) and (Engine.Camera.Pos.Z>Z2-64) and (Engine.Camera.Pos.Z<Z2+64) then CornerInView[X,Z]:=True;
    if not CornerInView[X,Z] then begin
     D3DXVec3Normalize(V1, MakeD3DVector(X2-Engine.Camera.Pos.X,0,Z2-Engine.Camera.Pos.Z));
     D3DXVec3Normalize(V2, MakeD3DVector(X2-Engine.Camera.Pos.X-Engine.Camera.Vectors2[0].X*Map_MaxDistance*Options.VisibleDepth,0,Z2-Engine.Camera.Pos.Z-Engine.Camera.Vectors2[0].Z*Map_MaxDistance*Options.VisibleDepth));
     D3DXVec3Normalize(V3, MakeD3DVector(X2-Engine.Camera.Pos.X-Engine.Camera.Vectors2[1].X*Map_MaxDistance*Options.VisibleDepth,0,Z2-Engine.Camera.Pos.Z-Engine.Camera.Vectors2[1].Z*Map_MaxDistance*Options.VisibleDepth));
     if Abs(ArcSin(V1.X*V2.X+V1.Z*V2.Z)+ArcSin(V2.X*V3.X+V2.Z*V3.Z)+ArcSin(V3.X*V1.X+V3.Z*V1.Z)+g_PI_DIV_2)<=0.0001 then CornerInView[X,Z]:=True;
    end;
    if not CornerInView[X,Z] then begin
     D3DXVec3Normalize(V2, MakeD3DVector(X2-Engine.Camera.Pos.X-Engine.Camera.Vectors2[2].X*Map_MaxDistance*Options.VisibleDepth*0.1,0,Z2-Engine.Camera.Pos.Z-Engine.Camera.Vectors2[2].Z*Map_MaxDistance*Options.VisibleDepth*0.1));
     if Abs(ArcSin(V1.X*V2.X+V1.Z*V2.Z)+ArcSin(V2.X*V3.X+V2.Z*V3.Z)+ArcSin(V3.X*V1.X+V3.Z*V1.Z)+g_PI_DIV_2)<=0.0001 then CornerInView[X,Z]:=True;
    end;
    if not CornerInView[X,Z] then begin
     D3DXVec3Normalize(V3, MakeD3DVector(X2-Engine.Camera.Pos.X-Engine.Camera.Vectors2[3].X*Map_MaxDistance*Options.VisibleDepth*0.1,0,Z2-Engine.Camera.Pos.Z-Engine.Camera.Vectors2[3].Z*Map_MaxDistance*Options.VisibleDepth*0.1));
     if Abs(ArcSin(V1.X*V2.X+V1.Z*V2.Z)+ArcSin(V2.X*V3.X+V2.Z*V3.Z)+ArcSin(V3.X*V1.X+V3.Z*V1.Z)+g_PI_DIV_2)<=0.0001 then CornerInView[X,Z]:=True;
    end;
    if not CornerInView[X,Z] then begin  
     D3DXVec3Normalize(V2, MakeD3DVector(X2-Engine.Camera.Pos.X-Engine.Camera.Vectors2[0].X*Map_MaxDistance*Options.VisibleDepth,0,Z2-Engine.Camera.Pos.Z-Engine.Camera.Vectors2[0].Z*Map_MaxDistance*Options.VisibleDepth));
     if Abs(ArcSin(V1.X*V2.X+V1.Z*V2.Z)+ArcSin(V2.X*V3.X+V2.Z*V3.Z)+ArcSin(V3.X*V1.X+V3.Z*V1.Z)+g_PI_DIV_2)<=0.0001 then CornerInView[X,Z]:=True;
    end;
   end;
 end;
 function BlockInView(X, Z: integer): Boolean;
 begin
  Result:=False;
  Result:=Result or CornerInView[X-MinX,Z-MinZ];
  Result:=Result or CornerInView[X-MinX,Z-MinZ+1];
  Result:=Result or CornerInView[X-MinX+1,Z-MinZ];
  Result:=Result or CornerInView[X-MinX+1,Z-MinZ+1];
 end;
 procedure CollectItemsView(AList: TList);
 var X, Z, N: integer;
 begin
  for X:=MinX to MaxX do
   for Z:=MinZ to MaxZ do
    if BlockInView(X,Z) then with Tiles[X,Z] do
     for N:=0 to Count-1 do begin
      if Items[N]<>nil then
      if not TMapItem(Items[N]).OnList then begin
       AList.Add(Items[N]);
       TMapItem(Items[N]).OnList:=True;
      end;
     end;
  for N:=0 to AList.Count-1 do
   TMapItem(AList.Items[N]).OnList:=False;
 end;
var I, J: integer;
    List: TList;
    TempV: array[0..255] of T3DVertexColor;
    DoDraw{, Updated}: Boolean;
    Vector, Vector2: TD3DXVector3;
    Temp1, Temp2: Single;
    //Group: TMapGroup;
begin
 try
 //for I:=0 to Groups.Count-1 do
 // if TMapItem(Groups.Items[I]) is TMapGroup then Engine.Textures.FastLoad(TMapGroup(Groups.Items[I]).Material);
 D3DXVec3TransformCoord(Vector2, D3DXVector3(0.0, 0.0, Options.VisibleDepth*Map_MaxDistance*0.6), Engine.Camera.Rot);
 Vector2.X:=Vector2.X+Engine.Camera.Pos.X; Vector2.Y:=Vector2.Y+Engine.Camera.Pos.Y; Vector2.Z:=Vector2.Z+Engine.Camera.Pos.Z;

 {CollectItems(List, Engine.Player.APos.X-Map_MaxDistance, Engine.Player.APos.Z-Map_MaxDistance, Engine.Player.APos.X+Map_MaxDistance, Engine.Player.APos.Z+Map_MaxDistance);
 for I:=0 to List.Count-1 do
  if TMapItem(List.Items[I]).IType=1 then with TStaticItem(List.Items[I]) do
   if Obj=nil then MakeObject;}

 with Engine.Camera do begin
  MinX:=Max(Round(Min(Pos.X,Pos.X+Map_MaxDistance*Options.VisibleDepth*Min(Min(Vectors2[0].X,Vectors2[1].X),Min(Vectors2[2].X*0.1,Vectors2[3].X*0.1)))*1024) div 65536,0);
  MinZ:=Max(Round(Min(Pos.Z,Pos.Z+Map_MaxDistance*Options.VisibleDepth*Min(Min(Vectors2[0].Z,Vectors2[1].Z),Min(Vectors2[2].Z*0.1,Vectors2[3].Z*0.1)))*1024) div 65536,0);
  MaxX:=Min(Round(Max(Pos.X,Pos.X+Map_MaxDistance*Options.VisibleDepth*Max(Max(Vectors2[0].X,Vectors2[1].X),Max(Vectors2[2].X*0.1,Vectors2[3].X*0.1)))*1024) div 65536,255);
  MaxZ:=Min(Round(Max(Pos.Z,Pos.Z+Map_MaxDistance*Options.VisibleDepth*Max(Max(Vectors2[0].Z,Vectors2[1].Z),Max(Vectors2[2].Z*0.1,Vectors2[3].Z*0.1)))*1024) div 65536,255);
 end;
 CalculateCorners;

 Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, Ord(D3DCULL_CCW));

 {List.Sort(MapPolySortAlpha);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 0);
 if Options.UseMultiTx then begin
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_TEXCOORDINDEX, 1);    
  Engine.m_pd3dDevice.SetTexture(1, Engine.Textures.Texture[5,0]);
  //Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_BLENDFACTORALPHA);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAARG2, D3DTA_CURRENT);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(128, 0, 0, 0));
 end;
 for I:=0 to List.Count-1 do
  with TMapPoly(List.Items[I]) do if VertexCount>=3 then begin
   Engine.SetTexture(txPack, txIndex);
   if Style=3 then
    if not Alpha then begin
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
     Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, 0);
     Alpha:=True;
    end;
   //if PolyType=1 then Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_BLENDFACTORALPHA);
   //if PolyType=1 then Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
   if VB=nil then MakeBuffer;         
   Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex2Tx));
   Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TX);
   Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, VertexCount-2);
   Engine.IncPolyCounter(VertexCount-2);
   //if PolyType=1 then Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);
  end;}
 //List.Clear;
 //Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, 1);
 //Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE)
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);;   
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Min(160, Round(Engine.Sky.SunPos.Y*128+128))*65793);
 Engine.m_pd3dDevice.LightEnable(0, False);
 if FFirstFrame then List:=Groups
  else begin
   List:=TList.Create;
   CollectItemsView(List);
   List.Sort(MapGroupsSortAlpha);
  end;
 Temp1:=0;
 Temp2:=0;
 //Updated:=False;
 for I:=0 to List.Count-1 do
  case TMapItem(List.Items[I]).IType of
   0: with TMapGroup(List.Items[I]) do if (IndexCount>=3) and (Material.MatType<>MATTYPE_INVISIBLE) then begin
       DoDraw:=True;
       if MaxDistance>0 then begin
        Vector:=D3DXVector3(MinPos.X*0.5+MaxPos.X*0.5, MinPos.Y*0.5+MaxPos.Y*0.5, MinPos.Z*0.5+MaxPos.Z*0.5);
        Temp1:=D3DXVec3LengthSq(VectorSubtract(Vector, Engine.Camera.Pos));
        Temp2:=Sqr(MaxDistance*Map_MaxDistance*0.01*Options.VisibleDepth)+D3DXVec3LengthSq(VectorSubtract(MinPos, MaxPos))*0.5;
        if Temp1>Temp2 then DoDraw:=False;
       end;
       if DoDraw then begin                                        
        if NeedVertexColor then begin
         Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENTMATERIALSOURCE, D3DMCS_COLOR1);
         Engine.m_pd3dDevice.SetRenderState(D3DRS_DIFFUSEMATERIALSOURCE, D3DMCS_COLOR1);
        end else begin
         Engine.m_pd3dDevice.SetRenderState(D3DRS_DIFFUSEMATERIALSOURCE, D3DMCS_MATERIAL);
         Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENTMATERIALSOURCE, D3DMCS_COLOR1);
        end;
        if Material.MatType=MATTYPE_NONEUP then begin
         Engine.Textures.SetMaterial(Material, 0);
         if Material.Opacity=98 then begin
          Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
          if (MaxDistance>0) and (Temp1/Temp2>0.6) then begin
           Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TFACTOR);
           Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round(220-(Temp1/Temp2-0.6)*550), 255, 255, 255));
          end else Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
         end;
         Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXCOLOR);
         for J:=0 to Min(255, VertexCount-1) do begin
          TempV[J].V:=Vertices[J].V;
          TempV[J].vN:=D3DXVector3((Vertices[J].nX-128)*0.007874015748031496, (Vertices[J].nY-128)*0.007874015748031496, (Vertices[J].nZ-128)*0.007874015748031496);
          TempV[J].Color:=Vertices[J].Color;
          TempV[J].tU:=(Vertices[J].tU-32768)*0.0078125;
          TempV[J].tV:=(Vertices[J].tV-32768)*0.0078125;
         end;
         Engine.m_pd3dDevice.DrawIndexedPrimitiveUP(D3DPT_TRIANGLELIST, 0, Min(256, VertexCount), IndexCount div 3, Indices^, D3DFMT_INDEX16, TempV, SizeOf(T3DVertexColor));
         Engine.IncPolyCounter(IndexCount div 3);
         if Material.Opacity=98 then begin
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
         end;         
        end else begin
         Material.NoEffects:=not ((MinPos.X<Engine.Camera.Pos.X+50) and (MinPos.Y<Engine.Camera.Pos.Y+50) and (MinPos.Z<Engine.Camera.Pos.Z+50) and (MaxPos.X>Engine.Camera.Pos.X-50) and (MaxPos.Y>Engine.Camera.Pos.Y-50) and (MaxPos.Z>Engine.Camera.Pos.Z-50));
         Engine.Textures.SetMaterial(Material, 0);
         if Material.Opacity=98 then begin
          Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);          
          Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
          if (MaxDistance>0) and (Temp1/Temp2>0.6) then begin
           Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TFACTOR);
           Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round(220-(Temp1/Temp2-0.6)*550), 255, 255, 255));
          end else Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
         end;
         if VB=nil then begin
          MakeBuffer;
          //ToUpdate.Push(List.Items[I]);
         end;
         {if (not Updated) and (CurrentVertex<VertexCount) and (not NeedVertexColor) then begin
          //UpdateBuffer;
          Updated:=True;
         end;}
         {if Sqr(Max(0, Engine.Uptime-LastUse)*0.001*Map_UpdateSpeed)>Sqr(Min(MinPos.X-Engine.Player.TopObj.APos.X, MaxPos.X-Engine.Player.TopObj.APos.X))+Sqr(Min(MinPos.Z-Engine.Player.TopObj.APos.Z, MaxPos.X-Engine.Player.TopObj.APos.Z)) then begin
          UpdateBuffer;
          LastUse:=Engine.Uptime+Random(1000);
         end;}
         Engine.Lights.EnableLights(MinPos, MaxPos);
         Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex2TxColor));
         Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TXCOLOR);
         Engine.m_pd3dDevice.SetIndices(IB, 0);
         Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, VertexCount, 0, IndexCount div 3);
         Engine.IncPolyCounter(IndexCount div 3);
         if Material.Opacity=98 then begin
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
          Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
          Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
         end;
        end;
       end;
      end;
   1: with TStaticItem(List.Items[I]) do begin
       {Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
       Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
       Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
       Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);}
       if Obj=nil then MakeObject;
       if D3DXVec3LengthSq(VectorSubtract(Obj.RPos, Vector2))<=Sqr(Options.VisibleDepth*Map_MaxDistance*0.6+Obj.Range*0.001) then begin
        Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENTMATERIALSOURCE, D3DMCS_MATERIAL);
        Engine.m_pd3dDevice.SetRenderState(D3DRS_DIFFUSEMATERIALSOURCE, D3DMCS_COLOR1);
        Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
        Engine.m_pd3dDevice.LightEnable(0, True);
        if Obj.Model.ObjType=100 then Obj.CalculateWind(Engine.TickCount);
        Obj.DrawNow:=True;
        Obj.Draw;
        Engine.m_pd3dDevice.LightEnable(0, False);
        Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Min(160, Round(Engine.Sky.SunPos.Y*128+128))*65793);
       end;
      end;
  end;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENTMATERIALSOURCE, D3DMCS_COLOR1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_DIFFUSEMATERIALSOURCE, D3DMCS_COLOR1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
 Engine.m_pd3dDevice.LightEnable(0, True);
 {for I:=0 to List.Count-1 do
  case TMapItem(List.Items[I]).IType of
   1: with TStaticItem(List.Items[I]) do begin
        if Obj=nil then MakeObject;
        Obj.DrawNow:=True;
        Obj.Draw;
      end;
  end;}
 if not FFirstFrame then List.Free;

 {if (not Updated) and (ToUpdate.Count>0) then begin
  Group:=TMapGroup(ToUpdate.Pop);
  if Sqr(Min(Group.MinPos.X-Engine.Player.TopObj.APos.X, Group.MaxPos.X-Engine.Player.TopObj.APos.X))
    +Sqr(Min(Group.MinPos.Z-Engine.Player.TopObj.APos.Z, Group.MaxPos.X-Engine.Player.TopObj.APos.Z))
    > Sqr(250.0) then begin
   Group.FreeBuffer;
   Group.CurrentVertex:=0;
  end else begin
   if (Group.CurrentVertex=Group.VertexCount) and (not Group.NeedVertexColor) then begin
    Group.CurrentVertex:=0;
    //Group.UpdateBuffer;
   end;
   ToUpdate.Push(Group);
  end;
 end;}

 {Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);}
 FFirstFrame:=False;
 except
  on Exception do
   raise Exception.Create('No nyt se otti ja kaatu. Saatana perkele! (MapDraw)');
 end;
end;

procedure TTssMap.LoadData(const FileName: string);
var SrcStream: TFileStream;
    Stream: TDecompressionStream;

    ItemCount: DWord;
    ItemType: Byte;

    I, J: integer;

    Group: TMapGroup;
    MapItem: TMapItem;
    Item: TStaticItem;

    TileCount: Word;
    Buffer: array[0..65535] of Byte;
begin
 for I:=0 to 255 do
  for J:=0 to 255 do
   Tiles[I,J].Clear;
 for I:=0 to Groups.Count-1 do
  TMapItem(Groups.Items[I]).Free;
 Groups.Clear;

 FFileName:=Engine.FilePath+'Data\'+FileName;
 Stream:=nil;
 SrcStream:=TFileStream.Create(FFileName, fmOpenRead);
 try
  SrcStream.Read(MapString, 32);
  SrcStream.Read(ItemCount, 4);
  Stream:=TDecompressionStream.Create(SrcStream);
  for I:=0 to ItemCount-1 do begin
   Stream.Read(ItemType, 1);
   case ItemType of
    0: begin // Polygon Group
        Group:=TMapGroup.Create;
        Group.IType:=0;
        Stream.Read(Group.Material.Name, 32);
        Stream.Read(Group.Material.DetailNm, 32);
        Stream.Read(Buffer, 9);
        Group.Material.SurfaceType:=Buffer[0];
        Group.Material.SurfaceGrassDensity:=Buffer[1];
        Group.Material.SurfaceObjDensity:=Buffer[2];
        Group.Material.MatType:=Buffer[3];
        if (Group.Material.MatType>=128) and (Group.Material.MatType<254) then Group.Material.MatType:=0;
        Group.Material.CanHide:=Buffer[4]>0;
        Group.Material.BumpHorz:=Buffer[5];
        Group.Material.BumpVert:=Buffer[6];
        Group.Material.NoWrapU:=Boolean(Buffer[7]);
        Group.Material.NoWrapV:=Boolean(Buffer[8]);
        Stream.Read(Group.VertexCount, 4); // This reads also IndexCount
        Group.Vertices:=AllocMem(Group.VertexCount*SizeOf(TMapDataVertex));
        Group.Indices:=AllocMem(Group.IndexCount*SizeOf(TIndex));
        Group.Bits.Count:=Group.IndexCount div 3;
        Stream.Read(Group.Vertices[0], Group.VertexCount*SizeOf(TMapDataVertex));
        Stream.Read(Group.Indices[0], Group.IndexCount*SizeOf(TIndex));
        Stream.Read(TileCount, 2);
        Stream.Read(Buffer, TileCount*2);
        Groups.Add(Group);
        for J:=0 to TileCount-1 do
         Tiles[Buffer[J*2+0], Buffer[J*2+1]].Add(Group);
        for J:=0 to Group.VertexCount-1 do begin
         if Group.Vertices[J].V.X<Group.MinPos.X then Group.MinPos.X:=Group.Vertices[J].V.X;
         if Group.Vertices[J].V.Y<Group.MinPos.Y then Group.MinPos.Y:=Group.Vertices[J].V.Y;
         if Group.Vertices[J].V.Z<Group.MinPos.Z then Group.MinPos.Z:=Group.Vertices[J].V.Z;
         if Group.Vertices[J].V.X>Group.MaxPos.X then Group.MaxPos.X:=Group.Vertices[J].V.X;
         if Group.Vertices[J].V.Y>Group.MaxPos.Y then Group.MaxPos.Y:=Group.Vertices[J].V.Y;
         if Group.Vertices[J].V.Z>Group.MaxPos.Z then Group.MaxPos.Z:=Group.Vertices[J].V.Z;
        end;
       end;
    1: begin // Pointer
        Item:=TStaticItem.Create;    
        Item.IType:=1;
        Item.TLHeader.RoundLength:=0;
        Stream.Read(Item.Name, 120);
        Stream.Read(TileCount, 2);
        Stream.Read(Buffer, TileCount*2);
        Groups.Add(Item);
        for J:=0 to TileCount-1 do
         Tiles[Buffer[J*2+0], Buffer[J*2+1]].Add(Item);
       end;
    2: begin // Lightmap
        Stream.Read(Buffer, 8);
        MapItem:=Groups.Items[PCardinal(@Buffer[0])^];
        MapItem.LightMap:=AllocMem(PCardinal(@Buffer[4])^*16);
        Stream.Read(MapItem.LightMap^, PCardinal(@Buffer[4])^*16);
       end;
    3: begin // Traffic Lane Info
        Groups.Add(TTrafficLane.Create(Stream));
       end;
    10: begin // Trafficlight Pointer
        Item:=TStaticItem.Create;
        Item.IType:=1;
        Stream.Read(Item.Name, 120);
        Stream.Read(Item.TLHeader, SizeOf(Item.TLHeader));
        Stream.Read(TileCount, 2);
        Stream.Read(Buffer, TileCount*2);
        Groups.Add(Item);
        for J:=0 to TileCount-1 do
         Tiles[Buffer[J*2+0], Buffer[J*2+1]].Add(Item);
       end;
   end;
  end;
  Engine.Surfaces.LoadData(Stream);
  ConnectTraffic;
 finally
  Stream.Free;
  SrcStream.Free;
  FFirstFrame:=True;
 end;
end;

procedure TTssMap.ConnectTraffic;
var I, J: integer;
    List: TList;
begin
 List:=TList.Create;
 for I:=0 to Groups.Count-1 do
  if TMapItem(Groups.Items[I]).IType=2 then with TTrafficLane(Groups.Items[I]) do begin
   List.Clear;
   CollectItems(List, Last.X-1.0, Last.Z-1.0, Last.X+1.0, Last.Z+1.0, TTrafficLane);
   for J:=0 to List.Count-1 do if List[J]<>Groups.Items[I] then begin
    if (Abs(TTrafficLane(List.Items[J]).First.X-Last.X)<1.0) and (Abs(TTrafficLane(List.Items[J]).First.Y-Last.Y)<1.0) and (Abs(TTrafficLane(List.Items[J]).First.Z-Last.Z)<1.0) then
     Connect(TTrafficLane(List.Items[J]), True);
    if Walk then if (Abs(TTrafficLane(List.Items[J]).Last.X-Last.X)<1.0) and (Abs(TTrafficLane(List.Items[J]).Last.Y-Last.Y)<1.0) and (Abs(TTrafficLane(List.Items[J]).Last.Z-Last.Z)<1.0) then
     Connect(TTrafficLane(List.Items[J]), False);
   end;
   if Walk then begin
    List.Clear;
    CollectItems(List, First.X-1.0, First.Z-1.0, First.X+1.0, First.Z+1.0, TTrafficLane);
    for J:=0 to List.Count-1 do if List[J]<>Groups.Items[I] then begin
     if (Abs(TTrafficLane(List.Items[J]).First.X-First.X)<1.0) and (Abs(TTrafficLane(List.Items[J]).First.Y-First.Y)<1.0) and (Abs(TTrafficLane(List.Items[J]).First.Z-First.Z)<1.0) then
      Connect2(TTrafficLane(List.Items[J]), True);
     if (Abs(TTrafficLane(List.Items[J]).Last.X-First.X)<1.0) and (Abs(TTrafficLane(List.Items[J]).Last.Y-First.Y)<1.0) and (Abs(TTrafficLane(List.Items[J]).Last.Z-First.Z)<1.0) then
      Connect2(TTrafficLane(List.Items[J]), False);
    end;
   end;
  end;
 List.Free;
end;

procedure TTssMap.CollectItems(AList: TList; const X1, Z1, X2, Z2: Single);
var X, Z, N, MinX, MinZ, MaxX, MaxZ: integer;
begin
 MinX:=Max(Trunc(Min(X1,X2)/64.0),0);
 MinZ:=Max(Trunc(Min(Z1,Z2)/64.0),0);
 MaxX:=Min(Trunc(Max(X1,X2)/64.0),255);
 MaxZ:=Min(Trunc(Max(Z1,Z2)/64.0),255);
 for X:=MinX to MaxX do
  for Z:=MinZ to MaxZ do
   with Tiles[X,Z] do
   for N:=0 to Tiles[X,Z].Count-1 do begin
    if Items[N]<>nil then
    if not TMapItem(Items[N]).OnList then begin
     AList.Add(Items[N]);
     TMapItem(Items[N]).OnList:=True;
    end;
   end;
 for N:=0 to AList.Count-1 do
  TMapItem(AList.Items[N]).OnList:=False;
end;

procedure TTssMap.CollectItems(AList: TList; const X1, Z1, X2, Z2: Single; Include: TMapItemClass);
var X, Z, N, MinX, MinZ, MaxX, MaxZ: integer;
begin
 MinX:=Max(Trunc(Min(X1,X2)/64.0),0);
 MinZ:=Max(Trunc(Min(Z1,Z2)/64.0),0);
 MaxX:=Min(Trunc(Max(X1,X2)/64.0),255);
 MaxZ:=Min(Trunc(Max(Z1,Z2)/64.0),255);
 for X:=MinX to MaxX do
  for Z:=MinZ to MaxZ do
   with Tiles[X,Z] do
   for N:=0 to Tiles[X,Z].Count-1 do begin
    if Items[N]<>nil then
    if (not TMapItem(Items[N]).OnList) and (TMapItem(Items[N]).ClassType=Include) then begin
     AList.Add(Items[N]);
     TMapItem(Items[N]).OnList:=True;
    end;
   end;
 for N:=0 to AList.Count-1 do
  TMapItem(AList.Items[N]).OnList:=False;
end;

procedure TTssMap.CollectGroups(AList: TList; const X1, Y1, Z1, Range: Single);
var X, Z, N: integer;
    MinX, MinY, MinZ, MaxX, MaxY, MaxZ: Single;
  function CheckGroup(Group: TMapGroup): Boolean;
  var I: integer;
      V0, V1, V2: PD3DXVector3;
  begin
   Result:=False;
   if (Group.MinPos.X<MaxX) and (Group.MinPos.Y<MaxY) and (Group.MinPos.Z<MaxZ) and (Group.MaxPos.X>MinX) and (Group.MaxPos.Y>MinY) and (Group.MaxPos.Z>MinZ) then begin
    Group.Bits.Clear;
    Group.BitsFrom:=65535;
    Group.BitsTo:=0;
    for I:=0 to Group.IndexCount div 3-1 do begin
     V0:=@(Group.Vertices[Group.Indices[I*3+0]].V);
     V1:=@(Group.Vertices[Group.Indices[I*3+1]].V);
     V2:=@(Group.Vertices[Group.Indices[I*3+2]].V);
     if ((V0.X<MaxX) or (V1.X<MaxX) or (V2.X<MaxX)) then
      if ((V0.Y<MaxY) or (V1.Y<MaxY) or (V2.Y<MaxY)) then
       if ((V0.Z<MaxZ) or (V1.Z<MaxZ) or (V2.Z<MaxZ)) then
        if ((V0.X>MinX) or (V1.X>MinX) or (V2.X>MinX)) then
         if ((V0.Y>MinY) or (V1.Y>MinY) or (V2.Y>MinY)) then
          if ((V0.Z>MinZ) or (V1.Z>MinZ) or (V2.Z>MinZ)) then begin
     {if Min3Singles(V0.X, V1.X, V2.X)<MaxX then
      if Min3Singles(V0.Y, V1.Y, V2.Y)<MaxY then
       if Min3Singles(V0.Z, V1.Z, V2.Z)<MaxZ then
        if Max3Singles(V0.X, V1.X, V2.X)>MinX then
         if Max3Singles(V0.Y, V1.Y, V2.Y)>MinY then
          if Max3Singles(V0.Z, V1.Z, V2.Z)>MinZ then begin}
           Result:=True;
           if I<Group.BitsFrom then Group.BitsFrom:=I;
           if I>Group.BitsTo then Group.BitsTo:=I;
           Group.Bits[I]:=True;
          end;
    end;
   end;
  end;
  function CheckStatic(Static: TStaticItem): Boolean;
  var I, J, K: integer;
      V0, V1, V2: PD3DXVector3;
  begin
   Result:=False;
   if Static.Obj=nil then Static.MakeObject;
   if (Static.Obj.AMinPos.X<MaxX) and (Static.Obj.AMinPos.Y<MaxY) and (Static.Obj.AMinPos.Z<MaxZ) and (Static.Obj.AMaxPos.X>MinX) and (Static.Obj.AMaxPos.Y>MinY) and (Static.Obj.AMaxPos.Z>MinZ) then with Static.Obj.Details[0] do begin
    Bits.Clear;
    BitsFrom:=65535;
    BitsTo:=0;
    for J:=0 to MeshData.Count-1 do with TMeshData(MeshData.Items[J]) do
     if (Material.Opacity<>99) and (Material.MatType<MATTYPE_NONEUP) then
    for I:=StartIndex div 3 to (StartIndex+IndexCount-1) div 3 do begin
    //for I:=0 to IndexCount div 3-1 do begin
     V0:=@(Vertices[Indices[I*3+0]].V2);
     V1:=@(Vertices[Indices[I*3+1]].V2);
     V2:=@(Vertices[Indices[I*3+2]].V2);
     if Min3Singles(V0.X, V1.X, V2.X)<MaxX then
      if Min3Singles(V0.Y, V1.Y, V2.Y)<MaxY then
       if Min3Singles(V0.Z, V1.Z, V2.Z)<MaxZ then
        if Max3Singles(V0.X, V1.X, V2.X)>MinX then
         if Max3Singles(V0.Y, V1.Y, V2.Y)>MinY then
          if Max3Singles(V0.Z, V1.Z, V2.Z)>MinZ then begin
           Result:=True;
           if I<BitsFrom then BitsFrom:=I;
           if I>BitsTo then BitsTo:=I;
           Bits[I]:=True;
          end;
    end;
    //if Static.Obj.SharedBuffers then
    for K:=0 to Static.Obj.Children.Count-1 do
     with Static.Obj.Children.Obj[K] do if (AMinPos.X<MaxX) and (AMinPos.Y<MaxY) and (AMinPos.Z<MaxZ) and (AMaxPos.X>MinX) and (AMaxPos.Y>MinY) and (AMaxPos.Z>MinZ) then
     for J:=0 to Details[0].MeshData.Count-1 do with TMeshData(Details[0].MeshData.Items[J]) do
      if (Material.Opacity<>99) and (Material.MatType<MATTYPE_NONEUP) then
       for I:=StartIndex div 3 to (StartIndex+IndexCount-1) div 3 do begin
       //for I:=0 to IndexCount div 3-1 do begin
        V0:=@(Vertices[Indices[I*3+0]].V2);
        V1:=@(Vertices[Indices[I*3+1]].V2);
        V2:=@(Vertices[Indices[I*3+2]].V2);
        if Min3Singles(V0.X, V1.X, V2.X)<MaxX then
         if Min3Singles(V0.Y, V1.Y, V2.Y)<MaxY then
          if Min3Singles(V0.Z, V1.Z, V2.Z)<MaxZ then
           if Max3Singles(V0.X, V1.X, V2.X)>MinX then
            if Max3Singles(V0.Y, V1.Y, V2.Y)>MinY then
             if Max3Singles(V0.Z, V1.Z, V2.Z)>MinZ then begin
              Result:=True;
              if I<BitsFrom then BitsFrom:=I;
              if I>BitsTo then BitsTo:=I;
              Bits[I]:=True;
             end;
       end;
   end;
  end;
var Count: integer;
begin
 Count:=AList.Count;
 MinX:=Max(X1-Range,0);
 MinY:=Max(Y1-Range,0);
 MinZ:=Max(Z1-Range,0);
 MaxX:=Min(X1+Range,16383);
 MaxY:=Min(Y1+Range,16383);
 MaxZ:=Min(Z1+Range,16383);
 for X:=Trunc(MinX/64) to Trunc(MaxX/64) do
  for Z:=Trunc(MinZ/64) to Trunc(MaxZ/64) do
   with Tiles[X,Z] do
    for N:=0 to Tiles[X,Z].Count-1 do begin
     if Items[N]<>nil then
      if (not TMapItem(Items[N]).OnList) and (TMapItem(Items[N]).IType<=1) then begin
       AList.Add(Items[N]);
       TMapItem(Items[N]).OnList:=True;
      end;
    end;
 for N:=AList.Count-1 downto Count do begin
  TMapItem(AList.Items[N]).OnList:=False;
  case TMapItem(AList.Items[N]).IType of
   0: if TMapGroup(AList.Items[N]).Material.MatType>=MATTYPE_NONEUP then AList.Delete(N)
       else if not CheckGroup(TMapGroup(AList.Items[N])) then AList.Delete(N);
   1: if CheckStatic(TStaticItem(AList.Items[N])) then AList.List[N]:=TStaticItem(AList.Items[N]).Obj
       else AList.Delete(N);
  end;
 end;
end;

procedure TTssMap.CollectGroupsMap(AList: TList; const X1, Y1, Z1, Range: Single);
var X, Z, N: integer;
    MinX, MinY, MinZ, MaxX, MaxY, MaxZ: Single;
  function CheckGroup(Group: TMapGroup): Boolean;
  var I: integer;
      V0, V1, V2: PD3DXVector3;
  begin
   Result:=False;
   if (Group.MinPos.X<MaxX) and (Group.MinPos.Y<MaxY) and (Group.MinPos.Z<MaxZ) and (Group.MaxPos.X>MinX) and (Group.MaxPos.Y>MinY) and (Group.MaxPos.Z>MinZ) then begin
    Group.Bits.Clear;
    Group.BitsFrom:=65535;
    Group.BitsTo:=0;
    for I:=0 to Group.IndexCount div 3-1 do begin
     V0:=@(Group.Vertices[Group.Indices[I*3+0]].V);
     V1:=@(Group.Vertices[Group.Indices[I*3+1]].V);
     V2:=@(Group.Vertices[Group.Indices[I*3+2]].V);
     if ((V0.X<MaxX) or (V1.X<MaxX) or (V2.X<MaxX)) then
      if ((V0.Y<MaxY) or (V1.Y<MaxY) or (V2.Y<MaxY)) then
       if ((V0.Z<MaxZ) or (V1.Z<MaxZ) or (V2.Z<MaxZ)) then
        if ((V0.X>MinX) or (V1.X>MinX) or (V2.X>MinX)) then
         if ((V0.Y>MinY) or (V1.Y>MinY) or (V2.Y>MinY)) then
          if ((V0.Z>MinZ) or (V1.Z>MinZ) or (V2.Z>MinZ)) then begin
           Result:=True;
           if I<Group.BitsFrom then Group.BitsFrom:=I;
           if I>Group.BitsTo then Group.BitsTo:=I;
           Group.Bits[I]:=True;
          end;
    end;
   end;
  end;
var Count: integer;
begin
 Count:=AList.Count;
 MinX:=Max(X1-Range,0);
 MinY:=Max(Y1-Range,0);
 MinZ:=Max(Z1-Range,0);
 MaxX:=Min(X1+Range,16383);
 MaxY:=Min(Y1+Range,16383);
 MaxZ:=Min(Z1+Range,16383);
 for X:=Round(MinX) div 64 to Round(MaxX) div 64 do
  for Z:=Round(MinZ) div 64 to Round(MaxZ) div 64 do
   with Tiles[X,Z] do
    for N:=0 to Tiles[X,Z].Count-1 do begin
     if Items[N]<>nil then if TMapItem(Items[N]).IType=0 then
      with TMapGroup(Items[N]) do
       if Material.MatType<MATTYPE_NONEUP then
        if not TMapItem(Items[N]).OnList then begin
         AList.Add(Items[N]);
         TMapItem(Items[N]).OnList:=True;
        end;
    end;
 for N:=AList.Count-1 downto Count do begin
  TMapItem(AList.Items[N]).OnList:=False;
  if not CheckGroup(TMapGroup(AList.Items[N])) then AList.Delete(N);
 end;
end;

procedure TTssMap.MakeIndividual(StaticObj: TTssObject);
var X, Z: integer;
begin
 for X:=Max(0,Round(StaticObj.AMinPos.X) div 64-1) to Min(255,Round(StaticObj.AMaxPos.X) div 64+1) do
  for Z:=Max(0,Round(StaticObj.AMinPos.Z) div 64-1 )to Min(255,Round(StaticObj.AMaxPos.Z) div 64+1) do
   Tiles[X, Z].Remove(StaticObj.PPointer);
 Groups.Remove(StaticObj.PPointer);
 with TStaticItem(StaticObj.PPointer) do begin
  Obj:=nil;
  Free;
 end;
 StaticObj.Static:=False;
 StaticObj.AutoHandle:=True;
 StaticObj.DrawNeedsConfirmation:=False;
 Engine.FObjects.Add(StaticObj);
end;

{procedure TTssMap.CollectPolygonsEx(List: TList; const X1, Z1, Range: integer);
 function CheckPoly(Face: TMapPoly): Boolean;
  function CheckLine(A, B: PMapVertex): Boolean;
  var Am, Bm: Single;
  begin
   Result:=False;
   if X1>Min(A.X,B.X)-Range then
    if X1<Max(A.X,B.X)+Range then
     if Z1>Min(A.Z,B.Z)-Range then
      if Z1<Max(A.Z,B.Z)+Range then begin
       Am:=B.Z-A.Z;
       Bm:=A.X-B.X;
       if Abs(Am*(X1-A.X)+Bm*(Z1-A.Z))/Sqrt(Sqr(Am)+Sqr(Bm))<Range then Result:=True;
      end;
  end;
 var L: integer;
     A, B, C: PMapVertex;
     XA, XB, XC, ZA, ZB, ZC, Diff: Single;
 begin
  Result:=False;
  if Face.Style=3 then Exit;
  if X1+Range<Face.MinPos.X then Exit;
  if X1-Range>Face.MaxPos.X then Exit;
  if Z1+Range<Face.MinPos.Z then Exit;
  if Z1-Range>Face.MaxPos.Z then Exit;                
  //if X1+Range<Face.MinPos then Exit;
  //if X1+Range<Face.MinPos then Exit;
  for L:=0 to Face.VertexCount-3 do begin
   Face.Vertices[L].Extra:=0;
   if Face.Style=0 then begin
    if L mod 2=0 then A:=@Face.Vertices[(Face.VertexCount-L div 2) mod Face.VertexCount] else A:=@Face.Vertices[(L+3) div 2];
    if L mod 2=1 then B:=@Face.Vertices[(Face.VertexCount-(L+1) div 2) mod Face.VertexCount] else B:=@Face.Vertices[(L+2) div 2];
    if L mod 2=0 then C:=@Face.Vertices[(Face.VertexCount-(L+2) div 2) mod Face.VertexCount] else C:=@Face.Vertices[(L+1) div 2];
   end else begin
    A:=@Face.Vertices[L+2*Ord(L mod 2=1)];
    B:=@Face.Vertices[L+1];
    C:=@Face.Vertices[L+2*Ord(L mod 2=0)];
   end;

   if X1>Min(A.X,Min(B.X,C.X))-Range then
    if X1<Max(A.X,Max(B.X,C.X))+Range then
     if Z1>Min(A.Z,Min(B.Z,C.Z))-Range then
      if Z1<Max(A.Z,Max(B.Z,C.Z))+Range then begin

   if CheckLine(A, B) then begin Result:=True; Face.Vertices[L].Extra:=1; end
    else if CheckLine(B, C) then begin Result:=True; Face.Vertices[L].Extra:=1; end
     else if CheckLine(C, A) then begin Result:=True; Face.Vertices[L].Extra:=1; end
   else begin
    XA:=(X1-A.X)*0.001;
    ZA:=(Z1-A.Z)*0.001;
    Diff:=Sqrt(Sqr(XA)+Sqr(ZA));
    XA:=XA/Diff;
    ZA:=ZA/Diff;
    XB:=(X1-B.X)*0.001;
    ZB:=(Z1-B.Z)*0.001;
    Diff:=Sqrt(Sqr(XB)+Sqr(ZB));
    XB:=XB/Diff;
    ZB:=ZB/Diff;
    XC:=(X1-C.X)*0.001;
    ZC:=(Z1-C.Z)*0.001;
    Diff:=Sqrt(Sqr(XC)+Sqr(ZC));
    XC:=XC/Diff;
    ZC:=ZC/Diff;
    if Abs(ArcSin(XA*XB+ZA*ZB)+ArcSin(XB*XC+ZB*ZC)+ArcSin(XC*XA+ZC*ZA)+g_PI_DIV_2)<=0.01 then begin
     Result:=True;
     Face.Vertices[L].Extra:=1;
    end;
   end;

   end;

  end;
 end;

var X, Z, N, Index, MinX, MinZ, MaxX, MaxZ: integer;
    //ItemList: TList;
begin
 MinX:=Max(X1-Range,0);
 MinZ:=Max(Z1-Range,0);
 MaxX:=Min(X1+Range,16777215);
 MaxZ:=Min(Z1+Range,16777215);
 for X:=MinX div 65536 to MaxX div 65536 do
  for Z:=MinZ div 65536 to MaxZ div 65536 do
   for N:=0 to Tiles[X,Z].PolyCount-1 do begin
    Index:=Tiles[X,Z].Data[N*3]*65536+Tiles[X,Z].Data[N*3+1]*256+Tiles[X,Z].Data[N*3+2];
    if not TMapPoly(Polys.Items[Index]).OnList then begin
     List.Add(Polys.Items[Index]);
     TMapPoly(Polys.Items[Index]).OnList:=True;
    end;
   end;
 for N:=List.Count-1 downto 0 do begin
  TMapPoly(List.Items[N]).OnList:=False;
  if not CheckPoly(TMapPoly(List.Items[N])) then List.Delete(N);
 end;
end;}

{function TGameMap.MakeSlideVertices(Poly: TMapPoly; NewPos: TD3DVector; Width: Single): Boolean;
var Count: integer;
    PrevPos1, PrevPos2: TD3DVector;
begin
 Count:=Poly.VertexCount;
 if Count>=2 then begin
  PrevPos1:=MakeD3DVector(Poly.MapVertexes[Count-1].X*0.0005+Poly.MapVertexes[Count-2].X*0.0005,Poly.MapVertexes[Count-1].Y*0.0005+Poly.MapVertexes[Count-2].Y*0.0005,Poly.MapVertexes[Count-1].Z*0.0005+Poly.MapVertexes[Count-2].Z*0.0005);
  Result:=(Sqr(PrevPos1.X-NewPos.X)+Sqr(PrevPos1.Y-NewPos.Y)+Sqr(PrevPos1.Z-NewPos.Z))<0.2
 end else Result:=True;
 if not Result then Exit;
 if Count>=4 then PrevPos2:=MakeD3DVector(Poly.MapVertexes[Count-3].X*0.0005+Poly.MapVertexes[Count-4].X*0.0005,Poly.MapVertexes[Count-3].Y*0.0005+Poly.MapVertexes[Count-4].Y*0.0005,Poly.MapVertexes[Count-3].Z*0.0005+Poly.MapVertexes[Count-4].Z*0.0005);
 case Count of
  0,1: begin
     Count:=2;
     Poly.VertexCount:=2;
     ReAllocMem(Poly.MapVertexes,Count*SizeOf(TMapVertex));
     Poly.MapVertexes[0].X:=Round(NewPos.X*1000);
     Poly.MapVertexes[0].Y:=Round(NewPos.Y*1000);
     Poly.MapVertexes[0].Z:=Round(NewPos.Z*1000);
     //Poly.MapVertexes[1].X:=Round(NewPos.X*1000);
     //Poly.MapVertexes[1].Y:=Round(NewPos.Y*1000);
     //Poly.MapVertexes[1].Z:=Round(NewPos.Z*1000);
  end;
  2,3: begin

  end;
  else begin

  end;
 end;
end;}

{ TMapItem }

destructor TMapItem.Destroy;
begin
 if LightMap<>nil then FreeMem(LightMap);
 inherited;
end;

{ TTrafficLight }

procedure TTrafficLight.Draw;
var Temp: Single;                       
    Vector: TD3DXVector3;
begin                                        
 inherited;
 Temp:=FloatRemainder(Engine.FSecondTimer, RoundLength);
 if ((Temp<=Enab1From) or (Temp>=Enab1To)) and ((Temp<=Enab2From) or (Temp>=Enab2To)) then begin
  Temp:=FloatRemainder(Engine.FSecondTimer-2.0, RoundLength);
  if (((Temp<=Enab1From) or (Temp>=Enab1To)) and ((Temp<=Enab2From) or (Temp>=Enab2To))) or (not Yellow) then begin
   D3DXVec3TransformCoord(Vector, RedPos, Matrix);
   Engine.AlphaSystem.NewAlpha(AlphaData2(1.2, Vector.X, Vector.Y, Vector.Z, $FFFF0000), 2);
  end else begin
   D3DXVec3TransformCoord(Vector, YellowPos, Matrix);
   Engine.AlphaSystem.NewAlpha(AlphaData2(1.2, Vector.X, Vector.Y, Vector.Z, $FFFFFF00), 2);
  end;
 end else begin
  Temp:=FloatRemainder(Engine.FSecondTimer-0.75, RoundLength);
  if (((Temp<=Enab1From) or (Temp>=Enab1To)) and ((Temp<=Enab2From) or (Temp>=Enab2To))) and Yellow then begin
   D3DXVec3TransformCoord(Vector, YellowPos, Matrix);
   Engine.AlphaSystem.NewAlpha(AlphaData2(1.2, Vector.X, Vector.Y, Vector.Z, $FFFFFF00), 2);
  end else begin
   D3DXVec3TransformCoord(Vector, GreenPos, Matrix);
   Engine.AlphaSystem.NewAlpha(AlphaData2(1.2, Vector.X, Vector.Y, Vector.Z, $FF00FF00), 2);
  end;
 end;
end;

procedure TTrafficLight.ExtraLoad(Data: Pointer; Size: Word);
begin
 Green:=Boolean(Data^);
 Inc(Integer(Data));
 Yellow:=Boolean(Data^);
 Inc(Integer(Data));
 Red:=Boolean(Data^);
 Inc(Integer(Data));
 GreenPos:=TD3DXVector3(Data^);
 Inc(Integer(Data), 12);
 YellowPos:=TD3DXVector3(Data^);
 Inc(Integer(Data), 12);
 RedPos:=TD3DXVector3(Data^);
 Inc(Integer(Data), 12);
end;

end.
