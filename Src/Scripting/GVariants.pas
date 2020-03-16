unit GVariants;

interface

uses
  GTypes, GConsts, Classes, SysUtils;

type
  TGVBoolean = class(TGCustomVariant)
  private
    FValue: GBool;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; Value: GBool);
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
  end;

  TGVInteger = class(TGCustomVariant)
  private
    FValue: GInt;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; Value: GInt);
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
  end;

  TGVFloat = class(TGCustomVariant)
  private
    FValue: GFloat;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; Value: GFloat);
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
  end;

  TGVString = class(TGCustomVariant)
  private
    FData: string;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; const Data: string);
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
    function SetItem(Index: integer; Item: TGCustomVariant): Boolean; override;
    function GetItem(Index: integer; out Item: TGCustomVariant): Boolean; override;
    function Count: integer; override;
  end;

  TGVArray = class(TGCustomVariant)
  private
    FItems: TGArray;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; const Data: array of TGCustomVariant);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
    function SetItem(Index: integer; Item: TGCustomVariant): Boolean; override;
    function SetItem(const Key: string; Item: TGCustomVariant): Boolean; override;
    function GetItem(Index: integer; out Item: TGCustomVariant): Boolean; override;
    function GetItem(const Key: string; out Item: TGCustomVariant): Boolean; override;
    function UnSetItem(Index: integer): Boolean; override;
    function UnSetItem(const Key: string): Boolean; override;
    function Count: integer; override;
    function Keys: TGCustomVariant; override;
    function Sort: Boolean; override;
  end;

implementation

{ TGVBoolean }

procedure TGVBoolean.Assign(Source: TPersistent);
begin
 if Source is TGVBoolean then
  FValue:=TGVBoolean(Source).FValue;
end;

function TGVBoolean.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual: Result:=FValue=Item.ResultBool;
  gotUnEqual: Result:=FValue<>Item.ResultBool;
  gotSmaller: Result:=FValue<Item.ResultBool;
  gotBigger: Result:=FValue>Item.ResultBool;
  gotSmallerEq: Result:=FValue<=Item.ResultBool;
  gotBiggerEq: Result:=FValue>=Item.ResultBool;
  else Result:=False;
 end;
end;

function TGVBoolean.Copy: TGCustomVariant;
begin
 Result:=TGVBoolean.Create(False, False, FValue);
end;

constructor TGVBoolean.Create(Temp, IsConst: Boolean; Value: GBool);
begin
 inherited Create(Temp, IsConst, False, False);
 FValue:=Value;
end;

function TGVBoolean.GetDefaultType: TGResultType;
begin
 Result:=grtBoolean;
end;

function TGVBoolean.GetResultBool: GBool;
begin
 Result:=FValue;
end;

function TGVBoolean.GetResultFloat: GFloat;
begin
 Result:=Ord(FValue);
end;

function TGVBoolean.GetResultInt: GInt;
begin
 Result:=Ord(FValue);
end;

function TGVBoolean.GetResultStr: GString;
begin
 Result:=GC_BooleanStr[FValue];
end;

function TGVBoolean.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtBoolean;
 if Result then
  FValue:=GBool(Value);
end;

{ TGVInteger }

procedure TGVInteger.Assign(Source: TPersistent);
begin
 if Source is TGVInteger then
  FValue:=TGVInteger(Source).FValue;
end;

function TGVInteger.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual: Result:=FValue=Item.ResultInt;
  gotUnEqual: Result:=FValue<>Item.ResultInt;
  gotSmaller: Result:=FValue<Item.ResultInt;
  gotBigger: Result:=FValue>Item.ResultInt;
  gotSmallerEq: Result:=FValue<=Item.ResultInt;
  gotBiggerEq: Result:=FValue>=Item.ResultInt;
  else Result:=False;
 end;
end;

function TGVInteger.Copy: TGCustomVariant;
begin
 Result:=TGVInteger.Create(False, False, FValue);
end;

constructor TGVInteger.Create(Temp, IsConst: Boolean; Value: GInt);
begin
 inherited Create(Temp, IsConst, False, False);
 FValue:=Value;
