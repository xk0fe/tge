unit G2Compiler;

interface

uses
  Math, Classes, G2Types, G2Consts, Windows, SysUtils;

const
  G2C_ALLOCBY = 1024;

type
  TG2Compiler = class(TPersistent)
  private
    FSource: PChar;
    FSrcLen: integer;
    FDestination: PChar;
    FDestLen: integer;                                       
    FCurLine: integer;
    FLineStart: integer;
    FErrorCode: integer;
    FErrorText: string;
    FSrcPos: integer;
    FDestPos: integer;
    FStrTablePos: integer;
    FStrTable: TG2Array;
    FFunctions: array of string;
    FConsts: string;
    FConstCount: integer;
    FEndChar: Char;
    FName: string;
    procedure NeedSpace(const Size: integer);
    procedure AddData(const Data; const Size: integer);
    function AddStr(var Succ: Boolean; const S: string): integer;
    procedure WriteStrTable;
    procedure WriteFuncTable;
    procedure IgnoreSpace;
    procedure IgnoreComment(const Multiline: Boolean);
    function ReadID(var Succ, SelfEnd: Boolean): string;
    function ReadCtrlStruct(const Struct: TG2StructureType; var Succ, SelfEnd: Boolean): string;
    function ReadVariable(var Succ: Boolean): string;
    function ReadOperator(var Succ: Boolean): TG2OperatorType;
    function ReadString(var Succ: Boolean): string;
    function ReadNumber(var Succ: Boolean): string;
    function ReadArray(var Succ: Boolean): string;
    function ReadIndex(var Succ: Boolean): string;
    function ReadField(var Succ: Boolean): string;
    function ReadFuncCall(const Name: string; var Succ: Boolean): string;
    function ReadCoreFunc(const Func: TG2FunctionType; var Succ: Boolean): string;
    function ReadNext(const EndChars: TG2Chars; var Succ: Boolean; var S: string; const AllowEnd: Boolean): Boolean;
    function PeekChar: Char;
    function PeekStr(const Len: integer): string;
    function ExpectChar(var Succ: Boolean; C: Char): Boolean; overload;
    function ExpectChar(var Succ: Boolean; C: TG2Chars): Boolean; overload;
    function GetErrorPos: integer;
    function Error(const Code: integer; const Params: array of const): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Compile: Boolean; overload;
    function Compile(const Src: string; const Dest: TStream): Boolean; overload;
    property Source: PChar read FSource write FSource;
    property SrcLen: integer read FSrcLen write FSrcLen;
    property Destination: PChar read FDestination;
    property DestLen: integer read FDestPos;
    property ErrorLine: integer read FCurLine;
    property ErrorPos: integer read GetErrorPos;
    property ErrorCode: integer read FErrorCode;
    property ErrorText: string read FErrorText;
    property Name: string read FName write FName;
  end;

function G2IsCompiled(const Data: Pointer; const DataLen: integer): Boolean;

implementation

function G2IsCompiled(const Data: Pointer; const DataLen: integer): Boolean;
begin
 if (Data=nil) or (DataLen<SizeOf(TCGSHeader)) then Result:=False
  else with PCGSHeader(Data)^ do
   Result:=ID=G2_HEADER;
end;

function CharName(const C: Char): string;
begin
 if C=#0 then Result:='EOF'
  else Result:=C;
end;

function CharList(const Chars: TG2Chars): string;
var I: Char;
begin
 Result:='';
 for I:=#0 to #255 do
  if I in Chars then begin
   if Result<>'' then Result:=Result+', ';
   Result:=Result+'"'+CharName(I)+'"';
  end;
end;

function GetRegExp(const Index: integer; const S: string): string;
var Cell, I, Start, L: integer;
    Ignore: Boolean;
begin
 Cell:=-1;
 Start:=0;
 Ignore:=False;
 I:=1;
 L:=Length(S);
 while I<=L do begin
  if not Ignore then case S[I] of
   '\': Ignore:=True;
   '/': begin
    Inc(Cell);
    if Cell=Index then Start:=I+1
     else If Cell=Index+1 then Break;
   end;
  end else Ignore:=False;
  Inc(I);
 end;
 Result:=Copy(S, Start, I-Start);
end;

function HexDig(ch: Char): integer;
begin
 Result:=0;
 if (ch >= 'a') and (ch <= 'f') then ch:=Char(Ord(ch)-(Ord('a')-Ord('A')));
 if (ch < '0') or (ch > 'F') or ((ch > '9') and (ch < 'A')) then Exit;
 Result:=Ord(ch)-Ord('0');
 if ch >= 'A' then Result:=Result-(Ord('A')-Ord('9')-1);
end;

function UnQuoteChars(const S: string; const SimpleOnly: Boolean): string;
var Pos, L: integer;
  function UnQuoteChar: Char;
  begin
   case S[Pos] of
    G2C_QuoteTab: Result:=G2C_Tab;
    G2C_QuoteNewLine: Result:=G2C_NewLine;
    G2C_QuoteCarReturn: Result:=G2C_CarReturn;
    G2C_QuoteFormFeed: Result:=G2C_FormFeed;
    G2C_QuoteAlarm: Result:=G2C_Alarm;
    G2C_QuoteEscape: Result:=G2C_Escape;
    G2C_QuoteHexadecimal: begin
     Result:=#0;
     Inc(Pos);
     if Pos>L then Exit;
     if S[Pos]=G2C_QuoteHexOpen then begin // \x{nnnn}
      repeat
       Inc(Pos);
       if Pos>L then Exit;
       if S[Pos]<>G2C_QuoteHexClose then begin
        if (Ord(Result) shr (SizeOf(Char)*8-4)) and $F<>0 then Exit;
        Result:=Char((Ord(Result) shl 4) or HexDig(S[Pos]));
       end else Break;
      until False;
     end else begin
      Result:=Char(HexDig(S[Pos]));
      Inc(Pos);
      if Pos>L then Exit;
      Result:=Char((Ord(Result) shl 4) or HexDig(S[Pos]));
     end;
    end;
    else Result:=S[Pos];
   end;
  end;
