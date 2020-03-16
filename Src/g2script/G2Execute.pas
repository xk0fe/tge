unit G2Execute;

interface

uses
  Math, Classes, G2Types, G2Consts, Windows, SysUtils, TypInfo;

type
  TG2Execute = class;
  TG2GetSourceEvent = function(Script: TG2Execute; const AName: string; out Data: Pointer; out DataLen: integer; out FreeData: Boolean): Boolean of object;
  TG2TextOutEvent = procedure(Script: TG2Execute; const Text: string) of object;

  TG2Execute = class(TPersistent)
  public
    FOwner: TG2Execute;
    FSrcPos: integer;
    FErrorCode: integer;
    FErrorText: string;
    FSrcLen: integer;
    FSource: PChar;
    FModules: TG2Array;
    FStrTableStart: PChar;
    FConsts: TG2Array;
    FVars: G2Arrays;
    FCurVars: integer;
    FCurItem: TG2Variant;
    FCurIndex: integer;
    FFuncs: TG2Array;
    FEvents: array of integer;
    FBreak: Boolean;
    FContinue: Boolean;
    FExit: Boolean;
    FReturn: Boolean;
    FResult: TG2Variant;
    FIncluded: TG2Array;
    FGetSource: TG2GetSourceEvent;
    FTextOut: TG2TextOutEvent;
    FAutoFreeSource: Boolean;
    FEventIndex: TG2Array;
    function Exec(var Succ: Boolean): Boolean;
    procedure ExecIf(var Succ: Boolean);
    procedure ExecWhile(var Succ: Boolean);
    procedure ExecFor(var Succ: Boolean);
    procedure ExecDo(var Succ: Boolean; const DoWhile: Boolean);
    procedure ExecForeach(var Succ: Boolean);
    function ExecGet(var Succ: Boolean): TG2Variant;
    procedure ExecSet(var Succ: Boolean; const Value: TG2Variant);
    function ExecFunc(var Succ: Boolean): TG2Variant;
    function ExecCoreFunc(var Succ: Boolean): TG2Variant;
    function ExecMethod(var Succ: Boolean): TG2Variant;
    procedure ExecTargetSet(var Succ: Boolean; const Result, Value: TG2Variant);
    function ExecConst(var Succ: Boolean): TG2Variant;
    function ExecConstStr(var Succ: Boolean): TG2Variant;
    function ExecConstInt(var Succ: Boolean): TG2Variant;
    function ExecConstFloat(var Succ: Boolean): TG2Variant;
    function ExecConstInt32(var Succ: Boolean): TG2Variant;
    function ExecConstInt16(var Succ: Boolean): TG2Variant;
    function ExecConstInt8(var Succ: Boolean): TG2Variant;
    function ExecConstFloat32(var Succ: Boolean): TG2Variant;
    function ExecOperRight(var Succ: Boolean): TG2Variant;
    function ExecOperLeft(var Succ: Boolean): TG2Variant;
    function ExecOperBoth(var Succ: Boolean): TG2Variant;
    function ExecVarGet(var Succ: Boolean): TG2Variant;
    procedure ExecVarSet(var Succ: Boolean; const Value: TG2Variant);
    function ExecVarScopeGet(var Succ: Boolean; const Local: Boolean): TG2Variant;
    procedure ExecVarScopeSet(var Succ: Boolean; const Local: Boolean; const Value: TG2Variant);
    function ExecArrayGet(var Succ: Boolean): TG2Variant;
    procedure ExecArraySet(var Succ: Boolean; const Value: TG2Variant);
    function ExecPropGet(var Succ: Boolean): TG2Variant;
    procedure ExecPropSet(var Succ: Boolean; const Value: TG2Variant);
    function ExecIndexGet(var Succ: Boolean): TG2Variant;
    procedure ExecIndexSet(var Succ: Boolean; const Value: TG2Variant);
    procedure ExecIndexNewSet(var Succ: Boolean; const Value: TG2Variant);
    function GetString(ID: integer): string;
    function SpaceError(var Succ: Boolean; Need: integer): Boolean;
    function Error(const Code: integer; const Params: array of const): Boolean;
  public
    constructor Create(const AOwner: TG2Execute = nil);
    destructor Destroy; override;
    procedure SetEvents(const Events: array of string);
    function Execute: Boolean; overload;
    function Execute(const Src: TStream): Boolean; overload;
    function Event(const ID: integer; const Params: array of TG2Variant): Boolean;
    property Source: PChar read FSource write FSource;
    property SrcLen: integer read FSrcLen write FSrcLen;
    property AutoFreeSource: Boolean read FAutoFreeSource write FAutoFreeSource;
    property ErrorPos: integer read FSrcPos;
    property ErrorCode: integer read FErrorCode;
    property ErrorText: string read FErrorText;
  end;

  TG2Method = function(const P: G2Array; const Script: TG2Execute): TG2Variant of object;

implementation

uses
  G2Script, G2Compiler, G2Oper, G2Functions;

var
  G2False, G2True, G2Zero, G2One, G2Empty, G2Nil: TG2Variant;

{ TG2Execute }

constructor TG2Execute.Create(const AOwner: TG2Execute = nil);
var I: integer;
    Item: TG2Module;
