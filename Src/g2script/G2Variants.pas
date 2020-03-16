unit G2Variants;

interface

uses
  Classes, G2Types, G2Consts, G2Execute, SysUtils, TypInfo, StrUtils;

type
  TG2VCustomString = class(TG2Variant)
  private
    FData: G2String;
  protected
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
  public
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    function Copy: TG2Variant; override;
    function Count: integer; override;
    function DefaultType: TG2ValueType; override;
  published
    function SubStr(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function Delete(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function Insert(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function Find(const P: G2Array; const Script: TG2Execute): TG2Variant;
  end;

  TG2VString = class(TG2VCustomString)
  private
    FData: G2String;
  protected
    function GetStr: G2String; override;
    procedure SetStr(const Value: G2String); override;
  end;

  TG2VSubString = class(TG2VCustomString)
  private
    FString: TG2Variant;
    FPos, FLength: integer;
  protected
    function GetStr: G2String; override;
    procedure SetStr(const Value: G2String); override;
  public
    constructor Create(const AString: TG2Variant; const APos, ALength: integer); overload;
    destructor Destroy; override;
    function CopyAndRelease: TG2Variant; override;
  end;

  TG2VStrProperty = class(TG2VCustomString)
  private
    FObject: G2Object;
    FPropInfo: PPropInfo;
  protected
    function GetStr: G2String; override;
    procedure SetStr(const Value: G2String); override;
  public
    constructor Create(const AObject: G2Object; const APropInfo: PPropInfo); overload;
    function CopyAndRelease: TG2Variant; override;
  end;

  TG2VInteger = class(TG2Variant)
  private
    FData: G2Int;
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
  public
    procedure Clear; override;
    procedure Assign(Source: TPersistent); override;
    function DefaultType: TG2ValueType; override;
  end;

  TG2VFloat = class(TG2Variant)
  private
    FData: G2Float;
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
  public
    procedure Clear; override;
    procedure Assign(Source: TPersistent); override;
    function DefaultType: TG2ValueType; override;
  end;

  TG2VBoolean = class(TG2Variant)
  private
    FData: G2Bool;
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
  public
    procedure Clear; override;
    procedure Assign(Source: TPersistent); override;
    function DefaultType: TG2ValueType; override;
  end;

  TG2VObject = class(TG2Variant)
  private
    FData: G2Object;
    FList: Boolean;
    FPersistent: Boolean;
    FPropCount: SmallInt;
    FPropList: PPropList;
    procedure SetVar(const PropInfo: PPropInfo; const Value: TG2Variant);
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
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    function Method(const Name: string): TMethod; override;
    function DefaultType: TG2ValueType; override;
    function Count: integer; override;
    function KeyCount: integer; override;
    function Key(const AIndex: integer): string; override;
  end;

  TG2VProperty = class(TG2Variant)
  private
    FObject: G2Object;
    FPropInfo: PPropInfo;
    FPropCount: SmallInt;
    FPropList: PPropList;
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
    constructor Create(const AObject: G2Object; const APropInfo: PPropInfo); overload;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    function Copy: TG2Variant; override;
    function CopyAndRelease: TG2Variant; override;
    function Method(const Name: string): TMethod; override;
    function DefaultType: TG2ValueType; override;
    function Count: integer; override;
    function KeyCount: integer; override;
    function Key(const AIndex: integer): string; override;
  end;

  TG2VArray = class(TG2Variant)
  private
    FData: TG2Array;
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
    constructor Create; override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    function Count: integer; override;
    function KeyCount: integer; override;
    function Key(const AIndex: integer): string; override;
    function DefaultType: TG2ValueType; override;
  end;

  TG2VNewVar = class(TG2Variant)
  private
    FScript: TG2Execute;
    FLocal: Boolean;
    FName: string;
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
  public
    constructor Create(const AScript: TG2Execute; const AName: string; const ALocal: Boolean); overload;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    function DefaultType: TG2ValueType; override;
  end;

implementation

uses
  G2Script;

function FirstChar(const S: string): Char;
begin
 if S='' then Result:=#0
  else Result:=S[1];
end;

{ TG2VCustomString }           

procedure TG2VCustomString.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then Str:=TG2Variant(Source).Str;
 inherited;
end;

procedure TG2VCustomString.Clear;
begin
 FData:='';
end;

function TG2VCustomString.Copy: TG2Variant;
begin
 Result:=G2Var(Str);
end;

function TG2VCustomString.Count: integer;
begin
 Result:=Length(Str);
end;

function TG2VCustomString.DefaultType: TG2ValueType;
begin
 Result:=gvtString;
end;

function TG2VCustomString.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VCustomString.GetBool: G2Bool;
begin
 Result:=(AnsiLowerCase(Str)=G2C_BooleanStr[True]) or (Str='1');
end;

function TG2VCustomString.GetFloat: G2Float;
begin
 Result:=StrToFloatDef(Str, 0.0);
end;

function TG2VCustomString.GetIndexedItem(const AKey: integer): TG2Variant;
begin
 if (AKey>=0) and (AKey<Length(Str)) then Result:=TG2VSubString.Create(Self, AKey, 1)
  else Result:=nil;
end;

function TG2VCustomString.GetInt: G2Int;
begin
 Result:=StrToInt64Def(Str, 0);
end;

function TG2VCustomString.GetObj: G2Object;
begin
 Result:=nil;
end;

procedure TG2VCustomString.SetArray(const Value: G2Array);
begin
 Clear;
 G2Release(Value);
end;

procedure TG2VCustomString.SetBool(const Value: G2Bool);
begin
 Str:=G2C_BooleanStr[Value];
end;

procedure TG2VCustomString.SetFloat(const Value: G2Float);
begin
 Str:=FloatToStr(Value);
end;

procedure TG2VCustomString.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
var S: string;
begin
 if Value=nil then Exit;
 S:=Str;
 if (AKey>=0) and (AKey<Length(S)) then begin
  S[AKey+1]:=FirstChar(Value.Str);
  Str:=S;
 end;
 G2ReleaseConst(Value);
end;

procedure TG2VCustomString.SetInt(const Value: G2Int);
begin
 Str:=IntToStr(Value);
end;

procedure TG2VCustomString.SetObj(const Value: G2Object);
begin
 Str:=G2ObjToStr(Value);
end;

function TG2VCustomString.SubStr(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 if G2ParamCountError(2, P, Script) then begin Result:=nil; Exit; end;
 Result:=TG2VSubString.Create(Self, P[0].Int, P[1].Int);
 G2Release(P);
end;

function TG2VCustomString.Delete(const P: G2Array; const Script: TG2Execute): TG2Variant;
var S: string;
begin
 Result:=nil;
 if G2ParamCountError(2, P, Script) then Exit;
 S:=Str;
 System.Delete(S, P[0].Int+1, P[1].Int);
 Str:=S;
 G2Release(P);
end;

function TG2VCustomString.Insert(const P: G2Array; const Script: TG2Execute): TG2Variant;
var S: string;
begin
 if G2ParamCountError(2, P, Script) then begin Result:=nil; Exit; end;
 S:=Str;
 System.Insert(P[0].Str, S, P[1].Int+1);
 Result:=P[0];
 Str:=S;
 G2ReleaseConst(P[1]);
end;

function TG2VCustomString.Find(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 if G2ParamRangeError(1, 2, P, Script) then begin Result:=nil; Exit; end;
 if Length(P)=1 then Result:=G2Var(Pos(P[0].Str, Str)-1)
 else Result:=G2Var(PosEx(P[0].Str, Str, P[1].Int+1)-1);
 G2Release(P);
end;

{ TG2VFloat }

procedure TG2VFloat.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then FData:=TG2Variant(Source).Float;
 inherited;
end;

procedure TG2VFloat.Clear;
begin
 FData:=0.0;
end;

function TG2VFloat.DefaultType: TG2ValueType;
begin
 Result:=gvtFloat;
end;

function TG2VFloat.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VFloat.GetBool: G2Bool;
begin
 Result:=FData>0.0;
end;

function TG2VFloat.GetFloat: G2Float;
begin
 Result:=FData;
end;

function TG2VFloat.GetInt: G2Int;
begin
 Result:=Round(FData);
end;

function TG2VFloat.GetObj: G2Object;
begin
 Result:=nil;
end;

function TG2VFloat.GetStr: G2String;
begin
 Result:=FloatToStr(FData);
end;

procedure TG2VFloat.SetArray(const Value: G2Array);
begin
 Clear;
 G2Release(Value);
end;

procedure TG2VFloat.SetBool(const Value: G2Bool);
begin
 FData:=Ord(Value);
end;

procedure TG2VFloat.SetFloat(const Value: G2Float);
begin
 FData:=Value;
end;

procedure TG2VFloat.SetInt(const Value: G2Int);
begin
 FData:=Value;
end;

procedure TG2VFloat.SetObj(const Value: G2Object);
begin
 FData:=0.0;
end;

procedure TG2VFloat.SetStr(const Value: G2String);
begin
 FData:=StrToFloatDef(Value, 0.0);
end;

{ TG2VInteger }

procedure TG2VInteger.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then FData:=TG2Variant(Source).Int;
 inherited;
end;

procedure TG2VInteger.Clear;
begin
 FData:=0;
end;

function TG2VInteger.DefaultType: TG2ValueType;
begin
 Result:=gvtInteger;
end;

function TG2VInteger.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VInteger.GetBool: G2Bool;
begin
 Result:=FData>0;
end;

function TG2VInteger.GetFloat: G2Float;
begin
 Result:=FData;
end;

function TG2VInteger.GetInt: G2Int;
begin
 Result:=FData;
end;

function TG2VInteger.GetObj: G2Object;
begin
 Result:=G2Object(FData);
end;

function TG2VInteger.GetStr: G2String;
begin
 Result:=IntToStr(FData);
end;

procedure TG2VInteger.SetArray(const Value: G2Array);
begin
 FData:=Length(Value);
 G2Release(Value);
end;

procedure TG2VInteger.SetBool(const Value: G2Bool);
begin
 FData:=Ord(Value);
end;

procedure TG2VInteger.SetFloat(const Value: G2Float);
begin
 FData:=Round(Value);
end;

procedure TG2VInteger.SetInt(const Value: G2Int);
begin
 FData:=Value;
end;

procedure TG2VInteger.SetObj(const Value: G2Object);
begin
 FData:=G2Int(Value);
end;

procedure TG2VInteger.SetStr(const Value: G2String);
begin
 FData:=StrToInt64Def(Value, 0);
end;

{ TG2VBoolean }

procedure TG2VBoolean.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then FData:=TG2Variant(Source).Bool;
 inherited;
end;

procedure TG2VBoolean.Clear;
begin
 FData:=False;
end;

function TG2VBoolean.DefaultType: TG2ValueType;
begin
 Result:=gvtBoolean;
end;

function TG2VBoolean.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VBoolean.GetBool: G2Bool;
begin
 Result:=FData;
end;

function TG2VBoolean.GetFloat: G2Float;
begin
 Result:=Ord(FData);
end;

function TG2VBoolean.GetInt: G2Int;
begin
 Result:=Ord(FData);
end;

function TG2VBoolean.GetObj: G2Object;
begin
 Result:=nil;
end;

function TG2VBoolean.GetStr: G2String;
begin
 Result:=G2C_BooleanStr[FData];
end;

procedure TG2VBoolean.SetArray(const Value: G2Array);
begin
 FData:=Length(Value)>0;
 G2Release(Value);
end;

procedure TG2VBoolean.SetBool(const Value: G2Bool);
begin
 FData:=Value;
end;

procedure TG2VBoolean.SetFloat(const Value: G2Float);
begin
 FData:=Value>0.0;
end;

procedure TG2VBoolean.SetInt(const Value: G2Int);
begin
 FData:=Value>0;
end;

procedure TG2VBoolean.SetObj(const Value: G2Object);
begin
 FData:=Value<>nil;
end;

procedure TG2VBoolean.SetStr(const Value: G2String);
begin
 FData:=(AnsiLowerCase(Value)=G2C_BooleanStr[True]) or (Value='1');
end;

{ TG2VObject }

procedure TG2VObject.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then Obj:=TG2Variant(Source).Obj;
 inherited;
end;

procedure TG2VObject.Clear;
begin
 SetObj(nil);
end;

function TG2VObject.Count: integer;
begin
 if FList then Result:=TList(FData).Count
 else if FPersistent then begin
  if FPropCount=-1 then FPropCount:=GetTypeData(FData.ClassInfo).PropCount;
  Result:=FPropCount;
 end else Result:=0;
end;

function TG2VObject.DefaultType: TG2ValueType;
begin
 Result:=gvtObject;
end;

destructor TG2VObject.Destroy;
begin
 if FPropList<>nil then Dispose(FPropList);
 inherited;
end;

function TG2VObject.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VObject.GetBool: G2Bool;
begin
 Result:=FData<>nil;
end;

function TG2VObject.GetFloat: G2Float;
begin
 Result:=0.0;
end;

function TG2VObject.GetIndexedItem(const AKey: integer): TG2Variant;
begin
 Result:=nil;
 if FList then begin
  if (AKey>=0) and (AKey<TList(FData).Count) then Result:=G2Var(TObject(TList(FData).Items[AKey]));
 end else if FPersistent then begin
  if FPropCount=-1 then FPropCount:=GetTypeData(FData.ClassInfo).PropCount;
  if FPropList=nil then begin
   GetMem(FPropList, FPropCount*SizeOf(PPropInfo));
   GetPropList(FData.ClassInfo, tkAny, FPropList);
  end;
  if (AKey>=0) and (AKey<FPropCount) then
   if FPropList[AKey].GetProc<>nil then
    case FPropList[AKey].PropType^.Kind of
     tkEnumeration, tkChar, tkWChar, tkSet, tkString, tkLString, tkWString: Result:=TG2VStrProperty.Create(FData, FPropList[AKey]);
     else Result:=TG2VProperty.Create(FData, FPropList[AKey]);
    end;
 end;
end;

function TG2VObject.GetInt: G2Int;
begin
 Result:=G2Int(FData);
end;

function TG2VObject.GetKeyedItem(const AKey: string): TG2Variant;
var PropInfo: PPropInfo;
begin
 Result:=nil;
 if FPersistent then begin
  PropInfo:=GetPropInfo(FData, AKey);
  if PropInfo<>nil then
   if PropInfo.GetProc<>nil then
    case PropInfo.PropType^.Kind of
     tkEnumeration, tkChar, tkWChar, tkSet, tkString, tkLString, tkWString: Result:=TG2VStrProperty.Create(FData, PropInfo);
     else Result:=TG2VProperty.Create(FData, PropInfo);
    end;
 end;
end;

function TG2VObject.GetObj: G2Object;
begin
 Result:=FData;
end;

function TG2VObject.GetStr: G2String;
begin
 Result:=G2ObjToStr(FData);
end;

function TG2VObject.Key(const AIndex: integer): string;
begin
 if FPersistent then begin
  if FPropCount=-1 then FPropCount:=GetTypeData(FData.ClassInfo).PropCount;
  if FPropList=nil then begin
   GetMem(FPropList, FPropCount*SizeOf(PPropInfo));
   GetPropList(FData.ClassInfo, tkAny, FPropList);
  end;
  if (AIndex>=0) and (AIndex<FPropCount) then Result:=FPropList[AIndex].Name
   else Result:='';
 end else Result:='';
end;

function TG2VObject.KeyCount: integer;
begin
 if FPersistent then begin
  if FPropCount=-1 then FPropCount:=GetTypeData(FData.ClassInfo).PropCount;
  Result:=FPropCount;
 end else Result:=0;
end;

function TG2VObject.Method(const Name: string): TMethod;
begin
 if FPersistent then begin
  Result.Code:=FData.MethodAddress(Name);
  Result.Data:=FData;
 end;
end;

procedure TG2VObject.SetArray(const Value: G2Array);
begin
 Clear;
 G2Release(Value);
end;

procedure TG2VObject.SetBool(const Value: G2Bool);
begin
 Clear;
end;

procedure TG2VObject.SetFloat(const Value: G2Float);
begin
 Clear;
end;

procedure TG2VObject.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
begin
 if FList then begin
  if (AKey>=0) and (AKey<TList(FData).Count) then TList(FData).Items[AKey]:=Value
   else TList(FData).Add(Value);
  G2ReleaseConst(Value); 
 end else if FPersistent then begin
  if FPropCount=-1 then FPropCount:=GetTypeData(FData.ClassInfo).PropCount;
  if FPropList=nil then begin
   GetMem(FPropList, FPropCount*SizeOf(PPropInfo));
   GetPropList(FData.ClassInfo, tkAny, FPropList);
  end;
  if (AKey>=0) and (AKey<FPropCount) then SetVar(FPropList[AKey], Value)
   else G2ReleaseConst(Value);
 end else G2ReleaseConst(Value);
end;

procedure TG2VObject.SetInt(const Value: G2Int);
begin
 Clear;
end;

procedure TG2VObject.SetKeyedItem(const AKey: string; const Value: TG2Variant);
var PropInfo: PPropInfo;
begin
 if FPersistent then begin
  PropInfo:=GetPropInfo(FData, AKey);
  if PropInfo<>nil then SetVar(PropInfo, Value)
   else G2ReleaseConst(Value);
 end else G2ReleaseConst(Value);
end;

procedure TG2VObject.SetObj(const Value: G2Object);
begin
 if FPropList<>nil then Dispose(FPropList);
 FPropList:=nil;
 FPropCount:=-1;
 FData:=Value;
 FList:=FData is TList;
 FPersistent:=FData is TPersistent;
end;

procedure TG2VObject.SetStr(const Value: G2String);
begin
 Clear;
end;

procedure TG2VObject.SetVar(const PropInfo: PPropInfo; const Value: TG2Variant);
begin
 if Value=nil then Exit;
 if PropInfo.SetProc<>nil then
  case PropInfo.PropType^.Kind of
   tkEnumeration: SetEnumProp(FData, PropInfo, Value.Str);
   tkChar, tkWChar: SetOrdProp(FData, PropInfo, Ord(FirstChar(Value.Str)));
   tkSet: SetOrdProp(FData, PropInfo, StringToSet(PropInfo, Value.Str));
   tkInteger: SetOrdProp(FData, PropInfo, Value.Int);
   tkInt64: SetInt64Prop(FData, PropInfo, Value.Int);
   tkFloat: SetFloatProp(FData, PropInfo, Value.Float);
   tkString, tkLString: SetStrProp(FData, PropInfo, Value.Str);
   tkWString: SetWideStrProp(FData, PropInfo, Value.Str);
   tkClass: SetObjectProp(FData, PropInfo, Value.Obj);
  end;
 Value.Release;
end;

{ TG2VProperty }

procedure TG2VProperty.Assign(Source: TPersistent);
begin
 if Source is TG2Variant then begin
  case FPropInfo.PropType^.Kind of
   tkEnumeration: SetEnumProp(FObject, FPropInfo, TG2Variant(Source).Str);
   tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, Ord(FirstChar(TG2Variant(Source).Str)));
   tkSet: SetOrdProp(FObject, FPropInfo, StringToSet(FPropInfo, TG2Variant(Source).Str));
   tkInteger: SetOrdProp(FObject, FPropInfo, TG2Variant(Source).Int);
   tkInt64: SetInt64Prop(FObject, FPropInfo, TG2Variant(Source).Int);
   tkFloat: SetFloatProp(FObject, FPropInfo, TG2Variant(Source).Float);
   tkString, tkLString: SetStrProp(FObject, FPropInfo, TG2Variant(Source).Str);
   tkWString: SetWideStrProp(FObject, FPropInfo, TG2Variant(Source).Str);
   tkClass: SetObjectProp(FObject, FPropInfo, TG2Variant(Source).Obj);
  end;
 end;
 inherited;
end;

procedure TG2VProperty.Clear;
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, '');
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, 0);
  tkSet: SetOrdProp(FObject, FPropInfo, 0);
  tkInteger: SetOrdProp(FObject, FPropInfo, 0);
  tkInt64: SetInt64Prop(FObject, FPropInfo, 0);
  tkFloat: SetFloatProp(FObject, FPropInfo, 0);
  tkString, tkLString: SetStrProp(FObject, FPropInfo, '');
  tkWString: SetWideStrProp(FObject, FPropInfo, '');
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;

function TG2VProperty.Copy: TG2Variant;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=G2Var(GetEnumProp(FObject, FPropInfo));
  tkChar, tkWChar: Result:=G2Var(Chr(GetOrdProp(FObject, FPropInfo)));
  tkSet: Result:=G2Var(SetToString(FPropInfo, GetOrdProp(FObject, FPropInfo), True));
  tkInteger: Result:=G2Var(GetOrdProp(FObject, FPropInfo));
  tkInt64: Result:=G2Var(GetInt64Prop(FObject, FPropInfo));
  tkFloat: Result:=G2Var(GetFloatProp(FObject, FPropInfo));
  tkString, tkLString: Result:=G2Var(GetStrProp(FObject, FPropInfo));
  tkWString: Result:=G2Var(GetWideStrProp(FObject, FPropInfo));
  tkClass: Result:=G2Var(GetObjectProp(FObject, FPropInfo));
  else Result:=G2Var('Unsupported!');
 end;
end;

function TG2VProperty.CopyAndRelease: TG2Variant;
begin
 Result:=Copy;
 Release;
end;

function TG2VProperty.Count: integer;
var Obj: TObject;
begin
 case FPropInfo.PropType^.Kind of
  tkString, tkLString: Result:=Length(GetStrProp(FObject, FPropInfo));
  tkWString: Result:=Length(GetWideStrProp(FObject, FPropInfo));
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TList then Result:=TList(Obj).Count
   else if Obj is TPersistent then begin
    if FPropCount=-1 then FPropCount:=GetTypeData(Obj.ClassInfo).PropCount;
    Result:=FPropCount;
   end else Result:=0;
  end;
  else Result:=0;
 end;
end;

constructor TG2VProperty.Create(const AObject: G2Object; const APropInfo: PPropInfo);
begin
 inherited Create;
 FObject:=AObject;
 FPropInfo:=APropInfo;
 FPropCount:=-1;
 ReadOnly:=FPropInfo.SetProc=nil;
end;

function TG2VProperty.DefaultType: TG2ValueType;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration, tkChar, tkWChar, tkSet, tkString, tkLString, tkWString: Result:=gvtString;
  tkInteger, tkInt64: Result:=gvtInteger;
  tkFloat: Result:=gvtFloat;
  tkClass: Result:=gvtObject;
  else Result:=gvtNone;
 end;
end;

destructor TG2VProperty.Destroy;
begin
 if FPropList<>nil then Dispose(FPropList);
 inherited;
end;

function TG2VProperty.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VProperty.GetBool: G2Bool;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=AnsiLowerCase(GetEnumProp(FObject, FPropInfo))=G2C_BooleanStr[True];
  tkChar, tkWChar: Result:=GetOrdProp(FObject, FPropInfo)>0;
  tkSet: Result:=GetOrdProp(FObject, FPropInfo)>0;
  tkInteger: Result:=GetOrdProp(FObject, FPropInfo)>0;
  tkInt64: Result:=GetInt64Prop(FObject, FPropInfo)>0;
  tkFloat: Result:=GetFloatProp(FObject, FPropInfo)>0.0;
  tkString, tkLString: Result:=AnsiLowerCase(GetStrProp(FObject, FPropInfo))=G2C_BooleanStr[True];
  tkWString: Result:=AnsiLowerCase(GetWideStrProp(FObject, FPropInfo))=G2C_BooleanStr[True];
  tkClass: Result:=GetObjectProp(FObject, FPropInfo)<>nil;
  else Result:=False;
 end;
end;

function TG2VProperty.GetFloat: G2Float;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=GetEnumValue(FPropInfo.PropType^, GetEnumProp(FObject, FPropInfo));
  tkChar, tkWChar: Result:=GetOrdProp(FObject, FPropInfo);
  tkSet: Result:=GetOrdProp(FObject, FPropInfo);
  tkInteger: Result:=GetOrdProp(FObject, FPropInfo);
  tkInt64: Result:=GetInt64Prop(FObject, FPropInfo);
  tkFloat: Result:=GetFloatProp(FObject, FPropInfo);
  tkString, tkLString: Result:=StrToFloatDef(GetStrProp(FObject, FPropInfo), 0.0);
  tkWString: Result:=StrToFloatDef(GetWideStrProp(FObject, FPropInfo), 0.0);
  else Result:=0.0;
 end;
end;

function TG2VProperty.GetIndexedItem(const AKey: integer): TG2Variant;
var Obj: TObject;
begin
 Result:=nil;
 if AKey<0 then Exit;
 case FPropInfo.PropType^.Kind of
  tkString, tkLString, tkWString: Result:=TG2VSubString.Create(Self, AKey, 1);
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TList then begin
    if TList(Obj).Count>AKey then Result:=G2Var(TObject(TList(Obj).Items[AKey]));
   end else if Obj is TPersistent then begin
    if FPropCount=-1 then FPropCount:=GetTypeData(Obj.ClassInfo).PropCount;
    if FPropList=nil then begin
     GetMem(FPropList, FPropCount*SizeOf(PPropInfo));
     GetPropList(Obj.ClassInfo, tkAny, FPropList);
    end;
    if (FPropCount>AKey) and (AKey>=0) then
     if FPropList[AKey].GetProc<>nil then
      case FPropList[AKey].PropType^.Kind of
       tkEnumeration, tkChar, tkWChar, tkSet, tkString, tkLString, tkWString: Result:=TG2VStrProperty.Create(Obj, FPropList[AKey]);
       else Result:=TG2VProperty.Create(Obj, FPropList[AKey]);
      end;
   end;
  end;
 end;
end;

function TG2VProperty.GetInt: G2Int;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=GetEnumValue(FPropInfo.PropType^, GetEnumProp(FObject, FPropInfo));
  tkChar, tkWChar: Result:=GetOrdProp(FObject, FPropInfo);
  tkSet: Result:=GetOrdProp(FObject, FPropInfo);
  tkInteger: Result:=GetOrdProp(FObject, FPropInfo);
  tkInt64: Result:=GetInt64Prop(FObject, FPropInfo);
  tkFloat: Result:=Round(GetFloatProp(FObject, FPropInfo));
  tkString, tkLString: Result:=StrToInt64Def(GetStrProp(FObject, FPropInfo), 0);
  tkWString: Result:=StrToInt64Def(GetWideStrProp(FObject, FPropInfo), 0);
  else Result:=0;
 end;
end;

function TG2VProperty.GetKeyedItem(const AKey: string): TG2Variant;
var Obj: TObject;
    PropInfo: PPropInfo;
begin
 Result:=nil;
 case FPropInfo.PropType^.Kind of
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TPersistent then begin
    PropInfo:=GetPropInfo(Obj, AKey);
    if PropInfo<>nil then
     if PropInfo.GetProc<>nil then
      case PropInfo.PropType^.Kind of
       tkEnumeration, tkChar, tkWChar, tkSet, tkString, tkLString, tkWString: Result:=TG2VStrProperty.Create(Obj, PropInfo);
       else Result:=TG2VProperty.Create(Obj, PropInfo);
      end;
   end;
  end;
 end;
end;

function TG2VProperty.GetObj: G2Object;
begin
 case FPropInfo.PropType^.Kind of
  tkClass: Result:=GetObjectProp(FObject, FPropInfo);
  else Result:=nil;
 end;
end;

function TG2VProperty.GetStr: G2String;
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=GetEnumProp(FObject, FPropInfo);
  tkChar, tkWChar: Result:=Chr(GetOrdProp(FObject, FPropInfo));
  tkSet: Result:=SetToString(FPropInfo, GetOrdProp(FObject, FPropInfo), True);
  tkInteger: Result:=IntToStr(GetOrdProp(FObject, FPropInfo));
  tkInt64: Result:=IntToStr(GetInt64Prop(FObject, FPropInfo));
  tkFloat: Result:=FloatToStr(GetFloatProp(FObject, FPropInfo));
  tkString, tkLString: Result:=GetStrProp(FObject, FPropInfo);
  tkWString: Result:=GetWideStrProp(FObject, FPropInfo);
  else Result:='Unsupported!';
 end;
end;

function TG2VProperty.Key(const AIndex: integer): string;
var Obj: TObject;
begin
 Result:='';
 case FPropInfo.PropType^.Kind of
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TPersistent then begin
    if FPropCount=-1 then FPropCount:=GetTypeData(Obj.ClassInfo).PropCount;
    if FPropList=nil then begin
     GetMem(FPropList, FPropCount*SizeOf(PPropInfo));
     GetPropList(Obj.ClassInfo, tkAny, FPropList);
    end;
    if (FPropCount>AIndex) and (AIndex>=0) then Result:=FPropList[AIndex].Name;
   end;
  end;
 end;
end;

function TG2VProperty.KeyCount: integer;
var Obj: TObject;
begin
 case FPropInfo.PropType^.Kind of
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TPersistent then begin
    if FPropCount=-1 then FPropCount:=GetTypeData(Obj.ClassInfo).PropCount;
    Result:=FPropCount;
   end else Result:=0;
  end;
  else Result:=0;
 end;
end;

function TG2VProperty.Method(const Name: string): TMethod;
var Obj: TObject;
begin
 Result.Code:=nil;
 case FPropInfo.PropType^.Kind of
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TPersistent then begin
    Result.Code:=Obj.MethodAddress(Name);
    Result.Data:=Obj;
   end;
  end;
 end;
end;

procedure TG2VProperty.SetArray(const Value: G2Array);
begin
 Clear;
 G2Release(Value);
end;

procedure TG2VProperty.SetBool(const Value: G2Bool);
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, G2C_BooleanStr[Value]);
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, Ord(Value));
  tkSet: SetOrdProp(FObject, FPropInfo, 0);
  tkInteger: SetOrdProp(FObject, FPropInfo, Ord(Value));
  tkInt64: SetInt64Prop(FObject, FPropInfo, Ord(Value));
  tkFloat: SetFloatProp(FObject, FPropInfo, Ord(Value));
  tkString, tkLString: SetStrProp(FObject, FPropInfo, G2C_BooleanStr[Value]);
  tkWString: SetWideStrProp(FObject, FPropInfo, G2C_BooleanStr[Value]);
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;