end;

function TGVInteger.GetDefaultType: TGResultType;
begin
 Result:=grtInteger;
end;

function TGVInteger.GetResultBool: GBool;
begin
 Result:=FValue<>0;
end;

function TGVInteger.GetResultFloat: GFloat;
begin
 Result:=FValue;
end;

function TGVInteger.GetResultInt: GInt;
begin
 Result:=FValue;
end;

function TGVInteger.GetResultStr: GString;
begin
 Result:=IntToStr(FValue);
end;

function TGVInteger.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtInteger;
 if Result then
  FValue:=GInt(Value);
end;

{ TGVFloat }

procedure TGVFloat.Assign(Source: TPersistent);
begin
 if Source is TGVFloat then
  FValue:=TGVFloat(Source).FValue;
end;

function TGVFloat.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual: Result:=FValue=Item.ResultFloat;
  gotUnEqual: Result:=FValue<>Item.ResultFloat;
  gotSmaller: Result:=FValue<Item.ResultFloat;
  gotBigger: Result:=FValue>Item.ResultFloat;
  gotSmallerEq: Result:=FValue<=Item.ResultFloat;
  gotBiggerEq: Result:=FValue>=Item.ResultFloat;
  else Result:=False;
 end;
end;

function TGVFloat.Copy: TGCustomVariant;
begin
 Result:=TGVFloat.Create(False, False, FValue);
end;

constructor TGVFloat.Create(Temp, IsConst: Boolean; Value: GFloat);
begin
 inherited Create(Temp, IsConst, False, False);
 FValue:=Value;
end;

function TGVFloat.GetDefaultType: TGResultType;
begin
 Result:=grtFloat;
end;

function TGVFloat.GetResultBool: GBool;
begin
 Result:=FValue<>0.0;
end;

function TGVFloat.GetResultFloat: GFloat;
begin
 Result:=FValue;
end;

function TGVFloat.GetResultInt: GInt;
begin
 Result:=Round(FValue);
end;

function TGVFloat.GetResultStr: GString;
begin
 Result:=FloatToStr(FValue);
end;

function TGVFloat.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtFloat;
 if Result then
  FValue:=GFloat(Value);
end;

{ TGVString }

procedure TGVString.Assign(Source: TPersistent);
begin
 if Source is TGVString then
  FData:=TGVString(Source).FData;
end;

function TGVString.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual: Result:=FData=Item.ResultStr;
  gotUnEqual: Result:=FData<>Item.ResultStr;
  gotSmaller: Result:=FData<Item.ResultStr;
  gotBigger: Result:=FData>Item.ResultStr;
  gotSmallerEq: Result:=FData<=Item.ResultStr;
  gotBiggerEq: Result:=FData>=Item.ResultStr;
  else Result:=False;
 end;    
end;

function TGVString.Copy: TGCustomVariant;
begin
 Result:=TGVString.Create(False, False, FData);
end;

constructor TGVString.Create(Temp, IsConst: Boolean; const Data: string);
begin
 inherited Create(Temp, IsConst, True, False);
 FData:=Data;
end;

function TGVString.GetDefaultType: TGResultType;
begin
 Result:=grtString;
end;

function TGVString.GetItem(Index: integer; out Item: TGCustomVariant): Boolean;
begin
 if (Index>=0) and (Index<Length(FData)) then Item:=TGVString.Create(True, False, FData[Index+1])
  else Item:=TGVString.Create(True, False, '');
 Result:=True;
end;

function TGVString.SetItem(Index: integer; Item: TGCustomVariant): Boolean;
begin
 if (Index>=0) and (Index<Length(FData)) and (Length(Item.ResultStr)>0) then FData[Index+1]:=Item.ResultStr[1];
 Item.Free;
 Result:=True;
end;

function TGVString.GetResultBool: GBool;
begin
 if (FData='1') or (AnsiLowerCase(FData)=GC_BooleanStr[True]) then Result:=True
  else if (FData='0') or (AnsiLowerCase(FData)=GC_BooleanStr[False]) then Result:=False
   else Result:=FData<>'';
