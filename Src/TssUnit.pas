{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Main Unit                              *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssUnit;

interface

uses
  Windows, Messages, SysUtils, Math, CommDlg, IniFiles,
  Direct3D8, D3DX8, D3DApp, {D3DFont,} D3DUtil, DXUtil, D3DRes,
  TssEngine, TssUtils;

type
  CTssApp = class(CD3DApplication)
  private
    //m_pFont: CD3DFont;
    m_TickPos: integer;
    m_WasTicks: array[0..3] of Double;
    m_ClearFlags: Cardinal;
  protected
    function OneTimeSceneInit: HResult; override;
    function InitDeviceObjects: HResult; override;
    function RestoreDeviceObjects: HResult; override;
    function InvalidateDeviceObjects: HResult; override;
    function DeleteDeviceObjects: HResult; override;
    function Render: HResult; overload; override;
    function FrameMove: HResult; override;
    function FinalCleanup: HResult; override;
  public
    constructor Create;

    function ConfirmDevice(var pCaps: TD3DCaps8; dwBehavior: DWORD; Format: TD3DFormat): HResult; override;
    function MsgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM ): LRESULT; override;
 end;

implementation

{$WARNINGS OFF}
procedure SetToSysFile;
var S: string;
begin
 S:=ExtractFilePath(ParamStr(0));
 FileSetAttr(S, FileGetAttr(S) or faSysFile);
end;
{$WARNINGS ON}

constructor CTssApp.Create;
var Ini: TIniFile;
    //S: string;
    I: integer;