procedure TG2VProperty.SetFloat(const Value: G2Float);
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, '');
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, 0);
  tkSet: SetOrdProp(FObject, FPropInfo, 0);
  tkInteger: SetOrdProp(FObject, FPropInfo, Round(Value));
  tkInt64: SetInt64Prop(FObject, FPropInfo, Round(Value));
  tkFloat: SetFloatProp(FObject, FPropInfo, Value);
  tkString, tkLString: SetStrProp(FObject, FPropInfo, FloatToStr(Value));
  tkWString: SetWideStrProp(FObject, FPropInfo, FloatToStr(Value));
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;

procedure TG2VProperty.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
var Obj: TObject;
    S: string;
    PropList: TPropList;
begin
 if Value=nil then Exit;
 case FPropInfo.PropType^.Kind of
  tkString, tkLString: begin
   if AKey<0 then Exit;
   S:=GetStrProp(FObject, FPropInfo);
   if Length(S)>AKey then S[AKey+1]:=FirstChar(Value.Str);
   SetStrProp(FObject, FPropInfo, S);
  end;
  tkWString: begin
   if AKey<0 then Exit;
   S:=GetWideStrProp(FObject, FPropInfo);
   if Length(S)>AKey then S[AKey+1]:=FirstChar(Value.Str);
   SetWideStrProp(FObject, FPropInfo, S);
  end;
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TList then begin
    if (TList(Obj).Count>AKey) and (AKey>=0) then TList(Obj).Items[AKey]:=Value.Obj
     else TList(Obj).Add(Value.Obj);
   end else if Obj is TPersistent then begin
    if GetPropList(Obj.ClassInfo, tkAny, @PropList)>AKey then
     if PropList[AKey].SetProc<>nil then
      case PropList[AKey].PropType^.Kind of
       tkEnumeration: SetEnumProp(Obj, PropList[AKey], Value.Str);
       tkChar, tkWChar: SetOrdProp(Obj, PropList[AKey], Ord(FirstChar(Value.Str)));
       tkSet: SetOrdProp(Obj, PropList[AKey], StringToSet(PropList[AKey], Value.Str));
       tkInteger: SetOrdProp(Obj, PropList[AKey], Value.Int);
       tkInt64: SetInt64Prop(Obj, PropList[AKey], Value.Int);
       tkFloat: SetFloatProp(Obj, PropList[AKey], Value.Float);
       tkString, tkLString: SetStrProp(Obj, PropList[AKey], Value.Str);
       tkWString: SetWideStrProp(Obj, PropList[AKey], Value.Str);
       tkClass: SetObjectProp(Obj, PropList[AKey], Value.Obj);
      end;
   end;
  end;
 end;
 G2ReleaseConst(Value);
