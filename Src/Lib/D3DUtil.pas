unit D3DUtil;
//-----------------------------------------------------------------------------
// File: D3DUtil.h
//
// Desc: Helper functions and typing shortcuts for Direct3D programming.
//
// Copyright (c) 1997-2001 Microsoft Corporation. All rights reserved.
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
  SysUtils,
  {$I UseD3D8.inc}, D3DX8, DXUtil;


//-----------------------------------------------------------------------------
// Name: D3DUtil_InitMaterial()
// Desc: Initializes a D3DMATERIAL8 structure, setting the diffuse and ambient
//       colors. It does not set emissive or specular colors.
//-----------------------------------------------------------------------------
procedure D3DUtil_InitMaterial(var mtrl: TD3DMaterial8;
  r: Single = 0.0;
  g: Single = 0.0;
  b: Single = 0.0;
  a: Single = 1.0);




//-----------------------------------------------------------------------------
// Name: D3DUtil_InitLight()
// Desc: Initializes a D3DLIGHT structure, setting the light position. The
//       diffuse color is set to white, specular and ambient left as black.
//-----------------------------------------------------------------------------
procedure D3DUtil_InitLight(var light: TD3DLight8; ltType: TD3DLightType;
  x: Single = 0.0;
  y: Single = 0.0;
  z: Single = 0.0);




//-----------------------------------------------------------------------------
// Name: D3DUtil_CreateTexture()
// Desc: Helper function to create a texture. It checks the root path first,
//       then tries the DXSDK media path (as specified in the system registry).
//-----------------------------------------------------------------------------
function D3DUtil_CreateTexture(pd3dDevice: IDirect3DDevice8; strTexture: PChar;
  var ppTexture: IDirect3DTexture8;
  d3dFormat: TD3DFormat = D3DFMT_UNKNOWN): HRESULT;




//-----------------------------------------------------------------------------
// Name: D3DUtil_SetColorKey()
// Desc: Changes all texels matching the colorkey to transparent, black.
//-----------------------------------------------------------------------------
function D3DUtil_SetColorKey(var pTexture: IDirect3DTexture8; dwColorKey: DWORD): HRESULT;




//-----------------------------------------------------------------------------
// Name: D3DUtil_CreateVertexShader()
// Desc: Assembles and creates a file-based vertex shader
//-----------------------------------------------------------------------------
function D3DUtil_CreateVertexShader(pd3dDevice: IDirect3DDevice8;
  strFilename: PChar; pdwVertexDecl: PDWORD; var pdwVertexShader: DWORD): HRESULT;




//-----------------------------------------------------------------------------
// Name: D3DUtil_GetCubeMapViewMatrix()
// Desc: Returns a view matrix for rendering to a face of a cubemap.
//-----------------------------------------------------------------------------
function D3DUtil_GetCubeMapViewMatrix(dwFace: TD3DCubemapFaces): TD3DXMatrix;




//-----------------------------------------------------------------------------
// Name: D3DUtil_GetRotationFromCursor()
// Desc: Returns a quaternion for the rotation implied by the window's cursor
//       position.
//-----------------------------------------------------------------------------
function D3DUtil_GetRotationFromCursor(hWnd_: HWND;
  fTrackBallRadius: Single = 1.0): TD3DXQuaternion;




//-----------------------------------------------------------------------------
// Name: D3DUtil_SetDeviceCursor
// Desc: Builds and sets a cursor for the D3D device based on hCursor.
//-----------------------------------------------------------------------------
function D3DUtil_SetDeviceCursor(pd3dDevice: IDirect3DDevice8; hCursor: HCURSOR;
  bAddWatermark: BOOL): HRESULT;

type
  //-----------------------------------------------------------------------------
  // Name: class CD3DArcBall
  // Desc:
  //-----------------------------------------------------------------------------
  CD3DArcBall = class

    m_iWidth: Integer;                     // ArcBall's window width
    m_iHeight: Integer;                    // ArcBall's window height
    m_fRadius: Single;                     // ArcBall's radius in screen coords
    m_fRadiusTranslation: Single;          // ArcBall's radius for translating the target

    m_qDown: TD3DXQuaternion;              // Quaternion before button down
    m_qNow: TD3DXQuaternion;               // Composite quaternion for current drag
    m_matRotation: TD3DXMatrix;            // Matrix for arcball's orientation
    m_matRotationDelta: TD3DXMatrix;       // Matrix for arcball's orientation
    m_matTranslation: TD3DXMatrix;         // Matrix for arcball's position
    m_matTranslationDelta: TD3DXMatrix;    // Matrix for arcball's position
    m_bDrag: BOOL;                         // Whether user is dragging arcball
    m_bRightHanded: BOOL;                  // Whether to use RH coordinate system

    function ScreenToVector(sx, sy: Integer): TD3DXVector3;

  public
    function HandleMouseMessages(hWnd: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): LRESULT; overload;
    procedure HandleMouseMessages(var Msg: TMsg; var Handled: Boolean); overload;

    function GetRotationMatrix: PD3DXMatrix;         { return &m_matRotation; }
    function GetRotationDeltaMatrix: PD3DXMatrix;    { return &m_matRotationDelta; }
    function GetTranslationMatrix: PD3DXMatrix;      { return &m_matTranslation; }
    function GetTranslationDeltaMatrix: PD3DXMatrix; { return &m_matTranslationDelta; }
    function IsBeingDragged: BOOL;                   { return m_bDrag; }

    procedure SetRadius(fRadius: Single);
    procedure SetWindow(w, h: Integer; r: Single = 0.9);
    procedure SetRightHanded(bRightHanded: BOOL); // { m_bRightHanded = bRightHanded; }

    constructor Create;
  end;




  //-----------------------------------------------------------------------------
  // Name: class CD3DCamera
  // Desc:
  //-----------------------------------------------------------------------------
  CD3DCamera = class

    m_vEyePt: TD3DXVector3;       // Attributes for view matrix
    m_vLookatPt: TD3DXVector3;
    m_vUpVec: TD3DXVector3;

    m_vView: TD3DXVector3;
    m_vCross: TD3DXVector3;

    m_matView: TD3DXMatrix;
    m_matBillboard: TD3DXMatrix;  // Special matrix for billboarding effects

    m_fFOV: Single;               // Attributes for projection matrix
    m_fAspect: Single;
    m_fNearPlane: Single;
    m_fFarPlane: Single;
    m_matProj: TD3DXMatrix;

  public
    // Access functions
    function GetEyePt: TD3DXVector3;          { return m_vEyePt; }
    function GetLookatPt: TD3DXVector3;       { return m_vLookatPt; }
    function GetUpVec: TD3DXVector3;          { return m_vUpVec; }
    function GetViewDir: TD3DXVector3;        { return m_vView; }
    function GetCross: TD3DXVector3;          { return m_vCross; }

    function GetViewMatrix: TD3DXMatrix;      { return m_matView; }
    function GetBillboardMatrix: TD3DXMatrix; { return m_matBillboard; }
    function GetProjMatrix: TD3DXMatrix;      { return m_matProj; }

    procedure SetViewParams(const vEyePt, vLookatPt, vUpVec: TD3DXVector3);
    procedure SetProjParams(fFOV, fAspect, fNearPlane, fFarPlane: Single);

    constructor Create;
  end;

