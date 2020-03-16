unit TssMenus;

interface

uses
  Classes, Windows, Direct3D8, DirectInput8, D3DX8, TssUtils, SysUtils, Math, TssCredits,
  TssTextures, G2Script, G2Types, G2Execute;

type
  TWindowColor = record
    case Integer of
      0: (Normal: Cardinal; Hot: Cardinal);
      1: (Values: array[Boolean] of Cardinal);    
  end;
  TWindowFloat = record
    case Integer of
      0: (Normal: Single; Hot: Single);
      1: (Values: array[Boolean] of Single);    
  end;

  TTssWindow = class(TComponent)
  private
    FLeft: Single;
    FVisible: Single;
    FEnabled: Boolean;
    FBottom: Single;
    FTop: Single;
    FRight: Single;
    FFadeTo: Single;
    FFadeSpeed: Single;
    FColor: TWindowColor;
    FBackGround: TWindowColor;
    FMaterial: TTssMaterial;
    FBorderColor: TWindowColor;
    FBorderWidth: TWindowFloat;
    FHot: Boolean;
    FHotTracked: Boolean;
    FOnAction: string;
    function GetHeight: Single;
    function GetWidth: Single;
    procedure SetHeight(const Value: Single);
    procedure SetWidth(const Value: Single);
    procedure SetLeft(const Value: Single);
    procedure SetTop(const Value: Single);
    function GetParent: TTssWindow;
    procedure SetVisible(const Value: Single);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure Draw;
    procedure DoMove(TickCount: Single); virtual;
    procedure DoDraw; virtual;
    function ClientToScreenX(const Value: Single): Single;
    function ClientToScreenY(const Value: Single): Single;
    function ScreenToClientX(const Value: Single): Single;
    function ScreenToClientY(const Value: Single): Single;
    function Visibility: Single;
  published
    property Left: Single read FLeft write SetLeft;
    property Top: Single read FTop write SetTop;
    property Right: Single read FRight write FRight;
    property Bottom: Single read FBottom write FBottom;
    property Width: Single read GetWidth write SetWidth;
    property Height: Single read GetHeight write SetHeight;
    property Visible: Single read FVisible write SetVisible;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Image: TTextureString read FMaterial.Name write FMaterial.Name;
    property HotTracked: Boolean read FHotTracked write FHotTracked;
    property Parent: TTssWindow read GetParent;
    property Color: Cardinal read FColor.Normal write FColor.Normal;
    property BackGround: Cardinal read FBackGround.Normal write FBackGround.Normal;
    property BorderColor: Cardinal read FBorderColor.Normal write FBorderColor.Normal;
    property BorderWidth: Single read FBorderWidth.Normal write FBorderWidth.Normal;
    property HotColor: Cardinal read FColor.Hot write FColor.Hot;
    property HotBackGround: Cardinal read FBackGround.Hot write FBackGround.Hot;
    property HotBorderColor: Cardinal read FBorderColor.Hot write FBorderColor.Hot;
    property HotBorderWidth: Single read FBorderWidth.Hot write FBorderWidth.Hot;
    property OnAction: string read FOnAction write FOnAction;
    function ToFront(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function ToBack(const P: G2Array; const Script: TG2Execute): TG2Variant;
    function FadeTo(const P: G2Array; const Script: TG2Execute): TG2Variant;
  end;

  TTextWindow = class(TTssWindow)
  private
    FText: string;
    FFont: integer;
    FFontSize: Single;
    FAspectRatio: Single;
    FShadowColor: TWindowColor;
    FShadowY: Single;
    FShadowX: Single;
    FAlign: integer;
    FLineSpace: Single;
    FCharSpace: Single;
    FShadowSize: Single;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoDraw; override;
  published
    property Text: string read FText write FText;
    property Font: integer read FFont write FFont;
    property FontSize: Single read FFontSize write FFontSize;
    property AspectRatio: Single read FAspectRatio write FAspectRatio;
    property LineSpace: Single read FLineSpace write FLineSpace;
    property CharSpace: Single read FCharSpace write FCharSpace;
    property ShadowSize: Single read FShadowSize write FShadowSize;
    property ShadowX: Single read FShadowX write FShadowX;
    property ShadowY: Single read FShadowY write FShadowY;
    property Align: integer read FAlign write FAlign;
    property ShadowColor: Cardinal read FShadowColor.Normal write FShadowColor.Normal;
    property HotShadowColor: Cardinal read FShadowColor.Hot write FShadowColor.Hot;
  end;

  TMouseWindow = class(TTssWindow)
  public
    procedure DoMove(TickCount: Single); override;
  end;

  TMeterWindow = class(TTssWindow)
  private
    FValueAddress: Cardinal;
    FStartPos: Single;
    FMultiplier: Single;
    FPointerMat: TTssMaterial;
  public
    procedure DoMove(TickCount: Single); override;
    procedure DoDraw; override;
  published
    property StartPos: Single read FStartPos write FStartPos;
    property Multiplier: Single read FMultiplier write FMultiplier;
    property ValueAddress: Cardinal read FValueAddress write FValueAddress;
    property PointerImage: TTextureString read FPointerMat.Name write FPointerMat.Name;
  end;

implementation

uses
  TssEngine;

function AlphaModulate(const Color: Cardinal; const Alpha: Single): Cardinal;
begin
 Result:=(Color and $FFFFFF) or (Round((Color shr 24)*Alpha) shl 24);
end;

{ TTssWindow }

constructor TTssWindow.Create(AOwner: TComponent);
begin
 if AOwner=nil then AOwner:=Engine.MainWnd;
 inherited Create(AOwner);
 FVisible:=1.0;
 FEnabled:=True;
 FBorderColor.Normal:=D3DCOLOR_ARGB(255, 0, 0, 0);
 FBorderColor.Hot:=D3DCOLOR_ARGB(255, 0, 0, 0);
end;

procedure TTssWindow.Move(TickCount: Single);
var I: integer;
begin
 if FFadeTo<>FVisible then begin
  if FFadeTo>FVisible then FVisible:=Min(FVisible+FFadeSpeed*TickCount*0.001, FFadeTo);
  if FFadeTo<FVisible then FVisible:=Max(FVisible-FFadeSpeed*TickCount*0.001, FFadeTo);
 end;
 if (not FEnabled) or (FVisible=0.0) then Exit;
 DoMove(TickCount);
 if FHotTracked then FHot:=(Engine.Controls.MouseY>=ClientToScreenY(0)) and (Engine.Controls.MouseX>=ClientToScreenX(0)) and (Engine.Controls.MouseY<ClientToScreenY(Height)) and (Engine.Controls.MouseX<ClientToScreenX(Width))
  else FHot:=False;
 for I:=0 to ComponentCount-1 do
  TTssWindow(Components[I]).Move(TickCount);
 if FHot then
  if Engine.Controls.MouseLeftClicked>0 then
   if FOnAction<>'' then Engine.Script.RunCommand(FOnAction);
end;

procedure DrawRect(const Left, Top, Right, Bottom: Single);
var Vertices: array[0..3] of T2DVertex;
begin
 Vertices[0]:=Make2DVertex(Engine.vp.Width*Left, Engine.vp.Width*Top, 0.0, 0.0, 0.0, 0.0);
 Vertices[1]:=Make2DVertex(Engine.vp.Width*Right, Engine.vp.Width*Top, 0.0, 0.0, 1.0, 0.0);
 Vertices[2]:=Make2DVertex(Engine.vp.Width*Left, Engine.vp.Width*Bottom, 0.0, 0.0, 0.0, 1.0);
 Vertices[3]:=Make2DVertex(Engine.vp.Width*Right, Engine.vp.Width*Bottom, 0.0, 0.0, 1.0, 1.0);
 Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
 Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex));
 Engine.IncPolyCounter(2);