begin
 Pos:=1;
 L:=Length(S);
 Result:='';
 while Pos<=L do begin
  if (Pos<L) and (S[Pos]=G2C_ConstantQuote) then begin
   Inc(Pos);
   if SimpleOnly then begin
    if S[Pos]=G2C_SimpleQuote then Result:=Result+S[Pos]
     else Result:=Result+S[Pos-1]+S[Pos];
   end else Result:=Result+UnQuoteChar;
  end else Result:=Result+S[Pos];
  Inc(Pos);
 end;
end;

{ TG2Compiler }

constructor TG2Compiler.Create;
begin
 inherited;
 FStrTable:=TG2Array.Create;
end;

destructor TG2Compiler.Destroy;
begin
 FStrTable.Free;
 inherited;
end;

function TG2Compiler.Compile: Boolean;
var Header: TCGSHeader;
    S: string;
begin
 Result:=True;
 FDestination:=nil;
 FDestLen:=0;
 FCurLine:=0;
 FLineStart:=0;
 Error(G2CE_INTERNAL, []);
 FSrcPos:=0;
 FDestPos:=0;
 FStrTablePos:=0;
 FStrTable.Clear;
 FFunctions:=nil;

 if (FSource=nil) or (FSrcLen=0) then begin
  Result:=Error(G2CE_NOSOURCE, []);
 end else begin
  Header.ID:=G2_HEADER;
  Header.VersionMajor:=G2_VERSIONMAJOR;
  Header.VersionMinor:=G2_VERSIONMINOR;
  Header.Reserved:=0;
  AddData(Header, SizeOf(Header));
  while ReadNext([G2C_Separator], Result, S, True) do begin
   AddData(PChar(S)^, Length(S));
   Inc(FSrcPos);
  end;
  if Result then begin
   AddData(PChar(S)^, Length(S));
   S:=Chr(G2CMD_END);
   AddData(PChar(S)^, 1);
   Header.StrTable:=FDestPos;
   WriteStrTable;
   Header.ConstTable:=FDestPos;
   AddData(PChar(FConsts)^, Length(FConsts));
   Header.FuncTable:=FDestPos;
   WriteFuncTable;
   TCGSHeader(Pointer(FDestination)^):=Header;
  end;
 end;

 FSource:=nil;
 FSrcLen:=0;
 if Result then begin
  FErrorCode:=G2E_NOERROR;
  FErrorText:='';
 end else begin
  if FDestination<>nil then FreeMem(FDestination);
  FDestination:=nil;
  FDestLen:=0;
 end;
end;

type
  PG2Element = ^TG2Element;
  TG2Element = record
    Oper: TG2OperatorType;
    Data: string;
  end;

function TG2Compiler.ReadNext(const EndChars: TG2Chars; var Succ: Boolean; var S: string; const AllowEnd: Boolean): Boolean;
var Elements: array of TG2Element;

  function AddElement: PG2Element;
  begin
   SetLength(Elements, Length(Elements)+1);
   Result:=@Elements[High(Elements)];
   Result.Oper:=gotNone;
   Result.Data:='';
  end;

  function GetLastOper(const iMin, iMax: integer): string;
  var I, Position, Priority: integer;
  begin
   Result:='';
   if not Succ then Exit;
   if (iMin=iMax) and (Elements[iMin].Oper<>gotNone) then begin
    Succ:=Error(G2CE_INVALIDOPER, []);
    Exit;
   end;
   Priority:=255;
   Position:=-1;
   for I:=iMax downto iMin do
    if Elements[I].Oper<>gotNone then
     if G2C_OperatorPriority[Elements[I].Oper]<Priority then begin
      Position:=I;
      Priority:=G2C_OperatorPriority[Elements[I].Oper];
     end;
   if Position=-1 then begin
    Result:=Elements[iMin].Data;
    if Result='' then Succ:=Error(G2CE_STATEMENT, []);
   end else begin
    SetLength(Result, SizeOf(TG2OperHeader));
    with PG2OperHeader(PChar(Result))^ do begin
     Cmd:=G2CMD_OPER+Ord(iMin<Position)*2+Ord(iMax>Position);
     Oper:=Ord(Elements[Position].Oper);
    end;
    if Elements[Position].Oper=gotAssign then begin
     if iMax>Position then Result:=Result+GetLastOper(Position+1, iMax);
     if iMin<Position then Result:=Result+GetLastOper(iMin, Position-1);
    end else begin
     if iMin<Position then Result:=Result+GetLastOper(iMin, Position-1);
     if iMax>Position then Result:=Result+GetLastOper(Position+1, iMax);
    end;
   end;
  end;

var C: Char;
    NeedOper, SelfEnd: Boolean;
