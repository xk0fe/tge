unit G2Functions;

interface

uses
  Windows, Classes, SysUtils, G2Types, G2Consts, G2Execute, G2Variants;

function G2Function(const Self: TG2Execute; const P: G2Array; const Func: TG2FunctionType): TG2Variant;

implementation

uses
  G2Script;

type TG2Function = function(const Self: TG2Execute; const P: G2Array): TG2Variant;

var FuncProcs: array[TG2FunctionType] of TG2Function;

function G2Function(const Self: TG2Execute; const P: G2Array; const Func: TG2FunctionType): TG2Variant;
begin
 if Assigned(FuncProcs[Func]) then Result:=FuncProcs[Func](Self, P)
  else Result:=nil;
end;

function G2Func_Keys(const Self: TG2Execute; const P: G2Array): TG2Variant;
var I, J: integer;
begin
 Result:=TG2VArray.Create;
 Result.ReadOnly:=True;
 for I:=Low(P) to High(P) do
  for J:=0 to P[I].KeyCount-1 do
   Result.IndexedItem[Result.Count]:=G2Var(P[I].Key(J));
 G2Release(P);
end;

function G2Func_KeyCount(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].KeyCount);
 G2Release(P);
end;

function G2Func_Key(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(2, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].Key(P[1].Int));
 G2Release(P);
end;