end;

function TGVString.GetResultFloat: GFloat;
begin
 Result:=StrToFloatDef(FData, 0);
end;

function TGVString.GetResultInt: GInt;
begin
 Result:=StrToIntDef(FData, 0);
end;

function TGVString.GetResultStr: GString;
begin
 Result:=FData;
end;

function TGVString.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtString;
 if Result then
  FData:=GString(Value);
end;

function TGVString.Count: integer;
begin
 Result:=Length(FData);
end;

{ TGVArray }

procedure TGVArray.Assign(Source: TPersistent);
var I: integer;
    Item: TGCustomVariant;
begin
 if Source is TGVArray then begin
  if (TGVArray(Source).Temp) and (Source<>Self) then begin
   for I:=0 to FItems.Count-1 do
    if FItems.GetItem(I, Item) and (Item<>nil) then Item.Free;
   FItems.Free;
   FItems:=TGVArray(Source).FItems;
   TGVArray(Source).FItems:=nil;
  end else if FItems<>nil then begin
   for I:=0 to FItems.Count-1 do
    if FItems.GetItem(I, Item) and (Item<>nil) then Item.Free;
   FItems.Assign(TGVArray(Source).FItems);
   for I:=0 to FItems.Count-1 do 
    if TGVArray(Source).FItems.GetItem(I, Item) and (Item<>nil) then begin
     Item:=Item.Copy;
     FItems.SetItem(I, Item);
    end;
  end;
 end;
end;

function TGVArray.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual: Result:=FItems.Count=Item.ResultInt;
  gotUnEqual: Result:=FItems.Count<>Item.ResultInt;
  gotSmaller: Result:=FItems.Count<Item.ResultInt;
  gotBigger: Result:=FItems.Count>Item.ResultInt;
  gotSmallerEq: Result:=FItems.Count<=Item.ResultInt;
  gotBiggerEq: Result:=FItems.Count>=Item.ResultInt;
  else Result:=False;
 end;
end;

function TGVArray.Copy: TGCustomVariant;
begin
 Result:=TGVArray.Create(False, False, []);
 Result.Assign(Self);
end;

function TGVArray.Count: integer;
begin
 Result:=FItems.Count;
end;

constructor TGVArray.Create(Temp, IsConst: Boolean; const Data: array of TGCustomVariant);
var I: integer;
begin
 inherited Create(Temp, IsConst, True, True);
 FItems:=TGArray.Create(SizeOf(TGCustomVariant));
 FItems.SetCapacity(High(Data)+1);
 for I:=Low(Data) to High(Data) do
  FItems.SetItem(I, Data[I]);
end;

destructor TGVArray.Destroy;
var I: integer;
    Item: TGCustomVariant;
begin
 if FItems<>nil then begin
  FItems.SetCapacity(FItems.Count);
  for I:=0 to FItems.Count-1 do
   if FItems.GetItem(I, Item) and (Item<>nil) then Item.Free;
  FItems.Free;
 end;
 inherited;
end;

function TGVArray.GetDefaultType: TGResultType;
begin
 Result:=grtArray;
end;

function TGVArray.GetItem(Index: integer; out Item: TGCustomVariant): Boolean;
begin
 Result:=FItems.GetItem(Index, Item) and (Item<>nil);
end;

function TGVArray.GetItem(const Key: string; out Item: TGCustomVariant): Boolean;
begin
 Result:=FItems.GetItem(Key, Item);
end;

function TGVArray.GetResultBool: GBool;
begin
 Result:=FItems<>nil;
 if Result then Result:=FItems.Count>0;
end;

function TGVArray.GetResultFloat: GFloat;
begin
 Result:=FItems.Count;
end;

function TGVArray.GetResultInt: GInt;
begin
 Result:=FItems.Count;
end;

function TGVArray.GetResultStr: GString;
var I: integer;
    Item: TGCustomVariant;
begin
 Result:='';
 if FItems<>nil then                        
  for I:=0 to FItems.Count-1 do
   if FItems.GetItem(I, Item) and (Item<>nil) then Result:=Result+Item.ResultStr;