begin
 SetLength(S, Length(G2C_LineComment));
 FEndChar:=#0;
 Elements:=nil;
 while (FSrcPos<FSrcLen) and Succ do begin
  NeedOper:=Elements<>nil;
  if NeedOper then NeedOper:=Elements[High(Elements)].Oper=gotNone;
  C:=PeekChar;
  if C=G2C_LineComment[1] then if PeekStr(Length(G2C_LineComment))=G2C_LineComment then begin
   IgnoreComment(False);
   C:=PeekChar;
  end;
  if C in G2C_WhiteSpaceChars then IgnoreSpace
  else if C in EndChars then begin FEndChar:=C; Break; end
  else if C in G2C_OperatorChars then AddElement.Oper:=ReadOperator(Succ)
  else if C=G2C_ArrayOpen then begin
   if NeedOper then Elements[High(Elements)].Data:=ReadIndex(Succ)+Elements[High(Elements)].Data
    else AddElement.Data:=ReadArray(Succ);
  end else if (C=G2C_FieldDelimiter) and NeedOper then begin
   Elements[High(Elements)].Data:=ReadField(Succ)+Elements[High(Elements)].Data;
  end else if NeedOper then Succ:=Error(G2CE_EXPECTOPER, [CharList(EndChars), CharName(C)])
  else if C in G2C_IDFirstChars then begin
   SelfEnd:=False;
   AddElement.Data:=ReadID(Succ, SelfEnd);
   if SelfEnd then begin
    if not AllowEnd then Succ:=Error(G2CE_BADCTRL, [])
     else Dec(FSrcPos);
    Break;
   end;
  end else if C=G2C_VarChar then AddElement.Data:=ReadVariable(Succ)
  else if C=G2C_ParamListOpen then begin
   Inc(FSrcPos);
   ReadNext([G2C_ParamListClose], Succ, AddElement.Data, False);
   Inc(FSrcPos);
  end else if C in G2C_Numbers then AddElement.Data:=ReadNumber(Succ)
  else if C in G2C_StringQuotes then AddElement.Data:=ReadString(Succ)
  else Succ:=Error(G2CE_ILLEGALCHAR, [CharName(C)]);
 end;
 if Succ and (Elements<>nil) then begin
  if High(Elements)=0 then S:=Elements[0].Data
   else S:=GetLastOper(Low(Elements), High(Elements));
 end else S:='';
 if S='' then S:=Chr(G2CMD_NOP);
 Result:=(FSrcPos<FSrcLen) and Succ;
end;

function TG2Compiler.ReadField(var Succ: Boolean): string;
var StartPos: integer;
    Name: string;

 function ReadMethodCall: string;
 var S: string;
 begin
  SetLength(Result, SizeOf(TG2FuncCallHeader));
  with TG2FuncCallHeader(Pointer(PChar(Result))^) do begin
   Cmd:=G2CMD_METHODCALL;
   Str:=AddStr(Succ, Name);
   Count:=0;
  end;
  Inc(FSrcPos);
  IgnoreSpace;
  if (PeekChar<>G2C_ParamListClose) and Succ then
   while ReadNext([G2C_ParamListDelimiter, G2C_ParamListClose], Succ, S, False) do begin
    if (S=Chr(G2CMD_NOP)) and ((PG2FuncCallHeader(PChar(Result)).Count>0) or (FEndChar=G2C_ParamListDelimiter)) then begin
     Succ:=Error(G2CE_EXPECTEXPR, [CharName(PeekChar)]);
     Break;
    end;
    Inc(PG2FuncCallHeader(PChar(Result)).Count);
    Result:=Result+S;
    if FEndChar<>G2C_ParamListDelimiter then Break;
    if PG2FuncCallHeader(PChar(Result)).Count=255 then begin
     Succ:=Error(G2CE_MANYPARAMS, [255]);
     Break;
    end;
    Inc(FSrcPos);
   end;
  if Succ then ExpectChar(Succ, G2C_ParamListClose);
  if Succ then Inc(FSrcPos);
 end;

begin
 Inc(FSrcPos);
 IgnoreSpace;
 ExpectChar(Succ, G2C_IDFirstChars);
 if not Succ then Exit;
 StartPos:=FSrcPos;
 Inc(FSrcPos);
 while FSrcPos<FSrcLen do begin
  if not (FSource[FSrcPos] in G2C_IDChars) then Break;
  Inc(FSrcPos);
 end;
 SetLength(Name, FSrcPos-StartPos);
 CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
 IgnoreSpace;
 if PeekChar=G2C_ParamListOpen then Result:=ReadMethodCall
  else begin
   SetLength(Result, SizeOf(TG2PropHeader));
   with TG2PropHeader(Pointer(PChar(Result))^) do begin
    Cmd:=G2CMD_PROPERTY;
    Str:=AddStr(Succ, Name);
   end;
  end;
end;

function TG2Compiler.ReadOperator(var Succ: Boolean): TG2OperatorType;
var S: string;
    StartPos: integer;
  function GetOper: TG2OperatorType;
  var otI: TG2OperatorType;
  begin
   for otI:=Low(TG2OperatorType) to High(TG2OperatorType) do
    if G2C_OperatorId[otI]=S then begin
     Result:=otI;
     Exit;
    end;
   Result:=gotNone;
  end;
