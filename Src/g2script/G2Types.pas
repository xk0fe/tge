unit G2Types;

interface

uses
  Classes, SysUtils, Math, Windows;

type
  TG2Variant = class;
  TG2VReference = class;
  TG2Array = class;

  PG2ArrayKey = ^TG2ArrayKey;
  TG2ArrayKey = record
    Key: string;
    Index: integer;
  end;

  PG2ArrayItem = ^TG2ArrayItem;
  TG2ArrayItem = record
    KeyIndex: integer;
    Data: Pointer;
  end;

  TG2Array = class
  private
    FItems: TList;
    FKeys: TList;
    function GetCount: integer;
    function GetKey(const AIndex: integer): string;
    function GetKeyCount: integer;
    procedure UpdateKeyIndices(const AFrom: integer = 0);
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOf(const AItem: Pointer): integer; overload;
    function IndexOf(const AKey: string): integer; overload;
    function ClosestKeyIndex(const AKey: string; out Found: Boolean): integer;
    function KeyIndex(const AIndex: integer): integer;
    function Add(const AItem: Pointer): Pointer; overload;
    function Add(const AItem: Pointer; const AKey: string): Pointer; overload;
    function AddOrGet(const AItem: Pointer; const AKey: string): Pointer;
    procedure Remove(const AItem: Pointer); 
    procedure Delete(const AKey: string); overload;
    procedure Delete(const AIndex: integer); overload;
    procedure Clear;
    procedure Exchange(const AIndex1, AIndex2: integer);
    procedure Fill(const ACount: integer; const AItem: Pointer = nil);
    function GetItemByIndex(const AIndex: integer): Pointer;
    function GetItemByKey(const AKey: string): Pointer;
    function SetItemByIndex(const AIndex: integer; const Value: Pointer): Pointer;
    function SetItemByKey(const AKey: string; const Value: Pointer): Pointer;
    property Keys[const AIndex: integer]: string read GetKey;
    property Count: integer read GetCount;
    property KeyCount: integer read GetKeyCount;
  end;
                                          
  TG2Chars = set of Char;
  
  TG2StructureType = (gstFunction, gstIf, gstElse, gstFor, gstWhile, gstDo,
                      gstUntil, gstForeach, gstReturn, gstBreak, gstContinue,
                      gstExit, gstNop, gstGlobal, gstLocal, gstEvent, gstI,
                      gstNone);

  TG2FunctionType = (gftKeys, gftKeyCount, gftKey, gftError, gftload, gftUnload,
                     gftPrint, gftEcho, gftRandom, gftRandSeed, gftLowerCase,
                     gftUpperCase, gftLC, gftUC, gftStr, gftBool, gftInt,
                     gftFloat, gftIsSet, gftUnSet, gftVar, gftCreate, gftFree,
                     gftUse, gftNone);

  TG2OperatorType = (gotAdd, gotSubtract, gotMultiply, gotDivide, gotRemainder,
                     gotPower, gotReplace, gotSplit, gotNot, gotAnd, gotOr,
                     gotNotSelf, gotAnd2, gotOr2, gotXor, gotAndSelf, gotOrSelf,
                     gotXorSelf, gotEqual, gotUnEqual, gotUnEqual2, gotSmaller,
                     gotBigger, gotSmallerEq, gotBiggerEq, gotIdentical,
                     gotUnIdentical, gotMatch, gotNoMatch, gotAssign, gotRepSelf,
                     gotIncOne, gotDecOne, gotInc, gotAddLeft, gotDec, gotMulSelf,
                     gotDivSelf, gotRemSelf, gotPowSelf, gotShiftLeft,
                     gotShiftRight, gotShlSelf, gotShrSelf, gotReference, gotCount,
                     gotNone);

  TG2ValueType = (gvtBoolean, gvtInteger, gvtFloat, gvtString, gvtObject,
                  gvtArray, gvtReference, gvtOther, gvtNone);

  G2Bool = ByteBool;
  G2Int = Int64;
  G2Float = Double;
  G2String = String;
  G2Object = TObject;
  G2Array = array of TG2Variant;

  G2Arrays = array of TG2Array;

  PCGSHeader = ^TCGSHeader;
  TCGSHeader = packed record
    ID: array[0..3] of Char;
    VersionMajor: Byte;
    VersionMinor: Byte;
    Reserved: Word;
    StrTable: integer;
    ConstTable: integer;
    FuncTable: integer;
  end;

  PG2FuncCallHeader = ^TG2FuncCallHeader;
  TG2FuncCallHeader = packed record
    Cmd: Byte;
    Count: Byte;
    case Integer of
      0: (Str: Word);
      1: (Index: Word);
    // Params: Count*Expression
    // ?Owner: Expression
  end;

  PG2ArrayHeader = ^TG2ArrayHeader;
  TG2ArrayHeader = packed record
    Cmd: Byte;
    Count: Byte;
    // Items: Count*Expression
  end;

  PG2ConstHeader = ^TG2ConstHeader;
  TG2ConstHeader = packed record
    Cmd: Byte;
    Index: Word;
  end;

  PG2ConstStrHeader = ^TG2ConstStrHeader;
  TG2ConstStrHeader = packed record
    Cmd: Byte;
    Str: Word;
  end;

  PG2ConstNumHeader = ^TG2ConstNumHeader;
  TG2ConstNumHeader = packed record
    Cmd: Byte;
    case Byte of
     3: (Int: G2Int);
     4: (Float: G2Float);
  end;

  PG2Const32BitHeader = ^TG2Const32BitHeader;
  TG2Const32BitHeader = packed record
    Cmd: Byte;
    case Byte of
     3: (Int: LongInt);
     4: (Float: Single);
  end;

  PG2Const16BitHeader = ^TG2Const16BitHeader;
  TG2Const16BitHeader = packed record
    Cmd: Byte;
    Int: SmallInt;
  end;

  PG2Const8BitHeader = ^TG2Const8BitHeader;
  TG2Const8BitHeader = packed record
    Cmd: Byte;
    Int: ShortInt;
  end;

  PG2OperHeader = ^TG2OperHeader;
  TG2OperHeader = packed record
    Cmd: Byte;
    Oper: Byte;
    // ?Left/RightArg: Expression
    // ?Right/LeftArg: Expression
  end;

  PG2VarHeader = ^TG2VarHeader;
  TG2VarHeader = packed record
    Cmd: Byte;
    Str: Word;
  end;

  PG2IfHeader = ^TG2IfHeader;
  TG2IfHeader = packed record
    Cmd: Byte;
    ContentLen: Word;
    ElseLen: Word;
    // Condition: Expression
    // Content: n*Statement
    // Else: n*Statement
  end;

  PG2WhileHeader = ^TG2WhileHeader;
  TG2WhileHeader = packed record
    Cmd: Byte;
    ContentLen: Word;
    // Condition: Expression
    // Content: n*Statement
  end;

  PG2ForHeader = ^TG2ForHeader;
  TG2ForHeader = packed record
    Cmd: Byte;
    StepLen: Word;
    ContentLen: Word;
    // Initialization: Statement
    // Step: Statement
    // Condition: Expression
    // Content: n*Statement
  end;

  PG2DoHeader = ^TG2DoHeader;
  TG2DoHeader = packed record
    Cmd: Byte;
    ContentLen: Word;
    ConditionLen: Word;
    // Content: n*Statement
    // Condition: Expression
  end;

  PG2ForeachHeader = ^TG2ForeachHeader;
  TG2ForeachHeader = packed record
    Cmd: Byte;
    ContentLen: Word;
    // Array: Expression
    // Content: n*Statement
  end;

  PG2FuncHeader = ^TG2FuncHeader;
  TG2FuncHeader = packed record
    Cmd: Byte;
    ParamCount: Byte;
    Name: Word;
    ContentLen: Word;
    // ParamNames: n*Word
    // Content: n*Statement
  end;

  PG2PropHeader = ^TG2PropHeader;
  TG2PropHeader = packed record
    Cmd: Byte;
    Str: Word;
    // Parent: Expression
  end;

  PG2IDHeader = ^TG2IDHeader;
  TG2IDHeader = packed record
    Cmd: Byte;
    Str: Word;
  end;

  TG2Variant = class(TPersistent)
  private
    FRefCount: integer;
    FReferrers: TList;
    FReadOnly: Boolean;
  protected
    function GetStr: G2String; virtual; abstract;
    procedure SetStr(const Value: G2String); virtual; abstract;
    function GetBool: G2Bool; virtual; abstract;
    function GetFloat: G2Float; virtual; abstract;
    function GetInt: G2Int; virtual; abstract;
    procedure SetBool(const Value: G2Bool); virtual; abstract;
    procedure SetFloat(const Value: G2Float); virtual; abstract;
    procedure SetInt(const Value: G2Int); virtual; abstract;
    function GetObj: G2Object; virtual; abstract;
    procedure SetObj(const Value: G2Object); virtual; abstract;
    function GetArray: G2Array; virtual; abstract;
    procedure SetArray(const Value: G2Array); virtual; abstract;
    function GetIndexedItem(const AKey: integer): TG2Variant; virtual;
    procedure SetIndexedItem(const AKey: integer; const Value: TG2Variant); virtual;
    function GetKeyedItem(const AKey: string): TG2Variant; virtual;
    procedure SetKeyedItem(const AKey: string; const Value: TG2Variant); virtual;
  public
    constructor Create; overload; virtual;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Reference: TG2Variant; virtual;
    function Copy: TG2Variant; virtual;
    function CopyAndRelease: TG2Variant; virtual;
    procedure Release; virtual;
    function Method(const Name: string): TMethod; virtual;
    procedure Clear; virtual; abstract;
    function Count: integer; virtual;
    function KeyCount: integer; virtual;
    function Key(const AIndex: integer): string; virtual;
    function DefaultType: TG2ValueType; virtual; abstract;
    property IndexedItem[const AIndex: integer]: TG2Variant read GetIndexedItem write SetIndexedItem;
    property KeyedItem[const AKey: string]: TG2Variant read GetKeyedItem write SetKeyedItem;
    property Bool: G2Bool read GetBool write SetBool;
    property Int: G2Int read GetInt write SetInt;
    property Float: G2Float read GetFloat write SetFloat;
    property Str: G2String read GetStr write SetStr;
    property Obj: G2Object read GetObj write SetObj;
    property Arr: G2Array read GetArray write SetArray;
    property RefCount: integer read FRefCount;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;
  TG2VariantClass = class of TG2Variant;

  TG2VReference = class(TG2Variant)
  private
    FData: TG2Variant;
  protected
    function GetStr: G2String; override;
    procedure SetStr(const Value: G2String); override;
    function GetBool: G2Bool; override;
    function GetFloat: G2Float; override;
    function GetInt: G2Int; override;
    procedure SetBool(const Value: G2Bool); override;
    procedure SetFloat(const Value: G2Float); override;
    procedure SetInt(const Value: G2Int); override;
    function GetObj: G2Object; override;
    procedure SetObj(const Value: G2Object); override;
    function GetArray: G2Array; override;
    procedure SetArray(const Value: G2Array); override;
    function GetIndexedItem(const AKey: integer): TG2Variant; override;
    procedure SetIndexedItem(const AKey: integer; const Value: TG2Variant); override;
    function GetKeyedItem(const AKey: string): TG2Variant; override;
    procedure SetKeyedItem(const AKey: string; const Value: TG2Variant); override;
  public
    constructor Create(const Variant: TG2Variant); overload;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Method(const Name: string): TMethod; override;
    function Copy: TG2Variant; override;
    procedure Clear; override;
    function Count: integer; override;
    function KeyCount: integer; override;
    function Key(const AIndex: integer): string; override;
    function DefaultType: TG2ValueType; override;
  end;

  TG2Module = class(TPersistent)
  public
    class function AutoLoad: Boolean; virtual;
  end;
  TG2ModuleClass = class of TG2Module;