end;

function TGVArray.SetItem(Index: integer; Item: TGCustomVariant): Boolean;
var OldItem: TGCustomVariant;
begin
 if FItems.GetItem(Index, OldItem) and (OldItem<>nil) then OldItem.Free;
 Item.Temp:=False;
 Result:=FItems.SetItem(Index, Item);
end;

function TGVArray.Keys: TGCustomVariant;
var I: integer;
begin
 Result:=TGVArray.Create(True, False, []);
 for I:=0 to FItems.KeyCount-1 do
  Result.SetItem(I, TGVString.Create(False, False, FItems.Key(I).Key));
end;

function TGVArray.SetItem(const Key: string; Item: TGCustomVariant): Boolean;
var OldItem: TGCustomVariant;
begin
 if FItems.GetItem(Key, OldItem) then OldItem.Free;
 Item.Temp:=False;
 Result:=FItems.SetItem(Key, Item);
end;

function TGVArray.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtArray;
 if Result then
  Assign(TPersistent(Value));
end;

function TGVArray.UnSetItem(Index: integer): Boolean;
var OldItem: TGCustomVariant;
begin
 if FItems.GetItem(Index, OldItem) and (OldItem<>nil) then OldItem.Free;
 FItems.Remove(Index);
 Result:=True;
end;

function TGVArray.UnSetItem(const Key: string): Boolean;
var OldItem: TGCustomVariant;
begin
 if FItems.GetItem(Key, OldItem) then OldItem.Free;
 FItems.Remove(Key);
 Result:=True;
end;
            
function TGVArray.Sort: Boolean;
 procedure QuickSort(iMin, iMax: integer);
 var I, Pivot: integer;
     Item1, Item2: TGCustomVariant;
     B: Boolean;
 begin
  Pivot:=(iMin+iMax) div 2;
  //FItems.GetItem(Pivot, Item1);
  Item1:=TGCustomVariant(FItems.Item(Pivot)^);
  I:=iMin;
  while I<Pivot do begin
   //FItems.GetItem(I, Item2);
   Item2:=TGCustomVariant(FItems.Item(I)^);
   if (Item1=nil) or (Item2=nil) then B:=(Item2=nil) and (Item1<>nil)
    else B:=Item1.Compare(Item2, gotSmaller);
   if B then begin
    //FItems.SetItem(Pivot, Item2);
    TGCustomVariant(FItems.Item(Pivot)^):=Item2;
    Dec(Pivot);
    //FItems.GetItem(Pivot, Item2);
    Item2:=TGCustomVariant(FItems.Item(Pivot)^);
    //FItems.SetItem(I, Item2);
    TGCustomVariant(FItems.Item(I)^):=Item2;
    //FItems.SetItem(Pivot, Item1);
    TGCustomVariant(FItems.Item(Pivot)^):=Item1;
   end else Inc(I);
  end;
  I:=iMax;
  while I>Pivot do begin
   //FItems.GetItem(I, Item2);
   Item2:=TGCustomVariant(FItems.Item(I)^);
   if (Item1=nil) or (Item2=nil) then B:=(Item1=nil) and (Item2<>nil)
    else B:=Item1.Compare(Item2, gotBigger);
   if B then begin
    //FItems.SetItem(Pivot, Item2);
    TGCustomVariant(FItems.Item(Pivot)^):=Item2;
    Inc(Pivot);
    //FItems.GetItem(Pivot, Item2);
    Item2:=TGCustomVariant(FItems.Item(Pivot)^);
    //FItems.SetItem(I, Item2);
    TGCustomVariant(FItems.Item(I)^):=Item2;
    //FItems.SetItem(Pivot, Item1);
    TGCustomVariant(FItems.Item(Pivot)^):=Item1;
   end else Dec(I);
  end;
  if Pivot>iMin+1 then QuickSort(iMin, Pivot-1);
  if Pivot<iMax-1 then QuickSort(Pivot+1, iMax);
 end;
begin
 if FItems.Count>1 then QuickSort(0, FItems.Count-1);
 Result:=True;
end;

end.
