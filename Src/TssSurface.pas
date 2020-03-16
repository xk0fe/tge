{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Surface Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssSurface;

interface

uses
  Classes, TssTextures, TssMap, Direct3D8, D3DX8, TssUtils, SysUtils, Math,
  TssObjects, Windows;

const
  SurfaceMaxDistance: array[0..3] of Single = (0.0, 15.0, 30.0, 60.0);
  SurfaceTempTimeout = 10.0;

type
  TSurfaceSystem = class;

  TTssSurface = class(TObject)
  private
    System: TSurfaceSystem;
  public
    constructor Create(Owner: TSurfaceSystem); virtual;
    procedure Draw(Group: TMapGroup); virtual; abstract;
  end;

  {TTssSurfaceGrass1 = class(TTssSurface)
  private
    MatGrass: TTssMaterial;
  public
    constructor Create(Owner: TSurfaceSystem); override;
    procedure Draw(Group: TMapGroup); override;
  end;
  TTssSurfaceGrassRock1 = class(TTssSurfaceGrass1)
  public
    procedure Draw(Group: TMapGroup); override;
  end;}

  TTssTempSurface = class(TObject)
  private
    System: TSurfaceSystem;
    LastVisible: Single;
  public
    PolyPointer: Pointer;
    VB: IDirect3DVertexBuffer8;
    PolyCount: integer;
    constructor Create(Owner: TSurfaceSystem); virtual;
    destructor Destroy; override;
    procedure Move(TickCount: Single); virtual;
    procedure Draw; virtual;
  end;

  TTssSurfaceData = class(TObject)
  public
    Visibility: Byte;
    GrassDensity: Single;
    GrassSizeMin: Single;
    GrassSizeMax: Single;
    ObjectDensity: Single;
    ObjectSizeMin: Single;
    ObjectSizeMax: Single;
    Grass: TTssMaterial;
    Objects: TTssObjectList;
    constructor Create;
    destructor Destroy; override;
  end;

  TSurfaceSystem = class(TObject)
  private
    //Rock1: TTssObject;
    //DynVB: IDirect3DVertexBuffer8;
    Surface: array[0..255] of TTssSurfaceData;
    //Surfaces: array[0..255] of TTssSurface;
    TempSurfaces: TList;
    NearPos: TD3DXVector3;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
    procedure LoadData(Stream: TStream);
  end;

implementation

uses
  TssEngine;

constructor TTssSurfaceData.Create;
begin
 inherited;
 Objects:=TTssObjectList.Create(True);
end;

destructor TTssSurfaceData.Destroy;
begin
 Objects.Free;
 inherited;
end;

constructor TTssSurface.Create(Owner: TSurfaceSystem);
begin
 inherited Create;
 System:=Owner;
end;

{constructor TTssSurfaceGrass1.Create(Owner: TSurfaceSystem);
begin
 inherited;
 MatGrass.Name:='GGrass1';
end;

procedure TTssSurfaceGrassRock1.Draw(Group: TMapGroup);
  procedure ProcessTriangle(const A, B, C: TD3DXVector3);
  var I, J, AB, AC: integer;
      BA, CA, Temp, Temp2: TD3DXVector3;
      WasRandSeed: LongInt;
      Distance, Size, Angle: Single;
  begin
   D3DXVec3Subtract(BA, B, A);
   D3DXVec3Subtract(CA, C, A);
   AB:=Round(D3DXVec3Length(VectorSubtract(BA, VectorProjectionNormalized(BA, CA)))*0.005*Group.Material.SurfaceParam2);
   AC:=Round(D3DXVec3Length(CA)*0.005*Group.Material.SurfaceParam2);
   WasRandSeed:=RandSeed;
   RandSeed:=Round(A.X*1000+B.X*999);
   for I:=0 to AB-1 do
    for J:=0 to Round(AC*(1-I/AB))-1 do begin
     Distance:=Sqr((Random(990)+5)*0.001);//(I+Random(1000)*0.001)/AB;
     Size:=(Random(990)+5)*0.001*(1-Distance);//(J+Random(1000)*0.001)/AC;
     Temp:=D3DXVector3(A.X+BA.X*Distance+CA.X*Size, A.Y+BA.Y*Distance+CA.Y*Size, A.Z+BA.Z*Distance+CA.Z*Size);
     Size:=(Random(750)+250)*0.001;
     Angle:=Random(360);
     D3DXVec3Subtract(Temp2, Temp, System.NearPos);
     Distance:=D3DXVec3LengthSq(Temp2);
     if Distance<Sqr(SurfaceMaxDistance*0.5) then begin
      D3DXVec3Subtract(Temp2, Temp, Engine.Camera.Pos);
      Distance:=D3DXVec3LengthSq(Temp2);
      if Distance/Sqr(Size)<Sqr(SurfaceMaxDistance) then begin
       System.Rock1.APos:=Temp;
       D3DXVec3Cross(Temp2, BA, CA);
       D3DXMatrixRotationAxis(System.Rock1.ARot, Temp2, Angle*g_DEGTORAD);
       Size:=Size*(1-Distance/Sqr(SurfaceMaxDistance));
       with System.Rock1.ARot do begin
        _11:=_11*Size; _12:=_12*Size; _13:=_13*Size;
        _21:=_21*Size; _22:=_22*Size; _23:=_23*Size;
        _31:=_31*Size; _32:=_32*Size; _33:=_33*Size;
       end;
       System.Rock1.Draw;
      end;
     end;
    end;
   RandSeed:=WasRandSeed;
  end;
var I: integer;
begin
 with Group do
  for I:=BitsFrom to BitsTo do
   if PolyBits[I div 8] and (1 shl (I mod 8))>0 then
    ProcessTriangle(Vertices[Indices[I*3+0]].V, Vertices[Indices[I*3+1]].V, Vertices[Indices[I*3+2]].V);
 inherited;
end;

procedure TTssSurfaceGrass1.Draw(Group: TMapGroup);
  procedure ProcessTriangle(AIndex: integer; const A, B, C: TD3DXVector3);
  var I, J, AB, AC: integer;
      //Vertices: array[0..SurfaceBufferSize*6-1] of T3DVertexColor;
      //CurItem: integer;
      BA, CA, Temp, Temp2, Temp3, Temp4: TD3DXVector3;
      WasRandSeed: LongInt;
      Distance, Size, Angle: Single;
      Vertices: PVertices;
      TriangePolyCount: integer;
      M: TD3DMatrix;
  begin
   D3DXVec3Subtract(BA, B, A);
   D3DXVec3Subtract(CA, C, A);
   AB:=Round(D3DXVec3Length(VectorSubtract(BA, VectorProjectionNormalized(BA, CA)))*0.025*Group.Material.SurfaceParam1);
   AC:=Round(D3DXVec3Length(CA)*0.025*Group.Material.SurfaceParam1);
   WasRandSeed:=RandSeed;
   RandSeed:=Round(A.X*1000+B.X*999);
   TriangePolyCount:=0;
   for I:=0 to AB-1 do
    for J:=0 to Round(AC*(1-I/AB))-1 do
     Inc(TriangePolyCount, 2);
   if Group.Surfaces=nil then Group.Surfaces:=AllocMem((Group.IndexCount div 3)*SizeOf(Pointer));
   Group.Surfaces[AIndex]:=TTssTempSurface.Create(System);
   with TTssTempSurface(Group.Surfaces[AIndex]) do begin
    PolyPointer:=@(Group.Surfaces[AIndex]);
    if TriangePolyCount>0 then begin
     Engine.m_pd3dDevice.CreateVertexBuffer(TriangePolyCount*3*SizeOf(T3DVertex), D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX, D3DPOOL_DEFAULT, VB);
     VB.Lock(0, 0, PByte(Vertices), D3DLOCK_DISCARD);
     PolyCount:=0;
     for I:=0 to AB-1 do
      for J:=0 to Round(AC*(1-I/AB))-1 do begin
       Distance:=Sqr((Random(950)+25)*0.001);
       Size:=(Random(950)+25)*0.001*(1-Distance);
       Temp:=D3DXVector3(A.X+BA.X*Distance+CA.X*Size, A.Y+BA.Y*Distance+CA.Y*Size, A.Z+BA.Z*Distance+CA.Z*Size);
       Size:=(Random(750)+500)*0.0003;
       Angle:=Random(360);
       D3DXVec3Cross(Temp2, BA, CA);
       D3DXVec3Normalize(Temp3, Temp2);
       D3DXMatrixRotationAxis(M, Temp2, Angle*g_DEGTORAD);
       D3DXVec3TransformCoord(Temp4, D3DXVector3(1.0, 0.0, 0.0), M);
       Vertices[PolyCount*3+0]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp4.X*Size*1.5, Temp.Y-Temp4.Y*Size*1.5, Temp.Z-Temp4.Z*Size*1.5), D3DXVector3(0.0, 1.0, 0.0), 0.0, 0.75);
       Vertices[PolyCount*3+1]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp4.X*Size*1.5+Temp3.X*Size, Temp.Y-Temp4.Y*Size*1.5+Temp3.Y*Size, Temp.Z-Temp4.Z*Size*1.5+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 0.0, 0.0);
       Vertices[PolyCount*3+2]:=MakeD3DVertex(D3DXVector3(Temp.X+Temp4.X*Size*1.5, Temp.Y+Temp4.Y*Size*1.5, Temp.Z+Temp4.Z*Size*1.5), D3DXVector3(0.0, 1.0, 0.0), 1.0, 0.75);
       Vertices[PolyCount*3+3]:=Vertices[PolyCount*3+2];
       Vertices[PolyCount*3+4]:=Vertices[PolyCount*3+1];
       Vertices[PolyCount*3+5]:=MakeD3DVertex(D3DXVector3(Temp.X+Temp4.X*Size*1.5+Temp3.X*Size, Temp.Y+Temp4.Y*Size*1.5+Temp3.Y*Size, Temp.Z+Temp4.Z*Size*1.5+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 1.0, 0.0);
       Inc(PolyCount, 2);
      end;
     VB.Unlock;
     Draw;
    end;
   end;
   RandSeed:=WasRandSeed;
  end;
var I: integer;
    Found: Boolean;
begin
 Engine.Textures.SetMaterial(MatGrass, 0);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
 with Group do
  for I:=BitsFrom to BitsTo do
   if PolyBits[I div 8] and (1 shl (I mod 8))>0 then begin
    Found:=False;
    if Group.Surfaces<>nil then
     if Group.Surfaces[I]<>nil then begin
      TTssTempSurface(Group.Surfaces[I]).Draw;
      Found:=True;
     end;
    if not Found then ProcessTriangle(I, Vertices[Indices[I*3+0]].V, Vertices[Indices[I*3+1]].V, Vertices[Indices[I*3+2]].V);
   end;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
end;}