var G2Modules: TG2Array;
var G2VarCount: integer = 0;

procedure G2RegisterModule(Module: TG2ModuleClass);

function G2ObjToStr(const Value: G2Object): string;

implementation

uses
  G2Consts, G2Script;

procedure G2RegisterModule(Module: TG2ModuleClass);
var Name: string;
begin
 Name:=Module.ClassName;
 Delete(Name, 1, Pos('_', Name));
 G2Modules.Add(Module, Name);
end;

function G2ObjToStr(const Value: G2Object): string;
begin
 if Value=nil then Result:=G2C_NilStr
  else Result:=Value.ClassName;
end;

{ TG2Module }

class function TG2Module.AutoLoad: Boolean;
begin
 Result:=False;
end;

{ TG2Variant }

procedure TG2Variant.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then FReadOnly:=TG2Variant(Source).ReadOnly;
end;

function TG2Variant.Copy: TG2Variant;
begin
 Result:=TG2VariantClass(ClassType).Create;
 Result.Assign(Self);
 Result.ReadOnly:=True;
end;

function TG2Variant.CopyAndRelease: TG2Variant;
begin
 if FRefCount=1 then Result:=Self
  else begin
   Dec(FRefCount);
   Result:=Copy;
  end;
end;

function TG2Variant.Count: integer;
begin
 Result:=0;
