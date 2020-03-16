{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  GScript-Module Unit                    *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssScript;

interface

uses
  Windows, G2Types, G2Script, G2Execute, Classes, SysUtils, D3DX8, Direct3D8;

type
  TScriptEvents = (seCarEnter, seCarExit, seEsc);
const
  ScriptEvents: array[TScriptEvents] of string = (
    'carEnter', 'carExit', 'esc'
  );

type
  TTssTimer = class
    Time: Single;
    Action: string;
  end;

type
  TG2Mdl_Tss = class(TG2Module)
  public
    class function AutoLoad: Boolean; override;
  published
    function Restore(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function Replay(const P: G2Array; const Script: TG2Execute): TG2Variant;
    
    function CreateTssObj(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function ARGB(const P: G2Array; const Script: TG2Execute): TG2Variant;

    function GetDate(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function GetTime(const P: G2Array; const Script: TG2Execute): TG2Variant;

    function Quit(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function TimeOut(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function CancelTimeOut(const P: G2Array; const Script: TG2Execute): TG2Variant;
  end;

implementation

uses TssEngine, TssUtils, TssObjects, TssPhysics, TssCars;

function TG2Mdl_Tss.Restore(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamCountError(0, P, Script) then Exit;
 with Engine.Player.TopObj do begin
  RPos:=OrigPos;
  RRot:=Engine.IdentityMatrix;    
  PosMove:=MakeD3DVector(0,0,0);
  RotMove:=MakeD3DVector(0,0,0);
 end;
end;

function TG2Mdl_Tss.Replay(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamCountError(0, P, Script) then Exit;
 Engine.Replay.Replay(Engine.Replay.Recording);
end;

function TG2Mdl_Tss.CreateTssObj(const P: G2Array; const Script: TG2Execute): TG2Variant;
var ObjClass: TTssObjectClass;
    Obj: TTssObject;
begin
 Result:=nil;
 if G2ParamCountError(6, P, Script) then Exit;
 ObjClass:=TTssObjectClass(GetClass(P[0].Str));
 if ObjClass<>nil then if not ObjClass.InheritsFrom(TTssObject) then ObjClass:=nil;
 if ObjClass=nil then begin
  Script.FErrorCode:=1;
  Script.FErrorText:='Unknown class: '+P[0].Str;
 end else begin
  Obj:=ObjClass.Create(nil, True);
  Obj.ScriptCreated:=True;
  Obj.LoadData(P[1].Str);
  Obj.OrigPos:=D3DXVector3(P[2].Float, P[3].Float, P[4].Float);
  if P[5].Bool then Obj.OrigPos.Y:=Physics_GetYPos(Obj.OrigPos.X, Obj.OrigPos.Z, Obj.OrigPos.Y-20, Obj.OrigPos.Y)-Obj.MinPos.Y+Ord(Obj is TTssCar)*0.35;
  Obj.RPos:=Obj.OrigPos;
  Result:=G2Var(Obj);
 end;
 G2Release(P);
end;

function TG2Mdl_Tss.GetDate(const P: G2Array; const Script: TG2Execute): TG2Variant;
var D: TDateTime;
begin
 Result:=nil;
 if G2ParamCountError(3, P, Script) then Exit;
 if TryEncodeDate(P[0].Int, P[1].Int, P[2].Int, D) then Result:=G2Var(D);
 G2Release(P);
end;

function TG2Mdl_Tss.GetTime(const P: G2Array; const Script: TG2Execute): TG2Variant;
var D: TDateTime;
begin
 Result:=nil;
 if G2ParamCountError(4, P, Script) then Exit;
 if TryEncodeTime(P[0].Int, P[1].Int, P[2].Int, P[3].Int, D) then Result:=G2Var(D);
 G2Release(P);
end;

class function TG2Mdl_Tss.AutoLoad: Boolean;
begin
 Result:=True;
end;

function TG2Mdl_Tss.ARGB(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 if G2ParamCountError(4, P, Script) then begin Result:=nil; Exit; end;
 Result:=G2Var(Cardinal(D3DCOLOR_ARGB(P[0].Int, P[1].Int, P[2].Int, P[3].Int))); 
 G2Release(P);
end;

function TG2Mdl_Tss.Quit(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamMaxError(0, P, Script) then Exit;
 PostQuitMessage(0);
end;

function TG2Mdl_Tss.TimeOut(const P: G2Array; const Script: TG2Execute): TG2Variant;
var Timer: TTssTimer;
begin
 if G2ParamCountError(2, P, Script) then begin Result:=nil; Exit; end;
 Timer:=TTssTimer.Create;
 Timer.Time:=P[0].Float;
 Timer.Action:=P[1].Str;
 Engine.FTimers.Add(Timer);
 Result:=G2Var(Timer);
end;

function TG2Mdl_Tss.CancelTimeOut(const P: G2Array; const Script: TG2Execute): TG2Variant;
var I: integer;
begin
 Result:=nil;
 if G2ParamCountError(1, P, Script) then Exit;
 for I:=Engine.FTimers.Count-1 downto 0 do
  if Engine.FTimers[I]=P[0].Obj then begin
   TTssTimer(Engine.FTimers[I]).Free;
   Engine.FTimers.Delete(I);
   Break;
  end;
end;

initialization
G2RegisterModule(TG2Mdl_Tss);
end.