end;

procedure TG2VProperty.SetInt(const Value: G2Int);
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, GetEnumName(FPropInfo.PropType^, Value));
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, Value);
  tkSet: SetOrdProp(FObject, FPropInfo, Value);
  tkInteger: SetOrdProp(FObject, FPropInfo, Value);
  tkInt64: SetInt64Prop(FObject, FPropInfo, Value);
  tkFloat: SetFloatProp(FObject, FPropInfo, Value);
  tkString, tkLString: SetStrProp(FObject, FPropInfo, IntToStr(Value));
  tkWString: SetWideStrProp(FObject, FPropInfo, IntToStr(Value));
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;

procedure TG2VProperty.SetKeyedItem(const AKey: string; const Value: TG2Variant);
var Obj: TObject;
    PropInfo: PPropInfo;
begin
 if Value=nil then Exit;
 case FPropInfo.PropType^.Kind of
  tkClass: begin
   Obj:=GetObjectProp(FObject, FPropInfo);
   if Obj is TPersistent then begin
    PropInfo:=GetPropInfo(Obj, AKey);
    if PropInfo<>nil then
     if PropInfo.SetProc<>nil then
      case PropInfo.PropType^.Kind of
       tkEnumeration: SetEnumProp(Obj, PropInfo, Value.Str);
       tkChar, tkWChar: SetOrdProp(Obj, PropInfo, Ord(FirstChar(Value.Str)));
       tkSet: SetOrdProp(Obj, PropInfo, StringToSet(PropInfo, Value.Str));
       tkInteger: SetOrdProp(Obj, PropInfo, Value.Int);
       tkInt64: SetInt64Prop(Obj, PropInfo, Value.Int);
       tkFloat: SetFloatProp(Obj, PropInfo, Value.Float);
       tkString, tkLString: SetStrProp(Obj, PropInfo, Value.Str);
       tkWString: SetWideStrProp(Obj, PropInfo, Value.Str);
       tkClass: SetObjectProp(Obj, PropInfo, Value.Obj);
      end;
   end;
  end;
 end;
 G2ReleaseConst(Value);