end;

constructor TG2Variant.Create;
begin
 inherited;
 Inc(G2VarCount);
 FRefCount:=1;
end;

destructor TG2Variant.Destroy;
var I: integer;
begin
 if FReferrers<>nil then begin
  for I:=FReferrers.Count-1 downto 0 do
   TG2VReference(FReferrers[I]).FData:=nil;
  FReferrers.Free;
 end;
 Dec(G2VarCount);
 inherited;
end;

function TG2Variant.GetIndexedItem(const AKey: integer): TG2Variant;
begin
 Result:=nil;
end;

function TG2Variant.GetKeyedItem(const AKey: string): TG2Variant;
begin
 Result:=nil;
end;

function TG2Variant.Key(const AIndex: integer): string;
begin
 Result:='';
end;

function TG2Variant.KeyCount: integer;
begin
 Result:=0;
end;

function TG2Variant.Method(const Name: string): TMethod;
begin
 Result.Code:=MethodAddress(Name);
 Result.Data:=Self;
end;

function TG2Variant.Reference: TG2Variant;
begin
 Result:=Self;
 Inc(FRefCount);
end;

procedure TG2Variant.Release;
begin
 Dec(FRefCount);
 if FRefCount=0 then Free;
end;

procedure TG2Variant.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
begin
 G2ReleaseConst(Value);