begin
 StartPos:=FSrcPos;
 Inc(FSrcPos);
 while FSrcPos<FSrcLen do begin
  if not (FSource[FSrcPos] in G2C_OperatorChars) then Break;
  Inc(FSrcPos);
 end;
 Result:=gotNone;
 while FSrcPos>StartPos do begin
  SetLength(S, FSrcPos-StartPos);
  CopyMemory(PChar(S), FSource+StartPos, FSrcPos-StartPos);
  Result:=GetOper;
  if Result<>gotNone then Break;
  Dec(FSrcPos);
 end;
 if Result=gotNone then Succ:=Error(G2CE_UNKNOWNOPER, [S]);
end;

function TG2Compiler.ReadID(var Succ, SelfEnd: Boolean): string;
var Name: string;
    StartPos: integer;
    stI: TG2StructureType;
    ftI: TG2FunctionType;
begin
 StartPos:=FSrcPos;
 Inc(FSrcPos);
 while FSrcPos<FSrcLen do begin
  if not (FSource[FSrcPos] in G2C_IDChars) then Break;
  Inc(FSrcPos);
 end;
 SetLength(Name, FSrcPos-StartPos);
 CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
 IgnoreSpace;

 for stI:=Low(TG2StructureType) to High(TG2StructureType) do
  if Name=G2C_StructureId[stI] then begin
   Result:=ReadCtrlStruct(stI, Succ, SelfEnd);
   Exit;
  end;
 for ftI:=Low(TG2FunctionType) to High(TG2FunctionType) do
  if Name=G2C_FunctionId[ftI] then begin
   Result:=ReadCoreFunc(ftI, Succ);
   Exit;
  end;
 if Name=G2C_BooleanStr[false] then Result:=Chr(G2CMD_CONSTFALSE)
 else if Name=G2C_BooleanStr[true] then Result:=Chr(G2CMD_CONSTTRUE)
 else if Name=G2C_NilStr then Result:=Chr(G2CMD_CONSTNIL)
 else if PeekChar=G2C_ParamListOpen then Result:=ReadFuncCall(Name, Succ)
 else begin
  SetLength(Result, SizeOf(TG2IDHeader));
  with PG2IDHeader(PChar(Result))^ do begin
   Cmd:=G2CMD_ID;
   Str:=AddStr(Succ, Name);
  end;
 end;
end;

