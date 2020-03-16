{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Texture Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssTextures;

interface

uses
  Windows, SysUtils, Classes, Direct3D8, D3DX8, TssFiles, TssUtils, Math;

const
  Max_Text_Length = 1024;

  MATTYPE_NONE          = 255;
  MATTYPE_NONEUP        = 254;

  MATTYPE_DEFAULT       = 000;
  MATTYPE_GRASS         = 002;
  MATTYPE_SAND          = 003;
  MATTYPE_COLORED1      = 004;
  MATTYPE_COLORED2      = 005;
  MATTYPE_COLORED3      = 006;
  MATTYPE_ALPHAGLASS    = 007;
  MATTYPE_MAPPEDGLASS   = 008;
  MATTYPE_INVISIBLE     = 009;

type
  TTextureSystem = class;
  TTextureString = string[31];

  // Internal Data Types
  PTssTexture = ^TTssTexture;
  TTssTexture = packed record
    Name: TTextureString;
    FileIndex: Word;
    Texture: IDirect3DTexture8;
    LastUse: Single;
    Loading: Boolean;
  end;
  PTssTextures = ^TTssTextures;
  TTssTextures = array[0..0] of TTssTexture;

  // Material Data
  PTssMaterial = ^TTssMaterial;
  TTssMaterial = packed record
    Name, DetailNm: TTextureString;
    Reflection: Byte;
    Opacity: Byte;
    MatType: Byte;
    CanHide: Boolean;
    BumpHorz, BumpVert: Byte;
    SurfaceType, SurfaceGrassDensity, SurfaceObjDensity: Byte;
    NoWrapU, NoWrapV: Boolean;
    NoEffects: Boolean;

    //Internal Variables
    NotFound: Boolean;
    Texture, DetailTx: PTssTexture;
  end;

  // Internal Font types
  TTssFont = record
    Material: TTssMaterial;
    Letters: array[#0..#255] of packed record
      Line, Column, Width: Byte;
    end;
  end;
  PTssFonts = ^TTssFonts;
  TTssFonts = array[0..0] of TTssFont;

  // Internal Thread Class to load textures dynamically without interupting the main process
  TTextureLoader = class(TThread)
  private
    FToLoad: PTssTexture;
    FSystem: TTextureSystem;
  protected
    procedure Execute; override;
  public
    constructor Create(TssTx: PTssTexture; System: TTextureSystem); overload;
    destructor Destroy; override;
  end;

  // Finally the texturesystem that the game engine should use
  TTextureSystem = class(TObject)
  private
    TextureCount: Word;
    Textures: PTssTextures;
    FilePack: TTssFilePack;
    Loader: TTextureLoader;
    EnvMap50: IDirect3DCubeTexture8;

    FontCount: Byte;
    //FontVertices: array[0..Max_Text_Length*6-1] of T2DVertex;
    FontVB2D: IDirect3DVertexBuffer8;

    function GetTexture(const Name: string): PTssTexture;
    function GetCubeTx: IDirect3DCubeTexture8;
    procedure LoadTexture(var Material: TTssMaterial);

    function FillFontBuffer2D(Font: Byte; X, Y, ScaleHorz, ScaleVert, AddHorz, AddVert, LineSpace, CharSpace: Single; const Text: string): integer;
  public
    Loading: integer; // internal
    FastMode: Boolean;
    AlphaRef: Byte;
    Fonts: PTssFonts;
    LastMaterial: TTssMaterial;

    constructor Create(const Path, FileName: string);
    destructor Destroy; override;

    procedure Move(TickCount: Single);

    procedure DelayedLoad(var Material: TTssMaterial);
    procedure FastLoad(var Material: TTssMaterial);
    procedure FastUnload(var Material: TTssMaterial);

    procedure SetReflection(var Material: TTssMaterial; Index: integer);
    procedure SetTexture(var Material: TTssMaterial; Index: integer);
    procedure SetOpacity(var Material: TTssMaterial; Index: integer);
    procedure SetWrapU(var Material: TTssMaterial; Index: integer);
    procedure SetWrapV(var Material: TTssMaterial; Index: integer);
    procedure SetDetails(var Material: TTssMaterial; Index: integer);

    procedure SetMaterial(var Material: TTssMaterial; Index: integer);
    property CubeTx: IDirect3DCubeTexture8 read GetCubeTx;

    procedure InitFonts(const Path, FileName: string);
    procedure DrawText2D(Font: Byte; X, Y, ScaleHorz, ScaleVert, LineSpace, CharSpace: Single; const Text: string);
    procedure DrawText2DShadow(Font: Byte; X, Y, ScaleHorz, ScaleVert, LineSpace, CharSpace, ShadowSize, OffsetX, OffsetY: Single; ShadowColor, TextColor: Cardinal; const Text: string);
    function TextWidth(Font: Byte; ScaleHorz, CharSpace: Single; const Text: string): Single;
    function TextHeight(Font: Byte; ScaleVert, LineSpace: Single; const Text: string): Single;
  end;

function IsMaterialHard(MatType: Byte): Boolean;

implementation

uses
  TssEngine;

function IsMaterialHard(MatType: Byte): Boolean;
begin
 Result:=MatType=MATTYPE_DEFAULT;
end;

constructor TTextureSystem.Create(const Path, FileName: string);
var I: integer;
begin
 inherited Create;
 FilePack:=TTssFilePack.Create(Path, FileName, Options.LockData, Options.PreferPacked);
 FastMode:=True;
 AlphaRef:=128;

 TextureCount:=FilePack.Count;
 Textures:=AllocMem(TextureCount*SizeOf(TTssTexture));
 for I:=0 to TextureCount-1 do begin
  Textures[I].FileIndex:=I;
  Textures[I].Name:=ChangeFileExt(FilePack.Header[I].FileName, '');
 end;
end;

destructor TTextureSystem.Destroy;
var I: integer;
begin
 for I:=0 to TextureCount-1 do
  Textures[I].Texture:=nil;
 FreeMem(Textures);
 FilePack.Free;
 FreeMem(Fonts);
 //FontVB2D:=nil;
 if Options.UseCubeMap then EnvMap50:=nil;
 if Loader<>nil then Loader.Terminate;
 inherited;
end;

procedure TTextureSystem.Move(TickCount: Single);   // Unload unused (minute timeout) textures
//var I: integer;
begin
 {for I:=0 to TextureCount-1 do with Textures[I] do
  if LastUse<>0 then begin
   LastUse:=LastUse+TickCount;
   if LastUse>60000 then begin
    LastUse:=0;
    Texture:=nil;
   end;
 end;}
end;

procedure TTextureSystem.LoadTexture(var Material: TTssMaterial);
begin
 if Material.Texture=nil then Material.Texture:=GetTexture(Material.Name);
 if Material.DetailNm<>'' then if Material.DetailTx=nil then Material.DetailTx:=GetTexture(Material.DetailNm);
 if FastMode then FastLoad(Material)
  else begin
   if Material.Texture.Texture=nil then begin
    if (Loading<Options.TXLMaxThreads) and (not Material.Texture.Loading) then begin
     Inc(Loading);
     Material.Texture.Loading:=True;
     Loader:=TTextureLoader.Create(Material.Texture, Self);
    end;
   end;
   if Material.DetailNm<>'' then if Material.DetailTx.Texture=nil then begin
    if (Loading<Options.TXLMaxThreads) and (not Material.DetailTx.Loading) then begin
     Inc(Loading);
     Material.DetailTx.Loading:=True;
     Loader:=TTextureLoader.Create(Material.DetailTx, Self);
    end;
   end;
  end; 
end;

procedure TTextureSystem.SetReflection(var Material: TTssMaterial; Index: integer);
begin
 if (LastMaterial.Reflection>0) and (not LastMaterial.NoEffects) then begin
  if Options.UseCubeMap and Options.UseMultiTx then begin
   if LastMaterial.MatType=MATTYPE_ALPHAGLASS then begin
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_TEXCOORDINDEX, 0);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_COLOROP, D3DTOP_MODULATE4X);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
   end else if LastMaterial.MatType=MATTYPE_MAPPEDGLASS then begin
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXCOORDINDEX, 1);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_DISABLE);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
   end else begin
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXCOORDINDEX, 1);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_DISABLE);
   end;
  end;
 end;
 if (Material.Reflection>0) and (not Material.NoEffects) then begin
  if Options.UseCubeMap and Options.UseMultiTx then begin
   if Material.MatType=MATTYPE_ALPHAGLASS then begin
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_TEXCOORDINDEX, D3DTSS_TCI_CAMERASPACEREFLECTIONVECTOR);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_COUNT3);
    Engine.m_pd3dDevice.SetTexture(Index, CubeTx);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(255-Material.Reflection*255 div 100, 255, 255, 255));
   end else if Material.MatType=MATTYPE_MAPPEDGLASS then begin
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXCOORDINDEX, D3DTSS_TCI_CAMERASPACEREFLECTIONVECTOR);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_COUNT3);
    Engine.m_pd3dDevice.SetTexture(Index+1, CubeTx);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_BLENDCURRENTALPHA);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
    Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Material.Reflection*255 div 100, 255, 255, 255));
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG2, D3DTA_CURRENT);
   end else begin
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXCOORDINDEX, D3DTSS_TCI_CAMERASPACEREFLECTIONVECTOR);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_COUNT3);
    Engine.m_pd3dDevice.SetTexture(Index+1, CubeTx);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_BLENDTEXTUREALPHA);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAOP, D3DTOP_ADDSMOOTH);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAARG2, D3DTA_CURRENT);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG2, D3DTA_CURRENT);
   end;
  end;
 end;
 LastMaterial.Reflection:=Material.Reflection;
 LastMaterial.MatType:=Material.MatType;
