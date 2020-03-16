unit D3DFont;
//-----------------------------------------------------------------------------
// File: D3DFont.h
//
// Desc: Texture-based font class
//
// Copyright (c) 1999-2001 Microsoft Corporation. All rights reserved.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Original ObjectPascal conversion made by: Boris V.
// E-Mail: bst@bstnet.org
//
// Updates and modifications by: Alexey Barkovoy
// E-Mail: clootie@reactor.ru
//-----------------------------------------------------------------------------
//  Latest version can be downloaded from:
//     http://clootie.narod.ru/delphi/
//       -- and choice version of DirectX SDK: 8.0 or 8.1
//-----------------------------------------------------------------------------

{$I DirectX.inc}

interface

uses
  Windows,
  {$I UseD3D8.inc}, DXUtil;

const
  // Font creation flags
  D3DFONT_BOLD      = $0001;
  D3DFONT_ITALIC    = $0002;
  D3DFONT_ZENABLE  = $0004;

  // Font rendering flags
  D3DFONT_CENTERED  = $0001;
  D3DFONT_TWOSIDED  = $0002;
  D3DFONT_FILTERED  = $0004;

type
  CD3DFont = class

    m_strFontName: array[0..79] of Char;  // Font properties
    m_dwFontHeight: DWORD;
    m_dwFontFlags: DWORD;

    m_pd3dDevice: IDirect3DDevice8;       // A D3DDevice used for rendering
    m_pTexture: IDirect3DTexture8;        // The d3d texture for this font
    m_pVB: IDirect3DVertexBuffer8;        // VertexBuffer for rendering text
    m_dwTexWidth: DWORD;                  // Texture dimensions
    m_dwTexHeight: DWORD;
    m_fTextScale: Single;
    m_fTexCoords: array[0..128-32-1, 0..3] of Single;

    // Stateblocks for setting and restoring render states
    m_dwSavedStateBlock: DWORD;
    m_dwDrawTextStateBlock: DWORD;

  public
    // 2D and 3D text drawing functions
    function DrawText(x, y: Single; dwColor: DWORD;
                      strText: PChar; dwFlags: DWORD = 0): HRESULT;
    function DrawTextScaled(x, y, z: Single; fXScale, fYScale: Single; dwColor: DWORD;
                            strText: PChar; dwFlags: DWORD = 0): HRESULT;
    function Render3DText(strText: PChar; dwFlags: DWORD = 0): HRESULT;

    // Function to get extent of text
    function GetTextExtent(strText: PChar; pSize: PSize): HRESULT;

    // Initializing and destroying device-dependent objects
    function InitDeviceObjects(pd3dDevice: IDirect3DDevice8): HRESULT;
    function RestoreDeviceObjects: HRESULT;
    function InvalidateDeviceObjects: HRESULT;
    function DeleteDeviceObjects: HRESULT;

    // Constructor / destructor
    //Todo: Do we really need VIRTUAL constructor
    constructor Create(strFontName: PChar; dwHeight: DWORD; dwFlags: DWORD = 0); // virtual;
    destructor Destroy; override;
  end;


implementation

uses
  SysUtils,
  D3DX8;

//-----------------------------------------------------------------------------
// Custom vertex types for rendering text
//-----------------------------------------------------------------------------
const
  MAX_NUM_VERTICES = 50*6;

type
  FONT2DVERTEX = packed record
    p: TD3DXVector4;
    color: DWORD;
    tu, tv: Single;
  end;

  FONT3DVERTEX = packed record
    p: TD3DXVector3;
    n: TD3DXVector3;
    tu, tv: Single;
  end;

const
  D3DFVF_FONT2DVERTEX = (D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1);
  D3DFVF_FONT3DVERTEX = (D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_TEX1);

function InitFont2DVertex(const p: TD3DXVector4; color: TD3DColor;
  tu, tv: Single): FONT2DVERTEX;
var
  v: FONT2DVERTEX;
begin
  v.p := p;   v.color := color;   v.tu := tu;   v.tv := tv;
  Result:= v;
end;

function InitFont3DVertex(const p: TD3DXVector3; const n: TD3DXVector3;
  tu, tv: Single): FONT3DVERTEX;