end;

procedure TG2VProperty.SetObj(const Value: G2Object);
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, '');
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, 0);
  tkSet: SetOrdProp(FObject, FPropInfo, 0);
  tkInteger: SetOrdProp(FObject, FPropInfo, Integer(Value));
  tkInt64: SetInt64Prop(FObject, FPropInfo, Int64(Value));
  tkFloat: SetFloatProp(FObject, FPropInfo, 0.0);
  tkString, tkLString: SetStrProp(FObject, FPropInfo, G2ObjToStr(Value));
  tkWString: SetWideStrProp(FObject, FPropInfo, G2ObjToStr(Value));
  tkClass: SetObjectProp(FObject, FPropInfo, Value);
 end;
end;

procedure TG2VProperty.SetStr(const Value: G2String);
begin
 if FPropList<>nil then begin Dispose(FPropList); FPropList:=nil; end;
 FPropCount:=-1;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, Value);
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, Ord(FirstChar(Value)));
  tkSet: SetOrdProp(FObject, FPropInfo, StringToSet(FPropInfo, Value));
  tkInteger: SetOrdProp(FObject, FPropInfo, StrToIntDef(Value, 0));
  tkInt64: SetInt64Prop(FObject, FPropInfo, StrToInt64Def(Value, 0));
  tkFloat: SetFloatProp(FObject, FPropInfo, StrToFloatDef(Value, 0.0));
  tkString, tkLString: SetStrProp(FObject, FPropInfo, Value);
  tkWString: SetWideStrProp(FObject, FPropInfo, Value);
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;


