{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Map Editor Mode Unit                   *
 *  (C) Aukiogames 2003                    *
(*-----------------------------------------*}

unit TssEditor;

interface

uses
  Windows, TssObjects, TssControls, Direct3D8, D3DX8, TssUtils, Math, DirectInput8, TssAlpha,
  TssShadows, SysUtils, TssParticles, TssWeapons, TssMap, TssTextures, Classes,
  TssCars, G2Script, G2Types, G2Execute;

type
  TTssEditPlayer = class(TTssPlayer)
  private
    FOnEnter: string;
    FNoMove: Boolean;
    procedure SetOnEnter(const Value: string);
  public
    procedure Move(TickCount: Single); override;
  published
    function Rotate(const P: G2Array; const Script: TG2Execute): TG2Variant;
    property OnEnter: string read FOnEnter write SetOnEnter;
    property NoMove: Boolean read FNoMove write FNoMove;
  end;

implementation

uses
  TssEngine;

procedure TTssEditPlayer.Move(TickCount: Single);
var Vector: TD3DXVector3;
    M1, M2: TD3DXMatrix;
begin
 if not NoMove then begin
  Controls.WalkZ:=Ord(Engine.Controls.GameKeyDown(keyWalkForward, 0))-Ord(Engine.Controls.GameKeyDown(keyWalkBackward, 0));
  Controls.WalkX:=Ord(Engine.Controls.GameKeyDown(keyWalkRight, 0))-Ord(Engine.Controls.GameKeyDown(keyWalkLeft, 0));
  Controls.TurnY:=Engine.Controls.MouseMoveX;
  Controls.TurnX:=Engine.Controls.MouseMoveY;

  D3DXVec3TransformCoord(Vector, D3DXVector3(0, 0, Controls.WalkZ*TickCount*0.05), RRot);
  RPos.X:=RPos.X+Vector.X;
  RPos.Y:=RPos.Y+Vector.Y;
  RPos.Z:=RPos.Z+Vector.Z;
  D3DXVec3TransformCoord(Vector, D3DXVector3(Controls.WalkX*TickCount*0.05, 0, 0), RRot);
  RPos.X:=RPos.X+Vector.X;
  RPos.Y:=RPos.Y+Vector.Y;
  RPos.Z:=RPos.Z+Vector.Z;
  D3DXMatrixRotationY(M2, Controls.TurnY*4);
  D3DXMatrixMultiply(M1, RRot, M2);
  D3DXMatrixRotationX(M2, Controls.TurnX*4);
  D3DXMatrixMultiply(RRot, M2, M1);
 end;
 ARot:=RRot;
 APos:=RPos;

 Engine.Camera.Rot:=RRot;
 Engine.Camera.Pos:=RPos;

 if Engine.Controls.DIKKeyDown(DIK_RETURN, -1) then Engine.FScript.RunCommand(FOnEnter);
end;

function TTssEditPlayer.Rotate(const P: G2Array; const Script: TG2Execute): TG2Variant;
var M1, M2: TD3DXMatrix;
begin
 Result:=nil;
 if G2ParamCountError(2, P, Script) then Exit;
 D3DXMatrixRotationY(M2, P[0].Float);
 D3DXMatrixMultiply(M1, RRot, M2);
 D3DXMatrixRotationX(M2, P[1].Float);
 D3DXMatrixMultiply(RRot, M2, M1);
 G2Release(P);
end;

procedure TTssEditPlayer.SetOnEnter(const Value: string);
begin
 FOnEnter:=Value;
end;

initialization
RegisterClass(TTssEditPlayer);
finalization
UnregisterClass(TTssEditPlayer);
end.