var
  v: FONT3DVERTEX;
begin
  v.p := p;   v.n := n;   v.tu := tu;   v.tv := tv;
  Result:= v;
end;



//-----------------------------------------------------------------------------
// Name: CD3DFont()
// Desc: Font class constructor
//-----------------------------------------------------------------------------
constructor CD3DFont.Create(strFontName: PChar; dwHeight, dwFlags: DWORD);
begin
  StrCopy(m_strFontName, strFontName);
  m_dwFontHeight        := dwHeight;
  m_dwFontFlags         := dwFlags;

  m_pd3dDevice          := nil;
  m_pTexture            := nil;
  m_pVB                 := nil;

  m_dwSavedStateBlock    := 0;
  m_dwDrawTextStateBlock := 0;
end;


//-----------------------------------------------------------------------------
// Name: ~CD3DFont()
// Desc: Font class destructor
//-----------------------------------------------------------------------------
destructor CD3DFont.Destroy;
begin
  InvalidateDeviceObjects;
  DeleteDeviceObjects;
  inherited Destroy;
end;


//-----------------------------------------------------------------------------
// Name: InitDeviceObjects()
// Desc: Initializes device-dependent objects, including the vertex buffer used
//       for rendering text and the texture map which stores the font image.
//-----------------------------------------------------------------------------
function CD3DFont.InitDeviceObjects(pd3dDevice: IDirect3DDevice8): HRESULT;
type
  pBit = array[0..0] of DWORD;
  PpBit = ^pBit;
var
  d3dCaps: TD3DCaps8;
  pBitmapBits: PpBit;
  bmi: TBitmapInfo;
  hDC_: HDC;
  hbmBitmap: HBITMAP;
  nHeight: Integer;
  dwBold, dwItalic: DWORD;
  hFont_: HFONT;
  x, y: DWORD;
  str: array[0..1] of Char;
  size_: TSize;
  c: byte;
  d3dlr: TD3DLockedRect;
  pDstRow: PByte;
  pDst16: PWord;
  bAlpha: Byte; // 4-bit measure of pixel intensity
