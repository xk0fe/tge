{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Particle Unit                          *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssParticles;

interface

uses
  Windows, Direct3D8, D3DX8, Classes, TssUtils, Contnrs, TssTextures, Math, TssObjects,
  TssLights, SysUtils;

type
  TParticleEngine = class;

  TParticleSystem = class(TObject)
  protected
    Owner: TParticleEngine;
  public
    Enabled: Boolean;
    constructor Create(AOwner: TParticleEngine; AEnabled: Boolean); virtual;
    destructor Destroy; override;
    procedure Move(TickCount: Single); virtual; abstract;
    procedure Draw; virtual; abstract;
  end;

  TSmokeData = class(TObject)
  public
    RPosition, APosition: TD3DXVector3;
    Visibility: Single;
    LifeTime: Single;
    FadeSpeed: Single;
    Rotated: Single;
  end;
  TTyreSmoke = class(TParticleSystem)
  private
    Items1: TList;
    Material1: TTssMaterial;
    FLastTime: Single;
    Temperature: Single;
  public
    Tyre: TTssObject;
    Speed: Single;
    constructor Create(AOwner: TParticleEngine; AEnabled: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure Draw; override;
    procedure AddItem(const Position: TD3DXVector3; Visibility, TickCount: Single);
    property LastTime: Single read FLastTime;
  end;

  TFSandData = class(TObject)
  public
    APosition, AMove: TD3DXVector3;
    LifeTime: Single;
    DeathLevel: Single;
  end;
  TFlyingSand = class(TParticleSystem)
  private
    Items1: TList;
    Material1: TTssMaterial;
    FLastTime: Single;
  public
    Tyre: TTssObject;
    Speed: Single;
    constructor Create(AOwner: TParticleEngine; AEnabled: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure Draw; override;
    procedure AddItem(const Position, Move: TD3DXVector3);
    property LastTime: Single read FLastTime;
  end;

  TGunFlame = class(TParticleSystem)
  private
    FlameMaterial: TTssMaterial;
    Light: TLight;
  public
    FLifeTime: Single;
    FFirePos: TD3DXVector3;
    FFireRot: TD3DMatrix;
    constructor Create(AOwner: TParticleEngine; AEnabled: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure Draw; override;
  end;

  TBulletLine = class(TParticleSystem)
  private
    LineMaterial: TTssMaterial;
  public
    Obj: TTssObject;
    Length: Single;
    constructor Create(AOwner: TParticleEngine; AEnabled: Boolean); override;
    procedure Move(TickCount: Single); override;
    procedure Draw; override;
  end;

  TParticleEngine = class(TObject)
  private
    Systems: TList;
    function GetSystem(Index: integer): TParticleSystem;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
    property System[Index: integer]: TParticleSystem read GetSystem;
  end;

implementation

uses
  TssEngine, TssCars, TssWeapons;

constructor TParticleEngine.Create;
begin
 inherited;
 Systems:=TList.Create;
end;

destructor TParticleEngine.Destroy;
var I: integer;
begin
 for I:=Systems.Count-1 downto 0 do
  System[I].Free;
 Systems.Free;
 inherited;
end;

function TParticleEngine.GetSystem(Index: integer): TParticleSystem;
begin
 Result:=TParticleSystem(Systems.Items[Index]);
end;

procedure TParticleEngine.Move(TickCount: Single);
var I: integer;
begin
 for I:=Systems.Count-1 downto 0 do
  with System[I] do if Enabled then Move(TickCount);
end;

procedure TParticleEngine.Draw;
var I: integer;
begin
 for I:=Systems.Count-1 downto 0 do
  with System[I] do if Enabled then System[I].Draw;
end;

constructor TParticleSystem.Create(AOwner: TParticleEngine; AEnabled: Boolean);
begin
 inherited Create;
 Owner:=AOwner;
 Enabled:=AEnabled;
 if Owner<>nil then Owner.Systems.Add(Self);
end;

destructor TParticleSystem.Destroy;
begin
 if Owner<>nil then Owner.Systems.Remove(Self);
 inherited;
end;



constructor TFlyingSand.Create(AOwner: TParticleEngine; AEnabled: Boolean);
begin
 inherited;
 Items1:=TList.Create;
 Material1.Name:='FlyingSnd1';
 Material1.Opacity:=99;
end;

destructor TFlyingSand.Destroy;
var I: integer;
begin
 for I:=0 to Items1.Count-1 do
  TObject(Items1.Items[I]).Free;
 Items1.Free;
 inherited;
end;

procedure TFlyingSand.Move(TickCount: Single);
var I: integer;
begin
 FLastTime:=FLastTime+TickCount*0.001;
 for I:=Items1.Count-1 downto 0 do
  with TFSandData(Items1.Items[I]) do begin
   LifeTime:=LifeTime+TickCount*0.001;
   APosition.X:=APosition.X+AMove.X*TickCount*0.001;
   APosition.Y:=APosition.Y+AMove.Y*TickCount*0.001;
   APosition.Z:=APosition.Z+AMove.Z*TickCount*0.001;
   AMove.Y:=AMove.Y-TickCount*0.001*9.81;
   if APosition.Y<DeathLevel then begin
    Free;
    Items1.Delete(I);
   end;
  end;
end;

procedure TFlyingSand.Draw;
var I: integer;
    Vertex: TPointVertex;
begin
 if Items1.Count>0 then begin
  Engine.Textures.AlphaRef:=160;
  Engine.Textures.SetMaterial(Material1, 0);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALEENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE, FloatAsInt(1.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE_MIN, FloatAsInt(0.5));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_A, FloatAsInt(0.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_B, FloatAsInt(0.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_C, FloatAsInt(1.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iFalse);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXPOINT);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
  for I:=0 to Items1.Count-1 do
   with TFSandData(Items1.Items[I]) do begin
    Vertex.V:=APosition;
    Vertex.Size:=0.6+LifeTime*0.8;
    Vertex.Color:=D3DCOLOR_ARGB(255, Engine.Sky.SkyColor.R div 2, Engine.Sky.SkyColor.G div 2, Engine.Sky.SkyColor.B div 2);
    Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_POINTLIST, 1, Vertex, SizeOf(TPointVertex));
    Engine.IncPolyCounter(1);
   end;
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iFalse); 
 end;
end;

procedure TFlyingSand.AddItem(const Position, Move: TD3DXVector3);
var NewItem: TFSandData;
begin
 FLastTime:=0;
 NewItem:=TFSandData.Create;
 NewItem.APosition:=Position;
 NewItem.AMove:=Move;
 NewItem.DeathLevel:=Position.Y-1.0;
 Items1.Add(NewItem);
 NewItem:=TFSandData.Create;
 NewItem.APosition:=D3DXVector3(Position.X+Random(1000)*0.0002-0.1, Position.Y+Random(1000)*0.0002-0.1, Position.Z+Random(1000)*0.0002-0.1);
 NewItem.AMove:=D3DXVector3(Move.X+Random(1000)*0.0002-0.1, Move.Y+Random(1000)*0.0002-0.1, Move.Z+Random(1000)*0.0002-0.1);
 NewItem.DeathLevel:=Position.Y-1.0;
 Items1.Add(NewItem);
end;



constructor TTyreSmoke.Create(AOwner: TParticleEngine; AEnabled: Boolean);
begin
 inherited;
 Items1:=TList.Create;
 Material1.Name:='Smoke1';
end;

destructor TTyreSmoke.Destroy;
var I: integer;
begin
 for I:=0 to Items1.Count-1 do
  TObject(Items1.Items[I]).Free;
 Items1.Free;
 inherited;
end;

procedure TTyreSmoke.Move(TickCount: Single);
var I: integer;
begin
 FLastTime:=FLastTime+TickCount*0.001;
 Temperature:=Max(0.0, Temperature-TickCount*0.0005);
 Tyre.Matrix:=Tyre.ARot;
 Tyre.Matrix._41:=Tyre.Matrix._41+Tyre.APos.X;
 Tyre.Matrix._42:=Tyre.Matrix._42+Tyre.APos.Y;
 Tyre.Matrix._43:=Tyre.Matrix._43+Tyre.APos.Z;
 for I:=Items1.Count-1 downto 0 do
  with TSmokeData(Items1.Items[I]) do begin
   LifeTime:=LifeTime+TickCount*0.001*(FadeSpeed*0.1+0.8);
   Visibility:=Visibility-TickCount*0.001*FadeSpeed;
   APosition.Y:=APosition.Y+TickCount*0.001;
   if Visibility<=0 then begin
    Free;
    Items1.Delete(I);
   end;
  end;
end;

procedure TTyreSmoke.Draw;
var I: integer;
    Vertex: TPointVertex;
begin
 if Items1.Count>0 then begin
  Engine.Textures.SetMaterial(Material1, 0);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALEENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE, FloatAsInt(1.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE_MIN, FloatAsInt(0.5));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_A, FloatAsInt(0.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_B, FloatAsInt(0.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_C, FloatAsInt(1.0));
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 0);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXPOINT);
  for I:=0 to Items1.Count-1 do
   with TSmokeData(Items1.Items[I]) do begin
    Vertex.V:=APosition;
    Vertex.Size:=0.5+LifeTime*2.0;
    Vertex.Color:=D3DCOLOR_ARGB(Round(Visibility*255), 255, 255, 255);
    Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_POINTLIST, 1, Vertex, SizeOf(T3DVertexColor));
    Engine.IncPolyCounter(1);
   end;
  Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iFalse);
 end;