{ TG2VArray }

procedure TG2VArray.Assign(Source: TPersistent);
var I: integer;
    SData: TG2Array;
    Item: TG2Variant;
begin
 if Source is TG2VArray then begin
  Clear;
  SData:=TG2VArray(Source).FData;
  for I:=0 to SData.Count-1 do begin
   Item:=SData.GetItemByIndex(I);
   if Item<>nil then Item:=Item.Copy;
   if SData.KeyIndex(I)<0 then Item:=FData.Add(Item)
    else Item:=FData.Add(Item, SData.Keys[SData.KeyIndex(I)]);
   if Item<>nil then Item.ReadOnly:=False;
  end;
 end else if Source is TG2Variant then Arr:=TG2Variant(Source).Arr;
 inherited;
end;

procedure TG2VArray.Clear;
var I: integer;
begin
 for I:=FData.Count-1 downto 0 do
  G2ReleaseConst(TG2Variant(FData.GetItemByIndex(I)));
 FData.Clear;
end;

function TG2VArray.Count: integer;
begin
 Result:=FData.Count;
end;

constructor TG2VArray.Create;
begin
 inherited;
 FData:=TG2Array.Create;
end;

function TG2VArray.DefaultType: TG2ValueType;
begin
 Result:=gvtArray;
end;