end;

procedure TTextureSystem.SetTexture(var Material: TTssMaterial; Index: integer);
begin
 with Material.Texture^ do if Texture=nil then begin
  LoadTexture(Material);
  Engine.m_pd3dDevice.SetTexture(Index, Engine.Material.Texture.Texture);
 end else begin
  Engine.m_pd3dDevice.SetTexture(Index, Texture);
  LastUse:=1;
 end;
 LastMaterial.Texture:=Material.Texture;
end;

procedure TTextureSystem.SetOpacity(var Material: TTssMaterial; Index: integer);
begin
 if Material.Opacity=99 then begin
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHAREF, AlphaRef);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
 end else begin
  Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHATESTENABLE, iFalse);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_CCW);
 end;
 LastMaterial.Opacity:=Material.Opacity;
end;

procedure TTextureSystem.SetWrapU(var Material: TTssMaterial; Index: integer);
begin
 if Material.NoWrapU then Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ADDRESSU, D3DTADDRESS_CLAMP)
  else Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ADDRESSU, D3DTADDRESS_WRAP);
 LastMaterial.NoWrapU:=Material.NoWrapU;
end;
procedure TTextureSystem.SetWrapV(var Material: TTssMaterial; Index: integer);
begin
 if Material.NoWrapV then Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ADDRESSV, D3DTADDRESS_CLAMP)
  else Engine.m_pd3dDevice.SetTextureStageState(Index, D3DTSS_ADDRESSV, D3DTADDRESS_WRAP);
  LastMaterial.NoWrapV:=Material.NoWrapV;