begin
  // Keep a local copy of the device
  m_pd3dDevice := pd3dDevice;

  // Establish the font and texture size
  m_fTextScale := 1.0; // Draw fonts into texture without scaling

  // Large fonts need larger textures
  if (m_dwFontHeight > 40) then
  begin
    m_dwTexWidth:= 1024;
    m_dwTexHeight:= m_dwTexWidth;
  end
  else if (m_dwFontHeight > 20) then
  begin
    m_dwTexHeight:= 512;
    m_dwTexWidth:= m_dwTexHeight;
  end else
  begin
    m_dwTexHeight := 256;
    m_dwTexWidth:= m_dwTexHeight;
  end;
  // If requested texture is too big, use a smaller texture and smaller font,
  // and scale up when rendering.

  m_pd3dDevice.GetDeviceCaps(d3dCaps);

  if (m_dwTexWidth > d3dCaps.MaxTextureWidth) then
  begin
    m_fTextScale := d3dCaps.MaxTextureWidth / m_dwTexWidth;
    m_dwTexHeight := d3dCaps.MaxTextureWidth;
    m_dwTexWidth := m_dwTexHeight;
  end;

  // Create a new texture for the font
  Result:= m_pd3dDevice.CreateTexture(m_dwTexWidth, m_dwTexHeight, 1,
                                      0, D3DFMT_A4R4G4B4,
                                      D3DPOOL_MANAGED, m_pTexture);
  if FAILED(Result) then Exit;

  // Prepare to create a bitmap
  ZeroMemory(@(bmi.bmiHeader), SizeOf(TBitmapInfoHeader));
  bmi.bmiHeader.biSize        := SizeOf(TBitmapInfoHeader);
  bmi.bmiHeader.biWidth       :=  m_dwTexWidth;
  bmi.bmiHeader.biHeight      := -m_dwTexHeight;
  bmi.bmiHeader.biPlanes      := 1;
  bmi.bmiHeader.biCompression := BI_RGB;
  bmi.bmiHeader.biBitCount    := 32;

  // Create a DC and a bitmap for the font
  hDC_      := CreateCompatibleDC(0);
  hbmBitmap := CreateDIBSection(hDC_, bmi, DIB_RGB_COLORS, Pointer(pBitmapBits), 0, 0);
  SetMapMode(hDC_, MM_TEXT);

  // Create a font.  By specifying ANTIALIASED_QUALITY, we might get an
  // antialiased font, but this is not guaranteed.
  nHeight:= -MulDiv(m_dwFontHeight,
                    Trunc(GetDeviceCaps(hDC_, LOGPIXELSY) * m_fTextScale), 72);
  if ((m_dwFontFlags and D3DFONT_BOLD) = D3DFONT_BOLD)
    then dwBold:= FW_BOLD
    else dwBold:= FW_NORMAL;
  if ((m_dwFontFlags and D3DFONT_ITALIC) = D3DFONT_ITALIC)
    then dwItalic:= 1
    else dwItalic:= 0;
  hFont_ := CreateFont(nHeight, 0, 0, 0, dwBold, dwItalic,
                       0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                       CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,
                       VARIABLE_PITCH, m_strFontName);
  if (0 = hFont_) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  SelectObject(hDC_, hbmBitmap);
  SelectObject(hDC_, hFont_);

  // Set text properties
  SetTextColor(hDC_, RGB(255, 255, 255));
  SetBkColor  (hDC_, $00000000);
  SetTextAlign(hDC_, TA_TOP);

  // Loop through all printable character and output them to the bitmap..
  // Meanwhile, keep track of the corresponding tex coords for each character.
  x := 0;
  y := 0;
  str := 'x'#0;

  for c:= 32 to 126 do
  begin
    str[0] := Char(c);
    GetTextExtentPoint32(hDC_, str, 1, size_);

    if (x + DWord(size_.cx) + 1 > m_dwTexWidth) then
    begin
      x := 0;
      y := y + DWord(size_.cy) + 1;
    end;

    ExtTextOut(hDC_, x + 0, y + 0, ETO_OPAQUE, nil, str, 1, nil);

    m_fTexCoords[c-32][0] := ((x+0))/m_dwTexWidth;
    m_fTexCoords[c-32][1] := ((y+0))/m_dwTexHeight;
    m_fTexCoords[c-32][2] := ((x+0+DWord(size_.cx)))/m_dwTexWidth;
    m_fTexCoords[c-32][3] := ((y+0+DWord(size_.cy)))/m_dwTexHeight;

    x := x + DWord(size_.cx) + 1;
  end;

  // Lock the surface and write the alpha values for the set pixels
  m_pTexture.LockRect(0, d3dlr, nil, 0);
  pDstRow:= d3dlr.pBits;

  for y:= 0 to (m_dwTexHeight - 1) do
  begin
    pDst16:= PWord(pDstRow);
    for x:= 0 to (m_dwTexWidth - 1) do
    begin
      bAlpha := (pBitmapBits^[m_dwTexWidth*y + x] and $ff) shr 4;
      if (bAlpha > 0) then
      begin
        pDst16^ := (bAlpha shl 12) or $0fff;
        Inc(pDst16);
      end else
      begin
        pDst16^ := $0000;
        Inc(pDst16);
      end;
    end;
    pDstRow:= PByte(Integer(pDstRow) + d3dlr.Pitch);
  end;

  // Done updating texture, so clean up used objects
  m_pTexture.UnlockRect(0);
  DeleteObject(hbmBitmap);
  DeleteDC(hDC_);
  DeleteObject(hFont_);

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: RestoreDeviceObjects()
// Desc:
//-----------------------------------------------------------------------------
function CD3DFont.RestoreDeviceObjects: HRESULT;
var
  which: LongWord;
