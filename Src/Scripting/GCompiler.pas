unit GCompiler;

interface

uses
  GTypes, GConsts, GBlocks, GVariants, Classes, SysUtils;

type
  TGCompiler = class
  private
    FScript: TGCustomScript;
    FBlock: TGCustomBlock;
    FSrc: ^string;
    FSize: integer;
    FPos: integer;
    function ExpectAll(Block: TGBContainer; out Successful: Boolean): Boolean;
    function ExpectStruct(Block: TGBContainer; out Successful: Boolean): Boolean;
    function ExpectFunction(Block: TGCustomBlock; out Successful: Boolean): TGCustomBlock;
    function ExpectValue(Block: TGCustomBlock; out Successful: Boolean; StopPriority: Byte): TGCustomBlock;
    function ExpectGetVariable(Block: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; out Successful: Boolean): TGCustomBlock;
    //function ExpectSetVariable(Block: TGCustomBlock; out Successful: Boolean): TGCustomBlock;
    function ExpectChar(const Chars: TGChars): Boolean; overload;
    function ExpectChar(Char: Char): Boolean; overload;
    function IsChar(const Chars: TGChars; IgnoreComment: Boolean = False): Boolean; overload;
    function IsChar(Char: Char; IgnoreComment: Boolean = False): Boolean; overload;
    function UnQuoteChars(const S: string; SimpleOnly: Boolean): string;
  public
    constructor Create(Block: TGCustomBlock; Script: TGCustomScript);
    function Compile(const Src: string; out Data: TGCustomBlock): Boolean;
  end;

function GetRegExp(Index: integer; const S: string): string;

implementation

function GetRegExp(Index: integer; const S: string): string;
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

function TGCompiler.UnQuoteChars(const S: string; SimpleOnly: Boolean): string;
var Pos, L: integer;
  function UnQuoteChar: Char;
  begin
   case S[Pos] of
    GC_QuoteTab: Result:=GC_Tab;
    GC_QuoteNewLine: Result:=GC_NewLine;
    GC_QuoteCarReturn: Result:=GC_CarReturn;
    GC_QuoteFormFeed: Result:=GC_FormFeed;
    GC_QuoteAlarm: Result:=GC_Alarm;
    GC_QuoteEscape: Result:=GC_Escape;
    GC_QuoteHexadecimal: begin 
     Result:=#0;
     Inc(Pos);
     if Pos>L then Exit;
     if S[Pos]=GC_QuoteHexOpen then begin // \x{nnnn}
      repeat
       Inc(Pos);
       if Pos>L then Exit;
       if S[Pos]<>GC_QuoteHexClose then begin
        if (Ord(Result) shr (SizeOf(Char)*8-4)) and $F<>0 then Exit;
        Result:=Char((Ord(Result) shl 4) or HexDig(S[Pos]));
       end else BREAK;
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
  if (Pos<L) and (S[Pos]=GC_ConstantQuote) then begin
   Inc(Pos);
   if SimpleOnly then begin
    if S[Pos]=GC_SimpleQuote then Result:=Result+S[Pos]
     else Result:=Result+S[Pos-1]+S[Pos];
   end else Result:=Result+UnQuoteChar;
  end else Result:=Result+S[Pos];
  Inc(Pos);
 end;
end;

{ TGCompiler }

function TGCompiler.Compile(const Src: string; out Data: TGCustomBlock): Boolean;
begin
 FSrc:=@Src;
 FSize:=Length(Src);
 FPos:=1;
 Data:=TGBContainer.Create(FBlock);
 while ExpectAll(TGBContainer(Data), Result) do
  Inc(FPos);
 if not Result then FreeAndNil(Data);
end;

constructor TGCompiler.Create(Block: TGCustomBlock; Script: TGCustomScript);
begin
 inherited Create;
 FBlock:=Block;
 FScript:=Script;
end;

