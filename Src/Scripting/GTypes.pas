unit GTypes;

interface

uses
  Classes, SysUtils, Windows, Math;

type
  TGCustomBlock = class;
  TGCustomScript = class;
  TGCustomVariant = class;
  TGCustomModule = class;

  PGArrayKey = ^TGArrayKey;
  TGArrayKey = record
    Key: string;
    Index: Cardinal;
  end;

  TGArray = class(TPersistent)
  private
    FKeys: array[#95..#122] of array of TGArrayKey;
    FItems: Pointer;
    FCount: Cardinal;
    FItemSize: Cardinal;
    FCapacity: Cardinal;
    FAllocated: Cardinal;
    procedure SetCount(Value: Cardinal);
  public
    constructor Create(ItemSize: Cardinal);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function KeyIndex(const Key: string): integer;
    function IndexKey(Index: Cardinal): string;
    function GetItem(Index: Cardinal; var Item): Boolean; overload;
    function GetItem(const Key: string; var Item): Boolean; overload;
    function SetItem(Index: Cardinal; const Item): Boolean; overload;
    function SetItem(const Key: string; const Item): Boolean; overload;
    function Item(Index: Cardinal): Pointer;
    procedure Remove(Index: Cardinal); overload;
    procedure Remove(const Key: string); overload;
    procedure SetCapacity(ACount: Cardinal);
    property Count: Cardinal read FCount write SetCount;
    function KeyCount: integer;
    function Key(Index: integer): PGArrayKey;
  end;
                                          
  TGChars = set of Char;
  
  TGStructureType = (gstFunction, gstIf, gstFor, gstWhile, gstRepeat, gstForeach,
                     gstReturn, gstNone); //None must be the last

  TGFunctionType = (gftGlobal, gftLocal, gftNone); //None must be the last

  TGOperatorType = (gotAdd, gotSubtract, gotMultiply, gotDivide, gotRemainder,
                    gotPower, gotReplace, gotSplit, gotNot, gotAnd, gotOr,
                    gotNotSelf, gotAnd2, gotOr2, gotXor, gotAndSelf, gotOrSelf,
                    gotXorSelf, gotEqual, gotUnEqual, gotUnEqual2, gotSmaller,
                    gotBigger, gotSmallerEq, gotBiggerEq, gotIdentical,
                    gotUnIdentical, gotMatch, gotNoMatch, gotAssign, gotRepSelf,
                    gotIncOne, gotDecOne, gotInc, gotAddLeft, gotDec, gotMulSelf,
                    gotDivSelf, gotRemSelf, gotPowSelf, gotShiftLeft,
                    gotShiftRight, gotShlSelf, gotShrSelf, gotNone); //None must be the last

  TGResultType = (grtNone, grtDefault, grtBoolean, grtInteger, grtFloat,
                  grtString, grtArray, grtObject, grtCustom);
  TGResultTypes = set of TGResultType;

  GBool = Boolean;
  GInt = Int64;
  GFloat = Extended;
  GString = String;

  TGOutProc = function(const S: string): Boolean of object;

  TGFunction = function(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean of object;

  TGCustomBlock = class(TPersistent)
  protected
    function GetResult: TGCustomVariant; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    function Execute(ResultType: TGResultTypes): Boolean; virtual; abstract;
    function Return(Value: TGCustomVariant): Boolean; virtual;
    property Result: TGCustomVariant read GetResult;
  end;

  TGValueData = record
    Operator: TGOperatorType;
    Value: TGCustomBlock;
  end;

  TGVariableKey = record
    KeyType: TGResultType;
    Value: TGCustomBlock;
  end;

  TGCustomVariant = class(TGCustomBlock)
  protected
    FTemp: Boolean;
    FIndexed: Boolean;
    FKeyed: Boolean;
    FConst: Boolean;
  protected
    constructor Create(Temp, IsConst, Indexed, Keyed: Boolean);
    function GetResult: TGCustomVariant; override;
    function GetResultBool: GBool; virtual; abstract;
    function GetResultInt: GInt; virtual; abstract;
    function GetResultFloat: GFloat; virtual; abstract;
    function GetResultStr: GString; virtual; abstract;
    function GetDefaultType: TGResultType; virtual; abstract;
  public
    function Copy: TGCustomVariant; virtual; abstract;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; virtual; abstract;
    function SetValue(ValueType: TGResultType; const Value): Boolean; virtual; abstract;
    function SetItem(Index: integer; Item: TGCustomVariant): Boolean; overload; virtual;
    function SetItem(const Key: string; Item: TGCustomVariant): Boolean; overload; virtual;
    function GetItem(Index: integer; out Item: TGCustomVariant): Boolean; overload; virtual;
    function GetItem(const Key: string; out Item: TGCustomVariant): Boolean; overload; virtual;
    function UnSetItem(Index: integer): Boolean; overload; virtual;
    function UnSetItem(const Key: string): Boolean; overload; virtual;
    function Count: integer; virtual;
    function Keys: TGCustomVariant; virtual;
    function Sort: Boolean; virtual;
    property ResultBool: GBool read GetResultBool;
    property ResultInt: GInt read GetResultInt;
    property ResultFloat: GFloat read GetResultFloat;
    property ResultStr: GString read GetResultStr;
    property DefaultType: TGResultType read GetDefaultType;
    property Temp: Boolean read FTemp write FTemp;
    property Indexed: Boolean read FIndexed;
    property Keyed: Boolean read FKeyed;
    property IsConst: Boolean read FConst;
  end;
  TGVariantClass = class of TGCustomVariant;

  TGModuleClass = class of TGCustomModule;
  TGModuleInfo = record
    Name: string;
    Module: TGModuleClass;
  end;

  PGScriptOptions = ^TGScriptOptions;
  TGScriptOptions = record
    SafeMode: Boolean;
    IODisabled: Boolean;
  end;

  TGOnLoad = function(const Name: string; out Src: string): Boolean of object;
  
  TGCustomScript = class(TGCustomBlock)
  protected
    FOutProc: TGOutProc;
    FErrorProc: TGOutProc;
    FSilentError: integer;
    FAbstractSrc: TGCustomBlock;
    FOptions: TGScriptOptions;
    FOnLoad: TGOnLoad;
  public
    constructor Create;
    property OutProc: TGOutProc read FOutProc write FOutProc;
    property ErrorProc: TGOutProc read FErrorProc write FErrorProc;
    property SilentError: integer read FSilentError write FSilentError;
    property AbstractSrc: TGCustomBlock read FAbstractSrc;
    property OnLoad: TGOnLoad read FOnLoad write FOnLoad;
    function Error(Id: Cardinal; const S: string; Sender: TGCustomBlock): Boolean; virtual; abstract;
    function GetFunction(const Name: string): TGFunction; virtual; abstract;
    function GetVariable(const Name: string): TGCustomVariant; virtual; abstract;
    procedure SetVariable(const Name: string; Item: TGCustomVariant); virtual; abstract;
    procedure UnsetVariable(const Name: string); virtual; abstract;
    function LoadModule(Module: TGModuleClass): TGCustomModule; virtual; abstract;
    procedure RegisterFunction(const Name: string; Item: TGFunction); virtual; abstract;
    procedure UnregisterFunction(const Name: string); virtual; abstract;
    property Options: TGScriptOptions read FOptions write FOptions;
  end;

  TGCustomModule = class
  protected
    FScript: TGCustomScript;
  public
    constructor Create(Script: TGCustomScript); virtual;
    procedure Unload; virtual; abstract;
  end;

  function GModuleCount: integer;
  function GModule(Index: integer): TGModuleInfo;
  procedure GRegisterModule(const Name: string; Module: TGModuleClass);
  function GDefaultModuleCount: integer;
  function GDefaultModule(Index: integer): TGModuleClass;
  procedure GRegisterDefaultModule(const Name: string; Module: TGModuleClass);

  function GBlockCount: integer;

  function GValueData(Operator: TGOperatorType; Value: TGCustomBlock): TGValueData;
  function GVariableKey(KeyType: TGResultType; Value: TGCustomBlock): TGVariableKey;

  function GFindFile(const FileName: string; out FilePath: string): Boolean;

implementation

var
  FGModules: array of TGModuleInfo;
  FGDefaultModules: array of TGModuleClass;

function GModuleCount: integer;
begin
 Result:=High(FGModules)+1;
end;

function GModule(Index: integer): TGModuleInfo;
begin
 Result:=FGModules[Index];
end;

procedure GRegisterModule(const Name: string; Module: TGModuleClass);
begin
 SetLength(FGModules, GModuleCount+1);
 FGModules[High(FGModules)].Name:=LowerCase(Name);
 FGModules[High(FGModules)].Module:=Module;
end;

function GDefaultModuleCount: integer;
begin
 Result:=High(FGDefaultModules)+1;
end;

function GDefaultModule(Index: integer): TGModuleClass;
begin
 Result:=FGDefaultModules[Index];
end;

procedure GRegisterDefaultModule(const Name: string; Module: TGModuleClass);
begin
 GRegisterModule(Name, Module);
 SetLength(FGDefaultModules, GDefaultModuleCount+1);
 FGDefaultModules[High(FGDefaultModules)]:=Module;
end;

var
  TotalBlocks: integer = 0;

function GBlockCount: integer;
begin
 Result:=TotalBlocks;
end;

function GValueData(Operator: TGOperatorType; Value: TGCustomBlock): TGValueData;
begin
 Result.Operator:=Operator;
 Result.Value:=Value;
end;

function GVariableKey(KeyType: TGResultType; Value: TGCustomBlock): TGVariableKey;
begin
 Result.KeyType:=KeyType;
 Result.Value:=Value;
end;

function GFindFile(const FileName: string; out FilePath: string): Boolean;
begin
 FilePath:=IncludeTrailingPathDelimiter(GetCurrentDir)+FileName;
 Result:=FileExists(FilePath);
end;

{ TGCustomVariant }

function TGCustomVariant.Count: integer;
begin
 Result:=0;
end;

constructor TGCustomVariant.Create(Temp, IsConst, Indexed, Keyed: Boolean);
begin
 inherited Create;
 FTemp:=Temp;
 FIndexed:=Indexed;
 FKeyed:=Keyed;
 FConst:=IsConst;
end;

function TGCustomVariant.Execute(ResultType: TGResultTypes): Boolean;
begin
 Result:=True;
end;

function TGCustomVariant.GetItem(Index: integer; out Item: TGCustomVariant): Boolean;
begin
 Result:=False;
end;
function TGCustomVariant.GetItem(const Key: string; out Item: TGCustomVariant): Boolean;
begin
 Result:=False;
end;

function TGCustomVariant.GetResult: TGCustomVariant;
begin
 Result:=Self;
end;

function TGCustomVariant.SetItem(Index: integer; Item: TGCustomVariant): Boolean;
begin
 Result:=False;
end;

function TGCustomVariant.Keys: TGCustomVariant;
begin
 Result:=nil;
end;

function TGCustomVariant.SetItem(const Key: string; Item: TGCustomVariant): Boolean;
begin
 Result:=False;
end;

function TGCustomVariant.UnSetItem(Index: integer): Boolean;
begin
 Result:=False;
end;

function TGCustomVariant.UnSetItem(const Key: string): Boolean;
begin
 Result:=False;
end;

function TGCustomVariant.Sort: Boolean;
begin
 Result:=False;
end;

{ TGArray }

procedure TGArray.Assign(Source: TPersistent);
var I: Char;
begin
 if Source is TGArray then begin
  //FKeys:=Copy(TGArray(Source).FKeys);
  for I:=#95 to #122 do
   FKeys[I]:=Copy(TGArray(Source).FKeys[I]);
  FCount:=TGArray(Source).FCount;
  FItemSize:=TGArray(Source).FItemSize;
  FCapacity:=TGArray(Source).FCapacity;
  SetCount(FCount);
  CopyMemory(FItems, TGArray(Source).FItems, FCount*FItemSize);
 end;
end;

constructor TGArray.Create(ItemSize: Cardinal);
begin
 inherited Create;
 FItemSize:=ItemSize;
end;

destructor TGArray.Destroy;
begin
 FreeMem(FItems);
 inherited;
end;

function TGArray.GetItem(Index: Cardinal; var Item): Boolean;
begin
 Result:=Index<FCount;
 if Result then CopyMemory(@Item, Pointer(Cardinal(FItems)+Index*FItemSize), FItemSize);
end;

function TGArray.GetItem(const Key: string; var Item): Boolean;
begin
 Result:=GetItem(KeyIndex(LowerCase(Key)), Item);
end;

function TGArray.IndexKey(Index: Cardinal): string;
var I: integer;
    J: Char;
begin
 Result:='';
 for J:=#95 to #122 do
  for I:=High(FKeys[J]) downto Low(FKeys[J]) do
   if FKeys[J,I].Index=Index then begin
    Result:=FKeys[J,I].Key;
    Break;
   end;
end;

function TGArray.Item(Index: Cardinal): Pointer;
begin
 Result:=Pointer(Cardinal(FItems)+Index*FItemSize);
end;

function TGArray.Key(Index: integer): PGArrayKey;
var J: Char;
begin
 Result:=nil;
 for J:=#95 to #122 do
  if Index<=High(FKeys[J]) then begin
   Result:=@(FKeys[J][Index]);
   Break;
  end else Index:=Index-High(FKeys[J])-1;
end;

function TGArray.KeyCount: integer;
var J: Char;
begin
 Result:=0;
 for J:=#95 to #122 do
  Inc(Result, High(FKeys[J])+1);
end;

function TGArray.KeyIndex(const Key: string): integer;
var I: integer;
begin
 Result:=-1;
 for I:=High(FKeys[Key[1]]) downto Low(FKeys[Key[1]]) do
  if FKeys[Key[1], I].Key=Key then begin
   Result:=FKeys[Key[1], I].Index;
   Break;
  end;
end;

procedure TGArray.Remove(Index: Cardinal);
var I, J: integer;
    K: Char;
begin
 for K:=#95 to #122 do begin
  J:=High(FKeys[K])+1;
  for I:=Low(FKeys[K]) to High(FKeys[K]) do begin
   if FKeys[K][I].Index>Index then Dec(FKeys[K][I].Index)
    else if FKeys[K][I].Index=Index then J:=I;
   if I>J then FKeys[K][I-1]:=FKeys[K][I];
  end;
  if J<=High(FKeys[K]) then SetLength(FKeys[K], High(FKeys[K]));
 end;
 if Index<FCount-1 then CopyMemory(Pointer(Cardinal(FItems)+Index*FItemSize), Pointer(Cardinal(FItems)+(Index+1)*FItemSize), (FCount-Index-1)*FItemSize);
 if Index<FCount then SetCount(FCount-1);
end;

procedure TGArray.Remove(const Key: string);
begin
 Remove(KeyIndex(LowerCase(Key)));
end;

procedure TGArray.SetCapacity(ACount: Cardinal);
begin
 FCapacity:=ACount*FItemSize;
 SetCount(FCount);
end;

procedure TGArray.SetCount(Value: Cardinal);
begin
 FCount:=Value;
 Value:=Max(FCount*FItemSize, FCapacity);
 ReAllocMem(FItems, Value);
 if Value>FAllocated then
  ZeroMemory(Pointer(Cardinal(FItems)+FAllocated), Value-FAllocated);
 FAllocated:=Value;
end;

function TGArray.SetItem(Index: Cardinal; const Item): Boolean;
begin
 if Index>=FCount then SetCount(Index+1);
 CopyMemory(Pointer(Cardinal(FItems)+Index*FItemSize), @Item, FItemSize);
 Result:=True;
end;

function TGArray.SetItem(const Key: string; const Item): Boolean;
var Index: integer;
    C: Char;
begin
 Result:=True;
 Index:=KeyIndex(LowerCase(Key));
 if Index<0 then begin
  Index:=FCount;
  C:=LowerCase(Key[1])[1];
  SetLength(FKeys[C], High(FKeys[C])+2);
  FKeys[C][High(FKeys[C])].Key:=LowerCase(Key);
  FKeys[C][High(FKeys[C])].Index:=Index;
 end;
 SetItem(Index, Item);
end;

{ TGCustomModule }

constructor TGCustomModule.Create(Script: TGCustomScript);
begin
 inherited Create;
 FScript:=Script;
end;

{ TGCustomBlock }

constructor TGCustomBlock.Create;
begin
 inherited;
 Inc(TotalBlocks);
end;

destructor TGCustomBlock.Destroy;
begin
 Dec(TotalBlocks);
 inherited;
end;

function TGCustomBlock.Return(Value: TGCustomVariant): Boolean;
begin
 Result:=True;
end;

{ TGCustomScript }

constructor TGCustomScript.Create;
begin
 inherited;
 with Options do SafeMode:=True;
end;

end.
 