function TG2Compiler.ReadCtrlStruct(const Struct: TG2StructureType; var Succ, SelfEnd: Boolean): string;

  function ReadExpression: string;
  begin
   IgnoreSpace;
   ExpectChar(Succ, G2C_ParamListOpen);
   Inc(FSrcPos);
   ReadNext([G2C_ParamListClose], Succ, Result, False);
   Inc(FSrcPos);
  end;

  function ReadContent: string;
  var S: string;
  begin
   Result:='';
   IgnoreSpace;
   if PeekChar=G2C_SrcOpen then begin
    Inc(FSrcPos);
    while ReadNext([G2C_Separator, G2C_SrcClose], Succ, S, True) do begin
     Result:=Result+S;
     Inc(FSrcPos);
     IgnoreSpace;
     if PeekChar=G2C_SrcClose then Break;
    end;
    ExpectChar(Succ, G2C_SrcClose);
   end else
    ReadNext([G2C_Separator], Succ, Result, True);
   Inc(FSrcPos);
   Result:=Result+Chr(G2CMD_END);
  end;

  function ReadIf: string;
  var S1, S2, S3: string;
  begin
   SelfEnd:=True;
   SetLength(Result, SizeOf(TG2IfHeader));
   with PG2IfHeader(PChar(Result))^ do begin
    Cmd:=G2CMD_IF;
    S1:=ReadExpression;
    S2:=ReadContent;
    if Length(S2)>65535 then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    ContentLen:=Length(S2);
    IgnoreSpace;
    if PeekStr(Length(G2C_StructureId[gstElse]))=G2C_StructureId[gstElse] then begin
     Inc(FSrcPos, Length(G2C_StructureId[gstElse]));
     S3:=ReadContent;
     if Length(S3)>65535 then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    end else S3:='';
    ElseLen:=Length(S3);
   end;
   Result:=Result+S1+S2+S3;
  end;

  function ReadWhile: string;
  var S1, S2: string;
  begin
   SelfEnd:=True;
   SetLength(Result, SizeOf(TG2WhileHeader));
   with PG2WhileHeader(PChar(Result))^ do begin
    Cmd:=G2CMD_WHILE;
    S1:=ReadExpression;
    S2:=ReadContent;
    if Length(S2)>65535 then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    ContentLen:=Length(S2);
   end;
   Result:=Result+S1+S2;
  end;

  function ReadFor: string;
  var S1, S2, S3, S4: string;
  begin
   SelfEnd:=True;
   IgnoreSpace;
   ExpectChar(Succ, G2C_ParamListOpen);
   Inc(FSrcPos);
   SetLength(Result, SizeOf(TG2ForHeader));
   with PG2ForHeader(PChar(Result))^ do begin
    Cmd:=G2CMD_FOR;
    ReadNext([G2C_Separator], Succ, S1, False);
    Inc(FSrcPos);
    ReadNext([G2C_Separator], Succ, S2, False);
    Inc(FSrcPos);
    ReadNext([G2C_ParamListClose], Succ, S3, False);
    Inc(FSrcPos);
    S4:=ReadContent;
    if (Length(S3)>65535) or (Length(S4)>65535) then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    StepLen:=Length(S3);
    ContentLen:=Length(S4);
   end;
   Result:=Result+S1+S3+S2+S4;
  end;

  function ReadDo: string;
  var S1, S2: string;
  begin
   SelfEnd:=True;
   SetLength(Result, SizeOf(TG2DoHeader));
   with PG2DoHeader(PChar(Result))^ do begin
    S1:=ReadContent;
    IgnoreSpace;
    if PeekStr(Length(G2C_StructureId[gstWhile]))=G2C_StructureId[gstWhile] then begin
     Inc(FSrcPos, Length(G2C_StructureId[gstWhile]));
     Cmd:=G2CMD_DOWHILE;
    end else if PeekStr(Length(G2C_StructureId[gstUntil]))=G2C_StructureId[gstUntil] then begin
     Inc(FSrcPos, Length(G2C_StructureId[gstUntil]));
     Cmd:=G2CMD_DOUNTIL;
    end else begin
     Succ:=Error(G2CE_BADCTRL, []);
     Exit;
    end;
    S2:=ReadExpression;
    if (Length(S1)>65535) or (Length(S2)>65535) then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    ContentLen:=Length(S1);
    ConditionLen:=Length(S2);
   end;
   IgnoreSpace;
   ExpectChar(Succ, G2C_Separator);
   Result:=Result+S1+S2;
  end;

  function ReadForeach: string;
  var S1, S2: string;
  begin
   SelfEnd:=True;
   SetLength(Result, SizeOf(TG2ForeachHeader));
   with PG2ForeachHeader(PChar(Result))^ do begin
    Cmd:=G2CMD_FOREACH;
    S1:=ReadExpression;
    S2:=ReadContent;
    if Length(S2)>65535 then Succ:=Error(G2CE_CONTROLSIZE, [65535]);
    ContentLen:=Length(S2);
   end;
   Result:=Result+S1+S2;
  end;

  function ReadFunction(Event: Boolean): string;
  var StartPos, FuncName, I: integer;
      S, Name, S3: string;
      Count: Byte;
  begin
   SelfEnd:=True;
   Result:='';
   Count:=0;
   SetLength(S3, 2);
   SetLength(FFunctions, Length(FFunctions)+1);
   IgnoreSpace;
   ExpectChar(Succ, G2C_IDFirstChars);
   FuncName:=0;
   if Succ then begin
    StartPos:=FSrcPos;
    Inc(FSrcPos);
    while FSrcPos<FSrcLen do begin
     if not (FSource[FSrcPos] in G2C_IDChars) then Break;
     Inc(FSrcPos);
    end;
    SetLength(Name, FSrcPos-StartPos);
    CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
    FuncName:=AddStr(Succ, Name);
    IgnoreSpace;
    ExpectChar(Succ, G2C_ParamListOpen);
   end;
   if Succ then begin
    for I:=Ord(Low(TG2StructureType)) to Ord(High(TG2StructureType)) do
     if G2C_StructureId[TG2StructureType(I)]=Name then begin
      Succ:=Error(G2CE_BADNAME, [Name]);
      Break;
     end; 
   end;
   if Succ then begin
    for I:=Ord(Low(TG2FunctionType)) to Ord(High(TG2FunctionType)) do
     if G2C_FunctionId[TG2FunctionType(I)]=Name then begin
      Succ:=Error(G2CE_BADNAME, [Name]);
      Break;
     end; 
   end;
   if Succ then begin
    Inc(FSrcPos);
    S:='';
    IgnoreSpace;
    if PeekChar<>G2C_ParamListClose then
     while True do begin
      IgnoreSpace;
      if PeekChar=G2C_VarChar then begin
       Inc(FSrcPos);
       if Count=255 then begin
        Succ:=Error(G2CE_MANYPARAMS, [255]);
        Exit;
       end;
       Inc(Count);
       ExpectChar(Succ, G2C_IDFirstChars);
       if not Succ then Exit;
       StartPos:=FSrcPos;
       Inc(FSrcPos);
       while FSrcPos<FSrcLen do begin
        if not (FSource[FSrcPos] in G2C_IDChars) then Break;
        Inc(FSrcPos);
       end;
       SetLength(Name, FSrcPos-StartPos);
       CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
       PWord(PChar(S3))^:=AddStr(Succ, Name);
       Insert(S3, S, Length(S)+1);
       if PeekChar=G2C_ParamListClose then begin
        Break;
       end else if PeekChar<>G2C_ParamListDelimiter then begin
        Succ:=Error(G2CE_EXPECTCHAR, [CharList([G2C_ParamListDelimiter, G2C_ParamListClose]), CharName(PeekChar)]);
        Exit;
       end;
      end else begin
       Succ:=Error(G2CE_EXPECTVAR, [CharName(PeekChar)]);
       Exit;
      end;
      Inc(FSrcPos);
     end;
    Inc(FSrcPos);
   end;
   if Succ then begin
    S3:=ReadContent;
    SetLength(FFunctions[High(FFunctions)], SizeOf(TG2FuncHeader));
    with PG2FuncHeader(PChar(FFunctions[High(FFunctions)]))^ do begin
     if Event then Cmd:=G2CMD_EVENT else Cmd:=G2CMD_FUNCTION;
     Name:=FuncName;
     ParamCount:=Count;
     ContentLen:=Length(S3);
    end;
    FFunctions[High(FFunctions)]:=FFunctions[High(FFunctions)]+S+S3;
   end;
  end;

  function ReadReturn: string;
  var S: string;
  begin
   SelfEnd:=True;
   IgnoreSpace;
   if PeekChar=G2C_Separator then Result:=Chr(G2CMD_RETURN)
    else begin
     ReadNext([G2C_Separator], Succ, S, False);
     Result:=Chr(G2CMD_RETURNVAL)+S;
    end;
  end;

  function ReadScope(Local: Boolean): string;
  var Name: string;
      StartPos: integer;
  begin
   IgnoreSpace;
   ExpectChar(Succ, G2C_VarChar);
   Inc(FSrcPos);
   StartPos:=FSrcPos;
   while FSrcPos<FSrcLen do begin
    if not (FSource[FSrcPos] in G2C_IDChars) then Break;
    Inc(FSrcPos);
   end;
   SetLength(Name, FSrcPos-StartPos);
   CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
   SetLength(Result, SizeOf(TG2VarHeader));
   with TG2VarHeader(Pointer(PChar(Result))^) do begin
    if Local then Cmd:=G2CMD_VARLOCAL else Cmd:=G2CMD_VARGLOBAL;
    Str:=AddStr(Succ, Name);
   end;
  end;