function TGCompiler.ExpectAll(Block: TGBContainer; out Successful: Boolean): Boolean;
//var StartPos: integer;
begin
 Successful:=True;
 Result:=False;
 while FPos<=FSize do begin
  if IsChar(GC_StructChars) and ExpectStruct(Block, Successful) then begin
   Result:=Successful;
  end else if IsChar(GC_FuncFirstChars) then begin
   //Block.Add(ExpectFunction(Block, Successful));
   Block.Add(ExpectValue(Block, Successful, 0));
   if Successful then Successful:=ExpectChar([GC_Separator, GC_SrcEnd]);
   Result:=Successful;
  end else if IsChar(GC_VarFirstChar) then begin
   //Block.Add(ExpectSetVariable(Block, Successful));
   Block.Add(ExpectValue(Block, Successful, 0));
   if Successful then Successful:=ExpectChar([GC_Separator, GC_SrcEnd]);
   Result:=Successful;
  end {else if IsChar(GC_StringQuotes) then begin
   Inc(FPos);
   StartPos:=FPos;
   while not IsChar(GC_StringQuotes+[GC_SrcEnd]) do Inc(FPos);
   Block.Add(TGVString.Create(False, Copy(FSrc^, StartPos, FPos-StartPos)));
   Successful:=ExpectChar(GC_StringQuotes);
   Inc(FPos);                
   if Successful then Successful:=ExpectChar([GC_Separator, GC_SrcEnd]);
  end else if IsChar(GC_Numbers) then begin
   StartPos:=FPos;
   Inc(FPos);
   while IsChar(GC_Numbers) do Inc(FPos);
   if IsChar(GC_DecimalPoint) then begin
    Inc(FPos);
    while IsChar(GC_Numbers) do Inc(FPos);
    DecimalSeparator:=GC_DecimalPoint;
    Block.Add(TGVFloat.Create(False, StrToFloatDef(Copy(FSrc^, StartPos, FPos-StartPos), 0.0)));
   end else
    Block.Add(TGVInteger.Create(False, StrToIntDef(Copy(FSrc^, StartPos, FPos-StartPos), 0)));
   Successful:=True;
  end} else if IsChar(GC_FuncSrcClose) then begin
   Break;
  end else if not IsChar(GC_WhiteSpaceChars) then begin
   Successful:=False;
   FScript.Error(GE_IllegalChar, 'Illegal Character: "'+FSrc^[FPos]+'"', nil);
  end;
  Inc(FPos);
  if not Successful then Break;
 end;
end;

