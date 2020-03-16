{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Controls Unit                          *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssControls;

interface

uses Windows, Messages, SysUtils, Classes, D3DApp, IniFiles, DirectInput8, dx8di, TssUtils;

type
  // Game Keys
  TTssKey = (
    keyCarAcc,
    keyCarBrake,
    keyCarSteerLeft,
    keyCarSteerRight,
    keyCarHandBrake,
    keyCarBurnOut,
    keyCarHorn,

    keyWalkForward,
    keyWalkBackward,
    keyWalkLeft,
    keyWalkRight,
    keyWalkJump,

    keyDoorOpen,
    keyLookBack,
    keyChangeCam
  );

const
  // Names for Game Keys
  GameKeyStr: array[Low(TTssKey)..High(TTssKey)] of string = (
    'Accelerate',
    'Brake',
    'Steer Left',
    'Steer Right',
    'Handbrake',
    'Burnout',
    'Horn',

    'Forward',
    'Backward',
    'Strafe Left',
    'Strafe Right',
    'Jump',

    'Enter/Exit',
    'Look Back',
    'Change Camera'
  );

const
  // Default Game Keys
  DefaultGameKeys: array[Low(TTssKey)..High(TTssKey)] of Byte = (
    DIK_UP,
    DIK_DOWN,
    DIK_LEFT,
    DIK_RIGHT,
    DIK_SPACE,
    DIK_LCONTROL,
    DIK_TAB,

    DIK_UP,
    DIK_DOWN,
    DIK_LEFT,
    DIK_RIGHT,
    DIK_RCONTROL,

    DIK_RETURN,
    DIK_B,
    DIK_C
  );

const
  // Names for all DirectInputKeys
  DIKStrings: array[0..255] of string = (
    'Undefined!',       //                     = $00
    'Esc',              // DIK_ESCAPE          = $01;
    '1',                // DIK_1               = $02;
    '2',                // DIK_2               = $03;
    '3',                // DIK_3               = $04;
    '4',                // DIK_4               = $05;
    '5',                // DIK_5               = $06;
    '6',                // DIK_6               = $07;
    '7',                // DIK_7               = $08;
    '8',                // DIK_8               = $09;
    '9',                // DIK_9               = $0A;
    '0',                // DIK_0               = $0B;
    '-',                // DIK_MINUS           = $0C;    (* - on main keyboard *)
    '=',                // DIK_EQUALS          = $0D;
    'Backspace',        // DIK_BACK            = $0E;    (* backspace *)
    'Tab',              // DIK_TAB             = $0F;
    'Q',                // DIK_Q               = $10;
    'W',                // DIK_W               = $11;
    'E',                // DIK_E               = $12;
    'R',                // DIK_R               = $13;
    'T',                // DIK_T               = $14;
    'Y',                // DIK_Y               = $15;
    'U',                // DIK_U               = $16;
    'I',                // DIK_I               = $17;
    'O',                // DIK_O               = $18;
    'P',                // DIK_P               = $19;
    '{',                // DIK_LBRACKET        = $1A;
    '}',                // DIK_RBRACKET        = $1B;
    'Return',           // DIK_RETURN          = $1C;    (* Enter on main keyboard *)
    'Left Control',     // DIK_LCONTROL        = $1D;
    'A',                // DIK_A               = $1E;
    'S',                // DIK_S               = $1F;
    'D',                // DIK_D               = $20;
    'F',                // DIK_F               = $21;
    'G',                // DIK_G               = $22;
    'H',                // DIK_H               = $23;
    'J',                // DIK_J               = $24;
    'K',                // DIK_K               = $25;
    'L',                // DIK_L               = $26;
    ';',                // DIK_SEMICOLON       = $27;
    #39,                // DIK_APOSTROPHE      = $28;
    'Grave',            // DIK_GRAVE           = $29;    (* accent grave *)
    'Left Shift',       // DIK_LSHIFT          = $2A;
    '\',                // DIK_BACKSLASH       = $2B;
    'Z',                // DIK_Z               = $2C;
    'X',                // DIK_X               = $2D;
    'C',                // DIK_C               = $2E;
    'V',                // DIK_V               = $2F;
    'B',                // DIK_B               = $30;
    'N',                // DIK_N               = $31;
    'M',                // DIK_M               = $32;
    ',',                // DIK_COMMA           = $33;
    '.',                // DIK_PERIOD          = $34;    (* . on main keyboard *)
    '/',                // DIK_SLASH           = $35;    (* / on main keyboard *)
    'Right Shift',      // DIK_RSHIFT          = $36;
    '*',                // DIK_MULTIPLY        = $37;    (* * on numeric keypad *)
    'Alt',              // DIK_LMENU           = $38;    (* left Alt *)
    'Space',            // DIK_SPACE           = $39;
    'Caps Lock',        // DIK_CAPITAL         = $3A;
    'F1',               // DIK_F1              = $3B;
    'F2',               // DIK_F2              = $3C;
    'F3',               // DIK_F3              = $3D;
    'F4',               // DIK_F4              = $3E;
    'F5',               // DIK_F5              = $3F;
    'F6',               // DIK_F6              = $40;
    'F7',               // DIK_F7              = $41;
    'F8',               // DIK_F8              = $42;
    'F9',               // DIK_F9              = $43;
    'F10',              // DIK_F10             = $44;
    'Num Lock',         // DIK_NUMLOCK         = $45;
    'Scroll Lock',      // DIK_SCROLL          = $46;    (* Scroll Lock *)
    'Numpad 7',         // DIK_NUMPAD7         = $47;
    'Numpad 8',         // DIK_NUMPAD8         = $48;
    'Numpad 9',         // DIK_NUMPAD9         = $49;
    'Numpad -',         // DIK_SUBTRACT        = $4A;    (* - on numeric keypad *)
    'Numpad 4',         // DIK_NUMPAD4         = $4B;
    'Numpad 5',         // DIK_NUMPAD5         = $4C;
    'Numpad 6',         // DIK_NUMPAD6         = $4D;
    'Numpad +',         // DIK_ADD             = $4E;    (* + on numeric keypad *)
    'Numpad 1',         // DIK_NUMPAD1         = $4F;
    'Numpad 2',         // DIK_NUMPAD2         = $50;
    'Numpad 3',         // DIK_NUMPAD3         = $51;
    'Numpad 0',         // DIK_NUMPAD0         = $52;
    'Numpad .',         // DIK_DECIMAL         = $53;    (* . on numeric keypad *)
    'Undefined!',       //                     = $54
    'Undefined!',       //                     = $55
    'OEM',              // DIK_OEM_102         = $56;    (* <> or \ | on RT 102-key keyboard (Non-U.S.) *)
    'F11',              // DIK_F11             = $57;
    'F12',              // DIK_F12             = $58;
    'Undefined!',       //                     = $59
    'Undefined!',       //                     = $5A
    'Undefined!',       //                     = $5B
    'Undefined!',       //                     = $5C
    'Undefined!',       //                     = $5D
    'Undefined!',       //                     = $5E
    'Undefined!',       //                     = $5F
    'Undefined!',       //                     = $60
    'Undefined!',       //                     = $61
    'Undefined!',       //                     = $62
    'Undefined!',       //                     = $63
    'F13',              // DIK_F13             = $64;    (*                     (NEC PC98) *)
    'F14',              // DIK_F14             = $65;    (*                     (NEC PC98) *)
    'F15',              // DIK_F15             = $66;    (*                     (NEC PC98) *)
    'Undefined!',       //                     = $67
    'Undefined!',       //                     = $68
    'Undefined!',       //                     = $69
    'Undefined!',       //                     = $6A
    'Undefined!',       //                     = $6B
    'Undefined!',       //                     = $6C
    'Undefined!',       //                     = $6D
    'Undefined!',       //                     = $6E
    'Undefined!',       //                     = $6F
    'Kana',             // DIK_KANA            = $70;    (* (Japanese keyboard)            *)
    'Undefined!',       //                     = $71
    'Undefined!',       //                     = $72
    'ABNT_C1',          // DIK_ABNT_C1         = $73;    (* /? on Brazilian keyboard       *)
    'Undefined!',       //                     = $74
    'Undefined!',       //                     = $75
    'Undefined!',       //                     = $76
    'Undefined!',       //                     = $77
    'Undefined!',       //                     = $78
    'Convert',          // DIK_CONVERT         = $79;    (* (Japanese keyboard)            *)
    'Undefined!',       //                     = $7A
    'Noconvert',        // DIK_NOCONVERT       = $7B;    (* (Japanese keyboard)            *)
    'Undefined!',       //                     = $7C
    'Yen',              // DIK_YEN             = $7D;    (* (Japanese keyboard)            *)
    'ABNT_C2',          // DIK_ABNT_C2         = $7E;    (* Numpad . on Brazilian keyboard *)
    'Undefined!',       //                     = $7F
    'Undefined!',       //                     = $80
    'Undefined!',       //                     = $81
    'Undefined!',       //                     = $82
    'Undefined!',       //                     = $83
    'Undefined!',       //                     = $84
    'Undefined!',       //                     = $85
    'Undefined!',       //                     = $86
    'Undefined!',       //                     = $87
    'Undefined!',       //                     = $88
    'Undefined!',       //                     = $89
    'Undefined!',       //                     = $8A
    'Undefined!',       //                     = $8B
    'Undefined!',       //                     = $8C
    'Numpad =',         // DIK_NUMPADEQUALS    = $8D;    (* = on numeric keypad (NEC PC98) *)
    'Undefined!',       //                     = $8E
    'Undefined!',       //                     = $8F
    'Circumflex',       // DIK_CIRCUMFLEX      = $90;    (* (Japanese keyboard)            *)
    '@',                // DIK_AT              = $91;    (*                     (NEC PC98) *)
    ',',                // DIK_COLON           = $92;    (*                     (NEC PC98) *)
    '_',                // DIK_UNDERLINE       = $93;    (*                     (NEC PC98) *)
    'Kanji',            // DIK_KANJI           = $94;    (* (Japanese keyboard)            *)
    'Stop',             // DIK_STOP            = $95;    (*                     (NEC PC98) *)
    'Ax',               // DIK_AX              = $96;    (*                     (Japan AX) *)
    'Unlabeled',        // DIK_UNLABELED       = $97;    (*                        (J3100) *)
    'Undefined!',       //                     = $98
    'Next Track',       // DIK_NEXTTRACK       = $99;    (* Next Track *)
    'Undefined!',       //                     = $9A
    'Undefined!',       //                     = $9B
    'Numpad Enter',     // DIK_NUMPADENTER     = $9C;    (* Enter on numeric keypad *)
    'Right Control',    // DIK_RCONTROL        = $9D;
    'Undefined!',       //                     = $9E
    'Undefined!',       //                     = $9F
    'Mute',             // DIK_MUTE            = $A0;    (* Mute *)
    'Calculator',       // DIK_CALCULATOR      = $A1;    (* Calculator *)
    'Play/Pause',       // DIK_PLAYPAUSE       = $A2;    (* Play / Pause *)
    'Undefined!',       //                     = $A3
    'Media Stop',       // DIK_MEDIASTOP       = $A4;    (* Media Stop *)
    'Undefined!',       //                     = $A5
    'Undefined!',       //                     = $A6
    'Undefined!',       //                     = $A7
    'Undefined!',       //                     = $A8
    'Undefined!',       //                     = $A9
    'Undefined!',       //                     = $AA
    'Undefined!',       //                     = $AB
    'Undefined!',       //                     = $AC
    'Undefined!',       //                     = $AD
    'Less Volume',      // DIK_VOLUMEDOWN      = $AE;    (* Volume - *)
    'Undefined!',       //                     = $AF
    'More Volume',      // DIK_VOLUMEUP        = $B0;    (* Volume + *)
    'Undefined!',       //                     = $B1
    'Web Home',         // DIK_WEBHOME         = $B2;    (* Web home *)
    'Numpad ,',         // DIK_NUMPADCOMMA     = $B3;    (* , on numeric keypad (NEC PC98) *)
    'Undefined!',       //                     = $B4
    'Numpad /',         // DIK_DIVIDE          = $B5;    (* / on numeric keypad *)
    'Undefined!',       //                     = $B6
    'Sys Rq',           // DIK_SYSRQ           = $B7;
    'Alt Gr',           // DIK_RMENU           = $B8;    (* right Alt *)
    'Undefined!',       //                     = $B9
    'Undefined!',       //                     = $BA
    'Undefined!',       //                     = $BB
    'Undefined!',       //                     = $BC
    'Undefined!',       //                     = $BD
    'Undefined!',       //                     = $BE
    'Undefined!',       //                     = $BF
    'Undefined!',       //                     = $C0
    'Undefined!',       //                     = $C1
    'Undefined!',       //                     = $C2
    'Undefined!',       //                     = $C3
    'Undefined!',       //                     = $C4
    'Pause',            // DIK_PAUSE           = $C5;    (* Pause (watch out - not realiable on some kbds) *)
    'Undefined!',       //                     = $C6
    'Home',             // DIK_HOME            = $C7;    (* Home on arrow keypad *)
    'Up',               // DIK_UP              = $C8;    (* UpArrow on arrow keypad *)
    'Page Up',          // DIK_PRIOR           = $C9;    (* PgUp on arrow keypad *)
    'Undefined!',       //                     = $CA
    'Left',             // DIK_LEFT            = $CB;    (* LeftArrow on arrow keypad *)
    'Undefined!',       //                     = $CC
    'Right',            // DIK_RIGHT           = $CD;    (* RightArrow on arrow keypad *)
    'Undefined!',       //                     = $CE
    'End',              // DIK_END             = $CF;    (* End on arrow keypad *)
    'Down',             // DIK_DOWN            = $D0;    (* DownArrow on arrow keypad *)
    'Page Down',        // DIK_NEXT            = $D1;    (* PgDn on arrow keypad *)
    'Insert',           // DIK_INSERT          = $D2;    (* Insert on arrow keypad *)
    'Delete',           // DIK_DELETE          = $D3;    (* Delete on arrow keypad *)
    'Undefined!',       //                     = $D4
    'Undefined!',       //                     = $D5
    'Undefined!',       //                     = $D6
    'Undefined!',       //                     = $D7
    'Undefined!',       //                     = $D8
    'Undefined!',       //                     = $D9
    'Undefined!',       //                     = $DA
    'Left Win',         // DIK_LWIN            = $DB;    (* Left Windows key *)
    'Right Win',        // DIK_RWIN            = $DC;    (* Right Windows key *)
    'App Menu',         // DIK_APPS            = $DD;    (* AppMenu key *)
    'Power',            // DIK_POWER           = $DE;
    'Sleep',            // DIK_SLEEP           = $DF;
    'Undefined!',       //                     = $E0
    'Undefined!',       //                     = $E1
    'Undefined!',       //                     = $E2
    'Wake',             // DIK_WAKE            = $E3;    (* System Wake *)
    'Undefined!',       //                     = $E4
    'Web Search',       // DIK_WEBSEARCH       = $E5;    (* Web Search *)
    'Web Favourites',   // DIK_WEBFAVORITES    = $E6;    (* Web Favorites *)
    'Web Refresh',      // DIK_WEBREFRESH      = $E7;    (* Web Refresh *)
    'Web Stop',         // DIK_WEBSTOP         = $E8;    (* Web Stop *)
    'Web Forward',      // DIK_WEBFORWARD      = $E9;    (* Web Forward *)
    'Web Backward',     // DIK_WEBBACK         = $EA;    (* Web Back *)
    'My Computer',      // DIK_MYCOMPUTER      = $EB;    (* My Computer *)
    'Mail',             // DIK_MAIL            = $EC;    (* Mail *)
    'Media Select',     // DIK_MEDIASELECT     = $ED;    (* Media Select *)
    'Undefined!',       //                     = $EE
    'Undefined!',       //                     = $EF
    'Undefined!',       //                     = $F0
    'Undefined!',       //                     = $F1
    'Undefined!',       //                     = $F2
    'Undefined!',       //                     = $F3
    'Undefined!',       //                     = $F4
    'Undefined!',       //                     = $F5
    'Undefined!',       //                     = $F6
    'Undefined!',       //                     = $F7
    'Undefined!',       //                     = $F8
    'Undefined!',       //                     = $F9
    'Undefined!',       //                     = $FA
    'Undefined!',       //                     = $FB
    'Undefined!',       //                     = $FC
    'Undefined!',       //                     = $FD
    'Undefined!',       //                     = $FE
    'Undefined!'        //                     = $FF
  );

const
  Key_NoWait      =  0.0;
  Key_WaitForever = -1.0;

type
  TTssControls = class(TObject)
  private
    GameKeys: array[Low(TTssKey)..High(TTssKey)] of Byte;
    DIKState: array[0..255] of Single;
    FileName: string;

    _x, _y, _z: LongInt;
    _0u, _0d, _0z, _1u, _1d, _1z: LongInt;
  public
    MouseX, MouseY: Single;
    Enabled: Boolean;

    constructor Create(AFileName: string);
    destructor Destroy; override;

    procedure Move(TickCount: Single);

    function GameKeyDown(Key: TTssKey; Delay: Single): Boolean;
    function DIKKeyDown(Key: Byte; Delay: Single): Boolean;

    function GetGameKey(Key: TTssKey): Byte;
    procedure SetGameKey(Key: TTssKey; Value: Byte);
    procedure ResetGameKeys;

    function MouseMoveX: Single;
    function MouseMoveY: Single;
    function MouseWheelChange: LongInt;
    function MouseLeftClicked: LongInt;
    function MouseRightClicked: LongInt;
  end;

function GetDIK(Text: string): Byte;

implementation

uses
  TssEngine;

function GetDIK(Text: string): Byte;
var I: integer;
begin
 for I:=0 to 255 do
  if DIKStrings[I]=Text then begin
   Result:=I;
   Exit;
  end;
 Result:=0;
end;

constructor TTssControls.Create(AFileName: string);
var Ini: TIniFile;
    Key: TTssKey;
begin
 inherited Create;
 FileName:=AFileName;
 Ini:=TIniFile.Create(FileName);
 for Key:=Low(TTssKey) to High(TTssKey) do
  GameKeys[Key]:=GetDIK(Ini.ReadString('GameKeys', GameKeyStr[Key], DIKStrings[DefaultGameKeys[Key]]));
 Ini.Free;
 Enabled:=True;
end;

destructor TTssControls.Destroy;
var Ini: TIniFile;
    Key: TTssKey;
begin
 Ini:=TIniFile.Create(FileName);
 for Key:=Low(TTssKey) to High(TTssKey) do
  Ini.WriteString('GameKeys', GameKeyStr[Key], DIKStrings[GameKeys[Key]]);
 Ini.Free;     
 DIClose;
 inherited;
end;

procedure TTssControls.Move(TickCount: Single);
var I: integer;
begin
 if DI8=nil then DIInit;
 if DIK8=nil then DIInitKeyboard(Engine.MainWindow.m_hWnd);
 if DIM8=nil then DIInitMouse(Engine.MainWindow.m_hWnd);
 DIGetKeyboardState;        
 DIGetMouseState(_x, _y, _z, _0u, _0d, _0z, _1u, _1d, _1z);
 MouseX:=MouseX+_x/Engine.vp.Width;
 MouseY:=MouseY+_y/Engine.vp.Width;
 if MouseX<0 then MouseX:=0;
 if MouseX>1 then MouseX:=1;
 if MouseY<0 then MouseY:=0;
 if MouseY>Engine.vp.Height/Engine.vp.Width then MouseY:=Engine.vp.Height/Engine.vp.Width;
 for I:=0 to 255 do if DIKState[I]<>0 then begin
  if DIKState[I]>0 then DIKState[I]:=FloatMax(0,DIKState[I]-TickCount);
  if not DIKeyDown(I) then DIKState[I]:=0;
 end;
end;

function TTssControls.GameKeyDown(Key: TTssKey; Delay: Single): Boolean;
begin
 Result:=DIKKeyDown(GameKeys[Key], Delay) and Enabled;
end;

function TTssControls.DIKKeyDown(Key: Byte; Delay: Single): Boolean;
begin
 Result:=False;
 if Enabled then
  if Delay=0 then Result:=DIKeyDown(Key)
   else if DIKState[Key]=0 then begin
    Result:=DIKeyDown(Key);
    if Result then DIKState[Key]:=Delay;
   end;
end;

function TTssControls.GetGameKey(Key: TTssKey): Byte;
begin
 Result:=GameKeys[Key];
end;

procedure TTssControls.SetGameKey(Key: TTssKey; Value: Byte);
begin
 if GameKeys[Key]<>Value then
  GameKeys[Key]:=Value;
end;

procedure TTssControls.ResetGameKeys;
var Key: TTssKey;
begin
 for Key:=Low(TTssKey) to High(TTssKey) do
  GameKeys[Key]:=DefaultGameKeys[Key];
end;

function TTssControls.MouseMoveX: Single;
begin
 Result:=_x/Engine.vp.Width*Ord(Enabled);
end;

function TTssControls.MouseMoveY: Single;
begin
 Result:=_y/Engine.vp.Width*Ord(Enabled);
end;

function TTssControls.MouseWheelChange: LongInt;
begin
 Result:=_z div 120*Ord(Enabled);
end;

function TTssControls.MouseLeftClicked: LongInt;
begin
 Result:=_0d*Ord(Enabled);
end;

function TTssControls.MouseRightClicked: LongInt;
begin
 Result:=_1d*Ord(Enabled);
end;

end.
