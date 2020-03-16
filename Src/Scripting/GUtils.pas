unit GUtils;

interface

uses
  GTypes, GConsts, GVariants, SysUtils, Windows;

type
  TGMUtils = class(TGCustomModule)
  private
    TimerFrequency, StartTime: Int64;

    function LowerCase(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function UpperCase(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function GetRandom(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;

    function ResetTimer(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function ElapsedTime(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    procedure Unload; override;
  end;

implementation

constructor TGMUtils.Create(Script: TGCustomScript);
begin
 inherited;
 Randomize;
 FScript.RegisterFunction('LowerCase', LowerCase); // $S = LowerCase(S);
 FScript.RegisterFunction('UpperCase', UpperCase); // $S = UpperCase(S);
 FScript.RegisterFunction('LC', LowerCase); // $S = LC(S);
 FScript.RegisterFunction('UC', UpperCase); // $S = UC(S);

 FScript.RegisterFunction('Random', GetRandom); // $F = Random(Fa, Fb);

 FScript.RegisterFunction('ResetTimer', ResetTimer); // ResetTimer;
 FScript.RegisterFunction('ElapsedTime', ElapsedTime); // $F = ElapsedTime;
end;

procedure TGMUtils.Unload;
begin
 FScript.UnregisterFunction('ElapsedTime');
 FScript.UnregisterFunction('ResetTimer');

 FScript.UnregisterFunction('Random');

 FScript.UnregisterFunction('UC');
 FScript.UnregisterFunction('LC');
 FScript.UnregisterFunction('UpperCase');
 FScript.UnregisterFunction('LowerCase');
end;

function TGMUtils.LowerCase(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtString]);
  if Result then begin
   Result:=Block.Return(TGVString.Create(True, False, AnsiLowerCase(Params[0].Result.ResultStr)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMUtils.UpperCase(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then begin
  Result:=Params[0].Execute([grtString]);
  if Result then begin
   Result:=Block.Return(TGVString.Create(True, False, AnsiUpperCase(Params[0].Result.ResultStr)));
   if Params[0].Result.Temp then Params[0].Result.Free;
  end;
 end;
end;

function TGMUtils.GetRandom(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=False;
 if High(Params)=-1 then begin
  Block.Return(TGVFloat.Create(True, False, Random(100000)*0.00001));
  Result:=True;
 end else if High(Params)=1 then begin
  Result:=Params[0].Execute([grtFloat]);
  if Result then Result:=Params[1].Execute([grtFloat]);
  if Result then begin
   Result:=Block.Return(TGVFloat.Create(True, False, Random(100000)*0.00001*(Params[1].Result.ResultFloat-Params[0].Result.ResultFloat)+Params[0].Result.ResultFloat));
   if Params[0].Result.Temp then Params[0].Result.Free;
   if Params[1].Result.Temp then Params[1].Result.Free;
  end;
 end;
end;

function TGMUtils.ElapsedTime(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var EndTime: Int64;
begin
 Result:=High(Params)=-1;
 if Result then begin
  QueryPerformanceCounter(EndTime);
  Result:=Block.Return(TGVFloat.Create(True, False, (EndTime-StartTime)/TimerFrequency));
 end;
end;

function TGMUtils.ResetTimer(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=-1;
 if Result then begin
  QueryPerformanceFrequency(TimerFrequency);
  QueryPerformanceCounter(StartTime);
 end;
end;

initialization
GRegisterModule('Utils', TGMUtils);
end.