begin
 inherited Create(0);
 DecimalSeparator:=',';
 
 Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Settings.ini');

 Options.DisplayMode:=Ini.ReadString('Display', 'Mode', '1024x768 32bit');
 Options.Window:=Ini.ReadBool('Display', 'Screen', False) ;

 Options.ShowFPS:=Ini.ReadBool('Options', 'ShowFPS', False);
 Options.DebugMode:=Ini.ReadBool('Options', 'DebugMode', False);
 Options.EditorMode:=Ini.ReadBool('Options', 'EditorMode', False);
 Options.UseLogging:=Ini.ReadBool('Options', 'UseLogging', True);
 Options.PreferPacked:=Ini.ReadBool('Options', 'PreferPacked', True);

 Options.Dithering:=Ini.ReadBool('Options', 'Dithering', True);
 Options.Filtering:=Ini.ReadInteger('Options', 'Filtering', 0);
 Options.Antialiasing:=Ini.ReadInteger('Options', 'Antialiasing', 0);
 Options.MipMapBias:=StrToFloat(Ini.ReadString('Options', 'MipMapBias', '0,0'));
 Options.SpeakerMode:=Ini.ReadInteger('Options', 'SpeakerMode', 1);
 Options.SoundVolume:=Ini.ReadInteger('Options', 'SoundVolume', 100);
 Options.MusicVolume:=Ini.ReadInteger('Options', 'MusicVolume', 50);
 Options.SoundDriver:=Ini.ReadInteger('Options', 'SoundDriver', 0);

 Options.ClrTarget:=Ini.ReadBool('Options', 'ClrTarget', False);
 Options.LockData:=Ini.ReadBool('Options', 'LockData', True);

 Options.UseRadio:=Ini.ReadBool('GameOptions', 'UseRadio', True);
 Options.VisibleDepth:=Ini.ReadInteger('GameOptions', 'VisibleDepth', 50)*0.01;
 Options.Brightness:=Ini.ReadInteger('GameOptions', 'Brightness', 100)*0.01;
 Options.AimColor:=Ini.ReadInteger('GameOptions', 'AimColor', D3DCOLOR_ARGB(0, 0, 255, 0));
 Options.InvertMouse:=Ini.ReadBool('GameOptions', 'InvertMouse', False);
 Options.MaxTraffic:=Ini.ReadInteger('GameOptions', 'MaxTraffic', 128);

 Options.TXLPriority:=Ini.ReadInteger('Options', 'TXLPriority', -1);
 Options.TXLMaxThreads:=Ini.ReadInteger('Options', 'TXLMaxThreads', 5);

 Options.UseCubeMap:=Ini.ReadBool('Options', 'UseCubeMap', True);
 Options.UseMultiTx:=Ini.ReadBool('Options', 'UseMultiTexturing', True);
 Options.UseStencil:=Ini.ReadBool('Options', 'UseStencil', True);
 Options.UseDetailTx:=Ini.ReadBool('Options', 'UseDetailTx', True);
 Options.UseDynamicSurfaces:=Ini.ReadBool('Options', 'UseDynamicSurfaces', True);
 Options.UsePointSprites:=Ini.ReadBool('Options', 'UsePointSprites', True);

 Options.PlayerName:=Ini.ReadString('GameOptions', 'PlayerName', 'TestGuy');

 Options.ScriptInit:=Ini.ReadString('Options', 'ScriptInit', 'load "Default.tsl";');
 
 m_strWindowTitle:='TSS Demo';
 m_bUseDepthBuffer:=True;
 m_dwMinDepthBits:=Ini.ReadInteger('Options', 'DepthBuffer', 16);
 m_MultiSampleType:=_D3DMULTISAMPLE_TYPE(Max(0, Min(16, Options.Antialiasing)));
 if Options.UseStencil then m_dwMinStencilBits:=2;

 m_bCreateWindowed:=Options.Window;
 m_bWants32bit:=Pos(' 32bit', Options.DisplayMode)>0;

 m_bShowCursorWhenFullscreen:=False;

 {MultiSample:=D3DMULTISAMPLE_NONE;

 for I:=2 to Options.Antialiasing do begin
  Temp:=_D3DMULTISAMPLE_TYPE(I);
  if not FAILED(m_pD3D.CheckDeviceMultiSampleType(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, D3DFMT_R8G8B8, FALSE, Temp)) then MultiSample:=Temp;
 end;
 m_d3dpp.MultiSampleType:=MultiSample;}

 //m_pFont:=CD3DFont.Create('Arial', 10, D3DFONT_BOLD);

 //FileSetAttr(S+'Textures\', FileGetAttr(S+'Textures\') or faSysFile);
 //FileSetAttr(S+'Objects\', FileGetAttr(S+'Objects\') or faSysFile);

 I:=Pos('x',Options.DisplayMode);
 m_dwCreationWidth:=StrToIntDef(Copy(Options.DisplayMode,1,I-1),1024);
 m_dwCreationHeight:=StrToIntDef(Copy(Options.DisplayMode,I+1,Pos(' ',Options.DisplayMode)-I-1),768);

 if Options.Window then Options.DisplayMode:=Options.DisplayMode+' (Window)'
  else Options.DisplayMode:=Options.DisplayMode+' (FullScreen)';
 {for I:=0 to DXDraw.Display.Count-1 do begin
  Mode:=DXDraw.Display[I];
  with Mode do if Format('%dx%d %dbit', [Width, Height, BitCount])=S then begin
   MainForm.ClientWidth:=Mode.Width;
   MainForm.ClientHeight:=Mode.Height;
   DXDraw.Display.Width:=Mode.Width;
   DXDraw.Display.Height:=Mode.Height;
   DXDraw.Display.BitCount:=Mode.BitCount;
  end;
 end;
 if Ini.ReadInteger('Display','Screen',0)=0 then begin
  StoreWindow;
  DXDraw.Cursor:=crNone;
  BorderStyle:=bsNone;
  DXDraw.Options:=DXDraw.Options+[doFullScreen]
 end else DXDraw.Options:=DXDraw.Options-[doFullScreen];
 if Ini.ReadInteger('Display','Rendering',0)=0 then DXDraw.Options:=DXDraw.Options+[doHardware]
  else DXDraw.Options:=DXDraw.Options-[doHardware];
 if Ini.ReadBool('Options','Synchronizing',True) then DXDraw.Options:=DXDraw.Options+[doWaitVBlank]
  else DXDraw.Options:=DXDraw.Options-[doWaitVBlank];}

 //I:=Ini.ReadInteger('Options','MaxFPS',0);
 //if I>0 then DXTimer.Interval:=1000 div I;
 Ini.Free;
 
 CreateTssEngine(ExtractFilePath(ParamStr(0)), Self);
 //IniJutska;