end;

procedure TTssWindow.Draw;
var I: integer;
    SLeft, STop, SRight, SBottom: Single;
begin
 if FVisible=0.0 then Exit;
 if (FMaterial.Name<>'') or (FBackGround.Values[FHot]<>0) then Engine.Textures.SetMaterial(FMaterial, 0);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TFACTOR);
 SLeft:=ClientToScreenX(0);
 STop:=ClientToScreenY(0);
 SRight:=ClientToScreenX(Width);
 SBottom:=ClientToScreenY(Height);
 if FMaterial.Name<>'' then begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  if FBackGround.Values[FHot]<>0 then Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, AlphaModulate(FBackGround.Values[FHot], Visibility))
   else Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round(Visibility*255), 0, 0, 0));
  DrawRect(SLeft, STop, SRight, SBottom);
 end else if FBackGround.Values[FHot]<>0 then begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2);   
  engine.Console.Add(inttostr(integer(self))+', '+floattostr(Visibility)+', '+floattostr(fvisible)); 
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, AlphaModulate(FBackGround.Values[FHot], Visibility));
  DrawRect(SLeft, STop, SRight, SBottom);
 end;
 if FBorderWidth.Values[FHot]>0 then begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, AlphaModulate(FBorderColor.Values[FHot], Visibility));
  DrawRect(SLeft-FBorderWidth.Values[FHot], STop-FBorderWidth.Values[FHot], SLeft, SBottom);
  DrawRect(SLeft, STop-FBorderWidth.Values[FHot], SRight+FBorderWidth.Values[FHot], STop);
  DrawRect(SRight, STop, SRight+FBorderWidth.Values[FHot], SBottom+FBorderWidth.Values[FHot]);
  DrawRect(SLeft-FBorderWidth.Values[FHot], SBottom, SRight, SBottom+FBorderWidth.Values[FHot]);
 end;
 Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
 if FColor.Values[FHot]<>0 then begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG2);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, AlphaModulate(FColor.Values[FHot], Visibility));
 end else begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(Round(Visibility*255), 0, 0, 0));
 end;
 DoDraw;
 for I:=0 to ComponentCount-1 do
  with TTssWindow(Components[I]) do if Visible>0.0 then Draw;
