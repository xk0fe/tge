{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Hud Unit                               *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssHud;

interface

uses
  Direct3D8, TssUtils, TssTextures, D3DX8, SysUtils;

type
  TTssHud = class(TObject)
  public
    VB: IDirect3DVertexBuffer8;
    DynVB: IDirect3DVertexBuffer8;
    MatSpeedBg, MatSpeedPnt, MatSpeedShd: TTssMaterial;
    MatMap, MatMapAlpha, MatMapItem: TTssMaterial;
    MatAim: TTssMaterial;
    ItemAlpha: Single;
    HudAlpha: Byte;
    AimVisibility: Single;
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
  end;

implementation

uses
  TssEngine;

constructor TTssHud.Create;
begin
 inherited;
 MatSpeedBg.Name:='SpeedBg';
 MatSpeedPnt.Name:='SpeedPnt';
 MatSpeedShd.Name:='SpeedShd';
 MatMap.Name:='Map_0_0';
 MatMapAlpha.Name:='MapAlpha';
 MatMapItem.Name:='MapItem';
 MatAim.Name:='AimPoint';
end;

destructor TTssHud.Destroy;
begin
 VB:=nil;
 inherited;
end;

procedure TTssHud.Move(TickCount: Single);
begin
 ItemAlpha:=ItemAlpha+TickCount*0.002;
 if ItemAlpha>1 then ItemAlpha:=ItemAlpha-2;
end;

procedure TTssHud.Draw;          
var PVB: P2DVertex;
    MSin, MCos, MX, MY: Single;
    Vertices: array[0..3] of T2DVertex2Tx;
begin
 if VB=nil then begin
  Engine.m_pd3dDevice.CreateVertexBuffer(8*SizeOf(T2DVertex), D3DUSAGE_WRITEONLY, D3DFVF_TSSVERTEX_2D, D3DPOOL_DEFAULT, VB);
  VB.Lock(0, 0, PByte(PVB), 0);
  PVB^:=Make2DVertex(Engine.vp.Width*0.01, Engine.vp.Height*0.71, 0.9, 1.0, 0.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.22, Engine.vp.Height*0.71, 0.9, 1.0, 1.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.01, Engine.vp.Height*0.99, 0.9, 1.0, 0.00, 1.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.22, Engine.vp.Height*0.99, 0.9, 1.0, 1.00, 1.00); Inc(PVB);

  PVB^:=Make2DVertex(Engine.vp.Width*0.49, Engine.vp.Height*0.48667, 0.9, 1.0, 0.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.51, Engine.vp.Height*0.48667, 0.9, 1.0, 1.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.49, Engine.vp.Height*0.51333, 0.9, 1.0, 0.00, 1.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*0.51, Engine.vp.Height*0.51333, 0.9, 1.0, 1.00, 1.00); Inc(PVB);
  VB.Unlock;
 end;
 if DynVB=nil then Engine.m_pd3dDevice.CreateVertexBuffer(8*SizeOf(T2DVertex), D3DUSAGE_DYNAMIC, D3DFVF_TSSVERTEX_2D, D3DPOOL_DEFAULT, DynVB);

 Engine.m_pd3dDevice.SetRenderState(D3DRS_ALPHABLENDENABLE, 1);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(HudAlpha, 0, 0, 0));

 if Engine.Player.Car<>nil then begin
  DynVB.Lock(0, 0, PByte(PVB), D3DLOCK_DISCARD);
  MSin:=Sin(4/3*g_PI-Abs(Engine.Player.Car.CarSpeed)*0.032142857*g_PI);
  MCos:=Cos(4/3*g_PI-Abs(Engine.Player.Car.CarSpeed)*0.032142857*g_PI);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.108+MCos*0.08-MSin*0.01050), Engine.vp.Height*(0.860-MCos*0.014-MSin*0.107), 0.9, 1.0, 0.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.108+MCos*0.08+MSin*0.01050), Engine.vp.Height*(0.860+MCos*0.014-MSin*0.107), 0.9, 1.0, 1.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.108-MSin*0.01050),           Engine.vp.Height*(0.860-MCos*0.014),            0.9, 1.0, 0.00, 0.75); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.108+MSin*0.01050),           Engine.vp.Height*(0.860+MCos*0.014),            0.9, 1.0, 1.00, 0.75); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.115+MCos*0.08-MSin*0.00525), Engine.vp.Height*(0.850-MCos*0.007-MSin*0.107), 0.9, 1.0, 0.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.115+MCos*0.08+MSin*0.00525), Engine.vp.Height*(0.850+MCos*0.007-MSin*0.107), 0.9, 1.0, 1.00, 0.00); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.115-MSin*0.00525),           Engine.vp.Height*(0.850-MCos*0.007),            0.9, 1.0, 0.00, 0.75); Inc(PVB);
  PVB^:=Make2DVertex(Engine.vp.Width*(0.115+MSin*0.00525),           Engine.vp.Height*(0.850+MCos*0.007),            0.9, 1.0, 1.00, 0.75); Inc(PVB);
  DynVB.Unlock;

  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);

  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);

  Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T2DVertex));
  Engine.Textures.SetMaterial(MatSpeedBg, 0);
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
  Engine.IncPolyCounter(2);

  Engine.m_pd3dDevice.SetStreamSource(0, DynVB, SizeOf(T2DVertex));
  Engine.Textures.SetMaterial(MatSpeedShd, 0);
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
  Engine.Textures.SetMaterial(MatSpeedPnt, 0);
  Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 4, 2);
  Engine.IncPolyCounter(4);
 end;

 MX:=GetYAngle(Engine.Camera.Rot);
 MSin:=Sin(MX);
 MCos:=Cos(MX);
 with Vertices[0] do begin
  vV:=D3DXVector4(Engine.vp.Width*0.78, Engine.vp.Height*0.71, 0.9, 1.0);
  tU1:=(-MCos+MSin)/4+Engine.Camera.Pos.X/2048;
  tV1:=(-MSin-MCos)/4-Engine.Camera.Pos.Z/2048;
  tU2:=0.0; tV2:=0.0;
 end;
 with Vertices[1] do begin
  vV:=D3DXVector4(Engine.vp.Width*0.99, Engine.vp.Height*0.71, 0.9, 1.0);
  tU1:=(+MCos+MSin)/4+Engine.Camera.Pos.X/2048;
  tV1:=(+MSin-MCos)/4-Engine.Camera.Pos.Z/2048;
  tU2:=1.0; tV2:=0.0;
 end;
 with Vertices[2] do begin
  vV:=D3DXVector4(Engine.vp.Width*0.78, Engine.vp.Height*0.99, 0.9, 1.0);
  tU1:=(-MCos-MSin)/4+Engine.Camera.Pos.X/2048;
  tV1:=(-MSin+MCos)/4-Engine.Camera.Pos.Z/2048;
  tU2:=0.0; tV2:=1.0;
 end;
 with Vertices[3] do begin
  vV:=D3DXVector4(Engine.vp.Width*0.99, Engine.vp.Height*0.99, 0.9, 1.0);
  tU1:=(+MCos-MSin)/4+Engine.Camera.Pos.X/2048;
  tV1:=(+MSin+MCos)/4-Engine.Camera.Pos.Z/2048;
  tU2:=1.0; tV2:=1.0;
 end;
 Engine.Textures.SetMaterial(MatMap, 0);
 if Options.UseMultiTx then begin
  Engine.Textures.SetMaterial(MatMapAlpha, 1);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_CURRENT);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAARG1, D3DTA_CURRENT);
  Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_ALPHAARG2, D3DTA_TEXTURE);
 end;
 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D2TX);
 Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex2Tx));
 Engine.IncPolyCounter(2);
 if Options.UseMultiTx then Engine.m_pd3dDevice.SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);

 MX:=-MCos*(Engine.Player.APos.X-Engine.Camera.Pos.X)/256+MSin*(Engine.Player.APos.Z-Engine.Camera.Pos.Z)/256;
 MY:=-MSin*(Engine.Player.APos.X-Engine.Camera.Pos.X)/256-MCos*(Engine.Player.APos.Z-Engine.Camera.Pos.Z)/256;
 with Vertices[0] do begin
  vV:=D3DXVector4(Engine.vp.Width*(0.885+0.105*(MX-0.15)), Engine.vp.Height*(0.85+0.14*(MY-0.15)), 0.9, 1.0);
  tU1:=0.0; tV1:=0.0;
 end;                                      
 with Vertices[1] do begin
  vV:=D3DXVector4(Engine.vp.Width*(0.885+0.105*(MX+0.15)), Engine.vp.Height*(0.85+0.14*(MY-0.15)), 0.9, 1.0);
  tU1:=1.0; tV1:=0.0;
 end;
 with Vertices[2] do begin
  vV:=D3DXVector4(Engine.vp.Width*(0.885+0.105*(MX-0.15)), Engine.vp.Height*(0.85+0.14*(MY+0.15)), 0.9, 1.0);
  tU1:=0.0; tV1:=1.0;
 end;
 with Vertices[3] do begin
  vV:=D3DXVector4(Engine.vp.Width*(0.885+0.105*(MX+0.15)), Engine.vp.Height*(0.85+0.14*(MY+0.15)), 0.9, 1.0);
  tU1:=1.0; tV1:=1.0;
 end;
 Engine.Textures.SetMaterial(MatMapItem, 0);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round((Abs(ItemAlpha)*0.75+0.25)*HudAlpha), 0, 0, 0));
 Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex2Tx));
 Engine.IncPolyCounter(2);

 Engine.Textures.SetMaterial(MatAim, 0);
 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
 Engine.m_pd3dDevice.SetStreamSource(0, VB, SizeOf(T2DVertex));
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, (Round(HudAlpha*AimVisibility) shl 24) or Options.AimColor);
 Engine.m_pd3dDevice.DrawPrimitive(D3DPT_TRIANGLESTRIP, 4, 2);
 Engine.IncPolyCounter(2);

 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
end;

end.