end;

procedure TG2Variant.SetKeyedItem(const AKey: string; const Value: TG2Variant);
begin
 G2ReleaseConst(Value);
end;

{ TG2Array }

constructor TG2Array.Create;
begin
 inherited;
 FItems:=TList.Create;
 FKeys:=TList.Create;
end;

destructor TG2Array.Destroy;
begin
 Clear;
 FKeys.Free;
 FItems.Free;
 inherited;
end;

function TG2Array.Add(const AItem: Pointer): Pointer;
var Item: PG2ArrayItem;
begin
 Item:=AllocMem(SizeOf(TG2ArrayItem));
 Item.KeyIndex:=-1;
 Item.Data:=AItem;
 FItems.Add(Item);
 Result:=AItem;
end;

function TG2Array.Add(const AItem: Pointer; const AKey: string): Pointer;
var Key: PG2ArrayKey;
    Item: PG2ArrayItem;
    Found: Boolean;
begin
 Key:=AllocMem(SizeOf(TG2ArrayKey));
 Item:=AllocMem(SizeOf(TG2ArrayItem));
 Item.KeyIndex:=ClosestKeyIndex(AKey, Found);
 Item.Data:=AItem;
 Key.Key:=AKey;
 Key.Index:=FItems.Count;
 FKeys.Insert(Item.KeyIndex, Key);
 FItems.Add(Item);
 UpdateKeyIndices(Item.KeyIndex);
 Result:=AItem;
end;

function TG2Array.AddOrGet(const AItem: Pointer; const AKey: string): Pointer;
var Key: PG2ArrayKey;
    Item: PG2ArrayItem;
    Found: Boolean;
    Index: integer;