begin
 inherited Create;
 if AOwner=nil then FOwner:=Self
  else FOwner:=AOwner;
 DecimalSeparator:=G2C_DecimalPoint;
 FModules:=TG2Array.Create;
 for I:=0 to G2Modules.KeyCount-1 do
  with TG2ModuleClass(G2Modules.GetItemByKey(G2Modules.Keys[I])) do
   if AutoLoad then begin
    Item:=Create;
    FModules.Add(Item, G2Modules.Keys[I]);
   end;
 FIncluded:=TG2Array.Create;
 SetLength(FVars, 1);
 if FOwner=Self then begin
  FVars[0]:=TG2Array.Create;
  FEventIndex:=TG2Array.Create;
 end else begin
  FVars[0]:=FOwner.FVars[0];
  SetLength(FEvents, FOwner.FEventIndex.Count);
  for I:=Low(FEvents) to High(FEvents) do
   FEvents[I]:=0;
 end;
 FFuncs:=TG2Array.Create;
 FConsts:=TG2Array.Create;
 FCurVars:=0;
end;

destructor TG2Execute.Destroy;
var I: integer;
begin
 if FAutoFreeSource and (FSource<>nil) then FreeMem(FSource);
 if FOwner=Self then begin
  for I:=0 to FVars[0].Count-1 do
   G2ReleaseConst(TG2Variant(FVars[0].GetItemByIndex(I)));
  FVars[0].Free;
  FEventIndex.Free;
 end;
 for I:=0 to FConsts.Count-1 do
  G2ReleaseConst(TG2Variant(FConsts.GetItemByIndex(I)));
 FConsts.Free;
 FFuncs.Free;
 for I:=0 to FIncluded.Count-1 do
  TG2Execute(FIncluded.GetItemByIndex(I)).Free;
 FIncluded.Free;
 for I:=0 to FModules.Count-1 do
  TG2Module(FModules.GetItemByIndex(I)).Free;
 FModules.Free;
 G2Release(FResult);
 inherited;
end;

function TG2Execute.Execute: Boolean;
var I: integer;
begin
 {if FVarsOwned then begin
  for I:=0 to FVars[0].Count-1 do
   G2ReleaseConst(TG2Variant(FVars[0].GetItemByIndex(I)));
  FVars[0].Clear;
 end;}
 for I:=0 to FConsts.Count-1 do
  G2ReleaseConst(TG2Variant(FConsts.GetItemByIndex(I)));
 for I:=0 to FModules.Count-1 do
  if not TG2Module(FModules.GetItemByIndex(I)).AutoLoad then begin
   TG2Module(FModules.GetItemByIndex(I)).Free;
   FModules.Delete(I);
  end;
 FConsts.Clear;
 G2Release(FResult);
 FCurVars:=0;
 FFuncs.Clear;
 Result:=True;
 Error(G2RE_INTERNAL, []);
 FSrcPos:=0;
 FBreak:=False;
 FContinue:=False;
 FExit:=False;
 FReturn:=False;
 for I:=Low(FEvents) to High(FEvents) do
  FEvents[I]:=0;

 if (FSource=nil) or (FSrcLen=0) then Result:=Error(G2RE_NOSOURCE, [])
 else if FSrcLen<SizeOf(TCGSHeader) then Result:=Error(G2RE_BADSRC, [])
 else with PCGSHeader(FSource)^ do begin
  if (ID<>G2_HEADER) or (StrTable>FSrcLen) or (StrTable<FSrcPos) then Result:=Error(G2RE_BADSRC, [])
  else if (VersionMajor<>G2_VERSIONMAJOR) or (VersionMinor>G2_VERSIONMINOR) then begin
   Result:=Error(G2RE_SRCVERSION, [VersionMajor, VersionMinor, G2_VERSIONMAJOR, G2_VERSIONMINOR]);
  end else begin
   FStrTableStart:=FSource+StrTable;
   FSrcPos:=ConstTable;
   while FSrcPos<FuncTable do begin
    FConsts.Add(ExecGet(Result));
    if not Result then Break;
   end;
   FSrcPos:=FuncTable;
   while FSrcPos<FSrcLen do begin
    if SpaceError(Result, SizeOf(TG2FuncHeader)) then Exit;
    with PG2FuncHeader(FSource+FSrcPos)^ do begin
     case Cmd of
      G2CMD_FUNCTION: FFuncs.Add(Pointer(FSrcPos), GetString(Name));
      G2CMD_EVENT: begin
       I:=FOwner.FEventIndex.IndexOf(GetString(Name));
       if I>=0 then I:=integer(FOwner.FEventIndex.GetItemByIndex(I));
       if (I>=0) and (I<Length(FEvents)) then FEvents[I]:=FSrcPos;
      end;
     end;
     Inc(FSrcPos, SizeOf(TG2FuncHeader)+ParamCount*SizeOf(Word)+ContentLen);
    end;
   end;
   FSrcPos:=SizeOf(TCGSHeader);
   if Result then
    while Exec(Result) do
     if FExit or FReturn then Break;
  end;
 end;

 if Result then begin
  FErrorCode:=G2E_NOERROR;
  FErrorText:='';
 end;
end;

function TG2Execute.Execute(const Src: TStream): Boolean;
begin
 if FSource<>nil then
  if FAutoFreeSource then
   FreeMem(FSource);
 FSrcLen:=Src.Size;
 GetMem(FSource, FSrcLen);
 Src.Read(FSource^, FSrcLen);
 Result:=Execute;
 FAutoFreeSource:=True;
end;