destructor TG2VArray.Destroy;
begin
 Clear;
 FData.Free;
 inherited;
end;

function TG2VArray.GetArray: G2Array;
var I: integer;
begin
 SetLength(Result, FData.Count);
 for I:=0 to FData.Count-1 do
  Result[I]:=TG2Variant(FData.GetItemByIndex(I)).Reference;
end;

function TG2VArray.GetBool: G2Bool;
begin
 Result:=FData.Count>0;
end;

function TG2VArray.GetFloat: G2Float;
begin
 Result:=0.0;
end;

function TG2VArray.GetIndexedItem(const AKey: integer): TG2Variant;
begin
 Result:=TG2Variant(FData.GetItemByIndex(AKey));
 if Result<>nil then Result:=Result.Reference;
end;

function TG2VArray.GetInt: G2Int;
begin
 Result:=FData.Count;
end;

function TG2VArray.GetKeyedItem(const AKey: string): TG2Variant;
begin
 Result:=TG2Variant(FData.GetItemByKey(AKey));
 if Result<>nil then Result:=Result.Reference;
end;

function TG2VArray.GetObj: G2Object;
begin
 Result:=nil;
end;

function TG2VArray.GetStr: G2String;
var I: integer;
begin
 Result:='[';
 for I:=0 to FData.Count-1 do begin
  if I>0 then Result:=Result+', ';
  if FData.GetItemByIndex(I)<>nil then Result:=Result+TG2Variant(FData.GetItemByIndex(I)).Str;
 end;
 Result:=Result+']';