begin
 case Struct of
  gstIf: Result:=ReadIf;
  gstWhile: Result:=ReadWhile;
  gstFor: Result:=ReadFor;
  gstDo: Result:=ReadDo;
  gstForeach: Result:=ReadForeach;
  gstBreak: Result:=Chr(G2CMD_BREAK);
  gstContinue: Result:=Chr(G2CMD_CONTINUE);
  gstExit: Result:=Chr(G2CMD_EXIT);
  gstFunction: Result:=ReadFunction(False);
  gstEvent: Result:=ReadFunction(True);
  gstReturn: Result:=ReadReturn;
  gstNop: Result:=Chr(G2CMD_NOP);
  gstGlobal: Result:=ReadScope(False);
  gstLocal: Result:=ReadScope(True);
  gstI: Result:=Chr(G2CMD_CURINDEX);
  else Succ:=Error(G2CE_BADCTRL, []);
 end;
end;

function TG2Compiler.ReadVariable(var Succ: Boolean): string;
var Name: string;
    StartPos: integer;
begin
 Inc(FSrcPos);
 StartPos:=FSrcPos;
 while FSrcPos<FSrcLen do begin
  if not (FSource[FSrcPos] in G2C_IDChars) then Break;
  Inc(FSrcPos);
 end;
 SetLength(Name, FSrcPos-StartPos);
 CopyMemory(PChar(Name), FSource+StartPos, FSrcPos-StartPos);
 if Name=G2C_CurrentVar then Result:=Chr(G2CMD_CURITEM)
  else begin
   SetLength(Result, SizeOf(TG2VarHeader));
   with TG2VarHeader(Pointer(PChar(Result))^) do begin
    Cmd:=G2CMD_VARIABLE;
    Str:=AddStr(Succ, Name);
   end;
  end;
end;

function TG2Compiler.ReadFuncCall(const Name: string; var Succ: Boolean): string;
var S: string;
begin
 SetLength(Result, SizeOf(TG2FuncCallHeader));
 with TG2FuncCallHeader(Pointer(PChar(Result))^) do begin
  Cmd:=G2CMD_FUNCCALL;
  Str:=AddStr(Succ, Name);
  Count:=0;
 end;

 Inc(FSrcPos);
 IgnoreSpace;
 if PeekChar<>G2C_ParamListClose then
  while ReadNext([G2C_ParamListDelimiter, G2C_ParamListClose], Succ, S, False) do begin
   if (S=Chr(G2CMD_NOP)) and ((PG2FuncCallHeader(PChar(Result)).Count>0) or (FEndChar=G2C_ParamListDelimiter)) then begin
    Succ:=Error(G2CE_EXPECTEXPR, [CharName(PeekChar)]);
    Break;
   end;
   Inc(PG2FuncCallHeader(PChar(Result)).Count);
   Result:=Result+S;
   if FEndChar<>G2C_ParamListDelimiter then Break;
   if PG2FuncCallHeader(PChar(Result)).Count=255 then begin
    Succ:=Error(G2CE_MANYPARAMS, [255]);
    Break;
   end;
   Inc(FSrcPos);
  end;
 ExpectChar(Succ, G2C_ParamListClose);
 if Succ then Inc(FSrcPos);
end;

function TG2Compiler.ReadCoreFunc(const Func: TG2FunctionType; var Succ: Boolean): string;
var S: string;
begin
 SetLength(Result, SizeOf(TG2FuncCallHeader));
 with TG2FuncCallHeader(Pointer(PChar(Result))^) do begin
  Cmd:=G2CMD_COREFUNC;
  Index:=Ord(Func);
  Count:=0;
 end;

 if PeekChar<>G2C_ParamListOpen then begin
  if ReadNext([G2C_Separator, G2C_ParamListClose, G2C_ParamListDelimiter, G2C_ArrayClose]+G2C_OperatorChars, Succ, S, False) then
   if S<>Chr(G2CMD_NOP) then begin
    Inc(PG2FuncCallHeader(PChar(Result)).Count);
    Result:=Result+S;
   end;
 end else begin
  Inc(FSrcPos);
  IgnoreSpace;
  if PeekChar<>G2C_ParamListClose then
   while ReadNext([G2C_ParamListDelimiter, G2C_ParamListClose], Succ, S, False) do begin
    if (S=Chr(G2CMD_NOP)) and ((PG2FuncCallHeader(PChar(Result)).Count>0) or (FEndChar=G2C_ParamListDelimiter)) then begin
     Succ:=Error(G2CE_EXPECTEXPR, [CharName(PeekChar)]);
     Break;
    end;
    Inc(PG2FuncCallHeader(PChar(Result)).Count);
    Result:=Result+S;
    if FEndChar<>G2C_ParamListDelimiter then Break;
    if PG2FuncCallHeader(PChar(Result)).Count=255 then begin
     Succ:=Error(G2CE_MANYPARAMS, [255]);
     Break;
    end;
    Inc(FSrcPos);
   end;
  ExpectChar(Succ, G2C_ParamListClose);
  if Succ then Inc(FSrcPos);
 end;