function TG2Execute.Exec(var Succ: Boolean): Boolean;
begin
 Result:=False;
 if (not Succ) or SpaceError(Succ, 1) then Exit;
 Result:=True;
 case PByte(FSource+FSrcPos)^ of
  G2CMD_END: begin Result:=False; Inc(FSrcPos); end;
  G2CMD_BREAK: begin Result:=False; Inc(FSrcPos); FBreak:=True; end;
  G2CMD_CONTINUE: begin Result:=False; Inc(FSrcPos); FContinue:=True; end;
  G2CMD_EXIT: begin Result:=False; Inc(FSrcPos); FExit:=True; end;
  G2CMD_RETURN: begin Result:=False; Inc(FSrcPos); FReturn:=True; G2Release(FResult); end;
  G2CMD_RETURNVAL: begin Result:=False; Inc(FSrcPos); FReturn:=True; G2Release(FResult); FResult:=ExecGet(Succ); end;
  G2CMD_NOP: Inc(FSrcPos);
  G2CMD_IF: ExecIf(Succ);
  G2CMD_WHILE: ExecWhile(Succ);
  G2CMD_FOR: ExecFor(Succ);
  G2CMD_DOWHILE: ExecDo(Succ, True);
  G2CMD_DOUNTIL: ExecDo(Succ, False);
  G2CMD_FOREACH: ExecForeach(Succ);
  G2CMD_FUNCCALL: G2ReleaseConst(ExecFunc(Succ));
  G2CMD_COREFUNC: G2ReleaseConst(ExecCoreFunc(Succ));
  G2CMD_METHODCALL: G2ReleaseConst(ExecMethod(Succ));
  G2CMD_OPERRIGHT: G2ReleaseConst(ExecOperRight(Succ));
  G2CMD_OPERLEFT: G2ReleaseConst(ExecOperLeft(Succ));
  G2CMD_OPERBOTH: G2ReleaseConst(ExecOperBoth(Succ));
  else if Succ then Succ:=Error(G2RE_COULDNOTEXE, []);
 end;
 if not Succ then Result:=False;
end;

function TG2Execute.ExecGet(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if (not Succ) or SpaceError(Succ, 1) then Exit;
 case PByte(FSource+FSrcPos)^ of
  G2CMD_FUNCCALL: Result:=ExecFunc(Succ);
  G2CMD_COREFUNC: Result:=ExecCoreFunc(Succ);
  G2CMD_METHODCALL: Result:=ExecMethod(Succ);
  G2CMD_VARIABLE: Result:=ExecVarGet(Succ);
  G2CMD_VARGLOBAL: Result:=ExecVarScopeGet(Succ, False);
  G2CMD_VARLOCAL: Result:=ExecVarScopeGet(Succ, True);
  G2CMD_ARRAY: Result:=ExecArrayGet(Succ);
  G2CMD_INDEX: Result:=ExecIndexGet(Succ);
  G2CMD_PROPERTY: Result:=ExecPropGet(Succ);
  G2CMD_CONST: Result:=ExecConst(Succ);
  G2CMD_CONSTSTR: Result:=ExecConstStr(Succ);
  G2CMD_CONSTINT: Result:=ExecConstInt(Succ);
  G2CMD_CONSTFLOAT: Result:=ExecConstFloat(Succ);
  G2CMD_CONSTINT32: Result:=ExecConstInt32(Succ);
  G2CMD_CONSTINT16: Result:=ExecConstInt16(Succ);
  G2CMD_CONSTINT8: Result:=ExecConstInt8(Succ);
  G2CMD_CONSTFLT32: Result:=ExecConstFloat32(Succ);
  G2CMD_OPERRIGHT: Result:=ExecOperRight(Succ);
  G2CMD_OPERLEFT: Result:=ExecOperLeft(Succ);
  G2CMD_OPERBOTH: Result:=ExecOperBoth(Succ);
  else begin
   case PByte(FSource+FSrcPos)^ of
    G2CMD_CURITEM: if FCurItem=nil then Succ:=Error(G2RE_NOCURITEM, []) else Result:=FCurItem.Reference;
    G2CMD_CURINDEX: if FCurItem=nil then Succ:=Error(G2RE_NOCURITEM, []) else Result:=G2Var(FCurIndex);
    G2CMD_CONSTFALSE: Result:=G2False.Reference;
    G2CMD_CONSTTRUE: Result:=G2True.Reference;
    G2CMD_CONSTZERO: Result:=G2Zero.Reference;
    G2CMD_CONSTONE: Result:=G2One.Reference;
    G2CMD_CONSTEMPTY: Result:=G2Empty.Reference;
    G2CMD_CONSTNIL: Result:=G2Nil.Reference;
   end;
   Inc(FSrcPos);
  end;
 end;
 if (Result=nil) and Succ then Succ:=Error(G2RE_COULDNOTGET, []);
end;

procedure TG2Execute.ExecSet(var Succ: Boolean; const Value: TG2Variant);
begin
 if (not Succ) or SpaceError(Succ, 1) then Exit;
 case PByte(FSource+FSrcPos)^ of
  G2CMD_FUNCCALL: ExecTargetSet(Succ, ExecFunc(Succ), Value);
  G2CMD_COREFUNC: ExecTargetSet(Succ, ExecCoreFunc(Succ), Value);
  G2CMD_METHODCALL: ExecTargetSet(Succ, ExecMethod(Succ), Value);
  G2CMD_VARIABLE: ExecVarSet(Succ, Value);
  G2CMD_VARGLOBAL: ExecVarScopeSet(Succ, False, Value);
  G2CMD_VARLOCAL: ExecVarScopeSet(Succ, True, Value);
  G2CMD_ARRAY: ExecArraySet(Succ, Value);
  G2CMD_INDEX: ExecIndexSet(Succ, Value);
  G2CMD_INDEXNEW: ExecIndexNewSet(Succ, Value);
  G2CMD_PROPERTY: ExecPropSet(Succ, Value);
  G2CMD_CURITEM: begin Inc(FSrcPos); ExecTargetSet(Succ, FCurItem.Reference, Value); end;
  else begin
   Value.Release;
   Succ:=Error(G2RE_CANTASSIGN, []);
  end; 
 end;
end;

procedure TG2Execute.ExecIf(var Succ: Boolean);
var Expr: TG2Variant;
    StartPos: integer;
begin
 if (not Succ) or SpaceError(Succ, SizeOf(TG2IfHeader)) then Exit;
 with PG2IfHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2IfHeader));
  Expr:=ExecGet(Succ);
  StartPos:=FSrcPos;
  if Succ then
   if Expr.Bool then begin
    while Exec(Succ) do
     if FBreak or FContinue or FExit or FReturn then Break;
   end else begin
    Inc(FSrcPos, ContentLen);
    if ElseLen>0 then
     while Exec(Succ) do
      if FBreak or FContinue or FExit or FReturn then Break;
   end;
  G2ReleaseConst(Expr);
  if Succ then FSrcPos:=StartPos+ContentLen+ElseLen;
 end;