procedure TTssTempSurface.Move(TickCount: Single);
begin
 LastVisible:=LastVisible+TickCount*0.001;
 if LastVisible>SurfaceTempTimeout then Free;
end;

procedure TTssTempSurface.Draw;
begin
 LastVisible:=0;
 if PolyCount>0 then begin
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX);
  Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex));
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, PolyCount);
  Engine.IncPolyCounter(PolyCount);
 end;
end;

constructor TTssTempSurface.Create(Owner: TSurfaceSystem);
begin
 inherited Create;
 System:=Owner;
 System.TempSurfaces.Add(Self);
 LastVisible:=0;
end;

destructor TTssTempSurface.Destroy;
begin
 VB:=nil;
 System.TempSurfaces.Remove(Self);
 Pointer(PolyPointer^):=nil;
 inherited;
end;


constructor TSurfaceSystem.Create;
begin
 inherited;
 TempSurfaces:=TList.Create;
 //Surfaces[1]:=TTssSurfaceGrassRock1.Create(Self);
 //Rock1:=TTssObject.Create(nil, False);
 //Rock1.LoadData('GRock1.obj');
end;

destructor TSurfaceSystem.Destroy;
var I: integer;
begin
 //DynVB:=nil;
 {for I:=0 to 255 do
  if Surfaces[I]<>nil then Surfaces[I].Free;}
 for I:=0 to 255 do
  Surface[I].Free;
 for I:=TempSurfaces.Count-1 downto 0 do
  TObject(TempSurfaces.Items[I]).Free;
 TempSurfaces.Free;
 //Rock1.Free;
 inherited;
