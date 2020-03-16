unit GCore;

interface

uses
  GTypes, GConsts, GBlocks, GVariants, GCompiler, Classes, SysUtils, Windows;

type
  TGMCore = class(TGCustomModule)
  private
    function Use(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Include(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Eval(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function GetFalse(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetTrue(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function GetBool(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetInt(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetFloat(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetStr(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetArray(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetChr(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function GetOrd(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function Count(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Keys(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Sort(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Join(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function IsSet(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function UnSet(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function Call(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function IsIndexed(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function IsKeyed(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    procedure Unload; override;
  end;

implementation

constructor TGMCore.Create(Script: TGCustomScript);
begin
 inherited;
 FScript.RegisterFunction('Use', Use); // Use(S1, S2, ... , Sn);
 FScript.RegisterFunction('Include', Include); // $X = Include(S1, S2, ... , Sn);
 FScript.RegisterFunction('Eval', Eval); // $X = Eval(S);

 FScript.RegisterFunction(GC_BooleanStr[False], GetFalse); // $B = False;
 FScript.RegisterFunction(GC_BooleanStr[True], GetTrue); // $B = True;

 FScript.RegisterFunction('Bool', GetBool); // $B = Bool(X);
 FScript.RegisterFunction('Int', GetInt); // $I = Int(X);
 FScript.RegisterFunction('Float', GetFloat); // $F = Float(X);
 FScript.RegisterFunction('Str', GetStr); // $S = Str(X);
 FScript.RegisterFunction('Array', GetArray); // $A = Array(X1, X2, ... , Xn);
 FScript.RegisterFunction('Chr', GetChr); // $S = Chr(I);
 FScript.RegisterFunction('Ord', GetOrd); // $I = Ord(S);

 FScript.RegisterFunction('Count', Count); // $I = Count(A/S);
 FScript.RegisterFunction('Keys', Keys); // $A = Keys(A);
 FScript.RegisterFunction('Sort', Sort); // $A = Sort(A);
 FScript.RegisterFunction('Join', Join); // $S = Join(A);

 FScript.RegisterFunction('IsSet', IsSet); // $B = IsSet($X);
 FScript.RegisterFunction('UnSet', UnSet); // UnSet($X);
 FScript.RegisterFunction('Call', Call); // $X = Call(S, X1, X2, ... , Xn);
 FScript.RegisterFunction('IsIndexed', IsIndexed); // $B = IsIndexed(X);
 FScript.RegisterFunction('IsKeyed', IsKeyed); // $B = IsKeyed(X);
end;

procedure TGMCore.Unload;
begin
 FScript.UnregisterFunction('IsKeyed');
 FScript.UnregisterFunction('IsIndexed');
 FScript.UnregisterFunction('Call');
 FScript.UnregisterFunction('UnSet');
 FScript.UnregisterFunction('IsSet');

 FScript.UnregisterFunction('Join');
 FScript.UnregisterFunction('Sort');
 FScript.UnregisterFunction('Keys');
 FScript.UnregisterFunction('Count');

 FScript.UnregisterFunction('Ord');
 FScript.UnregisterFunction('Chr');
 FScript.UnregisterFunction('Array');
 FScript.UnregisterFunction('Str');
 FScript.UnregisterFunction('Float');
 FScript.UnregisterFunction('Int');
 FScript.UnregisterFunction('Bool');

 FScript.UnregisterFunction(GC_BooleanStr[True]);
 FScript.UnregisterFunction(GC_BooleanStr[False]);

 FScript.UnregisterFunction('Eval');
 FScript.UnregisterFunction('Include');
 FScript.UnregisterFunction('Use');
end;

function TGMCore.GetFalse(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=-1;
 if Result then Result:=Block.Return(TGVBoolean.Create(True, False, False));
end;

function TGMCore.GetTrue(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=-1;
 if Result then Result:=Block.Return(TGVBoolean.Create(True, False, True));
end;

function TGMCore.Use(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I, J: integer;
begin
 Result:=False;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtString]);
  if Result then begin
   Result:=False;
   for J:=0 to GModuleCount-1 do
    if GModule(J).Name=AnsiLowerCase(Params[I].Result.ResultStr) then begin
     Result:=True;
     FScript.LoadModule(GModule(J).Module);
    end;
   if Params[I].Result.Temp then Params[I].Result.Free; 
  end;
  if not Result then Break;
 end;
end;

function TGMCore.Count(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtString, grtArray, grtDefault]);
 if Result then begin
  Result:=Params[0].Result.Indexed;
  if Result then Block.Return(TGVInteger.Create(True, False, Params[0].Result.Count));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.GetBool(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)<=0;
 if High(Params)<0 then Block.Return(TGVBoolean.Create(True, False, False))
  else begin
   if Result then Result:=Params[0].Execute([grtBoolean]);
   if Result then if Params[0].Result.DefaultType=grtBoolean then Block.Return(Params[0].Result)
    else begin
     Block.Return(TGVBoolean.Create(True, False, Params[0].Result.ResultBool));
     if Params[0].Result.Temp then Params[0].Result.Free;
    end;
  end;
end;

function TGMCore.GetFloat(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)<=0;
 if High(Params)<0 then Block.Return(TGVFloat.Create(True, False, 0.0))
  else begin
   if Result then Result:=Params[0].Execute([grtFloat]);
   if Result then if Params[0].Result.DefaultType=grtFloat then Block.Return(Params[0].Result)
    else begin
     Block.Return(TGVFloat.Create(True, False, Params[0].Result.ResultFloat));
     if Params[0].Result.Temp then Params[0].Result.Free;
    end;
  end;
end;

function TGMCore.GetInt(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)<=0;
 if High(Params)<0 then Block.Return(TGVInteger.Create(True, False, 0))
  else begin
   if Result then Result:=Params[0].Execute([grtInteger]);
   if Result then if Params[0].Result.DefaultType=grtInteger then Block.Return(Params[0].Result)
    else begin
     Block.Return(TGVInteger.Create(True, False, Params[0].Result.ResultInt));
     if Params[0].Result.Temp then Params[0].Result.Free;
    end;
  end;
end;

function TGMCore.GetStr(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)<=0;
 if High(Params)<0 then Block.Return(TGVString.Create(True, False, ''))
  else begin
   if Result then Result:=Params[0].Execute([grtString]);
   if Result then if Params[0].Result.DefaultType=grtString then Block.Return(Params[0].Result)
    else begin
     Block.Return(TGVString.Create(True, False, Params[0].Result.ResultStr));
     if Params[0].Result.Temp then Params[0].Result.Free;
    end;
  end;
end;

function TGMCore.GetArray(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var V: TGVArray;
    I: integer;
begin
 Result:=True;
 V:=TGVArray.Create(True, False, []);
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtDefault]);
  if Result then begin
   if Params[I].Result.Temp then Result:=V.SetItem(I, Params[I].Result)
    else Result:=V.SetItem(I, Params[I].Result.Copy);
  end;
  if not Result then Break;
 end;
 if Result then Block.Return(V) else V.Free;
end;

function TGMCore.Keys(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtArray]);
 if Result then Result:=Params[0].Result.Keyed;
 if Result then Result:=Block.Return(Params[0].Result.Keys);
 if Result then if Params[0].Result.Temp then Params[0].Result.Free;
end;

function TGMCore.IsSet(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0] is TGBVariable;
 FScript.SilentError:=FScript.SilentError+1;
 if Result then Block.Return(TGVBoolean.Create(True, False, Params[0].Execute([grtDefault])));
 FScript.SilentError:=FScript.SilentError-1;
end;

function TGMCore.UnSet(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0] is TGBVariable;
 if Result then Result:=TGBVariable(Params[0]).SetSrc(nil);
end;

function TGMCore.Call(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Func: TGFunction;
    FuncParams: array of TGCustomBlock;
    I: integer;
begin
 Result:=High(Params)>=0;
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  Func:=nil;
  if TGBlock(Block).SubScript<>nil then Func:=TGBlock(Block).SubScript.GetFunction(Params[0].Result.ResultStr);
  if not Assigned(Func) then Func:=FScript.GetFunction(Params[0].Result.ResultStr);
  Result:=Assigned(Func);
  if Result then begin
   SetLength(FuncParams, High(Params));
   for I:=1 to High(Params) do
    FuncParams[I-1]:=Params[I];
   Result:=Func(Block, ResultType, FuncParams);
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.Eval(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Data: TGCustomBlock;
    V: TGCustomVariant;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  with TGCompiler.Create(Block, FScript) do begin
   Result:=Compile(Params[0].Result.ResultStr, Data);
   if Result then Result:=Data.Execute(ResultType);
   if Result then if ResultType<>[grtNone] then
    if Data.Result.Temp then Block.Return(Data.Result)
     else begin
      V:=Data.Result.Copy;
      V.Temp:=True;
      Block.Return(V);
     end;
   Data.Free;
   Free;
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.GetChr(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtInteger]);
 if Result then begin
  Result:=Block.Return(TGVString.Create(True, False, Chr(Params[0].Result.ResultInt)));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.GetOrd(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  Result:=Params[0].Result.ResultStr<>'';
  if Result then Result:=Block.Return(TGVInteger.Create(True, False, Ord(Params[0].Result.ResultStr[1])));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.Join(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I: integer;
    GS: GString;
    Item: TGCustomVariant;
begin
 Result:=High(Params)=1;
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then Result:=Params[1].Execute([grtArray]);
 if Result then begin
  Result:=Params[1].Result.Indexed;
  if Result then begin
   if Params[1].Result.Count>0 then begin
    Params[1].Result.GetItem(0, Item);
    GS:=Item.ResultStr;
   end else GS:='';
   for I:=1 to Params[1].Result.Count-1 do begin
    Params[1].Result.GetItem(I, Item);
    GS:=GS+Params[0].Result.ResultStr+Item.ResultStr;
   end;
   Result:=Block.Return(TGVString.Create(True, False, GS));
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
  if Params[1].Result.Temp then Params[1].Result.Free;
 end;
end;    

function TGMCore.Include(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var Data: TGCustomBlock;
    S: string;
    I: integer;
    Src: TStrings;
begin
 Result:=High(Params)>=0;
 if Result then
  for I:=Low(Params) to High(Params) do begin
   Result:=Params[I].Execute([grtString]);
   if Result then begin
    if Assigned(FScript.OnLoad) then Result:=FScript.OnLoad(Params[I].Result.ResultStr, S)
     else begin
      Result:=GFindFile(Params[I].Result.ResultStr, S);
      if Result then begin
       Src:=TStringList.Create;
       Src.LoadFromFile(S);
       S:=Src.Text;
       Src.Free;
      end;
     end;
    if Params[I].Result.Temp then Params[I].Result.Free;
   end;
   if Result then begin
    with TGCompiler.Create(FScript.AbstractSrc, FScript) do begin
     Result:=Compile(S, Data);
     TGBContainer(FScript.AbstractSrc).Add(Data);
     if Result then Result:=Data.Execute(ResultType);
     if Result then Block.Return(Data.Result);
     Free;
    end;
   end;
  end;
end;

function TGMCore.Sort(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var V: TGCustomVariant;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtArray]);
 if Result then Result:=Params[0].Result.Indexed;
 if Result then begin
  if Params[0].Result.Temp then V:=Params[0].Result
   else begin
    V:=Params[0].Result.Copy;
    V.Temp:=True;
   end;
  Result:=V.Sort;
  if Result then Result:=Block.Return(V);
 end;
end;

function TGMCore.IsIndexed(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtDefault]);
 if Result then begin
  Result:=Block.Return(TGVBoolean.Create(True, False, Params[0].Result.Indexed));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

function TGMCore.IsKeyed(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtDefault]);
 if Result then begin
  Result:=Block.Return(TGVBoolean.Create(True, False, Params[0].Result.Keyed));
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

initialization
GRegisterDefaultModule('Core', TGMCore);
end.