end;

procedure TG2Execute.ExecWhile(var Succ: Boolean);
var Expr: TG2Variant;
    StartPos, EndPos: integer;
begin
 if (not Succ) or SpaceError(Succ, SizeOf(TG2WhileHeader)) then Exit;
 with PG2WhileHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2WhileHeader));
  StartPos:=FSrcPos;
  Expr:=ExecGet(Succ);
  EndPos:=FSrcPos+ContentLen;
  if Succ then
  while Expr.Bool do begin
   G2Release(Expr);
   while Exec(Succ) do
    if FBreak or FContinue or FExit or FReturn then Break;
   if FBreak then begin FBreak:=False; Break; end;
   if FContinue then FContinue:=False;
   if FExit or FReturn then Break;
   if Succ then begin
    FSrcPos:=StartPos;
    Expr:=ExecGet(Succ);
   end;
   if not Succ then Break; 
  end;
  G2Release(Expr);
  if Succ then FSrcPos:=EndPos;
 end;
end;

procedure TG2Execute.ExecFor(var Succ: Boolean);
var Condition: TG2Variant;
    StepPos, EndPos: integer;
begin
 if (not Succ) or SpaceError(Succ, SizeOf(TG2ForHeader)) then Exit;
 with PG2ForHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2ForHeader));
  Exec(Succ);
  StepPos:=FSrcPos;
  Inc(FSrcPos, StepLen);
  Condition:=ExecGet(Succ);
  EndPos:=FSrcPos+ContentLen;
  if Succ then
  while Condition.Bool do begin
   G2Release(Condition);
   while Exec(Succ) do
    if FBreak or FContinue or FExit or FReturn then Break;
   if FBreak then begin FBreak:=False; Break; end;
   if FContinue then FContinue:=False;
   if FExit or FReturn then Break;
   if Succ then begin
    FSrcPos:=StepPos;
    if StepLen>0 then Exec(Succ);
    Condition:=ExecGet(Succ);
   end;
   if not Succ then Break; 
  end;
  G2Release(Condition);
  if Succ then FSrcPos:=EndPos;
 end;
end;

procedure TG2Execute.ExecDo(var Succ: Boolean; const DoWhile: Boolean);
var Expr: TG2Variant;
    StartPos: integer;
begin
 if (not Succ) or SpaceError(Succ, SizeOf(TG2DoHeader)) then Exit;
 with PG2DoHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2DoHeader));
  StartPos:=FSrcPos;
  Expr:=nil;
  repeat
   G2Release(Expr);
   FSrcPos:=StartPos;
   while Exec(Succ) do
    if FBreak or FContinue or FExit or FReturn then Break;
   if FBreak then begin FBreak:=False; Break; end;
   if FContinue then FContinue:=False;
   if FExit or FReturn then Break;
   if Succ then begin
    FSrcPos:=StartPos+ContentLen;
    Expr:=ExecGet(Succ);
   end;
   if not Succ then Break;
  until Expr.Bool xor DoWhile;
  G2Release(Expr);
  FSrcPos:=StartPos+ContentLen+ConditionLen;
 end;
end;

procedure TG2Execute.ExecForeach(var Succ: Boolean);
var Expr, WasCurItem, CurItem: TG2Variant;
    StartPos, I: integer;
begin
 if (not Succ) or SpaceError(Succ, SizeOf(TG2WhileHeader)) then Exit;
 with PG2WhileHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2WhileHeader));
  Expr:=ExecGet(Succ);
  StartPos:=FSrcPos;
  WasCurItem:=FCurItem;
  if Succ then
   for I:=0 to Expr.Count-1 do begin
    FSrcPos:=StartPos;
    CurItem:=Expr.IndexedItem[I];
    FCurIndex:=I;
    FCurItem:=CurItem;
    while Exec(Succ) do
     if FBreak or FContinue or FExit or FReturn then Break;
    G2ReleaseConst(CurItem);
    if FBreak then begin FBreak:=False; Break; end;
    if FContinue then FContinue:=False;
    if FExit or FReturn then Break;
    if not Succ then Break; 
   end;
  FCurItem:=WasCurItem;
  G2ReleaseConst(Expr);
  if Succ then FSrcPos:=StartPos+ContentLen;
 end;
end;

function TG2Execute.ExecMethod(var Succ: Boolean): TG2Variant;
var I: integer;
    Params: G2Array;
    Owner: TG2Variant;
    Method: TMethod;