//-----------------------------------------------------------------------------
// Helper macros for pixel shader instructions
//-----------------------------------------------------------------------------
const
  // Parameter writemasks
  D3DPSP_WRITEMASK_B  = D3DSP_WRITEMASK_0;
  D3DPSP_WRITEMASK_G  = D3DSP_WRITEMASK_1;
  D3DPSP_WRITEMASK_R  = D3DSP_WRITEMASK_2;
  D3DPSP_WRITEMASK_A  = D3DSP_WRITEMASK_3;
  D3DPSP_WRITEMASK_C  = (D3DPSP_WRITEMASK_B or D3DPSP_WRITEMASK_G or D3DPSP_WRITEMASK_R);
  D3DPSP_WRITEMASK_ALL =(D3DSP_WRITEMASK_0 or D3DSP_WRITEMASK_1 or D3DSP_WRITEMASK_2 or D3DSP_WRITEMASK_3);
  D3DPSP_WRITEMASK_10  =(D3DSP_WRITEMASK_0 or D3DSP_WRITEMASK_1);
  D3DPSP_WRITEMASK_32  =(D3DSP_WRITEMASK_2 or D3DSP_WRITEMASK_3);

  // Source and destination parameter token
  // Translated below  :BAA
(*  D3DPS_REGNUM_MASK(_Num)   ( (1L<<31) | ((_Num)&D3DSP_REGNUM_MASK) )
  D3DPS_DST(_Num)           ( D3DPS_REGNUM_MASK(_Num) | D3DSPR_TEMP | D3DPSP_WRITEMASK_ALL )
  D3DPS_SRC_TEMP(_Num)      ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEMP )
  D3DPS_SRC_INPUT(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_INPUT )
  D3DPS_SRC_CONST(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_CONST )
  D3DPS_SRC_TEXTURE(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEXTURE )
  D3DVS_SRC_ADDR(_Num)      ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_ADDR )
  D3DVS_SRC_RASTOUT(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_RASTOUT )
  D3DVS_SRC_ATTROUT(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_ATTROUT )
  D3DVS_SRC_TEXCRDOUT(_Num) ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEXCRDOUT )
*)


//D3DPS_DST(_Num)           ( D3DPS_REGNUM_MASK(_Num) | D3DSPR_TEMP | D3DPSP_WRITEMASK_ALL )
  D3DPS_DST_ =  (DWORD(1 shl 31) {or (_Num and D3DSP_REGNUM_MASK)}) or DWORD(D3DSPR_TEMP) or D3DPSP_WRITEMASK_ALL;

  // Temp destination registers
  D3DS_DR0 = D3DPS_DST_ or 0; // D3DPS_DST(0)
  D3DS_DR1 = D3DPS_DST_ or 1; // D3DPS_DST(1)
  D3DS_DR2 = D3DPS_DST_ or 2; // D3DPS_DST(2)
  D3DS_DR3 = D3DPS_DST_ or 3; // D3DPS_DST(3)
  D3DS_DR4 = D3DPS_DST_ or 4; // D3DPS_DST(4)
  D3DS_DR5 = D3DPS_DST_ or 5; // D3DPS_DST(5)
  D3DS_DR6 = D3DPS_DST_ or 6; // D3DPS_DST(6)
  D3DS_DR7 = D3DPS_DST_ or 7; // D3DPS_DST(7)

//D3DPS_SRC_TEMP(_Num)      ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEMP )
  D3DPS_SRC_TEMP_ =  DWord(((1 shl 30) {or (_Num and D3DSP_REGNUM_MASK)}) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_TEMP));

  // Temp source registers
  D3DS_SR0 = D3DPS_SRC_TEMP_ or 0; // D3DPS_SRC_TEMP(0)
  D3DS_SR1 = D3DPS_SRC_TEMP_ or 1; // D3DPS_SRC_TEMP(1)
  D3DS_SR2 = D3DPS_SRC_TEMP_ or 2; // D3DPS_SRC_TEMP(2)
  D3DS_SR3 = D3DPS_SRC_TEMP_ or 3; // D3DPS_SRC_TEMP(3)
  D3DS_SR4 = D3DPS_SRC_TEMP_ or 4; // D3DPS_SRC_TEMP(4)
  D3DS_SR5 = D3DPS_SRC_TEMP_ or 5; // D3DPS_SRC_TEMP(5)
  D3DS_SR6 = D3DPS_SRC_TEMP_ or 6; // D3DPS_SRC_TEMP(6)
  D3DS_SR7 = D3DPS_SRC_TEMP_ or 7; // D3DPS_SRC_TEMP(7)


