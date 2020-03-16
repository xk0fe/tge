unit DXUtil;
//-----------------------------------------------------------------------------
// File: DXUtil.h
//
// Desc: Helper functions and typing shortcuts for DirectX programming.
//
// Copyright (c) 1997-2001 Microsoft Corporation. All rights reserved
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
  Windows, MMSystem;

//-----------------------------------------------------------------------------
// Miscellaneous helper functions
//-----------------------------------------------------------------------------
//#define SAFE_DELETE(p)       { if(p) { delete (p);     (p)=NULL; } }
//#define SAFE_DELETE_ARRAY(p) { if(p) { delete[] (p);   (p)=NULL; } }
//#define SAFE_RELEASE(p)      { if(p) { (p)->Release(); (p)=NULL; } }

procedure SAFE_RELEASE(var i);
procedure SAFE_DELETE(var Obj);

//-----------------------------------------------------------------------------
// Name: DXUtil_GetDXSDKMediaPath() and DXUtil_FindMediaFile()
// Desc: Returns the DirectX SDK path, as stored in the system registry
//       during the SDK install.
//-----------------------------------------------------------------------------
function DXUtil_GetDXSDKMediaPath: PChar;
function DXUtil_FindMediaFile(strPath: PChar; strFilename: PChar): HRESULT;



//-----------------------------------------------------------------------------
// Name: DXUtil_Read*RegKey() and DXUtil_Write*RegKey()
// Desc: Helper functions to read/write a string registry key
//-----------------------------------------------------------------------------
function DXUtil_WriteStringRegKey(hKey_: HKEY; strRegName: PChar; strValue: PChar): HRESULT;
function DXUtil_WriteIntRegKey (hKey_: HKEY; strRegName: PChar; dwValue: DWORD): HRESULT;
function DXUtil_WriteGuidRegKey(hKey_: HKEY; strRegName: PChar; guidValue: TGUID): HRESULT;
function DXUtil_WriteBoolRegKey(hKey_: HKEY; strRegName: PChar; bValue: BOOL): HRESULT;

function DXUtil_ReadStringRegKey(hKey_: HKEY; strRegName: PChar; var strValue: PChar; dwLength: DWORD; strDefault: PChar): HRESULT;
function DXUtil_ReadIntRegKey (hKey_: HKEY; strRegName: PChar; var pdwValue: DWORD; dwDefault: DWORD): HRESULT;
function DXUtil_ReadGuidRegKey(hKey_: HKEY; strRegName: PChar; var pGuidValue: TGUID; guidDefault: TGUID): HRESULT;
function DXUtil_ReadBoolRegKey(hKey_: HKEY; strRegName: PChar; var pbValue: BOOL; bDefault: BOOL): HRESULT;



//-----------------------------------------------------------------------------
// Name: DXUtil_Timer()
// Desc: Performs timer opertations. Use the following commands:
//          TIMER_RESET           - to reset the timer
//          TIMER_START           - to start the timer
//          TIMER_STOP            - to stop (or pause) the timer
//          TIMER_ADVANCE         - to advance the timer by 0.1 seconds
//          TIMER_GETABSOLUTETIME - to get the absolute system time
//          TIMER_GETAPPTIME      - to get the current time
//          TIMER_GETELAPSEDTIME  - to get the time that elapsed between
//                                  TIMER_GETELAPSEDTIME calls
//-----------------------------------------------------------------------------
type
  TIMER_COMMAND = DWORD;

const
  TIMER_RESET           = 0;
  TIMER_START           = 1;
  TIMER_STOP            = 2;
  TIMER_ADVANCE         = 3;
  TIMER_GETABSOLUTETIME = 4;
  TIMER_GETAPPTIME      = 5;
  TIMER_GETELAPSEDTIME  = 6;

function DXUtil_Timer(command: TIMER_COMMAND): Single; stdcall;


//-----------------------------------------------------------------------------
// UNICODE support for converting between CHAR, TCHAR, and WCHAR strings
//-----------------------------------------------------------------------------
//TODO!!

procedure DXUtil_ConvertAnsiStringToWide(wstrDestination: PWideChar;
  const strSource: PAnsiChar; cchDestChar: Integer = -1);