end;

procedure TSurfaceSystem.Move(TickCount: Single);
var I: integer;
begin
 for I:=TempSurfaces.Count-1 downto 0 do
  TTssTempSurface(TempSurfaces.Items[I]).Move(TickCount);
end;

procedure TSurfaceSystem.Draw;
  procedure DrawGrass(Group: TMapGroup; SurfaceData: TTssSurfaceData; Density: Single);
    procedure ProcessTriangle(AIndex: integer; const A, B, C: TD3DXVector3);
    var I: integer;
        BA, CA, Temp, Temp2, Temp3, Temp4: TD3DXVector3;
        Distance, Size, Angle, AB, AC: Single;
        Vertices: PVertices;
        TriangePolyCount: integer;
        M: TD3DMatrix;
    begin
     D3DXVec3Subtract(BA, B, A);
     D3DXVec3Subtract(CA, C, A);
     AB:=D3DXVec3Length(VectorSubtract(BA, VectorProjectionNormalized(BA, CA)))*2.5*Density*SurfaceData.GrassDensity;
     AC:=D3DXVec3Length(CA)*2.5*Density*SurfaceData.GrassDensity;
     RandSeed:=Round(A.X*1000+B.X*999);
     TriangePolyCount:=Max(Round(AB*AC*0.5)-1,-Random(2));
     {TriangePolyCount:=0;
     for I:=0 to AB do
      for J:=0 to Round(AC*(1-I/(AB+1)))-1 do
       Inc(TriangePolyCount);}
     if Group.Surfaces=nil then Group.Surfaces:=AllocMem((Group.IndexCount div 3)*SizeOf(Pointer));
     Group.Surfaces[AIndex]:=TTssTempSurface.Create(Self);
     with TTssTempSurface(Group.Surfaces[AIndex]) do begin
      PolyPointer:=@(Group.Surfaces[AIndex]);
      if TriangePolyCount>0 then begin
       Engine.m_pd3dDevice.CreateVertexBuffer(TriangePolyCount*3*SizeOf(T3DVertex), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX, D3DPOOL_DEFAULT, VB);
       VB.Lock(0, 0, PByte(Vertices), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
       PolyCount:=0;
       {for I:=0 to AB do
        for J:=0 to Round(AC*(1-I/(AB+1)))-1 do}
        for I:=0 to TriangePolyCount-1 do begin
         Distance:=Sqr((Random(950)+25)*0.001);
         Size:=(Random(950)+25)*0.001*(1-Distance);
         Temp:=D3DXVector3(A.X+BA.X*Distance+CA.X*Size, A.Y+BA.Y*Distance+CA.Y*Size, A.Z+BA.Z*Distance+CA.Z*Size);
         Size:=Random(1000)*0.001*(SurfaceData.GrassSizeMax-SurfaceData.GrassSizeMin)+SurfaceData.GrassSizeMin;
         Angle:=Random(360);
         D3DXVec3Cross(Temp2, BA, CA);
         D3DXVec3Normalize(Temp3, Temp2);
         D3DXMatrixRotationAxis(M, Temp2, Angle*g_DEGTORAD);
         D3DXVec3TransformCoord(Temp4, D3DXVector3(1.0, 0.0, 0.0), M);
         Vertices[PolyCount*3+0]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp3.X*Size, Temp.Y-Temp3.Y*Size, Temp.Z-Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 0.5, 1.6);
         Vertices[PolyCount*3+1]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp4.X*Size*2+Temp3.X*Size, Temp.Y-Temp4.Y*Size*2+Temp3.Y*Size, Temp.Z-Temp4.Z*Size*2+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0),-0.25, 0.0);
         Vertices[PolyCount*3+2]:=MakeD3DVertex(D3DXVector3(Temp.X+Temp4.X*Size*2+Temp3.X*Size, Temp.Y+Temp4.Y*Size*2+Temp3.Y*Size, Temp.Z+Temp4.Z*Size*2+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 1.25, 0.0);
         Inc(PolyCount);
        end;
       VB.Unlock;
       Draw;
      end;
     end;
     {for I:=0 to AB-1 do
      for J:=0 to Round(AC*(1-I/AB))-1 do
       Inc(TriangePolyCount, 2);
     if Group.Surfaces=nil then Group.Surfaces:=AllocMem((Group.IndexCount div 3)*SizeOf(Pointer));
     Group.Surfaces[AIndex]:=TTssTempSurface.Create(Self);
     with TTssTempSurface(Group.Surfaces[AIndex]) do begin
      PolyPointer:=@(Group.Surfaces[AIndex]);
      if TriangePolyCount>0 then begin
       Engine.m_pd3dDevice.CreateVertexBuffer(TriangePolyCount*3*SizeOf(T3DVertex), D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX, D3DPOOL_DEFAULT, VB);
       VB.Lock(0, 0, PByte(Vertices), D3DLOCK_DISCARD);
       PolyCount:=0;
       for I:=0 to AB-1 do
        for J:=0 to Round(AC*(1-I/AB))-1 do begin
         Distance:=Sqr((Random(950)+25)*0.001);
         Size:=(Random(950)+25)*0.001*(1-Distance);
         Temp:=D3DXVector3(A.X+BA.X*Distance+CA.X*Size, A.Y+BA.Y*Distance+CA.Y*Size, A.Z+BA.Z*Distance+CA.Z*Size);
         Size:=Random(1000)*0.001*(SurfaceData.GrassSizeMax-SurfaceData.GrassSizeMin)+SurfaceData.GrassSizeMin;
         Angle:=Random(360);
         D3DXVec3Cross(Temp2, BA, CA);
         D3DXVec3Normalize(Temp3, Temp2);
         D3DXMatrixRotationAxis(M, Temp2, Angle*g_DEGTORAD);
         D3DXVec3TransformCoord(Temp4, D3DXVector3(1.0, 0.0, 0.0), M);
         Vertices[PolyCount*3+0]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp4.X*Size*1.5, Temp.Y-Temp4.Y*Size*1.5, Temp.Z-Temp4.Z*Size*1.5), D3DXVector3(0.0, 1.0, 0.0), 0.0, 0.75);
         Vertices[PolyCount*3+1]:=MakeD3DVertex(D3DXVector3(Temp.X-Temp4.X*Size*1.5+Temp3.X*Size, Temp.Y-Temp4.Y*Size*1.5+Temp3.Y*Size, Temp.Z-Temp4.Z*Size*1.5+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 0.0, 0.0);
         Vertices[PolyCount*3+2]:=MakeD3DVertex(D3DXVector3(Temp.X+Temp4.X*Size*1.5, Temp.Y+Temp4.Y*Size*1.5, Temp.Z+Temp4.Z*Size*1.5), D3DXVector3(0.0, 1.0, 0.0), 1.0, 0.75);
         Vertices[PolyCount*3+3]:=Vertices[PolyCount*3+2];
         Vertices[PolyCount*3+4]:=Vertices[PolyCount*3+1];
         Vertices[PolyCount*3+5]:=MakeD3DVertex(D3DXVector3(Temp.X+Temp4.X*Size*1.5+Temp3.X*Size, Temp.Y+Temp4.Y*Size*1.5+Temp3.Y*Size, Temp.Z+Temp4.Z*Size*1.5+Temp3.Z*Size), D3DXVector3(0.0, 1.0, 0.0), 1.0, 0.0);
         Inc(PolyCount, 2);
        end;
       VB.Unlock;
       Draw;
      end;
     end;}
    end;
  var I: integer;
      Found: Boolean;
  begin
   Engine.Textures.SetMaterial(SurfaceData.Grass, 0);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
   Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
   Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
   Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
   Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Engine.IdentityMatrix);
   with Group do
    for I:=BitsFrom to BitsTo do
     if Bits[I] then begin
      Found:=False;
      if Group.Surfaces<>nil then
       if Group.Surfaces[I]<>nil then begin
        TTssTempSurface(Group.Surfaces[I]).Draw;
        Found:=True;
       end;
      if not Found then ProcessTriangle(I, Vertices[Indices[I*3+0]].V, Vertices[Indices[I*3+1]].V, Vertices[Indices[I*3+2]].V);
     end;
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
  end;
  procedure DrawObjects(Group: TMapGroup; SurfaceData: TTssSurfaceData; Density: Single);
    procedure ProcessTriangle(const A, B, C: TD3DXVector3);
    var I: integer;
        BA, CA, Temp, Temp2: TD3DXVector3;
        Size, Angle, AB, AC: Single;
    begin
     D3DXVec3Subtract(BA, B, A);
     D3DXVec3Subtract(CA, C, A);
     AB:=D3DXVec3Length(VectorSubtract(BA, VectorProjectionNormalized(BA, CA)))*0.5*Density*SurfaceData.ObjectDensity;
     AC:=D3DXVec3Length(CA)*0.5*Density*SurfaceData.ObjectDensity;
     RandSeed:=Round(A.X*1000+B.X*999);
     for I:=0 to Max(Round(AB*AC*0.5)-1,-Random(2)) do
     {for I:=0 to AB do
      for J:=0 to Round(AC*(1-I/(AB+1)))-1 do} with SurfaceData.Objects.Obj[Random(SurfaceData.Objects.Count)] do begin
       Distance:=Sqr((Random(990)+5)*0.001);//(I+Random(1000)*0.001)/AB;
       Size:=(Random(990)+5)*0.001*(1-Distance);//(J+Random(1000)*0.001)/AC;
       Temp:=D3DXVector3(A.X+BA.X*Distance+CA.X*Size, A.Y+BA.Y*Distance+CA.Y*Size, A.Z+BA.Z*Distance+CA.Z*Size);
       Size:=Random(1000)*0.001*(SurfaceData.ObjectSizeMax-SurfaceData.ObjectSizeMin)+SurfaceData.ObjectSizeMin;
       Angle:=Random(360);
       D3DXVec3Subtract(Temp2, Temp, NearPos);
       Distance:=D3DXVec3LengthSq(Temp2);
       if Distance<Sqr(SurfaceMaxDistance[SurfaceData.Visibility]*0.5) then begin
        D3DXVec3Subtract(Temp2, Temp, Engine.Camera.Pos);
        Distance:=D3DXVec3LengthSq(Temp2);
        if Distance/Sqr(Size)<Sqr(SurfaceMaxDistance[SurfaceData.Visibility]) then begin
         APos:=Temp;
         D3DXVec3Cross(Temp2, BA, CA);
         D3DXMatrixRotationAxis(ARot, Temp2, Angle*g_DEGTORAD);
         Size:=Size*(1-Distance/Sqr(SurfaceMaxDistance[SurfaceData.Visibility]));
         with ARot do begin
          _11:=_11; _12:=_12*Size; _13:=_13;
          _21:=_21; _22:=_22*Size; _23:=_23;
          _31:=_31; _32:=_32*Size; _33:=_33;
         end;
         Draw;
        end;
       end;
      end;
    end;
  var I: integer;
  begin
   Engine.Textures.AlphaRef:=64;
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
   Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
   with Group do
    for I:=BitsFrom to BitsTo do
     if Bits[I] then
      ProcessTriangle(Vertices[Indices[I*3+0]].V, Vertices[Indices[I*3+1]].V, Vertices[Indices[I*3+2]].V);
  end;