function TGCompiler.ExpectStruct(Block: TGBContainer; out Successful: Boolean): Boolean;

  procedure StructFunction;
  var StartPos: integer;
      Name: string;
      Params: array of string;
      SubProg: TGBSubProg;
  begin
    Params:=nil;
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    StartPos:=FPos;
    Successful:=ExpectChar(GC_FuncFirstChars);
    if not Successful then Exit;
    Inc(FPos);
    while IsChar(GC_FuncChars) do Inc(FPos);
    Name:=Copy(FSrc^, StartPos, FPos-StartPos);
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    Successful:=ExpectChar([GC_ParamListOpen, GC_FuncSrcOpen]);
    if IsChar(GC_ParamListOpen) then begin
     repeat
      Inc(FPos);
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      Successful:=ExpectChar(GC_VarFirstChar);
      if Successful then begin
       Inc(FPos);
       StartPos:=FPos;
       while IsChar(GC_VarChars) do Inc(FPos);
       SetLength(Params, High(Params)+2);
       Params[High(Params)]:=Copy(FSrc^, StartPos, FPos-StartPos);
       while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
       Successful:=ExpectChar([GC_ParamListClose, GC_ParamListDelimiter]);
      end;
     until (not Successful) or IsChar(GC_ParamListClose);
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    end;
    Successful:=ExpectChar(GC_FuncSrcOpen);
    if Successful then begin
     SubProg:=TGBSubProg.Create(Block, Name, Params);
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     if not IsChar(GC_FuncSrcClose) then ExpectAll(SubProg, Successful);
     Block.Add(SubProg);
     if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
    end;
  end;

  procedure StructIf;
  var StartPos: integer;
      IfBlock: TGBIf;
      List: Boolean;
  begin
    IfBlock:=TGBIf.Create(Block, nil);
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    List:=IsChar(GC_ParamListOpen);
    if List then begin
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    end;
    IfBlock.Exp:=ExpectValue(IfBlock, Successful, 0);
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    if Successful and List then begin
     Successful:=ExpectChar(GC_ParamListClose);
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    end;
    if Successful then begin
     Successful:=ExpectChar(GC_FuncSrcOpen);
     Inc(FPos);
     if Successful then begin
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      if not IsChar(GC_FuncSrcClose) then ExpectAll(IfBlock, Successful);
      if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
     end;
    end;
    if Successful then begin
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     StartPos:=FPos;
     while IsChar(GC_StructChars) do Inc(FPos);
     if AnsiLowerCase(Copy(FSrc^, StartPos, FPos-StartPos))=GC_ElseId then begin
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      Successful:=ExpectChar(GC_FuncSrcOpen);
      Inc(FPos);
      if Successful then begin
       while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
       if not IsChar(GC_FuncSrcClose) then begin
        IfBlock.ElseSrc:=TGBContainer.Create(IfBlock);
        ExpectAll(IfBlock.ElseSrc, Successful);
        if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
       end;
      end;
      Block.Add(IfBlock);
     end else if AnsiLowerCase(Copy(FSrc^, StartPos, FPos-StartPos))=GC_ElseIfId then begin
      Block.Add(IfBlock);
      IfBlock.ElseSrc:=TGBContainer.Create(IfBlock);
      Block:=IfBlock.ElseSrc;
      StructIf;
     end else begin
      Block.Add(IfBlock);
      FPos:=StartPos-1;
     end;
    end;
  end;

  procedure StructFor;
  var ForBlock: TGBFor;
      List: Boolean;
  begin
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    List:=IsChar(GC_ParamListOpen);
    if List then Inc(FPos);
    if Successful then begin
     ForBlock:=TGBFor.Create(Block);
     ForBlock.Init:=ExpectValue(ForBlock, Successful, 0);
     if Successful then Successful:=ExpectChar(GC_Separator);
     Inc(FPos);
     if Successful then ForBlock.Cond:=ExpectValue(ForBlock, Successful, 0);
     if Successful then Successful:=ExpectChar(GC_Separator);
     Inc(FPos);
     if Successful then ForBlock.Step:=ExpectValue(ForBlock, Successful, 0);
     if Successful and List then begin
      Successful:=ExpectChar(GC_ParamListClose);
      Inc(FPos);
     end;
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     Successful:=ExpectChar(GC_FuncSrcOpen);
     if Successful then begin
      Inc(FPos);
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      if not IsChar(GC_FuncSrcClose) then ExpectAll(ForBlock, Successful);
      if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
      if Successful then Block.Add(ForBlock);
     end;
    end;
  end;

  procedure StructWhile;
  var WhileBlock: TGBWhile;
      List: Boolean;
  begin
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    List:=IsChar(GC_ParamListOpen);
    if List then Inc(FPos);
    if Successful then begin
     WhileBlock:=TGBWhile.Create(Block);
     if Successful then WhileBlock.Cond:=ExpectValue(WhileBlock, Successful, 0);
     if Successful and List then begin
      Successful:=ExpectChar(GC_ParamListClose);
      Inc(FPos);
     end;
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     Successful:=ExpectChar(GC_FuncSrcOpen);
     if Successful then begin
      Inc(FPos);
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      if not IsChar(GC_FuncSrcClose) then ExpectAll(WhileBlock, Successful);
      if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
      if Successful then Block.Add(WhileBlock);
     end;
    end;
  end;

  procedure StructRepeat;
  var RepeatBlock: TGBRepeat;
      List: Boolean;
  begin
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    Successful:=ExpectChar(GC_FuncSrcOpen);
    if Successful then begin
     RepeatBlock:=TGBRepeat.Create(Block);
     Inc(FPos);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     if not IsChar(GC_FuncSrcClose) then ExpectAll(RepeatBlock, Successful);
     if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
     Inc(FPos);
     if Successful then Block.Add(RepeatBlock);
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     List:=IsChar(GC_ParamListOpen);
     if List then Inc(FPos);
     if Successful then begin
      if Successful then RepeatBlock.Cond:=ExpectValue(RepeatBlock, Successful, 0);
      if Successful and List then begin
       Successful:=ExpectChar(GC_ParamListClose);
       Inc(FPos);
      end;
      if Successful then ExpectChar(GC_Separator);
     end;
    end;
  end;

  procedure StructForeach;
  var ForeachBlock: TGBForeach;
      List: Boolean;
  begin
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    List:=IsChar(GC_ParamListOpen);
    if List then Inc(FPos);
    if Successful then begin
     ForeachBlock:=TGBForeach.Create(Block);
     if Successful then ForeachBlock.Src:=ExpectValue(ForeachBlock, Successful, 0);
     if Successful and List then begin
      Successful:=ExpectChar(GC_ParamListClose);
      Inc(FPos);
     end;
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     if Successful then Successful:=ExpectChar(GC_FuncSrcOpen);
     if Successful then begin
      Inc(FPos);
      while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
      if not IsChar(GC_FuncSrcClose) then ExpectAll(ForeachBlock, Successful);
      if Successful then Successful:=ExpectChar(GC_FuncSrcClose);
      if Successful then Block.Add(ForeachBlock);
     end;
    end;
  end;

  procedure StructReturn;
  var ReturnBlock: TGBReturn;
      List: Boolean;
  begin
    while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
    List:=IsChar(GC_ParamListOpen);
    if List then Inc(FPos);
    if Successful then begin
     ReturnBlock:=TGBReturn.Create(Block);
     if Successful then ReturnBlock.Src:=ExpectValue(ReturnBlock, Successful, 0);
     if Successful and List then begin
      Successful:=ExpectChar(GC_ParamListClose);
      Inc(FPos);
     end;
     while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
     if Successful then ExpectChar(GC_Separator);
     if Successful then Block.Add(ReturnBlock);
    end;
  end;