begin
 Index:=ClosestKeyIndex(AKey, Found);
 if Found then Result:=PG2ArrayItem(FItems[PG2ArrayKey(FKeys[Index])^.Index]).Data
  else begin
   Key:=AllocMem(SizeOf(TG2ArrayKey));
   Item:=AllocMem(SizeOf(TG2ArrayItem));
   Item.Data:=AItem;
   Item.KeyIndex:=Index;
   Key.Key:=AKey;
   Key.Index:=FItems.Count;
   FKeys.Insert(Item.KeyIndex, Key);
   FItems.Add(Item);
   UpdateKeyIndices(Item.KeyIndex);
   Result:=AItem;
  end; 
end;

function TG2Array.GetItemByIndex(const AIndex: integer): Pointer;
begin
 if (AIndex>=0) and (AIndex<FItems.Count) then Result:=TG2ArrayItem(FItems[AIndex]^).Data
  else Result:=nil;
end;

function TG2Array.GetItemByKey(const AKey: string): Pointer;
begin
 Result:=GetItemByIndex(IndexOf(AKey));
end;

function TG2Array.IndexOf(const AItem: Pointer): integer;
var I: integer;
begin
 for I:=0 to FItems.Count-1 do
  if TG2ArrayItem(FItems[I]^).Data=AItem then begin
   Result:=I;
   Exit;
  end;
 Result:=-1;
end;

function TG2Array.IndexOf(const AKey: string): integer;
var Found: Boolean;
begin
 Result:=ClosestKeyIndex(AKey, Found);
 if not Found then Result:=-1
  else Result:=PG2ArrayKey(FKeys[Result])^.Index;
end;

function TG2Array.ClosestKeyIndex(const AKey: string; out Found: Boolean): integer;
var GT, LT, Pos: integer;
begin
 Found:=True;
 GT:=-1;
 LT:=FKeys.Count;
 Pos:=FKeys.Count div 2;
 if Pos<FKeys.Count then
  while True do
   with TG2ArrayKey(FKeys[Pos]^) do
    if AKey>Key then begin
     GT:=Pos;
     Pos:=(Pos+LT+1) div 2;
     if (Pos=GT) or (Pos=LT) then Break;
    end else if AKey<Key then begin
     LT:=Pos;
     Pos:=(Pos+GT) div 2;
     if Pos=LT then Break;
    end else begin
     Result:=Pos;
     Exit;
    end;
 Result:=LT;
 Found:=False;
end;

procedure TG2Array.Remove(const AItem: Pointer);
begin
 Delete(IndexOf(AItem));
end;

procedure TG2Array.Fill(const ACount: integer; const AItem: Pointer);
var Item: PG2ArrayItem;
    I: integer;
begin
 for I:=0 to ACount-1 do begin
  Item:=AllocMem(SizeOf(TG2ArrayItem));
  Item.KeyIndex:=-1;
  Item.Data:=AItem;
  FItems.Add(Item);
 end;
end;

function TG2Array.SetItemByIndex(const AIndex: integer; const Value: Pointer): Pointer;
var Item: PG2ArrayItem;
begin
 Result:=nil;
 if (AIndex>=0) and (AIndex<FItems.Count) then begin
  Result:=TG2ArrayItem(FItems[AIndex]^).Data;
  TG2ArrayItem(FItems[AIndex]^).Data:=Value;
 end else begin
  if AIndex>FItems.Count then Fill(AIndex-FItems.Count);
  Item:=AllocMem(SizeOf(TG2ArrayItem));
  Item.KeyIndex:=-1;
  Item.Data:=Value;
  FItems.Add(Item);
 end;
end;

function TG2Array.SetItemByKey(const AKey: string; const Value: Pointer): Pointer;
var Key: PG2ArrayKey;
    Item: PG2ArrayItem;
    Index: integer;
    Found: Boolean;
begin
 Result:=nil;
 Index:=ClosestKeyIndex(AKey, Found);
 if Found then begin
  Result:=SetItemByIndex(PG2ArrayKey(FKeys[Index])^.Index, Value);
 end else begin
  Key:=AllocMem(SizeOf(TG2ArrayKey));
  Item:=AllocMem(SizeOf(TG2ArrayItem));
  Item.KeyIndex:=Index;
  Item.Data:=Value;
  Key.Key:=AKey;
  Key.Index:=FItems.Count;
  FKeys.Insert(Item.KeyIndex, Key);
  FItems.Add(Item);
  UpdateKeyIndices(Item.KeyIndex);
 end;
