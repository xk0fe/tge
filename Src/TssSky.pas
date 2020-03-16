{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Sky Unit                               *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssSky;

interface

uses
  Windows, Direct3D8, TssUtils, TssTextures, D3DX8, Classes, Math, SysUtils,
  TssMap, TssObjects;

const
  Sky_YSegments = 32;
  Sky_XZSegments = 16; // PolyCount = YSegs x XZSegs x 2 - XZSegs

  Sky_TempBuffer = 384;

  Sky_RainLength = 2;

  Sky_CloudMapSize = 128;

  Sky_SunColorHeight = 100;
  Sky_SunColorWidth = 300;

type
  PTssCloudParticle = ^TTssCloudParticle;
  TTssCloudParticle = record
    P, Direction: TD3DXVector3;
    Size: Single;
    DistanceSqr: Single;
    C1, C2, C3, C4, C5, C6: Single;
    ImageIndex: integer;
    Visible: Single;
  end;

  TTssCloud = class(TObject)
  public
    DistanceSqr: Single;
    Position: TD3DXVector3;
    Cloud_VB: IDirect3DVertexBuffer8;
    ParticleCount, VisibleCount: integer;
    Particles: array of TTssCloudParticle;
    PList: TList;
    Material: TTssMaterial;
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure MakeBuffer;
    procedure Draw;
    function Density(From, At: TD3DXVector3): Single;
  end;

  TTssRainDrop = class(TObject)
  public
    Size: Single;
    Dead: Boolean;
    Pos, OldPos: TD3DXVector3;
  end;

  PCloudMap = ^TCloudMap;
  TCloudMap = array[0..Sky_CloudMapSize-1, 0..Sky_CloudMapSize-1] of Byte;
  PSunColor = ^TSunColor;
  TSunColor = array[0..Sky_SunColorHeight-1, 0..Sky_SunColorWidth-1] of TColor24Bit;
  TTssSky = class(TPersistent)
  private
    Sky_VB, TempVB: IDirect3DVertexBuffer8;
    Sky_IB: IDirect3DIndexBuffer8;
    MatSkyBg1: TTssMaterial;
    MatBgCloud1: TTssMaterial;
    MatRainDrop: TTssMaterial;
    MatSun: TTssMaterial;
    Clouds: TList;
    //CIndex: integer;
    SkyPos, SkyMove, AvgWind: TD3DXVector2;
    CurMove: TD3DXVector3;
    CloudMap: PCloudMap;
    RainDrops: TList;
    SunColor: PSunColor;
    procedure MakeSkyBuffer;
  public
    SunPos: TD3DXVector3;
    SunVis: Single;
    RainAmount: Single;
    Light: TD3DLight8;
    SkyColor: TColor24Bit;
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
    procedure Draw2;
  published
    property PosX: Single read SkyPos.X write SkyPos.X;
    property PosZ: Single read SkyPos.Y write SkyPos.Y;
    property WindX: Single read SkyMove.X write SkyMove.X;
    property WindZ: Single read SkyMove.Y write SkyMove.Y;
  end;

implementation

uses
  TssEngine;

function CloudDistanceSort(Item1, Item2: Pointer): Integer;
begin
 Result:=Round(TTssCloud(Item2).DistanceSqr-TTssCloud(Item1).DistanceSqr);
 if Result=0 then Result:=Integer(Item2)-Integer(Item1);
end;

constructor TTssSky.Create;
var I: integer;
begin
 inherited;
 Clouds:=TList.Create;
 for I:=0 to 128-1 do
  Clouds.Add(TTssCloud.Create);
 RainDrops:=TList.Create;
 Engine.MiscFile.LoadToMemByName('CloudMap1.dat', Pointer(CloudMap));
 Engine.MiscFile.LoadToMemByName('SunColor.dat', Pointer(SunColor));
 SkyPos:=D3DXVector2(0.27, 0.22);
 //SkyPos:=D3DXVector2(0.5, 0.5);
 AvgWind:=D3DXVector2(-0.00000005, -0.00000005);
 SkyMove:=D3DXVector2(-0.00000005, -0.00000005);
 MatSkyBg1.Name:='SkyBg1';
 MatBgCloud1.Name:='BgCloud1';
 MatRainDrop.Name:='RainDrop1';
 MatSun.Name:='Sun1';
end;

destructor TTssSky.Destroy;
var I: integer;
begin
 for I:=0 to Clouds.Count-1 do
  TTssCloud(Clouds.Items[I]).Free;
 Clouds.Free;
 for I:=RainDrops.Count-1 downto 0 do
  TTssRainDrop(RainDrops.Items[I]).Free;
 RainDrops.Free;
 FreeMem(SunColor);
 FreeMem(CloudMap);
 Sky_VB:=nil;
 Sky_IB:=nil;
 inherited;
end;

procedure TTssSky.Move(TickCount: Single);
var I, J: integer;
begin
 SkyMove.X:=SkyMove.X+(AvgWind.X-SkyMove.X)*Power(1.001, TickCount)*0.001;
 SkyMove.Y:=SkyMove.Y+(AvgWind.Y-SkyMove.Y)*Power(1.001, TickCount)*0.001;

 CurMove.X:=TickCount*SkyMove.X-Engine.Camera.Move.X*0.00001;
 CurMove.Y:=-Engine.Camera.Move.Y*0.00001;
 CurMove.Z:=TickCount*SkyMove.Y-Engine.Camera.Move.Z*0.00001;
 SkyPos.X:=SkyPos.X-CurMove.X;
 SkyPos.Y:=SkyPos.Y-CurMove.Z;

 I:=Trunc(SkyPos.X*Sky_CloudMapSize-1);
 J:=Trunc(SkyPos.Y*Sky_CloudMapSize-1);
 RainAmount:=(CloudMap[J mod Sky_CloudMapSize, I mod Sky_CloudMapSize]*(1+I-SkyPos.X*Sky_CloudMapSize+1)+
             CloudMap[J mod Sky_CloudMapSize, (I+1) mod Sky_CloudMapSize]*(SkyPos.X*Sky_CloudMapSize-1-I))*(1+J-SkyPos.Y*Sky_CloudMapSize+1)+
             (CloudMap[(J+1) mod Sky_CloudMapSize, I mod Sky_CloudMapSize]*(1+I-SkyPos.X*Sky_CloudMapSize+1)+
             CloudMap[(J+1) mod Sky_CloudMapSize, (I+1) mod Sky_CloudMapSize]*(SkyPos.X*Sky_CloudMapSize-1-I))*(SkyPos.Y*Sky_CloudMapSize-1-J);

 if RainAmount>128 then
 for I:=0 to Round((RainAmount-128)*TickCount*0.03) do
  with TTssRainDrop(RainDrops.Items[RainDrops.Add(TTssRainDrop.Create)]) do begin
   Pos:=D3DXVector3((Random(1000)-500)*0.03-CurMove.X*80000000/TickCount, 10, (Random(1000)-500)*0.03-CurMove.Z*80000000/TickCount);
   Size:=Random(1000)*0.00001+0.01;
  end;

 for I:=RainDrops.Count-1 downto 0 do
  with TTssRainDrop(RainDrops.Items[I]) do begin
   OldPos:=Pos;
   Pos.X:=Pos.X+CurMove.X*100000;
   Pos.Z:=Pos.Z+CurMove.Z*100000;
   Pos.Y:=Pos.Y-TickCount*0.015{+CurMove.Y*100000};
   if Pos.Y<-10 then begin
    RainDrops.Delete(I);
    Free;
   end;
  end;

 {for I:=0 to Clouds.Count-1 do
  TTssCloud(Clouds.Items[I]).Move(TickCount);
 Clouds.Sort(CloudDistanceSort);}
end;

procedure TTssSky.MakeSkyBuffer;
var PVB: P3DVertex2Tx;
    PIB: PIndex;
    I, J: integer;
begin
 Engine.m_pd3dDevice.CreateVertexBuffer((Sky_YSegments*Sky_XZSegments+1)*SizeOf(T3DVertex2Tx), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX2TX, D3DPOOL_DEFAULT, Sky_VB);
 Engine.m_pd3dDevice.CreateIndexBuffer((Sky_YSegments*(Sky_XZSegments-1)*2+Sky_YSegments)*3*SizeOf(TIndex), D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_DEFAULT, Sky_IB);

 Sky_VB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
 for I:=0 to Sky_YSegments-1 do
  for J:=1 to Sky_XZSegments do begin
   PVB.X:=Cos(I/Sky_YSegments*g_2_PI)*J/Sky_XZSegments*10;
   PVB.Z:=Sin(I/Sky_YSegments*g_2_PI)*J/Sky_XZSegments*10;
   PVB.Y:=(Cos(J/Sky_XZSegments*g_2_PI/32)-Cos(g_2_PI/32))/(1-Cos(g_2_PI/32))*2-1.25;
   //PVB.tU1:=I/Sky_YSegments;
   //PVB.tV1:=J/Sky_XZSegments*0.9+0.1;
   PVB.tU1:=PVB.X*0.005+SkyPos.X;
   PVB.tV1:=PVB.Z*0.005+SkyPos.Y;
   Inc(PVB);
  end;
 PVB.vV:=D3DXVector3(0, 1.5, 0);
 PVB.tU1:=0.0;
 PVB.tV1:=0.1;
 Inc(PVB);                
 Sky_VB.Unlock;

 Sky_IB.Lock(0, 0, PByte(PIB), D3DLOCK_DISCARD);
 for I:=0 to Sky_YSegments-1 do
  for J:=0 to Sky_XZSegments-2 do begin
   PIB^:=((I+1) mod Sky_YSegments)*Sky_XZSegments+J+1; Inc(PIB);
   PIB^:=I*Sky_XZSegments+J; Inc(PIB);
   PIB^:=I*Sky_XZSegments+J+1; Inc(PIB);
   PIB^:=((I+1) mod Sky_YSegments)*Sky_XZSegments+J; Inc(PIB);
   PIB^:=I*Sky_XZSegments+J; Inc(PIB);
   PIB^:=((I+1) mod Sky_YSegments)*Sky_XZSegments+J+1; Inc(PIB);
  end;
 for I:=0 to Sky_YSegments-1 do begin
  PIB^:=((I+1) mod Sky_YSegments)*Sky_XZSegments; Inc(PIB);
  PIB^:=Sky_YSegments*Sky_XZSegments; Inc(PIB);
  PIB^:=I*Sky_XZSegments; Inc(PIB);    
 end;
 Sky_IB.Unlock;

end;

procedure TTssSky.Draw;
var //PVB: PColorVertices;
    PVB2: P3DVertex2Tx;
    Matrix: TD3DMatrix;
    I: integer;
    Vector, Vector2, Vector3: TD3DXVector3;
    //Col: TColor24Bit;
begin
 if Sky_VB=nil then MakeSkyBuffer;

 if Engine.GameTime<=0.5 then SkyColor:=SunColor[Min(Round((RainAmount/384+0.25)*Sky_SunColorHeight), Sky_SunColorHeight-1), Min(Max(0, Round((Engine.GameTime-0.25)*4*Sky_SunColorWidth)), Sky_SunColorWidth-1)]
  else SkyColor:=SunColor[Min(Round((RainAmount/384+0.25)*Sky_SunColorHeight), Sky_SunColorHeight-1), Min(Max(0, Round((0.75-Engine.GameTime)*4*Sky_SunColorWidth)), Sky_SunColorWidth-1)];

 D3DXMatrixRotationAxis(Matrix, D3DXVector3(0.0, 0.7071067811, 0.7071067811), Engine.ClockTime*g_2_PI);
 D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, -0.7071067811, 0.7071067811), Matrix);
 Vector.Y:=Vector.Y+0.25;
 D3DXVec3Normalize(SunPos, Vector);
 D3DXVec3Cross(Vector, SunPos, D3DXVector3(0.0, 1.0, 0.0));
 D3DXVec3Normalize(Vector2, Vector);
 D3DXVec3Cross(Vector, SunPos, Vector2);
 D3DXVec3Normalize(Vector3, Vector);
 SunVis:=1-RainAmount/255;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGCOLOR, D3DCOLOR_ARGB(255, Round(SkyColor.R*Max(0.2, Min(1.0, SunPos.Y+0.75))), Round(SkyColor.G*Max(0.2, Min(1.0, SunPos.Y+0.75))), Round(SkyColor.B*Max(0.2, Min(1.0, SunPos.Y+0.8)))));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGTABLEMODE, D3DFOG_LINEAR);
 
 // Draw sky
 Engine.Textures.SetMaterial(MatBgCloud1, 0);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);
 Engine.m_pd3dDevice.GetLight(0, Light);
 ZeroMemory(@Light, Sizeof(Light));
 Light._Type:=D3DLIGHT_DIRECTIONAL;
 Engine.AmbientLight:=Round(SunPos.Y*64+96)*65793;
 Light.Diffuse.R:=Max(0.0, Min(0.75, SunPos.Y*2+0.5)*SunVis);
 Light.Diffuse.G:=Light.Diffuse.R;
 Light.Diffuse.B:=Light.Diffuse.R;
 Light.Diffuse.A:=0.5;
 Light.Position:=SunPos;
 Light.Direction:=D3DXVector3(SunPos.X, SunPos.Y, SunPos.Z);
 Engine.m_pd3dDevice.SetLight(0, Light);
 Engine.m_pd3dDevice.LightEnable(0, False);
 Engine.Lights.DisableLights;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, D3DCOLOR_RGBA(Round(SunPos.Y*96+127), Round(SunPos.Y*96+127), Round(SunPos.Y*96+127), 0));

 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGCOLOR, D3DCOLOR_ARGB(255, Round(SkyColor.R*Max(0.2, Min(1.0, SunPos.Y+0.75))), Round(SkyColor.G*Max(0.2, Min(1.0, SunPos.Y+0.75))), Round(SkyColor.B*Max(0.2, Min(1.0, SunPos.Y+0.8)))));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGTABLEMODE, D3DFOG_LINEAR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGSTART, FloatAsInt(0.0));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGEND, FloatAsInt(10.0-RainAmount*0.015));

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, iFalse);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);

 Sky_VB.Lock(0, 0, PByte(PVB2), D3DLOCK_NOSYSLOCK);
 for I:=0 to Sky_YSegments*Sky_XZSegments do begin
  PVB2.tU1:=PVB2.X*0.005+SkyPos.X;
  PVB2.tV1:=PVB2.Z*0.005+SkyPos.Y;
  Inc(PVB2);
 end;
 Sky_VB.Unlock;

 Matrix:=Engine.IdentityMatrix;
 Matrix._41:=Engine.Camera.Pos.X;
 Matrix._42:=Engine.Camera.Pos.Y;
 Matrix._43:=Engine.Camera.Pos.Z;
 Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Matrix);
 Engine.m_pd3dDevice.SetStreamSource(0, Sky_VB, SizeOf(T3DVertex2Tx));
 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TX);
 Engine.m_pd3dDevice.SetIndices(Sky_IB, 0);
 Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, Sky_YSegments*Sky_XZSegments+1, 0, Sky_YSegments*(Sky_XZSegments-1)*2+Sky_YSegments);
 Engine.IncPolyCounter(Sky_YSegments*(Sky_XZSegments-1)*2+Sky_YSegments);


 // Draw Sun
 {if Engine.GameTime<=0.5 then Col:=SunColor[Min(Round(RainAmount/256*Sky_SunColorHeight), Sky_SunColorHeight-1), Min(Max(0, Round((Engine.GameTime-0.25)*4*Sky_SunColorWidth)), Sky_SunColorWidth-1)]
  else Col:=SunColor[Min(Round(RainAmount/256*Sky_SunColorHeight), Sky_SunColorHeight-1), Min(Max(0, Round((0.75-Engine.GameTime)*4*Sky_SunColorWidth)), Sky_SunColorWidth-1)];

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iFalse);
 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXCOLOR);

 if TempVB=nil then Engine.m_pd3dDevice.CreateVertexBuffer(Sky_TempBuffer*SizeOf(T3DVertexColor), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEXCOLOR, D3DPOOL_DEFAULT, TempVB);
 TempVB.Lock(0, 0, PByte(PVB), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
 I:=0;
 with PVB[I+0] do begin X:=SunPos.X*5+Vector2.X*0.5; Y:=SunPos.Y*5+Vector2.Y*0.5; Z:=SunPos.Z*5+Vector2.Z*0.5; tU:=0.0; tV:=0.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 with PVB[I+1] do begin X:=SunPos.X*5+Vector3.X*0.5; Y:=SunPos.Y*5+Vector3.Y*0.5; Z:=SunPos.Z*5+Vector3.Z*0.5; tU:=1.0; tV:=0.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 with PVB[I+2] do begin X:=SunPos.X*5-Vector3.X*0.5; Y:=SunPos.Y*5-Vector3.Y*0.5; Z:=SunPos.Z*5-Vector3.Z*0.5; tU:=0.0; tV:=1.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 with PVB[I+3] do begin X:=SunPos.X*5+Vector3.X*0.5; Y:=SunPos.Y*5+Vector3.Y*0.5; Z:=SunPos.Z*5+Vector3.Z*0.5; tU:=1.0; tV:=0.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 with PVB[I+4] do begin X:=SunPos.X*5-Vector3.X*0.5; Y:=SunPos.Y*5-Vector3.Y*0.5; Z:=SunPos.Z*5-Vector3.Z*0.5; tU:=0.0; tV:=1.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 with PVB[I+5] do begin X:=SunPos.X*5-Vector2.X*0.5; Y:=SunPos.Y*5-Vector2.Y*0.5; Z:=SunPos.Z*5-Vector2.Z*0.5; tU:=1.0; tV:=1.0; Color:=D3DCOLOR_ARGB(Round(SunVis*255), Col.R, Col.G, Col.B); end;
 TempVB.Unlock;
 Engine.Textures.SetMaterial(MatSun, 0);
 Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
 Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, 2);
 Engine.IncPolyCounter(2);

 // Draw Clouds

 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGEND, FloatAsInt(40.0-RainAmount*0.0625));}

 Engine.m_pd3dDevice.GetLight(0, Light);
 ZeroMemory(@Light, Sizeof(Light));
 Light._Type:=D3DLIGHT_DIRECTIONAL;
 Engine.AmbientLight:=D3DCOLOR_RGBA(Round(SunPos.Y*10+17+RainAmount*0.1), Round(SunPos.Y*10+17+RainAmount*0.1), Round(SunPos.Y*12+20+RainAmount*0.1), 0);
 Light.Diffuse.R:=SkyColor.R/256*Max(0.0, Min(0.6, SunPos.Y*1.2+0.3)*(SunVis*0.5+0.5));
 Light.Diffuse.G:=SkyColor.G/256*Max(0.0, Min(0.6, SunPos.Y*1.2+0.3)*(SunVis*0.5+0.5));;
 Light.Diffuse.B:=SkyColor.B/256*Max(0.0, Min(0.6, SunPos.Y*1.2+0.3)*(SunVis*0.5+0.5));
 Light.Diffuse.A:=0.5;
 Light.Position:=SunPos;
 Light.Direction:=D3DXVector3(-SunPos.X, -SunPos.Y, -SunPos.Z);
 Engine.m_pd3dDevice.SetLight(0, Light);
 Engine.m_pd3dDevice.LightEnable(0, True);

 {Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHAREF, 8);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iFalse);

 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXCOLOR);
 D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 0.0, Options.VisibleDepth*20000), Engine.Camera.Rot);
 TTssCloud(Clouds.Items[CIndex]).MakeBuffer;
 for I:=0 to Clouds.Count-1 do
  with TTssCloud(Clouds.Items[I]) do
   if D3DXVec3LengthSq(VectorSubtract(Position, Vector))<20000*20000 then Draw;
 CIndex:=(CIndex+1) mod Clouds.Count;}

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHATESTENABLE, iFalse);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, D3DZB_TRUE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGSTART, FloatAsInt(32.0-RainAmount/8));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_FOGEND, FloatAsInt(256-RainAmount*2));
end;