end;

procedure TTextureSystem.SetDetails(var Material: TTssMaterial; Index: integer);
begin
 if (Material.DetailNm<>'') and (not Material.NoEffects) then begin
  if Options.UseMultiTx and Options.UseDetailTx then begin
   with Material.DetailTx^ do if Texture=nil then begin
    LoadTexture(Material);
    Engine.m_pd3dDevice.SetTexture(Index+1, Engine.Material.Texture.Texture);
   end else begin
    Engine.m_pd3dDevice.SetTexture(Index+1, Texture);
    LastUse:=1;
   end;
   Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_MODULATE2X);
   Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG1, D3DTA_TEXTURE);
   Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLORARG2, D3DTA_CURRENT);
   {Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAOP, D3DTOP_SUBTRACT);
   Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
   Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_ALPHAARG2, D3DTA_CURRENT);}
  end;
 end else begin
  if (Material.Reflection=0) then if Options.UseMultiTx and Options.UseDetailTx then Engine.m_pd3dDevice.SetTextureStageState(Index+1, D3DTSS_COLOROP, D3DTOP_DISABLE);
 end;
 LastMaterial.DetailTx:=Material.DetailTx;
end;

procedure TTextureSystem.SetMaterial(var Material: TTssMaterial; Index: integer);
begin
 if Material.Texture=nil then Material.Texture:=GetTexture(Material.Name);
 if Material.DetailNm<>'' then if Material.DetailTx=nil then Material.DetailTx:=GetTexture(Material.DetailNm);

 if Material.Texture<>LastMaterial.Texture then SetTexture(Material, Index);
 if Material.Opacity<>LastMaterial.Opacity then SetOpacity(Material, Index);
 if Material.NoWrapU<>LastMaterial.NoWrapU then SetWrapU(Material, Index);
 if Material.NoWrapV<>LastMaterial.NoWrapV then SetWrapV(Material, Index);
 if Material.NoEffects<>LastMaterial.NoEffects then begin
  if (Material.Reflection>0) or (LastMaterial.Reflection>0) then SetReflection(Material, Index);
  if (Material.DetailTx<>nil) or (LastMaterial.DetailTx<>nil) then SetDetails(Material, Index);
  LastMaterial.NoEffects:=Material.NoEffects;
 end else begin
  if (Material.Reflection<>LastMaterial.Reflection) or (Material.MatType<>LastMaterial.MatType) then SetReflection(Material, Index);
  if Material.DetailTx<>LastMaterial.DetailTx then SetDetails(Material, Index);
 end;
