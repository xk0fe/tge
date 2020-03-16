{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Shadows Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssShadows;

interface

uses
  Windows, TssUtils, SysUtils, Direct3D8, D3DX8;

const
  Max_Shadow_Vertices = 1024;
  Max_Shadow_Indices = 1536;

  D3DFVF_SHADOWVERTEX = (D3DFVF_XYZ);

type
  // Internal data types
  TShadowLine = record
    Vertex1, Vertex2: Word;
    Poly1, Poly2: Word;
  end;
  PShadowLines = ^TShadowLines;
  TShadowLines = array[0..0] of TShadowLine;
  TShadowPoly = record
    Normal: TD3DXVector3;
    Front: Boolean;
  end;
  PShadowPolys = ^TShadowPolys;
  TShadowPolys = array[0..0] of TShadowPoly;

  PShadowVertex = ^TShadowVertex;
  TShadowVertex = packed record
    case Integer of
     0: (
       X, Y, Z: Single;
     );
     1: (
       vV: TD3DXVector3;
     );
  end;

  // Precalculation data to be stored into each mesh
  TShadowData = record
    Calculated: Boolean;
    LineCount: Word;
    PolyCount: Word;
    Lines: PShadowLines;
    Polys: PShadowPolys;
  end;

  // The main class to calculate and draw shadows
  TShadowPainter = class(TObject)
  private
    VB: IDirect3DVertexBuffer8;
    IB: IDirect3DIndexBuffer8;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure CalculateData(
        var Data: TShadowData;
        const StartVertex, VertexCount, StartIndex, IndexCount: Word;
        const Vertices: PObjDataVertices;
        const Indices: PIndices
    );
    procedure DrawDirectional(
        var Data: TShadowData;
        const StartVertex, VertexCount, StartIndex, IndexCount: Word;
        const Vertices: PObjDataVertices;
        const Indices: PIndices;
        const Light: TD3DXVector3;
        const Matrix: TD3DMatrix
    );
    procedure FreeData(var Data: TShadowData);
  end;

implementation

uses
  TssEngine;


constructor TShadowPainter.Create;
begin
 inherited;
 VB:=nil;
 IB:=nil;
end;

destructor TShadowPainter.Destroy;
begin
 VB:=nil;
 IB:=nil;
 inherited;
end;

procedure TShadowPainter.CalculateData(
        var Data: TShadowData;
        const StartVertex, VertexCount, StartIndex, IndexCount: Word;
        const Vertices: PObjDataVertices;
        const Indices: PIndices
);
var I, J: integer;
    V, V1, V2: TD3DXVector3;
begin
 FreeData(Data);
 
 Data.LineCount:=IndexCount;
 Data.PolyCount:=IndexCount div 3;
 Data.Lines:=AllocMem(Data.LineCount*SizeOf(TShadowLine));
 Data.Polys:=AllocMem(Data.PolyCount*SizeOf(TShadowPoly));
                                     
 for I:=0 to Data.PolyCount-1 do begin
  D3DXVec3Subtract(V1, Vertices[Indices[I*3+1+StartIndex]].V1, Vertices[Indices[I*3+StartIndex]].V1);
  D3DXVec3Subtract(V2, Vertices[Indices[I*3+2+StartIndex]].V1, Vertices[Indices[I*3+StartIndex]].V1);
  D3DXVec3Cross(V, V1, V2);
  D3DXVec3Normalize(Data.Polys[I].Normal, V);

  with Data.Lines[I*3+0] do begin
   Poly1:=I;
   Poly2:=65535;
   Vertex1:=Indices[I*3+0+StartIndex];
   Vertex2:=Indices[I*3+1+StartIndex];
  end;
  with Data.Lines[I*3+1] do begin
   Poly1:=I;
   Poly2:=65535;
   Vertex1:=Indices[I*3+1+StartIndex];
   Vertex2:=Indices[I*3+2+StartIndex];
  end;
  with Data.Lines[I*3+2] do begin
   Poly1:=I;
   Poly2:=65535;
   Vertex1:=Indices[I*3+2+StartIndex];
   Vertex2:=Indices[I*3+0+StartIndex];
  end;
  
 end;

 for I:=0 to Data.LineCount-1 do
  if Data.Lines[I].Poly1<65535 then
   for J:=0 to Data.LineCount-1 do
    if (Data.Lines[J].Poly1<65535) and (Data.Lines[J].Poly2=65535) then
     if D3DXVector3Equal(Vertices[Data.Lines[I].Vertex1].V1, Vertices[Data.Lines[J].Vertex2].V1) then
      if D3DXVector3Equal(Vertices[Data.Lines[I].Vertex2].V1, Vertices[Data.Lines[J].Vertex1].V1) then begin
       Data.Lines[I].Poly2:=Data.Lines[J].Poly1;
       Data.Lines[J].Poly1:=65535;
      end;

 J:=0;
 while Data.LineCount>0 do begin
  while Data.Lines[Data.LineCount-1].Poly1=65535 do begin
   Dec(Data.LineCount);
   if Data.LineCount=0 then Break;
  end;
  if J>=Data.LineCount then Break;
  while Data.Lines[J].Poly1<65535 do begin
   Inc(J);
   if J>=Data.LineCount then Break;
  end;
  if J>=Data.LineCount then Break;
  Data.Lines[J]:=Data.Lines[Data.LineCount-1];
  Dec(Data.LineCount);
 end;
 ReAllocMem(Data.Lines, Data.LineCount*SizeOf(TShadowLine));

 Data.Calculated:=True;
end;

procedure TShadowPainter.FreeData(var Data: TShadowData);
begin
 if Data.Calculated then begin
  FreeMem(Data.Lines);
  FreeMem(Data.Polys);
  Data.Calculated:=False;
 end;
end;

// Procedures to draw shadow of any CONVEX object.

procedure TShadowPainter.DrawDirectional(
        var Data: TShadowData;
        const StartVertex, VertexCount, StartIndex, IndexCount: Word;
        const Vertices: PObjDataVertices;
        const Indices: PIndices;
        const Light: TD3DXVector3;
        const Matrix: TD3DMatrix
);
var I, VCount, ICount: integer;
    PVB: PShadowVertex;
    PIB: PIndex;
    V1, V2: TD3DXVector3;
    InvMat, TempMat: TD3DMatrix;
    Temp: Single;
    IsEdge: Boolean;
begin
 if not Data.Calculated then CalculateData(Data, StartVertex, VertexCount, StartIndex, IndexCount, Vertices, Indices);

 if VB=nil then Engine.m_pd3dDevice.CreateVertexBuffer(Max_Shadow_Vertices*SizeOf(TShadowVertex), D3DUSAGE_DYNAMIC, D3DFVF_SHADOWVERTEX, D3DPOOL_DEFAULT, VB);
 if IB=nil then Engine.m_pd3dDevice.CreateIndexBuffer(Max_Shadow_Indices*SizeOf(TIndex), D3DUSAGE_DYNAMIC, D3DFMT_INDEX16, D3DPOOL_DEFAULT, IB);

 // Calculate light vector in object space and set length to 1000
 TempMat:=Matrix;
 TempMat._41:=0; TempMat._42:=0; TempMat._43:=0;
 D3DXMatrixInverse(InvMat, @Temp, TempMat);
 D3DXVec3TransformCoord(V1, Light, InvMat);
 D3DXVec3Normalize(V2, V1);                   
 D3DXVec3Scale(V1, V2, 1000);

 for I:=0 to Data.PolyCount-1 do
  with Data.Polys[I] do Front:=(D3DXVec3Dot(V2, Normal)<=0);
                                                        
 VCount:=0;
 ICount:=0; 
 VB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
 IB.Lock(0, 0, PByte(PIB), D3DLOCK_DISCARD);

 {for I:=StartVertex to StartVertex+VertexCount-1 do begin
  PVB.vV:=Vertices[I].V1; Inc(PVB);
 end;
 Inc(VCount, VertexCount);
 for I:=0 to IndexCount div 3-1 do begin
  PIB^:=Indices[StartIndex+I*3+2]; Inc(PIB);
  PIB^:=Indices[StartIndex+I*3+1]; Inc(PIB);
  PIB^:=Indices[StartIndex+I*3]; Inc(PIB);
 end;
 Inc(ICount, IndexCount);}

 for I:=0 to Data.LineCount-1 do
  with Data.Lines[I] do begin
   if Poly2<65535 then IsEdge:=(Data.Polys[Poly1].Front<>Data.Polys[Poly2].Front)
    else IsEdge:=Data.Polys[Poly1].Front;
   if IsEdge then begin
    PVB.vV:=Vertices[Vertex2].V1; Inc(PVB);
    PVB.vV:=Vertices[Vertex1].V1; Inc(PVB);
    PVB.X:=Vertices[Vertex2].V1.X+V1.X; PVB.Y:=Vertices[Vertex2].V1.Y+V1.Y; PVB.Z:=Vertices[Vertex2].V1.Z+V1.Z; Inc(PVB);
    PVB.X:=Vertices[Vertex1].V1.X+V1.X; PVB.Y:=Vertices[Vertex1].V1.Y+V1.Y; PVB.Z:=Vertices[Vertex1].V1.Z+V1.Z; Inc(PVB);

    PIB^:=VCount; Inc(PIB);
    PIB^:=VCount+2-Ord(Data.Polys[Poly1].Front); Inc(PIB);
    PIB^:=VCount+1+Ord(Data.Polys[Poly1].Front); Inc(PIB);
    PIB^:=VCount+2; Inc(PIB);
    PIB^:=VCount+3-2*Ord(Data.Polys[Poly1].Front); Inc(PIB);
    PIB^:=VCount+1+2*Ord(Data.Polys[Poly1].Front); Inc(PIB);

    Inc(VCount, 4);
    Inc(ICount, 6);
   end;
  end;

 VB.Unlock;
 IB.Unlock;

 Engine.Textures.SetMaterial(Engine.Material, 0);

 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_SHADOWVERTEX);
 Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, Matrix);
 Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(TShadowVertex));
 Engine.m_pd3dDevice.SetIndices(IB, 0);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILFUNC, D3DCMP_ALWAYS);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILREF, $1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILMASK, $ffffffff);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILWRITEMASK, $ffffffff);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILZFAIL, D3DSTENCILOP_KEEP);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILFAIL, D3DSTENCILOP_KEEP);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_INCR);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ZERO);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(64, 0, 0, 0));

 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);

 // First pass - Draw front faces of shadow volume increasing stencil
 Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, VCount, 0, ICount div 3);
 Engine.IncPolyCounter(ICount div 3);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CW);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILREF, $0);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_DECR);

 // Second pass - Draw back faces of shadow volume decreasing stencil
 Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, VCount, 0, ICount div 3);
 Engine.IncPolyCounter(ICount div 3);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILREF, $1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILFUNC, D3DCMP_EQUAL);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_INCR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);

 // Third pass - Draw front faces again, now draw color to targetsurface (only if stencil is 1)
 Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, VCount, 0, ICount div 3);
 Engine.IncPolyCounter(ICount div 3);
end;

end.
