unit G2Script;

interface

uses
  Classes, G2Types, G2Consts, G2Variants, G2Compiler, G2Execute,
  SysUtils;

type
  TG2ScriptSourceEvent = function(Sender: TObject; var Name: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean of object;
  TG2ScriptCompiledEvent = procedure(Sender: TObject; const Name: string; const Data: Pointer; const DataLen: integer) of object;
  TG2ScriptErrorEvent = procedure(Sender: TObject; const Error: string) of object;
  TG2ScriptOutputEvent = procedure(Sender: TObject; const Text: string) of object;

  TG2Script = class(TComponent)
  private
    FMain: TG2Execute;
    FOnNeedSource: TG2ScriptSourceEvent;
    FOnCompiled: TG2ScriptCompiledEvent;
    FOnError: TG2ScriptErrorEvent;
    FOnOutput: TG2ScriptOutputEvent;
    procedure DoError(const RunTime: Boolean; const Code: integer; const Text: string);
    function SrcGet(Script: TG2Execute; const AName: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean;
    procedure Output(Script: TG2Execute; const Text: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetEvents(const Events: array of string);
    procedure SetVariable(const Item: TG2Variant; const Name: string);
    procedure RunFile(const Name: string);
    procedure RunCommand(const S: string);
    procedure Event(const ID: integer; const Params: array of TG2Variant);
  published
    property OnNeedSource: TG2ScriptSourceEvent read FOnNeedSource write FOnNeedSource;
    property OnCompiled: TG2ScriptCompiledEvent read FOnCompiled write FOnCompiled;
    property OnError: TG2ScriptErrorEvent read FOnError write FOnError;
    property OnOutput: TG2ScriptOutputEvent read FOnOutput write FOnOutput;
  end;

function G2Var(const Value: G2String): TG2Variant; overload;
function G2Var(const Value: G2Int): TG2Variant; overload;
function G2Var(const Value: G2Float): TG2Variant; overload;
function G2Var(const Value: G2Bool): TG2Variant; overload;
function G2Var(const Value: G2Object): TG2Variant; overload;
function G2Var(const Value: G2Array): TG2Variant; overload;

function G2Var(const Value: G2String; const Release: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Bool; const Release: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Int; const Release: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Float; const Release: TG2Variant): TG2Variant; overload;

function G2Var(const Value: G2Bool; const Release1, Release2: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Int; const Release1, Release2: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Float; const Release1, Release2: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2String; const Release1, Release2: TG2Variant): TG2Variant; overload;
function G2Var(const Value: G2Array; const Release1, Release2: TG2Variant): TG2Variant; overload;

function G2ParamRangeError(const Min, Max: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
function G2ParamMinError(const Min: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
function G2ParamMaxError(const Max: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
function G2ParamCountError(const Need: integer; const Params: G2Array; const Self: TG2Execute): Boolean;

procedure G2Release(var Variant: TG2Variant); overload;
procedure G2Release(const Variants: G2Array); overload;
procedure G2ReleaseConst(const Variant: TG2Variant); overload;

procedure Register;

implementation

procedure Register;
begin
 RegisterComponents('Gebbiz', [TG2Script]);
end;

procedure G2Release(var Variant: TG2Variant);
begin
 if Variant<>nil then begin
  Variant.Release;
  Variant:=nil;
 end;
end;

procedure G2Release(const Variants: G2Array);
var I: integer;
begin
 for I:=Low(Variants) to High(Variants) do
  if Variants[I]<>nil then Variants[I].Release;
end;

procedure G2ReleaseConst(const Variant: TG2Variant);
begin
 if Variant<>nil then Variant.Release;
end;

function G2ParamRangeError(const Min, Max: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
var L: integer;
begin
 L:=Length(Params);
 if L<Min then begin
  Result:=True;
  Self.Error(G2RE_LOWPARAMS, [Min]);
  G2Release(Params);
 end else if L>Max then begin
  Result:=True;
  Self.Error(G2RE_MANYPARAMS, [Max]);
  G2Release(Params);
 end else Result:=False;
end;

function G2ParamMinError(const Min: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
begin
 if Length(Params)<Min then begin
  Result:=True;
  Self.Error(G2RE_LOWPARAMS, [Min]);
  G2Release(Params);
 end else Result:=False;
end;

function G2ParamMaxError(const Max: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
begin
 if Length(Params)>Max then begin
  Result:=True;
  Self.Error(G2RE_MANYPARAMS, [Max]);
  G2Release(Params);
 end else Result:=False;
end;

function G2ParamCountError(const Need: integer; const Params: G2Array; const Self: TG2Execute): Boolean;
var L: integer;
begin
 L:=Length(Params);
 if L<Need then begin
  Result:=True;
  Self.Error(G2RE_LOWPARAMS, [Need]);
  G2Release(Params);
 end else if L>Need then begin
  Result:=True;
  Self.Error(G2RE_MANYPARAMS, [Need]);
  G2Release(Params);
 end else Result:=False;
end;

function G2Var(const Value: G2String): TG2Variant;
begin
 Result:=TG2VString.Create;
 Result.Str:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Int): TG2Variant;
begin
 Result:=TG2VInteger.Create;
 Result.Int:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Float): TG2Variant;
begin
 Result:=TG2VFloat.Create;
 Result.Float:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Bool): TG2Variant;
begin
 Result:=TG2VBoolean.Create;
 Result.Bool:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Object): TG2Variant;
begin
 Result:=TG2VObject.Create;
 Result.Obj:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Array): TG2Variant;
begin
 Result:=TG2VArray.Create;
 Result.Arr:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2String; const Release: TG2Variant): TG2Variant;
begin
 if (Release.ClassType=TG2VString) and (Release.RefCount=1) then Result:=Release
  else begin
   Result:=TG2VString.Create;
   Release.Release;
  end;
 Result.Str:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Bool; const Release: TG2Variant): TG2Variant;
begin
 if (Release.ClassType=TG2VBoolean) and (Release.RefCount=1) then Result:=Release
  else begin
   Result:=TG2VBoolean.Create;
   Release.Release;
  end;
 Result.Bool:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Int; const Release: TG2Variant): TG2Variant;
begin
 if (Release.ClassType=TG2VInteger) and (Release.RefCount=1) then Result:=Release
  else begin
   Result:=TG2VInteger.Create;
   Release.Release;
  end;
 Result.Int:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Float; const Release: TG2Variant): TG2Variant;
