unit GBlocks;

interface

uses
  GTypes, GVariants, GConsts, Classes, SysUtils, Math, RegExpr;

type
  TGBCustomSubScript = class;
  TGBlock = class(TGCustomBlock)
  private
    FResult: TGCustomVariant;
    FParent: TGCustomBlock;
  protected
    function GetScript: TGCustomScript;
    function GetSubScript: TGBCustomSubScript; virtual;
    function GetResult: TGCustomVariant; override;
    function Error(Id: Cardinal; const S: string; Sender: TGCustomBlock): Boolean;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Return(Value: TGCustomVariant): Boolean; override;
    property Parent: TGCustomBlock read FParent write FParent;
    property Script: TGCustomScript read GetScript;
    property SubScript: TGBCustomSubScript read GetSubScript;
  end;     

  TGBContainer = class(TGBlock)
  private
    FStop: Boolean;
    FSrc: array of TGCustomBlock;
  public
    destructor Destroy; override;
    procedure Add(Src: TGCustomBlock);
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Stop: Boolean write FStop;
  end;

  TGBIf = class(TGBContainer)
  private
    FExp: TGCustomBlock;
    FElse: TGBContainer;
  public
    constructor Create(AParent: TGCustomBlock; Exp: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Exp: TGCustomBlock write FExp;
    property ElseSrc: TGBContainer read FElse write FElse;
  end;

  TGBFor = class(TGBContainer)
  private
    FInit, FCond, FStep: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Init: TGCustomBlock write FInit;
    property Cond: TGCustomBlock write FCond;
    property Step: TGCustomBlock write FStep;
  end;

  TGBWhile = class(TGBContainer)
  private
    FCond: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Cond: TGCustomBlock write FCond;
  end;

  TGBRepeat = class(TGBContainer)
  private
    FCond: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Cond: TGCustomBlock write FCond;
  end;

  TGBForeach = class(TGBContainer)
  private
    FSrc: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Src: TGCustomBlock write FSrc;
  end;

  TGBReturn = class(TGBlock)
  private
    FSrc: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Src: TGCustomBlock write FSrc;
  end;

  TGBCustomSubScript = class(TGBContainer)
  private
    FFunctions: TGArray;
    FVariables: array of TGArray;
  protected
    function GetSubScript: TGBCustomSubScript; override;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function GetFunction(const Name: string): TGFunction;
    function GetVariable(const Name: string): TGCustomVariant;
    procedure SetVariable(const Name: string; Item: TGCustomVariant);
    procedure UnsetVariable(const Name: string);
    procedure RegisterFunction(const Name: string; Item: TGFunction);
    procedure UnregisterFunction(const Name: string); 
  end;

  TGBSubProg = class(TGBCustomSubScript)
  private
    FName: string;
    FParams: array of string;
  public
    constructor Create(AParent: TGCustomBlock; const Name: string; Params: array of string);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    function ExecuteEx(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  end;

  TGBVariable = class(TGBlock)
  protected
    FName: string;
    constructor Create(AParent: TGCustomBlock; const Name: string);
  public
    function SetSrc(FSrc: TGCustomBlock): Boolean; virtual; abstract;
  end;

  TGBFuncCall = class(TGBVariable)
  private
    FParams: array of TGCustomBlock;
    FName: string;
  public
    constructor Create(AParent: TGCustomBlock; const Name: string; Params: array of TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    procedure SetParams(Params: array of TGCustomBlock);
    function SetSrc(FSrc: TGCustomBlock): Boolean; override;
  end;

  TGBGetVar = class(TGBVariable)
  private
    FForceGlobal, FForceLocal: Boolean;
  public
    constructor Create(AParent: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; const Name: string);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    function SetSrc(FSrc: TGCustomBlock): Boolean; override;
  end;

  TGBGetKeyedVar = class(TGBVariable)
  private
    FKey: array of TGVariableKey;
    FForceGlobal, FForceLocal: Boolean;
  public
    constructor Create(AParent: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; const Name: string; const Key: array of TGVariableKey);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    procedure SetKey(const Key: array of TGVariableKey);
    function SetSrc(FSrc: TGCustomBlock): Boolean; override;
  end;

  {TGBSetVar = class(TGBlock)
  private
    FName: string;
    FSrc: TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock; const Name: string; Src: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Src: TGCustomBlock write FSrc;
  end;

  TGBSetKeyedVar = class(TGBlock)
  private
    FName: string;
    FSrc: TGCustomBlock;
    FKey: array of TGCustomBlock;
  public
    constructor Create(AParent: TGCustomBlock; const Name: string; Src: TGCustomBlock; const Key: array of TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    property Src: TGCustomBlock write FSrc;
    procedure SetKey(const Key: array of TGCustomBlock);
  end;}

  TGBGetValue = class(TGBlock)
  private
    FSrc: array of TGValueData;
  public
    constructor Create(AParent: TGCustomBlock);
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    procedure Add(const Src: TGValueData);
    procedure Compile;
  end;

implementation

uses GCompiler;

{ TGBlock }

constructor TGBlock.Create(AParent: TGCustomBlock);
begin
 inherited Create;
 FParent:=AParent;
end;

destructor TGBlock.Destroy;
begin
 FreeAndNil(FResult);
 inherited;
end;

function TGBlock.Error(Id: Cardinal; const S: string; Sender: TGCustomBlock): Boolean;
begin
 Result:=Script<>nil;
 if Result then Result:=Script.Error(Id, S, Sender); 
end;

function TGBlock.GetSubScript: TGBCustomSubScript;
begin
 if Parent is TGBCustomSubScript then Result:=TGBCustomSubScript(Parent)
  else if Parent is TGBlock then Result:=TGBlock(Parent).GetSubScript
   else Result:=nil;
end;

function TGBlock.GetResult: TGCustomVariant;
begin
 Result:=FResult;
end;

function TGBlock.GetScript: TGCustomScript;
begin
 if Parent is TGCustomScript then Result:=TGCustomScript(Parent)
  else if Parent is TGBlock then Result:=TGBlock(Parent).GetScript
   else Result:=nil;
end;

function TGBlock.Return(Value: TGCustomVariant): Boolean;
begin
 //if FResult<>nil then if FResult.Temp then FResult.Free;
 FResult:=Value;
 Result:=True;
end;

{ TGBFuncCall }

constructor TGBFuncCall.Create(AParent: TGCustomBlock; const Name: string; Params: array of TGCustomBlock);
begin
 inherited Create(AParent, Name);
 FName:=Name;
 SetParams(Params);
end;

destructor TGBFuncCall.Destroy;
var I: integer;
begin
 for I:=Low(FParams) to High(FParams) do
  FreeAndNil(FParams[I]);
 FResult:=nil;
 inherited;
end;

function TGBFuncCall.Execute(ResultType: TGResultTypes): Boolean;
var F: TGFunction;
begin
 FResult:=nil;
 //Result:=FSrc<>nil;
 //if Result then begin
  Result:=False;
  F:=nil;
  if SubScript<>nil then begin
   F:=SubScript.GetFunction(FName);
   Result:=Assigned(F);
  end;
  if (not Result) and (Script<>nil) then begin
   F:=Script.GetFunction(FName);
   Result:=Assigned(F);
  end;
  if Result then Result:=F(Self, ResultType, FParams)
   else Error(GE_FuncNotFound, 'Undefined function: "'+FName+'".', Self);
 //end;
end;

procedure TGBFuncCall.SetParams(Params: array of TGCustomBlock);
var I: integer;
begin
 SetLength(FParams, High(Params)+1);
 for I:=Low(Params) to High(Params) do
  FParams[I]:=Params[I];
end;

function TGBFuncCall.SetSrc(FSrc: TGCustomBlock): Boolean;
begin
 Result:=FSrc<>nil;
 if Result then Result:=FSrc.Execute([grtDefault]);
 if Result then Result:=Execute([grtDefault]);
 if Result then Result:=not FResult.Temp;
 if Result then Result:=FResult is FSrc.Result.ClassType;
 if Result then begin
  FResult.Assign(FSrc.Result);
  if FSrc.Result.Temp then FSrc.Result.Free;
 end;
end;

{ TGBContainer }

procedure TGBContainer.Add(Src: TGCustomBlock);
begin
 SetLength(FSrc, High(FSrc)+2);
 FSrc[High(FSrc)]:=Src;
end;

destructor TGBContainer.Destroy;
var I: integer;
begin
 FResult:=nil;
 for I:=Low(FSrc) to High(FSrc) do
  FreeAndNil(FSrc[I]);
 inherited;
end;

function TGBContainer.Execute(ResultType: TGResultTypes): Boolean;
var I: integer;
begin
 FResult:=nil;
 FStop:=False;
 Result:=True;
 for I:=Low(FSrc) to High(FSrc) do begin
  Result:=FSrc[I].Execute([grtNone]);
  if not Result then Break;
  if FResult<>nil then if FResult.Temp then FreeAndNil(FResult);
  {if ResultType<>[grtNone] then} FResult:=FSrc[I].Result;
  if FStop then Break;
 end;
 if FResult<>nil then if FResult.Temp then FreeAndNil(FResult);
end;

{ TGBCustomSubScript }

constructor TGBCustomSubScript.Create(AParent: TGCustomBlock);
begin
 inherited;
 FFunctions:=TGArray.Create(SizeOf(TGFunction));
 //FVariables:=TGArray.Create(SizeOf(TGCustomVariant));
end;

destructor TGBCustomSubScript.Destroy;
//var I: integer;
//    Item: TGCustomVariant;
begin
 //for I:=0 to FVariables.Count-1 do
 // if FVariables.GetItem(I, Item) then if not Item.Temp then Item.Free;
 //FVariables.Free;
 FFunctions.Free;
 inherited;
end;

procedure TGBCustomSubScript.RegisterFunction(const Name: string; Item: TGFunction);
begin
 FFunctions.SetItem(Name, @Item);
end;

function TGBCustomSubScript.GetFunction(const Name: string): TGFunction;
begin
 Result:=nil;
 FFunctions.GetItem(Name, @Result);
end;

procedure TGBCustomSubScript.UnregisterFunction(const Name: string);
begin
 FFunctions.Remove(Name);
end;

function TGBCustomSubScript.GetVariable(const Name: string): TGCustomVariant;
begin
 Result:=nil;
 FVariables[High(FVariables)].GetItem(Name, Result);
end;

procedure TGBCustomSubScript.SetVariable(const Name: string; Item: TGCustomVariant);
begin
 Item.Temp:=False;
 FVariables[High(FVariables)].SetItem(Name, Item);
end;

procedure TGBCustomSubScript.UnsetVariable(const Name: string);
begin
 FVariables[High(FVariables)].Remove(Name);
end;

function TGBCustomSubScript.GetSubScript: TGBCustomSubScript;
begin
 Result:=Self;
end;

{ TGBSubProg }

constructor TGBSubProg.Create(AParent: TGCustomBlock; const Name: string; Params: array of string);
var I: integer;
begin
 inherited Create(AParent);
 if Script<>nil then Script.RegisterFunction(Name, ExecuteEx);
 SetLength(FParams, High(Params)+1);
 for I:=Low(Params) to High(Params) do
  FParams[I]:=Params[I];
 FName:=Name;
end;

destructor TGBSubProg.Destroy;
begin
 if Script<>nil then Script.UnregisterFunction(FName);
 inherited;
end;

function TGBSubProg.Execute(ResultType: TGResultTypes): Boolean;
begin
 FResult:=nil;
 Result:=True;
end;

function TGBSubProg.ExecuteEx(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var I: integer;
    V: TGCustomVariant;
    Variables: TGArray;
begin
 Result:=True;
 Variables:=TGArray.Create(SizeOf(TGCustomVariant));
 for I:=0 to Min(High(Params), High(FParams)) do begin
  Result:=Params[I].Execute([grtDefault]);
  if Result then begin
   if Params[I].Result.Temp then V:=Params[I].Result
    else V:=Params[I].Result.Copy;
   V.Temp:=False;
   Variables.SetItem(FParams[I], V);
  end else Break;                  
 end;
 SetLength(FVariables, High(FVariables)+2);
 FVariables[High(FVariables)]:=Variables;
 if Result then Result:=inherited Execute(ResultType);
 if Result then if ResultType<>[grtNone] then begin
  if not FResult.Temp then FResult:=FResult.Copy;
  FResult.Temp:=True;
  Block.Return(FResult);
 end;
 for I:=0 to Variables.Count-1 do
  if Variables.GetItem(I, V) then V.Free;
 Variables.Free;
 SetLength(FVariables, High(FVariables));
end;

{ TGBGetVar }

constructor TGBGetVar.Create(AParent: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; const Name: string);
begin
 inherited Create(AParent, Name);
 FForceGlobal:=ForceGlobal;
 FForceLocal:=ForceLocal;
end;

destructor TGBGetVar.Destroy;
begin
 FResult:=nil;
 inherited;
end;

function TGBGetVar.Execute(ResultType: TGResultTypes): Boolean;
var V: TGCustomVariant;
begin
 Result:=False;
 V:=nil;
 if not FForceGlobal then if SubScript<>nil then begin
  V:=SubScript.GetVariable(FName);
  Result:=Assigned(V);
 end;
 if not FForceLocal then if (not Result) and (Script<>nil) then begin
  V:=Script.GetVariable(FName);
  Result:=Assigned(V);
 end;
 if Result then FResult:=V
  else Error(GE_VarNotFound, 'Undefined variable: "'+FName+'".', Self);
end;

function TGBGetVar.SetSrc(FSrc: TGCustomBlock): Boolean;
var Global: Boolean;
begin
 if FSrc<>nil then Result:=FSrc.Execute([grtDefault]) else Result:=True;
 if not Result then Exit;
 FResult:=nil;
 if not FForceGlobal then if SubScript<>nil then FResult:=SubScript.GetVariable(FName);
 Global:=not Assigned(FResult);
 if not FForceLocal then if Global and (Script<>nil) then FResult:=Script.GetVariable(FName);
 Global:=Global and Assigned(FResult);
 if FSrc<>nil then begin
  if FResult is FSrc.Result.ClassType then begin
   FResult.Assign(FSrc.Result);
   if FSrc.Result.Temp then FSrc.Result.Free;
  end else begin
   FreeAndNil(FResult);
   if FSrc.Result.Temp then FResult:=FSrc.Result
    else FResult:=FSrc.Result.Copy;
   FResult.Temp:=False;
   if (not FForceGlobal) and (SubScript<>nil) and (not Global) then SubScript.SetVariable(FName, FResult)
    else if (not FForceLocal) and (Script<>nil) then Script.SetVariable(FName, FResult)
     else Result:=False;
  end;
 end else if FResult<>nil then begin
  FreeAndNil(FResult);
  if (not FForceGlobal) and (SubScript<>nil) and (not Global) then SubScript.UnsetVariable(FName)
   else if (not FForceLocal) and (Script<>nil) then Script.UnsetVariable(FName)
    else Result:=False;
 end;
end;

{ TGBGetKeyedVar }

constructor TGBGetKeyedVar.Create(AParent: TGCustomBlock; ForceGlobal, ForceLocal: Boolean; const Name: string; const Key: array of TGVariableKey);
begin
 inherited Create(AParent, Name);
 FForceGlobal:=ForceGlobal;
 FForceLocal:=ForceLocal;
 SetKey(Key);
end;

destructor TGBGetKeyedVar.Destroy;
var I: integer;
begin
 for I:=Low(FKey) to High(FKey) do
  FKey[I].Value.Free;
 FResult:=nil;
 inherited;
end;

function TGBGetKeyedVar.Execute(ResultType: TGResultTypes): Boolean;
var V, V2: TGCustomVariant;
    I: integer;
begin
 Result:=False;
 for I:=Low(FKey) to High(FKey) do begin
  Result:=FKey[I].Value.Execute([FKey[I].KeyType]);
  if not Result then Exit;
 end;
 if Result then begin
  Result:=False;
  V:=nil;
  if not FForceGlobal then if SubScript<>nil then begin
   V:=SubScript.GetVariable(FName);
   Result:=Assigned(V);
  end;
  if not FForceLocal then if (not Result) and (Script<>nil) then begin
   V:=Script.GetVariable(FName);
   Result:=Assigned(V);
  end;
  if Result then begin
   I:=0;
   Result:=False;
   while (I<=High(FKey)) do begin
    if (FKey[I].KeyType=grtString) and V.Keyed then Result:=V.GetItem(FKey[I].Value.Result.ResultStr, V2)
     else if (FKey[I].KeyType=grtInteger) and V.Indexed then Result:=V.GetItem(FKey[I].Value.Result.ResultInt, V2) and (V2<>nil);
    if V.Temp then V.Free;
    V:=V2;
    Inc(I);
    if not Result then Break;
   end;
   if Result then FResult:=V;
  end else Error(GE_VarNotFound, 'Undefined variable: "'+FName+'".', Self);
 end;
 for I:=Low(FKey) to High(FKey) do
  if FKey[I].Value.Result.Temp then FKey[I].Value.Result.Free;
end;

procedure TGBGetKeyedVar.SetKey(const Key: array of TGVariableKey);
var I: integer;
begin
 SetLength(FKey, High(Key)+1);
 for I:=Low(Key) to High(Key) do
  FKey[I]:=Key[I];
end;

function TGBGetKeyedVar.SetSrc(FSrc: TGCustomBlock): Boolean;
var V, V2: TGCustomVariant;
    I: integer;
begin
 Result:=False;
 for I:=Low(FKey) to High(FKey) do begin
  Result:=FKey[I].Value.Execute([FKey[I].KeyType]);
  if not Result then Exit;
 end;
 if FSrc<>nil then if Result then begin
  Result:=FSrc.Execute([grtDefault]);
  FResult:=FSrc.Result;
 end else FResult:=nil;
 if not Result then Exit;
 V:=nil;
 V2:=nil;
 if not FForceGlobal then if SubScript<>nil then V:=SubScript.GetVariable(FName);
 if not FForceLocal then if (not Assigned(V)) and (Script<>nil) then V:=Script.GetVariable(FName);
 I:=0;
 while I<=High(FKey) do begin
  if Assigned(V) then begin
   if V.Keyed and (FKey[I].KeyType=grtString) and (I<High(FKey)) then begin
    if not V.GetItem(FKey[I].Value.Result.ResultStr, V2) then begin
     if FSrc=nil then begin V:=nil; V2:=nil; Break; end;
     V2:=TGVArray.Create(False, False, []);
     V.SetItem(FKey[I].Value.Result.ResultStr, V2);
     V:=nil;
    end else begin
     if V.Temp then V.Free;
     if V.Temp and (not V2.Temp) then V:=V2.Copy
      else V:=V2;
     V2:=nil;
    end;
   end else if V.Indexed and (FKey[I].KeyType=grtInteger) and (I<High(FKey)) then begin
    if not V.GetItem(FKey[I].Value.Result.ResultInt, V2) then begin
     if FSrc=nil then begin V:=nil; V2:=nil; Break; end;
     V2:=TGVArray.Create(False, False, []);
     V.SetItem(FKey[I].Value.Result.ResultInt, V2);
     V:=nil;
    end else begin
     if V.Temp then V.Free;
     if V.Temp and (not V2.Temp) then V:=V2.Copy
      else V:=V2;
     V2:=nil;
    end;
   end else Result:=I=High(FKey);
  end else begin
   if FSrc=nil then begin V:=nil; V2:=nil; Break; end;
   V:=V2;
   V2:=TGVArray.Create(False, False, []);
   if I=0 then begin
    if (not FForceGlobal) and (SubScript<>nil) then SubScript.SetVariable(FName, V2)
     else if (not FForceLocal) and (Script<>nil) then Script.SetVariable(FName, V2)
      else Result:=False;
   end else if FKey[I-1].KeyType=grtString then V.SetItem(FKey[I-1].Value.Result.ResultStr, V2)
    else if FKey[I-1].KeyType=grtInteger then V.SetItem(FKey[I-1].Value.Result.ResultInt, V2);
   V:=nil;
  end;
  Inc(I);
  if not Result then Exit;
 end;
 if Assigned(V2) then V:=V2;
 Result:=Assigned(V) and Result;
 if Result then begin
  if V.Keyed and (FKey[High(FKey)].KeyType=grtString) then begin
   if FSrc=nil then Result:=V.UnsetItem(FKey[High(FKey)].Value.Result.ResultStr)
    else if FSrc.Result.Temp then V.SetItem(FKey[High(FKey)].Value.Result.ResultStr, FSrc.Result)
      else V.SetItem(FKey[High(FKey)].Value.Result.ResultStr, FSrc.Result.Copy);
  end else if V.Indexed and (FKey[High(FKey)].KeyType=grtInteger) then begin
   if FSrc=nil then Result:=V.UnsetItem(FKey[High(FKey)].Value.Result.ResultInt)
    else if FSrc.Result.Temp then V.SetItem(FKey[High(FKey)].Value.Result.ResultInt, FSrc.Result)
     else V.SetItem(FKey[High(FKey)].Value.Result.ResultInt, FSrc.Result.Copy);
  end else Result:=False;
  if V.Temp then V.Free;
 end else if FSrc=nil then Result:=True;
 for I:=Low(FKey) to High(FKey) do
  if FKey[I].Value.Result.Temp then FKey[I].Value.Result.Free;
 //if FSrc.Result.Temp then FSrc.Result.Free;
end;

{ TGBSetVar }

{constructor TGBSetVar.Create(AParent: TGCustomBlock; const Name: string; Src: TGCustomBlock);
begin
 inherited Create(AParent);
 FName:=Name;
 FSrc:=Src;
end;

destructor TGBSetVar.Destroy;
begin
 FSrc.Free;
 FResult:=nil;
 inherited;
end;

function TGBSetVar.Execute(ResultType: TGResultTypes): Boolean;
var Global: Boolean;
begin
 Result:=FSrc.Execute([grtDefault]);
 FResult:=nil;
 if SubScript<>nil then FResult:=SubScript.GetVariable(FName);
 Global:=not Assigned(FResult);
 if Global and (Script<>nil) then FResult:=Script.GetVariable(FName);
 Global:=Global and Assigned(FResult);
 if FResult is FSrc.Result.ClassType then begin
  FResult.Assign(FSrc.Result);
  if FSrc.Result.Temp then FSrc.Result.Free;
 end else begin
   FreeAndNil(FResult);
   if FSrc.Result.Temp then FResult:=FSrc.Result
    else FResult:=FSrc.Result.Copy;
   FResult.Temp:=False;
   if (SubScript<>nil) and (not Global) then SubScript.SetVariable(FName, FResult)
    else if Script<>nil then Script.SetVariable(FName, FResult);
  end;
end;}

{ TGBSetKeyedVar }

{constructor TGBSetKeyedVar.Create(AParent: TGCustomBlock; const Name: string; Src: TGCustomBlock; const Key: array of TGCustomBlock);
begin
 inherited Create(AParent);
 FName:=Name;
 SetKey(Key);
 FSrc:=Src;
end;

destructor TGBSetKeyedVar.Destroy;
var I: integer;
begin
 FSrc.Free;
 for I:=Low(FKey) to High(FKey) do
  FKey[I].Free;
 FResult:=nil;
 inherited;
end;

function TGBSetKeyedVar.Execute(ResultType: TGResultTypes): Boolean;
var V, V2: TGCustomVariant;
    I: integer;
begin
 Result:=False;
 for I:=Low(FKey) to High(FKey) do
  Result:=FKey[I].Execute([grtString]);
 if Result then Result:=FSrc.Execute([grtDefault]);
 FResult:=FSrc.Result;
 if not Result then Exit;
 V:=nil;
 V2:=nil;
 if SubScript<>nil then V:=SubScript.GetVariable(FName);
 if (not Assigned(V)) and (Script<>nil) then V:=Script.GetVariable(FName);
 I:=0;
 while I<=High(FKey) do begin
  if Assigned(V) then begin
   Result:=V.Keyed;
   if Result and (I<High(FKey)) then begin
    if not V.GetItem(FKey[I].Result.ResultStr, V2) then begin
     V2:=TGVArray.Create(False, []);
     V.SetItem(FKey[I].Result.ResultStr, V2);
     V:=nil;
    end else begin
     V:=V2;
     V2:=nil;
    end;
   end;
  end else begin
   V:=V2;
   V2:=TGVArray.Create(False, []);
   if I=0 then begin
    if SubScript<>nil then SubScript.SetVariable(FName, V2)
     else if Script<>nil then Script.SetVariable(FName, V2);
   end else V.SetItem(FKey[I-1].Result.ResultStr, V2);
   V:=nil;
  end;
  Inc(I);
  if not Result then Exit;
 end;
 if Assigned(V2) then V:=V2;
 Result:=Assigned(V) and Result;
 if Result then
  if V.Keyed then begin
   if FSrc.Result.Temp then begin
    FSrc.Result.Temp:=False;
    V.SetItem(FKey[High(FKey)].Result.ResultStr, FSrc.Result);
   end else V.SetItem(FKey[High(FKey)].Result.ResultStr, FSrc.Result.Copy);
  end else Result:=False;
 for I:=Low(FKey) to High(FKey) do
  if FKey[I].Result.Temp then FKey[I].Result.Free;
end;

procedure TGBSetKeyedVar.SetKey(const Key: array of TGCustomBlock);
var I: integer;
begin
 SetLength(FKey, High(Key)+1);
 for I:=Low(Key) to High(Key) do
  FKey[I]:=Key[I];
end;}

{ TGBGetValue }

constructor TGBGetValue.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBGetValue.Destroy;
var I: integer;
begin
 for I:=Low(FSrc) to High(FSrc) do
  FSrc[I].Value.Free;
 FResult:=nil;
 inherited;
end;

function FloatRemainder(Value, Divider: Single): Single;
begin                  
 Result:=Value-Divider*Trunc(Value/Divider);
end;

function TGBGetValue.Execute(ResultType: TGResultTypes): Boolean;
var I: integer;
    NewResult: TGCustomVariant;
    GB: GBool;
    GI: GInt;
    GF: GFloat;
    GS: GString;
    RType: TGResultType;

  procedure ValueNot;
  begin
    Result:=(FSrc[I].Value<>nil) and (I=0);
    if Result then Result:=FSrc[I].Value.Execute([grtBoolean, grtInteger]);
    if Result then FResult:=FSrc[I].Value.Result;
    if Result then if FResult.DefaultType=grtBoolean then begin
     GB:=not FResult.ResultBool;
     if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
     Result:=FResult.SetValue(grtBoolean, GB);
    end else if FResult.DefaultType=grtInteger then begin
     GI:=not FResult.ResultInt;
     if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
     Result:=FResult.SetValue(grtInteger, GI);
    end else begin
     GB:=not FResult.ResultBool;
     if FResult.Temp then FResult.Free;
     FResult:=TGVBoolean.Create(True, False, GB);
    end;
  end;

  procedure ValueNotSelf;
  begin
    Result:=((FSrc[I].Value<>nil) xor (I>0)) and (FResult=nil);
    if Result then if I>0 then begin
     Result:=FSrc[I-1].Value is TGBVariable;
     if Result then Result:=FSrc[I-1].Value.Execute([grtInteger, grtBoolean]);
     if Result then if FSrc[I-1].Value.Result.DefaultType=grtInteger then begin
      GI:=not FSrc[I-1].Value.Result.ResultInt;
      Result:=FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
      FResult:=FSrc[I-1].Value.Result;
     end else if FSrc[I-1].Value.Result.DefaultType=grtBoolean then begin
      GB:=not FSrc[I-1].Value.Result.ResultBool;
      Result:=FSrc[I-1].Value.Result.SetValue(grtBoolean, GB);
      FResult:=FSrc[I-1].Value.Result;
     end else Result:=False;
    end else begin
     Result:=FSrc[I].Value is TGBVariable;
     if Result then Result:=FSrc[I].Value.Execute([grtInteger, grtBoolean]);
     if Result then if ResultType<>[grtNone] then begin
      FResult:=FSrc[I].Value.Result.Copy;
      FResult.Temp:=True;
     end;
     if Result then if FSrc[I].Value.Result.DefaultType=grtInteger then begin
      GI:=not FSrc[I].Value.Result.ResultInt;
      Result:=FSrc[I].Value.Result.SetValue(grtInteger, GI);
     end else if FSrc[I].Value.Result.DefaultType=grtBoolean then begin
      GB:=not FSrc[I].Value.Result.ResultBool;
      Result:=FSrc[I].Value.Result.SetValue(grtBoolean, GB);
     end else Result:=False;
    end;
  end;

  procedure ValueAndOrXor;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result then if FResult=nil then begin
     Result:=FSrc[I-1].Value.Execute([grtBoolean, grtInteger]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
    if Result then begin
     if FResult.DefaultType=grtBoolean then begin
      case FSrc[I].Operator of
       gotAnd, gotAnd2: GB:=FResult.ResultBool and FSrc[I].Value.Result.ResultBool;
       gotOr, gotOr2: GB:=FResult.ResultBool or FSrc[I].Value.Result.ResultBool;
       gotXOr: GB:=FResult.ResultBool xor FSrc[I].Value.Result.ResultBool;
      end;
      if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
      Result:=FResult.SetValue(grtBoolean, GB);
     end else if FResult.DefaultType=grtInteger then begin
      case FSrc[I].Operator of
       gotAnd, gotAnd2: GI:=FResult.ResultInt and FSrc[I].Value.Result.ResultInt;
       gotOr, gotOr2: GI:=FResult.ResultInt or FSrc[I].Value.Result.ResultInt;
       gotXOr: GI:=FResult.ResultInt xor FSrc[I].Value.Result.ResultInt;
      end;
      if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
      Result:=FResult.SetValue(grtInteger, GI);
     end else begin
      case FSrc[I].Operator of
       gotAnd, gotAnd2: GB:=FResult.ResultBool and FSrc[I].Value.Result.ResultBool;
       gotOr, gotOr2: GB:=FResult.ResultBool or FSrc[I].Value.Result.ResultBool;
       gotXOr: GB:=FResult.ResultBool xor FSrc[I].Value.Result.ResultBool;
      end;
      if FResult.Temp then FResult.Free;
      FResult:=TGVBoolean.Create(True, False, GB);
     end;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

  procedure ValueAndOrXorSelf;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then Result:=FSrc[I-1].Value.Execute([grtInteger]);
    if Result then Result:=FSrc[I].Value.Execute([grtInteger]);
    if Result then begin
     if FSrc[I-1].Value.Result.DefaultType=grtBoolean then begin
      case FSrc[I].Operator of
       gotAndSelf: GB:=FSrc[I-1].Value.Result.ResultBool and FSrc[I].Value.Result.ResultBool;
       gotOrSelf: GB:=FSrc[I-1].Value.Result.ResultBool or FSrc[I].Value.Result.ResultBool;
       gotXOrSelf: GB:=FSrc[I-1].Value.Result.ResultBool xor FSrc[I].Value.Result.ResultBool;
      end;
      Result:=FSrc[I-1].Value.Result.SetValue(grtBoolean, GB);
     end else if FSrc[I-1].Value.Result.DefaultType=grtInteger then begin
      case FSrc[I].Operator of
       gotAndSelf: GI:=FSrc[I-1].Value.Result.ResultInt and FSrc[I].Value.Result.ResultInt;
       gotOrSelf: GI:=FSrc[I-1].Value.Result.ResultInt or FSrc[I].Value.Result.ResultInt;
       gotXOrSelf: GI:=FSrc[I-1].Value.Result.ResultInt xor FSrc[I].Value.Result.ResultInt;
      end;
      Result:=FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
     end else Result:=False;
     FResult:=FSrc[I-1].Value.Result;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

  procedure ValueShift;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result then if FResult=nil then begin
     Result:=FSrc[I-1].Value.Execute([grtInteger]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
    if Result then begin
     if FResult.DefaultType=grtInteger then begin
      case FSrc[I].Operator of
       gotShiftLeft: GI:=FResult.ResultInt shl FSrc[I].Value.Result.ResultInt;
       gotShiftRight: GI:=FResult.ResultInt shr FSrc[I].Value.Result.ResultInt;
      end;
      if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
      Result:=FResult.SetValue(grtInteger, GI);
     end else begin
      case FSrc[I].Operator of
       gotShiftLeft: GI:=FResult.ResultInt shl FSrc[I].Value.Result.ResultInt;
       gotShiftRight: GI:=FResult.ResultInt shr FSrc[I].Value.Result.ResultInt;
      end;
      if FResult.Temp then FResult.Free;
      FResult:=TGVInteger.Create(True, False, GI);
     end;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

  procedure ValueShiftSelf;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then Result:=FSrc[I-1].Value.Execute([grtInteger]);
    if Result then Result:=FSrc[I].Value.Execute([grtInteger]);
    if Result then begin
     if FSrc[I-1].Value.Result.DefaultType=grtInteger then begin
      if FSrc[I].Operator=gotShlSelf then GI:=FSrc[I-1].Value.Result.ResultInt shl FSrc[I].Value.Result.ResultInt
       else GI:=FSrc[I-1].Value.Result.ResultInt shr FSrc[I].Value.Result.ResultInt;
      FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
     end else Result:=False;
     FResult:=FSrc[I-1].Value.Result;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

  procedure ValueAdd;
  begin
    Result:=FSrc[I].Value<>nil;
    if Result then if (FResult=nil) and (I>0) then begin
     Result:=FSrc[I-1].Value.Execute([grtString, grtInteger, grtFloat]);
     FResult:=FSrc[I-1].Value.Result;
    end else Result:=True;
    if Result then
     if FResult=nil then begin
      Result:=FSrc[I].Value.Execute([grtString, grtInteger, grtFloat]);
      if Result then FResult:=FSrc[I].Value.Result;
     end else begin
      if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
      if Result then begin
       if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
       if (FResult.DefaultType=grtInteger) and (FSrc[I].Value.Result.DefaultType=grtInteger) then RType:=grtInteger
        else if (FResult.DefaultType=grtFloat) and (FSrc[I].Value.Result.DefaultType=grtFloat) then RType:=grtFloat
         else if (FResult.DefaultType=grtString) then RType:=grtString
          else if (FResult.DefaultType=grtArray) then RType:=grtArray
           else RType:=grtNone;
       case RType of
        grtArray: begin
         Result:=FResult.SetItem(FResult.Count, FSrc[I].Value.Result.Copy);
        end;
        grtString: begin
         GS:=FResult.ResultStr+FSrc[I].Value.Result.ResultStr;
         Result:=FResult.SetValue(grtString, GS);
        end;
        grtFloat: begin
         GF:=FResult.ResultFloat+FSrc[I].Value.Result.ResultFloat;
         Result:=FResult.SetValue(grtFloat, GF);
        end;
        grtInteger: begin
         GI:=FResult.ResultInt+FSrc[I].Value.Result.ResultInt;
         Result:=FResult.SetValue(grtInteger, GI);
        end;
        else begin
         GF:=FResult.ResultFloat+FSrc[I].Value.Result.ResultFloat;
         if FResult.Temp then FResult.Free;
         FResult:=TGVFloat.Create(True, False, GF);
        end;
       end;
       if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
      end;
     end;
  end;

  procedure ValueSubtract;
  begin
    Result:=FSrc[I].Value<>nil;
    if Result then if (FResult=nil) and (I>0) then begin
     Result:=FSrc[I-1].Value.Execute([grtInteger, grtFloat]);
     FResult:=FSrc[I-1].Value.Result;
    end else Result:=True;
    if Result then
     if FResult=nil then begin
      Result:=FSrc[I].Value.Execute([grtInteger, grtFloat]);
      if Result then begin
       FResult:=FSrc[I].Value.Result;
       if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
       case FResult.DefaultType of
        grtInteger: begin
         GI:=-FResult.ResultInt;
         FResult.SetValue(grtInteger, GI);
        end;
        grtFloat: begin
         GF:=-FResult.ResultFloat;
         FResult.SetValue(grtFloat, GF);
        end;
        else begin
         GF:=-FResult.ResultFloat;
         if FResult.Temp then FResult.Free;
         FResult:=TGVFloat.Create(True, False, GF);
        end;
       end;
      end;
     end else begin
      if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
       if Result then begin
        if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
        if (FResult.DefaultType=grtInteger) and (FSrc[I].Value.Result.DefaultType=grtInteger) then RType:=grtInteger
         else if (FResult.DefaultType=grtFloat) and (FSrc[I].Value.Result.DefaultType=grtFloat) then RType:=grtFloat
          else RType:=grtNone;
        case RType of
         grtFloat: begin
          GF:=FResult.ResultFloat-FSrc[I].Value.Result.ResultFloat;
          Result:=FResult.SetValue(grtFloat, GF);
         end;
         grtInteger: begin
          GI:=FResult.ResultInt-FSrc[I].Value.Result.ResultInt;
          Result:=FResult.SetValue(grtInteger, GI);
         end;
         else begin
          GF:=FResult.ResultFloat-FSrc[I].Value.Result.ResultFloat;
          if FResult.Temp then FResult.Free;
          FResult:=TGVFloat.Create(True, False, GF);
         end;
        end;
        if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
       end;
     end;
  end;

  procedure ValueMulDivRemPow;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result then if FResult=nil then begin
     Result:=FSrc[I-1].Value.Execute([grtInteger, grtFloat]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then begin                   
     Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
     if Result then begin
      if not FResult.Temp then begin FResult:=FResult.Copy; FResult.Temp:=True; end;
      if (FResult.DefaultType=grtInteger) and (FSrc[I].Value.Result.DefaultType=grtInteger) then RType:=grtInteger
       else if (FResult.DefaultType=grtFloat) and (FSrc[I].Value.Result.DefaultType=grtFloat) then RType:=grtFloat
        else RType:=grtNone;
      case RType of
       grtFloat: begin
        case FSrc[I].Operator of
         gotMultiply: GF:=FResult.ResultFloat*FSrc[I].Value.Result.ResultFloat;
         gotDivide: GF:=FResult.ResultFloat/FSrc[I].Value.Result.ResultFloat;
         gotRemainder: GF:=FloatRemainder(FResult.ResultFloat, FSrc[I].Value.Result.ResultFloat);
         gotPower: GF:=Power(FResult.ResultFloat, FSrc[I].Value.Result.ResultFloat);
        end;
        Result:=FResult.SetValue(grtFloat, GF);
       end;
       grtInteger: begin
        case FSrc[I].Operator of
         gotMultiply: GI:=FResult.ResultInt*FSrc[I].Value.Result.ResultInt;
         gotDivide: GI:=FResult.ResultInt div FSrc[I].Value.Result.ResultInt;
         gotRemainder: GI:=FResult.ResultInt mod FSrc[I].Value.Result.ResultInt;
         gotPower: GI:=Round(Power(FResult.ResultInt, FSrc[I].Value.Result.ResultFloat));
        end;
        Result:=FResult.SetValue(grtInteger, GI);
       end;
       else begin
        case FSrc[I].Operator of
         gotMultiply: GF:=FResult.ResultFloat*FSrc[I].Value.Result.ResultFloat;
         gotDivide: GF:=FResult.ResultFloat/FSrc[I].Value.Result.ResultFloat;
         gotRemainder: GF:=FloatRemainder(FResult.ResultFloat, FSrc[I].Value.Result.ResultFloat);
         gotPower: GF:=Power(FResult.ResultFloat, FSrc[I].Value.Result.ResultFloat);
        end;
        if FResult.Temp then FResult.Free;
        FResult:=TGVFloat.Create(True, False, GF);
       end;
      end;
      if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
     end;
    end;
  end;

  procedure ValueMulDivRemPowSelf;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then Result:=FSrc[I-1].Value.Execute([grtInteger, grtFloat]);
    if Result then Result:=FSrc[I].Value.Execute([grtInteger, grtFloat]);
    if Result then begin
     case FSrc[I-1].Value.Result.DefaultType of
      grtFloat: begin
       case FSrc[I].Operator of
        gotMulSelf: GF:=FSrc[I-1].Value.Result.ResultFloat*FSrc[I].Value.Result.ResultFloat;
        gotDivSelf: GF:=FSrc[I-1].Value.Result.ResultFloat/FSrc[I].Value.Result.ResultFloat;
        gotRemSelf: GF:=FloatRemainder(FSrc[I-1].Value.Result.ResultFloat, FSrc[I].Value.Result.ResultFloat);
        gotPowSelf: GF:=Power(FSrc[I-1].Value.Result.ResultFloat, FSrc[I].Value.Result.ResultFloat);
       end;
       Result:=FSrc[I-1].Value.Result.SetValue(grtFloat, GF);
       end;
      grtInteger: begin
       case FSrc[I].Operator of
        gotMulSelf: GI:=FSrc[I-1].Value.Result.ResultInt*FSrc[I].Value.Result.ResultInt;
        gotDivSelf: GI:=FSrc[I-1].Value.Result.ResultInt div FSrc[I].Value.Result.ResultInt;
        gotRemSelf: GI:=FSrc[I-1].Value.Result.ResultInt mod FSrc[I].Value.Result.ResultInt;
        gotPowSelf: GI:=Round(Power(FSrc[I-1].Value.Result.ResultInt, FSrc[I].Value.Result.ResultFloat));
       end;
       Result:=FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
      end;
      else Result:=False;
      FResult:=FSrc[I-1].Value.Result;
      if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
     end;
    end;
  end;

  procedure ValueAssign;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then begin
     Result:=TGBVariable(FSrc[I-1].Value).SetSrc(FSrc[I].Value);
     if Result and (ResultType<>[grtNone]) then begin
      Result:=FSrc[I-1].Value.Execute(ResultType);
      if Result then FResult:=FSrc[I-1].Value.Result;
     end;
    end;
  end;

  procedure ValueIncDec;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then Result:=FSrc[I-1].Value.Execute([grtInteger, grtFloat, grtString, grtArray]);
    if Result then Result:=FSrc[I].Value.Execute([grtInteger, grtFloat, grtString]);
    if Result then begin
     if (FSrc[I-1].Value.Result.DefaultType=grtArray) and (FSrc[I].Operator<>gotAddLeft) then begin
      if FSrc[I].Operator=gotInc then begin
       Result:=FSrc[I-1].Value.Result.SetItem(FSrc[I-1].Value.Result.Count, FSrc[I].Value.Result.Copy);
      end else Result:=False;
     end else if FSrc[I-1].Value.Result.DefaultType=grtString then begin
      if FSrc[I].Operator=gotInc then begin
       GS:=FSrc[I-1].Value.Result.ResultStr+FSrc[I].Value.Result.ResultStr;
       FSrc[I-1].Value.Result.SetValue(grtString, GS);
      end else if FSrc[I].Operator=gotAddLeft then begin
       GS:=FSrc[I].Value.Result.ResultStr+FSrc[I-1].Value.Result.ResultStr;
       FSrc[I-1].Value.Result.SetValue(grtString, GS);
      end else Result:=False;
     end else if (FSrc[I-1].Value.Result.DefaultType=grtInteger) and (FSrc[I].Operator<>gotAddLeft) then begin
      if FSrc[I].Operator=gotInc then GI:=FSrc[I-1].Value.Result.ResultInt+FSrc[I].Value.Result.ResultInt
       else GI:=FSrc[I-1].Value.Result.ResultInt-FSrc[I].Value.Result.ResultInt;
      FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
     end else if (FSrc[I-1].Value.Result.DefaultType=grtFloat) and (FSrc[I].Operator<>gotAddLeft) then begin
      if FSrc[I].Operator=gotInc then GF:=FSrc[I-1].Value.Result.ResultFloat+FSrc[I].Value.Result.ResultFloat
       else GF:=FSrc[I-1].Value.Result.ResultFloat-FSrc[I].Value.Result.ResultFloat;
      FSrc[I-1].Value.Result.SetValue(grtFloat, GF);
     end else Result:=False;
     FResult:=FSrc[I-1].Value.Result;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

  procedure ValueIncDecOne;
  begin
    Result:=((FSrc[I].Value<>nil) xor (I>0)) and (FResult=nil);
    if Result then if I>0 then begin
     Result:=FSrc[I-1].Value is TGBVariable;
     if Result then Result:=FSrc[I-1].Value.Execute([grtInteger]);
     if Result then if FSrc[I].Operator=gotIncOne then GI:=FSrc[I-1].Value.Result.ResultInt+1
      else GI:=FSrc[I-1].Value.Result.ResultInt-1;
     if Result then Result:=FSrc[I-1].Value.Result.SetValue(grtInteger, GI);
     if Result then FResult:=FSrc[I-1].Value.Result;
    end else begin
     Result:=FSrc[I].Value is TGBVariable;
     if Result then Result:=FSrc[I].Value.Execute([grtInteger]);
     if Result then if ResultType<>[grtNone] then begin
      FResult:=FSrc[I].Value.Result.Copy;
      FResult.Temp:=True;
     end;
     if FSrc[I].Operator=gotIncOne then GI:=FSrc[I].Value.Result.ResultInt+1
      else GI:=FSrc[I].Value.Result.ResultInt-1;
     if Result then Result:=FSrc[I].Value.Result.SetValue(grtInteger, GI);
    end;
  end;

  procedure ValueCompare;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result and (FResult=nil) then begin
     Result:=FSrc[I-1].Value.Execute([grtDefault]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
    if Result then begin
     if FSrc[I].Operator=gotUnEqual2 then FSrc[I].Operator:=gotUnEqual;
     NewResult:=TGVBoolean.Create(True, False, FResult.Compare(FSrc[I].Value.Result, FSrc[I].Operator));
     if FResult.Temp then FResult.Free;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
     FResult:=NewResult;
    end;
  end;

  procedure ValueIdentical;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result and (FResult=nil) then begin
     Result:=FSrc[I-1].Value.Execute([grtDefault]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([FResult.DefaultType]);
    if Result then begin
     GB:=(FSrc[I].Value.Result.DefaultType=FResult.DefaultType) and FResult.Compare(FSrc[I].Value.Result, gotEqual);
     if FSrc[I].Operator=gotUnIdentical then GB:=not GB;
     if FResult.Temp then FResult.Free;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
     FResult:=TGVBoolean.Create(True, False, GB);
    end;
  end;

  procedure ValueMatch;
  var R: TRegExpr;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result and (FResult=nil) then begin
     Result:=FSrc[I-1].Value.Execute([grtString]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([grtString]);
    if Result then begin
     R:=TRegExpr.Create;
     R.ModifierI:=False; R.ModifierR:=False; R.ModifierS:=False; R.ModifierG:=False; R.ModifierM:=False; R.ModifierX:=False;
     R.ModifierStr:=GetRegExp(1, FSrc[I].Value.Result.ResultStr);
     R.Expression:=GetRegExp(0, FSrc[I].Value.Result.ResultStr);
     GB:=R.Exec(FSrc[I-1].Value.Result.ResultStr);
     R.Free;
     if FResult.Temp then FResult.Free;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
     FResult:=TGVBoolean.Create(True, False, GB xor (FSrc[I].Operator=gotNoMatch));
    end;
  end;

  procedure ValueReplace;
  var R: TRegExpr;
      Pieces: TStrings;
      J: integer;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0);
    if Result and (FResult=nil) then begin
     Result:=FSrc[I-1].Value.Execute([grtString]);
     FResult:=FSrc[I-1].Value.Result;
    end;
    if Result then Result:=FSrc[I].Value.Execute([grtString]);
    if Result then begin
     R:=TRegExpr.Create;
     R.ModifierI:=False; R.ModifierR:=False; R.ModifierS:=False; R.ModifierG:=False; R.ModifierM:=False; R.ModifierX:=False;
     R.Expression:=GetRegExp(0, FSrc[I].Value.Result.ResultStr);
     if FSrc[I].Operator=gotReplace then begin
      R.ModifierStr:=GetRegExp(2, FSrc[I].Value.Result.ResultStr);
      GS:=R.Replace(FSrc[I-1].Value.Result.ResultStr, GetRegExp(1, FSrc[I].Value.Result.ResultStr), True);
      R.Free;
      if FResult.Temp then FResult.Free;
      if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
      FResult:=TGVString.Create(True, False, GS);
     end else begin
      Pieces:=TStringList.Create;
      R.ModifierStr:=GetRegExp(1, FSrc[I].Value.Result.ResultStr);
      R.Split(FSrc[I-1].Value.Result.ResultStr, Pieces);
      R.Free;
      if FResult.Temp then FResult.Free;
      if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
      FResult:=TGVArray.Create(True, False, []);
      for J:=0 to Pieces.Count-1 do
       FResult.SetItem(J, TGVString.Create(False, False, Pieces[j]));
      Pieces.Free;      
     end;
    end;
  end;

  procedure ValueReplaceSelf;
  var R: TRegExpr;
  begin
    Result:=(FSrc[I].Value<>nil) and (I>0) and (FResult=nil);
    if Result then Result:=FSrc[I-1].Value is TGBVariable;
    if Result then Result:=FSrc[I-1].Value.Execute([grtString]);
    if Result then Result:=FSrc[I].Value.Execute([grtString]);
    if Result then begin
     if FSrc[I-1].Value.Result.DefaultType=grtString then begin
      R:=TRegExpr.Create;
      R.ModifierI:=False; R.ModifierR:=False; R.ModifierS:=False; R.ModifierG:=False; R.ModifierM:=False; R.ModifierX:=False;
      R.ModifierStr:=GetRegExp(2, FSrc[I].Value.Result.ResultStr);
      R.Expression:=GetRegExp(0, FSrc[I].Value.Result.ResultStr);
      GS:=R.Replace(FSrc[I-1].Value.Result.ResultStr, GetRegExp(1, FSrc[I].Value.Result.ResultStr), True);
      R.Free;
      FSrc[I-1].Value.Result.SetValue(grtString, GS);
     end else Result:=False;
     FResult:=FSrc[I-1].Value.Result;
     if FSrc[I].Value.Result.Temp then FSrc[I].Value.Result.Free;
    end;
  end;

begin
 FResult:=nil;
 Result:=False;
 for I:=Low(FSrc) to High(FSrc) do begin
  case FSrc[I].Operator of
   gotNot: ValueNot;
   gotNotSelf: ValueNotSelf;
   gotAnd, gotOr, gotXor, gotAnd2, gotOr2: ValueAndOrXor;
   gotAndSelf, gotOrSelf, gotXorSelf: ValueAndOrXorSelf;
   gotShiftLeft, gotShiftRight: ValueShift;
   gotShlSelf, gotShrSelf: ValueShiftSelf;
   gotAdd: ValueAdd;
   gotSubtract: ValueSubtract;
   gotMultiply, gotDivide, gotRemainder, gotPower: ValueMulDivRemPow;
   gotMulSelf, gotDivSelf, gotRemSelf, gotPowSelf: ValueMulDivRemPowSelf;
   gotAssign: ValueAssign;
   gotInc, gotDec, gotAddLeft: ValueIncDec;
   gotIncOne, gotDecOne: ValueIncDecOne;
   gotEqual, gotUnEqual, gotUnEqual2, gotSmaller, gotBigger, gotSmallerEq, gotBiggerEq: ValueCompare;
   gotIdentical, gotUnIdentical: ValueIdentical;
   gotMatch, gotNoMatch: ValueMatch;
   gotReplace, gotSplit: ValueReplace;
   gotRepSelf: ValueReplaceSelf;
   gotNone: Result:=True;
   else Result:=False;
  end;
  if not Result then Exit;
 end;
end;

procedure TGBGetValue.Add(const Src: TGValueData);
begin
 SetLength(FSrc, High(FSrc)+2);
 FSrc[High(FSrc)]:=Src;
end;

procedure TGBGetValue.Compile;
var I, J, K, L, MinP, MaxP: integer;
    Block: TGBGetValue;
begin
 MinP:=255; MaxP:=0;
 for I:=Low(FSrc) to High(FSrc) do if GC_OperatorPriority[FSrc[I].Operator]>0 then begin
  MinP:=Min(MinP, GC_OperatorPriority[FSrc[I].Operator]);
  MaxP:=Max(MaxP, GC_OperatorPriority[FSrc[I].Operator]);
 end;
 if (MinP<255) and (MaxP>0) and (MinP<>MaxP) then begin
  I:=0;
  K:=0;
  J:=-1;
  while I<=High(FSrc) do begin
   if Max(MinP, GC_OperatorPriority[FSrc[I].Operator])=MinP then J:=I;
   Inc(I);
   while I<=High(FSrc) do if GC_OperatorPriority[FSrc[I].Operator]>MinP then Inc(I) else Break;
   if J=I-1 then FSrc[K]:=FSrc[J]
    else begin
     Block:=TGBGetValue.Create(Self);
     if J=-1 then begin
      Inc(J);
      Block.Add(FSrc[J]);
      FSrc[K]:=GValueData(gotNone, Block);
     end else begin
      Block.Add(GValueData(gotNone, FSrc[J].Value));
      FSrc[K]:=GValueData(FSrc[J].Operator, Block);
     end;
     for L:=J+1 to I-1 do
      Block.Add(FSrc[L]);
     Block.Compile;
    end;
   Inc(K);
  end;
  SetLength(FSrc, K);
 end;
end;

{ TGBIf }

constructor TGBIf.Create(AParent, Exp: TGCustomBlock);
begin
 inherited Create(AParent);
 FExp:=Exp;
end;

destructor TGBIf.Destroy;
begin
 FExp.Free;
 FElse.Free;
 inherited;
end;

function TGBIf.Execute(ResultType: TGResultTypes): Boolean;
begin
 Result:=FExp.Execute([grtBoolean]);
 if Result then begin
  if FExp.Result.ResultBool then Result:=inherited Execute(ResultType)
   else if FElse<>nil then begin
    Result:=FElse.Execute(ResultType);
    if Result then FResult:=FElse.Result;
   end;
  if FExp.Result.Temp then FExp.Result.Free;
 end;
end;

{ TGBVariable }

constructor TGBVariable.Create(AParent: TGCustomBlock; const Name: string);
begin
 inherited Create(AParent);
 FName:=Name;
end;

{ TGBFor }

constructor TGBFor.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBFor.Destroy;
begin
 FInit.Free;
 FCond.Free;
 FStep.Free;
 inherited;
end;

function TGBFor.Execute(ResultType: TGResultTypes): Boolean;
begin
 FResult:=nil;
 Result:=FInit.Execute([grtNone]);
 if Result then begin
  if FInit.Result<>nil then if FInit.Result.Temp then FInit.Result.Free;
  Result:=FCond.Execute([grtBoolean]);
  if Result then begin
   while FCond.Result.ResultBool do begin
    if FCond.Result.Temp then FCond.Result.Free;
    Result:=inherited Execute(ResultType);
    if Result then Result:=FStep.Execute([grtNone]);
    if FStep.Result<>nil then if FStep.Result.Temp then FStep.Result.Free;
    if Result then Result:=FCond.Execute([grtBoolean]);
    if not Result then Break;
   end;
   if Result then if FCond.Result.Temp then FCond.Result.Free;
  end;
 end;
end;

{ TGBWhile }

constructor TGBWhile.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBWhile.Destroy;
begin
 FCond.Free;
 inherited;
end;

function TGBWhile.Execute(ResultType: TGResultTypes): Boolean;
begin
 Result:=FCond.Execute([grtBoolean]);
 if Result then begin
  while FCond.Result.ResultBool do begin
   if FCond.Result.Temp then FCond.Result.Free;
   Result:=inherited Execute(ResultType);
   if Result then Result:=FCond.Execute([grtBoolean]);
   if not Result then Break;
  end;
  if Result then if FCond.Result.Temp then FCond.Result.Free;
 end;
end;

{ TGBRepeat }

constructor TGBRepeat.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBRepeat.Destroy;
begin
 FCond.Free;
 inherited;
end;

function TGBRepeat.Execute(ResultType: TGResultTypes): Boolean;
var Stop: Boolean;
begin
 repeat
  Result:=inherited Execute(ResultType);
  if Result then Result:=FCond.Execute([grtBoolean]);
  if Result then begin
   Stop:=FCond.Result.ResultBool;
   if FCond.Result.Temp then FCond.Result.Free;
  end else Stop:=True;
 until Stop;
end;

{ TGBForeach }

constructor TGBForeach.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBForeach.Destroy;
begin
 FSrc.Free;
 inherited;
end;

function TGBForeach.Execute(ResultType: TGResultTypes): Boolean;
var I: integer;
    Item: TGCustomVariant;
    Temp: Boolean;
    Global: Boolean;
begin
 Global:=False;
 Result:=FSrc.Execute([grtDefault]);
 if Result then Result:=FSrc.Result.Indexed;
 if Result then
  for I:=0 to FSrc.Result.Count-1 do begin
   Result:=FSrc.Result.GetItem(I, Item) and (Item<>nil);
   if Result then begin
    Temp:=Item.Temp;
    Item.Temp:=False;
    Global:=SubScript=nil;
    if Global then Script.SetVariable(GC_CurrentVar, Item)
     else SubScript.SetVariable(GC_CurrentVar, Item);
    Result:=inherited Execute(ResultType);
    if Temp then begin
     if not FSrc.Result.Temp then FSrc.Result.SetItem(I, Item)
      else Item.Free;
    end;
   end;
   if not Result then Break;
  end;
 if Result then begin
  if FSrc.Result.Count>0 then if Global then Script.UnsetVariable(GC_CurrentVar)
   else SubScript.UnsetVariable(GC_CurrentVar);
  if FSrc.Result.Temp then FSrc.Result.Free;
 end;
end;

{ TGBReturn }

constructor TGBReturn.Create(AParent: TGCustomBlock);
begin
 inherited Create(AParent);
end;

destructor TGBReturn.Destroy;
begin
 FSrc.Free;
 FResult:=nil;
 inherited;
end;

function TGBReturn.Execute(ResultType: TGResultTypes): Boolean;
begin
 if SubScript<>nil then SubScript.Stop:=True;
 Result:=FSrc.Execute([grtDefault]);
 FResult:=FSrc.Result;
end;

end.