end;

function TG2Compiler.ReadArray(var Succ: Boolean): string;
var S: string;
begin
 SetLength(Result, SizeOf(TG2ArrayHeader));
 with TG2ArrayHeader(Pointer(PChar(Result))^) do begin
  Cmd:=G2CMD_ARRAY;
  Count:=0;
 end;

 Inc(FSrcPos);
 IgnoreSpace;
 if PeekChar<>G2C_ArrayClose then
  while ReadNext([G2C_ArrayDelimiter, G2C_ArrayClose], Succ, S, False) do begin
   if (S=Chr(G2CMD_NOP)) and ((PG2ArrayHeader(PChar(Result)).Count>0) or (FEndChar=G2C_ArrayDelimiter)) then begin
    Succ:=Error(G2CE_EXPECTEXPR, [CharName(PeekChar)]);
    Break;
   end;
   Inc(PG2ArrayHeader(PChar(Result)).Count);
   Result:=Result+S;
   if FEndChar<>G2C_ArrayDelimiter then Break;
   if PG2ArrayHeader(PChar(Result)).Count=255 then begin
    Succ:=Error(G2CE_MANYITEMS, [255]);
    Break;
   end;
   Inc(FSrcPos);
  end;
 ExpectChar(Succ, G2C_ArrayClose);
 if Succ then Inc(FSrcPos);
end;

function TG2Compiler.ReadIndex(var Succ: Boolean): string;
var S: string;
begin
 Inc(FSrcPos);
 ReadNext([G2C_ArrayClose], Succ, S, False);
 ExpectChar(Succ, G2C_ArrayClose);
 Inc(FSrcPos);
 if S=Chr(G2CMD_NOP) then Result:=Chr(G2CMD_INDEXNEW)
  else Result:=Chr(G2CMD_INDEX)+S;
end;

function TG2Compiler.ReadString(var Succ: Boolean): string;
var EndChar: Char;
    StartPos: integer;
    S, S2: string;
begin
 EndChar:=PeekChar;
 Inc(FSrcPos);
 StartPos:=FSrcPos;
 while Succ do begin
  if PeekChar=EndChar then begin
   SetLength(S, FSrcPos-StartPos);
   CopyMemory(PChar(S), FSource+StartPos, FSrcPos-StartPos);
   if S='' then Result:=Chr(G2CMD_CONSTEMPTY)
    else begin
     SetLength(S2, SizeOf(TG2ConstStrHeader));
     with PG2ConstStrHeader(PChar(S2))^ do begin
      Cmd:=G2CMD_CONSTSTR;
      Str:=AddStr(Succ, UnQuoteChars(S, EndChar=G2C_SimpleQuote));
     end;
     SetLength(Result, SizeOf(TG2ConstHeader));
     with PG2ConstHeader(PChar(Result))^ do begin
      Cmd:=G2CMD_CONST;
      Index:=FConstCount;
     end;
     Insert(S2, FConsts, Length(FConsts)+1);
     Inc(FConstCount);
     if FConstCount>65535 then Succ:=Error(G2CE_CONSTCOUNT, [65535]);
    end;
   Break;
  end else if PeekChar=G2C_SrcEnd then begin
   Succ:=Error(G2CE_STRINGOPEN, []);
   Exit;
  end;
  Inc(FSrcPos);
 end;
 Inc(FSrcPos);
end;

function TG2Compiler.ReadNumber(var Succ: Boolean): string;
var StartPos: integer;
    IsFloat: Boolean;
    S, S2: string;
    IntVal: Int64;
begin
 StartPos:=FSrcPos;
 IsFloat:=False;
 while Succ do begin
  if (not IsFloat) and (PeekChar=G2C_DecimalPoint) then IsFloat:=True
   else if not (PeekChar in G2C_Numbers) then begin
    SetLength(S, FSrcPos-StartPos);
    CopyMemory(PChar(S), FSource+StartPos, FSrcPos-StartPos);
    if S='0' then Result:=Chr(G2CMD_CONSTZERO)
    else if S='1' then Result:=Chr(G2CMD_CONSTONE)
    else begin
     if IsFloat or (Length(S)>18) then begin
      if Length(S)>8 then begin
       SetLength(S2, SizeOf(TG2ConstNumHeader));
       with PG2ConstNumHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTFLOAT;
        Float:=StrToFloatDef(S, 0.0);
       end;
      end else begin
       SetLength(S2, SizeOf(TG2Const32BitHeader));
       with PG2Const32BitHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTFLT32;
        Float:=StrToFloatDef(S, 0.0);
       end;
      end;
     end else begin
      IntVal:=StrToInt64Def(S, 0);
      if Abs(IntVal)>2147483647 then begin
       SetLength(S2, SizeOf(TG2ConstNumHeader));
       with PG2ConstNumHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTINT;
        Int:=IntVal;
       end;
      end else if Abs(IntVal)>32767 then begin
       SetLength(S2, SizeOf(TG2Const32BitHeader));
       with PG2Const32BitHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTINT32;
        Int:=IntVal;
       end;
      end else if Abs(IntVal)>127 then begin
       SetLength(S2, SizeOf(TG2Const16BitHeader));
       with PG2Const16BitHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTINT16;
        Int:=IntVal;
       end;
      end else begin
       SetLength(S2, SizeOf(TG2Const8BitHeader));
       with PG2Const8BitHeader(PChar(S2))^ do begin
        Cmd:=G2CMD_CONSTINT8;
        Int:=IntVal;
       end;
      end;
     end;

     SetLength(Result, SizeOf(TG2ConstHeader));
     with PG2ConstHeader(PChar(Result))^ do begin
      Cmd:=G2CMD_CONST;
      Index:=FConstCount;
     end;
     Insert(S2, FConsts, Length(FConsts)+1);
     Inc(FConstCount);
     if FConstCount>65535 then Succ:=Error(G2CE_CONSTCOUNT, [65535]);
    end;
    Break;
   end;
  Inc(FSrcPos);
 end;