end;

function TTextureSystem.GetTexture(const Name: string): PTssTexture;
var I: integer;
begin
 for I:=0 to TextureCount-1 do
  if Textures[I].Name=Name then begin
   Result:=@(Textures[I]);
   Exit;
  end;
 if Name<>'' then Engine.FTestValue:='Texture not found: '+Name;
 if Engine.Material.Texture=nil then begin
  for I:=0 to TextureCount-1 do
   if Textures[I].Name=Engine.Material.Name then begin
    Engine.Material.Texture:=@(Textures[I]);
    Break;
   end;
  if Engine.Material.Texture=nil then Engine.Material.Texture:=@(Textures[0]);
 end;
 Result:=Engine.Material.Texture;
end;

function TTextureSystem.GetCubeTx: IDirect3DCubeTexture8;
  procedure LoadCubeTx;
  var Data: Pointer;
      Size: integer;
  begin
   Size:=FilePack.LoadToMemByName('EnvMap.dds', Data);
   D3DXCreateCubeTextureFromFileInMemoryEx((Engine.m_pd3dDevice)^, Data^,
    Size, D3DX_DEFAULT, D3DX_DEFAULT, 0, D3DFMT_UNKNOWN,
    D3DPOOL_DEFAULT{D3DPOOL_MANAGED}, D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER,
    D3DX_FILTER_BOX or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER, 0, nil, nil, EnvMap50);
   FreeMem(Data);
  end;
begin
 if EnvMap50=nil then LoadCubeTx;
 Result:=EnvMap50;
end;

procedure TTextureSystem.DelayedLoad(var Material: TTssMaterial);
begin
 if Material.Texture=nil then Material.Texture:=GetTexture(Material.Name);
 with Material.Texture^ do begin
  if Texture=nil then LoadTexture(Material);
  LastUse:=1;
 end;
 if Material.DetailNm<>'' then begin
  if Material.DetailTx=nil then Material.Texture:=GetTexture(Material.DetailNm);
  with Material.DetailTx^ do begin
   if Texture=nil then LoadTexture(Material);
   LastUse:=1;
  end;
 end;
end;

procedure TTextureSystem.FastLoad(var Material: TTssMaterial);
var Data: Pointer;
    Size: integer;