end;

procedure TTyreSmoke.AddItem(const Position: TD3DXVector3; Visibility, TickCount: Single);
var NewItem: TSmokeData;
    I: integer;
    OldPos: TD3DXVector3;
begin
 FLastTime:=0;
 Temperature:=Min(1.0, Temperature+Visibility*TickCount*0.0025);
 Visibility:=Visibility*Temperature;
 if Visibility<0.1 then Exit;
 OldPos:=VectorSubtract(Position, VectorScale(Tyre.PosMove, TickCount*0.001));
 for I:=0 to Round(TickCount*0.5)-1 do begin
  NewItem:=TSmokeData.Create;
  NewItem.APosition:=VectorInterpolate(OldPos, Position, I/TickCount*2);
  NewItem.APosition.X:=NewItem.APosition.X+(Random(1000)-500)*0.0006;
  NewItem.APosition.Y:=NewItem.APosition.Y+(Random(1000)-500)*0.0006-0.2;
  NewItem.APosition.Z:=NewItem.APosition.Z+(Random(1000)-500)*0.0006;
  NewItem.Visibility:=Visibility*(Random(750)+500)*0.001;
  NewItem.FadeSpeed:=0.1+Random(1000)*0.001;
  Items1.Add(NewItem);
 end;
end;

constructor TGunFlame.Create(AOwner: TParticleEngine; AEnabled: Boolean);
begin
 inherited;
 FlameMaterial.Name:='GunFlame1';
 Light:=TLight.Create;
 Light.LightType:=D3DLIGHT_POINT;
 Light.Color:=D3DCOLOR_ARGB(255, 255, 224, 64);
 Light.Range:=5.0;
