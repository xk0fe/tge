{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Alpha Unit                             *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssAlpha;

interface

uses
  Windows, Classes, Direct3D8, D3DX8, TssUtils, SysUtils, TssTextures, Math;

const
  MaxAlphaPolys = 4;

type
  TAlphaData = record
    case Integer of
     0: (
      srcObj: Pointer;
      srcIndex: Byte;
      Matrix: PD3DMatrix;
     );
     1: (
      Size: Single;
      X, Y, Z: Single;
      Color: DWord;
     );
  end;
  TAlphaItem = class(TObject)
  public
    PType: Byte;
    DistanceSqr: Single;
    txClass, txIndex: Byte;
    Data: TAlphaData;
  end;

  TAlphaSystem = class(TObject)
  private
    AlphaList: TList;
    //VB: IDirect3DVertexBuffer8;
    PointMaterial: TTssMaterial;
  public
    constructor Create;
    destructor Destroy; override;
    procedure NewAlpha(AData: TAlphaData; PType: Byte);
    procedure Draw;
  end;
  
function AlphaData1(ASrcObj: Pointer; ASrcIndex: Byte; AMatrix: PD3DMatrix): TAlphaData;
function AlphaData2(Size, X, Y, Z: Single; Color: DWord): TAlphaData;

implementation

uses
  TssEngine, TssObjects, TssMap;

function AlphaData1(ASrcObj: Pointer; ASrcIndex: Byte; AMatrix: PD3DMatrix): TAlphaData;
begin
 Result.srcObj:=ASrcObj;
 Result.srcIndex:=ASrcIndex;
 Result.Matrix:=AMatrix;
end;

function AlphaData2(Size, X, Y, Z: Single; Color: DWord): TAlphaData;
begin
 Result.Size:=Size;
 Result.X:=X;
 Result.Y:=Y;
 Result.Z:=Z;
 Result.Color:=Color;
end;

constructor TAlphaSystem.Create;
begin
 inherited;
 AlphaList:=TList.Create;
 PointMaterial.Name:='PLight';
end;

destructor TAlphaSystem.Destroy;
begin
 AlphaList.Free;
 //VB:=nil;
 inherited;
end;

procedure TAlphaSystem.NewAlpha(AData: TAlphaData; PType: Byte);
var Item: TAlphaItem;
    aX, aY, aZ, aW: Single;
begin
 Item:=TAlphaItem.Create;    
 case PType of
  0: begin
   if TTssObject(AData.srcObj).SharedBuffers then with TTssObject(AData.srcObj).Parent.Details[0].Vertices[0].V1 do begin
    aX:=X*AData.Matrix._11+Y*AData.Matrix._21+Z*AData.Matrix._31+AData.Matrix._41;
    aY:=X*AData.Matrix._12+Y*AData.Matrix._22+Z*AData.Matrix._32+AData.Matrix._42;
    aZ:=X*AData.Matrix._13+Y*AData.Matrix._23+Z*AData.Matrix._33+AData.Matrix._43;
    aW:=X*AData.Matrix._14+Y*AData.Matrix._24+Z*AData.Matrix._34+AData.Matrix._44;
   end else with TTssObject(AData.srcObj).Details[0].Vertices[0].V1 do begin
    aX:=X*AData.Matrix._11+Y*AData.Matrix._21+Z*AData.Matrix._31+AData.Matrix._41;
    aY:=X*AData.Matrix._12+Y*AData.Matrix._22+Z*AData.Matrix._32+AData.Matrix._42;
    aZ:=X*AData.Matrix._13+Y*AData.Matrix._23+Z*AData.Matrix._33+AData.Matrix._43;
    aW:=X*AData.Matrix._14+Y*AData.Matrix._24+Z*AData.Matrix._34+AData.Matrix._44;
   end;
   if Abs(aW)>=g_EPSILON then begin
    aX:=aX/aW;
    aY:=aY/aW;
    aZ:=aZ/aW;
   end;
   Item.DistanceSqr:=Sqr(Engine.Camera.Pos.X-aX)+Sqr(Engine.Camera.Pos.Y-aY)+Sqr(Engine.Camera.Pos.Z-aZ);
   Item.Data.srcObj:=AData.srcObj;
   Item.Data.srcIndex:=AData.srcIndex;
   Item.Data.Matrix:=AData.Matrix;
  end;
  2: begin
   Item.Data:=AData;
   Item.DistanceSqr:=Sqr(Engine.Camera.Pos.X-AData.X)+Sqr(Engine.Camera.Pos.Y-AData.Y)+Sqr(Engine.Camera.Pos.Z-AData.Z);
  end;
 end;
 Item.PType:=PType;
 AlphaList.Add(Item);
end;

function AlphaListSort(Item1, Item2: Pointer): Integer;
begin
 Result:=Round((TAlphaItem(Item1).DistanceSqr-TAlphaItem(Item2).DistanceSqr)*1000.0);
end;

procedure TAlphaSystem.Draw;
var I{, J}: integer;
    //PVB: PAlphaColorVertex;
    WasMatrix, NowMatrix: PD3DMatrix;
    WasLight: Boolean;
    Vertex: TPointVertex;
    //Surface: IDirect3DSurface8;
    //Locked: D3DLOCKED_RECT;

  function PolyListSort(Item1, Item2: Word): Integer;
  var V1, V2: TD3DXVector3;
      Diff: Single;
  begin
   with TAlphaItem(AlphaList.Items[I]) do
   with TTssObject(Data.srcObj).Details[0] do begin
    D3DXVec3Subtract(V1, Vertices[Indices[Item1+2]].V2, Engine.Camera.Pos);
    D3DXVec3Subtract(V2, Vertices[Indices[Item2+2]].V2, Engine.Camera.Pos);
    Diff:=(Sqr(V1.X)-Sqr(V2.X))+(Sqr(V1.Y)-Sqr(V2.Y))+(Sqr(V1.Z)-Sqr(V2.Z));
    if Diff<0 then Result:=1
     else if Diff>0 then Result:=-1
      else Result:=0;
   end;
  end;
  function SortPolyIndices: Boolean;
  var N, M, A: integer;
      Temp: Word;
  begin
   Result:=False;
   with TAlphaItem(AlphaList.Items[I]) do with TTssObject(Data.srcObj).Details[0] do with TMeshData(MeshData.Items[Data.srcIndex]) do begin
    for N:=1 to IndexCount div 3-1 do begin
     A:=-1;
     for M:=N-1 downto 0 do
      if PolyListSort(PolyIndices[M], PolyIndices[N])>0 then A:=M else Break;
     if A>=0 then begin
      Result:=True;
      Temp:=PolyIndices[A];
      PolyIndices[A]:=PolyIndices[N];
      PolyIndices[N]:=Temp;
     end;
    end;
   end;
  end;
begin
 AlphaList.Sort(AlphaListSort);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALEENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE, FloatAsInt(1.0));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSIZE_MIN, FloatAsInt(0.5));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_A, FloatAsInt(0.0));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_B, FloatAsInt(0.0));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSCALE_C, FloatAsInt(1.0));
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);       
 Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 //Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE4X);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
 WasLight:=True;
 WasMatrix:=nil;
 for I:=AlphaList.Count-1 downto 0 do with TAlphaItem(AlphaList.Items[I]) do begin
  if PType=2 then begin
   if WasLight then begin
    Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iFalse);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, $FFFFFF);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iFalse);
    //Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);
   end;
   WasLight:=False;
   NowMatrix:=@Engine.IdentityMatrix;
  end else begin
   if not WasLight then begin
    Engine.m_pd3dDevice.SetRenderState(D3DRS_LIGHTING, iTrue);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_ZWRITEENABLE, iTrue);
    //Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
   end;
   WasLight:=True;
   NowMatrix:=Data.Matrix;
  end; 
  if NowMatrix<>WasMatrix then Engine.m_pd3dDevice.SetTransform(D3DTS_WORLD, NowMatrix^);
  case PType of
   0: with TTssObject(Data.srcObj).Details[0] do begin
        with TMeshData(MeshData.Items[Data.srcIndex]) do begin
         if TTssObject(Data.srcObj).SharedBuffers then begin
          Engine.m_pd3dDevice.SetStreamSource(0, TTssObject(Data.srcObj).Parent.Details[0].VB, SizeOf(T3DVertex2TxColor));
          Engine.m_pd3dDevice.SetIndices(TTssObject(Data.srcObj).Parent.Details[0].IB, 0);
         end else begin
          Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex2TxColor));
          Engine.m_pd3dDevice.SetIndices(IB, 0);
         end;
         Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX2TXCOLOR);
         Engine.Textures.SetMaterial(Material, 0);
         Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round(TTssObject(Data.srcObj).FAlpha*(1-Material.Reflection*0.01)*255), 255, 255, 255));
         //Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
         {D3DXVec3Subtract(V0, TTssObject(Data.srcObj).APos, Engine.Camera.Pos);
         if D3DXVec3LengthSq(V0)<200 then begin
          if D3DXMatrixEqual(TTssObject(Data.srcObj).Details[0].PreCalculated, TTssObject(Data.srcObj).Matrix) then SortPolyIndices;
          for J:=0 to IndexCount div 3-1 do begin
           Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, StartVertex, VertexCount, PolyIndices[J], 1);
           Engine.IncPolyCounter(1);
          end;
         end else begin}
          Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, StartVertex, VertexCount, StartIndex, IndexCount div 3);
          Engine.IncPolyCounter(IndexCount div 3);
         //end;
         {Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex));
         Engine.m_pd3dDevice.SetIndices(AlphaIB, 0);
         Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX);
         Engine.Textures.SetMaterial(Material, 0);
         Engine.m_pd3dDevice.DrawIndexedPrimitive(D3DPT_TRIANGLELIST, StartVertex, VertexCount, 0, IndexCount div 3);
         Engine.IncPolyCounter(IndexCount div 3);}
        end;
      end;
   {1: with TMapPoly(Data.srcObj) do begin
        Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T3DVertex));
        Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX);
        Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, VertexCount-2);
        Engine.IncPolyCounter(VertexCount-2);
      end;}
   2: if Options.UsePointSprites then begin
        {if VB=nil then Engine.m_pd3dDevice.CreateVertexBuffer(4*SizeOf(TAlphaColorVertex), D3DUSAGE_DYNAMIC, D3DFVF_ALPHACOLORVERTEX, D3DPOOL_DEFAULT, VB);

        D3DXVec3Normalize(V0, MakeD3DVector(Engine.Camera.Pos.X-Data.X,Engine.Camera.Pos.Y-Data.Y,Engine.Camera.Pos.Z-Data.Z));
        V2:=MakeD3DVector(0,1,0);
        D3DXVec3Normalize(V1,MakeD3DVector(V0.Y*V2.Z-V0.Z*V2.Y,V0.Z*V2.X-V0.X*V2.Z,V0.X*V2.Y-V0.Y*V2.X));
        D3DXVec3Normalize(V2,MakeD3DVector(V0.Y*V1.Z-V0.Z*V1.Y,V0.Z*V1.X-V0.X*V1.Z,V0.X*V1.Y-V0.Y*V1.X));

        VB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
        PVB^:=MakeAlphaColorVertex(Data.X+(-V1.X+V2.X)*Data.Size+V0.X*0.2, Data.Y+(-V1.Y+V2.Y)*Data.Size+V0.Y*0.2, Data.Z+(-V1.Z+V2.Z)*Data.Size+V0.Z*0.2, 0, 0, Data.Color); Inc(PVB);
        PVB^:=MakeAlphaColorVertex(Data.X+(+V1.X+V2.X)*Data.Size+V0.X*0.2, Data.Y+(+V1.Y+V2.Y)*Data.Size+V0.Y*0.2, Data.Z+(+V1.Z+V2.Z)*Data.Size+V0.Z*0.2, 1, 0, Data.Color); Inc(PVB);
        PVB^:=MakeAlphaColorVertex(Data.X+(-V1.X-V2.X)*Data.Size+V0.X*0.2, Data.Y+(-V1.Y-V2.Y)*Data.Size+V0.Y*0.2, Data.Z+(-V1.Z-V2.Z)*Data.Size+V0.Z*0.2, 0, 1, Data.Color); Inc(PVB);
        PVB^:=MakeAlphaColorVertex(Data.X+(+V1.X-V2.X)*Data.Size+V0.X*0.2, Data.Y+(+V1.Y-V2.Y)*Data.Size+V0.Y*0.2, Data.Z+(+V1.Z-V2.Z)*Data.Size+V0.Z*0.2, 1, 1, Data.Color); Inc(PVB);
        VB.Unlock;
        
        Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(TAlphaColorVertex));
        Engine.m_pd3dDevice.SetVertexShader(D3DFVF_ALPHACOLORVERTEX);
        Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
        Engine.IncPolyCounter(2);}

        {D3DXVec3TransformCoord(V0, TD3DXVector3((@(Data.X))^), Engine.ScreenMat);
        X:=Round(V0.X);
        Y:=Round(V0.Y);

        Engine.m_pd3dDevice.GetDepthStencilSurface(DepthSurface);
        LockRect:=Rect(X, Y, X, Y);
        if not FAILED(DepthSurface.LockRect(LockedRect, @LockRect, D3DLOCK_READONLY)) then begin
         Engine.TestValue:=IntToStr(Word(LockedRect.pBits^));
         DepthSurface.UnlockRect;
        end;
        DepthSurface:=nil;}

        Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(255, 0, 0, 0));
        Engine.Textures.SetMaterial(PointMaterial, 0);
        Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEXPOINT);
        Vertex.V.X:=Data.X;
        Vertex.V.Y:=Data.Y;
        Vertex.V.Z:=Data.Z;
        Vertex.Size:=Data.Size;
        Vertex.Color:=Data.Color;
        Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_POINTLIST, 1, Vertex, SizeOf(TPointVertex));
        Engine.IncPolyCounter(1);

   end;
  end;
  WasMatrix:=NowMatrix;
  Free;
 end;
 AlphaList.Clear;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_AMBIENT, Engine.AmbientLight);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_POINTSPRITEENABLE, iFalse);
 {if Engine.m_pd3dDevice.GetBackBuffer(0, D3DBACKBUFFER_TYPE_MONO, Surface)=D3D_OK then begin
  if Surface.LockRect(Locked, nil, D3DLOCK_READONLY)=D3D_OK then
   Engine.TestValue:=IntToStr(Locked.Pitch);
  Surface.UnlockRect;
 end;
 Surface:=nil;}
end;

end.