begin
 Result:=nil;
 if (not Succ) or SpaceError(Succ, SizeOf(TG2FuncCallHeader)) then Exit;
 with PG2FuncCallHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2FuncCallHeader));

  SetLength(Params, Count);
  for I:=0 to Count-1 do
   Params[I]:=ExecGet(Succ);
  if Succ then begin
   Owner:=ExecGet(Succ);
   if Succ then begin
    Method:=Owner.Method(GetString(Str));
    if Method.Code=nil then Succ:=Error(G2RE_UNDEFMETHOD, [GetString(Str)]);
   end;
   if Succ then begin
    Result:=TG2Method(Method)(Params, Self);
    if FErrorCode<>G2RE_INTERNAL then begin
     Succ:=False;
     G2Release(Result);
    end;
   end else G2Release(Params);
   G2ReleaseConst(Owner);
  end else G2Release(Params);
 end;
end;

function TG2Execute.ExecCoreFunc(var Succ: Boolean): TG2Variant;
var I: integer;
    Params: G2Array;
begin
 Result:=nil;
 if (not Succ) or SpaceError(Succ, SizeOf(TG2FuncCallHeader)) then Exit;
 with PG2FuncCallHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2FuncCallHeader));

  SetLength(Params, Count);
  for I:=0 to Count-1 do
   Params[I]:=ExecGet(Succ);
  if Succ then begin
   Result:=G2Function(Self, Params, TG2FunctionType(Index));
   if (FErrorCode<>G2RE_INTERNAL) and (FErrorCode<>G2E_NOERROR) then begin
    Succ:=False;
    G2Release(Result);
   end;
  end else G2Release(Params);
 end;
end;

function TG2Execute.ExecFunc(var Succ: Boolean): TG2Variant;

  procedure ExecScriptFunc(const Script: TG2Execute; const ScriptPos, Count: integer);
  var I, NextPos: integer;
      Vars: TG2Array;
      WasVars: G2Arrays;
      Item: TG2Variant;
  begin
   WasVars:=nil;
   Vars:=TG2Array.Create;
   with Script do with PG2FuncHeader(FSource+ScriptPos)^ do begin
    if Count>ParamCount then Succ:=Self.Error(G2RE_MANYPARAMS, [ParamCount]);
    if Succ then for I:=0 to Count-1 do begin
     Item:=Self.ExecGet(Succ);
     if Item<>nil then Vars.Add(Item, GetString(PWord(FSource+ScriptPos+SizeOf(TG2FuncHeader)+I*SizeOf(Word))^));
     if not Succ then Break;
    end;
    if Succ then begin
     WasVars:=Copy(FVars);
     FCurVars:=1;
     SetLength(FVars, FCurVars+1);
     FVars[FCurVars]:=Vars;
     NextPos:=FSrcPos;
     FSrcPos:=ScriptPos+SizeOf(TG2FuncHeader)+ParamCount*SizeOf(Word);
     while Exec(Succ) do
      if FExit or FReturn then Break;
     if FReturn then begin
      FReturn:=False;
      Result:=FResult;
      FResult:=nil;
     end;
     FExit:=False;
     if Succ then FSrcPos:=NextPos
      else begin
       G2Release(Result);
       Self.FErrorCode:=Script.ErrorCode;
       Self.FErrorText:=Script.ErrorText;
      end;
     FVars:=WasVars;
     FCurVars:=High(FVars);
    end;  
   end;
   for I:=0 to Vars.Count-1 do
    G2ReleaseConst(TG2Variant(Vars.GetItemByIndex(I)));
   Vars.Free;
  end;

  procedure ExecModuleFunc(const Method: TMethod; const Count: integer);
  var I: integer;
      Params: G2Array;
  begin
   SetLength(Params, Count);
   for I:=0 to Count-1 do
    Params[I]:=ExecGet(Succ);
   if Succ then begin
    Result:=TG2Method(Method)(Params, Self);
    if FErrorCode<>G2RE_INTERNAL then begin
     Succ:=False;
     G2Release(Result);
    end;
   end else G2Release(Params);
  end;
  
var I: integer;
    Name: string;
    Method: TMethod;
    ScriptPos: integer;
    Script: TG2Execute;
begin
 Result:=nil;
 Method.Code:=nil;

 if (not Succ) or SpaceError(Succ, SizeOf(TG2FuncCallHeader)) then Exit;
 with PG2FuncCallHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2FuncCallHeader));
  
  Name:=GetString(Str);

  ScriptPos:=Integer(FFuncs.GetItemByKey(Name));
  if ScriptPos<>0 then begin
   ExecScriptFunc(Self, ScriptPos, Count);
   Exit;
  end;

  if FOwner<>Self then begin
   ScriptPos:=Integer(FOwner.FFuncs.GetItemByKey(Name));
   if ScriptPos<>0 then begin
    ExecScriptFunc(FOwner, ScriptPos, Count);
    Exit;
   end;
  end;

  for I:=0 to FOwner.FIncluded.Count-1 do begin
   Script:=FOwner.FIncluded.GetItemByIndex(I);
   if Script<>Self then begin
    ScriptPos:=Integer(Script.FFuncs.GetItemByKey(Name));
    if ScriptPos<>0 then begin
     ExecScriptFunc(Script, ScriptPos, Count);
     Exit;
    end;
   end;
  end; 

  for I:=0 to FModules.Count-1 do begin
   Method.Code:=TG2Module(FModules.GetItemByIndex(I)).MethodAddress(Name);
   if Method.Code<>nil then begin
    Method.Data:=TG2Module(FModules.GetItemByIndex(I));
    Break;
   end;
  end;
  if Method.Code<>nil then ExecModuleFunc(Method, Count)
   else Succ:=Error(G2RE_UNDEFFUNC, [Name]);
 end;