end;

function TG2Array.GetCount: integer;
begin
 Result:=FItems.Count;
end;

procedure TG2Array.Delete(const AKey: string);
begin
 Delete(IndexOf(AKey));
end;

procedure TG2Array.Delete(const AIndex: integer);
var Key: PG2ArrayKey;
    I: integer;
begin
 if (AIndex>=0) and (AIndex<FItems.Count) then begin
  with TG2ArrayItem(FItems[AIndex]^) do
   if KeyIndex>=0 then begin
    Key:=FKeys[KeyIndex];
    Dispose(Key);
    FKeys.Delete(KeyIndex);
    for I:=0 to FKeys.Count-1 do begin
     if I>KeyIndex then PG2ArrayItem(FItems[PG2ArrayKey(FKeys[I]).Index]).KeyIndex:=I;
     if PG2ArrayKey(FKeys[I]).Index>AIndex then Dec(PG2ArrayKey(FKeys[I]).Index);
    end;
   end;
  FreeMem(FItems[AIndex]);
  FItems.Delete(AIndex);
 end; 
end;

function TG2Array.GetKey(const AIndex: integer): string;
begin
 if (AIndex>=0) and (AIndex<FKeys.Count) then Result:=TG2ArrayKey(FKeys[AIndex]^).Key
  else Result:='';
end;

function TG2Array.GetKeyCount: integer;
begin
 Result:=FKeys.Count;
end;

function TG2Array.KeyIndex(const AIndex: integer): integer;
begin
 if (AIndex>=0) and (AIndex<FItems.Count) then Result:=TG2ArrayItem(FItems[AIndex]^).KeyIndex
  else Result:=-1;
end;

procedure TG2Array.Clear;
var I: integer;
    Key: PG2ArrayKey;
begin
 for I:=0 to FKeys.Count-1 do begin
  Key:=FKeys[I];
  Dispose(Key);
 end;
 FKeys.Clear;
 for I:=0 to FItems.Count-1 do
  FreeMem(FItems[I]);
 FItems.Clear;
end;

procedure TG2Array.Exchange(const AIndex1, AIndex2: integer);
var Item: TG2ArrayItem;
begin
 if (AIndex1>=0) and (AIndex1<FItems.Count) and (AIndex2>=0) and (AIndex2<FItems.Count) then begin
  Item:=PG2ArrayItem(FItems[AIndex1])^;
  PG2ArrayItem(FItems[AIndex1])^:=PG2ArrayItem(FItems[AIndex2])^;
  PG2ArrayItem(FItems[AIndex2])^:=Item;
  with PG2ArrayItem(FItems[AIndex1])^ do if KeyIndex>=0 then PG2ArrayKey(FKeys[KeyIndex]).Index:=AIndex1;
  with PG2ArrayItem(FItems[AIndex2])^ do if KeyIndex>=0 then PG2ArrayKey(FKeys[KeyIndex]).Index:=AIndex2;
 end;
end;

procedure TG2Array.UpdateKeyIndices(const AFrom: integer = 0);
var I: integer;
begin
 for I:=AFrom to FKeys.Count-1 do
  PG2ArrayItem(FItems[PG2ArrayKey(FKeys[I]).Index]).KeyIndex:=I;
end;

{ TG2VReference }

procedure TG2VReference.Assign(Source: TPersistent);
begin
 if Source is TG2VReference then begin
  if FData<>nil then begin
   FData.FReferrers.Remove(Self);
   FData.Release;
  end;
  FData:=TG2VReference(Source).FData;
  if FData<>nil then begin
   if FData.FReferrers=nil then FData.FReferrers:=TList.Create;
   FData.Reference;
   FData.FReferrers.Add(Self);
  end; 
 end else if (FData=nil) and (Source is TG2Variant) then begin
  FData:=TG2Variant(Source);
  if FData<>nil then begin
   if FData.FReferrers=nil then FData.FReferrers:=TList.Create;
   FData.Reference;
   FData.FReferrers.Add(Self);
  end; 
 end else if FData<>nil then FData.Assign(Source);
 FReadOnly:=False;