procedure DXUtil_ConvertWideStringToAnsi(strDestination: PAnsiChar;
  const wstrSource: PWideChar; cchDestChar: Integer = -1);
procedure DXUtil_ConvertGenericStringToAnsi(strDestination: PAnsiChar;
  const tstrSource: PChar; cchDestChar: Integer = -1);
procedure DXUtil_ConvertGenericStringToWide(wstrDestination: PWideChar;
  const tstrSource: PChar; cchDestChar: Integer = -1);

procedure DXUtil_ConvertAnsiStringToGeneric(tstrDestination: PChar;
  const strSource: PAnsiChar; cchDestChar: Integer = -1);
procedure DXUtil_ConvertWideStringToGeneric(tstrDestination: PChar;
  const wstrSource: PWideChar; cchDestChar: Integer = -1);



//-----------------------------------------------------------------------------
// GUID to String converting
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertGUIDToString(const pGuidIn: TGUID; out strOut: PChar);
// function DXUtil_ConvertStringToGUID(const strIn: PChar; out pGuidOut: TGUID): BOOL;




//-----------------------------------------------------------------------------
// Debug printing support
//-----------------------------------------------------------------------------
(*
VOID    DXUtil_Trace( TCHAR* strMsg, ... );
HRESULT _DbgOut( TCHAR*, DWORD, HRESULT, TCHAR* );

#if defined(DEBUG) | defined(_DEBUG)
    #define DXTRACE           DXUtil_Trace
#else
    #define DXTRACE           sizeof
#endif

#if defined(DEBUG) | defined(_DEBUG)
    #define DEBUG_MSG(str)    _DbgOut( __FILE__, (DWORD)__LINE__, 0, str )
#else
    #define DEBUG_MSG(str)    (0L)
#endif
*)

implementation

uses
  SysUtils;


procedure SAFE_RELEASE(var i);
begin
  if IUnknown(i) <> nil then IUnknown(i):= nil;
end;