end;

function TG2Execute.GetString(ID: integer): string;
begin
 Result:=PChar(FStrTableStart+ID);
end;

function TG2Execute.SpaceError(var Succ: Boolean; Need: integer): Boolean;
begin
 Result:=FSrcPos+Need>FSrcLen;
 if Result and Succ then Succ:=Error(G2RE_BADSRC, []);
end;

function TG2Execute.ExecConst(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2ConstHeader)) then Exit;
 Result:=TG2Variant(FConsts.GetItemByIndex(PG2ConstHeader(FSource+FSrcPos).Index)).Reference;
 Inc(FSrcPos, SizeOf(TG2ConstHeader));
end;

function TG2Execute.ExecConstStr(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2ConstStrHeader)) then Exit;
 Result:=G2Var(GetString(PG2ConstStrHeader(FSource+FSrcPos).Str));
 Inc(FSrcPos, SizeOf(TG2ConstStrHeader));
end;

function TG2Execute.ExecConstFloat(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2ConstNumHeader)) then Exit;
 Result:=G2Var(PG2ConstNumHeader(FSource+FSrcPos).Float);
 Inc(FSrcPos, SizeOf(TG2ConstNumHeader));
end;

function TG2Execute.ExecConstInt(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2ConstNumHeader)) then Exit;
 Result:=G2Var(PG2ConstNumHeader(FSource+FSrcPos).Int);
 Inc(FSrcPos, SizeOf(TG2ConstNumHeader));
end;

function TG2Execute.ExecConstFloat32(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2Const32BitHeader)) then Exit;
 Result:=G2Var(PG2Const32BitHeader(FSource+FSrcPos).Float);
 Inc(FSrcPos, SizeOf(TG2Const32BitHeader));
end;

function TG2Execute.ExecConstInt16(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2Const16BitHeader)) then Exit;
 Result:=G2Var(PG2Const16BitHeader(FSource+FSrcPos).Int);
 Inc(FSrcPos, SizeOf(TG2Const16BitHeader));
end;

function TG2Execute.ExecConstInt32(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2Const32BitHeader)) then Exit;
 Result:=G2Var(PG2Const32BitHeader(FSource+FSrcPos).Int);
 Inc(FSrcPos, SizeOf(TG2Const32BitHeader));
end;

function TG2Execute.ExecConstInt8(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2Const8BitHeader)) then Exit;
 Result:=G2Var(PG2Const8BitHeader(FSource+FSrcPos).Int);
 Inc(FSrcPos, SizeOf(TG2Const8BitHeader));
end;

function TG2Execute.ExecOperBoth(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2OperHeader)) then Exit;
 with PG2OperHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2OperHeader));
  Result:=G2OperationBoth(Self, Succ, TG2OperatorType(Oper));
 end;
 if not Succ then if FErrorCode=G2RE_INTERNAL then Error(G2RE_INVALIDOPER, []);
end;

function TG2Execute.ExecOperLeft(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2OperHeader)) then Exit;
 with PG2OperHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2OperHeader));
  Result:=G2OperationLeft(Self, Succ, TG2OperatorType(Oper));
 end;
 if not Succ then if FErrorCode=G2RE_INTERNAL then Error(G2RE_INVALIDOPER, []);
end;

function TG2Execute.ExecOperRight(var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2OperHeader)) then Exit;
 with PG2OperHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2OperHeader));
  Result:=G2OperationRight(Self, Succ, TG2OperatorType(Oper));
 end;
 if not Succ then if FErrorCode=G2RE_INTERNAL then Error(G2RE_INVALIDOPER, []);
end;

function TG2Execute.ExecVarGet(var Succ: Boolean): TG2Variant;
var I: integer;
    S: string;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2VarHeader)) then Exit;
 S:=GetString(PG2VarHeader(FSource+FSrcPos).Str);
 for I:=FCurVars downto 0 do begin
  Result:=FVars[I].GetItemByKey(S);
  if Result<>nil then Break;
 end;
 if Result=nil then Succ:=Error(G2RE_UNDEFVAR, [GetString(PG2VarHeader(FSource+FSrcPos).Str)])
  else Result:=Result.Reference;
 Inc(FSrcPos, SizeOf(TG2VarHeader));
end;

function TG2Execute.ExecVarScopeGet(var Succ: Boolean; const Local: Boolean): TG2Variant;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2VarHeader)) then Exit;
 if Local then Result:=FVars[FCurVars].GetItemByKey(GetString(PG2VarHeader(FSource+FSrcPos).Str))
  else Result:=FVars[0].GetItemByKey(GetString(PG2VarHeader(FSource+FSrcPos).Str));
 if Result=nil then Succ:=Error(G2RE_UNDEFVAR, [GetString(PG2VarHeader(FSource+FSrcPos).Str)])
  else Result:=Result.Reference;
 Inc(FSrcPos, SizeOf(TG2VarHeader));
end;

procedure TG2Execute.ExecVarSet(var Succ: Boolean; const Value: TG2Variant);
var Index: integer;
    S: string;
    I: integer;