var StartPos, I: integer;
    S: string;
begin
 Result:=False;
 if not IsChar(GC_StructChars) then Exit;
 Successful:=True;
 StartPos:=FPos;
 Inc(FPos);
 while IsChar(GC_StructChars) do Inc(FPos);
 S:=AnsiLowerCase(Copy(FSrc^, StartPos, FPos-StartPos));
 for I:=0 to Ord(gstNone) do
  if S=GC_StructureId[TGStructureType(I)] then begin
   Result:=True;
   case TGStructureType(I) of
    gstFunction: StructFunction;
    gstIf: StructIf;
    gstFor: StructFor;
    gstWhile: StructWhile;
    gstRepeat: StructRepeat;
    gstForeach: StructForeach;
    gstReturn: StructReturn;
   end;
   Exit;
  end;
 FPos:=StartPos;
end;

function TGCompiler.ExpectFunction(Block: TGCustomBlock; out Successful: Boolean): TGCustomBlock;
var StartPos: integer;
    NeedClose, TempBool: Boolean;
    Src: array of TGCustomBlock;
    S: string;
    I: integer;
  procedure FunctionGlobal(Local: Boolean);
  begin
   NeedClose:=IsChar(GC_ParamListOpen);
   if NeedClose then Inc(FPos);
   while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
   Successful:=ExpectChar(GC_VarFirstChar);
   if Successful then Result:=ExpectGetVariable(Block, not Local, Local, Successful);
   if Successful then if NeedClose then begin
    Successful:=ExpectChar([GC_ParamListDelimiter, GC_ParamListClose]);
    Inc(FPos);
   end;
  end;
begin
 Successful:=True;
 StartPos:=FPos;
 TempBool:=False;
 Src:=nil;
 Inc(FPos);
 while IsChar(GC_FuncChars) do Inc(FPos);
 S:=Copy(FSrc^, StartPos, FPos-StartPos);
 while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
 for I:=0 to Ord(gftNone) do
  if S=GC_FunctionId[TGFunctionType(I)] then begin
   case TGFunctionType(I) of
    gftGlobal: FunctionGlobal(False);
    gftLocal: FunctionGlobal(True);
   end;
   Exit;
  end;

 Result:=TGBFuncCall.Create(Block, S, []);
 if not IsChar([GC_Separator, GC_SrcEnd, GC_ParamListClose, GC_ParamListDelimiter, GC_FuncSrcOpen, GC_FuncSrcClose] + GC_OperatorChars) then begin
  NeedClose:=IsChar(GC_ParamListOpen);
  if NeedClose then Inc(FPos);
  repeat
   while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
   SetLength(Src, High(Src)+2);
   Src[High(Src)]:=ExpectValue(Result, Successful, 0);
   if not Successful then Break;
   while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
   if NeedClose then Successful:=ExpectChar([GC_ParamListDelimiter, GC_ParamListClose])
    else Successful:=ExpectChar([GC_ParamListDelimiter, GC_Separator, GC_SrcEnd]);
   TempBool:=IsChar(GC_ParamListDelimiter);
   if TempBool then Inc(FPos);
  until (not Successful) or (not TempBool);
  TGBFuncCall(Result).SetParams(Src);
  if NeedClose then begin
   Inc(FPos);
   while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
  end;
 end;
 if not Successful then FreeAndNil(Result);