procedure SAFE_DELETE(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;


//-----------------------------------------------------------------------------
// Name: DXUtil_GetDXSDKMediaPath()
// Desc: Returns the DirectX SDK media path
//-----------------------------------------------------------------------------
function DXUtil_GetDXSDKMediaPath: PChar;
const
  strNull: array[0..1] of Char = (#0,#0);
  strPath: array[0..MAX_PATH-1] of Char = #0;
var
  dwType,dwSize: DWORD;
  hKey_: HKEY;
  lResult: Integer;
begin
  dwSize := MAX_PATH;

  // Open the appropriate registry key
  lResult := RegOpenKeyEx(HKEY_LOCAL_MACHINE,
                          'Software\Microsoft\DirectX SDK',
                          0, KEY_READ, hKey_);
  if (ERROR_SUCCESS <> lResult) then
  begin
    Result:= strNull;
    Exit;
  end;

  lResult := RegQueryValueEx(hKey_, 'DX81SDK Samples Path', nil,
                             @dwType, PByte(@strPath), @dwSize);
  RegCloseKey(hKey_);

  if (ERROR_SUCCESS <> lResult) then
  begin
    Result:= strNull;
    Exit;
  end;

  StrCat(strPath, '\Media\');

  Result:= strPath;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_FindMediaFile()
// Desc: Returns a valid path to a DXSDK media file
//-----------------------------------------------------------------------------
function DXUtil_FindMediaFile(strPath: PChar; strFilename: PChar): HRESULT;
var
  file_: DWord;
  strFullPath: array [0..1023] of Char;
  strShortName: PChar;
  cchPath: DWord;
begin
  if (nil = strFilename) or (nil = strPath) then
  begin
    Result:= E_INVALIDARG;
    Exit;
  end;

  // Build full path name from strFileName (strShortName will be just the leaf filename)
  cchPath := GetFullPathName(strFilename, SizeOf(strFullPath) div SizeOf(Char),
                             strFullPath, strShortName);
  // if ((cchPath == 0) || (sizeof(strFullPath)/sizeof(TCHAR) <= cchPath))
  if ((cchPath = 0) or (SizeOf(strFullPath) div SizeOf(Char) <= cchPath)) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  // first try to find the filename given a full path
  file_:= CreateFile(strFullPath, GENERIC_READ, FILE_SHARE_READ, nil,
                     OPEN_EXISTING, 0, 0);
  if (INVALID_HANDLE_VALUE <> file_) then
  begin
    StrCopy(strPath, strFullPath);
    CloseHandle(file_);
    Result:= S_OK;
    Exit;
  end;

  // next try to find the filename in the current working directory (path stripped)
  file_:= CreateFile(strShortName, GENERIC_READ, FILE_SHARE_READ, nil,
                     OPEN_EXISTING, 0, 0);
  if (INVALID_HANDLE_VALUE <> file_) then
  begin
    StrCopy(strPath, strShortName);
    CloseHandle(file_);
    Result:= S_OK;
    Exit
  end;

  // last, check if the file exists in the media directory
  // _stprintf( strPath, _T(%s%s), DXUtil_GetDXSDKMediaPath, strShortName);
  StrFmt(strPath, '%s%s', [DXUtil_GetDXSDKMediaPath, strShortName]);

  file_:= CreateFile(strPath, GENERIC_READ, FILE_SHARE_READ, nil,
                     OPEN_EXISTING, 0, 0);
  if (INVALID_HANDLE_VALUE <> file_) then
  begin
    CloseHandle(file_);
    Result:= S_OK;
    Exit;
  end;

  // On failure, just return the file as the path
  StrCopy(strPath, strFilename);
  Result:= E_FAIL;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ReadStringRegKey()
// Desc: Helper function to read a registry key string
//-----------------------------------------------------------------------------
function DXUtil_ReadStringRegKey(hKey_: HKEY; strRegName: PChar;
  var strValue: PChar; dwLength: DWORD; strDefault: PChar): HRESULT;
var
  dwType: DWORD;
begin
  if (ERROR_SUCCESS <> RegQueryValueEx(hKey_, strRegName, nil, @dwType,
                                       PByte(strValue), @dwLength)) then
  begin
    StrCopy(strValue, strDefault);
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_WriteStringRegKey()
// Desc: Helper function to write a registry key string
//-----------------------------------------------------------------------------
function DXUtil_WriteStringRegKey(hKey_: HKEY; strRegName: PChar; strValue: PChar): HRESULT;
begin
  if (ERROR_SUCCESS <> RegSetValueEx(hKey_, strRegName, 0, REG_SZ,
                                     strValue,
                                     StrLen(strValue)+1)*sizeof(PChar)) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ReadIntRegKey()
// Desc: Helper function to read a registry key int
//-----------------------------------------------------------------------------
function DXUtil_ReadIntRegKey(hKey_: HKEY; strRegName: PChar; var pdwValue: DWORD; dwDefault: DWORD): HRESULT;
var
  dwType: DWORD;
  dwLength: DWORD;
begin
  dwLength := SizeOf(DWORD);

  if (ERROR_SUCCESS <> RegQueryValueEx(hKey_, strRegName, nil, @dwType,
                                       PByte(@pdwValue), @dwLength)) then
  begin
    pdwValue:= dwDefault;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_WriteIntRegKey()
// Desc: Helper function to write a registry key int
//-----------------------------------------------------------------------------
function DXUtil_WriteIntRegKey(hKey_: HKEY; strRegName: PChar; dwValue: DWORD): HRESULT;
begin
  if (ERROR_SUCCESS <> RegSetValueEx(hKey_, strRegName, 0, REG_DWORD,
                                     PByte(@dwValue), SizeOf(DWORD))) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ReadBoolRegKey()
// Desc: Helper function to read a registry key BOOL
//-----------------------------------------------------------------------------
function DXUtil_ReadBoolRegKey(hKey_: HKEY; strRegName: PChar; var pbValue: BOOL;
  bDefault: BOOL): HRESULT;
var
  dwType: DWORD;
  dwLength: DWORD;
begin
  dwLength := SizeOf(BOOL);

  if (ERROR_SUCCESS <> RegQueryValueEx(hKey_, strRegName, nil, @dwType,
                                       PByte(@pbValue), @dwLength)) then
  begin
    pbValue := bDefault;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_WriteBoolRegKey()
// Desc: Helper function to write a registry key BOOL
//-----------------------------------------------------------------------------
function DXUtil_WriteBoolRegKey(hKey_: HKEY; strRegName: PChar; bValue: BOOL): HRESULT;
begin
  if (ERROR_SUCCESS <> RegSetValueEx(hKey_, strRegName, 0, REG_DWORD,
                                     PByte(@bValue), sizeof(BOOL))) then
  begin
    Result:= E_FAIL;
    Exit;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ReadGuidRegKey()
// Desc: Helper function to read a registry key guid
//-----------------------------------------------------------------------------
function DXUtil_ReadGuidRegKey(hKey_: HKEY; strRegName: PChar;
  var pGuidValue: TGUID; guidDefault: TGUID): HRESULT;
var
  dwType: DWORD;
  dwLength: DWORD;
begin
  dwLength := SizeOf(TGUID);

  if (ERROR_SUCCESS <> RegQueryValueEx(hKey_, strRegName, nil, @dwType,
                                       PByte(@pGuidValue), @dwLength)) then
  begin
    pGuidValue := guidDefault;
  end;

  Result:= S_OK;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_WriteGuidRegKey()
// Desc: Helper function to write a registry key guid
//-----------------------------------------------------------------------------
function DXUtil_WriteGuidRegKey(hKey_: HKEY; strRegName: PChar; guidValue: TGUID): HRESULT;
begin
  if (ERROR_SUCCESS <> RegSetValueEx(hKey_, strRegName, 0, REG_BINARY,
                                     PByte(@guidValue), SizeOf(TGUID))) then
  begin
    Result:=E_FAIL;
    Exit;
  end;

  Result:= S_OK;
end;


//-----------------------------------------------------------------------------
// Name: DXUtil_Timer()
// Desc: Performs timer opertations. Use the following commands:
//          TIMER_RESET           - to reset the timer
//          TIMER_START           - to start the timer
//          TIMER_STOP            - to stop (or pause) the timer
//          TIMER_ADVANCE         - to advance the timer by 0.1 seconds
//          TIMER_GETABSOLUTETIME - to get the absolute system time
//          TIMER_GETAPPTIME      - to get the current time
//          TIMER_GETELAPSEDTIME  - to get the time that elapsed between
//                                  TIMER_GETELAPSEDTIME calls
//-----------------------------------------------------------------------------
function DXUtil_Timer(command: TIMER_COMMAND): Single; stdcall;
{$WRITEABLECONST ON}
const
  m_bTimerInitialized: BOOL   = FALSE;
  m_bUsingQPF: BOOL           = FALSE;
  m_bTimerStopped: BOOL       = TRUE;
  m_llQPFTicksPerSec: Int64   = 0;
  m_llStopTime: Int64         = 0;
  m_llLastElapsedTime: Int64  = 0;
  m_llBaseTime: Int64         = 0;
  m_fLastElapsedTime: Double  = 0.0;
  m_fBaseTime: Double         = 0.0;
  m_fStopTime: Double         = 0.0;
{$WRITEABLECONST OFF}
var
  qwTicksPerSec: Int64; // LARGE_INTEGER;
  qwTime: Int64; // LARGE_INTEGER;
  fTime: Double;
  fElapsedTime: Double;
  fAppTime: Double;
begin
  // Initialize the timer
  if (FALSE = m_bTimerInitialized) then
  begin
    m_bTimerInitialized := TRUE;

    // Use QueryPerformanceFrequency() to get frequency of timer.  If QPF is
    // not supported, we will timeGetTime() which returns milliseconds.

    m_bUsingQPF := QueryPerformanceFrequency(qwTicksPerSec);
    if (m_bUsingQPF) then
      m_llQPFTicksPerSec:= qwTicksPerSec{.QuadPart};
  end;

  if (m_bUsingQPF) then
  begin
    // Get either the current time or the stop time, depending
    // on whether we're stopped and what command was sent
    if (m_llStopTime <> 0) and (command <> TIMER_START) and (command <> TIMER_GETABSOLUTETIME) then
      qwTime{.QuadPart} := m_llStopTime
    else
      QueryPerformanceCounter(Int64(qwTime));

    // Return the elapsed time
    if (command = TIMER_GETELAPSEDTIME) then
    begin
      fElapsedTime:= (qwTime{.QuadPart} - m_llLastElapsedTime) /  m_llQPFTicksPerSec;
      m_llLastElapsedTime:= qwTime{.QuadPart};
      Result:= fElapsedTime;
      Exit;
    end;

    // Return the current time
    if (command = TIMER_GETAPPTIME) then
    begin
      fAppTime:= (qwTime{.QuadPart} - m_llBaseTime) /  m_llQPFTicksPerSec;
      Result:= fAppTime;
      Exit;
    end;

    // Reset the timer
    if (command = TIMER_RESET) then
    begin
      m_llBaseTime        := qwTime{.QuadPart};
      m_llLastElapsedTime := qwTime{.QuadPart};
      m_llStopTime        := 0;
      m_bTimerStopped     := FALSE;
      Result:= 0.0;
      Exit;
    end;

    // Start the timer
    if (command = TIMER_START) then
    begin
      if m_bTimerStopped then
        m_llBaseTime:= m_llBaseTime + (qwTime{.QuadPart} - m_llStopTime);
      m_bTimerStopped := FALSE;
      m_llStopTime:= 0;
      m_llLastElapsedTime:= qwTime{.QuadPart};
      Result:=0.0;
      Exit;
    end;

    // Stop the timer
    if (command = TIMER_STOP) then
    begin
      m_llStopTime:= qwTime{.QuadPart};
      m_llLastElapsedTime:= qwTime{.QuadPart};
      m_bTimerStopped := TRUE;
      Result:= 0.0;
      Exit;
    end;

    // Advance the timer by 1/10th second
    if (command = TIMER_ADVANCE) then
    begin
      m_llStopTime:= Trunc(m_llStopTime + m_llQPFTicksPerSec/10);
      Result:= 0.0;
      Exit;
    end;

    if (command = TIMER_GETABSOLUTETIME) then
    begin
      fTime:= qwTime{.QuadPart} / m_llQPFTicksPerSec;
      Result:= fTime;
      Exit;
    end;

    Result:= -1.0; // Invalid command specified
    Exit;
  end else
  begin
    // Get the time using timeGetTime()

    // Get either the current time or the stop time, depending
    // on whether we're stopped and what command was sent
    if (m_fStopTime <> 0.0) and (command <> TIMER_START) and (command <> TIMER_GETABSOLUTETIME) then
      fTime:= m_fStopTime
    else
      fTime:= timeGetTime * 0.001;

    // Return the elapsed time
    if (command = TIMER_GETELAPSEDTIME) then
    begin
      fElapsedTime:= (fTime - m_fLastElapsedTime);
      m_fLastElapsedTime:= fTime;
      Result:= fElapsedTime;
      Exit;
    end;

    // Return the current time
    if (command = TIMER_GETAPPTIME) then
    begin
      Result:= (fTime - m_fBaseTime);
      Exit;
    end;

    // Reset the timer
    if (command = TIMER_RESET) then
    begin
      m_fBaseTime         := fTime;
      m_fLastElapsedTime  := fTime;
      m_fStopTime         := 0;
      m_bTimerStopped     := FALSE;
      Result:= 0.0;
      Exit;
    end;

    // Start the timer
    if (command = TIMER_START) then
    begin
      if m_bTimerStopped then
        m_fBaseTime := m_fBaseTime + (fTime - m_fStopTime);
      m_bTimerStopped := FALSE;
      m_fStopTime := 0.0;
      m_fLastElapsedTime:= fTime;
      Result:= 0.0;
      Exit;
    end;

    // Stop the timer
    if (command = TIMER_STOP) then
    begin
      m_fStopTime:= fTime;
      m_fLastElapsedTime := fTime;
      m_bTimerStopped := TRUE;
      Result:= 0.0;
      Exit;
    end;

    // Advance the timer by 1/10th second
    if (command = TIMER_ADVANCE) then
    begin
      m_fStopTime:= m_fStopTime + 0.1;
      Result:= 0.0;
      Exit;
    end;

    if (command = TIMER_GETABSOLUTETIME) then
    begin
      Result:= fTime;
      Exit;
    end;

    Result:= -1.0; // Invalid command specified
  end;
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertAnsiStringToWide()
// Desc: This is a UNICODE conversion utility to convert a CHAR string into a
//       WCHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertAnsiStringToWide(wstrDestination: PWideChar;
  const strSource: PAnsiChar; cchDestChar: Integer);
begin
  if (wstrDestination = nil) or (strSource = nil) then Exit;

  if (cchDestChar = -1) then
    cchDestChar:= StrLen(strSource) + 1;

  MultiByteToWideChar(CP_ACP, 0, strSource, -1, wstrDestination, cchDestChar - 1);

  wstrDestination[cchDestChar-1]:= #0;
end;

function WStrLen(Str: PWideChar): Integer;
begin
  Result := 0;
  while Str[Result] <> #0 do Inc(Result);
end;

//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertWideStringToAnsi()
// Desc: This is a UNICODE conversion utility to convert a WCHAR string into a
//       CHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertWideStringToAnsi(strDestination: PAnsiChar;
  const wstrSource: PWideChar; cchDestChar: Integer = -1);
begin
  if (strDestination = nil) or (wstrSource = nil) then Exit;

  if (cchDestChar = -1) then
    cchDestChar := WStrLen(wstrSource) + 1;

  WideCharToMultiByte(CP_ACP, 0, wstrSource, -1, strDestination,
                      cchDestChar-1, nil, nil);

  strDestination[cchDestChar-1] := #0;
end;


//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertGenericStringToAnsi()
// Desc: This is a UNICODE conversion utility to convert a TCHAR string into a
//       CHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertGenericStringToAnsi(strDestination: PAnsiChar;
  const tstrSource: PChar; cchDestChar: Integer);