end;

destructor TGunFlame.Destroy;
begin
 Light.Free;
 inherited;
end;

procedure TGunFlame.Move(TickCount: Single);
begin
 Light.Enabled:=True;
 Light.Pos:=FFirePos;
 FLifeTime:=FLifeTime+TickCount*0.001;
 if FLifeTime>0.1 then begin
  Enabled:=False;
  Light.Enabled:=False;
 end;
end;

procedure TGunFlame.Draw;
var Vertices: array[0..3] of T3DVertex;
    V1, V2, V3: TD3DXVector3;
    Angle: Single;
begin
 if FLifeTime<0.1 then begin
  Engine.Textures.SetMaterial(FlameMaterial, 0);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 0);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFF);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX);
  D3DXVec3TransformCoord(V1, D3DXVector3(1.0, 0.0, 0.0), FFireRot);
  D3DXVec3Normalize(V2, VectorSubtract(FFirePos, Engine.Camera.Pos));
  Angle:=ArcCos(D3DXVec3Dot(V1, V2));
  D3DXVec3Cross(V3, V1, V2);
  D3DXVec3Normalize(V2, V3);
  D3DXVec3Cross(V3, V1, V2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round((1-Sqr(FLifeTime*10))*(1-Abs(g_PI_DIV_2-Angle)/g_PI_DIV_2)*255), 0, 0, 0));
  Vertices[0].vV:=D3DXVector3(FFirePos.X-V2.X*0.25-V1.X*0.1, FFirePos.Y-V2.Y*0.25-V1.Y*0.1, FFirePos.Z-V2.Z*0.25-V1.Z*0.1);
  Vertices[0].vtU:=0.0; Vertices[0].vtV:=0.0;
  Vertices[1].vV:=D3DXVector3(FFirePos.X-V2.X*0.25+V1.X*0.5, FFirePos.Y-V2.Y*0.25+V1.Y*0.5, FFirePos.Z-V2.Z*0.25+V1.Z*0.5);
  Vertices[1].vtU:=1.0; Vertices[1].vtV:=0.0;
  Vertices[2].vV:=D3DXVector3(FFirePos.X+V2.X*0.25-V1.X*0.1, FFirePos.Y+V2.Y*0.25-V1.Y*0.1, FFirePos.Z+V2.Z*0.25-V1.Z*0.1);
  Vertices[2].vtU:=0.0; Vertices[2].vtV:=0.5;
  Vertices[3].vV:=D3DXVector3(FFirePos.X+V2.X*0.25+V1.X*0.5, FFirePos.Y+V2.Y*0.25+V1.Y*0.5, FFirePos.Z+V2.Z*0.25+V1.Z*0.5);
  Vertices[3].vtU:=1.0; Vertices[3].vtV:=0.5;
  Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T3DVertex));
  Engine.IncPolyCounter(2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round((1-Sqr(FLifeTime*10))*Abs(g_PI_DIV_2-Angle)/g_PI_DIV_2*255), 0, 0, 0));
  Vertices[0].vV:=D3DXVector3(FFirePos.X-V2.X*0.25, FFirePos.Y-V2.Y*0.25, FFirePos.Z-V2.Z*0.25);
  Vertices[0].vtU:=0.0; Vertices[0].vtV:=0.5;
  Vertices[1].vV:=D3DXVector3(FFirePos.X+V3.X*0.25, FFirePos.Y+V3.Y*0.25, FFirePos.Z+V3.Z*0.25);
  Vertices[1].vtU:=0.5; Vertices[1].vtV:=0.5;
  Vertices[2].vV:=D3DXVector3(FFirePos.X-V3.X*0.25, FFirePos.Y-V3.Y*0.25, FFirePos.Z-V3.Z*0.25);
  Vertices[2].vtU:=0.0; Vertices[2].vtV:=1.0;
  Vertices[3].vV:=D3DXVector3(FFirePos.X+V2.X*0.25, FFirePos.Y+V2.Y*0.25, FFirePos.Z+V2.Z*0.25);
  Vertices[3].vtU:=0.5; Vertices[3].vtV:=1.0;
  Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T3DVertex));
  Engine.IncPolyCounter(2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
 end;
end;

constructor TBulletLine.Create(AOwner: TParticleEngine; AEnabled: Boolean);
begin
 inherited;
 LineMaterial.Name:='ShootLine1';
end;

procedure TBulletLine.Move(TickCount: Single);
begin
 // Nothing
end;

procedure TBulletLine.Draw;
var Vertices: array[0..3] of T3DVertexColor;
    V1, V2, V3: TD3DXVector3;
begin
  Engine.Textures.SetMaterial(LineMaterial, 0);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
  Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, 0);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFF);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXCOLOR);
  D3DXVec3TransformCoord(V1, D3DXVector3(-1.0, 0.0, 0.0), Obj.ARot);
  D3DXVec3Normalize(V2, VectorSubtract(Obj.APos, Engine.Camera.Pos));
  D3DXVec3Cross(V3, V1, V2);
  D3DXVec3Normalize(V2, V3);
  Vertices[0].V:=D3DXVector3(Obj.APos.X-V2.X*0.02, Obj.APos.Y-V2.Y*0.2, Obj.APos.Z-V2.Z*0.02);
  Vertices[0].tU:=0.0; Vertices[0].vtV:=0.0; Vertices[0].vColor:=DWord(255 shl 24);
  Vertices[1].V:=D3DXVector3(Obj.APos.X-V2.X*0.02+V1.X*Length, Obj.APos.Y-V2.Y*0.02+V1.Y*Length, Obj.APos.Z-V2.Z*0.02+V1.Z*Length);
  Vertices[1].tU:=0.0; Vertices[1].vtV:=1.0; Vertices[1].vColor:=0;
  Vertices[2].V:=D3DXVector3(Obj.APos.X+V2.X*0.02, Obj.APos.Y+V2.Y*0.02, Obj.APos.Z+V2.Z*0.02);
  Vertices[2].tU:=1.0; Vertices[2].vtV:=0.0; Vertices[2].vColor:=DWord(255 shl 24);
  Vertices[3].V:=D3DXVector3(Obj.APos.X+V2.X*0.02+V1.X*Length, Obj.APos.Y+V2.Y*0.02+V1.Y*Length, Obj.APos.Z+V2.Z*0.02+V1.Z*Length);
  Vertices[3].tU:=1.0; Vertices[3].vtV:=1.0; Vertices[3].vColor:=0;
  Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T3DVertexColor));
  Engine.IncPolyCounter(2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
end;

end.