begin
 if Material.Texture=nil then Material.Texture:=GetTexture(Material.Name);
 with Material.Texture^ do begin
   if Texture=nil then begin
    Size:=FilePack.LoadToMemByIndex(FileIndex, Data);
    D3DXCreateTextureFromFileInMemoryEx((Engine.m_pd3dDevice)^, Data^,
     Size, D3DX_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, 0, D3DFMT_UNKNOWN,
     D3DPOOL_DEFAULT{D3DPOOL_MANAGED}, D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER,
     D3DX_FILTER_BOX or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER, 0, nil, nil, Texture);
    FreeMem(Data);
   end;
   LastUse:=1;
 end;
 if Material.DetailNm<>'' then begin
  if Material.DetailTx=nil then Material.DetailTx:=GetTexture(Material.DetailNm);
   with Material.DetailTx^ do begin
    if Texture=nil then begin
     Size:=FilePack.LoadToMemByIndex(FileIndex, Data);
     D3DXCreateTextureFromFileInMemoryEx((Engine.m_pd3dDevice)^, Data^,
      Size, D3DX_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, 0, D3DFMT_UNKNOWN,
      D3DPOOL_DEFAULT{D3DPOOL_MANAGED}, D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER,
      D3DX_FILTER_BOX or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER, 0, nil, nil, Texture);
     FreeMem(Data);
    end;
    LastUse:=1;
  end;
 end;
end;

procedure TTextureSystem.FastUnload(var Material: TTssMaterial);
begin
 if Material.Texture=nil then Material.Texture:=GetTexture(Material.Name);
 with Material.Texture^ do begin
  Texture:=nil;
  LastUse:=0;
 end;
 if Material.DetailNm<>'' then begin
  if Material.DetailTx=nil then Material.DetailTx:=GetTexture(Material.DetailNm);
  with Material.DetailTx^ do begin
   Texture:=nil;
   LastUse:=0;
  end;
 end;
end;

procedure TTextureLoader.Execute;
var Data: Pointer;
    Size: integer;
begin
 Size:=FSystem.FilePack.LoadToMemByIndex(FToLoad.FileIndex, Data);
 D3DXCreateTextureFromFileInMemoryEx((Engine.m_pd3dDevice)^, Data^,
  Size, D3DX_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, 0, D3DFMT_UNKNOWN,
  D3DPOOL_DEFAULT{D3DPOOL_MANAGED}, D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER,
  D3DX_FILTER_BOX or D3DX_FILTER_MIRROR or D3DX_FILTER_DITHER, 0, nil, nil, FToLoad.Texture);
 FreeMem(Data);
 Terminate;
end;

constructor TTextureLoader.Create(TssTx: PTssTexture; System: TTextureSystem);
begin
 inherited Create(True);
 Priority:=GetPriority(Options.TXLPriority);
 FToLoad:=TssTx;
 FSystem:=System;
 FreeOnTerminate:=True;
 Resume;
end;

destructor TTextureLoader.Destroy;
begin
 Dec(FSystem.Loading);
 FToLoad.Loading:=False;
 FSystem.Loader:=nil;
 inherited;
end;


procedure TTextureSystem.InitFonts(const Path, FileName: string);
var FontFile: TTssFilePack;
type
  PFontFileData = ^TFontFileData;
  TFontFileData = packed record
    Material: string[10];
    Count: Byte;
    Letters: array[0..255] of packed record
      Letter: Char;
      Line, Column, Width: Byte;
    end;
  end;
var I, J: integer;
    Data: PFontFileData;
begin
 FontFile:=TTssFilePack.Create(Path, FileName, Options.LockData, Options.PreferPacked);
 FontCount:=FontFile.Count;
 Fonts:=AllocMem(FontCount*SizeOf(TTssFont));
 ZeroMemory(Fonts, FontCount*SizeOf(TTssFont));
 for I:=0 to FontFile.Count-1 do begin
  FontFile.LoadToMemByName('Font_'+IntToStr3(I)+'.tfd', Pointer(Data));
  Fonts[I].Material.Name:=Data.Material;
  for J:=0 to Data.Count-1 do begin
   Fonts[I].Letters[Data.Letters[J].Letter].Line:=Data.Letters[J].Line;
   Fonts[I].Letters[Data.Letters[J].Letter].Column:=Data.Letters[J].Column;
   Fonts[I].Letters[Data.Letters[J].Letter].Width:=Data.Letters[J].Width;
  end;
  FreeMem(Data);
 end;
 FontFile.Free;