end;

procedure TG2VReference.Clear;
begin
 if FData<>nil then FData.Clear;
end;

function TG2VReference.Copy: TG2Variant;
begin
 if FData=nil then Result:=inherited Copy
  else Result:=FData.Copy;
end;

function TG2VReference.Count: integer;
begin
 if FData<>nil then Result:=FData.Count
  else Result:=0;
end;

constructor TG2VReference.Create(const Variant: TG2Variant);
begin
 inherited Create;
 FData:=Variant;
 if FData<>nil then begin
  if FData.FReferrers=nil then FData.FReferrers:=TList.Create;
  FData.FReferrers.Add(Self);
 end;
end;

function TG2VReference.DefaultType: TG2ValueType;
begin
 if FData<>nil then Result:=FData.DefaultType
  else Result:=gvtOther;
end;

destructor TG2VReference.Destroy;
begin
 if FData<>nil then begin
  FData.FReferrers.Remove(Self);
  FData.Release;
 end;
 inherited;
end;

function TG2VReference.GetArray: G2Array;
begin
 if FData<>nil then Result:=FData.GetArray
  else Result:=nil;
end;

function TG2VReference.GetBool: G2Bool;
begin
 if FData<>nil then Result:=FData.GetBool
  else Result:=False;
end;

function TG2VReference.GetFloat: G2Float;
begin
 if FData<>nil then Result:=FData.GetFloat
  else Result:=0.0;
end;

function TG2VReference.GetIndexedItem(const AKey: integer): TG2Variant;
begin
 if FData<>nil then Result:=FData.GetIndexedItem(AKey)
  else Result:=nil;
end;

function TG2VReference.GetInt: G2Int;
begin
 if FData<>nil then Result:=FData.GetInt
  else Result:=0;
end;

function TG2VReference.GetKeyedItem(const AKey: string): TG2Variant;
begin
 if FData<>nil then Result:=FData.GetKeyedItem(AKey)
  else Result:=nil;
end;

function TG2VReference.GetObj: G2Object;
begin
 if FData<>nil then Result:=FData.GetObj
  else Result:=nil;
end;

function TG2VReference.GetStr: G2String;
begin
 if FData<>nil then Result:=FData.GetStr
  else Result:='';
end;

function TG2VReference.Key(const AIndex: integer): string;
begin
 if FData<>nil then Result:=FData.Key(AIndex)
  else Result:='';
end;

function TG2VReference.KeyCount: integer;
begin
 if FData<>nil then Result:=FData.KeyCount
  else Result:=0;
end;

function TG2VReference.Method(const Name: string): TMethod;
begin
 if FData<>nil then Result:=FData.Method(Name)
  else Result.Code:=nil;
end;

procedure TG2VReference.SetArray(const Value: G2Array);
begin
 if FData<>nil then FData.SetArray(Value)
  else G2Release(Value);
end;

procedure TG2VReference.SetBool(const Value: G2Bool);
begin
 if FData<>nil then FData.SetBool(Value);
end;

procedure TG2VReference.SetFloat(const Value: G2Float);
begin
 if FData<>nil then FData.SetFloat(Value);
end;

procedure TG2VReference.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
begin
 if FData<>nil then FData.SetIndexedItem(AKey, Value);
end;

procedure TG2VReference.SetInt(const Value: G2Int);
begin
 if FData<>nil then FData.SetInt(Value);
end;

procedure TG2VReference.SetKeyedItem(const AKey: string; const Value: TG2Variant);
begin
 if FData<>nil then FData.SetKeyedItem(AKey, Value);
end;

procedure TG2VReference.SetObj(const Value: G2Object);
begin
 if FData<>nil then FData.SetObj(Value);
end;

procedure TG2VReference.SetStr(const Value: G2String);
begin
 if FData<>nil then FData.SetStr(Value);
end;

initialization
Randomize;
G2Modules:=TG2Array.Create;
finalization
G2Modules.Free;
end.
 