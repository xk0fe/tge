unit D3DApp;
//-----------------------------------------------------------------------------
// File: D3DApp.h
//
// Desc: Application class for the Direct3D samples framework library.
//
// Copyright (c) 1998-2001 Microsoft Corporation. All rights reserved.
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
  Windows, {$I UseD3D8.inc}, DXUtil;

const
  MSG_NONE              = 0;
  MSGERR_APPMUSTEXIT    = 1;
  MSGWARN_SWITCHEDTOREF = 2;

const
  //-----------------------------------------------------------------------------
  // Error codes
  //-----------------------------------------------------------------------------

  D3DAPPERR_NODIRECT3D          = HResult($82000001);
  D3DAPPERR_NOWINDOW            = HResult($82000002);
  D3DAPPERR_NOCOMPATIBLEDEVICES = HResult($82000003);
  D3DAPPERR_NOWINDOWABLEDEVICES = HResult($82000004);
  D3DAPPERR_NOHARDWAREDEVICE    = HResult($82000005);
  D3DAPPERR_HALNOTCOMPATIBLE    = HResult($82000006);
  D3DAPPERR_NOWINDOWEDHAL       = HResult($82000007);
  D3DAPPERR_NODESKTOPHAL        = HResult($82000008);
  D3DAPPERR_NOHALTHISMODE       = HResult($82000009);
  D3DAPPERR_NONZEROREFCOUNT     = HResult($8200000a);
  D3DAPPERR_MEDIANOTFOUND       = HResult($8200000b);
  D3DAPPERR_RESIZEFAILED        = HResult($8200000c);
  D3DAPPERR_NULLREFDEVICE       = HResult($8200000d);

type
  APPMSGTYPE = Integer;

type
  QSortCB = function (const arg1, arg2: Pointer): Integer;
  Size_t = Cardinal;

procedure QSort(base: Pointer; num: Size_t; width: Size_t; compare: QSortCB);