procedure TTssSky.Draw2;
var I, J: integer;
    Vector, Vector2, Vector3, Vector4: TD3DXVector3;
    PVB: PColorVertices;
    M: TD3DXMatrix;
begin
 if RainDrops.Count>0 then begin
  if TempVB=nil then Engine.m_pd3dDevice.CreateVertexBuffer(Sky_TempBuffer*SizeOf(T3DVertexColor), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEXCOLOR, D3DPOOL_DEFAULT, TempVB);
  M:=Engine.IdentityMatrix;

  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE4X);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXCOLOR);
  Engine.Textures.SetMaterial(MatRainDrop, 0);
  J:=0;
  TempVB.Lock(0, 0, PByte(PVB), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
  D3DXVec3TransformCoord(Vector4, D3DXVector3(0.0, 0.0, 10.0), Engine.Camera.Rot);

  for I:=0 to RainDrops.Count-1 do with TTssRainDrop(RainDrops.Items[I]) do
   if Sqr(Vector4.X-Pos.X)+Sqr(Vector4.Y-Pos.Y)+Sqr(Vector4.Z-Pos.Z)<25.0 then begin
   D3DXVec3Normalize(Vector2, VectorSubtract(OldPos, Pos));
   D3DXVec3Cross(Vector3, Vector2, Pos);
   D3DXVec3Normalize(Vector, Vector3);

   D3DXVec3Cross(Vector3, Vector2, Vector);
      
   with PVB[J*3+2] do begin vN:=Vector3; V.X:=Pos.X+Vector2.X*Sky_RainLength; V.Y:=Pos.Y+Vector2.Y*Sky_RainLength; V.Z:=Pos.Z+Vector2.Z*Sky_RainLength; tU:=0.5; tV:=0.0; Color:=D3DCOLOR_ARGB(64, 255, 255, 255); end;
   with PVB[J*3+1] do begin vN:=Vector3; V.X:=Pos.X-Vector.X*Size;            V.Y:=Pos.Y-Vector.Y*Size;            V.Z:=Pos.Z-Vector.Z*Size;            tU:=0.0; tV:=1.0; Color:=D3DCOLOR_ARGB(64, 255, 255, 255); end;
   with PVB[J*3+0] do begin vN:=Vector3; V.X:=Pos.X+Vector.X*Size;            V.Y:=Pos.Y+Vector.Y*Size;            V.Z:=Pos.Z+Vector.Z*Size;            tU:=1.0; tV:=1.0; Color:=D3DCOLOR_ARGB(64, 255, 255, 255); end;

   Inc(J);
   if (J*3>=Sky_TempBuffer) and (I<RainDrops.Count-1) then begin
    TempVB.Unlock;
    Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
    M._41:=Engine.Camera.Pos.X-3.0;
    M._42:=Engine.Camera.Pos.Y;
    M._43:=Engine.Camera.Pos.Z-3.0;
    Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
    Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
    Engine.IncPolyCounter(J);
    M._41:=Engine.Camera.Pos.X+3.0;
    M._42:=Engine.Camera.Pos.Y;
    M._43:=Engine.Camera.Pos.Z+3.0;
    Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
    Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
    Engine.IncPolyCounter(J);
    M._41:=Engine.Camera.Pos.X-3.0;
    M._42:=Engine.Camera.Pos.Y;
    M._43:=Engine.Camera.Pos.Z+3.0;
    Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
    Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
    Engine.IncPolyCounter(J);
    M._41:=Engine.Camera.Pos.X+3.0;
    M._42:=Engine.Camera.Pos.Y;
    M._43:=Engine.Camera.Pos.Z-3.0;
    Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
    Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
    Engine.IncPolyCounter(J);
    J:=0;
    TempVB.Lock(0, 0, PByte(PVB), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
   end;
  end;
  TempVB.Unlock;
  if J>0 then begin
   M._41:=Engine.Camera.Pos.X-3.0;
   M._42:=Engine.Camera.Pos.Y;
   M._43:=Engine.Camera.Pos.Z-3.0;
   Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
   Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
   Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
   Engine.IncPolyCounter(J);
   M._41:=Engine.Camera.Pos.X+3.0;
   M._42:=Engine.Camera.Pos.Y;
   M._43:=Engine.Camera.Pos.Z+3.0;
   Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
   Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
   Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
   Engine.IncPolyCounter(J);
   M._41:=Engine.Camera.Pos.X-3.0;
   M._42:=Engine.Camera.Pos.Y;
   M._43:=Engine.Camera.Pos.Z+3.0;
   Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
   Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
   Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
   Engine.IncPolyCounter(J);
   M._41:=Engine.Camera.Pos.X+3.0;
   M._42:=Engine.Camera.Pos.Y;
   M._43:=Engine.Camera.Pos.Z-3.0;
   Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, M);
   Engine.m_pd3dDevice.SetStreamSource(0, TempVB, SizeOf(T3DVertexColor));
   Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, J);
   Engine.IncPolyCounter(J);
  end;
 end;