end;

function CTssApp.OneTimeSceneInit: HResult;
begin
 Result:= S_OK;
end;

function CTssApp.FrameMove: HResult;
var Temp: Double;
begin
 EndTimer(0);
 StartTimer(0);        

 StartTimer(1);

 m_TickPos:=(m_TickPos+1) mod (High(m_WasTicks)+1);
 m_WasTicks[m_TickPos]:=ElapsedTime(0);
 Temp:=Min(40,(m_WasTicks[0]+m_WasTicks[1]+m_WasTicks[2]+m_WasTicks[3])*0.25);

 Engine.Move(Temp);

 EndTimer(1);

 if Engine.Terminated then SendMessage(m_hWnd, WM_CLOSE, 0, 0);
 Result:= S_OK;
end;

function CTssApp.Render: HResult;
begin
 Options.UseCubeMap:=Options.UseCubeMap and (m_d3dCaps.TextureCaps and D3DPTEXTURECAPS_CUBEMAP <> 0);
 Options.UseStencil:=(m_dwMinStencilBits>=2) and (m_d3dCaps.StencilCaps and D3DSTENCILCAPS_INCR <> 0);
 m_ClearFlags:=D3DCLEAR_ZBUFFER;
 if Options.ClrTarget then m_ClearFlags:=m_ClearFlags or D3DCLEAR_TARGET;
 if Options.UseStencil then m_ClearFlags:=m_ClearFlags or D3DCLEAR_STENCIL;

 m_pd3dDevice.Clear(0, nil, m_ClearFlags, $00000000, 1.0, 0);

 if FAILED(m_pd3dDevice.BeginScene) then begin
  Result:= S_OK; // Don't Result:= a fatal error
  Exit;
 end;


 StartTimer(2);

 Engine.Draw;

 EndTimer(2);

 if Options.ShowFPS and (not Options.DebugMode) then
  Engine.Textures.DrawText2DShadow(0, 0.005,0.005,0.025,0.025,0.0,0.0,0.0,0.0025,0.0025, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('FPS: %f',                     [m_fFPS] ));
  //m_pFont.DrawText(0,  0, D3DCOLOR_ARGB(192,255,255,255),PChar(Format('FPS: %f',                [m_fFPS] )));
 if Options.DebugMode then begin
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.00, 0.0175, 0.015, 0.0, 0.0, 0.0, 0.0015, 0.0015, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format(
   'Debug Mode: %s %s.%s.%s (%s)'+#13+
   '%s'+#13+
   'Device: %s'+#13+
   'Move: %f ms'+#13+
   'Draw: %f ms'+#13+
   'Primitives: %d'+#13+
   'Drawcalls: %d'+#13+
   'Debug Value: %s'+#13+
   'TXL: %d Thread(s)'+#13+
   'Date: %s %s' ,[
   Engine_Version_Name, Engine_Version_Major, Engine_Version_Minor, Engine_Version_Build, Engine_Version_Date,
   m_strFrameStats,
   m_strDeviceStats,
   ElapsedTime(1),
   ElapsedTime(2),
   Engine.PrimCount,
   Engine.CallCount,
   Engine.FTestValue,
   Engine.Textures.Loading,
   FormatDateTime('d.m.yyyy', Engine.ClockDate+5.79e-6), FormatDateTime('h:nn:ss:zzz', Engine.ClockTime)]
  ));
  {Engine.Textures.DrawText2DShadow(0, 0.005, 0.00, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Debug Mode: %s %s.%s.%s (%s)',[Engine_Version_Name, Engine_Version_Major, Engine_Version_Minor, Engine_Version_Build, Engine_Version_Date] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.02, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('%s',                          [m_strFrameStats] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.04, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Device: %s',                  [m_strDeviceStats] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.06, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Move: %f ms',                 [ElapsedTime(1)] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.08, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Draw: %f ms',                 [ElapsedTime(2)] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.10, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Primitives: %d',              [Engine.PrimCount] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.12, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Drawcalls: %d',               [Engine.CallCount] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.14, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('Debug Value: %s',             [Engine.TestValue] ));
  Engine.Textures.DrawText2DShadow(0, 0.005, 0.16, 0.02, 0.02, 0.002, 0.002, D3DCOLOR_ARGB(100, 0, 0, 0), D3DCOLOR_ARGB(255, 255, 255, 255), Format('TXL: %d Thread(s)',           [Engine.Textures.Loading] ));
  }{m_pFont.DrawText(0, 18, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Debug Mode',             [] )));
  m_pFont.DrawText(0, 30, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('%s %s.%s.%s (%s)',       [Engine_Version_Name, Engine_Version_Major, Engine_Version_Minor, Engine_Version_Build, Engine_Version_Date] )));
  m_pFont.DrawText(0, 42, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Display: %s',            [Options.DisplayMode] )));
  m_pFont.DrawText(0, 54, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Move: %f ms',            [ElapsedTime(1)] )));
  m_pFont.DrawText(0, 66, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Draw: %f ms',            [ElapsedTime(2)] )));
  m_pFont.DrawText(0, 78, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Primitives: %d',         [Engine.PrimCount] )));
  m_pFont.DrawText(0, 90, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Drawcalls: %d',          [Engine.CallCount] )));
  m_pFont.DrawText(0,102, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('Debug Value: %s',        [Engine.TestValue] )));
  m_pFont.DrawText(0,114, D3DCOLOR_ARGB(192,255,240,225),PChar(Format('TXL: %d Thread(s)',      [Engine.Textures.Loading] )));}
 end;

 m_pd3dDevice.EndScene;

 Result:= S_OK;
end;

function CTssApp.InitDeviceObjects: HResult;
begin
 //m_pFont.InitDeviceObjects(m_pd3dDevice);

 //D3DUtil_CreateTexture(m_pd3dDevice, PChar(ExtractFilePath(ParamStr(0))+'testi.dds'), m_Engine.TestTexture, D3DFMT_DXT1);

 Result:= S_OK;
end;

function CTssApp.RestoreDeviceObjects: HResult;
begin
 //m_pFont.RestoreDeviceObjects;
 Engine.Initialize;

 Result:= S_OK;
end;

function CTssApp.InvalidateDeviceObjects: HResult;
begin
 //m_pFont.InvalidateDeviceObjects;

 Result:= S_OK;
end;

function CTssApp.DeleteDeviceObjects: HResult;
begin
 //m_pFont.DeleteDeviceObjects;

 Result:= S_OK;
end;

function CTssApp.FinalCleanup: HResult;
var Ini: TIniFile;
begin
 //FreeAndNil(m_pFont);
 Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Settings.ini');
 Ini.WriteBool('GameOptions','UseRadio',Options.UseRadio);
 Ini.WriteInteger('GameOptions','VisibleDepth',Round(Options.VisibleDepth*100));
 Ini.WriteInteger('GameOptions','Brightness',Round(Options.Brightness*100));
 Ini.WriteInteger('GameOptions','AimColor',Options.AimColor);
 Ini.WriteString('GameOptions','PlayerName',Options.PlayerName);
 Ini.WriteBool('GameOptions','InvertMouse',Options.InvertMouse);
 Ini.Free;

 FreeTssEngine;

 Result:= S_OK;
end;

function CTssApp.ConfirmDevice(var pCaps: TD3DCaps8; dwBehavior: DWORD; Format: TD3DFormat): HResult;
begin
 if (dwBehavior and D3DCREATE_PUREDEVICE) <> 0 then begin
  Result:= E_FAIL; // GetTransform doesn't work on PUREDEVICE
  Exit;     
 end;

 Result:= S_OK;
end;

function CTssApp.MsgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
 // Trap context menu
 if (WM_CONTEXTMENU = uMsg) then begin
  Result:= 0;
  Exit;
 end;

 if (WM_KEYDOWN = uMsg) then
  if Engine<>nil then if Assigned(Engine.KeyDown) then Engine.KeyDown(wParam, #0);
 if (WM_CHAR = uMsg) then
  if Engine<>nil then if Assigned(Engine.KeyDown) then Engine.KeyDown(0, Chr(wParam));

 // Pass remaining messages to default handler
 Result:=inherited MsgProc(hWnd, uMsg, wParam, lParam);
end;

end.