type
  //-----------------------------------------------------------------------------
  // Name: struct D3DModeInfo
  // Desc: Structure for holding information about a display mode
  //-----------------------------------------------------------------------------
  PD3DModeInfo = ^TD3DModeInfo;
  TD3DModeInfo = record
    Width: DWORD;                    // Screen width in this mode
    Height: DWORD;                   // Screen height in this mode
    Format: TD3DFormat;              // Pixel format in this mode
    dwBehavior: DWORD;               // Hardware / Software / Mixed vertex processing
    DepthStencilFormat: TD3DFormat;  // Which depth/stencil format to use with this mode
  end;




  //-----------------------------------------------------------------------------
  // Name: struct D3DDeviceInfo
  // Desc: Structure for holding information about a Direct3D device, including
  //       a list of modes compatible with this device
  //-----------------------------------------------------------------------------
  PD3DDeviceInfo = ^TD3DDeviceInfo;
  TD3DDeviceInfo = record
    // Device data
    DeviceType: TD3DDevType; // Reference, HAL, etc.
    d3dCaps: TD3DCaps8;      // Capabilities of this device
    strDesc: PChar;          // Name of this device
    bCanDoWindowed: BOOL;    // Whether this device can work in windowed mode

    // Modes for this device
    dwNumModes: DWORD;
    modes: array[0..149] of TD3DModeInfo;

    // Current state
    dwCurrentMode: DWORD;
    bWindowed: BOOL;
    MultiSampleTypeWindowed: TD3DMultiSampleType;
    MultiSampleTypeFullscreen: TD3DMultiSampleType;
  end;




  //-----------------------------------------------------------------------------
  // Name: struct D3DAdapterInfo
  // Desc: Structure for holding information about an adapter, including a list
  //       of devices available on this adapter
  //-----------------------------------------------------------------------------
  PD3DAdapterInfo = ^TD3DAdapterInfo;
  TD3DAdapterInfo = record
    // Adapter data
    d3dAdapterIdentifier: TD3DAdapterIdentifier8;
    d3ddmDesktop: TD3DDisplayMode;      // Desktop display mode for this adapter

    // Devices for this adapter
    dwNumDevices: DWORD;
    devices: array[0..4] of TD3DDeviceInfo;

    // Current state
    dwCurrentDevice: DWORD;
  end;


  //-----------------------------------------------------------------------------
  // Name: class CD3DApplication
  // Desc: A base class for creating sample D3D8 applications. To create a simple
  //       Direct3D application, simply derive this class into a class (such as
  //       class CMyD3DApplication) and override the following functions, as
  //       needed:
  //          OneTimeSceneInit()    - To initialize app data (alloc mem, etc.)
  //          InitDeviceObjects()   - To initialize the 3D scene objects
  //          FrameMove()           - To animate the scene
  //          Render()              - To render the scene
  //          DeleteDeviceObjects() - To cleanup the 3D scene objects
  //          FinalCleanup()        - To cleanup app data (for exitting the app)
  //          MsgProc()             - To handle Windows messages
  //-----------------------------------------------------------------------------
  CD3DApplication = class
  protected
    // Internal variables for the state of the app
    m_Adapters: array[0..9] of TD3DAdapterInfo;
    m_dwNumAdapters: DWORD;
    m_dwAdapter: DWORD;
    m_bWindowed: BOOL;
    m_bActive: BOOL;
    m_bReady: BOOL;
    m_bHasFocus: BOOL;

    FOldWndProc: Pointer;

    // Internal variables used for timing
    m_bFrameMoving: BOOL;
    m_bSingleStep: BOOL;


    // Internal error handling function
    function DisplayErrorMsg(hr: HRESULT; dwType: DWORD): HRESULT;

    // Internal functions to manage and render the 3D scene
    function BuildDeviceList: HRESULT;
    function FindDepthStencilFormat(iAdapter: UINT; DeviceType: TD3DDevType;
                TargetFormat: TD3DFormat; var pDepthStencilFormat: TD3DFormat): BOOL;
    function Initialize3DEnvironment: HRESULT;
    function Resize3DEnvironment: HRESULT;
    function ToggleFullscreen: HRESULT;
    function ForceWindowed: HRESULT;
    function UserSelectNewDevice: HRESULT;
    procedure Cleanup3DEnvironment;
    function Render3DEnvironment: HRESULT;
    function AdjustWindowForChange: HRESULT; virtual;

    // Overridable functions for the 3D scene created by the app
    function ConfirmDevice(var p1: TD3DCaps8; p2: DWORD; p3: TD3DFormat): HRESULT; virtual;   { return S_OK; }
    function OneTimeSceneInit: HRESULT; virtual;                         { return S_OK; }
    function InitDeviceObjects: HRESULT; virtual;                        { return S_OK; }
    function RestoreDeviceObjects: HRESULT; virtual;                     { return S_OK; }
    function FrameMove: HRESULT; virtual;                                { return S_OK; }
    function Render: HRESULT; virtual;                                   { return S_OK; }
    function InvalidateDeviceObjects: HRESULT; virtual;                  { return S_OK; }
    function DeleteDeviceObjects: HRESULT; virtual;                      { return S_OK; }
    function FinalCleanup: HRESULT; virtual;                             { return S_OK; }

  public
    // Main objects used for creating and rendering the 3D scene
    m_d3dpp: TD3DPresentParameters;        // Parameters for CreateDevice/Reset
    m_hWnd: HWND;                          // The main app window
    m_hWndFocus: HWND;                     // The D3D focus window (usually same as m_hWnd)
    m_hMenu: HMENU;                        // App menu bar (stored here when fullscreen)
    m_pD3D: IDirect3D8;                    // The main D3D object
    m_pd3dDevice: IDirect3DDevice8;        // The D3D rendering device
    m_d3dCaps: TD3DCaps8;                  // Caps for the device
    m_d3dsdBackBuffer: TD3DSurfaceDesc;    // Surface desc of the backbuffer
    m_dwCreateFlags: DWORD;                // Indicate sw or hw vertex processing
    m_dwWindowStyle: DWORD;                // Saved window style for mode switches
    m_rcWindowBounds: TRect;               // Saved window bounds for mode switches
    m_rcWindowClient: TRect;               // Saved client area size for mode switches

    // Variables for timing
    m_fTime: Single;                        // Current time in seconds
    m_fElapsedTime: Single;                 // Time elapsed since last frame
    m_fFPS: Single;                         // Instanteous frame rate
    m_strDeviceStats: array[0..89] of Char; // String to hold D3D device stats
    m_strFrameStats: array[0..89] of Char;  // String to hold frame stats

    // Overridable variables for the app
    m_strWindowTitle: PChar;                // Title for the app's window
    m_bUseDepthBuffer: BOOL;                // Whether to autocreate depthbuffer
    m_dwMinDepthBits: DWORD;                // Minimum number of bits needed in depth buffer
    m_dwMinStencilBits: DWORD;              // Minimum number of bits needed in stencil buffer
    m_dwCreationWidth: DWORD;               // Width used to create window
    m_dwCreationHeight: DWORD;              // Height used to create window
    m_bCreateWindowed: Boolean;
    m_bWants32bit: Boolean;
    m_MultiSampleType: _D3DMULTISAMPLE_TYPE;
    m_bShowCursorWhenFullscreen: BOOL;      // Whether to show cursor when fullscreen
    m_bClipCursorWhenFullscreen: BOOL;      // Whether to limit cursor pos when fullscreen

    // Functions to create, run, pause, and clean up the application
    function Create_(hInstance: LongWord): HRESULT; virtual;
    function Run: Integer; virtual;
    function MsgProc(hWnd:HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual;

    procedure ToggleStart;
    procedure SingleStep;
    procedure ToggleFullScreenMode;

    // Internal constructor
    constructor Create(hWindow: HWND);
    destructor Destroy; override;
  end;

implementation

uses
  Messages,
  SysUtils,
  D3DUtil, D3DRes;

type
  PdumpArray = ^dumpArray;
  dumpArray = array[0..99] of TD3DDisplayMode;

procedure qsort_int(base: Pointer; width: Integer; compare: QSortCB;
  Left, Right: Integer; TempBuffer, TempBuffer2: Pointer);
var
  Lo, Hi: Integer;
  P: Pointer;
begin
  Lo := Left;
  Hi := Right;
  P := Pointer(Integer(base) + ((Lo + Hi) div 2)*width);
  Move(P^, TempBuffer2^, width);
  repeat
    while compare(Pointer(Integer(base) + Lo*width), TempBuffer2) < 0 do Inc(Lo);
    while compare(Pointer(Integer(base) + Hi*width), TempBuffer2) > 0 do Dec(Hi);
    if Lo <= Hi then
    begin
      Move(Pointer(Integer(base) + Lo*width)^, TempBuffer^,                        width);
      Move(Pointer(Integer(base) + Hi*width)^, Pointer(Integer(base) + Lo*width)^, width);
      Move(TempBuffer^,                        Pointer(Integer(base) + Hi*width)^, width);
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;

  if Hi > Left  then qsort_int(base, width, compare, Left, Hi,  TempBuffer, TempBuffer2);
  if Lo < Right then qsort_int(base, width, compare, Lo, Right, TempBuffer, TempBuffer2);
end;

procedure QSort(base: Pointer; num: Size_t; width: Size_t; compare: QSortCB);
var
  p, p1: Pointer;
begin
  GetMem(p, width);
  GetMem(p1, width);
    qsort_int(base, width, compare, 0, num - 1, p, p1);
    FreeMem(p1, width);
    FreeMem(p, width);
end;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; forward;
function SelectDeviceProc(hDlg: HWND; msg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer; stdcall; forward;

function Button_GetCheck(hwndCtl: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
end;

function ComboBox_GetCurSel(hwndCtl: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
end;

function ComboBox_SetCurSel(hwndCtl, index: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_SETCURSEL, index, 0);
end;

function ComboBox_GetItemData(hwndCtl, index: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_GETITEMDATA, index, 0);
end;

function ComboBox_SetItemData(hwndCtl, index, data: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_SETITEMDATA, index, data);
end;

function ComboBox_GetCount(hwndCtl: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_GETCOUNT, 0, 0);
end;

function ComboBox_ResetContent(hwndCtl: Integer): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_RESETCONTENT, 0, 0);
end;

function ComboBox_AddString(hwndCtl: Integer; lpsz: PChar): Integer;
begin
  Result:= SendMessage(hwndCtl, CB_ADDSTRING, 0, Integer(lpsz));
end;

function Button_SetCheck(hwndCtl: Integer; check: BOOL): Integer;
begin
  Result:= SendMessage(hwndCtl, BM_SETCHECK, Integer(check), 0);
end;

////////////////////////////////

function CD3DApplication.
  ConfirmDevice(var p1: TD3DCaps8; p2: DWORD; p3: TD3DFormat): HRESULT; begin Result:= S_OK; end;
function CD3DApplication.
  OneTimeSceneInit: HRESULT;                         begin result:= S_OK; end;
function CD3DApplication.
  InitDeviceObjects: HRESULT;                        begin result:= S_OK; end;
function CD3DApplication.
  RestoreDeviceObjects: HRESULT;                     begin result:= S_OK; end;
function CD3DApplication.
  FrameMove: HRESULT;                                begin result:= S_OK; end;
function CD3DApplication.
  Render: HRESULT;                                   begin result:= S_OK; end;
function CD3DApplication.
  InvalidateDeviceObjects: HRESULT;                  begin result:= S_OK; end;
function CD3DApplication.
  DeleteDeviceObjects: HRESULT;                      begin result:= S_OK; end;
function CD3DApplication.
  FinalCleanup: HRESULT;                             begin result:= S_OK; end;

procedure CD3DApplication.ToggleStart;
begin
  // Toggle frame movement
  m_bFrameMoving := not m_bFrameMoving;

  // DXUtil_Timer( m_bFrameMoving ? TIMER_START : TIMER_STOP );
  if m_bFrameMoving then DXUtil_Timer(TIMER_START) else DXUtil_Timer(TIMER_STOP);
end;

procedure CD3DApplication.SingleStep;
begin
  // Single-step frame movement
  if (FALSE = m_bFrameMoving)
    then DXUtil_Timer(TIMER_ADVANCE)
    else DXUtil_Timer(TIMER_STOP);

  m_bFrameMoving := False;
  m_bSingleStep  := True;
end;

procedure CD3DApplication.ToggleFullScreenMode;
begin
  // Toggle the fullscreen/window mode
  if m_bActive and m_bReady then
  begin
    if FAILED(ToggleFullscreen) then
      DisplayErrorMsg(D3DAPPERR_RESIZEFAILED, MSGERR_APPMUSTEXIT);
  end;
end;

//-----------------------------------------------------------------------------
// Global access to the app (needed for the global WndProc())
//-----------------------------------------------------------------------------
//static CD3DApplication* g_pD3DApp = NULL;
var
  g_pD3DApp: CD3DApplication = nil;

//-----------------------------------------------------------------------------
// Name: CD3DApplication()
// Desc: Constructor
//-----------------------------------------------------------------------------
constructor CD3DApplication.Create(hWindow: HWND);
begin
  g_pD3DApp           := Self;

  FOldWndProc         := nil;

  m_dwNumAdapters     := 0;
  m_dwAdapter         := 0;
  m_pD3D              := nil;
  m_pd3dDevice        := nil;
  m_hWnd              := hWindow;
  m_hWndFocus         := 0;
  m_hMenu             := 0;
  m_bActive           := False;
  m_bReady            := False;
  m_bHasFocus         := False;
  m_dwCreateFlags     := 0;

  m_bFrameMoving      := True;
  m_bSingleStep       := False;
  m_fFPS              := 0.0;
  m_strDeviceStats[0] := #0;
  m_strFrameStats[0]  := #0;

  m_strWindowTitle    := 'D3D8 Application';
  m_dwCreationWidth   := 400;
  m_dwCreationHeight  := 300;
  m_bUseDepthBuffer   := False;
  m_dwMinDepthBits    := 16;
  m_dwMinStencilBits  := 0;
  m_bShowCursorWhenFullscreen := False;

  // When m_bClipCursorWhenFullscreen is TRUE, the cursor is limited to
  // the device window when the app goes fullscreen.  This prevents users
  // from accidentally clicking outside the app window on a multimon system.
  // This flag is turned off by default for debug builds, since it makes
  // multimon debugging difficult.
{$IFDEF DEBUG}
  m_bClipCursorWhenFullscreen := False;
{$ELSE}
  m_bClipCursorWhenFullscreen := True;
{$ENDIF}
end;


//-----------------------------------------------------------------------------
// Name: WndProc()
// Desc: Static msg handler which passes messages to the application class.
//-----------------------------------------------------------------------------
function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  Result:= g_pD3DApp.MsgProc(hWnd, uMsg, wParam, lParam);
end;

var
  wndClass: TWndClass = (
    style: 0;
    lpfnWndProc: @WndProc;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hInstance: 0;
    hIcon: 0;
    hCursor: 0;
    hbrBackground: 0;
    lpszMenuName: nil;
    lpszClassName: 'D3D Window');


//-----------------------------------------------------------------------------
// Name: Create()
// Desc:
//-----------------------------------------------------------------------------
function CD3DApplication.Create_(hInstance: LongWord): HRESULT;
var
  hr: HRESULT;
  rc: TRect;
begin
  // Create the Direct3D object
  m_pD3D:= Direct3DCreate8(D3D_SDK_VERSION);
  if (m_pD3D = nil) then
  begin
    Result:= DisplayErrorMsg(D3DAPPERR_NODIRECT3D, MSGERR_APPMUSTEXIT);
    Exit;
  end;

  // Build a list of Direct3D adapters, modes and devices. The
  // ConfirmDevice() callback is used to confirm that only devices that
  // meet the app's requirements are considered.
  hr:= BuildDeviceList;
  if FAILED(hr) then
  begin
    SAFE_RELEASE(m_pD3D);
    Result:= DisplayErrorMsg(hr, MSGERR_APPMUSTEXIT);
    Exit;
  end;

  // Unless a substitute hWnd has been specified, create a window to
  // render into
  if (m_hWnd = 0) then
  begin
    // Register the windows class
    with wndClass do
    begin
      hInstance:= SysInit.hInstance;
      hIcon:= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MAIN_ICON));
      hCursor:= LoadCursor(0, IDC_ARROW);
      hbrBackground:= GetStockObject(WHITE_BRUSH);
    end;
    RegisterClass(wndClass);

    // Set the window's initial style
    m_dwWindowStyle:= WS_OVERLAPPED or
                      WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or
                      WS_MINIMIZEBOX or WS_VISIBLE;

    // Set the window's initial width
    SetRect(rc, 0, 0, m_dwCreationWidth, m_dwCreationHeight);
    AdjustWindowRect(rc, m_dwWindowStyle, TRUE);

    // Create the render window
    m_hWnd:= CreateWindow('D3D Window', m_strWindowTitle, m_dwWindowStyle,
                          Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
                          (rc.right-rc.left), (rc.bottom-rc.top), 0,
                          LoadMenu(hInstance, MAKEINTRESOURCE(IDR_MENU)),
                          hInstance, nil);
  end else
  begin
    FOldWndProc := Pointer(SetWindowLong(m_hWnd, GWL_WndProc, Longint(@WndProc)));
  end;

  SetWindowText(m_hWnd, m_strWindowTitle);

  // The focus window can be a specified to be a different window than the
  // device window.  If not, use the device window as the focus window.
  if (m_hWndFocus = 0) then
    m_hWndFocus:= m_hWnd;

  // Save window properties
  m_dwWindowStyle:= GetWindowLong(m_hWnd, GWL_STYLE);
  GetWindowRect(m_hWnd, m_rcWindowBounds);
  GetClientRect(m_hWnd, m_rcWindowClient);

  // Initialize the application timer
  DXUtil_Timer(TIMER_START);

  // Initialize the app's custom scene stuff
  hr:= OneTimeSceneInit;
  if FAILED(hr) then
  begin
    SAFE_RELEASE(m_pD3D);
    Result:= DisplayErrorMsg(hr, MSGERR_APPMUSTEXIT);
    Exit;
  end;

  // Initialize the 3D environment for the app
  hr:= Initialize3DEnvironment;
  if FAILED(hr) then
  begin
    SAFE_RELEASE(m_pD3D);
    Result:= DisplayErrorMsg(hr, MSGERR_APPMUSTEXIT);
    Exit;
  end;

  // The app is ready to go
  m_bReady:= TRUE;

  Result:= S_OK;
end;

destructor CD3DApplication.Destroy;
begin
  if Assigned(FOldWndProc) then
    SetWindowLong(m_hWnd, GWL_WndProc, Integer(FOldWndProc));

  inherited Destroy;
end;




//-----------------------------------------------------------------------------
// Name: SortModesCallback()
// Desc: Callback function for sorting display modes (used by BuildDeviceList).
//-----------------------------------------------------------------------------
function SortModesCallback(const arg1, arg2: Pointer): Integer;
var
  p1: PD3DDisplayMode;
  p2: PD3DDisplayMode;
begin
  p1 := arg1;
  p2 := arg2;

  if (p1^.Format > p2^.Format) then begin result:= -1; Exit; end;
  if (p1^.Format < p2^.Format) then begin result:= +1; Exit; end;
  if (p1^.Width  < p2^.Width)  then begin result:= -1; Exit; end;
  if (p1^.Width  > p2^.Width)  then begin result:= +1; Exit; end;
  if (p1^.Height < p2^.Height) then begin result:= -1; Exit; end;
  if (p1^.Height > p2^.Height) then begin result:= +1; Exit; end;

  Result:= 0;
end;


//-----------------------------------------------------------------------------
// Name: BuildDeviceList()
// Desc:
//-----------------------------------------------------------------------------
function CD3DApplication.BuildDeviceList:HRESULT;
const
  dwNumDeviceTypes = 2;
  //const TCHAR* strDeviceDescs[] = { _T("HAL"), _T("REF") };
  strDeviceDescs: array[0..1] of PChar = ('HAL', 'REF');
  //const D3DDEVTYPE DeviceTypes[] = { D3DDEVTYPE_HAL, D3DDEVTYPE_REF };
  DeviceTypes: array[0..1] of TD3DDevType = (D3DDEVTYPE_HAL, D3DDEVTYPE_REF);
var
  bHALExists: BOOL;
  bHALIsWindowedCompatible: BOOL;
  bHALIsDesktopCompatible: BOOL;
  bHALIsSampleCompatible: BOOL;
  iAdapter: Integer;
  pAdapter: PD3DAdapterInfo;
  modes: array[0..99] of TD3DDisplayMode;
  formats: array[0..19] of TD3DFormat;
  dwNumFormats: Integer;
  dwNumModes: Integer;
  dwNumAdapterModes: DWORD;
  iMode: Integer;
  DisplayMode: TD3DDisplayMode;
  m, f, a, d: Integer;
  iDevice: Cardinal;
  pDevice: PD3DDeviceInfo;
  bFormatConfirmed: array[0..19] of BOOL;
  dwBehavior: array[0..19] of DWORD;
  fmtDepthStencil: array[0..19] of TD3DFormat;
  WhileCounter: integer;
begin
  bHALExists := False;
  bHALIsWindowedCompatible := False;
  bHALIsDesktopCompatible  := False;
  bHALIsSampleCompatible   := False;

  // Loop through all the adapters on the system (usually, there's just one
  // unless more than one graphics card is present).
  WhileCounter:=0;
  while WhileCounter<2 do begin
  m_dwNumAdapters:=0;

  for iAdapter := 0 to (m_pD3D.GetAdapterCount - 1) do
  begin
    // Fill in adapter info
    pAdapter := @m_Adapters[m_dwNumAdapters];
    m_pD3D.GetAdapterIdentifier(iAdapter, D3DENUM_NO_WHQL_LEVEL, pAdapter^.d3dAdapterIdentifier);
    m_pD3D.GetAdapterDisplayMode(iAdapter, pAdapter^.d3ddmDesktop);
    pAdapter^.dwNumDevices    := 0;
    pAdapter^.dwCurrentDevice := 0;

    // Enumerate all display modes on this adapter
    dwNumFormats      := 0;
    dwNumModes        := 0;
    dwNumAdapterModes := m_pD3D.GetAdapterModeCount(iAdapter);

    // Add the adapter's current desktop format to the list of formats
    formats[dwNumFormats] := pAdapter^.d3ddmDesktop.Format;
    inc(dwNumFormats);

    for iMode := 0 to (dwNumAdapterModes - 1) do
    begin
      // Get the display mode attributes
      m_pD3D.EnumAdapterModes(iAdapter, iMode, DisplayMode);

      // Filter out low-resolution modes
      if (DisplayMode.Width < 640) or (DisplayMode.Height < 400)
        then Continue;

      // Check if the mode already exists (to filter out refresh rates)
      m:= 0;
      if dwNumModes <> 0 then
        for m:= 0 to (dwNumModes - 1) do
        begin
          if ((modes[m].Width  = DisplayMode.Width ) and
              (modes[m].Height = DisplayMode.Height) and
              (modes[m].Format = DisplayMode.Format))
          then Break;
        end;

      // If we found a new mode, add it to the list of modes
      if (m = dwNumModes) then
      begin
        modes[dwNumModes].Width       := DisplayMode.Width;
        modes[dwNumModes].Height      := DisplayMode.Height;
        modes[dwNumModes].Format      := DisplayMode.Format;
        modes[dwNumModes].RefreshRate := 0;
        Inc(dwNumModes);

        // Check if the mode's format already exists
        for f:= 0 to dwNumFormats - 1 do
          if (DisplayMode.Format = formats[f]) then Break;

        // If the format is new, add it to the list
        if (f = dwNumFormats) then
        begin
          formats[dwNumFormats]:= DisplayMode.Format;
          Inc(dwNumFormats);
        end;
      end;
    end;

    // Sort the list of display modes (by format, then width, then height)
    qsort(@modes, dwNumModes, SizeOf(TD3DDisplayMode), SortModesCallback);

    // Add devices to adapter
    for iDevice := 0 to (dwNumDeviceTypes - 1) do
    begin
      // Fill in device info
      pDevice                  := @pAdapter^.devices[pAdapter^.dwNumDevices];
      pDevice^.DeviceType      := DeviceTypes[iDevice];
      m_pD3D.GetDeviceCaps(iAdapter, DeviceTypes[iDevice], pDevice^.d3dCaps);
      pDevice^.strDesc         := strDeviceDescs[iDevice];
      pDevice^.dwNumModes      := 0;
      pDevice^.dwCurrentMode   := 0;
      pDevice^.bCanDoWindowed  := FALSE;
      pDevice^.bWindowed       := FALSE;
      pDevice^.MultiSampleTypeWindowed := D3DMULTISAMPLE_NONE;
      pDevice^.MultiSampleTypeFullscreen := D3DMULTISAMPLE_NONE;

      // Examine each format supported by the adapter to see if it will
      // work with this device and meets the needs of the application.

      for f:= 0 to (dwNumFormats - 1) do
      begin
        bFormatConfirmed[f] := False;
        fmtDepthStencil[f]  := D3DFMT_UNKNOWN;

        // Skip formats that cannot be used as render targets on this device
        if FAILED(m_pD3D.CheckDeviceType(iAdapter, pDevice^.DeviceType, formats[f], formats[f], FALSE))
        then Continue;

        if (pDevice^.DeviceType = D3DDEVTYPE_HAL) then
        begin
          // This system has a HAL device
          bHALExists := True;

          if (pDevice^.d3dCaps.Caps2 and D3DCAPS2_CANRENDERWINDOWED) = D3DCAPS2_CANRENDERWINDOWED then
          begin
            // HAL can run in a window for some mode
            bHALIsWindowedCompatible := True;

            if (f = 0) then
            begin
              // HAL can run in a window for the current desktop mode
              bHALIsDesktopCompatible := True;
            end;
          end;
        end;

        // Confirm the device/format for HW vertex processing
        if (pDevice^.d3dCaps.DevCaps and D3DDEVCAPS_HWTRANSFORMANDLIGHT) = D3DDEVCAPS_HWTRANSFORMANDLIGHT then
        begin
          if (pDevice^.d3dCaps.DevCaps and D3DDEVCAPS_PUREDEVICE) = D3DDEVCAPS_PUREDEVICE then
          begin
            dwBehavior[f] := D3DCREATE_HARDWARE_VERTEXPROCESSING or
                             D3DCREATE_PUREDEVICE;

            if SUCCEEDED(ConfirmDevice(pDevice^.d3dCaps, dwBehavior[f], formats[f]))
            then bFormatConfirmed[f] := True;
          end;

          if (FALSE = bFormatConfirmed[f]) then
          begin
            dwBehavior[f] := D3DCREATE_HARDWARE_VERTEXPROCESSING;

            if SUCCEEDED(ConfirmDevice(pDevice^.d3dCaps, dwBehavior[f], formats[f]))
            then bFormatConfirmed[f] := True;
          end;

          if (FALSE = bFormatConfirmed[f]) then
          begin
            dwBehavior[f] := D3DCREATE_MIXED_VERTEXPROCESSING;

            if SUCCEEDED(ConfirmDevice(pDevice^.d3dCaps, dwBehavior[f], formats[f]))
            then bFormatConfirmed[f] := True;
          end;
        end;

        // Confirm the device/format for SW vertex processing
        if (FALSE = bFormatConfirmed[f]) then
        begin
          dwBehavior[f] := D3DCREATE_SOFTWARE_VERTEXPROCESSING;

          if SUCCEEDED(ConfirmDevice(pDevice^.d3dCaps, dwBehavior[f], formats[f]))
          then bFormatConfirmed[f] := True;
        end;

        // Find a suitable depth/stencil buffer format for this device/format
        if (bFormatConfirmed[f] and m_bUseDepthBuffer) then
        begin
          if (not FindDepthStencilFormat(iAdapter, pDevice^.DeviceType,
                                         formats[f], fmtDepthStencil[f]))
          then bFormatConfirmed[f] := False;
        end;
      end;

      // Add all enumerated display modes with confirmed formats to the
      // device's list of valid modes
      for m:= 0 to dwNumModes - 1 do
      begin
        for f:= 0 to dwNumFormats - 1 do
        begin
          if (modes[m].Format = formats[f]) then
          begin
            if (bFormatConfirmed[f] = TRUE) then
            begin
              // Add this mode to the device's list of valid modes
              pDevice^.modes[pDevice^.dwNumModes].Width      := modes[m].Width;
              pDevice^.modes[pDevice^.dwNumModes].Height     := modes[m].Height;
              pDevice^.modes[pDevice^.dwNumModes].Format     := modes[m].Format;
              pDevice^.modes[pDevice^.dwNumModes].dwBehavior := dwBehavior[f];
              pDevice^.modes[pDevice^.dwNumModes].DepthStencilFormat := fmtDepthStencil[f];
              Inc(pDevice^.dwNumModes);

              if (pDevice^.DeviceType = D3DDEVTYPE_HAL) then
                bHALIsSampleCompatible := True;
            end;
          end;
        end;
      end;

      // Select any 640x480 mode for default (but prefer a 16-bit mode)
      if pDevice^.dwNumModes <> 0 then for m:= 0 to (pDevice^.dwNumModes - 1) do
      begin
        if (pDevice^.modes[m].Width = m_dwCreationWidth) and (pDevice^.modes[m].Height = m_dwCreationHeight) then begin
          pDevice^.dwCurrentMode := m;
          if m_bWants32bit then begin
           if (pDevice^.modes[m].Format = D3DFMT_R8G8B8) or
              (pDevice^.modes[m].Format = D3DFMT_A8R8G8B8) or
              (pDevice^.modes[m].Format = D3DFMT_X8R8G8B8) or
              (pDevice^.modes[m].Format = D3DFMT_A2B10G10R10)
           then Break;
          end else begin
           if (pDevice^.modes[m].Format = D3DFMT_R5G6B5) or
              (pDevice^.modes[m].Format = D3DFMT_X1R5G5B5) or
              (pDevice^.modes[m].Format = D3DFMT_A1R5G5B5) or
              (pDevice^.modes[m].Format = D3DFMT_A4R4G4B4) or
              (pDevice^.modes[m].Format = D3DFMT_X4R4G4B4)
           then Break;
          end;
        end;
      end;

      // Check if the device is compatible with the desktop display mode
      // (which was added initially as formats[0])
      if (bFormatConfirmed[0]) and
         ((pDevice^.d3dCaps.Caps2 and D3DCAPS2_CANRENDERWINDOWED) = D3DCAPS2_CANRENDERWINDOWED) then
      begin
        pDevice^.bCanDoWindowed := True;
        pDevice^.bWindowed      := m_bCreateWindowed;
      end;

      // If valid modes were found, keep this device
      if (pDevice^.dwNumModes > 0) then
        Inc(pAdapter^.dwNumDevices);
    end;

    // If valid devices were found, keep this adapter
    if (pAdapter^.dwNumDevices > 0) then Inc(m_dwNumAdapters);
  end;

  for a:= 0 to m_dwNumAdapters - 1 do begin
   for d:= 0 to m_Adapters[a].dwNumDevices - 1 do if m_Adapters[a].devices[d].bCanDoWindowed or (not m_bCreateWindowed) then begin
    if (m_Adapters[a].devices[d].DeviceType = D3DDEVTYPE_REF) then m_dwMinStencilBits:=0
     else WhileCounter:=256;
    Break;
    WhileCounter:=-WhileCounter;
   end;
   if WhileCounter<0 then begin WhileCounter:=-WhileCounter; Break; end;
  end;
  Inc(WhileCounter);

  end;

  // Return an error if no compatible devices were found
  if (0 = m_dwNumAdapters) then
  begin
    Result:= D3DAPPERR_NOCOMPATIBLEDEVICES;
    Exit;
  end;

  // Pick a default device that can render into a window
  // (This code assumes that the HAL device comes before the REF
  // device in the device array).
  for a:= 0 to m_dwNumAdapters - 1 do
  begin
    for d:= 0 to m_Adapters[a].dwNumDevices - 1 do
    begin
      if m_Adapters[a].devices[d].bCanDoWindowed or (not m_bCreateWindowed) then
      begin
        m_Adapters[a].dwCurrentDevice := d;
        m_dwAdapter := a;
        m_bWindowed := m_bCreateWindowed;

        // Display a warning message
        if (m_Adapters[a].devices[d].DeviceType = D3DDEVTYPE_REF) then
        begin
          if (not bHALExists) then
            DisplayErrorMsg(D3DAPPERR_NOHARDWAREDEVICE, MSGWARN_SWITCHEDTOREF)
          else if (not bHALIsSampleCompatible) then
            DisplayErrorMsg(D3DAPPERR_HALNOTCOMPATIBLE, MSGWARN_SWITCHEDTOREF)
          else if (not bHALIsWindowedCompatible) then
            DisplayErrorMsg(D3DAPPERR_NOWINDOWEDHAL, MSGWARN_SWITCHEDTOREF)
          else if (not bHALIsDesktopCompatible) then
            DisplayErrorMsg(D3DAPPERR_NODESKTOPHAL, MSGWARN_SWITCHEDTOREF)
          else // HAL is desktop compatible, but not sample compatible
            DisplayErrorMsg(D3DAPPERR_NOHALTHISMODE, MSGWARN_SWITCHEDTOREF);
        end;

        Result:= S_OK;
        Exit;
      end;
    end;
  end;

  Result:= D3DAPPERR_NOWINDOWABLEDEVICES;
end;


//-----------------------------------------------------------------------------
// Name: FindDepthStencilFormat()
// Desc: Finds a depth/stencil format for the given device that is compatible
//       with the render target format and meets the needs of the app.
//-----------------------------------------------------------------------------
function CD3DApplication.
  FindDepthStencilFormat(iAdapter: UINT; DeviceType: TD3DDevType;
  TargetFormat: TD3DFormat; var pDepthStencilFormat: TD3DFormat): BOOL;
begin
  if (m_dwMinDepthBits <= 16) and (m_dwMinStencilBits = 0) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType, TargetFormat,
         D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D16)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
           TargetFormat, TargetFormat, D3DFMT_D16)) then
      begin
        pDepthStencilFormat:= D3DFMT_D16;
        Result:= TRUE;
        Exit;
      end;                           
    end;
  end;

  if (m_dwMinDepthBits <= 15) and (m_dwMinStencilBits <= 1) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType, TargetFormat,
         D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D15S1)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
           TargetFormat, TargetFormat, D3DFMT_D15S1)) then
      begin
        pDepthStencilFormat := D3DFMT_D15S1;
        Result:= True;
        Exit;
      end;
    end;
  end;

  if (m_dwMinDepthBits <= 24) and (m_dwMinStencilBits = 0) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType, TargetFormat,
         D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D24X8)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
           TargetFormat, TargetFormat, D3DFMT_D24X8)) then
      begin
        pDepthStencilFormat := D3DFMT_D24X8;
        Result:= True;
        Exit;
      end;
    end;
  end;

  if (m_dwMinDepthBits <= 24) and (m_dwMinStencilBits <= 8) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType,
         TargetFormat, D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D24S8)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
           TargetFormat, TargetFormat, D3DFMT_D24S8)) then
      begin
        pDepthStencilFormat := D3DFMT_D24S8;
        Result:= True;
        Exit;
      end;
    end;
  end;

  if (m_dwMinDepthBits <= 24) and (m_dwMinStencilBits <= 4) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType, TargetFormat,
         D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D24X4S4)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
          TargetFormat, TargetFormat, D3DFMT_D24X4S4)) then
      begin
        pDepthStencilFormat := D3DFMT_D24X4S4;
        Result:= True;
        Exit;
      end;
    end;
  end;

  if (m_dwMinDepthBits <= 32) and (m_dwMinStencilBits = 0) then
  begin
    if SUCCEEDED(m_pD3D.CheckDeviceFormat(iAdapter, DeviceType, TargetFormat,
         D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, D3DFMT_D32)) then
    begin
      if SUCCEEDED(m_pD3D.CheckDepthStencilMatch(iAdapter, DeviceType,
           TargetFormat, TargetFormat, D3DFMT_D32)) then
      begin
        pDepthStencilFormat := D3DFMT_D32;
        Result:= True;
        Exit;
      end;
    end;
  end;

  Result:= False;