end;

procedure TTssWindow.DoDraw;
begin
end;

destructor TTssWindow.Destroy;
begin
 inherited;
end;

function TTssWindow.GetHeight: Single;
begin
 Result:=FBottom-FTop;
end;

function TTssWindow.GetWidth: Single;
begin
 Result:=FRight-FLeft;
end;

procedure TTssWindow.SetHeight(const Value: Single);
begin
 FBottom:=FTop+Value;
end;

procedure TTssWindow.SetWidth(const Value: Single);
begin
 FRight:=FLeft+Value;
end;

function TTssWindow.ToBack(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamMaxError(0, P, Script) then Exit;
 if Owner<>nil then ComponentIndex:=0;
end;

function TTssWindow.ToFront(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamMaxError(0, P, Script) then Exit;
 if Owner<>nil then ComponentIndex:=Owner.ComponentCount-1;
end;

function TTssWindow.ClientToScreenX(const Value: Single): Single;
begin
 if Owner=nil then Result:=Left+Value
  else Result:=TTssWindow(Owner).ClientToScreenX(Left+Value);
end;

function TTssWindow.ClientToScreenY(const Value: Single): Single;
begin
 if Owner=nil then Result:=Top+Value
  else Result:=TTssWindow(Owner).ClientToScreenY(Top+Value);
end;

function TTssWindow.ScreenToClientX(const Value: Single): Single;
begin
 if Owner=nil then Result:=Value-Left
  else Result:=TTssWindow(Owner).ScreenToClientX(Value)-Left;
end;

function TTssWindow.ScreenToClientY(const Value: Single): Single;
begin
 if Owner=nil then Result:=Value-Top
  else Result:=TTssWindow(Owner).ScreenToClientY(Value)-Top;
end;

procedure TTssWindow.SetLeft(const Value: Single);
begin
 FRight:=Value+Width;
 FLeft:=Value;
end;

procedure TTssWindow.SetTop(const Value: Single);
begin
 FBottom:=Value+Height;
 FTop:=Value;
end;

function TTssWindow.FadeTo(const P: G2Array; const Script: TG2Execute): TG2Variant;
begin
 Result:=nil;
 if G2ParamRangeError(0, 2, P, Script) then Exit;
 if Length(P)>0 then FFadeTo:=P[0].Float
 else if FVisible<0.5 then FFadeTo:=1.0 else FFadeTo:=0.0;
 if Length(P)>1 then FFadeSpeed:=P[1].Float
 else FFadeSpeed:=5.0;
 G2Release(P);
end;

function TTssWindow.Visibility: Single;
begin
 if Owner=nil then Result:=FVisible
  else Result:=TTssWindow(Owner).Visibility*FVisible;     
end;

function TTssWindow.GetParent: TTssWindow;
begin
 Result:=TTssWindow(Owner);
end;

procedure TTssWindow.DoMove(TickCount: Single);
begin
end;

procedure TTssWindow.SetVisible(const Value: Single);
begin
 FVisible:=Value;
 FFadeSpeed:=0.0;
end;

{ TTextWindow }

constructor TTextWindow.Create(AOwner: TComponent);
begin
 inherited;
 FFontSize:=0.03;
 FAspectRatio:=1.0;
 FShadowX:=0.003;
 FShadowY:=0.003;
end;

procedure TTextWindow.DoDraw;
var X, Y: Single;
begin
 if FText<>'' then begin
  Y:=ClientToScreenY((Height-Engine.Textures.TextHeight(FFont, FFontSize, FLineSpace, FText))*0.5);
  case FAlign of
   -1: X:=ClientToScreenX(0);
   1: X:=ClientToScreenX(Width-Engine.Textures.TextWidth(FFont, FAspectRatio*FFontSize, FCharSpace, FText));
   else X:=ClientToScreenX((Width-Engine.Textures.TextWidth(FFont, FAspectRatio*FFontSize, FCharSpace, FText))*0.5);
  end;
  if FShadowColor.Values[FHot]<>0 then begin
   if Color<>0 then Engine.Textures.DrawText2DShadow(FFont, X, Y, FAspectRatio*FFontSize, FFontSize, FLineSpace, FCharSpace, FShadowSize, FShadowX, FShadowY, AlphaModulate(FShadowColor.Values[FHot], Visibility), AlphaModulate(FColor.Values[FHot], Visibility), FText)
    else Engine.Textures.DrawText2DShadow(FFont, X, Y, FAspectRatio*FFontSize, FFontSize, FLineSpace, FCharSpace, FShadowSize, FShadowX, FShadowY, AlphaModulate(FShadowColor.Values[FHot], Visibility), D3DCOLOR_ARGB(Round(Visibility*255), 0, 0, 0), FText);
  end else begin
   Engine.Textures.DrawText2D(FFont, X, Y, FAspectRatio*FFontSize, FFontSize, FLineSpace, FCharSpace, FText);
  end;
 end;
 inherited;
end;

{ TMouseWindow }

procedure TMouseWindow.DoMove(TickCount: Single);
begin
 Left:=ScreenToClientX(Engine.Controls.MouseX+FLeft);
 Top:=ScreenToClientY(Engine.Controls.MouseY+FTop);
 inherited;
end;

{ TMeterWindow }

procedure TMeterWindow.DoDraw;
var Vertices: array[0..3] of T2DVertex;
    MSin, MCos: Single;
    X, Y, Length: Single;
begin
 if FValueAddress<>0 then begin
  Engine.Textures.SetMaterial(FPointerMat, 0);

  X:=ClientToScreenX(Width*0.5);
  Y:=ClientToScreenY(Height*0.5);
  Length:=Width*0.4;

  MSin:=Sin((FStartPos-Abs(PSingle(FValueAddress)^)*FMultiplier)*2*g_PI);
  MCos:=Cos((FStartPos-Abs(PSingle(FValueAddress)^)*FMultiplier)*2*g_PI);
  Vertices[0]:=Make2DVertex(Engine.vp.Width*(X+MCos*Length-MSin*Length*0.1), Engine.vp.Width*(Y-MCos*Length*0.1-MSin*Length), 0.9, 1.0, 0.00, 0.00);
  Vertices[1]:=Make2DVertex(Engine.vp.Width*(X+MCos*Length+MSin*Length*0.1), Engine.vp.Width*(Y+MCos*Length*0.1-MSin*Length), 0.9, 1.0, 1.00, 0.00);
  Vertices[2]:=Make2DVertex(Engine.vp.Width*(X-MSin*Length*0.1),             Engine.vp.Width*(Y-MCos*Length*0.1),             0.9, 1.0, 0.00, 0.75);
  Vertices[3]:=Make2DVertex(Engine.vp.Width*(X+MSin*Length*0.1),             Engine.vp.Width*(Y+MCos*Length*0.1),             0.9, 1.0, 1.00, 0.75);

  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);

  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
  Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex));
  Engine.IncPolyCounter(2);
 end;
 inherited;
end;

procedure TMeterWindow.DoMove(TickCount: Single);
begin
 inherited;
end;

initialization
RegisterClasses([TTssWindow, TTextWindow, TMouseWindow, TMeterWindow]);
end.