//D3DPS_SRC_TEXTURE(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEXTURE )
  D3DPS_SRC_TEXTURE_ =  DWord((DWORD(1 shl 31) {or (_Num and D3DSP_REGNUM_MASK)}) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_TEXTURE));

  // Texture parameters
  D3DS_T0 = D3DPS_SRC_TEXTURE_ or 0; // D3DPS_SRC_TEXTURE(0)
  D3DS_T1 = D3DPS_SRC_TEXTURE_ or 1; // D3DPS_SRC_TEXTURE(1)
  D3DS_T2 = D3DPS_SRC_TEXTURE_ or 2; // D3DPS_SRC_TEXTURE(2)
  D3DS_T3 = D3DPS_SRC_TEXTURE_ or 3; // D3DPS_SRC_TEXTURE(3)
  D3DS_T4 = D3DPS_SRC_TEXTURE_ or 4; // D3DPS_SRC_TEXTURE(4)
  D3DS_T5 = D3DPS_SRC_TEXTURE_ or 5; // D3DPS_SRC_TEXTURE(5)
  D3DS_T6 = D3DPS_SRC_TEXTURE_ or 6; // D3DPS_SRC_TEXTURE(6)
  D3DS_T7 = D3DPS_SRC_TEXTURE_ or 7; // D3DPS_SRC_TEXTURE(7)

//D3DPS_SRC_CONST(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_CONST )
  D3DPS_SRC_CONST_ =  DWord((DWORD(1 shl 31) {or (_Num and D3DSP_REGNUM_MASK)}) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_CONST));

  // Constant (factor) source parameters
  D3DS_C0 =  D3DPS_SRC_CONST_ or 0; // D3DPS_SRC_CONST(0);
  D3DS_C1 =  D3DPS_SRC_CONST_ or 1; // D3DPS_SRC_CONST(1);
  D3DS_C2 =  D3DPS_SRC_CONST_ or 2; // D3DPS_SRC_CONST(2);
  D3DS_C3 =  D3DPS_SRC_CONST_ or 3; // D3DPS_SRC_CONST(3);
  D3DS_C4 =  D3DPS_SRC_CONST_ or 4; // D3DPS_SRC_CONST(4);
  D3DS_C5 =  D3DPS_SRC_CONST_ or 5; // D3DPS_SRC_CONST(5);
  D3DS_C6 =  D3DPS_SRC_CONST_ or 6; // D3DPS_SRC_CONST(6);
  D3DS_C7 =  D3DPS_SRC_CONST_ or 7; // D3DPS_SRC_CONST(7);

//D3DPS_SRC_INPUT(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_INPUT )
  D3DPS_SRC_INPUT_ =  DWord((DWORD(1 shl 31) {or (_Num and D3DSP_REGNUM_MASK)}) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_INPUT));

  // Iterated source parameters (0==Diffuse, 1==specular)
  D3DS_V0 =  D3DPS_SRC_INPUT_ or 0; // D3DPS_SRC_INPUT(0);
  D3DS_V1 =  D3DPS_SRC_INPUT_ or 1; // D3DPS_SRC_INPUT(1);


// Source and destination parameter token
//  Definition above :BAA
function D3DPS_REGNUM_MASK(_Num: DWord): DWord;
function D3DPS_DST(_Num: DWord): DWord;
function D3DPS_SRC_TEMP(_Num: DWord): DWord;
function D3DPS_SRC_INPUT(_Num: DWord): DWord;
function D3DPS_SRC_CONST(_Num: DWord): DWord;
function D3DPS_SRC_TEXTURE(_Num: DWord): DWord;
function D3DVS_SRC_ADDR(_Num: DWord): DWord;
function D3DVS_SRC_RASTOUT(_Num: DWord): DWord;
function D3DVS_SRC_ATTROUT(_Num: DWord): DWord;
function D3DVS_SRC_TEXCRDOUT(_Num: DWord): DWord;


implementation

uses
  Messages, Math;

function CD3DArcBall.GetRotationMatrix:PD3DXMATRIX;         begin result:= @m_matRotation; end;
function CD3DArcBall.GetRotationDeltaMatrix:PD3DXMATRIX;    begin result:= @m_matRotationDelta; end;
function CD3DArcBall.GetTranslationMatrix:PD3DXMATRIX;      begin result:= @m_matTranslation; end;
function CD3DArcBall.GetTranslationDeltaMatrix:PD3DXMATRIX; begin result:= @m_matTranslationDelta; end;
function CD3DArcBall.IsBeingDragged: BOOL;                  begin result:= m_bDrag; end;

function CD3DCamera.GetEyePt: TD3DXVECTOR3;          begin result:= m_vEyePt; end;
function CD3DCamera.GetLookatPt: TD3DXVECTOR3;       begin result:= m_vLookatPt; end;
function CD3DCamera.GetUpVec: TD3DXVECTOR3;          begin result:= m_vUpVec; end;
function CD3DCamera.GetViewDir: TD3DXVECTOR3;        begin result:= m_vView; end;
function CD3DCamera.GetCross: TD3DXVECTOR3;          begin result:= m_vCross; end;
function CD3DCamera.GetViewMatrix: TD3DXMATRIX;      begin result:= m_matView; end;
function CD3DCamera.GetBillboardMatrix: TD3DXMATRIX; begin result:= m_matBillboard; end;
function CD3DCamera.GetProjMatrix: TD3DXMATRIX;      begin result:= m_matProj; end;


//-----------------------------------------------------------------------------
// Name: D3DUtil_InitMaterial()
// Desc: Initializes a D3DMATERIAL8 structure, setting the diffuse and ambient
//       colors. It does not set emissive or specular colors.
//-----------------------------------------------------------------------------
procedure D3DUtil_InitMaterial(var mtrl: TD3DMaterial8; r: Single; g: Single;
                                                        b: Single; a: Single);