var List: TList;
    I: integer;
    WasRandSeed: LongInt;
begin
 WasRandSeed:=RandSeed;
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP);
 List:=TList.Create;
 D3DXVec3TransformCoord(NearPos, D3DXVector3(0.0, 0.0, SurfaceMaxDistance[1]*0.5), Engine.Camera.Rot);
 NearPos.X:=NearPos.X+Engine.Camera.Pos.X;
 NearPos.Y:=NearPos.Y+Engine.Camera.Pos.Y;
 NearPos.Z:=NearPos.Z+Engine.Camera.Pos.Z;
 Engine.GameMap.CollectGroupsMap(List, NearPos.X, NearPos.Y, NearPos.Z, SurfaceMaxDistance[1]*0.5);
 for I:=0 to List.Count-1 do
  if TObject(List.Items[I]) is TMapGroup then
   with TMapGroup(List.Items[I]).Material do
    if Surface[SurfaceType].Visibility=1 then begin
     if (Surface[SurfaceType].Objects.Count>0) and (SurfaceObjDensity>0) then DrawObjects(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceObjDensity*0.01);
     if (Surface[SurfaceType].Grass.Name<>'') and (SurfaceGrassDensity>0) then DrawGrass(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceGrassDensity*0.01);
    end;
 List.Clear;
 D3DXVec3TransformCoord(NearPos, D3DXVector3(0.0, 0.0, SurfaceMaxDistance[2]*0.5), Engine.Camera.Rot);
 NearPos.X:=NearPos.X+Engine.Camera.Pos.X;
 NearPos.Y:=NearPos.Y+Engine.Camera.Pos.Y;
 NearPos.Z:=NearPos.Z+Engine.Camera.Pos.Z;
 Engine.GameMap.CollectGroupsMap(List, NearPos.X, NearPos.Y, NearPos.Z, SurfaceMaxDistance[2]*0.5);
 for I:=0 to List.Count-1 do
  if TObject(List.Items[I]) is TMapGroup then
   with TMapGroup(List.Items[I]).Material do
    if Surface[SurfaceType].Visibility=2 then begin
     if (Surface[SurfaceType].Objects.Count>0) and (SurfaceObjDensity>0) then DrawObjects(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceObjDensity*0.01);
     if (Surface[SurfaceType].Grass.Name<>'') and (SurfaceGrassDensity>0) then DrawGrass(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceGrassDensity*0.01);
    end;
 List.Clear;
 D3DXVec3TransformCoord(NearPos, D3DXVector3(0.0, 0.0, SurfaceMaxDistance[3]*0.5), Engine.Camera.Rot);
 NearPos.X:=NearPos.X+Engine.Camera.Pos.X;
 NearPos.Y:=NearPos.Y+Engine.Camera.Pos.Y;
 NearPos.Z:=NearPos.Z+Engine.Camera.Pos.Z;
 Engine.GameMap.CollectGroupsMap(List, NearPos.X, NearPos.Y, NearPos.Z, SurfaceMaxDistance[3]*0.5);
 for I:=0 to List.Count-1 do
  if TObject(List.Items[I]) is TMapGroup then
   with TMapGroup(List.Items[I]).Material do
    if Surface[SurfaceType].Visibility=3 then begin
     if (Surface[SurfaceType].Objects.Count>0) and (SurfaceObjDensity>0) then DrawObjects(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceObjDensity*0.01);
     if (Surface[SurfaceType].Grass.Name<>'') and (SurfaceGrassDensity>0) then DrawGrass(TMapGroup(List.Items[I]), Surface[SurfaceType], SurfaceGrassDensity*0.01);
    end;
 List.Free;
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSU, D3DTADDRESS_WRAP);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ADDRESSV, D3DTADDRESS_WRAP);
 RandSeed:=WasRandSeed;