end;

function TTextureSystem.TextWidth(Font: Byte; ScaleHorz, CharSpace: Single; const Text: string): Single;
var I: integer;
    Width: Single;
begin
 Result:=0;
 if (FontCount>Font) and (Length(Text)>0) then with Fonts[Font] do begin
  Width:=0;
  for I:=1 to Length(Text) do begin
   case Text[I] of
    #13: begin
      Result:=Max(Result, Width-CharSpace);
      Width:=0;
    end;
    ' ': Width:=Width+0.75*ScaleHorz*(12/32)+CharSpace;
    else Width:=Width+0.75*ScaleHorz*(Letters[Text[I]].Width/32+0.1)+CharSpace;
   end;
  end;
  Result:=Max(Result, Width-CharSpace);
 end;
end;

function TTextureSystem.TextHeight(Font: Byte; ScaleVert, LineSpace: Single; const Text: string): Single;
var I: integer;
begin
 Result:=0;
 if (FontCount>Font) and (Length(Text)>0) then with Fonts[Font] do begin
  Result:=ScaleVert;
  for I:=1 to Length(Text) do
   if Text[I]=#13 then Result:=Result+ScaleVert+LineSpace;
 end;  
end;

function TTextureSystem.FillFontBuffer2D(Font: Byte; X, Y, ScaleHorz, ScaleVert, AddHorz, AddVert, LineSpace, CharSpace: Single; const Text: string): integer;
var I: integer;
    PVB: P2DVertex;
    CurX, NextX: Single;
begin
 Result:=0;
 if (FontCount>Font) and (Length(Text)>0) then with Fonts[Font] do begin

  if FontVB2D=nil then Engine.m_pd3dDevice.CreateVertexBuffer(Max_Text_Length*6*SizeOf(T2DVertex), D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX_2D, D3DPOOL_DEFAULT, FontVB2D);

  FontVB2D.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
                                                  
  CurX:=X;
  for I:=1 to Length(Text) do begin
   if Result>=Max_Text_Length then Break;
   case Text[I] of

    #13: begin
      Y:=Y+ScaleVert+LineSpace;
      CurX:=X;
    end;

    ' ': CurX:=CurX+0.75*ScaleHorz*(12/32)+CharSpace+AddHorz;

    else with Letters[Text[I]] do if Width>0 then begin
      NextX:=CurX+0.75*ScaleHorz*(Width/32)+AddHorz;

      {FontVertices[Result*6+0]:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Height*Y,             0.9, 1.0, Column/32+0.00390625          , Line/8+0.00390625);
      FontVertices[Result*6+1]:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Height*Y,             0.9, 1.0, Column/32+Width/256-0.00390625, Line/8+0.00390625);
      FontVertices[Result*6+2]:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Height*(Y+ScaleVert), 0.9, 1.0, Column/32+0.00390625          , (Line+1)/8-0.00390625);

      FontVertices[Result*6+3]:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Height*(Y+ScaleVert), 0.9, 1.0, Column/32+0.00390625          , (Line+1)/8-0.00390625);
      FontVertices[Result*6+4]:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Height*Y,             0.9, 1.0, Column/32+Width/256-0.00390625, Line/8+0.00390625);
      FontVertices[Result*6+5]:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Height*(Y+ScaleVert), 0.9, 1.0, Column/32+Width/256-0.00390625, (Line+1)/8-0.00390625);}

      PVB^:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Width*Y,             0.9, 1.0, Column/32+0.00390625          , Line/8+0.00390625);     Inc(PVB);
      PVB^:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Width*Y,             0.9, 1.0, Column/32+Width/256-0.00390625, Line/8+0.00390625);     Inc(PVB);
      PVB^:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Width*(Y+ScaleVert+AddVert), 0.9, 1.0, Column/32+0.00390625          , (Line+1)/8-0.00390625); Inc(PVB);

      PVB^:=Make2DVertex(Engine.vp.Width*CurX,  Engine.vp.Width*(Y+ScaleVert+AddVert), 0.9, 1.0, Column/32+0.00390625          , (Line+1)/8-0.00390625); Inc(PVB);
      PVB^:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Width*Y,             0.9, 1.0, Column/32+Width/256-0.00390625, Line/8+0.00390625);     Inc(PVB);
      PVB^:=Make2DVertex(Engine.vp.Width*NextX, Engine.vp.Width*(Y+ScaleVert+AddVert), 0.9, 1.0, Column/32+Width/256-0.00390625, (Line+1)/8-0.00390625); Inc(PVB);

      CurX:=NextX+0.75*ScaleHorz*0.1+CharSpace;
      Inc(Result);
    end;
   end;
  end;

  FontVB2D.Unlock;
 end;