end;

{ TTssCloud }

constructor TTssCloud.Create;
var X, Y, Z, I, Size: integer;
begin
 inherited;
 Position:=D3DXVector3(Random(59800)-29900, Random(2000)+1500, Random(58000)-29900);
 Material.Name:='CloudParticles';
 Size:=Random(4)+3;
 ParticleCount:=9+15*Ord(Size>3)+21*Ord(Size>4)+27*Ord(Size>5);
 SetLength(Particles, ParticleCount);
 PList:=TList.Create;
 I:=0;
 for Y:=0 to Size-3 do
  for X:=0 to Size-1-Y do
   for Z:=0 to Size-1-Y do if (X=0) or (X=Size-1-Y) or (Z=0) or (Z=Size-1-Y) or (Y=0) then begin
    Particles[I].P:=D3DXVector3((X-(Size-1-Y)*0.5)*400+Random(1000)*0.4-200.0, (Y-(Size-2)*0.5)*400+Random(1000)*0.4-200.0, (Z-(Size-1-Y)*0.5)*400+Random(1000)*0.4-200.0);
    Particles[I].Size:=Random(1000)*0.3+400.0;
    Particles[I].ImageIndex:=Random(4);
    Particles[I].Direction:=D3DXVector3(Random(1000)*0.001, Random(1000)*0.001, Random(1000)*0.001);
    Particles[I].Visible:=1.0;
    PList.Add(@Particles[I]);
    Inc(I);
   end;