begin
 if SpaceError(Succ, SizeOf(TG2VarHeader)) then Exit;
 S:=GetString(PG2VarHeader(FSource+FSrcPos).Str);
 Inc(FSrcPos, SizeOf(TG2VarHeader));
 I:=FCurVars+1;
 repeat
  Dec(I);
  Index:=FVars[I].IndexOf(S);
 until (I=0) or (Index>=0);
 if Index=-1 then TG2Variant(FVars[FCurVars].Add(Value.CopyAndRelease, S)).ReadOnly:=False
  else with TG2Variant(FVars[I].GetItemByIndex(Index)) do
   if ((DefaultType=Value.DefaultType) and ((Value.RefCount>1) or (RefCount>1))) or (ClassType=TG2VReference) then begin
    Assign(Value);
    Value.Release;
    ReadOnly:=False;
   end else begin
    Release;
    FVars[FCurVars].SetItemByIndex(Index, Value.CopyAndRelease);
    TG2Variant(FVars[FCurVars].GetItemByIndex(Index)).ReadOnly:=False;
   end;
end;

procedure TG2Execute.ExecVarScopeSet(var Succ: Boolean; const Local: Boolean; const Value: TG2Variant);
var Index, VIndex: integer;
    S: string;
begin
 if SpaceError(Succ, SizeOf(TG2VarHeader)) then Exit;
 S:=GetString(PG2VarHeader(FSource+FSrcPos).Str);
 Inc(FSrcPos, SizeOf(TG2VarHeader));
 if Local then VIndex:=FCurVars else VIndex:=0;
 Index:=FVars[VIndex].IndexOf(S);
 if Index=-1 then TG2Variant(FVars[VIndex].Add(Value.CopyAndRelease, S)).ReadOnly:=False
  else with TG2Variant(FVars[VIndex].GetItemByIndex(Index)) do
   if ((DefaultType=Value.DefaultType) and (Value.RefCount>1)) or (ClassType=TG2VReference) then begin
    Assign(Value);
    Value.Release;
    ReadOnly:=False;
   end else begin
    Release;
    FVars[VIndex].SetItemByIndex(Index, Value.CopyAndRelease);
    TG2Variant(FVars[VIndex].GetItemByIndex(Index)).ReadOnly:=False;
   end;
end;

function TG2Execute.Error(const Code: integer; const Params: array of const): Boolean;
var S: string;
begin
 with FOwner.FIncluded do S:=Keys[KeyIndex(IndexOf(Self))];
 if S='' then S:='<main>';
 FErrorCode:=Code;
 FErrorText:=Format(G2E_MSG, [S, IntToStr(FSrcPos), Format(G2RE_ERRORS[Code], Params)]);
 Result:=False;
end;

function TG2Execute.ExecArrayGet(var Succ: Boolean): TG2Variant;
var Items: G2Array;
    I: integer;
begin
 Result:=nil;
 if SpaceError(Succ, SizeOf(TG2ArrayHeader)) then Exit;
 with PG2ArrayHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2ArrayHeader));
  SetLength(Items, Count);
  for I:=0 to Count-1 do
   Items[I]:=ExecGet(Succ);
  if Succ then Result:=G2Var(Items)
   else for I:=Low(Items) to High(Items) do
    G2ReleaseConst(Items[I]);
 end;
end;

procedure TG2Execute.ExecArraySet(var Succ: Boolean; const Value: TG2Variant);
var I, LastFound: integer;
    Item: TG2Variant;
begin
 if SpaceError(Succ, SizeOf(TG2ArrayHeader)) then Exit;
 with PG2ArrayHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2ArrayHeader));
  LastFound:=-1;
  for I:=0 to Count-1 do begin
   Item:=Value.IndexedItem[I];
   if Item=nil then begin
    if LastFound>=0 then Item:=Value.IndexedItem[LastFound];
    if Item=nil then Item:=G2Zero.Reference;
   end else LastFound:=I;
   ExecSet(Succ, Item);
   if not Succ then Break;
  end;
  Value.Release;
 end;
end;

function TG2Execute.ExecIndexGet(var Succ: Boolean): TG2Variant;
var Index, Target: TG2Variant;
begin
 Result:=nil;
 Inc(FSrcPos);
 Index:=ExecGet(Succ);
 Target:=ExecGet(Succ);
 if Succ then begin
  if Index.DefaultType=gvtString then Result:=Target.KeyedItem[Index.Str]
   else Result:=Target.IndexedItem[Index.Int];
  if Result=nil then Succ:=Error(G2RE_INDEX, [Index.Str]);
 end;
 G2ReleaseConst(Index);
 G2ReleaseConst(Target);
end;

function TG2Execute.ExecPropGet(var Succ: Boolean): TG2Variant;
var Target: TG2Variant;
begin
 Result:=nil;
 with PG2PropHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2PropHeader));
  Target:=ExecGet(Succ);
  if Succ then begin
   Result:=Target.KeyedItem[GetString(Str)];
   if Result=nil then Succ:=Error(G2RE_INDEX, [GetString(Str)]);
  end;
  G2ReleaseConst(Target);
 end;
end;

procedure TG2Execute.ExecIndexSet(var Succ: Boolean; const Value: TG2Variant);
var Index, Target, Item: TG2Variant;
begin
 Inc(FSrcPos);
 Index:=ExecGet(Succ);
 Target:=ExecGet(Succ);
 if Succ then begin
   if Index.DefaultType=gvtString then Item:=Target.KeyedItem[Index.Str]
    else Item:=Target.IndexedItem[Index.Int];
   if (Item=nil) and (Target.ReadOnly) then begin
    Succ:=Error(G2RE_CANTASSIGN, []);
    G2ReleaseConst(Value);
   end else if Item<>nil then begin
    {if Item.ReadOnly then begin
     Succ:=Error(G2RE_CANTASSIGN, []);
     G2ReleaseConst(Value);
    end else} if ((Item.DefaultType=Value.DefaultType) or Target.ReadOnly) and (not Item.ReadOnly) then begin
     Item.Assign(Value);
     G2ReleaseConst(Value);
    end else begin
     if Index.DefaultType=gvtString then Target.KeyedItem[Index.Str]:=Value
      else Target.IndexedItem[Index.Int]:=Value;
    end;
    G2ReleaseConst(Item);
   end else begin
    if Index.DefaultType=gvtString then Target.KeyedItem[Index.Str]:=Value
     else Target.IndexedItem[Index.Int]:=Value;
   end;
 end else G2ReleaseConst(Value);
 G2ReleaseConst(Index);
 G2ReleaseConst(Target);