begin
  // Create vertex buffer for the letters
  Result:= m_pd3dDevice.CreateVertexBuffer(MAX_NUM_VERTICES*SizeOf(FONT2DVERTEX),
                                           D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC,
                                           0, D3DPOOL_DEFAULT, m_pVB);
  if FAILED(Result) then Exit;

  // Create the state blocks for rendering text
  for which:= 0 to 1 do
  begin
    m_pd3dDevice.BeginStateBlock;
    m_pd3dDevice.SetTexture(0, m_pTexture);

    if (D3DFONT_ZENABLE and m_dwFontFlags) <> 0 then
      m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, iTrue)
    else
      m_pd3dDevice.SetRenderState(D3DRS_ZENABLE, iFalse);

    m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
    m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND,         D3DBLEND_SRCALPHA);
    m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND,        D3DBLEND_INVSRCALPHA);
    m_pd3dDevice.SetRenderState(D3DRS_ALPHATESTENABLE,  1);
    m_pd3dDevice.SetRenderState(D3DRS_ALPHAREF,         $08);
    m_pd3dDevice.SetRenderState(D3DRS_ALPHAFUNC,        D3DCMP_GREATEREQUAL);
    m_pd3dDevice.SetRenderState(D3DRS_FILLMODE,         D3DFILL_SOLID);
    m_pd3dDevice.SetRenderState(D3DRS_CULLMODE,         D3DCULL_CCW);
    m_pd3dDevice.SetRenderState(D3DRS_STENCILENABLE,    0);
    m_pd3dDevice.SetRenderState(D3DRS_CLIPPING,         1);
    m_pd3dDevice.SetRenderState(D3DRS_EDGEANTIALIAS,    0);
    m_pd3dDevice.SetRenderState(D3DRS_CLIPPLANEENABLE,  0);
    m_pd3dDevice.SetRenderState(D3DRS_VERTEXBLEND,      0);
    m_pd3dDevice.SetRenderState(D3DRS_INDEXEDVERTEXBLENDENABLE, 0);
    m_pd3dDevice.SetRenderState(D3DRS_FOGENABLE,        0);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP,   D3DTOP_MODULATE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP,   D3DTOP_MODULATE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_POINT);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_POINT);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MIPFILTER, D3DTEXF_NONE);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_TEXCOORDINDEX, 0);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP,   D3DTOP_DISABLE);
    m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAOP,   D3DTOP_DISABLE);

    if (which = 0) then
      m_pd3dDevice.EndStateBlock(m_dwSavedStateBlock)
    else
      m_pd3dDevice.EndStateBlock(m_dwDrawTextStateBlock);
  end;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: InvalidateDeviceObjects()
// Desc: Destroys all device-dependent objects
//-----------------------------------------------------------------------------
function CD3DFont.InvalidateDeviceObjects: HRESULT;
begin
  SAFE_RELEASE(m_pVB);

  // Delete the state blocks
  if (m_pd3dDevice <> nil) then
  begin
    if (m_dwSavedStateBlock <> 0) then
      m_pd3dDevice.DeleteStateBlock(m_dwSavedStateBlock);
    if (m_dwDrawTextStateBlock <> 0) then
      m_pd3dDevice.DeleteStateBlock(m_dwDrawTextStateBlock);
  end;

  m_dwSavedStateBlock    := 0;
  m_dwDrawTextStateBlock := 0;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DeleteDeviceObjects()
// Desc: Destroys all device-dependent objects
//-----------------------------------------------------------------------------
function CD3DFont.DeleteDeviceObjects: HRESULT;
begin
  SAFE_RELEASE(m_pTexture);
  m_pd3dDevice:= nil; //BAA: no Release in original C++
  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: GetTextExtent()
// Desc: Get the dimensions of a text string
//-----------------------------------------------------------------------------
function CD3DFont.GetTextExtent(strText:PChar; pSize: PSize): HRESULT;
var
  fRowWidth, fRowHeight, fWidth, fHeight: Single;
  c: PChar;
  tx1, tx2: Single;