function G2Func_Error(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 Result:=nil;
 if G2ParamCountError(1, P, Self) then Exit;
 Self.Error(G2RE_SCRIPTERROR, [P[0].Str]);
 G2Release(P);
end;

function G2Func_Load(const Self: TG2Execute; const P: G2Array): TG2Variant;

 procedure DoInclude(const Name: TG2Variant);
 var NewExec: TG2Execute;
 begin
  NewExec:=TG2Execute(Self.FOwner.FIncluded.GetItemByKey(Name.Str));
  if NewExec=nil then begin
   NewExec:=TG2Execute.Create(Self.FOwner);
   Self.FOwner.FIncluded.Add(NewExec, Name.Str);
   if not Self.FOwner.FGetSource(Self, Name.Str, Pointer(NewExec.FSource), NewExec.FSrcLen, NewExec.FAutoFreeSource) then Exit;
  end;
  if NewExec.Execute then begin
   if NewExec.FReturn then begin
    G2ReleaseConst(Result);
    Result:=NewExec.FResult;
    NewExec.FResult:=nil;
    NewExec.FReturn:=False;
   end;
   NewExec.FExit:=False;
  end else begin
   Self.FErrorCode:=NewExec.FErrorCode;
   Self.FErrorText:=NewExec.FErrorText;
  end;
 end;

var I: integer;
begin
 Result:=nil;
 if G2ParamMinError(1, P, Self) then Exit;
 if not Assigned(Self.FOwner.FGetSource) then Self.Error(G2RE_NOSRCGET, [])
  else for I:=Low(P) to High(P) do begin
   DoInclude(P[I]);
   if Self.FErrorCode<>G2RE_INTERNAL then Break;
  end; 
 G2Release(P);
end;

function G2Func_Unload(const Self: TG2Execute; const P: G2Array): TG2Variant;

 procedure DoExclude(const Name: TG2Variant);
 var NewExec: TG2Execute;
 begin
  NewExec:=TG2Execute(Self.FOwner.FIncluded.GetItemByKey(Name.Str));
  if NewExec=nil then Self.Error(G2RE_BADMODULE, [Name.Str])
   else begin
    Self.FOwner.FIncluded.Delete(Name.Str);
    NewExec.Free;
   end;
 end;

var I: integer;
begin
 Result:=nil;
 if G2ParamMinError(1, P, Self) then Exit;
 for I:=Low(P) to High(P) do begin
  DoExclude(P[I]);
  if Self.FErrorCode<>G2RE_INTERNAL then Break;
 end; 
 G2Release(P);
end;

function G2Func_Print(const Self: TG2Execute; const P: G2Array): TG2Variant;
var I: integer;
begin
 Result:=nil;
 if not Assigned(Self.FOwner.FTextOut) then Self.Error(G2RE_NOOUTPUT, [])
  else for I:=Low(P) to High(P) do
   Self.FOwner.FTextOut(Self, P[I].Str);
 G2Release(P);
end;

function G2Func_Random(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 Result:=nil;
 if G2ParamMaxError(2, P, Self) then Exit;
 case Length(P) of
  0: Result:=G2Var(Random(MaxInt)/MaxInt);
  1: Result:=G2Var(Random(P[0].Int), P[0]);
  2: Result:=G2Var(P[0].Int+Random(P[1].Int-P[0].Int+1), P[0], P[1]);
 end;
end;

function G2Func_RandSeed(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 Result:=nil;
 if G2ParamMaxError(1, P, Self) then Exit;
 case Length(P) of
  0: Result:=G2Var(RandSeed);
  1: RandSeed:=P[0].Int;
 end;
 G2Release(P);
end;

function G2Func_LowerCase(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(AnsiLowerCase(P[0].Str), P[0]);
end;

function G2Func_UpperCase(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(AnsiUpperCase(P[0].Str), P[0]);
end;

function G2Func_Str(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].Str, P[0]);
end;

function G2Func_Bool(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].Bool, P[0]);
end;

function G2Func_Int(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].Int, P[0]);
end;

function G2Func_Float(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 if G2ParamCountError(1, P, Self) then begin Result:=nil; Exit; end;
 Result:=G2Var(P[0].Float, P[0]);
end;

function G2Func_IsSet(const Self: TG2Execute; const P: G2Array): TG2Variant;
var Local, Global, IsSet: Boolean;
begin
 Result:=nil;
 if G2ParamRangeError(1, 2, P, Self) then Exit;
 Local:=True;
 Global:=True;
 case Length(P) of
  2: begin Local:=P[1].Bool; Global:=not Local; end;
 end;
 IsSet:=False;
 if Local then IsSet:=IsSet or (Self.FVars[Self.FCurVars].IndexOf(P[0].Str)<>-1);
 if Global then IsSet:=IsSet or (Self.FVars[0].IndexOf(P[0].Str)<>-1);
 Result:=G2Var(IsSet);
 G2Release(P);
end;

function G2Func_UnSet(const Self: TG2Execute; const P: G2Array): TG2Variant;
var Local, Global, UnSet: Boolean;
    Index: integer;
begin
 Result:=nil;
 if G2ParamRangeError(1, 2, P, Self) then Exit;
 Local:=True;
 Global:=True;
 case Length(P) of
  2: begin Local:=P[1].Bool; Global:=not Local; end;
 end;
 UnSet:=False;
 if Local then begin
  Index:=Self.FVars[Self.FCurVars].IndexOf(P[0].Str);
  if Index<>-1 then begin
   G2ReleaseConst(TG2Variant(Self.FVars[Self.FCurVars].GetItemByIndex(Index)));
   Self.FVars[Self.FCurVars].Delete(Index);
   UnSet:=True;
  end;
 end;
 if Global and (not UnSet) and (Self.FCurVars>0) then begin
  Index:=Self.FVars[0].IndexOf(P[0].Str);
  if Index<>-1 then begin
   G2ReleaseConst(TG2Variant(Self.FVars[0].GetItemByIndex(Index)));
   Self.FVars[0].Delete(Index);
  end;
 end;
 G2Release(P);
end;

function G2Func_Var(const Self: TG2Execute; const P: G2Array): TG2Variant;
var Local, Global: Boolean;
begin
 Result:=nil;
 if G2ParamRangeError(1, 2, P, Self) then Exit;
 Local:=True;
 Global:=True;
 case Length(P) of
  2: begin Local:=P[1].Bool; Global:=not Local; end;
 end;
 if Local then Result:=Self.FVars[Self.FCurVars].GetItemByKey(P[0].Str);
 if Global and (Result=nil) then Result:=Self.FVars[0].GetItemByKey(P[0].Str);
 if Result<>nil then Result:=Result.Reference
  else Result:=TG2VNewVar.Create(Self, P[0].Str, Local);
 G2Release(P);
end;

function G2Func_Create(const Self: TG2Execute; const P: G2Array): TG2Variant;
var ClassType: TPersistentClass;
    Owner: TComponent;
begin
 Result:=nil;
 Owner:=nil;
 if G2ParamRangeError(1, 2, P, Self) then Exit;
 try
  ClassType:=FindClass(P[0].Str);
 except
  on Exception do ClassType:=nil;
 end;
 if ClassType=nil then Self.Error(G2RE_BADCLASS, [P[0].Str])
  else begin
   if Length(P)>1 then if P[1].Obj is TComponent then Owner:=TComponent(P[1].Obj);
   if ClassType.InheritsFrom(TComponent) then Result:=G2Var(TComponentClass(ClassType).Create(Owner))
    else Result:=G2Var(ClassType.Create);
  end;
 G2Release(P);
end;

function G2Func_Free(const Self: TG2Execute; const P: G2Array): TG2Variant;
begin
 Result:=nil;
 if G2ParamCountError(1, P, Self) then Exit;
 if P[0].Obj is TObject then begin
  P[0].Obj.Free;
  P[0].Obj:=nil;
 end;
 G2Release(P);
end;

function G2Func_Use(const Self: TG2Execute; const P: G2Array): TG2Variant;
var Module: TG2ModuleClass;
    I: integer;
    S: string;
begin
 Result:=nil;
 for I:=Low(P) to High(P) do begin
  S:=P[I].Str;
  if Self.FModules.IndexOf(S)<0 then begin
   Module:=G2Modules.GetItemByKey(S);
   if Module<>nil then Self.FModules.Add(Module.Create, S)
   else begin
    Self.Error(G2RE_BADMODULE, [S]);
    Break;
   end;
  end;
 end;
 G2Release(P);
end;

initialization
ZeroMemory(@FuncProcs, SizeOf(FuncProcs));
FuncProcs[gftKeys]:=G2Func_Keys;
FuncProcs[gftKeyCount]:=G2Func_KeyCount;
FuncProcs[gftKey]:=G2Func_Key;
FuncProcs[gftError]:=G2Func_Error;
FuncProcs[gftLoad]:=G2Func_Load;
FuncProcs[gftUnload]:=G2Func_Unload;
FuncProcs[gftPrint]:=G2Func_Print;
FuncProcs[gftEcho]:=G2Func_Print;
FuncProcs[gftRandom]:=G2Func_Random;
FuncProcs[gftRandSeed]:=G2Func_RandSeed;
FuncProcs[gftLowerCase]:=G2Func_LowerCase;
FuncProcs[gftUpperCase]:=G2Func_UpperCase;
FuncProcs[gftLC]:=G2Func_LowerCase;
FuncProcs[gftUC]:=G2Func_UpperCase;
FuncProcs[gftStr]:=G2Func_Str;
FuncProcs[gftBool]:=G2Func_Bool;
FuncProcs[gftInt]:=G2Func_Int;
FuncProcs[gftFloat]:=G2Func_Float;
FuncProcs[gftIsSet]:=G2Func_IsSet;
FuncProcs[gftUnSet]:=G2Func_UnSet;
FuncProcs[gftVar]:=G2Func_Var;
FuncProcs[gftCreate]:=G2Func_Create;
FuncProcs[gftFree]:=G2Func_Free;
FuncProcs[gftUse]:=G2Func_Use;
end.