begin
  if (strDestination = nil) or (tstrSource = nil) or (cchDestChar = 0) then Exit;

{$IFDEF UNICODE}
  DXUtil_ConvertWideStringToAnsi(strDestination, tstrSource, cchDestChar);
{$ELSE}
  if (cchDestChar = -1) then
  begin
    StrCopy(strDestination, tstrSource);
  end else
  begin
    StrLCopy(strDestination, tstrSource, cchDestChar);
    strDestination[cchDestChar-1]:= #0;
  end;
{$ENDIF}
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertGenericStringToWide()
// Desc: This is a UNICODE conversion utility to convert a TCHAR string into a
//       WCHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertGenericStringToWide(wstrDestination: PWideChar;
  const tstrSource: PChar; cchDestChar: Integer);
begin
  if (wstrDestination = nil) or (tstrSource = nil) or (cchDestChar = 0) then Exit;

{$IFDEF UNICODE}
  if (cchDestChar = -1) then
  begin
    StrCopy(wstrDestination, tstrSource);
  end else
  begin
    StrLCopy(wstrDestination, tstrSource, cchDestChar);
    wstrDestination[cchDestChar-1]:= #0; // This should be WORD
  end;
{$ELSE}
  DXUtil_ConvertAnsiStringToWide(wstrDestination, tstrSource, cchDestChar);
{$ENDIF}
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertAnsiStringToGeneric()
// Desc: This is a UNICODE conversion utility to convert a CHAR string into a
//       TCHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertAnsiStringToGeneric(tstrDestination: PChar;
  const strSource: PAnsiChar; cchDestChar: Integer);
