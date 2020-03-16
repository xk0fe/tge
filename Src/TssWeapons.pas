{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Weapons Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssWeapons;

interface

uses
  Classes, SysUtils, Direct3D8, D3DX8, TssUtils, TssObjects, TssParticles,
  TssLights, Math;

type
  WEAPON_AMMO_TYPES = (
    WAT_BASIC = 0
  );

  TTssBullet = class(TTssObject)
  private
    Effect: TBulletLine;
  public
    StartPos: TD3DXVector3;
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
  end;

  TTssWeapon = class(TTssObject)
  protected
    procedure PointerLoad(const Data: TPointerData); override;
  public
    FirePos1: TD3DXVector3;
    Ammo: Word;
    AmmoType: WEAPON_AMMO_TYPES;
    HoldAnimIndex: Word;
    FireAnimIndex: Word;
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;

    procedure Fire; virtual; abstract;
  end;

  TTssPistol = class(TTssWeapon)
  private
    Effect: TGunFlame;
  public
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Fire; override;
  end;

implementation

uses
  TssEngine, TssPhysics;

constructor TTssWeapon.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
end;

destructor TTssWeapon.Destroy;
begin
 inherited;
end;

procedure TTssWeapon.Move(TickCount: Single);
begin
 inherited;
end;

procedure TTssWeapon.PointerLoad(const Data: TPointerData);
begin
 if Data.Name='Fire#1' then begin
  FirePos1.X:=Data.Matrix._41;
  FirePos1.Y:=Data.Matrix._42;
  FirePos1.Z:=Data.Matrix._43;
 end;
end;

constructor TTssBullet.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 OwnMass:=0.1;
 TotMass:=0.1;
 Range:=0;
 HitStyle:=hsRay;
 Effect:=TBulletLine.Create(Engine.Particles, True);
 Effect.Obj:=Self;
end;

destructor TTssBullet.Destroy;
begin
 Effect.Free;
 inherited;
end;

procedure TTssBullet.Move(TickCount: Single);
begin
 inherited;
 if Stopped then begin Free; Exit; end;
 Effect.Length:=Min(D3DXVec3Length(VectorSubtract(APos, StartPos)), 200);
 if D3DXVec3LengthSq(VectorSubtract(APos, Engine.Camera.Pos))>Sqr(1000) then Free;
end;


constructor TTssPistol.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 AmmoType:=WAT_BASIC;
 Effect:=TGunFlame.Create(Engine.Particles, False);
end;

destructor TTssPistol.Destroy;
begin
 Effect.Free;
 inherited;
end;

procedure TTssPistol.Fire;
begin
 Effect.Enabled:=True;
 Effect.FLifeTime:=0.0;
 Matrix:=ARot;
 Matrix._41:=Matrix._41+APos.X;
 Matrix._42:=Matrix._42+APos.Y;
 Matrix._43:=Matrix._43+APos.Z;
 D3DXVec3TransformCoord(Effect.FFirePos, FirePos1, Matrix);
 Effect.FFireRot:=ARot;
 with TTssBullet.Create(nil, True) do begin
  LoadData('Bullet1.obj');
  StartPos:=Self.APos;
  RPos:=Self.APos;
  RRot:=Self.ARot;
  D3DXVec3TransformCoord(PosMove, D3DXVector3(1000.0, 0.0, 0.0), RRot);
 end;
end;

end.
 