{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Tool Unit                              *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssUtils;

interface

uses
  Windows, SysUtils, Classes, Math,
  Direct3D8, D3DX8, DXUtil;

const
  g_PI       =  3.14159265358979323846; // Pi
  g_2_PI     =  6.28318530717958623200; // 2 * Pi
  g_PI_DIV_2 =  1.57079632679489655800; // Pi / 2
  g_PI_DIV_4 =  0.78539816339744827900; // Pi / 4
  g_INV_PI   =  0.31830988618379069122; // 1 / Pi
  g_DEGTORAD =  0.01745329251994329547; // Degrees to Radians
  g_RADTODEG = 57.29577951308232286465; // Radians to Degrees
  g_HUGE     =  1.0e+38;                // Huge number for FLOAT
  g_EPSILON  =  1.0e-5;                 // Tolerance for FLOATs
  g_minusEPSILON = -1.0e-5;
  g_1plusEPSILON = 1.0 + 1.0e-5;         

type
  // Some TssEngine Data Types

  PDirect3DDevice8 = ^IDirect3DDevice8;

  P3DVertex = ^T3DVertex;
  T3DVertex = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       nX, nY, nZ: Single;
       tU, tV: Single;
     );
     1: (
       vV: TD3DXVector3;
       vN: TD3DXVector3;
       vtU, vtV: Single;
     );
  end;
  P3DVertexColor = ^T3DVertexColor;
  T3DVertexColor = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       nX, nY, nZ: Single;
       Color: TD3DColor;
       tU, tV: Single;
     );
     1: (
       V: TD3DXVector3;
       vN: TD3DXVector3;
       vColor: TD3DColor;
       vtU, vtV: Single;
     );
  end;
  P3DVertexColorNN = ^T3DVertexColorNN;
  T3DVertexColorNN = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       Color: TD3DColor;
       tU, tV: Single;
     );
     1: (
       V: TD3DXVector3;
     );
  end;
  P3DVertex2Tx = ^T3DVertex2Tx;
  T3DVertex2Tx = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       nX, nY, nZ: Single;
       tU1, tV1: Single;
       tU2, tV2: Single;
     );
     1: (
       vV: TD3DXVector3;
       vN: TD3DXVector3;
       vtU1, vtV1: Single;
       vtU2, vtV2: Single;
     );
  end;
  P3DVertex2TxColor = ^T3DVertex2TxColor;
  T3DVertex2TxColor = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       nX, nY, nZ: Single;
       Color: TD3DColor;
       tU1, tV1: Single;
       tU2, tV2: Single;
     );
     1: (
       V: TD3DXVector3;
       N: TD3DXVector3;
     );
  end;
  P2DVertex = ^T2DVertex;
  T2DVertex = packed record
    case Integer of
     0: (
       X, Y, Z, W: Single;
       tU, tV: Single;
     );
     1: (
       vV: TD3DXVector4;
       vtU, vtV: Single;
     );
  end;
  P2DVertex2Tx = ^T2DVertex2Tx;
  T2DVertex2Tx = packed record
    case Integer of
     0: (
       X, Y, Z, W: Single;
       tU1, tV1: Single;
       tU2, tV2: Single;
     );
     1: (
       vV: TD3DXVector4;
       vtU1, vtV1: Single;
       vtU2, vtV2: Single;
     );
  end;
  PIndex = ^TIndex;
  TIndex = Word;

  PPointVertex = ^TPointVertex;
  TPointVertex = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
       Size: Single;
       Color: TD3DColor;
     );
     1: (
       V: TD3DXVector3;
     );
  end;

  PVertices = ^TVertices;
  TVertices = array[0..0] of T3DVertex;
  PNNColorVertices = ^TNNColorVertices;
  TNNColorVertices = array[0..0] of T3DVertexColorNN;
  PColorVertices = ^TColorVertices;
  TColorVertices = array[0..0] of T3DVertexColor;
  P2TxColorVertices = ^T2TxColorVertices;
  T2TxColorVertices = array[0..0] of T3DVertex2TxColor;
  PIndices = ^TIndices;
  TIndices = array[0..0] of TIndex;

  PVectors = ^TVectors;
  TVectors = array[0..0] of TD3DXVector3;

  TObjDataVertex = packed record
    V1, V2: TD3DXVector3;
    nX, nY, nZ: Byte;
    tU, tV: Word;
    Color: TD3DColor;
  end;
  PObjDataVertices = ^TObjDataVertices;
  TObjDataVertices = array[0..0] of TObjDataVertex;

  PBits = ^TBits;
  TBits = array[0..0] of Cardinal;

  TBitArray = class(TPersistent)
  private
    FCount: integer;
    FBits: PBits;
    procedure SetBit(Index: integer; const Value: Boolean);
    function GetBit(Index: integer): Boolean;
    procedure SetCount(const Value: integer);
  public
    constructor Create(const Size: integer = 0);
    destructor Destroy; override;
    procedure Clear;
    property Bit[Index: integer]: Boolean read GetBit write SetBit; default;
    property Bits: PBits read FBits;
    property Count: integer read FCount write SetCount;
  end;

  TVirtualObject = class(TPersistent)
  public
    procedure VirtualData(AId: Cardinal; AData: Pointer; ASize: Cardinal); virtual; abstract;
  end;

  TString32 = string[31];

  TCustomVirtualEngine = class(TPersistent)
  private
    FRecording, FPlaying: Boolean;
  public
    procedure Move(TickCount: Single); virtual; abstract;
    procedure PlayMove(TickCount: Single); virtual; abstract;
    procedure RecordMove(TickCount: Single); virtual; abstract;
    procedure AddData(Unique: Boolean; AItem: TVirtualObject; AId: Cardinal; AData: Pointer; ASize: Cardinal); virtual; abstract;
    function FrameLength: Single; virtual; abstract;
    function FrameSlerpR: Single; virtual; abstract;
    function FrameSlerpP: Single; virtual; abstract;
  published
    property Recording: Boolean read FRecording write FRecording;
    property Playing: Boolean read FPlaying write FPlaying;
  end;

  TKeyDown = procedure(KeyVk: Cardinal; KeyChr: Char) of object;

  TColor24Bit = packed record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  function GetD3DColor(Color: TColor24Bit): TD3DColor;