end;

procedure TTextureSystem.DrawText2D(Font: Byte; X, Y, ScaleHorz, ScaleVert, LineSpace, CharSpace: Single; const Text: string);
var Count: integer;
begin
 Count:=FillFontBuffer2D(Font, X, Y, ScaleHorz, ScaleVert, 0.0, 0.0, LineSpace, CharSpace, Text);
 if Count>0 then with Fonts[Font] do begin
  Engine.Textures.SetMaterial(Material, 0);
  Engine.m_pd3dDevice.SetStreamSource(0, FontVB2D, SizeOf(T2DVertex));
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, Count*2);
  //Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, Count*2, FontVertices, SizeOf(T2DVertex));
  Engine.IncPolyCounter(Count*2);
 end;
end;

procedure TTextureSystem.DrawText2DShadow(Font: Byte; X, Y, ScaleHorz, ScaleVert, LineSpace, CharSpace, ShadowSize, OffsetX, OffsetY: Single; ShadowColor, TextColor: Cardinal; const Text: string);
var Count: integer;
begin
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, ShadowColor);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TFACTOR);
 Count:=FillFontBuffer2D(Font, X+OffsetX-ShadowSize, Y+OffsetY-ShadowSize, ScaleHorz, ScaleVert, ShadowSize*2, ShadowSize*2, LineSpace-ShadowSize*2, CharSpace-ShadowSize*2, Text);
 if Count>0 then with Fonts[Font] do begin
  Engine.Textures.SetMaterial(Material, 0);
  Engine.m_pd3dDevice.SetStreamSource(0, FontVB2D, SizeOf(T2DVertex));
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, Count*2);
  Engine.IncPolyCounter(Count*2);
 end;
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, TextColor);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 DrawText2D(Font, X, Y, ScaleHorz, ScaleVert, LineSpace, CharSpace, Text);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
{var I, Count: integer;
    PVB: P2DVertex;
begin
 Count:=FillFontBuffer2D(Font, X+0.75*OffsetX, Y+OffsetY, ScaleHorz, ScaleVert, Text);
 if Count>0 then with Fonts[Font] do begin
  Engine.Textures.SetMaterial(Material, 0);
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);

  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, ShadowColor);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TFACTOR);
  Engine.m_pd3dDevice.SetStreamSource(0, FontVB2D, SizeOf(T2DVertex));
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, Count*2);
  //Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, Count*2, FontVertices, SizeOf(T2DVertex));
  Engine.IncPolyCounter(Count*2);

  FontVB2D.Lock(0, 0, PByte(PVB), 0);
  for I:=0 to Count*6-1 do begin
   //FontVertices[I].X:=FontVertices[I].X-Engine.vp.Width*0.75*OffsetX;
   //FontVertices[I].Y:=FontVertices[I].Y-Engine.vp.Height*OffsetY;
   PVB.X:=PVB.X-Engine.vp.Width*0.75*OffsetX;
   PVB.Y:=PVB.Y-Engine.vp.Height*OffsetY;
   Inc(PVB);
  end;
  FontVB2D.Unlock;

  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, TextColor);
  //Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetStreamSource(0, FontVB2D, SizeOf(T2DVertex));
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, Count*2);
  //Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLELIST, Count*2, FontVertices, SizeOf(T2DVertex));
  Engine.IncPolyCounter(Count*2);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
 end;}
end;

end.