end;

function TGCompiler.ExpectValue(Block: TGCustomBlock; out Successful: Boolean; StopPriority: Byte): TGCustomBlock;
var StartPos, I: integer;
    S: string;
    Ch: Char;
    Operator: TGOperatorType;
    GetValue: TGBGetValue;
begin
 Result:=nil;
 //Result:=TGBGetValue.Create(Block);
 Successful:=True;
 Operator:=gotNone;
 while Successful do begin
  if IsChar(GC_OperatorChars) then begin
   if (Operator=gotNone) then begin
    StartPos:=FPos;
    Inc(FPos);
    while IsChar(GC_OperatorChars) do Inc(FPos);
    S:=Copy(FSrc^, StartPos, FPos-StartPos);
    Operator:=gotNone;
    for I:=0 to Ord(gotNone) do
     if GC_OperatorId[TGOperatorType(I)]=S then Operator:=TGOperatorType(I);
    if GC_OperatorPriority[Operator]<=StopPriority then begin
     FPos:=StartPos;
     Operator:=gotNone;
     Break;
    end;
    if Result=nil then Result:=TGBGetValue.Create(Block)
     else if not (Result is TGBGetValue) then begin
      GetValue:=TGBGetValue.Create(Block);
      if Result is TGBlock then TGBlock(Result).Parent:=GetValue;
      GetValue.Add(GValueData(gotNone, Result));
      Result:=GetValue;
     end;
   end else begin
    TGBGetValue(Result).Add(GValueData(Operator, ExpectValue(Result, Successful, GC_OperatorPriority[Operator])));
    Operator:=gotNone;
   end;
  end else if IsChar(GC_CountPrefix) then begin
   if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, TGBFuncCall.Create(Block, 'Count', [ExpectGetVariable(Block, False, False, Successful)])))
    else if Result=nil then Result:=TGBFuncCall.Create(Block, 'Count', [ExpectGetVariable(Block, False, False, Successful)]);
   Operator:=gotNone;
  end else if IsChar(GC_FuncFirstChars) then begin
   if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, ExpectFunction(Block, Successful)))
    else if Result=nil then Result:=ExpectFunction(Block, Successful);
   Operator:=gotNone;
  end else if IsChar(GC_VarFirstChar) then begin
   if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, ExpectGetVariable(Block, False, False, Successful)))
     else if Result=nil then Result:=ExpectGetVariable(Block, False, False, Successful);      
   Operator:=gotNone;
  end else if IsChar(GC_StringQuotes) then begin
   Ch:=FSrc^[FPos];
   StartPos:=FPos+1;
   repeat
    Inc(FPos);
    if IsChar(GC_ConstantQuote, True) then Inc(FPos,2);
   until IsChar([Ch, GC_SrcEnd], True);
   if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, TGVString.Create(False, True, UnQuoteChars(Copy(FSrc^, StartPos, FPos-StartPos), Ch=GC_SimpleQuote))))
     else if Result=nil then Result:=TGVString.Create(False, True, UnQuoteChars(Copy(FSrc^, StartPos, FPos-StartPos), Ch=GC_SimpleQuote));
   Successful:=ExpectChar(GC_StringQuotes);
   Inc(FPos);
   Operator:=gotNone;
  end else if IsChar(GC_ConstantQuote) then begin
   StartPos:=FPos;
   Inc(FPos, 2);
   while IsChar(GC_QuoteHexChars) do Inc(FPos);
   if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, TGVString.Create(False, True, UnQuoteChars(Copy(FSrc^, StartPos, FPos-StartPos), False))))
     else if Result=nil then Result:=TGVString.Create(False, True, UnQuoteChars(Copy(FSrc^, StartPos, FPos-StartPos), False));
   Operator:=gotNone;
  end else if IsChar(GC_Numbers) then begin
   StartPos:=FPos;
   Inc(FPos);
   while IsChar(GC_Numbers) do Inc(FPos);
   if IsChar(GC_DecimalPoint) then begin
    Inc(FPos);
    while IsChar(GC_Numbers) do Inc(FPos);
    DecimalSeparator:=GC_DecimalPoint;
    if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, TGVFloat.Create(False, True, StrToFloatDef(Copy(FSrc^, StartPos, FPos-StartPos), 0.0))))
     else if Result=nil then Result:=TGVFloat.Create(False, True, StrToFloatDef(Copy(FSrc^, StartPos, FPos-StartPos), 0.0));
   end else                                                
    if Result is TGBGetValue then TGBGetValue(Result).Add(GValueData(Operator, TGVInteger.Create(False, True, StrToInt64Def(Copy(FSrc^, StartPos, FPos-StartPos), 0))))
     else if Result=nil then Result:=TGVInteger.Create(False, True, StrToInt64Def(Copy(FSrc^, StartPos, FPos-StartPos), 0));
   Successful:=True;
   Operator:=gotNone;
  end else if IsChar(GC_ParamListOpen) then begin
   Inc(FPos);
   if Result=nil then Result:=TGBGetValue.Create(Block);
   {if Result is TGBGetValue then} TGBGetValue(Result).Add(GValueData(Operator, ExpectValue(Result, Successful, 0)));
    //else if Result=nil then Result:=ExpectValue(Block, Successful, 0);
   if Successful then Successful:=ExpectChar(GC_ParamListClose);
   Inc(FPos);
   Operator:=gotNone;
  end else if Result=nil then begin
   if IsChar(GC_SrcEnd) then begin
    Successful:=False;
    FScript.Error(GE_UnexpectedEnd, 'Value expected but end of script found.', nil);
   end else if not IsChar(GC_WhiteSpaceChars) then begin
    Successful:=False;
    FScript.Error(GE_IllegalChar, 'Value expected but '#39+FSrc^[FPos]+#39' found.', nil);
   end else Inc(FPos);
  end else if IsChar([GC_SrcEnd, GC_Separator, GC_ParamListDelimiter, GC_ParamListClose, GC_FuncSrcOpen, GC_FuncSrcClose, GC_KeyClose, GC_IndexClose]) then Break else Inc(FPos);
  while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
 end;
 if not Successful then FreeAndNil(Result)
  else if Result is TGBGetValue then begin
   if Operator<>gotNone then TGBGetValue(Result).Add(GValueData(Operator, nil));
   TGBGetValue(Result).Compile;
  end;
end;

function TGCompiler.ExpectGetVariable(Block: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; out Successful: Boolean): TGCustomBlock;
var StartPos: integer;
    Name: string;
    Keys: array of TGVariableKey;
begin
 Successful:=True;
 Inc(FPos);
 StartPos:=FPos;
 Keys:=nil;
 while IsChar(GC_VarChars) do Inc(FPos);
 Name:=Copy(FSrc^, StartPos, FPos-StartPos);
 while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
 while (IsChar(GC_VarKeyDelimiter) or IsChar(GC_KeyOpen) or IsChar(GC_IndexOpen)) and Successful do begin
  if IsChar(GC_IndexOpen) then begin
   Inc(FPos);
   SetLength(Keys, High(Keys)+2);
   Keys[High(Keys)]:=GVariableKey(grtInteger, ExpectValue(Block, Successful, 0));
   if Successful then Successful:=ExpectChar(GC_IndexClose);
   Inc(FPos);
  end else if IsChar(GC_KeyOpen) then begin
   Inc(FPos);
   SetLength(Keys, High(Keys)+2);
   Keys[High(Keys)]:=GVariableKey(grtString, ExpectValue(Block, Successful, 0));
   if Successful then Successful:=ExpectChar(GC_KeyClose);
   Inc(FPos);
  end else begin
   Inc(FPos);
   StartPos:=FPos;
   while IsChar(GC_VarChars) do Inc(FPos);
   SetLength(Keys, High(Keys)+2);
   Keys[High(Keys)]:=GVariableKey(grtString, TGVString.Create(False, True, Copy(FSrc^, StartPos, FPos-StartPos)));
  end;
  while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
 end;
 if Keys<>nil then Result:=TGBGetKeyedVar.Create(Block, ForceGlobal, ForceLocal, Name, Keys)
   else Result:=TGBGetVar.Create(Block, ForceGlobal, ForceLocal, Name);
end;

{function TGCompiler.ExpectSetVariable(Block: TGCustomBlock; out Successful: Boolean): TGCustomBlock;
var StartPos: integer;
    Name: string;
    Keys: array of TGCustomBlock;
begin
 Result:=nil;
 Inc(FPos);
 StartPos:=FPos;
 Keys:=nil;
 while IsChar(GC_VarChars) do Inc(FPos);
 Name:=Copy(FSrc^, StartPos, FPos-StartPos);
 while IsChar(GC_VarKeyDelimiter) do begin
  Inc(FPos);
  StartPos:=FPos;
  while IsChar(GC_VarChars) do Inc(FPos);
  SetLength(Keys, High(Keys)+2);
  Keys[High(Keys)]:=TGVString.Create(False, Copy(FSrc^, StartPos, FPos-StartPos));
 end;
 while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
 Successful:=ExpectChar([GC_Separator, GC_SrcEnd, GC_VarAssign]);
 if Successful then
  if IsChar(GC_VarAssign) then begin
   Inc(FPos);
   while IsChar(GC_WhiteSpaceChars) do Inc(FPos);
   if Keys<>nil then begin
    Result:=TGBSetKeyedVar.Create(Block, Name, nil, Keys);
    TGBSetKeyedVar(Result).Src:=ExpectValue(Result, Successful);
   end else begin
    Result:=TGBSetVar.Create(Block, Name, nil);
    TGBSetVar(Result).Src:=ExpectValue(Result, Successful);
   end;
  end else if Keys<>nil then Result:=TGBGetKeyedVar.Create(Block, Name, Keys)
   else Result:=TGBGetVar.Create(Block, Name);
 if not Successful then FreeAndNil(Result);
end;}

function TGCompiler.ExpectChar(const Chars: TGChars): Boolean;
  procedure Error;
  var I: Char;
      S: string;
  begin
   S:='';
   for I:=#255 downto #1 do
    if I in Chars then begin
     if Length(S)=3 then S:=' or '+S
      else if S<>'' then S:=', '+S;
     S:=#39+I+#39+S;
    end;
   if FPos>FSize then FScript.Error(GE_ExpectedChar, S+' expected but end of script found.', nil)
    else FScript.Error(GE_ExpectedChar, S+' expected but '#39+FSrc^[FPos]+#39' found.', nil);
  end;
begin
 Result:=IsChar(Chars);
 if not Result then Error;
end;

function TGCompiler.ExpectChar(Char: Char): Boolean;
  procedure Error;
  begin
   if FPos>FSize then FScript.Error(GE_ExpectedChar, Char+' expected but end of script found.', nil)
    else FScript.Error(GE_ExpectedChar, Char+' expected but '#39+FSrc^[FPos]+#39' found.', nil);
  end;
begin
 Result:=IsChar(Char);
 if not Result then Error;
end;

function TGCompiler.IsChar(const Chars: TGChars; IgnoreComment: Boolean = False): Boolean;
begin
 if FPos>FSize then Result:=GC_SrcEnd in Chars
  else begin
   Result:=FSrc^[FPos] in Chars;
   if not (Result or IgnoreComment) then if FSrc^[FPos]=GC_Comment[1] then if FPos<=FSize-Length(GC_Comment)+1 then
    if Copy(FSrc^, FPos, Length(GC_Comment))=GC_Comment then
     while not IsChar([GC_NewLine, GC_SrcEnd], True) do Inc(FPos);
  end;
end;

function TGCompiler.IsChar(Char: Char; IgnoreComment: Boolean = False): Boolean;
begin
 if FPos>FSize then Result:=GC_SrcEnd=Char
  else begin
   Result:=FSrc^[FPos]=Char;
   if not (Result or IgnoreComment) then if FSrc^[FPos]=GC_Comment[1] then if FPos<=FSize-Length(GC_Comment)+1 then
    if Copy(FSrc^, FPos, Length(GC_Comment))=GC_Comment then
     while not IsChar([GC_NewLine, GC_SrcEnd], True) do Inc(FPos);
  end;
end;

end.

