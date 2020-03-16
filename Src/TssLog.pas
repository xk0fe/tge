{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Log Unit                               *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssLog;

interface

uses
  Windows, Messages, SysUtils, Classes;

type
  TLogItem = string[255];
  TTssLogger = class(TObject)
  private
    LogFile: TFileStream;
  public
    Enabled: Boolean;
    constructor Create(Enabled: Boolean);
    destructor Destroy; override;
    procedure Log(S: TLogItem);
  end;

implementation

uses
  TssEngine;

{var
  DebuggerFound: Boolean;
  DebugWindow: hWnd;

function EnumWindowsCallback(Handle: HWND; Param: LPARAM): Boolean; stdcall;
var ClassName: array[0..30] of Char;
begin
 GetClassName(Handle, ClassName, 30);
 Result:=StrIComp(ClassName, 'TTssDebugWnd') <> 0;
 if not Result then begin
  DebugWindow:=Handle;
  DebuggerFound:=True;
 end;
end;}

constructor TTssLogger.Create(Enabled: Boolean);
begin
 inherited Create;
 Self.Enabled:=Enabled;
 if Enabled then LogFile:=TFileStream.Create(Engine.FilePath+'DebugLog.txt', fmCreate);
end;

destructor TTssLogger.Destroy;
begin
 LogFile.Free;
 inherited;
end;

procedure TTssLogger.Log(S: TLogItem);
var P: Pointer;
begin
 S:=S+#13#10;
 P:=Pointer(Integer(@S)+1);
 if Enabled then LogFile.Write(P^, Length(S));
 {Windows.GlobalLock()
 if Enabled and DebuggerFound then begin
  LogPos^:=(LogPos^+1) mod LogBufferSize;
  with LogBuffer[LogPos^] do begin
   LogId:=Id;
   LogInfo:=Info;
   QueryPerformanceCounter(LogTime);
  end;
 end;}
  //PostMessage(DebugWindow, WM_TSSLOG, Id, Info);
end;

end.
 