end;

function TTssCloud.Density(From, At: TD3DXVector3): Single;
var I: integer;
    Vector: TD3DXVector3;
begin
 Result:=1.0;
 for I:=0 to ParticleCount-1 do begin
  D3DXVec3Subtract(Vector, From, Particles[I].P);
  if (D3DXVec3Dot(Vector, At)<0) and (D3DXVec3LengthSq(Vector)>Sqr(Particles[I].Size)) then
   if LinePointDistance(At, Vector)<Particles[I].Size then
    Result:=Result*0.85;
 end;
end;

destructor TTssCloud.Destroy;
begin
 PList.Free;
 Cloud_VB:=nil;
 inherited;
end;

procedure TTssCloud.Draw;
var Matrix: TD3DMatrix;
begin
 if Cloud_VB=nil then MakeBuffer;
 D3DXMatrixScaling(Matrix, 0.001, 0.001, 0.001);
 Matrix._41:=Engine.Camera.Pos.X+Position.X*0.001;
 Matrix._42:=Engine.Camera.Pos.Y+Position.Y*0.001-(Sqr(Position.X)+Sqr(Position.Z))*0.000000005;
 Matrix._43:=Engine.Camera.Pos.Z+Position.Z*0.001;
 Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Matrix);
 Engine.Textures.SetMaterial(Material, 0);
 Engine.m_pd3dDevice.SetStreamSource(0, Cloud_VB, SizeOf(T3DVertexColor));
 Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, VisibleCount*2);
 Engine.IncPolyCounter(VisibleCount*2);