end;

function TG2VArray.Key(const AIndex: integer): string;
begin
 Result:=FData.Keys[AIndex];
end;

function TG2VArray.KeyCount: integer;
begin
 Result:=FData.KeyCount;
end;

procedure TG2VArray.SetArray(const Value: G2Array);
var I: integer;
begin
 Clear;
 for I:=Low(Value) to High(Value) do
  if Value[I]=nil then FData.Add(nil)
   else TG2Variant(FData.Add(Value[I].CopyAndRelease)).ReadOnly:=False;
end;

procedure TG2VArray.SetBool(const Value: G2Bool);
begin
 Clear;
end;

procedure TG2VArray.SetFloat(const Value: G2Float);
begin
 Clear;
end;

procedure TG2VArray.SetIndexedItem(const AKey: integer; const Value: TG2Variant);
var TheValue: TG2Variant;
begin
 if Value=nil then G2ReleaseConst(TG2Variant(FData.SetItemByIndex(AKey, nil)))
  else begin
   TheValue:=Value.CopyAndRelease;
   TheValue.ReadOnly:=False;
   G2ReleaseConst(TG2Variant(FData.SetItemByIndex(AKey, TheValue)));
 end;
end;

procedure TG2VArray.SetInt(const Value: G2Int);
begin
 Clear;
end;