begin
  if (nil = strText) or (nil = pSize) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  fRowWidth := 0.0;
  fRowHeight:= (m_fTexCoords[0][3]-m_fTexCoords[0][1])*m_dwTexHeight;
  fWidth    := 0.0;
  fHeight   := fRowHeight;

  while (strText^ <> #0) do
  begin
    c := strText;
    Inc(strText);

    if (c[0] = #10) then
    begin
      fRowWidth := 0.0;
      fHeight  := fHeight + fRowHeight;
    end;
    if (c[0] < ' ') then Continue;

    tx1 := m_fTexCoords[byte(c^)-32][0];
    tx2 := m_fTexCoords[byte(c^)-32][2];

    fRowWidth := fRowWidth + (tx2-tx1)*m_dwTexWidth;

    if (fRowWidth > fWidth) then fWidth := fRowWidth;
  end;

  pSize^.cx := Trunc(fWidth);
  pSize^.cy := Trunc(fHeight);

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: DrawTextScaled()
// Desc: Draws scaled 2D text.  Note that x and y are in viewport coordinates
//       (ranging from -1 to +1).  fXScale and fYScale are the size fraction
//       relative to the entire viewport.  For example, a fXScale of 0.25 is
//       1/8th of the screen width.  This allows you to output text at a fixed
//       fraction of the viewport, even if the screen or window size changes.
//-----------------------------------------------------------------------------
function CD3DFont.DrawTextScaled(x, y, z: Single;
                                  fXScale, fYScale: Single; dwColor: DWORD;
                                  strText: PChar; dwFlags: DWORD): HRESULT;
var
  vp: TD3DViewport8;
  sx, sy, sz, rhw, fStartX, fLineHeight: Single;
  pVertices: ^FONT2DVERTEX;
  dwNumTriangles: DWORD;
  c: PChar;
  tx1, ty1, tx2, ty2: Single;
  w, h: Single;
begin
  if (m_pd3dDevice = nil) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  // Set up renderstate
  m_pd3dDevice.CaptureStateBlock(m_dwSavedStateBlock);
  m_pd3dDevice.ApplyStateBlock(m_dwDrawTextStateBlock);
  m_pd3dDevice.SetVertexShader(D3DFVF_FONT2DVERTEX);
  m_pd3dDevice.SetPixelShader(0);
  m_pd3dDevice.SetStreamSource(0, m_pVB, SizeOf(FONT2DVERTEX));

  // Set filter states
  if (dwFlags and D3DFONT_FILTERED) = D3DFONT_FILTERED then
  begin
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
  end;

  m_pd3dDevice.GetViewport(vp);
  sx  := (x+1.0)*vp.Width/2;
  sy  := (y+1.0)*vp.Height/2;
  sz  := z;
  rhw := 1.0;
  fStartX := sx;

  fLineHeight := (m_fTexCoords[0][3] - m_fTexCoords[0][1]) * m_dwTexHeight;

  // Fill vertex buffer

  dwNumTriangles := 0;
  m_pVB.Lock(0, 0, PByte(pVertices), D3DLOCK_DISCARD);

  while (strText <> nil) do
  begin
    c := strText;
    Inc(strText);

    if (c[0] = #10) then
    begin
      sx := fStartX;
      sy := sy + fYScale*vp.Height;
    end;
    if (c[0] < ' ') then Continue;

    tx1 := m_fTexCoords[byte(c[0])-32][0];
    ty1 := m_fTexCoords[byte(c[0])-32][1];
    tx2 := m_fTexCoords[byte(c[0])-32][2];
    ty2 := m_fTexCoords[byte(c[0])-32][3];

    w := (tx2-tx1)*m_dwTexWidth;
    h := (ty2-ty1)*m_dwTexHeight;

    w := w*(fXScale*vp.Width)/fLineHeight;
    h := h*(fYScale*vp.Height)/fLineHeight;

    if (c[0] <> ' ') then
    begin
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+0-0.5, sy+h-0.5, sz, rhw), dwColor, tx1, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+0-0.5, sy+0-0.5, sz, rhw), dwColor, tx1, ty1); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+w-0.5, sy+h-0.5, sz, rhw), dwColor, tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+w-0.5, sy+0-0.5, sz, rhw), dwColor, tx2, ty1); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+w-0.5, sy+h-0.5, sz, rhw), dwColor, tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(sx+0-0.5, sy+0-0.5, sz, rhw), dwColor, tx1, ty1); Inc(pVertices);
      dwNumTriangles := dwNumTriangles + 2;

      if (dwNumTriangles*3 > (MAX_NUM_VERTICES-6)) then
      begin
        // Unlock, render, and relock the vertex buffer
        m_pVB.Unlock;
        m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);
        m_pVB.Lock(0, 0, PByte(pVertices), D3DLOCK_DISCARD);
        dwNumTriangles := 0;
      end;
    end;

    sx := sx + w;
  end;

  // Unlock and render the vertex buffer
  m_pVB.Unlock;
  if (dwNumTriangles > 0) then
      m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);

  // Restore the modified renderstates
  m_pd3dDevice.ApplyStateBlock(m_dwSavedStateBlock);

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: DrawText()
// Desc: Draws 2D text
//-----------------------------------------------------------------------------
function CD3DFont.DrawText(x, y: Single; dwColor: DWORD;
  strText: PChar; dwFlags: DWORD): HRESULT;