begin
  if (tstrDestination = nil) or (strSource = nil) or (cchDestChar = 0) then Exit;

{$IFDEF UNICODE}
  DXUtil_ConvertAnsiStringToWide(tstrDestination, strSource, cchDestChar);
{$ELSE}
  if (cchDestChar = -1) then
  begin
    StrCopy(tstrDestination, strSource);
  end else
  begin
    StrLCopy(tstrDestination, strSource, cchDestChar);
    tstrDestination[cchDestChar-1]:= #0;
  end;
{$ENDIF}
end;




//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertAnsiStringToGeneric()
// Desc: This is a UNICODE conversion utility to convert a WCHAR string into a
//       TCHAR string. cchDestChar defaults -1 which means it
//       assumes strDest is large enough to store strSource
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertWideStringToGeneric(tstrDestination: PChar;
  const wstrSource: PWideChar; cchDestChar: Integer = -1);
begin
  if (tstrDestination = nil) or (wstrSource = nil) then Exit;

{$IFDEF UNICODE}
  if (cchDestChar = -1) then
    StrCopy(tstrDestination, wstrSource);
  else
    StrLCopy(tstrDestination, wstrSource, cchDestChar);
{$ELSE}
  DXUtil_ConvertWideStringToAnsi(tstrDestination, wstrSource, cchDestChar);
{$ENDIF}
end;



