unit GMulti;

interface

uses
  GTypes, GConsts, GScript, SysUtils;

type
  TGMultiScript = class(TGScript)
  public
    FScripts: array of TGScript;
    constructor Create;
    destructor Destroy; override;
    procedure SetVariable(const Name: string; Item: TGCustomVariant); override;
    procedure UnsetVariable(const Name: string); override;
  end;

  TGMMulti = class(TGCustomModule)
  private
    FGlobal: TGMultiScript;
    function LoadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function RunScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function UnloadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function ReloadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    procedure Unload; override;
  end;

implementation

{ TGMultiScript }

constructor TGMultiScript.Create;
begin
 inherited;
 TGMMulti(LoadModule(TGMMulti)).FGlobal:=Self;
end;

destructor TGMultiScript.Destroy;
var I: integer;
begin
 for I:=Low(FScripts) to High(FScripts) do
  FScripts[I].Free;
 inherited;
end;

procedure TGMultiScript.SetVariable(const Name: string; Item: TGCustomVariant);
var I: integer;
begin
 inherited;
 for I:=Low(FScripts) to High(FScripts) do
  FScripts[I].SetVariable(Name, Item);
end;

procedure TGMultiScript.UnsetVariable(const Name: string);
var I: integer;
begin
 inherited;
 for I:=Low(FScripts) to High(FScripts) do
  FScripts[I].UnSetVariable(Name);
end;

{ TGMMulti }

constructor TGMMulti.Create(Script: TGCustomScript);
begin
 inherited Create(Script);
 FScript.RegisterFunction('Load', LoadScript); // Load(S1, S2, ... , Sn);
 FScript.RegisterFunction('Run', RunScript); // $X = Run(S1, S2, ... , Sn);
 FScript.RegisterFunction('Unload', UnloadScript); // Unload(S1, S2, ... , Sn);
 FScript.RegisterFunction('Reload', ReloadScript); // Reload(S1, S2, ... , Sn);
end;

procedure TGMMulti.Unload;
begin
 FScript.UnregisterFunction('Reload');
 FScript.UnregisterFunction('Unload');
 FScript.UnregisterFunction('Run');
 FScript.UnregisterFunction('Load');
end;

function TGMMulti.LoadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var S: string;
    I, J: integer;
    Item: TGCustomVariant;
begin
 Result:=False;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtString]);
  if Result then begin
   Result:=FGlobal.FOnLoad(Params[I].Result.ResultStr, S);
   if Result then begin
    SetLength(FGlobal.FScripts, High(FGlobal.FScripts)+2);
    FGlobal.FScripts[High(FGlobal.FScripts)]:=TGScript.Create(Params[I].Result.ResultStr);
    with FGlobal.FScripts[High(FGlobal.FScripts)] do begin
     TGMMulti(LoadModule(TGMMulti)).FGlobal:=FGlobal;
     OutProc:=FGlobal.OutProc;
     ErrorProc:=FGlobal.ErrorProc;
     OnLoad:=FGlobal.OnLoad;
     Options:=FGlobal.Options;
     for J:=0 to FGlobal.FVariables.Count-1 do
      if FGlobal.FVariables.GetItem(J, Item) and (Item<>nil) then SetVariable(FGlobal.FVariables.IndexKey(J), Item.Copy);
     if SetSrc(S) then LoadScript:=Execute(ResultType)
      else LoadScript:=False;
    end;
   end;
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
end;

function TGMMulti.UnloadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I, J: integer;
begin
 Result:=False;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtString]);
  if Result then begin
   for J:=High(FGlobal.FScripts) downto Low(FGlobal.FScripts) do
    if AnsiLowerCase(FGlobal.FScripts[J].Name)=AnsiLowerCase(Params[I].Result.ResultStr) then begin
     FGlobal.FScripts[J].Free;
     if High(FGlobal.FScripts)>J then FGlobal.FScripts[J]:=FGlobal.FScripts[High(FGlobal.FScripts)];
     SetLength(FGlobal.FScripts, High(FGlobal.FScripts));
    end;
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
end;

function TGMMulti.ReloadScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=UnloadScript(Block, ResultType, Params);
 if Result then Result:=LoadScript(Block, ResultType, Params);
end;

function TGMMulti.RunScript(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var S: string;
    I, J: integer;
    Item: TGCustomVariant;
begin
 Result:=False;
 for I:=Low(Params) to High(Params) do begin
  Result:=Params[I].Execute([grtString]);
  if Result then begin
   Result:=FGlobal.FOnLoad(Params[I].Result.ResultStr, S);
   if Result then begin
    with TGScript.Create(Params[I].Result.ResultStr) do begin
     TGMMulti(LoadModule(TGMMulti)).FGlobal:=FGlobal;
     OutProc:=FGlobal.OutProc;
     ErrorProc:=FGlobal.ErrorProc;
     OnLoad:=FGlobal.OnLoad;
     Options:=FGlobal.Options;
     for J:=0 to FGlobal.FVariables.Count-1 do
      if FGlobal.FVariables.GetItem(J, Item) and (Item<>nil) then SetVariable(FGlobal.FVariables.IndexKey(J), Item.Copy);
     if SetSrc(S) then begin
      RunScript:=Execute(ResultType);
      if ResultType<>[grtNone] then
       if Result.Temp then Block.Return(Result)
        else begin
         Item:=Result.Copy;
         Item.Temp:=True;
         Block.Return(Item);
        end;
     end else RunScript:=False;
     Free;
    end;
   end;
   if Params[I].Result.Temp then Params[I].Result.Free;
  end;
  if not Result then Break;
 end;
end;

end.
 