var
  fStartX: Single;
  pVertices: ^FONT2DVERTEX;
  dwNumTriangles: DWORD;
  c: Char;
  tx1, ty1, tx2, ty2: Single;
  w, h: Single;
begin
  if (m_pd3dDevice = nil) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  // Setup renderstate
  m_pd3dDevice.CaptureStateBlock(m_dwSavedStateBlock);
  m_pd3dDevice.ApplyStateBlock(m_dwDrawTextStateBlock);
  m_pd3dDevice.SetVertexShader(D3DFVF_FONT2DVERTEX);
  m_pd3dDevice.SetPixelShader(0);
  m_pd3dDevice.SetStreamSource(0, m_pVB, SizeOf(FONT2DVERTEX));

  // Set filter states
  if (dwFlags and D3DFONT_FILTERED) = D3DFONT_FILTERED then
  begin
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
  end;

  fStartX := x;

  // Fill vertex buffer
  pVertices:= nil;
  dwNumTriangles := 0;
  m_pVB.Lock(0, 0, PByte(pVertices), D3DLOCK_DISCARD);

  while (strText^ <> #0) do
  begin
    c := strText^;
    Inc(strText);

    if (c = #10) then
    begin
      x := fStartX;
      y := y + (m_fTexCoords[0][3]-m_fTexCoords[0][1])*m_dwTexHeight;
    end;
    if (c < ' ') then Continue;

    tx1 := m_fTexCoords[byte(c)-32][0];
    ty1 := m_fTexCoords[byte(c)-32][1];
    tx2 := m_fTexCoords[byte(c)-32][2];
    ty2 := m_fTexCoords[byte(c)-32][3];

    w := (tx2-tx1) * m_dwTexWidth  / m_fTextScale;
    h := (ty2-ty1) * m_dwTexHeight / m_fTextScale;

    if (c <> ' ') then
    begin
      pVertices^ := InitFont2DVertex(D3DXVector4(x+0-0.5,y+h-0.5,0.9,1.0), dwColor, tx1, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(x+0-0.5,y+0-0.5,0.9,1.0), dwColor, tx1, ty1); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(x+w-0.5,y+h-0.5,0.9,1.0), dwColor, tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(x+w-0.5,y+0-0.5,0.9,1.0), dwColor, tx2, ty1); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(x+w-0.5,y+h-0.5,0.9,1.0), dwColor, tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont2DVertex(D3DXVector4(x+0-0.5,y+0-0.5,0.9,1.0), dwColor, tx1, ty1); Inc(pVertices);
      dwNumTriangles :=dwNumTriangles + 2;

      if dwNumTriangles*3 > (MAX_NUM_VERTICES-6)  then
      begin
        // Unlock, render, and relock the vertex buffer
        m_pVB.Unlock;
        m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);
        pVertices:= nil;
        m_pVB.Lock(0, 0, PByte(pVertices), D3DLOCK_DISCARD);
        dwNumTriangles := 0;
      end;
    end;

    x := x+w;
  end;

  // Unlock and render the vertex buffer
  m_pVB.Unlock;
  if (dwNumTriangles > 0) then
      m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);

  // Restore the modified renderstates
  m_pd3dDevice.ApplyStateBlock(m_dwSavedStateBlock);

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: Render3DText()
// Desc: Renders 3D text
//-----------------------------------------------------------------------------
function CD3DFont.Render3DText(strText: PChar; dwFlags: DWORD): HRESULT;
var
  x, y: Single;
  sz: TSize;
  fStartX: Single;
  c: Char;
  pVertices: ^FONT3DVERTEX;
  // dwVertex: DWORD; -  it's not used anyway
  dwNumTriangles: DWORD;
  tx1, ty1, tx2, ty2: Single;
  w, h: Single;