end;

procedure TG2Compiler.NeedSpace(const Size: integer);
begin
 if FDestLen-FDestPos<Size then begin
  FDestLen:=((FDestPos+Size+G2C_ALLOCBY-1) div G2C_ALLOCBY)*G2C_ALLOCBY;
  ReAllocMem(FDestination, FDestLen);
 end;
end;

procedure TG2Compiler.AddData(const Data; const Size: integer);
begin
 NeedSpace(Size);
 CopyMemory(FDestination+FDestPos, @Data, Size);
 Inc(FDestPos, Size);
end;

function TG2Compiler.Compile(const Src: string; const Dest: TStream): Boolean;
begin
 Source:=PChar(Src);
 SrcLen:=Length(Src);
 Result:=Compile;
 if Result then begin
  Dest.Write(Destination^, DestLen);
  FreeMem(Destination);
 end; 
end;

procedure TG2Compiler.IgnoreSpace;
begin
 while FSrcPos<FSrcLen do begin
  if FSource[FSrcPos]=G2C_LineComment[1] then if PeekStr(Length(G2C_LineComment))=G2C_LineComment then begin
   IgnoreComment(False);
   if FSrcPos>=FSrcLen then Exit;
  end;
  if not (FSource[FSrcPos] in G2C_WhiteSpaceChars) then Exit
   else if FSource[FSrcPos]=G2C_NewLine then begin
    Inc(FCurLine);
    FLineStart:=FSrcPos;
   end; 
  Inc(FSrcPos);
 end;
end;

procedure TG2Compiler.IgnoreComment(const Multiline: Boolean);
begin
 if Multiline then begin

 end else begin
  while FSrcPos<FSrcLen do begin
   if FSource[FSrcPos]=G2C_NewLine then Exit;
   Inc(FSrcPos);
  end;
 end;
end;

function TG2Compiler.GetErrorPos: integer;
begin
 Result:=FSrcPos-FLineStart;
end;

function TG2Compiler.AddStr(var Succ: Boolean; const S: string): integer;
begin
 Result:=integer(FStrTable.AddOrGet(Pointer(FStrTablePos), S));
 if Result=FStrTablePos then Inc(FStrTablePos, Length(S)+1);
 if FStrTablePos>=G2C_MaxStrTablePos then Succ:=Error(G2CE_STRTBLFULL, [G2C_MaxStrTablePos]);
end;

procedure TG2Compiler.WriteStrTable;
var I: integer;
    S: string;
begin
 for I:=0 to FStrTable.Count-1 do begin
  S:=FStrTable.Keys[FStrTable.KeyIndex(I)];
  AddData(PChar(S)^, Length(S)+1);
 end;
end;

procedure TG2Compiler.WriteFuncTable;
var I: integer;
begin
 for I:=Low(FFunctions) to High(FFunctions) do
  AddData(PChar(FFunctions[I])^, Length(FFunctions[I]));
end;

function TG2Compiler.PeekChar: Char;
begin
 if FSrcPos<FSrcLen then Result:=FSource[FSrcPos]
  else Result:=G2C_SrcEnd;
end;

function TG2Compiler.PeekStr(const Len: integer): string;
var Pos: integer;
begin
 Pos:=FSrcPos;
 Result:='';
 while (Pos<FSrcLen) and (Pos-FSrcPos<Len) do begin
  Result:=Result+FSource[Pos];
  Inc(Pos);
 end;
end;

function TG2Compiler.ExpectChar(var Succ: Boolean; C: Char): Boolean;
begin
 Result:=PeekChar=C;
 if (not Result) and Succ then Succ:=Error(G2CE_EXPECTCHAR, [CharName(C), CharName(PeekChar)]);
end;

function TG2Compiler.ExpectChar(var Succ: Boolean; C: TG2Chars): Boolean;
begin
 Result:=PeekChar in C;
 if (not Result) and Succ then Succ:=Error(G2CE_EXPECTCHAR, [CharList(C), CharName(PeekChar)]);
end;

function TG2Compiler.Error(const Code: integer; const Params: array of const): Boolean;
var S: string;
begin
 S:=FName;
 if S='' then S:='<main>';
 FErrorCode:=Code;
 FErrorText:=Format(G2E_MSG, [S, Format(G2E_ERRORPOS, [FCurLine, FSrcPos-FLineStart]), Format(G2CE_ERRORS[Code], Params)]);
 Result:=False;
end;

end.