end;

function CloudParticleSort(Item1, Item2: Pointer): Integer;
begin
 Result:=Ord(PTssCloudParticle(Item2).Visible>0.05)-Ord(PTssCloudParticle(Item1).Visible>0.05);
 if Result=0 then
  if PTssCloudParticle(Item1).DistanceSqr>PTssCloudParticle(Item2).DistanceSqr then Result:=-1
   else if PTssCloudParticle(Item1).DistanceSqr<PTssCloudParticle(Item2).DistanceSqr then Result:=1;
end;

procedure TTssCloud.MakeBuffer;
var PVB: PColorVertices;
    I: integer;
    Normal, A, B, Vector: TD3DXVector3;
    C: Byte;
    isNew: Boolean;
begin
 isNew:=(Cloud_VB=nil);
 if isNew then
  Engine.m_pd3dDevice.CreateVertexBuffer(ParticleCount*6*SizeOf(T3DVertexColor), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEXCOLOR, D3DPOOL_DEFAULT, Cloud_VB);
 VisibleCount:=0;
 for I:=0 to ParticleCount-1 do begin
  Particles[I].DistanceSqr:=Sqr(Position.X+Particles[I].P.X)+Sqr(Position.Y+Particles[I].P.Y)+Sqr(Position.Z+Particles[I].P.Z);
  Particles[I].Visible:=Particles[I].Visible*0.95+Ord((Density(Particles[I].P, VectorScale(VectorAdd(Position, Particles[I].P), -1.0))<1.0) and (Density(D3DXVector3(Particles[I].P.X+Random(Round(Particles[I].Size))-Particles[I].Size, Particles[I].P.Y+Random(Round(Particles[I].Size))-Particles[I].Size, Particles[I].P.Z+Random(Round(Particles[I].Size))-Particles[I].Size), VectorScale(VectorAdd(Position, Particles[I].P), -1.0))<1.0))*0.05;
  if Particles[I].Visible>0.05 then Inc(VisibleCount);
 end;
 PList.Sort(CloudParticleSort);
 Cloud_VB.Lock(0, 0, PByte(PVB), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
 for I:=0 to ParticleCount-1 do with PTssCloudParticle(PList.Items[I])^ do begin
  D3DXVec3Normalize(Normal, VectorAdd(Position, P));
  D3DXVec3Normalize(A, CrossProduct(Normal, Direction));
  D3DXVec3Normalize(B, CrossProduct(Normal, A));
  Vector:=D3DXVector3(P.X+A.X*Size, P.Y+A.Y*Size, P.Z+A.Z*Size);
  PVB[I*6+0].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+0].vN, Vector);
  PVB[I*6+0].vtU:=(ImageIndex and 1)*0.5; PVB[I*6+0].vtV:=(ImageIndex and 2)*0.5;
  C1:=Ord(not isNew)*C1*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round((64*C1+64)*Max(0.2, Min(1.0, Engine.Sky.SunPos.Y+0.75)));
  PVB[I*6+0].Color:=D3DCOLOR_ARGB(Round(Visible*255), Round(C*(Engine.Sky.SkyColor.R/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.G/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.B/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)));
  Vector:=D3DXVector3(P.X+B.X*Size, P.Y+B.Y*Size, P.Z+B.Z*Size);
  PVB[I*6+1].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+1].vN, Vector);
  PVB[I*6+1].vtU:=(ImageIndex and 1)*0.5+0.5; PVB[I*6+1].vtV:=(ImageIndex and 2)*0.5;
  C2:=Ord(not isNew)*C2*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round((64*C2+64)*Max(0.2, Min(1.0, Engine.Sky.SunPos.Y+0.75)));
  PVB[I*6+1].Color:=D3DCOLOR_ARGB(Round(Visible*255), Round(C*(Engine.Sky.SkyColor.R/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.G/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.B/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)));
  Vector:=D3DXVector3(P.X-A.X*Size, P.Y-A.Y*Size, P.Z-A.Z*Size);
  PVB[I*6+2].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+2].vN, Vector);
  PVB[I*6+2].vtU:=(ImageIndex and 1)*0.5+0.5; PVB[I*6+2].vtV:=(ImageIndex and 2)*0.5+0.5;
  C3:=Ord(not isNew)*C3*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round((64*C3+64)*Max(0.2, Min(1.0, Engine.Sky.SunPos.Y+0.75)));
  PVB[I*6+2].Color:=D3DCOLOR_ARGB(Round(Visible*255), Round(C*(Engine.Sky.SkyColor.R/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.G/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.B/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)));
  {Vector:=D3DXVector3(P.X+A.X*Size, P.Y+A.Y*Size, P.Z+A.Z*Size);
  PVB[I*6+3].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+3].vN, Vector);
  PVB[I*6+3].vtU:=(ImageIndex and 1)*0.5; PVB[I*6+3].vtV:=(ImageIndex and 2)*0.5;
  C4:=Ord(not isNew)*C4*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round(64*C4+64);
  PVB[I*6+3].Color:=D3DCOLOR_ARGB(Round(Visible*255), C, C, C);}
  PVB[I*6+3]:=PVB[I*6+0];
  Vector:=D3DXVector3(P.X-B.X*Size, P.Y-B.Y*Size, P.Z-B.Z*Size);
  PVB[I*6+4].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+4].vN, Vector);
  PVB[I*6+4].vtU:=(ImageIndex and 1)*0.5; PVB[I*6+4].vtV:=(ImageIndex and 2)*0.5+0.5;
  C5:=Ord(not isNew)*C5*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round((64*C5+64)*Max(0.2, Min(1.0, Engine.Sky.SunPos.Y+0.75)));
  PVB[I*6+4].Color:=D3DCOLOR_ARGB(Round(Visible*255), Round(C*(Engine.Sky.SkyColor.R/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.G/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)), Round(C*(Engine.Sky.SkyColor.B/256*C/128*C/128*C/128+1.0-C/128*C/128*C/128)));
  {Vector:=D3DXVector3(P.X-A.X*Size, P.Y-A.Y*Size, P.Z-A.Z*Size);
  PVB[I*6+5].V:=Vector;
  D3DXVec3Normalize(PVB[I*6+5].vN, Vector);
  PVB[I*6+5].vtU:=(ImageIndex and 1)*0.5+0.5; PVB[I*6+5].vtV:=(ImageIndex and 2)*0.5+0.5;
  C6:=Ord(not isNew)*C6*0.9+Density(Vector, Engine.Sky.SunPos)*(0.1+0.9*Ord(isNew));
  C:=Round(64*C6+64);
  PVB[I*6+5].Color:=D3DCOLOR_ARGB(Round(Visible*255), C, C, C);}
  PVB[I*6+5]:=PVB[I*6+2];
 end;
 Cloud_VB.Unlock;
end;

procedure TTssCloud.Move(TickCount: Single);
begin
 DistanceSqr:=Sqr(Position.X)+Sqr(Position.Y)+Sqr(Position.Z);
 Position.X:=Position.X+Engine.Sky.CurMove.X*400000;
 Position.Y:=Position.Y+Engine.Sky.CurMove.Y*400000;
 Position.Z:=Position.Z+Engine.Sky.CurMove.Z*400000;
 if Position.X>30000 then Position.X:=Position.X-60000;
 if Position.X<-30000 then Position.X:=Position.X+60000;
 if Position.Z>30000 then Position.Z:=Position.Z-60000;
 if Position.Z<-30000 then Position.Z:=Position.Z+60000;
end;

end.
 