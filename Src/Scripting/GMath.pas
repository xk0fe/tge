unit GMath;

interface

uses
  GTypes, GConsts, GVariants, SysUtils, Math;

type
  TGMMath = class(TGCustomModule)
  private
    function MathSqrt(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathSin(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathCos(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathTan(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathPi(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathMin(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathMax(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function MathSum(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    procedure Unload; override;
  end;

implementation

constructor TGMMath.Create(Script: TGCustomScript);
begin
 inherited;
 FScript.RegisterFunction('Sqrt', MathSqrt); // $F = Sqrt(F);
 FScript.RegisterFunction('Sin', MathSin); // $F = Sin(F);
 FScript.RegisterFunction('Cos', MathCos); // $F = Cos(F);
 FScript.RegisterFunction('Tan', MathTan); // $F = Tan(F);
 FScript.RegisterFunction('Pi', MathPi); // $F = Pi;
 FScript.RegisterFunction('Min', MathMin); // $F/I = Min(F/I1, F/I2, ... ,F/In);
 FScript.RegisterFunction('Max', MathMax); // $F/I = Max(F/I1, F/I2, ... ,F/In);
 FScript.RegisterFunction('Sum', MathSum); // $F/I = Sum(A);
end;

procedure TGMMath.Unload;
begin
 FScript.UnregisterFunction('Sum');
 FScript.UnregisterFunction('Max');
 FScript.UnregisterFunction('Min');
 FScript.UnregisterFunction('Pi');
 FScript.UnregisterFunction('Tan');
 FScript.UnregisterFunction('Cos');
 FScript.UnregisterFunction('Sin');
 FScript.UnregisterFunction('Sqrt');
end;

function TGMMath.MathSqrt(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtFloat]);
  if Result then begin
   Block.Return(TGVFloat.Create(True, False, Sqrt(Params[0].Result.ResultFloat)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMMath.MathCos(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtFloat]);
  if Result then begin
   Block.Return(TGVFloat.Create(True, False, Cos(Params[0].Result.ResultFloat)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMMath.MathSin(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtFloat]);
  if Result then begin
   Block.Return(TGVFloat.Create(True, False, Sin(Params[0].Result.ResultFloat)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMMath.MathTan(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtFloat]);
  if Result then begin
   Block.Return(TGVFloat.Create(True, False, Tan(Params[0].Result.ResultFloat)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMMath.MathPi(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=-1;
 if Result then Block.Return(TGVFloat.Create(True, False, Pi));
end;

function TGMMath.MathMax(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var GF: GFloat;
    I: integer;
begin
 Result:=False;
 GF:=0;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtInteger, grtFloat]);
  if Result then begin
   if I=0 then GF:=Params[I].Result.ResultFloat
    else GF:=Max(GF, Params[I].Result.ResultFloat);
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
 if Result then if Round(GF)<>GF then Block.Return(TGVFloat.Create(True, False, GF))
  else Block.Return(TGVInteger.Create(True, False, Round(GF)));
end;

function TGMMath.MathMin(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var GF: GFloat;
    I: integer;
begin
 Result:=False;
 GF:=0;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtInteger, grtFloat]);
  if Result then begin
   if I=0 then GF:=Params[I].Result.ResultFloat
    else GF:=Min(GF, Params[I].Result.ResultFloat);
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
 if Result then if Round(GF)<>GF then Block.Return(TGVFloat.Create(True, False, GF))
  else Block.Return(TGVInteger.Create(True, False, Round(GF)));
end;

function TGMMath.MathSum(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I: integer;
    GF: GFloat;
    Item: TGCustomVariant;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtArray]);
 if Result then Result:=Params[0].Result.Indexed;
 if Result then begin
  GF:=0;
  for I:=0 to Params[0].Result.Count-1 do begin
   Params[0].Result.GetItem(I, Item);
   GF:=GF+Item.ResultFloat;
   if Item.Temp then Item.Free;
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
  if Round(GF)<>GF then Block.Return(TGVFloat.Create(True, False, GF))
   else Block.Return(TGVInteger.Create(True, False, Round(GF)));
 end;
end;

initialization
GRegisterModule('Math', TGMMath);
end.