end;

procedure TG2Execute.ExecIndexNewSet(var Succ: Boolean; const Value: TG2Variant);
var Target: TG2Variant;
begin
 Inc(FSrcPos);
 Target:=ExecGet(Succ);
 if Succ then begin
   if Target.ReadOnly then begin
    Succ:=Error(G2RE_CANTASSIGN, []);
    G2ReleaseConst(Value);
   end else begin
    Target.IndexedItem[Target.Count]:=Value;
   end;
 end else G2ReleaseConst(Value);
 G2ReleaseConst(Target);
end;

procedure TG2Execute.ExecPropSet(var Succ: Boolean; const Value: TG2Variant);
var Target, Item: TG2Variant;
begin
 with PG2PropHeader(FSource+FSrcPos)^ do begin
  Inc(FSrcPos, SizeOf(TG2PropHeader));
  Target:=ExecGet(Succ);
  if Succ then begin
   Item:=Target.KeyedItem[GetString(Str)];
   if (Item=nil) and (Target.ReadOnly) then begin
    Succ:=Error(G2RE_CANTASSIGN, []);
    G2ReleaseConst(Value);
   end else if Item<>nil then begin
    {if Item.ReadOnly then begin
     Succ:=Error(G2RE_CANTASSIGN, []);
     G2ReleaseConst(Value);
    end else} if ((Item.DefaultType=Value.DefaultType) or Target.ReadOnly) and (not Item.ReadOnly) then begin
     Item.Assign(Value);
     G2ReleaseConst(Value);
    end else begin
     Target.KeyedItem[GetString(Str)]:=Value;
    end;
    G2ReleaseConst(Item);
   end else begin
    Target.KeyedItem[GetString(Str)]:=Value;
   end;
  end else G2ReleaseConst(Value);
  G2ReleaseConst(Target);
 end;
end;

procedure TG2Execute.ExecTargetSet(var Succ: Boolean; const Result, Value: TG2Variant);
begin
 if Succ then begin
  if Result=nil then Succ:=Error(G2RE_CANTASSIGN, [])
  else if Result.ReadOnly then Succ:=Error(G2RE_CANTASSIGN, [])
  else Result.Assign(Value);
 end;
 G2ReleaseConst(Value);
 G2ReleaseConst(Result);
end;

function TG2Execute.Event(const ID: integer; const Params: array of TG2Variant): Boolean;
var I, NextPos, EventPos: integer;
    WasVars: G2Arrays;
    Vars: TG2Array;
begin
 Result:=True;
 WasVars:=nil;
 EventPos:=FEvents[ID];
 if EventPos>0 then with PG2FuncHeader(FSource+EventPos)^ do begin
  Error(G2RE_INTERNAL, []);
  Vars:=TG2Array.Create;
  for I:=Low(Params) to High(Params) do
   Vars.Add(Params[I], GetString(PWord(FSource+EventPos+SizeOf(TG2FuncHeader)+I*SizeOf(Word))^));
  WasVars:=Copy(FVars);
  FCurVars:=1;
  SetLength(FVars, FCurVars+1);
  FVars[FCurVars]:=Vars;
  NextPos:=FSrcPos;
  FSrcPos:=EventPos+SizeOf(TG2FuncHeader)+ParamCount*SizeOf(Word);
  while Exec(Result) do 
   if FExit or FReturn then Break; 
  if FReturn then begin
   FReturn:=False;
   G2Release(FResult);
  end;     
  FExit:=False;
  if Result then FSrcPos:=NextPos;
  FVars:=WasVars;
  FCurVars:=High(FVars);
  Vars.Free;
 end;
 if Result and (FOwner=Self) then begin
  for I:=0 to FIncluded.Count-1 do
   if not TG2Execute(FIncluded.GetItemByIndex(I)).Event(ID, Params) then begin
    FErrorCode:=TG2Execute(FIncluded.GetItemByIndex(I)).ErrorCode;
    FErrorText:=TG2Execute(FIncluded.GetItemByIndex(I)).ErrorText;
    Exit;
   end;
 end;
end;

procedure TG2Execute.SetEvents(const Events: array of string);
var I: integer;
begin
 if FOwner<>Self then Exit;
 FEventIndex.Clear;
 for I:=Low(Events) to High(Events) do
  FEventIndex.Add(Pointer(I), Events[I]);
 SetLength(FEvents, FEventIndex.Count);
 for I:=Low(FEvents) to High(FEvents) do
  FEvents[I]:=0;
end;

initialization
G2False:=G2Var(False);
G2True:=G2Var(True);
G2Zero:=G2Var(0);
G2One:=G2Var(1);
G2Empty:=G2Var('');
G2Nil:=G2Var(TObject(nil));
finalization
G2False.Release;
G2True.Release;
G2Zero.Release;
G2One.Release;
G2Empty.Release;
G2Nil.Release;
end.