begin
 if (Release.ClassType=TG2VFloat) and (Release.RefCount=1) then Result:=Release
  else begin
   Result:=TG2VFloat.Create;
   Release.Release;
  end;
 Result.Float:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Bool; const Release1, Release2: TG2Variant): TG2Variant;
begin
 if (Release1.ClassType=TG2VBoolean) and (Release1.RefCount=1) then begin
  Result:=Release1;
  Release2.Release;
 end else begin
  Release1.Release;
  if (Release2.ClassType=TG2VBoolean) and (Release2.RefCount=1) then Result:=Release2
  else begin
   Result:=TG2VBoolean.Create;
   Release2.Release;
  end;
 end;
 Result.Bool:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Int; const Release1, Release2: TG2Variant): TG2Variant;
begin
 if (Release1.ClassType=TG2VInteger) and (Release1.RefCount=1) then begin
  Result:=Release1;
  Release2.Release;
 end else begin
  Release1.Release;
  if (Release2.ClassType=TG2VInteger) and (Release2.RefCount=1) then Result:=Release2
  else begin
   Result:=TG2VInteger.Create;
   Release2.Release;
  end;
 end;
 Result.Int:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Float; const Release1, Release2: TG2Variant): TG2Variant; overload;
begin
 if (Release1.ClassType=TG2VFloat) and (Release1.RefCount=1) then begin
  Result:=Release1;
  Release2.Release;
 end else begin
  Release1.Release;
  if (Release2.ClassType=TG2VFloat) and (Release2.RefCount=1) then Result:=Release2
  else begin
   Result:=TG2VFloat.Create;
   Release2.Release;
  end;
 end;
 Result.Float:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2String; const Release1, Release2: TG2Variant): TG2Variant;
begin
 if (Release1.ClassType=TG2VString) and (Release1.RefCount=1) then begin
  Result:=Release1;
  Release2.Release;
 end else begin
  Release1.Release;
  if (Release2.ClassType=TG2VString) and (Release2.RefCount=1) then Result:=Release2
  else begin
   Result:=TG2VString.Create;
   Release2.Release;
  end;
 end;
 Result.Str:=Value;
 Result.ReadOnly:=True;
end;

function G2Var(const Value: G2Array; const Release1, Release2: TG2Variant): TG2Variant;
begin
 if (Release1.ClassType=TG2VArray) and (Release1.RefCount=1) then begin
  Result:=Release1;
  Release2.Release;
 end else begin
  Release1.Release;
  if (Release2.ClassType=TG2VArray) and (Release2.RefCount=1) then Result:=Release2
  else begin
   Result:=TG2VArray.Create;
   Release2.Release;
  end;
 end;
 Result.Arr:=Value;
 Result.ReadOnly:=True;
end;

{ TG2Script }

constructor TG2Script.Create(AOwner: TComponent);
begin
 inherited;
 FMain:=TG2Execute.Create;
 FMain.FGetSource:=SrcGet;
 FMain.FTextOut:=Output;
end;

