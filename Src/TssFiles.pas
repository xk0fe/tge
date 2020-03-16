{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Filepack Unit                          *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssFiles;

interface

uses
  Windows, Classes, SysUtils, Math, zlib;

type
  // Internal Data Types
  TFileHeader = packed record
    FileName: string[63];
    Position, Length: DWord;
  end;
  PFileHeaders = ^TFileHeaders;
  TFileHeaders = array[0..0] of TFileHeader;

  // TssFilePackage (*.tss) Reading System
  TTssFilePack = class(TObject)
  private
    Stream: TFileStream;
    FCount: Word;
    Headers: PFileHeaders;
    FileName: string;
    LockFile: Boolean;
    PreferPacked: Boolean;
    function GetHeader(Index: integer): TFileHeader;
    function GetHeaderIndex(Name: string): integer;
  public
    constructor Create(const APath, AFileName: string; LockFile, PreferPacked: Boolean);
    destructor Destroy; override;
    function LoadToMemByIndex(Index: integer; var Mem: Pointer): integer;
    function LoadToMemByName(const Name: string; var Mem: Pointer): integer;
    function LoadToMemFromFile(const Name: string; var Mem: Pointer): integer;
    property Count: Word read FCount;
    property Header[Index: integer]: TFileHeader read GetHeader;
  end;

implementation

uses TssEngine;

{$WARNINGS OFF}
const
  AllFiles = faReadOnly + faHidden + faSysFile + faVolumeID + faDirectory + faArchive + faAnyFile;
{$WARNINGS ON}
function ReadDir(const Path: string; Recursive: Boolean = True; Include: integer = AllFiles; const Ext: string = ''): TStrings;
  procedure DoFind(const Path: string);
  var SearchRec: TSearchRec;
  begin
   if FindFirst(Path+'*'+Ext, faAnyFile, SearchRec)=0 then repeat
    if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then begin
     if ((SearchRec.Attr and faDirectory) <> 0) and Recursive then DoFind(Path+SearchRec.Name+'\')
      else if ((SearchRec.Attr and Include) <> 0) then Result.Add(Path+SearchRec.Name);
    end;
   until FindNext(SearchRec)<>0;
   FindClose(SearchRec);
  end;
begin
 Result:=TStringList.Create;
 DoFind(IncludeTrailingPathDelimiter(Path));
end;

constructor TTssFilePack.Create(const APath, AFileName: string; LockFile, PreferPacked: Boolean);
var I: integer;
    Mode: Cardinal;
begin
 inherited Create;
 Self.PreferPacked:=PreferPacked;
 if LockFile then Mode:=fmShareDenyWrite
  else Mode:=fmShareDenyNone;
 FileName:=ExtractFilePath(ParamStr(0))+ChangeFileExt(AFileName, '');
 if FileExists(APath+AFileName) then begin
  Stream:=TFileStream.Create(APath+AFileName, fmOpenRead or Mode);
  Stream.Read(FCount,2);
  Headers:=AllocMem(FCount*SizeOf(TFileHeader));
  Stream.Read(Headers^,FCount*SizeOf(TFileHeader));
  for I:=0 to FCount-1 do
   Headers[I].FileName:=ExtractFileName(Headers[I].FileName);
 end;

 if not PreferPacked then
  with ReadDir(ChangeFileExt(ExtractFilePath(ParamStr(0))+AFileName, '')) do begin
   for I:=0 to Count-1 do
    if GetHeaderIndex(ExtractFileName(Strings[I]))<0 then begin
     Inc(FCount);
     ReAllocMem(Headers, ((FCount+16) div 16*16)*SizeOf(TFileHeader));
     Headers[FCount-1].FileName:=ExtractFileName(Strings[I]);
    end;
   Free;
  end;

 //Stream.Free; // TEST!
end;

destructor TTssFilePack.Destroy;
begin
 Stream.Free;
 FreeMem(Headers);
 inherited;
end;

function TTssFilePack.LoadToMemByIndex(Index: integer; var Mem: Pointer): integer;
var Temp: Pointer;  
begin
 if Index<0 then Index:=0;
 if not PreferPacked then begin
  Result:=LoadToMemFromFile(Headers[Index].FileName, Mem);
  if Result>0 then Exit;
 end;
 //Stream:=TFileStream.Create(FileName, fmOpenRead); // TEST!
 Temp:=AllocMem(Headers[Index].Length);
 while LockFile do Sleep(1);
 LockFile:=True;
 Stream.Position:=Headers[Index].Position;
 Stream.Read(Temp^, Headers[Index].Length);
 LockFile:=False;
 DecompressBuf(Temp, Headers[Index].Length, 0, Mem, Result);
 FreeMem(Temp);
 //Stream.Free; // TEST!
end;

function TTssFilePack.LoadToMemByName(const Name: string; var Mem: Pointer): integer;
begin
 if not PreferPacked then begin
  Result:=LoadToMemFromFile(Name, Mem);
  if Result>0 then Exit;
 end;
 LoadToMemByIndex(GetHeaderIndex(Name), Mem);
 Result:=0;
end;

function TTssFilePack.GetHeader(Index: integer): TFileHeader;
begin
 Result:=Headers[Index];
end;

function TTssFilePack.LoadToMemFromFile(const Name: string; var Mem: Pointer): integer;
  procedure LoadFile(const FileName: string);
  var Stream: TFileStream;
  begin
   try
    Stream:=TFileStream.Create(FileName, fmOpenRead);
    Result:=Stream.Size;
    Mem:=AllocMem(Result);
    Stream.Read(Mem^, Result);
    Stream.Free;
   except
    on Exception do Result:=0;
   end;
  end;
  function CheckPath(const Dir: string): Boolean;
  var FindData: TWin32FindData;
      SearchHandle: Cardinal;
      Succesfull: Boolean;
  begin
   Result:=FileExists(Dir+Name);
   if Result then LoadFile(Dir+Name)
    else begin
     SearchHandle:=Windows.FindFirstFile(PChar(Dir+'*'),FindData);
     Succesfull:=SearchHandle<>INVALID_HANDLE_VALUE;
     while Succesfull and (not Result) do begin
      if FindData.cFileName[0]<>'.' then
       if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then Result:=CheckPath(Dir+FindData.cFileName+'\');
      if not Result then Succesfull:=Windows.FindNextFile(SearchHandle, FindData);
     end;
     Windows.FindClose(SearchHandle);
    end;
  end;
begin
 Result:=0;
 CheckPath(FileName+'\');
end;

function TTssFilePack.GetHeaderIndex(Name: string): integer;
var I: integer;
begin
 for I:=0 to FCount-1 do
  if Headers[I].FileName=Name then begin
   Result:=I;
   Exit;
  end;
 Result:=-1;
end;

end.