procedure TG2VArray.SetKeyedItem(const AKey: string; const Value: TG2Variant);
var TheValue: TG2Variant;
begin
 if Value=nil then G2ReleaseConst(TG2Variant(FData.SetItemByKey(AKey, nil)))
  else begin
   TheValue:=Value.CopyAndRelease;
   TheValue.ReadOnly:=False;
   G2ReleaseConst(TG2Variant(FData.SetItemByKey(AKey, TheValue)));
 end;
end;

procedure TG2VArray.SetObj(const Value: G2Object);
begin
 Clear;
end;

procedure TG2VArray.SetStr(const Value: G2String);
begin
 Clear;
end;

{ TG2VString }

function TG2VString.GetStr: G2String;
begin
 Result:=FData;
end;

procedure TG2VString.SetStr(const Value: G2String);
begin
 FData:=Value;
end;

{ TG2VSubString }

function TG2VSubString.CopyAndRelease: TG2Variant;
begin
 Result:=Copy;
 Release;
end;

constructor TG2VSubString.Create(const AString: TG2Variant; const APos, ALength: integer);
begin
 inherited Create;
 if AString<>nil then FString:=AString.Reference;
 FPos:=APos;
 FLength:=ALength;
end;

destructor TG2VSubString.Destroy;
begin
 if FString<>nil then FString.Release;
 inherited;
end;

function TG2VSubString.GetStr: G2String;
begin
 if FString<>nil then Result:=System.Copy(FString.Str, FPos+1, FLength);
end;

procedure TG2VSubString.SetStr(const Value: G2String);
var S: string;
begin
 if FString<>nil then
  if not FString.ReadOnly then begin
   S:=FString.Str;
   System.Delete(S, FPos+1, FLength);
   System.Insert(Value, S, FPos+1);
   FString.Str:=S;
  end;
end;

{ TG2VStrProperty }

function TG2VStrProperty.CopyAndRelease: TG2Variant;
begin
 Result:=Copy;
 Release;
end;

constructor TG2VStrProperty.Create(const AObject: G2Object; const APropInfo: PPropInfo);
begin
 inherited Create;
 FObject:=AObject;
 FPropInfo:=APropInfo;
 ReadOnly:=FPropInfo.SetProc=nil;
end;

function TG2VStrProperty.GetStr: G2String;
begin
 if FPropInfo.GetProc=nil then begin Result:=''; Exit; end;
 case FPropInfo.PropType^.Kind of
  tkEnumeration: Result:=GetEnumProp(FObject, FPropInfo);
  tkChar, tkWChar: Result:=Chr(GetOrdProp(FObject, FPropInfo));
  tkSet: Result:=SetToString(FPropInfo, GetOrdProp(FObject, FPropInfo), True);
  tkInteger: Result:=IntToStr(GetOrdProp(FObject, FPropInfo));
  tkInt64: Result:=IntToStr(GetInt64Prop(FObject, FPropInfo));
  tkFloat: Result:=FloatToStr(GetFloatProp(FObject, FPropInfo));
  tkString, tkLString: Result:=GetStrProp(FObject, FPropInfo);
  tkWString: Result:=GetWideStrProp(FObject, FPropInfo);
  else Result:='Unsupported!';
 end;
end;

procedure TG2VStrProperty.SetStr(const Value: G2String);
begin
 case FPropInfo.PropType^.Kind of
  tkEnumeration: SetEnumProp(FObject, FPropInfo, Value);
  tkChar, tkWChar: SetOrdProp(FObject, FPropInfo, Ord(FirstChar(Value)));
  tkSet: SetOrdProp(FObject, FPropInfo, StringToSet(FPropInfo, Value));
  tkInteger: SetOrdProp(FObject, FPropInfo, StrToIntDef(Value, 0));
  tkInt64: SetInt64Prop(FObject, FPropInfo, StrToInt64Def(Value, 0));
  tkFloat: SetFloatProp(FObject, FPropInfo, StrToFloatDef(Value, 0.0));
  tkString, tkLString: SetStrProp(FObject, FPropInfo, Value);
  tkWString: SetWideStrProp(FObject, FPropInfo, Value);
  tkClass: SetObjectProp(FObject, FPropInfo, nil);
 end;
end;

{ TG2VNewVar }

procedure TG2VNewVar.Assign(Source: TPersistent);
var Index: integer;
    Item: TG2Variant;
begin
 if FLocal then Index:=FScript.FCurVars
  else Index:=0;
 Item:=FScript.FVars[Index].GetItemByKey(FName);
 if Item<>nil then Item.Assign(Source)
  else if Source is TG2Variant then
   FScript.FVars[Index].SetItemByKey(FName, TG2Variant(Source).Copy);
end;

procedure TG2VNewVar.Clear;
begin
end;

constructor TG2VNewVar.Create(const AScript: TG2Execute; const AName: string; const ALocal: Boolean);
begin
 inherited Create;
 FScript:=AScript;
 FName:=AName;
 FLocal:=ALocal;
end;

function TG2VNewVar.DefaultType: TG2ValueType;
begin
 Result:=gvtNone;
end;

function TG2VNewVar.GetArray: G2Array;
begin
 Result:=nil;
end;

function TG2VNewVar.GetBool: G2Bool;
begin
 Result:=False;
end;

function TG2VNewVar.GetFloat: G2Float;
begin
 Result:=0.0;
end;

function TG2VNewVar.GetInt: G2Int;
begin
 Result:=0;
end;

function TG2VNewVar.GetObj: G2Object;
begin
 Result:=nil;
end;

function TG2VNewVar.GetStr: G2String;
begin
 Result:='';
end;

procedure TG2VNewVar.SetArray(const Value: G2Array);
begin
 G2Release(Value);
end;

procedure TG2VNewVar.SetBool(const Value: G2Bool);
begin
end;

procedure TG2VNewVar.SetFloat(const Value: G2Float);
begin
end;

procedure TG2VNewVar.SetInt(const Value: G2Int);
begin
end;

procedure TG2VNewVar.SetObj(const Value: G2Object);
begin
end;

procedure TG2VNewVar.SetStr(const Value: G2String);
begin
end;

end.