begin
    ZeroMemory(@mtrl, SizeOf(TD3DMaterial8));
    mtrl.Diffuse.r := r;
    mtrl.Ambient.r := r;
    mtrl.Diffuse.g := g;
    mtrl.Ambient.g := g;
    mtrl.Diffuse.b := b;
    mtrl.Ambient.b := b;
    mtrl.Diffuse.a := a;
    mtrl.Ambient.a := a;
end;

//-----------------------------------------------------------------------------
// Name: D3DUtil_InitLight()
// Desc: Initializes a D3DLIGHT structure, setting the light position. The
//       diffuse color is set to white; specular and ambient are left as black.
//-----------------------------------------------------------------------------
procedure D3DUtil_InitLight(var light: TD3DLight8; ltType: TD3DLightType;
  x: Single; y: Single; z: Single);
begin
  ZeroMemory(@light, SizeOf(TD3DLight8));
  light._Type       := ltType;
  light.Diffuse.r   := 1.0;
  light.Diffuse.g   := 1.0;
  light.Diffuse.b   := 1.0;
  D3DXVec3Normalize(light.Direction, D3DXVector3(x, y, z));
  light.Position.x  := x;
  light.Position.y  := y;
  light.Position.z  := z;
  light.Range       := 1000.0;
end;




//-----------------------------------------------------------------------------
// Name: D3DUtil_CreateTexture()
// Desc: Helper function to create a texture. It checks the root path first,
//       then tries the DXSDK media path (as specified in the system registry).
//-----------------------------------------------------------------------------
function D3DUtil_CreateTexture(pd3dDevice: IDirect3DDevice8; strTexture: PChar;
  var ppTexture: IDirect3DTexture8; d3dFormat: TD3DFormat): HRESULT;
var
  strPath: array[0..MAX_PATH-1] of Char;
begin
  // Get the path to the texture
  DXUtil_FindMediaFile(strPath, strTexture);

  // Create the texture using D3DX
  Result:= D3DXCreateTextureFromFileEx(pd3dDevice, strPath,
              D3DX_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, 0, d3dFormat,
              D3DPOOL_MANAGED, D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR,
              D3DX_FILTER_TRIANGLE or D3DX_FILTER_MIRROR, 0, nil, nil, ppTexture);
end;



//-----------------------------------------------------------------------------
// Name: D3DUtil_SetColorKey()
// Desc: Changes all texels matching the colorkey to transparent, black.
//-----------------------------------------------------------------------------
function D3DUtil_SetColorKey(var pTexture: IDirect3DTexture8; dwColorKey: DWORD): HRESULT;
var
  r,g,b: DWORD;
  d3dsd: TD3DSurfaceDesc;
  d3dlr: TD3DLockedRect;
  x, y: DWORD;
begin
  // Get colorkey's red, green, and blue components
  r := ((dwColorKey and $00ff0000) shr 16);
  g := ((dwColorKey and $0000ff00) shr 8);
  b := ((dwColorKey and $000000ff) shr 0);

  // Put the colorkey in the texture's native format
  pTexture.GetLevelDesc(0, d3dsd);
  if (d3dsd.Format = D3DFMT_A4R4G4B4) then
      dwColorKey := $f000 + ((r shr 4) shl 8) + ((g shr 4) shl 4) + (b shr 4)
  else if (d3dsd.Format = D3DFMT_A1R5G5B5) then
      dwColorKey := $8000 + ((r shr 3) shl 10) + ((g shr 3) shl 5) + (b shr 3)
  else if (d3dsd.Format <> D3DFMT_A8R8G8B8) then
      begin Result:= E_FAIL; Exit; end;

  // Lock the texture
  if FAILED(pTexture.LockRect(0, d3dlr, nil, 0)) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  // Scan through each pixel, looking for the colorkey to replace
  for y:= 0 to d3dsd.Height - 1 do
  begin
    for x:= 0 to d3dsd.Width - 1 do
    begin
      if (d3dsd.Format = D3DFMT_A8R8G8B8) then
      begin
        // Handle 32-bit formats
        // if( ((DWORD*)d3dlr.pBits)[d3dsd.Width*y+x] == dwColorKey )
        //     ((DWORD*)d3dlr.pBits)[d3dsd.Width*y+x] = 0x00000000;
        if PDWord(DWord(d3dlr.pBits) + 4*(d3dsd.Width*y+x))^ = dwColorKey then
           PDWord(DWord(d3dlr.pBits) + 4*(d3dsd.Width*y+x))^:= 00000000;
      end else
      begin
        // Handle 16-bit formats
        // if( ((WORD*)d3dlr.pBits)[d3dsd.Width*y+x] == dwColorKey )
        //     ((WORD*)d3dlr.pBits)[d3dsd.Width*y+x] = 0x0000;
        if TWordArray(d3dlr.pBits^)[d3dsd.Width*y+x] = dwColorKey then
           TWordArray(d3dlr.pBits^)[d3dsd.Width*y+x]:= $0000;
      end;
    end;
  end;

  // Unlock the texture and return OK.
  pTexture.UnlockRect(0);
  result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: D3DUtil_CreateVertexShader()
// Desc: Assembles and creates a file-based vertex shader
//-----------------------------------------------------------------------------
function D3DUtil_CreateVertexShader(pd3dDevice: IDirect3DDevice8;
  strFilename: PChar; pdwVertexDecl: PDWORD; var pdwVertexShader: DWORD): HRESULT;
var
  pCode: ID3DXBuffer;
  strPath: array[0..MAX_PATH-1] of Char;
