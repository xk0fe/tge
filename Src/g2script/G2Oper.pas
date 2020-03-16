unit G2Oper;

interface

uses
  Windows, G2Types, G2Consts, G2Execute, Math;

function G2OperationBoth(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;
function G2OperationLeft(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;
function G2OperationRight(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;

type
  TG2OperProc = function(const Self: TG2Execute; var Succ: Boolean): TG2Variant;

var OperBothProcs: array[TG2OperatorType] of TG2OperProc;
var OperRightProcs: array[TG2OperatorType] of TG2OperProc;
var OperLeftProcs: array[TG2OperatorType] of TG2OperProc;

implementation

uses
  G2Script;

function G2OperationBoth(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;
begin
 if Assigned(OperBothProcs[Oper]) then Result:=OperBothProcs[Oper](Self, Succ)
  else begin Result:=nil; Succ:=False; end;
end;

function G2OperationLeft(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;
begin
 if Assigned(OperLeftProcs[Oper]) then Result:=OperLeftProcs[Oper](Self, Succ)
  else begin Result:=nil; Succ:=False; end;
end;

function G2OperationRight(const Self: TG2Execute; var Succ: Boolean; const Oper: TG2OperatorType): TG2Variant;
begin
 if Assigned(OperRightProcs[Oper]) then Result:=OperRightProcs[Oper](Self, Succ)
  else begin Result:=nil; Succ:=False; end;
end;

// Both Procs

function CombineArrays(const Arr1, Arr2: G2Array): G2Array;
var I, L1, L2: integer;
begin
 L1:=Length(Arr1);
 L2:=Length(Arr2);
 SetLength(Result, L1+L2);
 for I:=0 to L1-1 do
  Result[I]:=Arr1[I];
 for I:=0 to L2-1 do
  Result[L1+I]:=Arr2[I];
end;

function G2OperBoth_Add(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Left.Int+Right.Int, Left, Right);
  gvtFloat: Result:=G2Var(Left.Float+Right.Float, Left, Right);
  gvtString: Result:=G2Var(Left.Str+Right.Str, Left, Right);
  gvtArray: Result:=G2Var(CombineArrays(Left.Arr, Right.Arr), Left, Right);
  else Result:=G2Var(Left.Float+Right.Float, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Subtract(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Left.Int-Right.Int, Left, Right);
  gvtFloat: Result:=G2Var(Left.Float-Right.Float, Left, Right);
  else Result:=G2Var(Left.Float-Right.Float, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Multiply(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Left.Int*Right.Int, Left, Right);
  gvtFloat: Result:=G2Var(Left.Float*Right.Float, Left, Right);
  else Result:=G2Var(Left.Float*Right.Float, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Divide(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: if Right.Int=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result:=G2Var(Left.Int div Right.Int, Left, Right);
  gvtFloat: if Right.Float=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
             else Result:=G2Var(Left.Float/Right.Float, Left, Right);
  else if Right.Float=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
        else Result:=G2Var(Left.Float/Right.Float, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function FloatRemainder(Value, Divider: G2Float): G2Float;
begin                  
 Result:=Value-Divider*Trunc(Value/Divider);
end;

function G2OperBoth_Remainder(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: if Right.Int=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result:=G2Var(Left.Int mod Right.Int, Left, Right);
  gvtFloat: if Right.Float=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
             else Result:=G2Var(FloatRemainder(Left.Float, Right.Float), Left, Right);
  else if Right.Float=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
        else Result:=G2Var(FloatRemainder(Left.Float, Right.Float), Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Power(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Round(Power(Left.Int, Right.Int)), Left, Right);
  gvtFloat: Result:=G2Var(Power(Left.Float, Right.Float), Left, Right);
  else Result:=G2Var(Power(Left.Float, Right.Float), Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_And(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtBoolean: Result:=G2Var(Left.Bool and Right.Bool, Left, Right);
  gvtInteger: Result:=G2Var(Left.Int and Right.Int, Left, Right);
  else Result:=G2Var(Left.Bool and Right.Bool, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Or(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtBoolean: Result:=G2Var(Left.Bool or Right.Bool, Left, Right);
  gvtInteger: Result:=G2Var(Left.Int or Right.Int, Left, Right);
  else Result:=G2Var(Left.Bool or Right.Bool, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_Xor(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtBoolean: Result:=G2Var(Left.Bool xor Right.Bool, Left, Right);
  gvtInteger: Result:=G2Var(Left.Int xor Right.Int, Left, Right);
  else Result:=G2Var(Left.Bool xor Right.Bool, Left, Right);
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_AndSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtBoolean: Result.Bool:=Result.Bool and Value.Bool;
  gvtInteger: Result.Int:=Result.Int and Value.Int;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_OrSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtBoolean: Result.Bool:=Result.Bool or Value.Bool;
  gvtInteger: Result.Int:=Result.Int or Value.Int;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_XorSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtBoolean: Result.Bool:=Result.Bool xor Value.Bool;
  gvtInteger: Result.Int:=Result.Int xor Value.Int;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function Equal(var Succ: Boolean; const V1, V2: TG2Variant): Boolean;
begin
 case V1.DefaultType of
  gvtBoolean: Result:=V1.Bool=V2.Bool;
  gvtInteger: Result:=V1.Int=V2.Int;
  gvtFloat: Result:=V1.Float=V2.Float;
  gvtString: Result:=V1.Str=V2.Str;
  gvtObject: Result:=V1.Obj=V2.Obj;
  gvtArray: Result:=V1.Int=V2.Int;
  else begin Succ:=False; Result:=False; end;
 end;
end;

function Smaller(var Succ: Boolean; const V1, V2: TG2Variant): Boolean;
begin
 case V1.DefaultType of
  gvtBoolean: Result:=V1.Bool<V2.Bool;
  gvtInteger: Result:=V1.Int<V2.Int;
  gvtFloat: Result:=V1.Float<V2.Float;
  gvtString: Result:=V1.Str<V2.Str;
  gvtObject: Result:=V1.Int<V2.Int;
  gvtArray: Result:=V1.Int<V2.Int;
  else begin Succ:=False; Result:=False; end;
 end;
end;

function Bigger(var Succ: Boolean; const V1, V2: TG2Variant): Boolean;
begin
 case V1.DefaultType of
  gvtBoolean: Result:=V1.Bool>V2.Bool;
  gvtInteger: Result:=V1.Int>V2.Int;
  gvtFloat: Result:=V1.Float>V2.Float;
  gvtString: Result:=V1.Str>V2.Str;
  gvtObject: Result:=V1.Int>V2.Int;
  gvtArray: Result:=V1.Int>V2.Int;
  else begin Succ:=False; Result:=False; end;
 end;
end;

function G2OperBoth_Equal(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(Equal(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_UnEqual(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(not Equal(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_Smaller(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(Smaller(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_Bigger(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(Bigger(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_SmallerEq(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(not Bigger(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_BiggerEq(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(not Smaller(Succ, Left, Right), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_Identical(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(Equal(Succ, Left, Right) and (Left.DefaultType=Right.DefaultType), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_UnIdentical(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var((not Equal(Succ, Left, Right)) or (Left.DefaultType<>Right.DefaultType), Left, Right)
  else begin
   G2ReleaseConst(Left);
   G2ReleaseConst(Right);
  end;
 if not Succ then G2Release(Result);
end;

function G2OperBoth_Assign(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ); 
 if Succ then Self.ExecSet(Succ, Value)
  else G2ReleaseConst(Value);
end;

function G2OperBoth_Inc(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int+Value.Int;
  gvtFloat: Result.Float:=Result.Float+Value.Float;
  gvtString: Result.Str:=Result.Str+Value.Str;
  gvtArray: begin Result.IndexedItem[Result.Count]:=Value; Value:=nil; end;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_AddLeft(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtString: Result.Str:=Value.Str+Result.Str;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_Dec(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int-Value.Int;
  gvtFloat: Result.Float:=Result.Float-Value.Float;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_MulSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int*Value.Int;
  gvtFloat: Result.Float:=Result.Float*Value.Float;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_DivSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: if Value.Int=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result.Int:=Result.Int div Value.Int;
  gvtFloat: if Value.Float=0.0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result.FLoat:=Result.Float/Value.Float;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_RemSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: if Value.Int=0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result.Int:=Result.Int mod Value.Int;
  gvtFloat: if Value.Float=0.0 then Succ:=Self.Error(G2RE_ZERODIVIDER, [])
               else Result.Float:=FloatRemainder(Result.Float, Value.Float);
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_PowSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Round(Power(Result.Int, Value.Int));
  gvtFloat: Result.Float:=Power(Result.Float, Value.Float);
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_ShiftLeft(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Left.Int shl Right.Int, Left, Right);
  else Succ:=False;;
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_ShiftRight(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Left, Right: TG2Variant;
begin
 Result:=nil;
 Left:=Self.ExecGet(Succ);
 Right:=Self.ExecGet(Succ);
 if Succ then case Left.DefaultType of
  gvtInteger: Result:=G2Var(Left.Int shr Right.Int, Left, Right);
  else Succ:=False;;
 end;
 if not Succ then begin
  G2ReleaseConst(Left);
  G2ReleaseConst(Right);
  G2Release(Result);
 end;
end;

function G2OperBoth_ShlSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int shl Value.Int;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;

function G2OperBoth_ShrSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 Value:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int shr Value.Int;
  else Succ:=False;
 end;
 G2ReleaseConst(Value);
 if not Succ then G2Release(Result);
end;


// Right Procs

function G2OperRight_Add(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 if not Succ then G2Release(Result);
end;

function G2OperRight_Subtract(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then case Value.DefaultType of
  gvtInteger: Result:=G2Var(-Value.Int, Value);
  gvtFloat: Result:=G2Var(-Value.Float, Value);
  else Result:=G2Var(-Value.Float, Value);
 end;
 if not Succ then begin
  G2ReleaseConst(Value);
  G2Release(Result);
 end;
end;

function G2OperRight_Not(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then case Value.DefaultType of
  gvtBoolean: Result:=G2Var(not Value.Bool, Value);
  gvtInteger: Result:=G2Var(not Value.Int, Value);
  else Result:=G2Var(not Value.Bool, Value);
 end;
 if not Succ then begin
  G2ReleaseConst(Value);
  G2Release(Result);
 end;
end;

function G2OperRight_IncOne(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int+1;
  else Result.Int:=Result.Int+1;
 end;
 if not Succ then G2Release(Result);
end;

function G2OperRight_DecOne(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=Result.Int-1;
  else Result.Int:=Result.Int-1;
 end;
 if not Succ then G2Release(Result);
end;

function G2OperRight_NotSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
begin
 Result:=Self.ExecGet(Succ);
 if Succ then if Result.ReadOnly then Succ:=False;
 if Succ then case Result.DefaultType of
  gvtInteger: Result.Int:=not Result.Int;
  gvtBoolean: Result.Bool:=not Result.Bool;
  else Result.Bool:=not Result.Bool;
 end;
 if not Succ then G2Release(Result);
end;

function G2OperRight_Reference(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Value<>nil then
  if Value.ReadOnly then begin
   Succ:=Self.Error(G2RE_INVALIDREF, []);
   G2Release(Value);
  end else Result:=TG2VReference.Create(Value);
end;

function G2OperRight_Count(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then Result:=G2Var(Value.Count, Value);
end;


// Left procs

function G2OperLeft_IncOne(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then if Value.ReadOnly then Succ:=False;
 if Succ then begin
  Result:=Value.Copy;
  case Value.DefaultType of
   gvtInteger: Value.Int:=Value.Int+1;
   else Succ:=False;
  end;
  Value.Release;
 end;
 if not Succ then G2Release(Result);
end;

function G2OperLeft_DecOne(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then if Value.ReadOnly then Succ:=False;
 if Succ then begin
  Result:=Value.Copy;
  case Value.DefaultType of
   gvtInteger: Value.Int:=Value.Int-1;
   else Succ:=False;
  end;
  Value.Release;
 end;
 if not Succ then G2Release(Result);
end;

function G2OperLeft_NotSelf(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
var Value: TG2Variant;
begin
 Result:=nil;
 Value:=Self.ExecGet(Succ);
 if Succ then if Value.ReadOnly then Succ:=False;
 if Succ then begin
  Result:=Value.Copy;
  case Value.DefaultType of
   gvtInteger: Value.Int:=not Value.Int;
   gvtBoolean: Value.Bool:=not Value.Bool;
   else Succ:=False;
  end;
  Value.Release;
 end;
 if not Succ then G2Release(Result);
end;

function G2Oper_NoRegExpr(const Self: TG2Execute; var Succ: Boolean): TG2Variant;
begin
 Result:=nil;
 Succ:=Self.Error(G2RE_NOREGEXPR, []);
end;

initialization
ZeroMemory(@OperBothProcs, SizeOf(OperBothProcs));
ZeroMemory(@OperLeftProcs, SizeOf(OperLeftProcs));
ZeroMemory(@OperRightProcs, SizeOf(OperRightProcs));

OperBothProcs[gotAdd]:=G2OperBoth_Add;
OperBothProcs[gotSubtract]:=G2OperBoth_Subtract;
OperBothProcs[gotMultiply]:=G2OperBoth_Multiply;
OperBothProcs[gotDivide]:=G2OperBoth_Divide;
OperBothProcs[gotRemainder]:=G2OperBoth_Remainder;
OperBothProcs[gotPower]:=G2OperBoth_Power;
OperBothProcs[gotAnd]:=G2OperBoth_And;
OperBothProcs[gotAnd2]:=G2OperBoth_And;
OperBothProcs[gotOr]:=G2OperBoth_Or;
OperBothProcs[gotOr2]:=G2OperBoth_Or;
OperBothProcs[gotXor]:=G2OperBoth_Xor;
OperBothProcs[gotAndSelf]:=G2OperBoth_AndSelf;
OperBothProcs[gotOrSelf]:=G2OperBoth_OrSelf;
OperBothProcs[gotXorSelf]:=G2OperBoth_XorSelf;
OperBothProcs[gotEqual]:=G2OperBoth_Equal;
OperBothProcs[gotUnEqual]:=G2OperBoth_UnEqual;
OperBothProcs[gotUnEqual2]:=G2OperBoth_UnEqual;
OperBothProcs[gotSmaller]:=G2OperBoth_Smaller;
OperBothProcs[gotBigger]:=G2OperBoth_Bigger;
OperBothProcs[gotSmallerEq]:=G2OperBoth_SmallerEq;
OperBothProcs[gotBiggerEq]:=G2OperBoth_BiggerEq;
OperBothProcs[gotIdentical]:=G2OperBoth_Identical;
OperBothProcs[gotUnIdentical]:=G2OperBoth_UnIdentical;
OperBothProcs[gotAssign]:=G2OperBoth_Assign;
OperBothProcs[gotInc]:=G2OperBoth_Inc;
OperBothProcs[gotAddLeft]:=G2OperBoth_AddLeft;
OperBothProcs[gotDec]:=G2OperBoth_Dec;
OperBothProcs[gotMulSelf]:=G2OperBoth_MulSelf;
OperBothProcs[gotDivSelf]:=G2OperBoth_DivSelf;
OperBothProcs[gotRemSelf]:=G2OperBoth_RemSelf;
OperBothProcs[gotPowSelf]:=G2OperBoth_PowSelf;
OperBothProcs[gotShiftLeft]:=G2OperBoth_ShiftLeft;
OperBothProcs[gotShiftRight]:=G2OperBoth_ShiftRight;
OperBothProcs[gotShlSelf]:=G2OperBoth_ShlSelf;
OperBothProcs[gotShrSelf]:=G2OperBoth_ShrSelf;

OperRightProcs[gotAdd]:=G2OperRight_Add;
OperRightProcs[gotSubtract]:=G2OperRight_Subtract;
OperRightProcs[gotNot]:=G2OperRight_Not;
OperRightProcs[gotIncOne]:=G2OperRight_IncOne;
OperRightProcs[gotDecOne]:=G2OperRight_DecOne;
OperRightProcs[gotNotSelf]:=G2OperRight_NotSelf;
OperRightProcs[gotReference]:=G2OperRight_Reference;
OperRightProcs[gotCount]:=G2OperRight_Count;

OperLeftProcs[gotIncOne]:=G2OperLeft_IncOne;
OperLeftProcs[gotDecOne]:=G2OperLeft_DecOne;
OperLeftProcs[gotNotSelf]:=G2OperLeft_NotSelf;

OperBothProcs[gotReplace]:=G2Oper_NoRegExpr;
OperBothProcs[gotSplit]:=G2Oper_NoRegExpr;
OperBothProcs[gotMatch]:=G2Oper_NoRegExpr;
OperBothProcs[gotNoMatch]:=G2Oper_NoRegExpr;
OperBothProcs[gotRepSelf]:=G2Oper_NoRegExpr;
end.