begin
  if (m_pd3dDevice = nil) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  // Setup renderstate
  m_pd3dDevice.CaptureStateBlock(m_dwSavedStateBlock);
  m_pd3dDevice.ApplyStateBlock(m_dwDrawTextStateBlock);
  m_pd3dDevice.SetVertexShader(D3DFVF_FONT3DVERTEX);
  m_pd3dDevice.SetPixelShader(0);
  m_pd3dDevice.SetStreamSource(0, m_pVB, SizeOf(FONT3DVERTEX));

  // Set filter states
  if (dwFlags and D3DFONT_FILTERED) = D3DFONT_FILTERED then
  begin
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MINFILTER, D3DTEXF_LINEAR);
    m_pd3dDevice.SetTextureStageState(0, D3DTSS_MAGFILTER, D3DTEXF_LINEAR);
  end;

  // Position for each text element
  x := 0.0;
  y := 0.0;

  // Center the text block at the origin
  if (dwFlags and D3DFONT_CENTERED) = D3DFONT_CENTERED then
  begin
    GetTextExtent(strText, @sz);
    x := -((sz.cx)/10.0)/2.0;
    y := -((sz.cy)/10.0)/2.0;
  end;

  // Turn off culling for two-sided text
  if (dwFlags and D3DFONT_TWOSIDED) = D3DFONT_TWOSIDED then
    m_pd3dDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);

  fStartX := x;

  // Fill vertex buffer
  // dwVertex       := 0;  -  it's not used anyway
  dwNumTriangles := 0;
  m_pVB.Lock(0, 0, PByte(pVertices), D3DLOCK_DISCARD);

  c:= strText^;
  while (c <> #0) do
  begin
    Inc(strText);
    if (c = #10) then
    begin
      x := fStartX;
      y := y-(m_fTexCoords[0][3]-m_fTexCoords[0][1])*m_dwTexHeight/10.0;
    end;
    if (Byte(c) < 32) then Continue;

    tx1 := m_fTexCoords[byte(c)-32][0];
    ty1 := m_fTexCoords[byte(c)-32][1];
    tx2 := m_fTexCoords[byte(c)-32][2];
    ty2 := m_fTexCoords[byte(c)-32][3];

    w := (tx2-tx1) * m_dwTexWidth  / (10.0 * m_fTextScale);
    h := (ty2-ty1) * m_dwTexHeight / (10.0 * m_fTextScale);

    if (c <> ' ') then
    begin
      pVertices^ := InitFont3DVertex(D3DXVector3(x+0,y+0,0), D3DXVector3(0,0,-1), tx1, ty2); Inc(pVertices);
      pVertices^ := InitFont3DVertex(D3DXVector3(x+0,y+h,0), D3DXVector3(0,0,-1), tx1, ty1); Inc(pVertices);
      pVertices^ := InitFont3DVertex(D3DXVector3(x+w,y+0,0), D3DXVector3(0,0,-1), tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont3DVertex(D3DXVector3(x+w,y+h,0), D3DXVector3(0,0,-1), tx2, ty1); Inc(pVertices);
      pVertices^ := InitFont3DVertex(D3DXVector3(x+w,y+0,0), D3DXVector3(0,0,-1), tx2, ty2); Inc(pVertices);
      pVertices^ := InitFont3DVertex(D3DXVector3(x+0,y+h,0), D3DXVector3(0,0,-1), tx1, ty1); Inc(pVertices);
      dwNumTriangles := dwNumTriangles + 2;

      if (dwNumTriangles*3 > (MAX_NUM_VERTICES - 6)) then
      begin
        // Unlock, render, and relock the vertex buffer
        m_pVB.Unlock;
        m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);
        m_pVB.Lock(0, 0, PBYTE(pVertices), D3DLOCK_DISCARD);
        dwNumTriangles := 0;
      end;
    end;

    x := x + w;
    c:= strText^;
  end;

  // Unlock and render the vertex buffer
  m_pVB.Unlock;
  if (dwNumTriangles > 0) then
    m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLELIST, 0, dwNumTriangles);

  // Restore the modified renderstates
  m_pd3dDevice.ApplyStateBlock(m_dwSavedStateBlock);

  Result:= S_OK;
end;

end.
