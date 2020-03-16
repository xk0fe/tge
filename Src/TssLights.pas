{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Light Unit                             *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssLights;

interface

uses
  Windows, Direct3D8, D3DX8, Classes, TssUtils, TssTextures, Math, SysUtils;

const
  Lights_Max = 5;

type
  TLight = class(TPersistent)
  private
    FLightType: D3DLIGHTTYPE;
    FEnabled, FCurEnab: Boolean;
    FPos: TD3DXVector3;
    FDir: TD3DXVector3;
    FColor: DWord;
    FRange: Single;
    FDistanceSq: Single;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property LightType: D3DLIGHTTYPE read FLightType write FLightType;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Pos: TD3DXVector3 read FPos write FPos;
    property Dir: TD3DXVector3 read FDir write FDir;
    property Color: DWord read FColor write FColor;
    property Range: Single read FRange write FRange;
  end;

  TLightSystem = class(TList)
  private
    FEnab: TList;
    FHigh: integer;
    function GetLight(Index: integer): TLight;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw;
    property Light[Index: integer]: TLight read GetLight;
    procedure EnableLights(const MinPos, MaxPos: TD3DXVector3);
    procedure DisableLights;
  end;

implementation

uses
  TssEngine;

constructor TLightSystem.Create;
begin
 inherited;
 FEnab:=TList.Create;
end;

destructor TLightSystem.Destroy;
var I: integer;
begin
 for I:=Count-1 downto 0 do
  Light[I].Free;
 FEnab.Free;
 inherited;
end;

procedure TLightSystem.DisableLights;
var I: integer;
begin
 for I:=0 to Min(Lights_Max, Count)-1 do
  with Light[I] do if FCurEnab then 
   FCurEnab:=False;
 for I:=0 to Engine.Lights.FHigh-1 do
  Engine.m_pd3dDevice.LightEnable(I+1, False);
 Engine.Lights.FHigh:=0;
end;

procedure TLightSystem.Draw;
var D3DLight: TD3DLight8;
    I: integer;
begin
 for I:=0 to Count-1 do
  with Light[I] do begin
   if Enabled then begin
    Engine.m_pd3dDevice.GetLight(I+1, D3DLight);
    D3DLight._Type:=LightType;
    D3DLight.Diffuse.A:=(Color shr 24)/255;
    D3DLight.Diffuse.R:=(Color shr 16 and $FF)/255;
    D3DLight.Diffuse.G:=(Color shr 8 and $FF)/255;
    D3DLight.Diffuse.B:=(Color and $FF)/255;
    D3DLight.Specular.R:=0;
    D3DLight.Specular.G:=0;
    D3DLight.Specular.B:=0;
    D3DLight.Specular.A:=0;
    D3DLight.Ambient:=D3DLight.Specular;
    D3DLight.Position:=Pos;
    D3DLight.Direction:=Dir;
    D3DLight.Range:=Range;
    D3DLight.Attenuation0:=1.0;
    D3DLight.Attenuation1:=-0.04;
    D3DLight.Attenuation2:=0.002;
    D3DLight.Falloff:=15.0;
    D3DLight.Theta:=0.0;
    D3DLight.Phi:=g_PI;
    Engine.m_pd3dDevice.SetLight(I+1, D3DLight);
   end else FCurEnab:=False;
   Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
  end;    
end;

function LightDistanceSort(Item1, Item2: Pointer): integer;
begin
 if TLight(Item1).FDistanceSq<TLight(Item2).FDistanceSq then Result:=-1
  else if TLight(Item1).FDistanceSq>TLight(Item2).FDistanceSq then Result:=1
   else Result:=0;
end;

procedure TLightSystem.EnableLights(const MinPos, MaxPos: TD3DXVector3);
var I{, EnableCount}: integer;
    MinP, MaxP: TD3DXVector3;
    NowEnable: Boolean;
begin
 //EnableCount:=0;
 FEnab.Clear;
 for I:=0 to Count-1 do
  with Light[I] do begin
   if Enabled then begin
    if LightType=D3DLIGHT_SPOT then begin
     MinP.X:=(Pos.X+Dir.X*Range*0.5)-Range*0.5;
     MinP.Y:=(Pos.Y+Dir.Y*Range*0.5)-Range*0.5;
     MinP.Z:=(Pos.Z+Dir.Z*Range*0.5)-Range*0.5;
     MaxP.X:=(Pos.X+Dir.X*Range*0.5)+Range*0.5;
     MaxP.Y:=(Pos.Y+Dir.Y*Range*0.5)+Range*0.5;
     MaxP.Z:=(Pos.Z+Dir.Z*Range*0.5)+Range*0.5;
    end else begin
     MinP:=D3DXVector3(Pos.X-Range, Pos.Y-Range, Pos.Z-Range);
     MaxP:=D3DXVector3(Pos.X+Range, Pos.Y+Range, Pos.Z+Range);
    end;
    NowEnable:=(MaxP.X>MinPos.X) and (MinP.X<MaxPos.X) and (MaxP.Y>MinPos.Y) and (MinP.Y<MaxPos.Y) and (MaxP.Z>MinPos.Z) and (MinP.Z<MaxPos.Z);
    if NowEnable then begin
     if LightType=D3DLIGHT_SPOT then FDistanceSq:=D3DXVec3LengthSq(D3DXVector3(Pos.X+Dir.X*Range*0.25-(MinPos.X+MaxPos.X)*0.5, Pos.Y+Dir.Y*Range*0.25-(MinPos.Y+MaxPos.Y)*0.5, Pos.Z+Dir.Z*Range*0.25-(MinPos.Z+MaxPos.Z)*0.5))
      else FDistanceSq:=D3DXVec3LengthSq(D3DXVector3(Pos.X-(MinPos.X+MaxPos.X)*0.5, Pos.Y-(MinPos.Y+MaxPos.Y)*0.5, Pos.Z-(MinPos.Z+MaxPos.Z)*0.5));
     FEnab.Add(Light[I]);
    end;
    if NowEnable xor FCurEnab then begin
     FCurEnab:=NowEnable;
     Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
    end
   end else if FCurEnab then begin
    FCurEnab:=False;
    Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
   end;
  end;
 FEnab.Sort(LightDistanceSort);
 for I:=0 to Min(Lights_Max, FEnab.Count)-1 do with TLight(FEnab[I]) do
  if not FCurEnab then begin
   FCurEnab:=True;
   Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
  end;
 for I:=Lights_Max to FEnab.Count-1 do with TLight(FEnab[I]) do
  if FCurEnab then begin
   FCurEnab:=False;
   Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
  end;
    {if NowEnable then Inc(EnableCount);}
   {end else NowEnable:=False;
   if NowEnable xor FCurEnab then begin
    FCurEnab:=NowEnable;
    Engine.m_pd3dDevice.LightEnable(I+1, FCurEnab);
   end;
  end;}
 Engine.Lights.FHigh:=Max(Engine.Lights.FHigh, Engine.Lights.Count); 
end;

function TLightSystem.GetLight(Index: integer): TLight;
begin
 Result:=TLight(Items[Index]);
end;

{ TLight }

constructor TLight.Create;
begin
 Engine.Lights.Add(Self);
 Engine.Lights.FHigh:=Max(Engine.Lights.FHigh, Engine.Lights.Count);
end;

destructor TLight.Destroy;
begin
 Engine.Lights.Remove(Self);
 inherited;
end;

end.
 