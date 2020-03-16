unit GInOut;

interface

uses
  GTypes, GConsts, GBlocks, GVariants, GObject, Classes, SysUtils, ShellAPI, Windows;

type
  TGMInOut = class(TGCustomModule)
  private
    FOpenFiles: array of TStream;

    function Write(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function WriteLn(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Read(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function ReadLn(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function Error(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function System(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function Open(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Close(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Exists(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function ReadFile(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    destructor Destroy; override;
    procedure Unload; override;
  end;

implementation

constructor TGMInOut.Create(Script: TGCustomScript);
begin
 inherited;
 FScript.RegisterFunction('Write', Write); // $S = Write([O], S);
 FScript.RegisterFunction('WriteLn', WriteLn); // $S = WriteLn([O], S);
 FScript.RegisterFunction('Read', Read); // $S = Read([O], [I]);
 FScript.RegisterFunction('ReadLn', ReadLn); // $S = ReadLn([O]);

 FScript.RegisterFunction('Echo', Write); // $S = Echo(S);
 FScript.RegisterFunction('Error', Error); // Error(S1, S2, ... , Sn);
 FScript.RegisterFunction('System', System); // $X = System(Sc, Sp);

 FScript.RegisterFunction('Open', Open); // $O = Open(Sf, [Sm]);
 FScript.RegisterFunction('Close', Close); // Close(F);
 FScript.RegisterFunction('Exists', Exists); // $B = Exists(S);
 FScript.RegisterFunction('File', ReadFile); // $S = File(S);
end;

procedure TGMInOut.Unload;
begin
 FScript.UnregisterFunction('File');
 FScript.UnregisterFunction('Exists');
 FScript.UnregisterFunction('Close');
 FScript.UnregisterFunction('Open');

 FScript.UnregisterFunction('System');
 FScript.UnregisterFunction('Error');
 FScript.UnregisterFunction('Echo');

 FScript.UnregisterFunction('ReadLn');
 FScript.UnregisterFunction('Read');
 FScript.UnregisterFunction('WriteLn');
 FScript.UnregisterFunction('Write');
end;

destructor TGMInOut.Destroy;
var I: integer;
begin
 for I:=Low(FOpenFiles) to High(FOpenFiles) do
  FOpenFiles[I].Free;
 inherited;
end;

function TGMInOut.Write(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=(High(Params)>=0) and (High(Params)<=Ord(not FScript.Options.IODisabled));
 if not Result then Exit;
 if High(Params)=0 then begin
  Result:=Params[0].Execute([grtString]);
  if Result then Result:=Assigned(FScript.OutProc);
  if Result then begin
   Result:=FScript.OutProc(Params[0].Result.ResultStr);
   if ResultType<>[grtNone] then Block.Return(Params[0].Result)
    else if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end else begin
  Result:=Params[0].Execute([grtObject]);
  if Result then Result:=Params[1].Execute([grtString]);
  if Result then Result:=Params[0].Result is TGVObject;
  if Result then Result:=TGVObject(Params[0].Result).Obj is TStream;
  if Result then begin
   if Params[1].Result.ResultStr<>'' then
    TStream(TGVObject(Params[0].Result).Obj).Write(Params[1].Result.ResultStr[1], Length(Params[1].Result.ResultStr));
   if Params[0].Result.Temp then Params[0].Result.Free;
   if ResultType<>[grtNone] then Result:=Block.Return(Params[1].Result)
    else if Params[1].Result.Temp then Params[1].Result.Free;
  end;
 end;
end;

function TGMInOut.WriteLn(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var C: Char;
begin
 Result:=(High(Params)>=0) and (High(Params)<=Ord(not FScript.Options.IODisabled));
 if not Result then Exit;
 if High(Params)=0 then begin
  Result:=Params[0].Execute([grtString]);
  if Result then Result:=Assigned(FScript.OutProc);
  if Result then begin
   Result:=FScript.OutProc(Params[0].Result.ResultStr+GC_NewLine);
   if ResultType<>[grtNone] then Block.Return(Params[0].Result)
    else if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end else begin
  Result:=Params[0].Execute([grtObject]);
  if Result then Result:=Params[1].Execute([grtString]);
  if Result then Result:=Params[0].Result is TGVObject;
  if Result then Result:=TGVObject(Params[0].Result).Obj is TStream;
  if Result then begin
   if Params[1].Result.ResultStr<>'' then
    TStream(TGVObject(Params[0].Result).Obj).Write(Params[1].Result.ResultStr[1], Length(Params[1].Result.ResultStr));
   C:=GC_NewLine;
   TStream(TGVObject(Params[0].Result).Obj).Write(C, 1);
   if Params[0].Result.Temp then Params[0].Result.Free;
   if ResultType<>[grtNone] then Result:=Block.Return(Params[1].Result)
    else if Params[1].Result.Temp then Params[1].Result.Free;
  end;
 end;
end;

function TGMInOut.Error(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I: integer;
begin
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtString]);
  if Result then begin
   Result:=FScript.Error(GE_Script, Params[I].Result.ResultStr, Block);
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
 Result:=False;
end;

function TGMInOut.System(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=(High(Params)>=0) and (High(Params)<=1) and (not FScript.Options.SafeMode) and (not FScript.Options.IODisabled);
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  if (High(Params)=1) then begin
   Result:=Params[1].Execute([grtString]);
   if Result then begin
    Result:=ShellExecute(0, 'open', PAnsiChar(Params[0].Result.ResultStr), PAnsiChar(Params[1].Result.ResultStr), PAnsiChar(GetCurrentDir), SW_SHOWNA)>32;
    if Params[1].Result.Temp then Params[1].Result.Free;
   end;
  end else
   Result:=ShellExecute(0, 'open', PAnsiChar(Params[0].Result.ResultStr), nil, PAnsiChar(GetCurrentDir), SW_SHOWNA)>32;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMInOut.Read(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Buffer: string;
begin
 Result:=High(Params)<=Ord(not FScript.Options.IODisabled)-1;
 if not Result then Exit;
 if High(Params)=-1 then begin
  Result:=False; // under construction...
 end else begin
  Result:=Params[0].Execute([grtObject]);
  if Result then Result:=Params[0].Result is TGVObject;
  if Result then Result:=TGVObject(Params[0].Result).Obj is TStream;
  if Result then begin
   with TStream(TGVObject(Params[0].Result).Obj) do begin
    SetLength(Buffer, Size);
    Read(Buffer[1], Size);
   end;
   if Params[0].Result.Temp then Params[0].Result.Free;
   Result:=Block.Return(TGVString.Create(True, False, Buffer));
  end;
 end;
end;

function TGMInOut.ReadLn(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Buffer: string;
    I, J: integer;
begin
 Result:=High(Params)<=Ord(not FScript.Options.IODisabled)-1;
 if not Result then Exit;
 if High(Params)=-1 then begin
  Result:=False; // under construction...
 end else begin
  Result:=Params[0].Execute([grtObject]);
  if Result then Result:=Params[0].Result is TGVObject;
  if Result then Result:=TGVObject(Params[0].Result).Obj is TStream;
  if Result then begin
   SetLength(Buffer, 1024);
   I:=0;
   J:=1024;
   while (I=0) and (J=1024) do begin
    J:=TStream(TGVObject(Params[0].Result).Obj).Read(Buffer[1], 1024);
    I:=Pos(GC_NewLine, Copy(Buffer, 1, J));
   end;
   TStream(TGVObject(Params[0].Result).Obj).Seek(I-J, soFromCurrent);	
   if Params[0].Result.Temp then Params[0].Result.Free;
   Result:=Block.Return(TGVString.Create(True, False, Copy(Buffer, 1, I-1)));
  end;
 end;
end;

function TGMInOut.Close(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I: integer;
begin
 Result:=(High(Params)=0) and (not FScript.Options.IODisabled);
 if Result then Result:=Params[0].Execute([grtObject]);
 if Result then Result:=Params[0].Result is TGVObject;
 if Result then Result:=TGVObject(Params[0].Result).Obj is TStream;
 if Result then begin
  for I:=Low(FOpenFiles) to High(FOpenFiles) do
   if FOpenFiles[I]=TStream(TGVObject(Params[0].Result).Obj) then begin
    if I<High(FOpenFiles) then FOpenFiles[I]:=FOpenFiles[High(FOpenFiles)];
    SetLength(FOpenFiles, High(FOpenFiles));
    Break;
   end;
  TStream(TGVObject(Params[0].Result).Obj).Free;
  if Params[0] is TGBVariable then TGBVariable(Params[0]).SetSrc(TGVObject.Create(True, False, nil));
 end;
end;

function TGMInOut.Open(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Mode: Word;
    Read, Write: Boolean;
begin
 Result:=(High(Params)>=0) and (High(Params)<=1) and (not FScript.Options.IODisabled);
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  Mode:=fmOpenReadWrite;
  if High(Params)=1 then begin
   Result:=Params[1].Execute([grtString]);
   Read:=Pos('r', Params[1].Result.ResultStr)>0;
   Write:=Pos('w', Params[1].Result.ResultStr)>0;
   case Ord(Read)+Ord(Write)*2 of
    0: Mode:=fmCreate;
    1: Mode:=fmOpenRead;
    2: Mode:=fmOpenWrite;
    3: Mode:=fmOpenReadWrite;
   end;
   if Params[1].Result.Temp then Params[1].Result.Free;
  end;
  if Result then begin
   SetLength(FOpenFiles, High(FOpenFiles)+2);
   try
    FOpenFiles[High(FOpenFiles)]:=TFileStream.Create(Params[0].Result.ResultStr, Mode);
   except
    on E:Exception do begin
     Result:=False;
     FScript.Error(GE_IOError, E.Message, Block);
     SetLength(FOpenFiles, High(FOpenFiles));
    end;
   end;
  end;
  if Result then Result:=Block.Return(TGVObject.Create(True, False, FOpenFiles[High(FOpenFiles)]));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMInOut.Exists(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=(High(Params)=0) and (not FScript.Options.IODisabled);
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  Result:=Block.Return(TGVBoolean.Create(True, False, FileExists(Params[0].Result.ResultStr)));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMInOut.ReadFile(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Stream: TStream;
    Buffer: string;
begin
 Result:=(High(Params)=0) and (not FScript.Options.IODisabled);
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  Stream:=nil;
  try
   Stream:=TFileStream.Create(Params[0].Result.ResultStr, fmOpenRead);
  except
   on E:Exception do begin
    Result:=False;
    FScript.Error(GE_IOError, E.Message, Block);
   end;
  end;
  if Result then begin
   SetLength(Buffer, Stream.Size);
   Stream.Read(Buffer[1], Stream.Size);
   Result:=Block.Return(TGVString.Create(True, False, Buffer));
   Stream.Free;
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

initialization
GRegisterDefaultModule('InOut', TGMInOut);
end.