end;

procedure TSurfaceSystem.LoadData(Stream: TStream);
var SData: packed record
      ObjectCount: Byte;
      Visibility: Byte;
      GrassDensity: Single;
      GrassSizeMin: Single;
      GrassSizeMax: Single;
      ObjectDensity: Single;
      ObjectSizeMin: Single;
      ObjectSizeMax: Single;           
      Grass: string[10];
      Objects: array[0..255] of string[10];
    end;
    I, J: integer;
begin
 for I:=0 to 255 do begin
  Stream.Read(SData, 37);
  if SData.ObjectCount>0 then Stream.Read(SData.Objects, SData.ObjectCount*11);
  Surface[I]:=TTssSurfaceData.Create;
  Surface[I].Visibility:=SData.Visibility;
  Surface[I].GrassDensity:=SData.GrassDensity;
  Surface[I].GrassSizeMin:=SData.GrassSizeMin;
  Surface[I].GrassSizeMax:=SData.GrassSizeMax;
  Surface[I].ObjectDensity:=SData.ObjectDensity;
  Surface[I].ObjectSizeMin:=SData.ObjectSizeMin;
  Surface[I].ObjectSizeMax:=SData.ObjectSizeMax;
  Surface[I].Grass.Name:=SData.Grass;
  for J:=0 to SData.ObjectCount-1 do begin
   Surface[I].Objects.Add(TTssObject.Create(nil, False));
   Surface[I].Objects.Obj[J].LoadData(SData.Objects[J]+'.obj');
   Surface[I].Objects.Obj[J].FastDraw:=True;
  end;
 end;
end;

end.