end;


//-----------------------------------------------------------------------------
// Name: MsgProc()
// Desc: Message handling function.
//-----------------------------------------------------------------------------
function CD3DApplication.MsgProc(
  hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hr: HRESULT;
  rcClientOld: TRect;
  ptCursor: TPoint;
begin
  case uMsg of
    WM_PAINT:
      // Handle paint messages when the app is not ready
      if (m_pd3dDevice <> nil) and (not m_bReady) then
      begin
        if (m_bWindowed) then
        begin
          Render;
          m_pd3dDevice.Present(nil, nil, 0, nil);
        end;
      end;

    WM_ACTIVATEAPP:
      m_bHasFocus:= BOOL(wParam);

    WM_GETMINMAXINFO:
    begin
      PMinMaxInfo(lParam)^.ptMinTrackSize.x := 100;
      PMinMaxInfo(lParam)^.ptMinTrackSize.y := 100;
    end;

    //WM_ENTERSIZEMOVE:
      // Halt frame movement while the app is sizing or moving

    WM_SIZE:
      // Check to see if we are losing our window...
      if (SIZE_MAXHIDE = wParam) or (SIZE_MINIMIZED = wParam) then
      begin
        if (m_bClipCursorWhenFullscreen and not m_bWindowed) then
          ClipCursor(nil);
        m_bActive := FALSE;
      end
      else
        m_bActive := TRUE;

    WM_EXITSIZEMOVE:
    begin

      if (m_bActive) and (m_bWindowed) then
      begin
        rcClientOld := m_rcWindowClient;

        // Update window properties
        GetWindowRect(m_hWnd, m_rcWindowBounds);
        GetClientRect(m_hWnd, m_rcWindowClient);

        if (rcClientOld.right - rcClientOld.left <>
              m_rcWindowClient.right - m_rcWindowClient.left) or
           (rcClientOld.bottom - rcClientOld.top <>
              m_rcWindowClient.bottom - m_rcWindowClient.top) then
        begin
          // A new window size will require a new backbuffer
          // size, so the 3D structures must be changed accordingly.
          m_bReady := False;

          m_d3dpp.BackBufferWidth  := m_rcWindowClient.right - m_rcWindowClient.left;
          m_d3dpp.BackBufferHeight := m_rcWindowClient.bottom - m_rcWindowClient.top;

          // Resize the 3D environment
          hr := Resize3DEnvironment;
          if FAILED(hr) then
          begin
            DisplayErrorMsg(D3DAPPERR_RESIZEFAILED, MSGERR_APPMUSTEXIT);
            Result:= 0;
            Exit;
          end;

          m_bReady := True;
        end;
      end;
    end;

    WM_SETCURSOR:
      // Turn off Windows cursor in fullscreen mode
      if (m_bActive) and (m_bReady) and (not m_bWindowed) then
      begin
        SetCursor(0);
        if (m_bShowCursorWhenFullscreen) then
          m_pd3dDevice.ShowCursor(TRUE);
        Result:= 1; // prevent Windows from setting cursor to window class cursor
        Exit;
      end;

    WM_MOUSEMOVE:
      if (m_bActive) and (m_bReady) and (m_pd3dDevice <> nil) then
      begin
        GetCursorPos(ptCursor);
        if (not m_bWindowed) then
          ScreenToClient(m_hWnd, ptCursor);
        m_pd3dDevice.SetCursorPosition(ptCursor.x, ptCursor.y, 0);
      end;

    //WM_ENTERMENULOOP:
      // Pause the app when menus are displayed

    //WM_EXITMENULOOP:

    WM_CONTEXTMENU:
    begin
      // No context menus allowed in fullscreen mode
      if m_bWindowed then
        // Handle the app's context menu (via right mouse click)
        TrackPopupMenuEx(GetSubMenu(LoadMenu(0, MAKEINTRESOURCE(IDR_POPUP)), 0),
                         TPM_VERTICAL, LOWORD(lParam), HIWORD(lParam), hWnd, nil);
    end;

    WM_NCHITTEST:
      // Prevent the user from selecting the menu in fullscreen mode
      if (not m_bWindowed) then
      begin
        Result:= HTCLIENT;
        Exit;
      end;

    WM_POWERBROADCAST:
    begin
      case wParam of
        // #define PBT_APMQUERYSUSPEND 0x0000
        $0000:
        begin
          // At this point, the app should save any data for open
          // network connections, files, etc., and prepare to go into
          // a suspended mode.
          Result:= iTRUE;
          Exit;
        end;

        // #define PBT_APMRESUMESUSPEND 0x0007
        $0007:
        begin
          // At this point, the app should recover any data, network
          // connections, files, etc., and resume running from when
          // the app was suspended.
          Result:= iTRUE;
          Exit;
        end;
      end;
    end;

    WM_SYSCOMMAND:
      // Prevent moving/sizing and power loss in fullscreen mode
      case wParam of
        SC_MOVE,
        SC_SIZE,
        SC_MAXIMIZE,
        SC_KEYMENU,
        SC_MONITORPOWER:
          if (FALSE = m_bWindowed) then
          begin
            Result:= 1;
            Exit;
          end;
      end;

    WM_COMMAND:
      case LOWORD(wParam) of
        IDM_TOGGLESTART:
        begin
          // Toggle frame movement
          m_bFrameMoving:= not m_bFrameMoving;
          if m_bFrameMoving then
            DXUtil_Timer(TIMER_START)
          else
            DXUtil_Timer(TIMER_STOP);
        end;

        IDM_SINGLESTEP:
        begin
          // Single-step frame movement
          if (not m_bFrameMoving) then
            DXUtil_Timer(TIMER_ADVANCE)
          else
            DXUtil_Timer(TIMER_STOP);
          m_bFrameMoving := False;
          m_bSingleStep  := True;
        end;

        IDM_CHANGEDEVICE:
        begin
          // Prompt the user to select a new device or mode
          if (m_bActive and m_bReady) then
          begin

            if FAILED(UserSelectNewDevice) then
            begin
              Result:= 0;
              Exit;
            end;
          end;
          Result:= 0;
          Exit;
        end;

        IDM_TOGGLEFULLSCREEN:
        begin
          // Toggle the fullscreen/window mode
          if (m_bActive and m_bReady) then
          begin

            if FAILED(ToggleFullscreen) then
            begin
              DisplayErrorMsg(D3DAPPERR_RESIZEFAILED, MSGERR_APPMUSTEXIT);
              Result:= 0;
              Exit;
            end;

          end;
          Result:= 0;
          Exit;
        end;

        IDM_EXIT:
        begin
          // Recieved key/menu command to exit app
          SendMessage(hWnd, WM_CLOSE, 0, 0);
          Result:= 0;
          Exit;
        end;
      end;

    WM_CLOSE:
    begin
      Cleanup3DEnvironment;
      DestroyMenu(GetMenu(hWnd));
      DestroyWindow(hWnd);
      PostQuitMessage(0);
      Result:= 0;
      Exit;
    end;
  end;

  if Assigned(FOldWndProc)
  then Result := CallWindowProc(FOldWndProc, hWnd, uMsg, wParam, lParam)
  else Result := DefWindowProc (             hWnd, uMsg, wParam, lParam);
end;



//-----------------------------------------------------------------------------
// Name: Initialize3DEnvironment()
// Desc:
//-----------------------------------------------------------------------------
function CD3DApplication.Initialize3DEnvironment: HRESULT;
var
  hr: HRESULT;
  pAdapterInfo: PD3DAdapterInfo;
  pDeviceInfo: PD3DDeviceInfo;
  pModeInfo: PD3DModeInfo;
  pBackBuffer: IDirect3DSurface8;
  hCursor: DWORD;
  i: Cardinal;
  rcWindow: TRect;
begin
  pAdapterInfo := @m_Adapters[m_dwAdapter];
  pDeviceInfo  := @pAdapterInfo^.devices[pAdapterInfo^.dwCurrentDevice];
  pModeInfo    := @pDeviceInfo^.modes[pDeviceInfo^.dwCurrentMode];

  // Prepare window for possible windowed/fullscreen change
  AdjustWindowForChange;

  // Set up the presentation parameters
  ZeroMemory(@m_d3dpp, SizeOf(m_d3dpp));
  m_d3dpp.Windowed               := pDeviceInfo^.bWindowed;
  m_d3dpp.BackBufferCount        := 1;
  if (pDeviceInfo^.bWindowed) then                        
    m_d3dpp.MultiSampleType:= pDeviceInfo^.MultiSampleTypeWindowed
  else
    m_d3dpp.MultiSampleType:= pDeviceInfo^.MultiSampleTypeFullscreen;
  if not FAILED(m_pD3D.CheckDeviceMultisampleType(m_dwAdapter, pDeviceInfo^.DeviceType, pModeInfo^.Format, pDeviceInfo^.bWindowed, m_MultiSampleType)) then m_d3dpp.MultiSampleType:=m_MultiSampleType;

  m_d3dpp.SwapEffect             := D3DSWAPEFFECT_DISCARD;
  m_d3dpp.EnableAutoDepthStencil := m_bUseDepthBuffer;
  m_d3dpp.AutoDepthStencilFormat := pModeInfo^.DepthStencilFormat;
  m_d3dpp.hDeviceWindow          := m_hWnd;
  //m_d3dpp.Flags:=D3DPRESENTFLAG_LOCKABLE_BACKBUFFER;
  if (m_bWindowed) then
  begin
    m_d3dpp.BackBufferWidth  := m_rcWindowClient.right - m_rcWindowClient.left;
    m_d3dpp.BackBufferHeight := m_rcWindowClient.bottom - m_rcWindowClient.top;
    m_d3dpp.BackBufferFormat := pAdapterInfo^.d3ddmDesktop.Format;
  end else
  begin
    m_d3dpp.BackBufferWidth  := pModeInfo^.Width;
    m_d3dpp.BackBufferHeight := pModeInfo^.Height;
    m_d3dpp.BackBufferFormat := pModeInfo^.Format;
  end;

  if (pDeviceInfo.d3dCaps.PrimitiveMiscCaps and D3DPMISCCAPS_NULLREFERENCE <> 0) then
  begin
    // Warn user about null ref device that can't render anything
    DisplayErrorMsg(D3DAPPERR_NULLREFDEVICE, 0);
  end;

  // Create the device
  hr := m_pD3D.CreateDevice(m_dwAdapter, pDeviceInfo^.DeviceType,
                            m_hWndFocus, pModeInfo^.dwBehavior, m_d3dpp,
                            m_pd3dDevice);
  if SUCCEEDED(hr) then
  begin
    // When moving from fullscreen to windowed mode, it is important to
    // adjust the window size after recreating the device rather than
    // beforehand to ensure that you get the window size you want.  For
    // example, when switching from 640x480 fullscreen to windowed with
    // a 1000x600 window on a 1024x768 desktop, it is impossible to set
    // the window size to 1000x600 until after the display mode has
    // changed to 1024x768, because windows cannot be larger than the
    // desktop.
    if m_bWindowed then
    begin
      SetWindowPos(m_hWnd, HWND_NOTOPMOST,
                   m_rcWindowBounds.left, m_rcWindowBounds.top,
                   (m_rcWindowBounds.right - m_rcWindowBounds.left),
                   (m_rcWindowBounds.bottom - m_rcWindowBounds.top),
                   SWP_SHOWWINDOW);
    end;

    // Store device Caps
    m_pd3dDevice.GetDeviceCaps(m_d3dCaps);
    m_dwCreateFlags := pModeInfo^.dwBehavior;

    // Store device description
    if (pDeviceInfo^.DeviceType = D3DDEVTYPE_REF) then
      StrCopy(m_strDeviceStats, 'REF')
    else if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
      StrCopy(m_strDeviceStats, 'HAL')
    else if (pDeviceInfo^.DeviceType = D3DDEVTYPE_SW) then
      StrCopy(m_strDeviceStats, 'SW');

    if ((pModeInfo^.dwBehavior and D3DCREATE_HARDWARE_VERTEXPROCESSING) = D3DCREATE_HARDWARE_VERTEXPROCESSING) and
       ((pModeInfo^.dwBehavior and D3DCREATE_PUREDEVICE) = D3DCREATE_PUREDEVICE) then
    begin
      if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
        lstrcat(m_strDeviceStats, ' (pure hw vp)')
      else
        lstrcat(m_strDeviceStats, ' (simulated pure hw vp)');
    end
    else if (pModeInfo^.dwBehavior and D3DCREATE_HARDWARE_VERTEXPROCESSING ) = D3DCREATE_HARDWARE_VERTEXPROCESSING then
    begin
      if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
        lstrcat(m_strDeviceStats, ' (hw vp)')
      else
        lstrcat(m_strDeviceStats, ' (simulated hw vp)');
    end
    else if (pModeInfo^.dwBehavior and D3DCREATE_MIXED_VERTEXPROCESSING) = D3DCREATE_MIXED_VERTEXPROCESSING then
    begin
      if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
        lstrcat(m_strDeviceStats, ' (mixed vp)')
      else
        lstrcat(m_strDeviceStats, ' (simulated mixed vp)');
    end
    else if (pModeInfo^.dwBehavior and D3DCREATE_SOFTWARE_VERTEXPROCESSING) = D3DCREATE_SOFTWARE_VERTEXPROCESSING then
    begin
      lstrcat(m_strDeviceStats, ' (sw vp)');
    end;

    if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
    begin
      lstrcat(m_strDeviceStats, ': ');
      lstrcat(m_strDeviceStats, pAdapterInfo^.d3dAdapterIdentifier.Description);
    end;

    // Store render target surface desc

    m_pd3dDevice.GetBackBuffer(0, D3DBACKBUFFER_TYPE_MONO, pBackBuffer);
    pBackBuffer.GetDesc(m_d3dsdBackBuffer);
    SAFE_RELEASE(pBackBuffer);

    // Set up the fullscreen cursor
    if (m_bShowCursorWhenFullscreen) and (not m_bWindowed) then
    begin
      {$IFDEF WIN64}
      hCursor := GetClassLongPtr(m_hWnd, GCLP_HCURSOR);
      {$ELSE}
      hCursor := GetClassLong(m_hWnd, GCL_HCURSOR);
      {$ENDIF}
      D3DUtil_SetDeviceCursor(m_pd3dDevice, hCursor, True);
      m_pd3dDevice.ShowCursor(TRUE);
    end;

    // Confine cursor to fullscreen window
    if (m_bClipCursorWhenFullscreen) then
    begin
      if (not m_bWindowed) then
      begin
        GetWindowRect(m_hWnd, rcWindow);
        ClipCursor(@rcWindow);
      end else
        ClipCursor(nil);
    end;

    // Initialize the app's device-dependent objects
    hr := InitDeviceObjects;
    if SUCCEEDED(hr) then
    begin
      hr := RestoreDeviceObjects;
      if SUCCEEDED(hr) then
      begin
        m_bActive:= True;
        Result:= S_OK;
        Exit;
      end;
    end;

    // Cleanup before we try again
    InvalidateDeviceObjects;
    DeleteDeviceObjects;
    SAFE_RELEASE(m_pd3dDevice);
  end;

  // If that failed, fall back to the reference rasterizer
  if (pDeviceInfo^.DeviceType = D3DDEVTYPE_HAL) then
  begin
    // Select the default adapter
    m_dwAdapter := 0;
    pAdapterInfo := @m_Adapters[m_dwAdapter];

    // Look for a software device
    for i:= 0 to (pAdapterInfo^.dwNumDevices - 1) do
    begin
      if (pAdapterInfo^.devices[i].DeviceType = D3DDEVTYPE_REF) then
      begin
        pAdapterInfo^.dwCurrentDevice := i;
        pDeviceInfo:= @pAdapterInfo^.devices[i];
        m_bWindowed:= pDeviceInfo^.bWindowed;
        break;
      end;
    end;

    // Try again, this time with the reference rasterizer
    if (pAdapterInfo^.devices[pAdapterInfo^.dwCurrentDevice].DeviceType =
          D3DDEVTYPE_REF) then
    begin
      // Make sure main window isn't topmost, so error message is visible
      SetWindowPos(m_hWnd, HWND_NOTOPMOST,
                   m_rcWindowBounds.left, m_rcWindowBounds.top,
                   (m_rcWindowBounds.right - m_rcWindowBounds.left),
                   (m_rcWindowBounds.bottom - m_rcWindowBounds.top),
                   SWP_SHOWWINDOW);
      AdjustWindowForChange;

      // Let the user know we are caseing from HAL to the reference rasterizer
      DisplayErrorMsg(hr, MSGWARN_SWITCHEDTOREF);

      hr:= Initialize3DEnvironment;
    end;
  end;

  Result:= hr;
end;


//-----------------------------------------------------------------------------
// Name:
// Desc:
//-----------------------------------------------------------------------------
function CD3DApplication.Resize3DEnvironment: HRESULT;
var
  pBackBuffer: IDirect3DSurface8;
  hCursor_: HCURSOR;
  rcWindow: TRect;
begin
  // Release all vidmem objects
  Result := InvalidateDeviceObjects;
  if FAILED(Result) then Exit;

  // Reset the device
  Result := m_pd3dDevice.Reset(m_d3dpp);
  if FAILED(Result) then Exit;

  // Store render target surface desc
  m_pd3dDevice.GetBackBuffer(0, D3DBACKBUFFER_TYPE_MONO, pBackBuffer);
  pBackBuffer.GetDesc(m_d3dsdBackBuffer);
  SAFE_RELEASE(pBackBuffer);

  // Set up the fullscreen cursor
  if (m_bShowCursorWhenFullscreen) and (not m_bWindowed) then
  begin
    {$IFDEF WIN64}
    hCursor_ := GetClassLongPtr(m_hWnd, GCLP_HCURSOR);
    {$ELSE}
    hCursor_ := GetClassLong(m_hWnd, GCL_HCURSOR);
    {$ENDIF}
    D3DUtil_SetDeviceCursor(m_pd3dDevice, hCursor_, True);
    m_pd3dDevice.ShowCursor(True);
  end;

  // Confine cursor to fullscreen window
  if m_bClipCursorWhenFullscreen then
  begin
    if (not m_bWindowed) then
    begin
      GetWindowRect(m_hWnd, rcWindow);
      ClipCursor(@rcWindow);
    end else
      ClipCursor(nil);
  end;

  // Initialize the app's device-dependent objects
  Result := RestoreDeviceObjects;
  if FAILED(Result) then Exit;

  // If the app is paused, trigger the rendering of the current frame
  if (FALSE = m_bFrameMoving) then
  begin
    m_bSingleStep := True;
    DXUtil_Timer(TIMER_START);
    DXUtil_Timer(TIMER_STOP);
  end;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: ToggleFullScreen()
// Desc: Called when user toggles between fullscreen mode and windowed mode
//-----------------------------------------------------------------------------
function CD3DApplication.ToggleFullscreen: HRESULT;
var
  pAdapterInfo: PD3DAdapterInfo;
  pDeviceInfo: PD3DDeviceInfo;
  pModeInfo: PD3DModeInfo;
begin
  // Get access to current adapter, device, and mode
  pAdapterInfo := @m_Adapters[m_dwAdapter];
  pDeviceInfo  := @pAdapterInfo^.devices[pAdapterInfo^.dwCurrentDevice];
  pModeInfo    := @pDeviceInfo^.modes[pDeviceInfo^.dwCurrentMode];

  // Need device change if going windowed and the current device
  // can only be fullscreen
  if (not m_bWindowed) and (not pDeviceInfo^.bCanDoWindowed) then
  begin
    Result:= ForceWindowed;
    Exit;
  end;

  m_bReady := False;

  // Toggle the windowed state
  m_bWindowed := not m_bWindowed;
  pDeviceInfo^.bWindowed := m_bWindowed;

  // Prepare window for windowed/fullscreen change
  AdjustWindowForChange;

  // Set up the presentation parameters
  m_d3dpp.Windowed               := pDeviceInfo^.bWindowed;
  if (pDeviceInfo^.bWindowed) then
    m_d3dpp.MultiSampleType:= pDeviceInfo^.MultiSampleTypeWindowed
  else
    m_d3dpp.MultiSampleType:= pDeviceInfo^.MultiSampleTypeFullscreen;
  m_d3dpp.AutoDepthStencilFormat := pModeInfo^.DepthStencilFormat;
  m_d3dpp.hDeviceWindow          := m_hWnd;

  if (m_bWindowed) then
  begin
    m_d3dpp.BackBufferWidth  := m_rcWindowClient.right - m_rcWindowClient.left;
    m_d3dpp.BackBufferHeight := m_rcWindowClient.bottom - m_rcWindowClient.top;
    m_d3dpp.BackBufferFormat := pAdapterInfo^.d3ddmDesktop.Format;
  end else
  begin
    m_d3dpp.BackBufferWidth  := pModeInfo^.Width;
    m_d3dpp.BackBufferHeight := pModeInfo^.Height;
    m_d3dpp.BackBufferFormat := pModeInfo^.Format;
  end;

  // Resize the 3D device
  if FAILED(Resize3DEnvironment) then
  begin
    if (m_bWindowed)
    then Result:= ForceWindowed
    else Result:= E_FAIL;
    Exit;
  end;

  // When moving from fullscreen to windowed mode, it is important to
  // adjust the window size after resetting the device rather than
  // beforehand to ensure that you get the window size you want.  For
  // example, when switching from 640x480 fullscreen to windowed with
  // a 1000x600 window on a 1024x768 desktop, it is impossible to set
  // the window size to 1000x600 until after the display mode has
  // changed to 1024x768, because windows cannot be larger than the
  // desktop.
  if m_bWindowed then
  begin
    SetWindowPos(m_hWnd, HWND_NOTOPMOST,
                 m_rcWindowBounds.left, m_rcWindowBounds.top,
                 (m_rcWindowBounds.right - m_rcWindowBounds.left),
                 (m_rcWindowBounds.bottom - m_rcWindowBounds.top),
                 SWP_SHOWWINDOW);
  end;

  m_bReady := True;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: ForceWindowed()
// Desc: Switch to a windowed mode, even if that means picking a new device
//       and/or adapter
//-----------------------------------------------------------------------------
function CD3DApplication.ForceWindowed: HRESULT;
var
  hr: HRESULT;
  pAdapterInfoCur: PD3DAdapterInfo;
  pDeviceInfoCur: PD3DDeviceInfo;
  bFoundDevice: BOOL;
  pAdapterInfo: PD3DAdapterInfo;
  dwAdapter: DWORD;
  pDeviceInfo: PD3DDeviceInfo;
  dwDevice: DWORD;
begin
  pAdapterInfoCur := @m_Adapters[m_dwAdapter];
  pDeviceInfoCur  := @pAdapterInfoCur^.devices[pAdapterInfoCur^.dwCurrentDevice];
  bFoundDevice    := FALSE;

  if (pDeviceInfoCur^.bCanDoWindowed) then
  begin
    bFoundDevice := True;
  end else
  begin
    // Look for a windowable device on any adapter
    for dwAdapter:= 0 to (m_dwNumAdapters - 1) do
    begin
      pAdapterInfo := @m_Adapters[dwAdapter];
      for dwDevice := 0 to (pAdapterInfo^.dwNumDevices - 1) do
      begin
        pDeviceInfo := @pAdapterInfo^.devices[dwDevice];
        if (pDeviceInfo^.bCanDoWindowed) then
        begin
          m_dwAdapter := dwAdapter;
          pDeviceInfoCur := pDeviceInfo;
          pAdapterInfo^.dwCurrentDevice := dwDevice;
          bFoundDevice := True;
          Break;
        end;
      end;
      if bFoundDevice then Break;
    end;
  end;

  if not bFoundDevice then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  pDeviceInfoCur^.bWindowed := True;
  m_bWindowed := True;

  // Now destroy the current 3D device objects, then reinitialize

  m_bReady := False;

  // Release all scene objects that will be re-created for the new device
  InvalidateDeviceObjects;
  DeleteDeviceObjects;

  // Release display objects, so a new device can be created
  // if( m_pd3dDevice->Release() > 0L )
  //     return DisplayErrorMsg( D3DAPPERR_NONZEROREFCOUNT, MSGERR_APPMUSTEXIT );
  m_pd3dDevice:= nil;

  // Create the new device
  hr := Initialize3DEnvironment;
  if FAILED(hr) then
  begin
    Result:= DisplayErrorMsg(hr, MSGERR_APPMUSTEXIT);
    Exit;
  end;
  m_bReady := True;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: AdjustWindowForChange()
// Desc: Prepare the window for a possible change between windowed mode and
//       fullscreen mode.  This function is virtual and thus can be overridden
//       to provide different behavior, such as switching to an entirely
//       different window for fullscreen mode (as in the MFC sample apps).
//-----------------------------------------------------------------------------
function CD3DApplication.AdjustWindowForChange: HRESULT;
begin
  if (m_bWindowed) then
  begin
    // Set windowed-mode style
    SetWindowLong(m_hWnd, GWL_STYLE, m_dwWindowStyle);
    if (m_hMenu <> 0) then
      SetMenu(m_hWnd, m_hMenu);
  end else
  begin
    // Set fullscreen-mode style
    SetWindowLong(m_hWnd, GWL_STYLE, Integer(WS_POPUP or WS_SYSMENU or WS_VISIBLE));
    m_hMenu:= HMENU(SetMenu(m_hWnd, 0));
  end;
  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: UserSelectNewDevice()
// Desc: Displays a dialog so the user can select a new adapter, device, or
//       display mode, and then recreates the 3D environment if needed
//-----------------------------------------------------------------------------
function CD3DApplication.UserSelectNewDevice: HRESULT;
var
  hr: HRESULT;
  dwDevice: DWORD;
begin
  // Can't display dialogs in fullscreen mode
  if (m_bWindowed = FALSE) then
  begin
    if FAILED(ToggleFullscreen) then
    begin
      DisplayErrorMsg(D3DAPPERR_RESIZEFAILED, MSGERR_APPMUSTEXIT);
      Result:= E_FAIL;
      Exit;
    end;
  end;

  // Prompt the user to change the mode
  if (IDOK <> DialogBoxParam(GetModuleHandle(nil),
                             MAKEINTRESOURCE(IDD_SELECTDEVICE), m_hWnd,
                             @SelectDeviceProc, Integer(Self))) then
  begin
    Result:= S_OK;
    Exit;
  end;

  // Get access to the newly selected adapter, device, and mode
  dwDevice    := m_Adapters[m_dwAdapter].dwCurrentDevice;
  m_bWindowed := m_Adapters[m_dwAdapter].devices[dwDevice].bWindowed;

  // Release all scene objects that will be re-created for the new device
  InvalidateDeviceObjects;
  DeleteDeviceObjects;

  // Release display objects, so a new device can be created
  // if( m_pd3dDevice->Release() > 0L )
  //     result:= DisplayErrorMsg( D3DAPPERR_NONZEROREFCOUNT, MSGERR_APPMUSTEXIT );
  m_pd3dDevice:= nil;

  // Inform the display class of the change. It will internally
  // re-create valid surfaces, a d3ddevice, etc.
  hr := Initialize3DEnvironment;
  if FAILED(hr) then
  begin
    Result:= DisplayErrorMsg(hr, MSGERR_APPMUSTEXIT);
    Exit;
  end;

  // If the app is paused, trigger the rendering of the current frame
  if (FALSE = m_bFrameMoving) then
  begin
    m_bSingleStep := True;
    DXUtil_Timer(TIMER_START);
    DXUtil_Timer(TIMER_STOP);
  end;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: SelectDeviceProc()
// Desc: Windows message handling function for the device select dialog
//-----------------------------------------------------------------------------
function SelectDeviceProc(hDlg: HWND; msg: Cardinal;
  wParam: WPARAM; lParam: LPARAM): Integer; stdcall;
{$WRITEABLECONST ON}
// Static state for adapter/device/mode selection
const
  pd3dApp: CD3DApplication = nil;
  dwOldAdapter: DWORD = 0;
  dwNewAdapter: DWORD = 0;
  dwOldDevice: DWORD = 0;
  dwNewDevice: DWORD = 0;
  dwOldMode: DWORD = 0;
  dwNewMode: DWORD = 0;
  bOldWindowed: BOOL = False;
  bNewWindowed: BOOL = False;
  OldMultiSampleTypeWindowed: TD3DMultiSampleType = D3DMULTISAMPLE_NONE;
  NewMultiSampleTypeWindowed: TD3DMultiSampleType = D3DMULTISAMPLE_NONE;
  OldMultiSampleTypeFullscreen: TD3DMultiSampleType = D3DMULTISAMPLE_NONE;
  NewMultiSampleTypeFullscreen: TD3DMultiSampleType = D3DMULTISAMPLE_NONE;
{$WRITEABLECONST OFF}

var
  hwndAdapterList: HWND;
  hwndDeviceList: HWND;
  hwndFullscreenModeList: HWND;
  hwndWindowedRadio: HWND;
  hwndFullscreenRadio: HWND;
  hwndMultiSampleList: HWND;
  bUpdateDlgControls: BOOL;
  // Working variables
  pAdapter: PD3DAdapterInfo;
  pDevice: PD3DDeviceInfo;

  dwItem, d, a, m: DWORD;
  BitDepth: DWORD;
  strMode: array[0..79] of Char;
  strDesc: array[0..49] of Char;
  fmt: TD3DFormat;
begin
  // Get access to the UI controls
  hwndAdapterList        := GetDlgItem(hDlg, IDC_ADAPTER_COMBO);
  hwndDeviceList         := GetDlgItem(hDlg, IDC_DEVICE_COMBO);
  hwndFullscreenModeList := GetDlgItem(hDlg, IDC_FULLSCREENMODES_COMBO);
  hwndWindowedRadio      := GetDlgItem(hDlg, IDC_WINDOW);
  hwndFullscreenRadio    := GetDlgItem(hDlg, IDC_FULLSCREEN);
  hwndMultiSampleList    := GetDlgItem(hDlg, IDC_MULTISAMPLE_COMBO);
  bUpdateDlgControls     := FALSE;

  // Handle the initialization message
  if (WM_INITDIALOG = msg) then
  begin
    // Old state
    pd3dApp      := CD3DApplication(lParam);
    dwOldAdapter := pd3dApp.m_dwAdapter;
    pAdapter     := @pd3dApp.m_Adapters[dwOldAdapter];

    dwOldDevice  := pAdapter^.dwCurrentDevice;
    pDevice      := @pAdapter^.devices[dwOldDevice];

    dwOldMode    := pDevice^.dwCurrentMode;
    bOldWindowed := pDevice^.bWindowed;
    OldMultiSampleTypeWindowed :=   pDevice^.MultiSampleTypeWindowed;
    OldMultiSampleTypeFullscreen := pDevice^.MultiSampleTypeFullscreen;

    // New state is initially the same as the old state
    dwNewAdapter := dwOldAdapter;
    dwNewDevice  := dwOldDevice;
    dwNewMode    := dwOldMode;
    bNewWindowed := bOldWindowed;
    NewMultiSampleTypeWindowed :=   OldMultiSampleTypeWindowed;
    NewMultiSampleTypeFullscreen := OldMultiSampleTypeFullscreen;

    // Set flag to update dialog controls below
    bUpdateDlgControls := True;
  end;

  if (WM_COMMAND = msg) then
  begin
    // Get current UI state
    bNewWindowed  := BOOL(Button_GetCheck( hwndWindowedRadio ));

    if (IDOK = LOWORD(wParam)) then
    begin
      // Handle the case when the user hits the OK button. Check if any
      // of the options were changed
      if (dwNewAdapter <> dwOldAdapter) or (dwNewDevice  <> dwOldDevice)  or
         (dwNewMode    <> dwOldMode)    or (bNewWindowed <> bOldWindowed) or
         (NewMultiSampleTypeWindowed <> OldMultiSampleTypeWindowed) or
         (NewMultiSampleTypeFullscreen <> OldMultiSampleTypeFullscreen) then
      begin
        pd3dApp.m_dwAdapter := dwNewAdapter;

        pAdapter := @pd3dApp.m_Adapters[dwNewAdapter];
        pAdapter^.dwCurrentDevice := dwNewDevice;

        pAdapter^.devices[dwNewDevice].dwCurrentMode := dwNewMode;
        pAdapter^.devices[dwNewDevice].bWindowed     := bNewWindowed;
        pAdapter^.devices[dwNewDevice].MultiSampleTypeWindowed := NewMultiSampleTypeWindowed;
        pAdapter^.devices[dwNewDevice].MultiSampleTypeFullscreen := NewMultiSampleTypeFullscreen;

        EndDialog(hDlg, IDOK);
      end
      else
        EndDialog(hDlg, IDCANCEL);

      Result:= iTRUE;
      Exit;
    end
    else if (IDCANCEL = LOWORD(wParam)) then
    begin
      // Handle the case when the user hits the Cancel button
      EndDialog(hDlg, IDCANCEL);
      Result:= iTRUE;
      Exit;
    end
    else if (CBN_SELENDOK = HIWORD(wParam)) then
    begin
      if (LOWORD(wParam) = IDC_ADAPTER_COMBO) then
      begin
        dwNewAdapter := ComboBox_GetCurSel(hwndAdapterList);
        pAdapter     := @pd3dApp.m_Adapters[dwNewAdapter];

        dwNewDevice  := pAdapter^.dwCurrentDevice;
        dwNewMode    := pAdapter^.devices[dwNewDevice].dwCurrentMode;
        bNewWindowed := pAdapter^.devices[dwNewDevice].bWindowed;
      end
      else if (LOWORD(wParam) = IDC_DEVICE_COMBO) then
      begin
        pAdapter     := @pd3dApp.m_Adapters[dwNewAdapter];

        dwNewDevice  := ComboBox_GetCurSel(hwndDeviceList);
        dwNewMode    := pAdapter^.devices[dwNewDevice].dwCurrentMode;
        bNewWindowed := pAdapter^.devices[dwNewDevice].bWindowed;
      end
      else if (LOWORD(wParam) = IDC_FULLSCREENMODES_COMBO) then
      begin
        dwNewMode := ComboBox_GetCurSel(hwndFullscreenModeList);
      end
      else if (LOWORD(wParam) = IDC_MULTISAMPLE_COMBO) then
      begin
        dwItem := ComboBox_GetCurSel(hwndMultiSampleList);
        if (bNewWindowed) then
          NewMultiSampleTypeWindowed := TD3DMultiSampleType(ComboBox_GetItemData(hwndMultiSampleList, dwItem))
        else
          NewMultiSampleTypeFullscreen := TD3DMultiSampleType(ComboBox_GetItemData(hwndMultiSampleList, dwItem));
      end;
    end;
    // Keep the UI current
    bUpdateDlgControls := True;
  end;

  // Update the dialog controls
  if (bUpdateDlgControls) then
  begin
    // Reset the content in each of the combo boxes
    ComboBox_ResetContent(hwndAdapterList);
    ComboBox_ResetContent(hwndDeviceList);
    ComboBox_ResetContent(hwndFullscreenModeList);
    ComboBox_ResetContent(hwndMultiSampleList);

    pAdapter := @pd3dApp.m_Adapters[dwNewAdapter];
    pDevice  := @pAdapter^.devices[dwNewDevice];

    // Add a list of adapters to the adapter combo box
    for a:= 0 to (pd3dApp.m_dwNumAdapters - 1) do
    begin
      // Add device name to the combo box
      dwItem := ComboBox_AddString(hwndAdapterList,
        pd3dApp.m_Adapters[a].d3dAdapterIdentifier.Description);

      // Set the item data to identify this adapter
      ComboBox_SetItemData(hwndAdapterList, dwItem, a);

      // Set the combobox selection on the current adapater
      if (a = dwNewAdapter) then
        ComboBox_SetCurSel(hwndAdapterList, dwItem);
    end;

    // Add a list of devices to the device combo box
    for d:= 0 to (pAdapter^.dwNumDevices - 1) do
    begin
      // Add device name to the combo box
      dwItem := ComboBox_AddString(hwndDeviceList, pAdapter^.devices[d].strDesc);

      // Set the item data to identify this device
      ComboBox_SetItemData(hwndDeviceList, dwItem, d);

      // Set the combobox selection on the current device
      if (d = dwNewDevice) then
        ComboBox_SetCurSel(hwndDeviceList, dwItem);
    end;

    // Add a list of modes to the mode combo box
    for m:= 0 to (pDevice^.dwNumModes - 1) do
    begin
      BitDepth := 16;
      if (pDevice^.modes[m].Format = D3DFMT_X8R8G8B8) or
         (pDevice^.modes[m].Format = D3DFMT_A8R8G8B8) or
         (pDevice^.modes[m].Format = D3DFMT_R8G8B8) then
      begin
        BitDepth := 32;
      end;

      // Add mode desc to the combo box
      StrFmt(strMode, '%d x %d x %d',
        [pDevice^.modes[m].Width, pDevice.modes[m].Height, BitDepth]);
      dwItem := ComboBox_AddString( hwndFullscreenModeList, strMode);

      // Set the item data to identify this mode
      ComboBox_SetItemData(hwndFullscreenModeList, dwItem, m);

      // Set the combobox selection on the current mode
      if (m = dwNewMode) then
        ComboBox_SetCurSel(hwndFullscreenModeList, dwItem);
    end;

    // Add a list of multisample modes to the multisample combo box
    for m:= 0 to 16 do
    begin
      if (bNewWindowed)
      then fmt := pd3dApp.m_Adapters[dwNewAdapter].d3ddmDesktop.Format
      else fmt := pDevice^.modes[dwNewMode].Format;

      if (m = 1) then Continue; // 1 is not a valid multisample type

      if SUCCEEDED(pd3dApp.m_pD3D.CheckDeviceMultiSampleType(
           dwNewAdapter, pDevice^.DeviceType, fmt, bNewWindowed, TD3DMultiSampleType(m))) then
      begin
        if (m = 0) then
          strcopy(strDesc, 'none')
        else
          StrFmt(strDesc, '%d samples', [m]);

        // Add device name to the combo box
        dwItem := ComboBox_AddString(hwndMultiSampleList, strDesc);

        // Set the item data to identify this multisample type
        ComboBox_SetItemData(hwndMultiSampleList, dwItem, m);

        // Set the combobox selection on the current multisample type
        if (bNewWindowed) then
        begin
          if (TD3DMultiSampleType(m) = NewMultiSampleTypeWindowed) or (m = 0)
          then ComboBox_SetCurSel(hwndMultiSampleList, dwItem);
        end else
        begin
          if (TD3DMultiSampleType(m) = NewMultiSampleTypeFullscreen) or (m = 0)
          then ComboBox_SetCurSel(hwndMultiSampleList, dwItem);
        end;
      end;
    end;
    dwItem := ComboBox_GetCurSel(hwndMultiSampleList);
    if bNewWindowed then
      NewMultiSampleTypeWindowed := TD3DMultiSampleType(ComboBox_GetItemData(hwndMultiSampleList, dwItem))
    else
      NewMultiSampleTypeFullscreen := TD3DMultiSampleType(ComboBox_GetItemData(hwndMultiSampleList, dwItem));
    EnableWindow(hwndMultiSampleList, ComboBox_GetCount(hwndMultiSampleList) > 1);
    EnableWindow(hwndWindowedRadio, pDevice^.bCanDoWindowed);

    if bNewWindowed then
    begin
      Button_SetCheck(hwndWindowedRadio,   True);
      Button_SetCheck(hwndFullscreenRadio, False);
      EnableWindow(hwndFullscreenModeList, False);
    end
    else
    begin
      Button_SetCheck(hwndWindowedRadio,   False);
      Button_SetCheck(hwndFullscreenRadio, True);
      EnableWindow(hwndFullscreenModeList, True);
    end;
    Result:= iTRUE;
    Exit;
  end;

  Result:= iFALSE;
end;


//-----------------------------------------------------------------------------
// Name: Run()
// Desc:
//-----------------------------------------------------------------------------
function CD3DApplication.Run: Integer;
var
  hAccel: THandle;
  bGotMsg: BOOL;
  msg: TMsg;
begin
  // Load keyboard accelerators
  hAccel:= LoadAccelerators(0, MAKEINTRESOURCE(IDR_MAIN_ACCEL));

  // Now we're ready to recieve and process Windows messages.
  msg.message:= WM_NULL;
  PeekMessage(msg, 0, 0, 0, PM_NOREMOVE);

  while (WM_QUIT <> msg.message) do
  begin
    // Use PeekMessage() if the app is active, so we can use idle time to
    // render the scene. Else, use GetMessage() to avoid eating CPU time.
    if (m_bActive and m_bHasFocus)
      then bGotMsg:= PeekMessage(msg, 0, 0, 0, PM_REMOVE)
      else bGotMsg:= GetMessage(msg, 0, 0, 0);

    if bGotMsg then
    begin
      // Translate and dispatch the message
      if TranslateAccelerator(m_hWnd, hAccel, msg) = 0 then
      begin
        TranslateMessage(msg);
        DispatchMessage(msg);
      end;
    end else
    begin
      // Render a frame during idle time (no messages are waiting)
      if (m_bActive and m_bReady and m_bHasFocus) then
      begin
        if FAILED(Render3DEnvironment) then
          SendMessage(m_hWnd, WM_CLOSE, 0, 0);
      end;
    end;
  end;

  Result:= msg.wParam;
end;


//-----------------------------------------------------------------------------
// Name: Render3DEnvironment()
// Desc: Draws the scene.
//-----------------------------------------------------------------------------
function CD3DApplication.Render3DEnvironment: HRESULT;
{$WRITEABLECONST ON}
const
  fLastTime: Single = 0.0;
  dwFrames: DWORD = 0;
{$WRITEABLECONST OFF}
var
  pAdapterInfo: PD3DAdapterInfo;
  fAppTime: Single;
  fElapsedAppTime: Single;
  fTime: Single;
  mode: TD3DDisplayMode;
  d1: Integer;

  pDeviceInfo: PD3DDeviceInfo;
  pModeInfo: PD3DModeInfo;
  MultiSampleType: TD3DMultiSampleType;
begin
  // Test the cooperative level to see if it's okay to render
  Result:= m_pd3dDevice.TestCooperativeLevel;
  if FAILED(Result) then
  begin
    // If the device was lost, do not render until we get it back
    if (D3DERR_DEVICELOST = Result) then
    begin
      Result:= S_OK;
      Exit;
    end;

    // Check if the device needs to be resized.
    if (D3DERR_DEVICENOTRESET = Result) then
    begin
      // If we are windowed, read the desktop mode and use the same format for
      // the back buffer
      if m_bWindowed then
      begin
        pAdapterInfo := @m_Adapters[m_dwAdapter];
        m_pD3D.GetAdapterDisplayMode(m_dwAdapter, pAdapterInfo^.d3ddmDesktop);
        m_d3dpp.BackBufferFormat:= pAdapterInfo^.d3ddmDesktop.Format;
      end;

      Result:= Resize3DEnvironment;
      if FAILED(Result) then Exit;
    end;

    Exit;
  end;

  // Get the app's time, in seconds. Skip rendering if no time elapsed
  fAppTime        := DXUtil_Timer(TIMER_GETAPPTIME);
  fElapsedAppTime := DXUtil_Timer(TIMER_GETELAPSEDTIME);
  if (0.0 = fElapsedAppTime) and (m_bFrameMoving) then
  begin
    Result:= S_OK;
    Exit;
  end;

  // FrameMove (animate) the scene
  if (m_bFrameMoving) or (m_bSingleStep) then
  begin
    // Store the time for the app
    m_fTime        := fAppTime;
    m_fElapsedTime := fElapsedAppTime;

    // Frame move the scene
    Result := FrameMove;
    if FAILED(Result) then Exit;

    m_bSingleStep := False;
  end;

  // Render the scene as normal
  Result:= Render;
  if FAILED(Result) then Exit;

  // Keep track of the frame count
  begin
    fTime := DXUtil_Timer(TIMER_GETABSOLUTETIME);
    Inc(dwFrames);

    // Update the scene stats once per second
    if ((fTime - fLastTime) > 1.0) then
    begin
      m_fFPS    := dwFrames / (fTime - fLastTime);
      fLastTime := fTime;
      dwFrames  := 0;

      // Get adapter's current mode so we can report
      // bit depth (back buffer depth may be unknown)
      m_pD3D.GetAdapterDisplayMode(m_dwAdapter, mode);

      if (mode.Format = D3DFMT_X8R8G8B8) then d1:= 32 else d1:= 16;
      StrFmt(m_strFrameStats, '%.02f fps (%dx%dx%d)',
        [m_fFPS, m_d3dsdBackBuffer.Width, m_d3dsdBackBuffer.Height, d1]);

      pAdapterInfo := @m_Adapters[m_dwAdapter];
      pDeviceInfo  := @pAdapterInfo^.devices[pAdapterInfo^.dwCurrentDevice];
      pModeInfo    := @pDeviceInfo^.modes[pDeviceInfo^.dwCurrentMode];
      if m_bUseDepthBuffer then
      begin
        case pModeInfo^.DepthStencilFormat of
          D3DFMT_D16:     strcat(m_strFrameStats, ' (D16)');
          D3DFMT_D15S1:   strcat(m_strFrameStats, ' (D15S1)');
          D3DFMT_D24X8:   strcat(m_strFrameStats, ' (D24X8)');
          D3DFMT_D24S8:   strcat(m_strFrameStats, ' (D24S8)');
          D3DFMT_D24X4S4: strcat(m_strFrameStats, ' (D24X4S4)');
          D3DFMT_D32:     strcat(m_strFrameStats, ' (D32)');
        end;
      end;

      if m_bWindowed then
        MultiSampleType := pDeviceInfo.MultiSampleTypeWindowed
      else
        MultiSampleType := pDeviceInfo.MultiSampleTypeFullscreen;

      case MultiSampleType of
        D3DMULTISAMPLE_2_SAMPLES:  lstrcat(m_strFrameStats, ' (2x Multisample)');
        D3DMULTISAMPLE_3_SAMPLES:  lstrcat(m_strFrameStats, ' (3x Multisample)');
        D3DMULTISAMPLE_4_SAMPLES:  lstrcat(m_strFrameStats, ' (4x Multisample)');
        D3DMULTISAMPLE_5_SAMPLES:  lstrcat(m_strFrameStats, ' (5x Multisample)');
        D3DMULTISAMPLE_6_SAMPLES:  lstrcat(m_strFrameStats, ' (6x Multisample)');
        D3DMULTISAMPLE_7_SAMPLES:  lstrcat(m_strFrameStats, ' (7x Multisample)');
        D3DMULTISAMPLE_8_SAMPLES:  lstrcat(m_strFrameStats, ' (8x Multisample)');
        D3DMULTISAMPLE_9_SAMPLES:  lstrcat(m_strFrameStats, ' (9x Multisample)');
        D3DMULTISAMPLE_10_SAMPLES: lstrcat(m_strFrameStats, ' (10x Multisample)');
        D3DMULTISAMPLE_11_SAMPLES: lstrcat(m_strFrameStats, ' (11x Multisample)');
        D3DMULTISAMPLE_12_SAMPLES: lstrcat(m_strFrameStats, ' (12x Multisample)');
        D3DMULTISAMPLE_13_SAMPLES: lstrcat(m_strFrameStats, ' (13x Multisample)');
        D3DMULTISAMPLE_14_SAMPLES: lstrcat(m_strFrameStats, ' (14x Multisample)');
        D3DMULTISAMPLE_15_SAMPLES: lstrcat(m_strFrameStats, ' (15x Multisample)');
        D3DMULTISAMPLE_16_SAMPLES: lstrcat(m_strFrameStats, ' (16x Multisample)');
      end;
    end;
  end;

  // Show the frame on the primary surface.
  m_pd3dDevice.Present(nil, nil, 0, nil);

  Result:= S_OK;
end;



//-----------------------------------------------------------------------------
// Name: Cleanup3DEnvironment()
// Desc: Cleanup scene objects
//-----------------------------------------------------------------------------
procedure CD3DApplication.Cleanup3DEnvironment;
begin
  m_bActive := False;
  m_bReady  := False;

  if (m_pd3dDevice <> nil) then
  begin
    InvalidateDeviceObjects;
    DeleteDeviceObjects;

    SAFE_RELEASE(m_pd3dDevice);
    SAFE_RELEASE(m_pD3D);
  end;

  FinalCleanup;
end;


//-----------------------------------------------------------------------------
// Name: DisplayErrorMsg()
// Desc: Displays error messages in a message box
//-----------------------------------------------------------------------------
function CD3DApplication.DisplayErrorMsg(hr: HRESULT; dwType: DWORD): HRESULT;
var
  strMsg: array[0..511] of Char;
begin
  case hr of
    D3DAPPERR_NODIRECT3D:
        StrCopy(strMsg, 'Could not initialize Direct3D. You may'#10 +
                        'want to check that the latest version of'#10 +
                        'DirectX is correctly installed on your'#10 +
                        'system.  Also make sure that this program'#10 +
                        'was compiled with header files that match'#10 +
                        'the installed DirectX DLLs.');

    D3DAPPERR_NOCOMPATIBLEDEVICES:
        StrCopy(strMsg, 'Could not find any compatible Direct3D'#10'devices.');

    D3DAPPERR_NOWINDOWABLEDEVICES:
        StrCopy(strMsg, 'This application cannot run in a desktop'#10 +
                        'window with the current display settings.'#10 +
                        'Please change your desktop settings to a'#10 +
                        '16- or 32-bit display mode and re-run this'#10 +
                        'sample.');

    D3DAPPERR_NOHARDWAREDEVICE:
        StrCopy(strMsg, 'No hardware-accelerated Direct3D devices'#10 +
                        'were found.');

    D3DAPPERR_HALNOTCOMPATIBLE:
        StrCopy(strMsg, 'This application requires functionality that is'#10 +
                        'not available on your Direct3D hardware'#10 +
                        'accelerator.');

    D3DAPPERR_NOWINDOWEDHAL:
        StrCopy(strMsg, 'Your Direct3D hardware accelerator cannot'#10 +
                        'render into a window.'#10 +
                        'Press F2 while the app is running to see a'#10 +
                        'list of available devices and modes.');

    D3DAPPERR_NODESKTOPHAL:
        StrCopy(strMsg, 'Your Direct3D hardware accelerator cannot'#10 +
                        'render into a window with the current'#10 +
                        'desktop display settings.'#10 +
                        'Press F2 while the app is running to see a'#10 +
                        'list of available devices and modes.');

    D3DAPPERR_NOHALTHISMODE:
        StrCopy(strMsg, 'This application requires functionality that is'#10 +
                        'not available on your Direct3D hardware'#10 +
                        'accelerator with the current desktop display'#10 +
                        'settings.'#10 +
                        'Press F2 while the app is running to see a'#10 +
                        'list of available devices and modes.');

    D3DAPPERR_MEDIANOTFOUND:
        StrCopy(strMsg, 'Could not load required media.');

    D3DAPPERR_RESIZEFAILED:
        StrCopy(strMsg, 'Could not reset the Direct3D device.');

    D3DAPPERR_NONZEROREFCOUNT:
        StrCopy(strMsg, 'A D3D object has a non-zero reference'#10 +
                        'count (meaning things were not properly'#10 +
                        'cleaned up).');

    D3DAPPERR_NULLREFDEVICE:
        StrCopy(strMsg, 'Warning: Nothing will be rendered.'#10 +
                        'The reference rendering device was selected, but your'#10 +
                        'computer only has a reduced-functionality reference device'#10 +
                        'installed.  Install the DirectX SDK to get the full'#10 +
                        'reference device.'#10);

    E_OUTOFMEMORY:
        StrCopy(strMsg, 'Not enough memory.');

    D3DERR_OUTOFVIDEOMEMORY:
        StrCopy(strMsg, 'Not enough video memory.');

    else
        StrCopy(strMsg, 'Generic application error. Enable'#10 +
                        'debug output for detailed information.');
  end;

  if (MSGERR_APPMUSTEXIT = dwType) then
  begin
    StrCat(strMsg, #10#10'This application will now exit.');
    MessageBox(0, strMsg, m_strWindowTitle, MB_ICONERROR or MB_OK);

    // Close the window, which shuts down the app
    if (m_hWnd <> 0) then
      SendMessage(m_hWnd, WM_CLOSE, 0, 0);
  end else
  begin
    if (MSGWARN_SWITCHEDTOREF = dwType) then
      StrCat(strMsg, #10#10'Switching to the reference rasterizer,'#10 +
                     'a software device that implements the entire'#10 +
                     'Direct3D feature set, but runs very slowly.');
    MessageBox(0, strMsg, m_strWindowTitle, MB_ICONWARNING or MB_OK);
  end;

  Result:= hr;
end;

end.