begin
  // Get the path to the vertex shader file
  DXUtil_FindMediaFile(strPath, strFilename);

  // Assemble the vertex shader file
  Result:= D3DXAssembleShaderFromFile(strPath, 0, nil, @pCode, nil);
  if FAILED(Result) then Exit;

  // Create the vertex shader
{$IFDEF DXG_COMPAT}
  Result:= pd3dDevice.CreateVertexShader(pdwVertexDecl^,         {$ELSE}
  Result:= pd3dDevice.CreateVertexShader(PDWord(pdwVertexDecl),  {$ENDIF}
                                         pCode.GetBufferPointer,
                                         pdwVertexShader, 0);
  SAFE_RELEASE(pCode);
end;


//-----------------------------------------------------------------------------
// Name: D3DUtil_GetCubeMapViewMatrix()
// Desc: Returns a view matrix for rendering to a face of a cubemap.
//-----------------------------------------------------------------------------
function D3DUtil_GetCubeMapViewMatrix(dwFace: TD3DCubemapFaces): TD3DXMatrix;
var
  vEyePt: TD3DXVector3;
  vLookDir: TD3DXVector3;
  vUpDir: TD3DXVector3;
  matView: TD3DXMatrix;
begin
  vEyePt:= D3DXVector3(0.0, 0.0, 0.0);

  case dwFace of
    D3DCUBEMAP_FACE_POSITIVE_X:
    begin
      vLookDir := D3DXVector3( 1.0, 0.0, 0.0 );
      vUpDir   := D3DXVector3( 0.0, 1.0, 0.0 );
    end;
    D3DCUBEMAP_FACE_NEGATIVE_X:
    begin
      vLookDir := D3DXVector3(-1.0, 0.0, 0.0 );
      vUpDir   := D3DXVector3( 0.0, 1.0, 0.0 );
    end;
    D3DCUBEMAP_FACE_POSITIVE_Y:
    begin
      vLookDir := D3DXVector3( 0.0, 1.0, 0.0 );
      vUpDir   := D3DXVector3( 0.0, 0.0,-1.0 );
    end;
    D3DCUBEMAP_FACE_NEGATIVE_Y:
    begin
      vLookDir := D3DXVector3( 0.0,-1.0, 0.0 );
      vUpDir   := D3DXVector3( 0.0, 0.0, 1.0 );
    end;
    D3DCUBEMAP_FACE_POSITIVE_Z:
    begin
      vLookDir := D3DXVector3( 0.0, 0.0, 1.0 );
      vUpDir   := D3DXVector3( 0.0, 1.0, 0.0 );
    end;
    D3DCUBEMAP_FACE_NEGATIVE_Z:
    begin
      vLookDir := D3DXVector3( 0.0, 0.0,-1.0 );
      vUpDir   := D3DXVector3( 0.0, 1.0, 0.0 );
    end;
  end;

  // Set the view transform for this cubemap surface
  D3DXMatrixLookAtLH(matView, vEyePt, vLookDir, vUpDir);
  Result:= matView;
end;


//-----------------------------------------------------------------------------
// Name: D3DUtil_GetRotationFromCursor()
// Desc: Returns a quaternion for the rotation implied by the window's cursor
//       position.
//-----------------------------------------------------------------------------
function D3DUtil_GetRotationFromCursor(hWnd_: HWND; fTrackBallRadius: Single): TD3DXQuaternion;
var
  pt: TPoint;
  rc: TRect;
  sx, sy, sz, d2, t, fAngle: Single;
  p1: TD3DXVector3;
  p2: TD3DXVector3;
  vAxis: TD3DXVector3;
  quat: TD3DXQuaternion;
  v: TD3DXVector3; // temporary vector
begin
  GetCursorPos(pt);
  GetClientRect(hWnd_, rc);
  ScreenToClient(hWnd_, pt);
  sx := ((2.0 * pt.x) / (rc.right-rc.left)) - 1;
  sy := ((2.0 * pt.y) / (rc.bottom-rc.top)) - 1;

  if (sx = 0.0) and (sy = 0.0) then
  begin
    Result:= D3DXQuaternion(0.0, 0.0, 0.0, 1.0);
    Exit;
  end;

  // d1 := 0.0; - it's not used anyway
  d2:= Sqrt(sx*sx + sy*sy);

  if (d2 < fTrackBallRadius * 0.70710678118654752440) then // Inside sphere
    sz := sqrt(fTrackBallRadius*fTrackBallRadius - d2*d2)
  else                                                     // On hyperbola
    sz := (fTrackBallRadius*fTrackBallRadius) / (2.0*d2);

  // Get two points on trackball's sphere
  p1:= D3DXVector3(sx, sy, sz);
  p2:= D3DXVector3(0.0, 0.0, fTrackBallRadius);

  // Get axis of rotation, which is cross product of p1 and p2
  D3DXVec3Cross(vAxis, p1, p2);

  // Calculate angle for the rotation about that axis
  // FLOAT t = D3DXVec3Length( &(p2-p1) ) / ( 2.0f*fTrackBallRadius );
  t:= D3DXVec3Length(
        D3DXVec3Scale(v,
          D3DXVec3Subtract(v, p2, p1)^, 1 / (2.0*fTrackBallRadius))^);
  if( t > +1.0) then t := +1.0;
  if( t < -1.0) then t := -1.0;
  fAngle := 2.0 * ArcSin(t);

  // Convert axis to quaternion
  D3DXQuaternionRotationAxis(quat, vAxis, fAngle);
  Result:= quat;
end;


//-----------------------------------------------------------------------------
// Name: D3DUtil_SetDeviceCursor
// Desc: Gives the D3D device a cursor with image and hotspot from hCursor.
//-----------------------------------------------------------------------------
function D3DUtil_SetDeviceCursor(pd3dDevice: IDirect3DDevice8; hCursor: HCURSOR;
  bAddWatermark: BOOL): HRESULT;
const
  wMask: array [0..4] of Word = ($ccc0, $a2a0, $a4a0, $a2a0, $ccc0);
label
  End_;
type
  PACOLORREF = ^ACOLORREF;
  ACOLORREF = array[0..0] of COLORREF;
type
  pImg = ^img;
  img = array[0..16000] of DWORD;
var
  hr: HRESULT;
  iconinfo_: TIconInfo;
  bBWCursor: BOOL;
  pCursorBitmap: IDirect3DSurface8;
  hdcColor: HDC;
  hdcMask: HDC;
  hdcScreen: HDC;
  bm: TBitmap;
  dwWidth: DWORD;
  dwHeightSrc: DWORD;
  dwHeightDest: DWORD;
  crColor: COLORREF;
  crMask: COLORREF;
  x,y: Cardinal;
  bmi: TBitmapInfo;
  pcrArrayColor: PACOLORREF;
  pcrArrayMask: PACOLORREF;
  pBitmap: pImg;
  hgdiobjOld: HGDIOBJ;
  lr: TD3DLockedRect;
begin
  hr := E_FAIL;
  pCursorBitmap := nil;
  hdcColor := 0;
  hdcMask := 0;
  hdcScreen := 0;
  pcrArrayColor := nil;
  pcrArrayMask := nil;

  ZeroMemory(@iconinfo_, SizeOf(TIconInfo));
  if not GetIconInfo(hCursor, iconinfo_) then
    goto End_;

  if (0 = GetObject(iconinfo_.hbmMask, SizeOf(TBitmap), @bm)) then
    goto End_;
  dwWidth := bm.bmWidth;
  dwHeightSrc := bm.bmHeight;

  if (iconinfo_.hbmColor = 0) then
  begin
    bBWCursor := TRUE;
    dwHeightDest := dwHeightSrc div 2;
  end else
  begin
    bBWCursor := FALSE;
    dwHeightDest := dwHeightSrc;
  end;

  // Create a surface for the fullscreen cursor
  hr:= pd3dDevice.CreateImageSurface(dwWidth, dwHeightDest, D3DFMT_A8R8G8B8,
                                     pCursorBitmap);
  if FAILED(hr) then
    goto End_;

  // pcrArrayMask = new DWORD[dwWidth * dwHeightSrc];
  GetMem(pcrArrayMask, SizeOf(DWORD)*(dwWidth * dwHeightSrc));

  ZeroMemory(@bmi, sizeof(bmi));
  bmi.bmiHeader.biSize := sizeof(bmi.bmiHeader);
  bmi.bmiHeader.biWidth := dwWidth;
  bmi.bmiHeader.biHeight := dwHeightSrc;
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 32;
  bmi.bmiHeader.biCompression := BI_RGB;

  hdcScreen := GetDC(0);
  hdcMask := CreateCompatibleDC(hdcScreen);
  if (hdcMask = 0) then
  begin
    hr := E_FAIL;
    goto End_;
  end;
  hgdiobjOld := SelectObject(hdcMask, iconinfo_.hbmMask);
  GetDIBits(hdcMask, iconinfo_.hbmMask, 0, dwHeightSrc, pcrArrayMask, bmi,
    DIB_RGB_COLORS);
  SelectObject(hdcMask, hgdiobjOld);

  if (not bBWCursor) then
  begin
    // pcrArrayColor = new DWORD[dwWidth * dwHeightDest];
    GetMem(pcrArrayColor, SizeOf(DWORD)*(dwWidth * dwHeightDest));
    hdcColor := CreateCompatibleDC(GetDC(0));
    if (hdcColor = 0) then
    begin
      hr := E_FAIL;
      goto End_;
    end;
    SelectObject(hdcColor, iconinfo_.hbmColor);
    GetDIBits(hdcColor, iconinfo_.hbmColor, 0, dwHeightDest, pcrArrayColor, bmi,
      DIB_RGB_COLORS);
  end;

  // Transfer cursor image into the surface
  pCursorBitmap.LockRect(lr, nil, 0);
  pBitmap := lr.pBits;
  for y:= 0 to dwHeightDest - 1 do
  begin
    for x:= 0 to dwWidth - 1 do
    begin
      if bBWCursor then
      begin
        crColor := pcrArrayMask^[dwWidth*(dwHeightDest-1-y) + x];
        crMask := pcrArrayMask^[dwWidth*(dwHeightSrc-1-y) + x];
      end else
      begin
        crColor := pcrArrayColor^[dwWidth*(dwHeightDest-1-y) + x];
        crMask := pcrArrayMask^[dwWidth*(dwHeightDest-1-y) + x];
      end;
      if (crMask = 0) then
        pBitmap^[dwWidth*y + x] := $ff000000 or crColor
      else
        pBitmap^[dwWidth*y + x] := $00000000;

      // It may be helpful to make the D3D cursor look slightly
      // different from the Windows cursor so you can distinguish
      // between the two when developing/testing code.  When
      // bAddWatermark is TRUE, the following code adds some
      // small grey "D3D" characters to the upper-left corner of
      // the D3D cursor image.

      //if( bAddWatermark && x < 12 && y < 5 )
      if bAddWatermark and (x < 12) and (y < 5) then
      begin
          // 11.. 11.. 11.. .... CCC0
          // 1.1. ..1. 1.1. .... A2A0
          // 1.1. .1.. 1.1. .... A4A0
          // 1.1. ..1. 1.1. .... A2A0
          // 11.. 11.. 11.. .... CCC0

          // if( wMask[y] & (1 << (15 - x)) )
          if (wMask[y] and (1 shl (15 - x)) <> 0) then
          begin
            pBitmap[dwWidth*y + x]:= pBitmap[dwWidth*y + x] or $ff808080;
          end;
      end;
    end;
  end;
  pCursorBitmap.UnlockRect;

  // Set the device cursor
  hr := pd3dDevice.SetCursorProperties(iconinfo_.xHotspot,
      iconinfo_.yHotspot, pCursorBitmap);
  if FAILED(hr) then
    goto End_;

  hr := S_OK;

End_:
  if (iconinfo_.hbmMask <> 0)  then DeleteObject(iconinfo_.hbmMask);
  if (iconinfo_.hbmColor <> 0) then DeleteObject(iconinfo_.hbmColor);
  if (hdcScreen <> 0)          then ReleaseDC(0, hdcScreen);
  if (hdcColor <> 0)           then DeleteDC(hdcColor);
  if (hdcMask <> 0)            then DeleteDC(hdcMask);
  // SAFE_DELETE_ARRAY(pcrArrayColor);
  FreeMem(pcrArrayColor);
  // SAFE_DELETE_ARRAY(pcrArrayMask);
  FreeMem(pcrArrayMask);
  SAFE_RELEASE(pCursorBitmap);
  Result:= hr;
end;


//-----------------------------------------------------------------------------
// Name: D3DXQuaternionUnitAxisToUnitAxis2
// Desc: Axis to axis quaternion double angle (no normalization)
//       Takes two points on unit sphere an angle THETA apart, returns
//       quaternion that represents a rotation around cross product by 2*THETA.
//-----------------------------------------------------------------------------
{inline} function D3DXQuaternionUnitAxisToUnitAxis2(out pOut: TD3DXQuaternion;
           const pvFrom, pvTo: TD3DXVector3): PD3DXQuaternion; // WINAPI;
var
  vAxis: TD3DXVector3;
begin
  D3DXVec3Cross(vAxis, pvFrom, pvTo);    // proportional to sin(theta)
  pOut.x := vAxis.x;
  pOut.y := vAxis.y;
  pOut.z := vAxis.z;
  pOut.w := D3DXVec3Dot(pvFrom, pvTo);
  Result:= @pOut;
end;



//-----------------------------------------------------------------------------
// Name: D3DXQuaternionAxisToAxis
// Desc: Axis to axis quaternion
//       Takes two points on unit sphere an angle THETA apart, returns
//       quaternion that represents a rotation around cross product by theta.
//-----------------------------------------------------------------------------
{inline} function D3DXQuaternionAxisToAxis(out pOut: TD3DXQuaternion;
           const pvFrom, pvTo: TD3DXVector3): PD3DXQuaternion; // WINAPI;
var
  vA, vB: TD3DXVector3;
  vHalf: TD3DXVector3;
begin
  D3DXVec3Normalize(vA, pvFrom);
  D3DXVec3Normalize(vB, pvTo);
  D3DXVec3Add(vHalf, vA, vB);
  D3DXVec3Normalize(vHalf, vHalf);
  Result:= D3DXQuaternionUnitAxisToUnitAxis2(pOut, vA, vHalf);
end;





//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
constructor CD3DArcBall.Create;
begin
  D3DXQuaternionIdentity(m_qDown);
  D3DXQuaternionIdentity(m_qNow);
  D3DXMatrixIdentity(m_matRotation);
  D3DXMatrixIdentity(m_matRotationDelta);
  D3DXMatrixIdentity(m_matTranslation);
  D3DXMatrixIdentity(m_matTranslationDelta);
  m_bDrag := FALSE;
  m_fRadiusTranslation := 1.0;
  m_bRightHanded := FALSE;
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
procedure CD3DArcBall.SetWindow(w, h: Integer; r: Single);
begin
  // Set ArcBall info
  m_iWidth  := w;
  m_iHeight := h;
  m_fRadius := r;
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
procedure CD3DArcBall.SetRightHanded(bRightHanded: BOOL);
begin
  m_bRightHanded:= bRightHanded;
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CD3DArcBall.ScreenToVector(sx, sy: Integer): TD3DXVector3;
var
  x, y, z, mag, scale: Single;
begin
  // Scale to screen
  x   := -(sx - m_iWidth/2)  / (m_fRadius*m_iWidth/2);
  y   :=  (sy - m_iHeight/2) / (m_fRadius*m_iHeight/2);

  if m_bRightHanded then
  begin
    x := -x;
    y := -y;
  end;

  z   := 0.0;
  mag := x*x + y*y;

  if (mag > 1.0) then
  begin
    scale := 1.0/sqrt(mag);
    x := x*scale;
    y := y*scale;
  end
  else
    z := sqrt(1.0 - mag);

  // Return vector
  Result:= D3DXVector3(x, y, z);
end;



//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
procedure CD3DArcBall.SetRadius(fRadius: Single);
begin
  m_fRadiusTranslation:= fRadius;
end;



//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CD3DArcBall.HandleMouseMessages(
  hWnd: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  Msg: TMsg;
  Handled: Boolean;
begin
  Msg.hwnd:= hWnd;
  Msg.message:= uMsg;
  Msg.wParam:= wParam;
  Msg.lParam:= lParam;

  HandleMouseMessages(Msg, Handled);
  Result:= Integer(Handled);
end;

procedure CD3DArcBall.HandleMouseMessages(
  var Msg: TMsg; var Handled: Boolean);
{$WRITEABLECONST ON}
const
  iCurMouseX: Integer = 0;                         // Saved mouse position
  iCurMouseY: Integer = 0;
  s_vDown: TD3DXVector3 = (x:0; y:0; z:0);         // Button down vector
{$WRITEABLECONST OFF}
var
  // Current mouse position
  iMouseX: Integer;
  iMouseY: Integer;
  vCur: TD3DXVector3;
  fDeltaX, fDeltaY: Single;
  qAxisToAxis: TD3DXQuaternion;
begin
  // Current mouse position
  iMouseX := LOWORD(Msg.lParam);
  iMouseY := HIWORD(Msg.lParam);

  case (Msg.message) of
    WM_RBUTTONDOWN,
    WM_MBUTTONDOWN:
    begin
      // Store off the position of the cursor when the button is pressed
      iCurMouseX:= iMouseX;
      iCurMouseY:= iMouseY;
      Handled:= TRUE;
      Exit;
    end;

    WM_LBUTTONDOWN:
    begin
      // Start drag mode
      m_bDrag:= True;
      s_vDown:= ScreenToVector(iMouseX, iMouseY);
      m_qDown:= m_qNow;
      Handled:= TRUE;
      Exit;
    end;

    WM_LBUTTONUP:
    begin
      // End drag mode
      m_bDrag:= FALSE;
      Handled:= TRUE;
      Exit;
    end;

    WM_MOUSEMOVE:
    begin
      // Drag object
      if ((MK_LBUTTON and Msg.wParam) = MK_LBUTTON) then
      begin
        if m_bDrag then
        begin
          // recompute m_qNow
          vCur:= ScreenToVector(iMouseX, iMouseY);
          D3DXQuaternionAxisToAxis(qAxisToAxis, s_vDown, vCur);
          m_qNow := m_qDown;
          // m_qNow *= qAxisToAxis;
          D3DXQuaternionMultiply(m_qNow, m_qNow, qAxisToAxis);
          D3DXMatrixRotationQuaternion(m_matRotationDelta, qAxisToAxis);
        end else
          D3DXMatrixIdentity(m_matRotationDelta);

        D3DXMatrixRotationQuaternion(m_matRotation, m_qNow);
        m_bDrag:= TRUE;
      end
      else if ((MK_RBUTTON and Msg.wParam) = MK_RBUTTON) or
              ((MK_MBUTTON and Msg.wParam) = MK_MBUTTON) then
      begin
        // Normalize based on size of window and bounding sphere radius
        fDeltaX:= (iCurMouseX - iMouseX) * m_fRadiusTranslation / m_iWidth;
        fDeltaY:= (iCurMouseY - iMouseY) * m_fRadiusTranslation / m_iHeight;

        if (Msg.wParam and MK_RBUTTON) = MK_RBUTTON then
        begin
          D3DXMatrixTranslation(m_matTranslationDelta, -2*fDeltaX, 2*fDeltaY, 0.0);
          D3DXMatrixMultiply(m_matTranslation, m_matTranslation, m_matTranslationDelta);
        end
        else  // wParam & MK_MBUTTON
        begin
          D3DXMatrixTranslation(m_matTranslationDelta, 0.0, 0.0, 5*fDeltaY);
          D3DXMatrixMultiply(m_matTranslation, m_matTranslation, m_matTranslationDelta);
        end;

        // Store mouse coordinate
        iCurMouseX:= iMouseX;
        iCurMouseY:= iMouseY;
      end;
      Handled:= TRUE;
      Exit;
    end;
  end;

  Handled:= FALSE;
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
constructor CD3DCamera.Create;
var
  v1,v2,v3:TD3DXVector3;
begin
  // Set attributes for the view matrix
  v1:= D3DXVector3(0.0,0.0,0.0);
  v2:= D3DXVector3(0.0,0.0,1.0);
  v3:= D3DXVector3(0.0,1.0,0.0);
  SetViewParams(v1, v2, v3);

  // Set attributes for the projection matrix
  SetProjParams(D3DX_PI/4, 1.0, 1.0, 1000.0);
end;




//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
procedure CD3DCamera.SetViewParams(const vEyePt, vLookatPt, vUpVec: TD3DXVector3);
var
  v: TD3DXVector3; // temp var
begin
  // Set attributes for the view matrix
  m_vEyePt    := vEyePt;
  m_vLookatPt := vLookatPt;
  m_vUpVec    := vUpVec;
  // D3DXVec3Normalize( &m_vView, &(m_vLookatPt - m_vEyePt) );
  D3DXVec3Normalize(m_vView, D3DXVec3Subtract(v, m_vLookatPt , m_vEyePt)^);
  D3DXVec3Cross(m_vCross, m_vView, m_vUpVec);

  D3DXMatrixLookAtLH(m_matView, m_vEyePt, m_vLookatPt, m_vUpVec);
  D3DXMatrixInverse(m_matBillboard, nil, m_matView);
  m_matBillboard._41 := 0.0;
  m_matBillboard._42 := 0.0;
  m_matBillboard._43 := 0.0;
end;




//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
procedure CD3DCamera.SetProjParams(fFOV, fAspect, fNearPlane, fFarPlane: Single);
begin
  // Set attributes for the projection matrix
  m_fFOV        := fFOV;
  m_fAspect     := fAspect;
  m_fNearPlane  := fNearPlane;
  m_fFarPlane   := fFarPlane;

  D3DXMatrixPerspectiveFovLH(m_matProj, fFOV, fAspect, fNearPlane, fFarPlane);
end;

///////////////////////////////////////////////////////////////////

//  D3DPS_REGNUM_MASK(_Num)   ( (1L<<31) | ((_Num)&D3DSP_REGNUM_MASK) )
function D3DPS_REGNUM_MASK(_Num: DWord): DWord;
begin Result:= DWord(1 shl 31) or (_Num and D3DSP_REGNUM_MASK); end;

//  D3DPS_DST(_Num)           ( D3DPS_REGNUM_MASK(_Num) | D3DSPR_TEMP | D3DPSP_WRITEMASK_ALL )
function D3DPS_DST(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or DWORD(D3DSPR_TEMP) or D3DPSP_WRITEMASK_ALL; end;

//  D3DPS_SRC_TEMP(_Num)      ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEMP )
function D3DPS_SRC_TEMP(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_TEMP); end;

//  D3DPS_SRC_INPUT(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_INPUT )
function D3DPS_SRC_INPUT(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_INPUT); end;

//  D3DPS_SRC_CONST(_Num)     ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_CONST )
function D3DPS_SRC_CONST(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_CONST); end;

//  D3DPS_SRC_TEXTURE(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEXTURE )
function D3DPS_SRC_TEXTURE(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_TEXTURE); end;

//  D3DVS_SRC_ADDR(_Num)      ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_ADDR )
function D3DVS_SRC_ADDR(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_ADDR); end;

//  D3DVS_SRC_RASTOUT(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_RASTOUT )
function D3DVS_SRC_RASTOUT(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_RASTOUT); end;

//  D3DVS_SRC_ATTROUT(_Num)   ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_ATTROUT )
function D3DVS_SRC_ATTROUT(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_ATTROUT); end;

//  D3DVS_SRC_TEXCRDOUT(_Num) ( D3DPS_REGNUM_MASK(_Num) | D3DSP_NOSWIZZLE | D3DSPR_TEXCRDOUT )
function D3DVS_SRC_TEXCRDOUT(_Num: DWord): DWord;
begin Result:= D3DPS_REGNUM_MASK(_Num) or D3DSP_NOSWIZZLE or DWORD(D3DSPR_TEXCRDOUT); end;

end.
