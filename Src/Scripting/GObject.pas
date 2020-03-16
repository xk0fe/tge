unit GObject;

interface

uses
  GTypes, GConsts, GVariants, Classes, SysUtils, TypInfo;

type
  TGMObject = class(TGCustomModule)
  private
    function GetNil(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function CreateObj(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
    function FreeObj(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
  public
    constructor Create(Script: TGCustomScript); override;
    procedure Unload; override;
  end;

  TGVObject = class(TGCustomVariant)
  private
    FValue: TObject;
  protected
    function GetResultBool: GBool; override;
    function GetResultInt: GInt; override;
    function GetResultFloat: GFloat; override;
    function GetResultStr: GString; override;
    function GetDefaultType: TGResultType; override;
  public
    constructor Create(Temp, IsConst: Boolean; Value: TObject);
    procedure Assign(Source: TPersistent); override;
    function Copy: TGCustomVariant; override;
    function Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean; override;
    function SetValue(ValueType: TGResultType; const Value): Boolean; override;
    function SetItem(Index: integer; Item: TGCustomVariant): Boolean; override;
    function SetItem(const Key: string; Item: TGCustomVariant): Boolean; override;
    function GetItem(Index: integer; out Item: TGCustomVariant): Boolean; override;
    function GetItem(const Key: string; out Item: TGCustomVariant): Boolean; override;
    function Count: integer; override;
    function Keys: TGCustomVariant; override;
    function Obj: TObject;
  end;

  procedure GRegisterObject(Script: TGCustomScript; const Name: string; Instance: TObject);

implementation

procedure GRegisterObject(Script: TGCustomScript; const Name: string; Instance: TObject);
begin
 Script.SetVariable(Name, TGVObject.Create(False, True, Instance));
end;

{ TGVObject }

procedure TGVObject.Assign(Source: TPersistent);
begin
 if Source is TGVObject then
  FValue:=TGVObject(Source).FValue;
 FIndexed:=FValue is TList;
 FKeyed:=FValue is TPersistent;
end;

function TGVObject.Compare(Item: TGCustomVariant; Operator: TGOperatorType): Boolean;
begin
 case Operator of
  gotEqual:
   if Item is TGVObject then Result:=FValue=TGVObject(Item).FValue
    else Result:=ResultStr=Item.ResultStr;
  gotUnEqual:
   if Item is TGVObject then Result:=FValue<>TGVObject(Item).FValue
    else Result:=ResultStr<>Item.ResultStr;
  gotSmaller:
   if Item is TGVObject then Result:=Cardinal(FValue)<Cardinal(TGVObject(Item).FValue)
    else Result:=ResultStr<Item.ResultStr;
  gotBigger:
   if Item is TGVObject then Result:=Cardinal(FValue)>Cardinal(TGVObject(Item).FValue)
    else Result:=ResultStr>Item.ResultStr;
  gotSmallerEq:
   if Item is TGVObject then Result:=Cardinal(FValue)<=Cardinal(TGVObject(Item).FValue)
    else Result:=ResultStr<=Item.ResultStr;
  gotBiggerEq:
   if Item is TGVObject then Result:=Cardinal(FValue)>=Cardinal(TGVObject(Item).FValue)
    else Result:=ResultStr>=Item.ResultStr;
  else Result:=False;
 end;
end;

function TGVObject.Copy: TGCustomVariant;
begin
 Result:=TGVObject.Create(False, False, FValue);
end;

function TGVObject.Count: integer;
begin
 if FValue is TList then Result:=TList(FValue).Count
  else Result:=0;
end;

constructor TGVObject.Create(Temp, IsConst: Boolean; Value: TObject);
begin
 inherited Create(Temp, IsConst, Value is TList, Value is TPersistent);
 FValue:=Value;
end;

function TGVObject.GetDefaultType: TGResultType;
begin
 Result:=grtObject;
end;

function TGVObject.GetItem(Index: integer; out Item: TGCustomVariant): Boolean;
begin
 Result:=FValue is TList;
 if Result then Result:=TList(FValue).Count>Index;
 if Result then Item:=TGVObject.Create(True, False, TObject(TList(FValue).Items[Index]));
end;

function TGVObject.GetItem(const Key: string; out Item: TGCustomVariant): Boolean;
var PropInfo: PPropInfo;
begin
 Result:=FValue is TPersistent;
 if Result then begin        
  PropInfo:=GetPropInfo(FValue, Key);
  Result:=PropInfo<>nil;            
  if Result then begin
   case PropInfo.PropType^.Kind of
    tkEnumeration: Item:=TGVBoolean.Create(True, False, GetEnumProp(FValue, Key)=BooleanIdents[True]);
    tkInteger: Item:=TGVInteger.Create(True, False, GetOrdProp(FValue, Key));
    tkInt64: Item:=TGVInteger.Create(True, False, GetInt64Prop(FValue, Key));
    tkFloat: Item:=TGVFloat.Create(True, False, GetFloatProp(FValue, Key));
    tkChar, tkString, tkLString: Item:=TGVString.Create(True, False, GetStrProp(FValue, Key));
    tkClass: Item:=TGVObject.Create(True, False, TPersistent(GetObjectProp(FValue, Key)));
    else Item:=TGVString.Create(True, False, 'Unsupported!');
   end;
  end; 
 end;
end;

function TGVObject.GetResultBool: GBool;
begin
 Result:=FValue<>nil;
end;

function TGVObject.GetResultFloat: GFloat;
begin
 Result:=Ord(FValue<>nil);
end;

function TGVObject.GetResultInt: GInt;
begin
 Result:=Ord(FValue<>nil);
end;

function TGVObject.GetResultStr: GString;
begin
 if FValue<>nil then Result:=FValue.ClassName
  else Result:='';
end;

function TGVObject.Keys: TGCustomVariant;
var PropList: PPropList;
    I, Count: integer;
begin
 Result:=TGVArray.Create(True, False, []);
 if not (FValue is TPersistent) then Exit;
 New(PropList);
 Count:=GetPropList(FValue.ClassType.ClassInfo, tkAny, PropList, True);
 for I:=0 to Count-1 do
  Result.SetItem(I, TGVString.Create(False, False, PropList^[I]^.Name));
 Dispose(PropList);
end;

function TGVObject.Obj: TObject;
begin
 Result:=FValue;
end;

function TGVObject.SetItem(const Key: string; Item: TGCustomVariant): Boolean;
var PropInfo: PPropInfo;
begin
 Result:=FValue is TPersistent;
 if Result then begin
  PropInfo:=GetPropInfo(FValue, Key);
  Result:=PropInfo<>nil;
  if Result then begin
   case PropInfo.PropType^.Kind of
    tkEnumeration: SetEnumProp(FValue, Key, BooleanIdents[Item.ResultBool]);
    tkInteger: SetOrdProp(FValue, Key, Item.ResultInt);
    tkInt64: SetInt64Prop(FValue, Key, Item.ResultInt);
    tkFloat: SetFloatProp(FValue, Key, Item.ResultFloat);
    tkChar, tkString, tkLString: SetStrProp(FValue, Key, Item.ResultStr);
    tkClass: begin
     if Item is TGVObject then SetObjectProp(FValue, Key, TGVObject(Item).FValue)
      else SetObjectProp(FValue, Key, nil);
    end;
    else Result:=False;
   end;
  end;
 end;
 Item.Free;
end;

function TGVObject.SetItem(Index: integer; Item: TGCustomVariant): Boolean;
var I: integer;
begin
 Result:=(FValue is TList) and (Item is TGVObject);
 if Result then begin
  if TList(FValue).Count>Index then begin
   TList(FValue).Items[Index]:=TGVObject(Item).FValue;
  end else begin
   for I:=TList(FValue).Count to Index-1 do
    TList(FValue).Add(nil);
   TList(FValue).Add(TGVObject(Item).FValue);
  end;
  Item.Free;
 end;
end;

function TGVObject.SetValue(ValueType: TGResultType; const Value): Boolean;
begin
 Result:=ValueType=grtObject;
 if Result then
  FValue:=TObject(Value);
 FIndexed:=FValue is TList;
 FKeyed:=FValue is TPersistent;
end;

{ TGMObject }

constructor TGMObject.Create(Script: TGCustomScript);
begin
 inherited;
 FScript.RegisterFunction('Nil', GetNil); // $O = Nil;
 FScript.RegisterFunction('CreateObject', CreateObj); // $O = CreateObject(S);
 FScript.RegisterFunction('FreeObject', FreeObj); // FreeObject(O);
end;

procedure TGMObject.Unload;
begin
 FScript.UnregisterFunction('FreeObject');
 FScript.UnregisterFunction('CreateObject');
 FScript.UnregisterFunction('Nil');
end;

function TGMObject.GetNil(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=-1;
 if Result then Result:=Block.Return(TGVObject.Create(True, False, nil));
end;

function TGMObject.CreateObj(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
var ObjClass: TClass;
    Obj: TObject;
begin
 ObjClass:=nil;
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtString]);
 if Result then begin
  ObjClass:=GetClass(Params[0].Result.ResultStr);
  Result:=ObjClass<>nil;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
 if Result then begin
  Obj:=ObjClass.Create;
  if ResultType<>[grtNone] then Block.Return(TGVObject.Create(True, False, Obj));
 end;
end;

function TGMObject.FreeObj(Block: TGCustomBlock; ResultType: TGResultTypes; const Params: array of TGCustomBlock): Boolean;
begin
 Result:=High(Params)=0;
 if Result then Result:=Params[0].Execute([grtObject]);
 if Result then begin
  Result:=Params[0].Result is TGVObject;
  if Result then begin
   TGVObject(Params[0].Result).FValue.Free;
   TGVObject(Params[0].Result).FValue:=nil;
  end;
  if Params[0].Result.Temp then Params[0].Result.Free;
 end;
end;

initialization
GRegisterDefaultModule('Object', TGMObject);
end.
 