(*
//-----------------------------------------------------------------------------
// Name: _DbgOut()
// Desc: Outputs a message to the debug stream
//-----------------------------------------------------------------------------
HRESULT _DbgOut( TCHAR* strFile, DWORD dwLine, HRESULT hr, TCHAR* strMsg )
{
    TCHAR buffer[256];
    wsprintf( buffer, _T("%s(%ld): "), strFile, dwLine );
    OutputDebugString( buffer );
    OutputDebugString( strMsg );

    if( hr )
    {
        wsprintf( buffer, _T("(hr=%08lx)\n"), hr );
        OutputDebugString( buffer );
    }

    OutputDebugString( _T("\n") );

    return hr;
}




//-----------------------------------------------------------------------------
// Name: DXUtil_Trace()
// Desc: Outputs to the debug stream a formatted string with a variable-
//       argument list.
//-----------------------------------------------------------------------------
VOID DXUtil_Trace( TCHAR* strMsg, ... )
{
#if defined(DEBUG) | defined(_DEBUG)
    TCHAR strBuffer[512];

    va_list args;
    va_start(args, strMsg);
    _vsntprintf( strBuffer, 512, strMsg, args );
    va_end(args);

    OutputDebugString( strBuffer );
#endif
}

*)

(*
//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertStringToGUID()
// Desc: Converts a string to a GUID
//-----------------------------------------------------------------------------
function DXUtil_ConvertStringToGUID(const strIn: PChar; out pGuidOut: TGUID): BOOL;
var
  aiTmp: array[0..9] of LongWord;
begin

  if( _stscanf( strIn, TEXT("{%8X-%4X-%4X-%2X%2X-%2X%2X%2X%2X%2X%2X}"),
                  &pGuidOut->Data1,
                  &aiTmp[0], &aiTmp[1],
                  &aiTmp[2], &aiTmp[3],
                  &aiTmp[4], &aiTmp[5],
                  &aiTmp[6], &aiTmp[7],
                  &aiTmp[8], &aiTmp[9] ) != 11 )
  begin
    ZeroMemory( pGuidOut, SizeOf(GUID));
    Result:= FALSE;
  end else
  begin
      pGuidOut.Data2       := (USHORT) aiTmp[0];
      pGuidOut.Data3       := (USHORT) aiTmp[1];
      pGuidOut.Data4[0]    := (BYTE) aiTmp[2];
      pGuidOut.Data4[1]    := (BYTE) aiTmp[3];
      pGuidOut.Data4[2]    := (BYTE) aiTmp[4];
      pGuidOut.Data4[3]    := (BYTE) aiTmp[5];
      pGuidOut.Data4[4]    := (BYTE) aiTmp[6];
      pGuidOut.Data4[5]    := (BYTE) aiTmp[7];
      pGuidOut.Data4[6]    := (BYTE) aiTmp[8];
      pGuidOut.Data4[7]    := (BYTE) aiTmp[9];
      Result:= TRUE;
  end;
end;

*)

//-----------------------------------------------------------------------------
// Name: DXUtil_ConvertGUIDToString()
// Desc: Converts a GUID to a string
//-----------------------------------------------------------------------------
procedure DXUtil_ConvertGUIDToString(const pGuidIn: TGUID; out strOut: PChar);
begin
  // _stprintf( strOut, TEXT("{%0.8X-%0.4X-%0.4X-%0.2X%0.2X-%0.2X%0.2X%0.2X%0.2X%0.2X%0.2X}"),
  StrFmt(strOut, '{%0.8X-%0.4X-%0.4X-%0.2X%0.2X-%0.2X%0.2X%0.2X%0.2X%0.2X%0.2X}',
    [pGuidIn.D1, pGuidIn.D2, pGuidIn.D3,
     pGuidIn.D4[0], pGuidIn.D4[1],
     pGuidIn.D4[2], pGuidIn.D4[3],
     pGuidIn.D4[4], pGuidIn.D4[5],
     pGuidIn.D4[6], pGuidIn.D4[7]]);
end;

end.