const
  D3DFVF_TSSVERTEX = (D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_TEX1);
  D3DFVF_TSSVERTEX2TX = (D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_TEX2);
  D3DFVF_TSSVERTEXCOLOR = (D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_DIFFUSE or D3DFVF_TEX1);
  D3DFVF_TSSVERTEXCOLORNN = (D3DFVF_XYZ or D3DFVF_DIFFUSE or D3DFVF_TEX1);
  D3DFVF_TSSVERTEX2TXCOLOR = (D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_DIFFUSE or D3DFVF_TEX2);
  D3DFVF_TSSVERTEX_2D = (D3DFVF_XYZRHW or D3DFVF_TEX1);
  D3DFVF_TSSVERTEX_2D2TX = (D3DFVF_XYZRHW or D3DFVF_TEX2);
  D3DFVF_TSSVERTEXPOINT = (D3DFVF_XYZ or D3DFVF_DIFFUSE or D3DFVF_PSIZE);

  // Some Usefull (or not) functions...

  function BlendColor(const Value1, Value2: TD3DColor; const t: Single): TD3DColor;

  function Min3Singles(Value1, Value2, Value3: Single): Single;
  function Max3Singles(Value1, Value2, Value3: Single): Single;
  function FloatMin(V1, V2: Single): Single;
  function FloatMax(V1, V2: Single): Single;

  function IntToStr3(Value: integer): string;
  function FloatRemainder(Value, Divider: Single): Single;
  function StrToVector(Value: string): TD3DXVector3;

  function MakeD3DVector(const X, Y, Z: Single): TD3DXVector3;
  function MakeD3DVertex(const V, N: TD3DXVector3; const tU, tV: Single): T3DVertex;
  function Make2DVertex(const X, Y, Z, W, U, V: Single): T2DVertex;
  function MakeColorVertex(X, Y, Z: Single; U, V: Single; Color: DWord): T3DVertexColor;

  function VectorInterpolate(const V1, V2: TD3DXVector3; Value: Single): TD3DXVector3;
  function VectorAdd(const V1, V2: TD3DXVector3): TD3DXVector3;
  function VectorSubtract(const V1, V2: TD3DXVector3): TD3DXVector3;
  function VectorScale(const V: TD3DXVector3; const T: Single): TD3DXVector3;
  function VectorInvert(const V: TD3DXVector3): TD3DXVector3;
  function DotProduct(const A, B: TD3DXVector3): Single;
  function CrossProduct(const A, B: TD3DXVector3): TD3DXVector3;
  function VectorTriangleIntersect(const Tri1, Tri1to2, Tri1to3, VecA, VecAtoB: TD3DXVector3): Single;
  function VectorRectIntersect(const Rect1, Rect1to2, Rect1to3, VecA, VecAtoB: TD3DXVector3): Single;
  function VectorProjectionNormalized(const A, B: TD3DXVector3): TD3DXVector3; // A: Vector, B: Direction
  function LinePointDistance(const AB, PA: TD3DXVector3): Single;
  function LinePointDistanceSq(const AB, PA: TD3DXVector3): Single;
  function SegmentPointDistanceSq(const A, B, P: TD3DXVector3): Single;
  function ScalarProject(const A, B: TD3DXVector3): Single;
  function CubicBezier(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;
  function CubicBezierTangent(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;
  function CubicBezierTangent2(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;

  function GetYAngle(const Rot: TD3DMatrix): Single;
  function GetVectorYAngle(const Vector: TD3DXVector3): Single;
  function GetMove(const PosMove, RotMove, Position: TD3DXVector3; TickCount: Single): TD3DXVector3;

  function FloatAsInt(Value: Single): DWord; // Get Actual Bytes of 32 bit Float As 32 bit Integer

  function VectorNormalize(const V: TD3DXVector3): TD3DXVector3;
  procedure VertexMatrixMultiply(var vDest: T3DVertex; const vSrc: T3DVertex; const mat: TD3DMatrix);

  procedure StartTimer(Tag: Byte);
  procedure EndTimer(Tag: Byte);
  function ElapsedTime(Tag: Byte): Double;

  function GetPriority(Value: integer): TThreadPriority;

  function BytesNeeded(BitCount: DWord): DWord;

var
  // TssEngine Global Options
  Options: record
    DisplayMode: string;
    Window: Boolean;

    ShowFPS: Boolean;
    DebugMode: Boolean;
    EditorMode: Boolean;
    UseLogging: Boolean;
    PreferPacked: Boolean;
    
    Dithering: Boolean;
    Filtering: integer;
    Antialiasing: integer;
    MipMapBias: Single;
    SpeakerMode: integer;
    SoundVolume: integer;
    MusicVolume: integer;
    SoundDriver: integer;

    ClrTarget: Boolean;
    LockData: Boolean;

    UseRadio: Boolean;
    VisibleDepth: Single;
    Brightness: Single;
    AimColor: D3DCOLOR;
    InvertMouse: Boolean;
    MaxTraffic: integer;

    TXLPriority: integer;
    TXLMaxThreads: integer;

    UseStencil: Boolean;
    UseCubeMap: Boolean;
    UseMultiTx: Boolean;
    UseDetailTx: Boolean;
    UseDynamicSurfaces: Boolean;
    UsePointSprites: Boolean;

    PlayerName: string;
    
    ScriptInit: string;
  end;

var TimerFrequency: Int64;

implementation

var TimerTemp: array[0..15] of Int64;
    TimerElapsed: array[0..15] of Int64;

function GetD3DColor(Color: TColor24Bit): TD3DColor;
begin
 Result:=D3DCOLOR_ARGB(255, Color.R, Color.G, Color.B);
end;

procedure StartTimer(Tag: Byte);
begin
 QueryPerformanceCounter(TimerTemp[Tag]);
end;
procedure EndTimer(Tag: Byte);
var Temp: Int64;
begin
 QueryPerformanceCounter(Temp);
 TimerElapsed[Tag]:=Temp-TimerTemp[Tag];
end;
function ElapsedTime(Tag: Byte): Double;
begin
 Result:=TimerElapsed[Tag]/TimerFrequency*1000;
end;

function BytesNeeded(BitCount: DWord): DWord;
begin
 Result:=(BitCount-1) div 8+1;
end;

type T3DColor = record B, G, R, A: Byte; end;
function BlendColor(const Value1, Value2: TD3DColor; const t: Single): TD3DColor;
begin
 T3DColor(Result).R:=Round(T3DColor(Value1).R*(1.0-t)+T3DColor(Value2).R*t);
 T3DColor(Result).G:=Round(T3DColor(Value1).G*(1.0-t)+T3DColor(Value2).G*t);
 T3DColor(Result).B:=Round(T3DColor(Value1).B*(1.0-t)+T3DColor(Value2).B*t);
end;

function Min3Singles(Value1, Value2, Value3: Single): Single;
begin
 Result:=Value1;
 if Value2<Result then Result:=Value2;
 if Value3<Result then Result:=Value3;
end;
function Max3Singles(Value1, Value2, Value3: Single): Single;
begin
 Result:=Value1;
 if Value2>Result then Result:=Value2;
 if Value3>Result then Result:=Value3;
end;
function FloatMin(V1, V2: Single): Single;
begin
 if V1<V2 then Result:=V1
  else Result:=V2;
end;
function FloatMax(V1, V2: Single): Single;
begin
 if V1>V2 then Result:=V1
  else Result:=V2;
end;

function IntToStr3(Value: integer): string;
begin
 Result:=intToStr(Value);
 if Value<100 then Result:='0'+Result;
 if Value<10 then Result:='0'+Result;
end;

function FloatRemainder(Value, Divider: Single): Single;
begin
 Result:=Value-Divider*Trunc(Value/Divider);
end;

function StrToVector(Value: string): TD3DXVector3;
var CommaPos: integer;
begin
 CommaPos:=Pos(',', Value);
 Result.X:=StrToFloat(Copy(Value, 1, CommaPos-1));
 Delete(Value, 1, CommaPos);
 CommaPos:=Pos(',', Value);
 Result.Y:=StrToInt(Copy(Value, 1, CommaPos-1));
 Result.Z:=StrToInt(Copy(Value, CommaPos+1, Length(Value)-CommaPos));
end;

function FloatAsInt(Value: Single): DWord;
begin
 Result:=DWord((@Value)^);
end;

function MakeD3DVector(const X, Y, Z: Single): TD3DXVector3;
begin
 Result.X:=X;
 Result.Y:=Y;
 Result.Z:=Z;
end;

function MakeD3DVertex(const V, N: TD3DXVector3; const tU, tV: Single): T3DVertex;
begin
 Result.vV:=V;
 Result.vN:=N;
 Result.vtU:=tU;
 Result.vtV:=tV;
end;

function Make2DVertex(const X, Y, Z, W, U, V: Single): T2DVertex;
begin
 Result.X:=X;
 Result.Y:=Y;
 Result.Z:=Z;
 Result.W:=W;
 Result.tU:=U;
 Result.tV:=V;
end;


function MakeColorVertex(X, Y, Z: Single; U, V: Single; Color: DWord): T3DVertexColor;
begin
 Result.X:=X;
 Result.Y:=Y;
 Result.Z:=Z;
 Result.tU:=U;
 Result.tV:=V;
 Result.Color:=Color;
end;

function GetYAngle(const Rot: TD3DMatrix): Single;
var Vector, Vector2: TD3DXVector3;
begin
 D3DXVec3TransformCoord(Vector, MakeD3DVector(0,0,1), Rot);
 D3DXVec3Normalize(Vector2, MakeD3DVector(Vector.X,0,Vector.Z));
 if (Vector2.X<-1) or (Vector2.X>1) or (Vector2.X=0) then Vector2.X:=0;
 Result:=(1-2*Ord(Vector2.Z>0))*ArcCos(Vector2.X)+g_PI_DIV_2;
 if IsNan(Result) or (Abs(Result)>g_2_PI) then Result:=0;
end;

function GetVectorYAngle(const Vector: TD3DXVector3): Single;
var Vector2: TD3DXVector3;
begin
 D3DXVec3Normalize(Vector2, MakeD3DVector(Vector.X,0,Vector.Z));
 if (Vector2.X<-1) or (Vector2.X>1) or (Vector2.X=0) then Vector2.X:=0;
 Result:=(1-2*Ord(Vector2.Z>0))*ArcCos(Vector2.X)+g_PI_DIV_2;
 if IsNan(Result) or (Abs(Result)>g_2_PI) then Result:=0;
end;

function VectorNormalize(const V: TD3DXVector3): TD3DXVector3;
begin
 D3DXVec3Normalize(Result, V);
end;

procedure VertexMatrixMultiply(var vDest: T3DVertex; const vSrc: T3DVertex; const mat: TD3DMatrix);
var
  pSrcVec, pDestVec: PD3DXVector3;
begin                                          
  pSrcVec:=@vSrc.x;
  pDestVec:=@vDest.x;

  D3DXVec3TransformCoord(pDestVec^, pSrcVec^, mat);

  pSrcVec  := @vSrc.nx;
  pDestVec := @vDest.nx;
  D3DXVec3TransformCoord(pDestVec^, pSrcVec^, mat);
  vDest.tu:=vSrc.tu;
  vDest.tv:=vSrc.tv;
end;


function VectorInterpolate(const V1, V2: TD3DXVector3; Value: Single): TD3DXVector3;
begin
 Result.X:=V1.X*(1-Value)+V2.X*Value;
 Result.Y:=V1.Y*(1-Value)+V2.Y*Value;
 Result.Z:=V1.Z*(1-Value)+V2.Z*Value;
end;

function VectorAdd(const V1, V2: TD3DXVector3): TD3DXVector3;
begin
 Result.X:=V1.X+V2.X;
 Result.Y:=V1.Y+V2.Y;
 Result.Z:=V1.Z+V2.Z;
end;
function VectorSubtract(const V1, V2: TD3DXVector3): TD3DXVector3;
begin
 Result.X:=V1.X-V2.X;
 Result.Y:=V1.Y-V2.Y;
 Result.Z:=V1.Z-V2.Z;
end;

function VectorScale(const V: TD3DXVector3; const T: Single): TD3DXVector3;
begin
 Result.X:=V.X*T;
 Result.Y:=V.Y*T;
 Result.Z:=V.Z*T;
end;

function VectorInvert(const V: TD3DXVector3): TD3DXVector3;
begin
 Result.X:=-V.X;
 Result.Y:=-V.Y;
 Result.Z:=-V.Z;
end;

function DotProduct(const A, B: TD3DXVector3): Single;
begin
 Result:=A.X*B.X+A.Y*B.Y+A.Z*B.Z;
end;

function CrossProduct(const A, B: TD3DXVector3): TD3DXVector3;
begin
 Result.X:=A.Y*B.Z-A.Z*B.Y;
 Result.Y:=A.Z*B.X-A.X*B.Z;
 Result.Z:=A.X*B.Y-A.Y*B.X;
end;

function CubicBezier(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;
var T1, tA, tB, tC, tD: Single;
begin
 T1:=1.0-T;
 tD:=T*T*T;
 tC:=3.0*T*T*T1;
 tB:=3.0*T*T1*T1;
 tA:=T1*T1*T1;
 Result.X:=A.X*tA+B.X*tB+C.X*tC+D.X*tD;
 Result.Y:=A.Y*tA+B.Y*tB+C.Y*tC+D.Y*tD;
 Result.Z:=A.Z*tA+B.Z*tB+C.Z*tC+D.Z*tD;
end;

function CubicBezierTangent(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;
var tA, tB, tC, tD: Single;
begin
 tD:=3.0*T*T;
 tC:=6.0*T-9.0*T*T;
 tB:=3.0-12.0*T+9.0*T*T;
 tA:=6.0*T-3.0-3.0*T*T;
 Result.X:=A.X*tA+B.X*tB+C.X*tC+D.X*tD;
 Result.Y:=A.Y*tA+B.Y*tB+C.Y*tC+D.Y*tD;
 Result.Z:=A.Z*tA+B.Z*tB+C.Z*tC+D.Z*tD;
end;

function CubicBezierTangent2(const A, B, C, D: TD3DXVector3; const T: Single): TD3DXVector3;
var tA, tB, tC, tD: Single;
begin
 tD:=6.0*T;
 tC:=6.0-18.0*T;
 tB:=18.0*T-12.0;
 tA:=6.0-6.0*T;
 Result.X:=A.X*tA+B.X*tB+C.X*tC+D.X*tD;
 Result.Y:=A.Y*tA+B.Y*tB+C.Y*tC+D.Y*tD;
 Result.Z:=A.Z*tA+B.Z*tB+C.Z*tC+D.Z*tD;
end;

// Tri1 + x2*Tri1to2 + x3*Tri1to3 = VecA + x1*VecAtoB
// solved using cramers rule: x(i) = det B(i) / det A
function VectorTriangleIntersect(const Tri1, Tri1to2, Tri1to3, VecA, VecAtoB: TD3DXVector3): Single;
var Det, aa, bb: Single;
    Tri1ToVecA: TD3DXVector3;
  function Det3x3Vecs(const A, B, C: TD3DXVector3): Single;
  begin
   // with 3x3 matrix, det A = a1 . (a2 x a3)
   Result:=A.X*(B.Y*C.Z-B.Z*C.Y)+A.Y*(B.Z*C.X-B.X*C.Z)+A.Z*(B.X*C.Y-B.Y*C.X);
  end;
begin
 Result:=-1.0;
 Det:=Det3x3Vecs(VecAtoB, Tri1to2, Tri1to3);
 if Det=0.0 then Exit;
 Det:=1.0/Det;
 D3DXVec3Subtract(Tri1ToVecA, VecA, Tri1);
 aa:=Det3x3Vecs(VecAtoB, Tri1ToVecA, Tri1to3)*Det;
 if (aa<g_minusEPSILON) or (aa>g_1plusEPSILON) then Exit;
 bb:=Det3x3Vecs(VecAtoB, Tri1to2, Tri1ToVecA)*Det;
 if (bb<g_minusEPSILON) or (bb>g_1plusEPSILON) then Exit;
 if aa+bb>g_1plusEPSILON then Exit;
 Result:=-Det3x3Vecs(Tri1ToVecA, Tri1to2, Tri1to3)*Det;
end;

function VectorRectIntersect(const Rect1, Rect1to2, Rect1to3, VecA, VecAtoB: TD3DXVector3): Single;
var Det, aa, bb: Single;
    Rect1ToVecA: TD3DXVector3;
  function Det3x3Vecs(const A, B, C: TD3DXVector3): Single;
  begin
   Result:=A.X*(B.Y*C.Z-B.Z*C.Y)+A.Y*(B.Z*C.X-B.X*C.Z)+A.Z*(B.X*C.Y-B.Y*C.X);
  end;
begin
 Result:=-1.0;
 Det:=Det3x3Vecs(VecAtoB, Rect1to2, Rect1to3);
 if Det=0.0 then Exit;
 Det:=1.0/Det;
 D3DXVec3Subtract(Rect1ToVecA, VecA, Rect1);
 aa:=Det3x3Vecs(VecAtoB, Rect1ToVecA, Rect1to3)*Det;
 if (aa<g_minusEPSILON) or (aa>g_1plusEPSILON) then Exit;
 bb:=Det3x3Vecs(VecAtoB, Rect1to2, Rect1ToVecA)*Det;
 if (bb<g_minusEPSILON) or (bb>g_1plusEPSILON) then Exit;
 Result:=-Det3x3Vecs(Rect1ToVecA, Rect1to2, Rect1to3)*Det;
end;

{function VectorTriangleIntersect(const O1, A, B, O2, C: TD3DXVector3): Single;
var Am, Bm, Cm, Temp: Single;
begin
   Result:=-1;
   Temp:=(A.Z*C.X-A.X*C.Z)*(C.Z*B.Y-C.Y*B.Z)-(A.Z*C.Y-A.Y*C.Z)*(C.Z*B.X-C.X*B.Z);
   if Abs(Temp)>0.001 then Bm:=((A.Z*C.Y-A.Y*C.Z)*(C.Z*(O1.X-O2.X)+C.X*(O2.Z-O1.Z))-(A.Z*C.X-A.X*C.Z)*(C.Z*(O1.Y-O2.Y)+C.Y*(O2.Z-O1.Z)))/Temp
    else begin
     Temp:=(A.X*C.Y-A.Y*C.X)*(C.X*B.Z-C.Z*B.X)-(A.X*C.Z-A.Z*C.X)*(C.X*B.Y-C.Y*B.X);
     if Abs(Temp)>0.001 then Bm:=((A.X*C.Z-A.Z*C.X)*(C.X*(O1.Y-O2.Y)+C.Y*(O2.X-O1.X))-(A.X*C.Y-A.Y*C.X)*(C.X*(O1.Z-O2.Z)+C.Z*(O2.X-O1.X)))/Temp
      else begin
       Temp:=(A.Y*C.Z-A.Z*C.Y)*(C.Y*B.X-C.X*B.Y)-(A.Y*C.X-A.X*C.Y)*(C.Y*B.Z-C.Z*B.Y);
       if Temp<>0 then Bm:=((A.Y*C.X-A.X*C.Y)*(C.Y*(O1.Z-O2.Z)+C.Z*(O2.Y-O1.Y))-(A.Y*C.Z-A.Z*C.Y)*(C.Y*(O1.X-O2.X)+C.X*(O2.Y-O1.Y)))/Temp
        else Exit;
      end;
    end;
   if (Bm>1) or (Bm<0) then Exit;
   Temp:=A.Z*C.Y-A.Y*C.Z;
   if Abs(Temp)>0.001 then Am:=(C.Z*(O1.Y+Bm*B.Y-O2.Y)-C.Y*(O1.Z+Bm*B.Z-O2.Z))/Temp
    else begin
     Temp:=A.X*C.Z-A.Z*C.X;
     if Abs(Temp)>0.001 then Am:=(C.X*(O1.Z+Bm*B.Z-O2.Z)-C.Z*(O1.X+Bm*B.X-O2.X))/Temp
      else begin
       Temp:=A.Y*C.X-A.X*C.Y;
       if Temp<>0 then Am:=(C.Y*(O1.X+Bm*B.X-O2.X)-C.X*(O1.Y+Bm*B.Y-O2.Y))/Temp
        else Exit;
      end
    end;
   if (Am>1) or (Am<0) then Exit;
   if Am+Bm>1 then Exit;
   if Abs(C.X)>0.001 then Cm:=(O1.X+Am*A.X+Bm*B.X-O2.X)/C.X
    else if Abs(C.Y)>0.001 then Cm:=(O1.Y+Am*A.Y+Bm*B.Y-O2.Y)/C.Y
     else if C.Z<>0 then Cm:=(O1.Z+Am*A.Z+Bm*B.Z-O2.Z)/C.Z
      else Exit;
   if (Cm<0) or (Cm>1) then Exit;
   if (Abs(O1.X+Am*A.X+Bm*B.X-O2.X-Cm*C.X)<0.001) and (Abs(O1.Y+Am*A.Y+Bm*B.Y-O2.Y-Cm*C.Y)<0.001) and (Abs(O1.Z+Am*A.Z+Bm*B.Z-O2.Z-Cm*C.Z)<0.001) then
    Result:=Cm;
end;}
{function VectorRectIntersect(const O1, A, B, O2, C: TD3DXVector3): Single;
var Am, Bm, Cm, Temp: Single;
begin
   Result:=-1;
   Temp:=(A.Z*C.X-A.X*C.Z)*(C.Z*B.Y-C.Y*B.Z)-(A.Z*C.Y-A.Y*C.Z)*(C.Z*B.X-C.X*B.Z);
   if Abs(Temp)>0.001 then Bm:=((A.Z*C.Y-A.Y*C.Z)*(C.Z*(O1.X-O2.X)+C.X*(O2.Z-O1.Z))-(A.Z*C.X-A.X*C.Z)*(C.Z*(O1.Y-O2.Y)+C.Y*(O2.Z-O1.Z)))/Temp
    else begin
     Temp:=(A.X*C.Y-A.Y*C.X)*(C.X*B.Z-C.Z*B.X)-(A.X*C.Z-A.Z*C.X)*(C.X*B.Y-C.Y*B.X);
     if Abs(Temp)>0.001 then Bm:=((A.X*C.Z-A.Z*C.X)*(C.X*(O1.Y-O2.Y)+C.Y*(O2.X-O1.X))-(A.X*C.Y-A.Y*C.X)*(C.X*(O1.Z-O2.Z)+C.Z*(O2.X-O1.X)))/Temp
      else begin
       Temp:=(A.Y*C.Z-A.Z*C.Y)*(C.Y*B.X-C.X*B.Y)-(A.Y*C.X-A.X*C.Y)*(C.Y*B.Z-C.Z*B.Y);
       if Temp<>0 then Bm:=((A.Y*C.X-A.X*C.Y)*(C.Y*(O1.Z-O2.Z)+C.Z*(O2.Y-O1.Y))-(A.Y*C.Z-A.Z*C.Y)*(C.Y*(O1.X-O2.X)+C.X*(O2.Y-O1.Y)))/Temp
        else Exit;
      end;
    end;
   if (Bm>1) or (Bm<0) then Exit;
   Temp:=A.Z*C.Y-A.Y*C.Z;
   if Abs(Temp)>0.001 then Am:=(C.Z*(O1.Y+Bm*B.Y-O2.Y)-C.Y*(O1.Z+Bm*B.Z-O2.Z))/Temp
    else begin
     Temp:=A.X*C.Z-A.Z*C.X;
     if Abs(Temp)>0.001 then Am:=(C.X*(O1.Z+Bm*B.Z-O2.Z)-C.Z*(O1.X+Bm*B.X-O2.X))/Temp
      else begin
       Temp:=A.Y*C.X-A.X*C.Y;
       if Temp<>0 then Am:=(C.Y*(O1.X+Bm*B.X-O2.X)-C.X*(O1.Y+Bm*B.Y-O2.Y))/Temp
        else Exit;
      end
    end;
   if (Am>1) or (Am<0) then Exit;
   if Abs(C.X)>0.001 then Cm:=(O1.X+Am*A.X+Bm*B.X-O2.X)/C.X
    else if Abs(C.Y)>0.001 then Cm:=(O1.Y+Am*A.Y+Bm*B.Y-O2.Y)/C.Y
     else if C.Z<>0 then Cm:=(O1.Z+Am*A.Z+Bm*B.Z-O2.Z)/C.Z
      else Exit;
   if (Cm<0) or (Cm>1) then Exit;
   if (Abs(O1.X+Am*A.X+Bm*B.X-O2.X-Cm*C.X)<0.001) and (Abs(O1.Y+Am*A.Y+Bm*B.Y-O2.Y-Cm*C.Y)<0.001) and (Abs(O1.Z+Am*A.Z+Bm*B.Z-O2.Z-Cm*C.Z)<0.001) then
    Result:=Cm;
end;}

function VectorProjectionNormalized(const A, B: TD3DXVector3): TD3DXVector3;
var FCos: Single;
begin
 FCos:=DotProduct(A,B)/DotProduct(B,B);
 Result:=MakeD3DVector(FCos*B.X,FCos*B.Y,FCos*B.Z);
end;

function GetMove(const PosMove, RotMove, Position: TD3DXVector3; TickCount: Single): TD3DXVector3;
var NewPos: TD3DXVector3;
    mat1, mat2, mat3: TD3DMatrix;
begin
 D3DXMatrixIdentity(mat1);
 if Abs(RotMove.Z)>0 then begin
  mat2:=mat1;
  D3DXMatrixRotationZ(mat3, -RotMove.Z*TickCount*0.001);
  D3DXMatrixMultiply(mat1, mat2, mat3);
 end;
 if Abs(RotMove.Y)>0 then begin
  mat2:=mat1;
  D3DXMatrixRotationY(mat3, -RotMove.Y*TickCount*0.001);
  D3DXMatrixMultiply(mat1, mat2, mat3);
 end;
 if Abs(RotMove.X)>0 then begin
  mat2:=mat1;
  D3DXMatrixRotationX(mat3, -RotMove.X*TickCount*0.001);
  D3DXMatrixMultiply(mat1, mat2, mat3);
 end;
 D3DXVec3TransformCoord(NewPos, Position, mat1);
 Result:=MakeD3DVector(-(NewPos.X-Position.X)/TickCount*1000+PosMove.X,-(NewPos.Y-Position.Y)/TickCount*1000+PosMove.Y,-(NewPos.Z-Position.Z)/TickCount*1000+PosMove.Z);
end;

// P = the point
// A = a point in the line
// B = another point in the line
// AB = vector from A to B = B - A
// PA = vector from P to A = A - P
function LinePointDistance(const AB, PA: TD3DXVector3): Single;
begin
 Result:=Sqrt(D3DXVec3LengthSq(CrossProduct(AB, PA))/D3DXVec3LengthSq(AB));
end;

function LinePointDistanceSq(const AB, PA: TD3DXVector3): Single; //Faster
begin
 Result:=D3DXVec3LengthSq(CrossProduct(AB, PA))/D3DXVec3LengthSq(AB);
end;

function SegmentPointDistanceSq(const A, B, P: TD3DXVector3): Single;
var AB: TD3DXVector3;
begin
 D3DXVec3Subtract(AB, B, A);
 if D3DXVec3Dot(AB, VectorSubtract(P, A))<=0.0 then Result:=D3DXVec3LengthSq(VectorSubtract(P, A))
  else if D3DXVec3Dot(AB, VectorSubtract(B, P))<=0.0 then Result:=D3DXVec3LengthSq(VectorSubtract(B, P))
   else Result:=D3DXVec3LengthSq(CrossProduct(AB, VectorSubtract(A, P)))/D3DXVec3LengthSq(AB);
end;

function ScalarProject(const A, B: TD3DXVector3): Single;
begin
 Result:=D3DXVec3Dot(A, B)/D3DXVec3Length(B);
end;

function GetPriority(Value: integer): TThreadPriority;
begin
 case Value of
  -3 : Result:=tpIdle;
  -2 : Result:=tpLowest;
  -1 : Result:=tpLower;
   1 : Result:=tpHigher;
   2 : Result:=tpHighest;
   3 : Result:=tpTimeCritical;
  else Result:=tpNormal;
 end;
end;

{ TBitArray }

procedure TBitArray.Clear;
begin
 if FCount>0 then ZeroMemory(FBits, ((FCount-1) shr 5+1)*4);
end;

constructor TBitArray.Create(const Size: integer = 0);
begin
 inherited Create;
 Count:=Size;
end;

destructor TBitArray.Destroy;
begin
 ReAllocMem(FBits, 0);
 inherited;
end;

function TBitArray.GetBit(Index: integer): Boolean;
begin
 Result:=(FBits[Index shr 5] shr (Index and $1F)) and 1=1;
end;

procedure TBitArray.SetBit(Index: integer; const Value: Boolean);
begin
 if Value then FBits[Index shr 5]:=FBits[Index shr 5] or (1 shl (Index and $1F))
  else FBits[Index shr 5]:=FBits[Index shr 5] and (not (1 shl (Index and $1F)));
end;

procedure TBitArray.SetCount(const Value: integer);
begin
 if Value<=0 then begin
  FCount:=0;
  ReAllocMem(FBits, 0);
 end else begin
  FCount:=Value;
  ReAllocMem(FBits, ((FCount-1) shr 5+1)*4);
 end;
end;

initialization
  QueryPerformanceFrequency(TimerFrequency);


end.