destructor TG2Script.Destroy;
begin
 FMain.Free;
 inherited;
end;

procedure TG2Script.DoError(const RunTime: Boolean; const Code: integer; const Text: string);
begin
 if Assigned(FOnError) then begin
  if RunTime then FOnError(Self, 'Runtime error: '+Text)
   else FOnError(Self, 'Compiler error: '+Text);
 end;
end;

procedure TG2Script.Event(const ID: integer; const Params: array of TG2Variant);
var I: integer;
begin
 if not FMain.Event(ID, Params) then DoError(True, FMain.FErrorCode, FMain.FErrorText);
 for I:=Low(Params) to High(Params) do
  G2ReleaseConst(Params[I]);
end;

procedure TG2Script.Output(Script: TG2Execute; const Text: string);
begin
 if Assigned(FOnOutput) then
  FOnOutput(Self, Text);
end;

procedure TG2Script.RunCommand(const S: string);
begin
 with TG2Compiler.Create do begin
  Source:=PChar(S);
  SrcLen:=Length(S);
  if Compile then begin
   if FMain.FAutoFreeSource and (FMain.FSource<>nil) then FreeMem(FMain.FSource);
   FMain.FSource:=Destination;
   FMain.FSrcLen:=DestLen;
   FMain.FAutoFreeSource:=True;
   if not FMain.Execute then DoError(True, FMain.FErrorCode, FMain.FErrorText);
  end else DoError(False, ErrorCode, ErrorText);
  Free;
 end;
end;

procedure TG2Script.RunFile(const Name: string);
begin
 if FMain.FAutoFreeSource and (FMain.FSource<>nil) then FreeMem(FMain.FSource);
 if SrcGet(FMain, Name, Pointer(FMain.FSource), FMain.FSrcLen, FMain.FAutoFreeSource) then begin
  if not FMain.Execute then DoError(True, FMain.FErrorCode, FMain.FErrorText);
 end else DoError(False, FMain.FErrorCode, FMain.FErrorText);
end;

procedure TG2Script.SetEvents(const Events: array of string);
begin
 FMain.SetEvents(Events);
end;

procedure TG2Script.SetVariable(const Item: TG2Variant; const Name: string);
var OldItem: TG2Variant;
begin
 OldItem:=FMain.FVars[0].GetItemByKey(Name);
 if OldItem<>nil then OldItem.Release;
 FMain.FVars[0].SetItemByKey(Name, Item);
end;

function TG2Script.SrcGet(Script: TG2Execute; const AName: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean;
var Stream: TStream;
    FileName: string;
    FileDate: TDateTime;
    F: TSearchRec;
    P: Pointer;
    L: integer;
    DoFree: Boolean;
begin
 Result:=False;
 DoFree:=True;
 if Assigned(FOnNeedSource) then begin
  FileName:=AName;
  if not FOnNeedSource(Self, FileName, P, L, DoFree) then begin
   Result:=Script.Error(G2RE_FNOTFOUND, [AName]);
   Exit;
  end;
 end else begin
  FileName:='';
  FileDate:=MinDateTime;
  if FindFirst(AName+'.*', faReadOnly+faHidden, F)=0 then begin
   repeat
    if FileDateToDateTime(F.Time)>FileDate then begin
     FileName:=F.Name;
     FileDate:=FileDateToDateTime(F.Time);
    end;
   until FindNext(F)<>0;
  end;
  FindClose(F);
  if FileName='' then begin
   Result:=Script.Error(G2RE_FNOTFOUND, [AName]);
   Exit;
  end;
  Stream:=TFileStream.Create(FileName, fmOpenRead);
  try
   L:=Stream.Size;
   if L>0 then begin
    GetMem(P, L);
    Stream.Read(P^, L);
   end else P:=nil;
  finally
   Stream.Free;
  end;
 end;
  
 if G2IsCompiled(P, L) then begin
  Data:=P;
  DataLen:=L;
  FreeData:=DoFree;
  Result:=True;
 end else begin
  with TG2Compiler.Create do begin
   Source:=P;
   SrcLen:=L;
   Name:=AName;
   if Compile then begin
    Data:=Destination;
    DataLen:=DestLen;
    Result:=True;
    if Assigned(FOnCompiled) then FOnCompiled(Self, FileName, Destination, DestLen)
     else begin
      Stream:=TFileStream.Create(ChangeFileExt(FileName, G2_EXTENSION), fmCreate);
      try
       Stream.Write(Destination^, DestLen);
      finally
       Stream.Free;
      end;
     end;
   end else begin
    Script.FErrorCode:=ErrorCode;
    Script.FErrorText:=ErrorText;
   end;
   if DoFree and (P<>nil) then FreeMem(P);
   Free;
  end;
 end;
end;

end.
