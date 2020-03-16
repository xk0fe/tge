(*)
 [------------------------------------------------------------------------------
 [  DirectSound 8.1 Additions by Tim Baumgarten
 [  DirectSound 8.0 Delphi Adaptation by Ivo Steinmann
 [  DirectSound 7.0 Delphi Adaptation by Erik Unger
 [------------------------------------------------------------------------------
 [  Files    : dpaddr.h
 [             DPlay8.h
 [             dplobby8.h
 [             dvoice.h
 [  Modified : 11-Sep-2002
 [  E-Mail   : isteinmann@bluewin.ch
 [  Download : http://www.crazyentertainment.net
 [------------------------------------------------------------------------------
(*)

(*)
 [------------------------------------------------------------------------------
 [ History :
 [----------
 [ 11-Sep-2002 (Tim Baumgarten) : Bugfix to TDPNMsgConnectComplete
 [                                Removed use of DXCommon
 [                                Cosmetic changes
 [ 13-Mar-2002 (Tim Baumgarten) : Little changes for DX8.1
 [------------------------------------------------------------------------------
(*)

unit DirectPlay8;

{$MINENUMSIZE 4}
{$ALIGN ON}

//Remove dot to revert to dx8
{.$DEFINE DX8}

{$IFDEF VER150}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CAST OFF}
{$ENDIF}

interface

uses
  Windows,
  WinSock,
  DirectSound;

{$IFDEF DX8}
var
  DPlayDLL      : HMODULE = 0;
  DPlayDLLAddr  : HMODULE = 0;
  DPlayDLLLobby : HMODULE = 0;
  DPlayDLLVoice : HMODULE = 0;
{$ENDIF}

(****************************************************************************
 *
 * DirectPlay8 Datatypes (Non-Structure / Non-Message)
 *
 ****************************************************************************)

type
//
// Player IDs.  Used to uniquely identify a player in a session
//
  PDPNID = ^TDPNID;
  TDPNID = LongWord;

//
// Used as identifiers for operations
//

  PDPNHandle = ^TDPNHandle;
  TDPNHandle = LongWord;

(****************************************************************************
 *
 * DirectPlay8 Callback Functions
 *
 ****************************************************************************)

type
  TDPNMessageHandler = function (pvUserContext : Pointer; dwMessageType : LongWord; pMessage : Pointer) : HResult; stdcall;


(*==========================================================================;
 *
 *  Copyright (C) 2000 Microsoft Corporation.  All Rights Reserved.
 *
 *  File:       dpaddr.h
 *  Content:   DirectPlayAddress include file
 ***************************************************************************)


(****************************************************************************
 *
 * DirectPlay8Address Constants
 *
 ****************************************************************************)

const
  DPNA_DATATYPE_STRING      = $00000001;
  DPNA_DATATYPE_DWORD       = $00000002;
  DPNA_DATATYPE_GUID        = $00000003;
  DPNA_DATATYPE_BINARY      = $00000004;
  DPNA_DATATYPE_STRING_ANSI = $00000005;

  DPNA_DPNSVR_PORT          = 6073;

  DPNA_INDEX_INVALID        = $FFFFFFFF;

(****************************************************************************
 *
 * DirectPlay8Address Address Elements
 *
 ****************************************************************************)

//// UNICODE DEFINITIONS

  DPNA_SEPARATOR_KEYVALUE       = '=';
  DPNA_SEPARATOR_USERDATA       = '#';
  DPNA_SEPARATOR_COMPONENT      = ';';
  DPNA_ESCAPECHAR               = '%';

// Header
  DPNA_HEADER                   = 'x-directplay:/';

// key names for address components
  DPNA_KEY_APPLICATION_INSTANCE = 'applicationinstance';
  DPNA_KEY_BAUD                 = 'baud';
  DPNA_KEY_DEVICE               = 'device';
  DPNA_KEY_FLOWCONTROL          = 'flowcontrol';
  DPNA_KEY_HOSTNAME             = 'hostname';
  DPNA_KEY_PARITY               = 'parity';
  DPNA_KEY_PHONENUMBER          = 'phonenumber';
  DPNA_KEY_PORT                 = 'port';
  DPNA_KEY_PROGRAM              = 'program';
  DPNA_KEY_PROVIDER             = 'provider';
  DPNA_KEY_STOPBITS             = 'stopbits';

// values for baud rate
  DPNA_BAUD_RATE_9600           = 9600;
  DPNA_BAUD_RATE_14400          = 14400;
  DPNA_BAUD_RATE_19200          = 19200;
  DPNA_BAUD_RATE_38400          = 38400;
  DPNA_BAUD_RATE_56000          = 56000;
  DPNA_BAUD_RATE_57600          = 57600;
  DPNA_BAUD_RATE_115200         = 115200;

// values for stop bits
  DPNA_STOP_BITS_ONE            = '1';
  DPNA_STOP_BITS_ONE_FIVE       = '1.5';
  DPNA_STOP_BITS_TWO            = '2';

// values for parity
  DPNA_PARITY_NONE              = 'NONE';
  DPNA_PARITY_EVEN              = 'EVEN';
  DPNA_PARITY_ODD               = 'ODD';
  DPNA_PARITY_MARK              = 'MARK';
  DPNA_PARITY_SPACE             = 'SPACE';

// values for flow control
  DPNA_FLOW_CONTROL_NONE        = 'NONE';
  DPNA_FLOW_CONTROL_XONXOFF     = 'XONXOFF';
  DPNA_FLOW_CONTROL_RTS         = 'RTS';
  DPNA_FLOW_CONTROL_DTR         = 'DTR';
  DPNA_FLOW_CONTROL_RTSDTR      = 'RTSDTR';

// Shortcut values
//
// These can be used instead of the corresponding CLSID_DP8SP_XXXX guids
//
  DPNA_VALUE_TCPIPPROVIDER      = 'IP';
  DPNA_VALUE_IPXPROVIDER        = 'IPX';
  DPNA_VALUE_MODEMPROVIDER      = 'MODEM';
  DPNA_VALUE_SERIALPROVIDER     = 'SERIAL';


//// ANSI DEFINITIONS

// Header
  DPNA_HEADER_A                   = 'x-directplay:/';
  DPNA_SEPARATOR_KEYVALUE_A       = '=';
  DPNA_SEPARATOR_USERDATA_A       = '#';
  DPNA_SEPARATOR_COMPONENT_A      = ';';
  DPNA_ESCAPECHAR_A	              = '%';

// key names for address components
  DPNA_KEY_APPLICATION_INSTANCE_A = 'applicationinstance';
  DPNA_KEY_BAUD_A                 = 'baud';
  DPNA_KEY_DEVICE_A               = 'device';
  DPNA_KEY_FLOWCONTROL_A          = 'flowcontrol';
  DPNA_KEY_HOSTNAME_A             = 'hostname';
  DPNA_KEY_PARITY_A               = 'parity';
  DPNA_KEY_PHONENUMBER_A          = 'phonenumber';
  DPNA_KEY_PORT_A                 = 'port';
  DPNA_KEY_PROGRAM_A              = 'program';
  DPNA_KEY_PROVIDER_A             = 'provider';
  DPNA_KEY_STOPBITS_A             = 'stopbits';

// values for stop bits
  DPNA_STOP_BITS_ONE_A            = '1';
  DPNA_STOP_BITS_ONE_FIVE_A       = '1.5';
  DPNA_STOP_BITS_TWO_A            = '2';

// values for parity
  DPNA_PARITY_NONE_A              = 'NONE';
  DPNA_PARITY_EVEN_A              = 'EVEN';
  DPNA_PARITY_ODD_A               = 'ODD';
  DPNA_PARITY_MARK_A              = 'MARK';
  DPNA_PARITY_SPACE_A             = 'SPACE';

// values for flow control
  DPNA_FLOW_CONTROL_NONE_A        = 'NONE';
  DPNA_FLOW_CONTROL_XONXOFF_A     = 'XONXOFF';
  DPNA_FLOW_CONTROL_RTS_A         = 'RTS';
  DPNA_FLOW_CONTROL_DTR_A         = 'DTR';
  DPNA_FLOW_CONTROL_RTSDTR_A      = 'RTSDTR';

// Shortcut values
//
// These can be used instead of the corresponding CLSID_DP8SP_XXXX guids
//
  DPNA_VALUE_TCPIPPROVIDER_A      = 'IP';
  DPNA_VALUE_IPXPROVIDER_A        = 'IPX';
  DPNA_VALUE_MODEMPROVIDER_A      = 'MODEM';
  DPNA_VALUE_SERIALPROVIDER_A     = 'SERIAL';

(****************************************************************************
 *
 * DirectPlay8Address Forward Declarations For External Types
 *
 ****************************************************************************)
type
  IDirectPlay8Address   = interface;
  IDirectPlay8AddressIP = interface;

(****************************************************************************
 *
 * DirectPlay8Address Interface Pointer definitions
 *
 ****************************************************************************)

//
// COM definition for IDirectPlay8Address Generic Interface
//
  PIDirectPlay8Addresses = ^TIDirectPlay8Addresses;
  TIDirectPlay8Addresses = array[0..0] of IDirectPlay8Address;

  IDirectPlay8Address = interface (IUnknown)
    ['{83783300-4063-4c8a-9DB3-82830A7FEB31}']
    function BuildFromURLW(pwszSourceURL : PWChar) : HResult; stdcall;
    function BuildFromURLA(pszSourceURL : PChar) : HResult; stdcall;
    function Duplicate(out ppdpaNewAddress : IDirectPlay8Address) : HResult; stdcall;
    function SetEqual(pdpaAddress : IDirectPlay8Address) : HResult; stdcall;
    function IsEqual(pdpaAddress : IDirectPlay8Address) : HResult; stdcall;
    function Clear : HResult; stdcall;
    function GetURLW(pwszURL : PWChar; var pdwNumChars : LongWord) : HResult; stdcall;
    function GetURLA(pszURL : PChar; var pdwNumChars : LongWord) : HResult; stdcall;
    function GetSP(var pguidSP : TGUID) : HResult; stdcall;
    function GetUserData (pvUserData : Pointer; var pdwBufferSize : LongWord) : HResult; stdcall;
    function SetSP(const pguidSP : PGUID): HResult; stdcall;
    function SetUserData(pvUserData : Pointer; dwDataSize : LongWord) : HResult; stdcall;
    function GetNumComponents(var pdwNumComponents : LongWord) : HResult; stdcall;
    function GetComponentByName(pwszName : PWChar; pvBuffer : Pointer; var pdwBufferSize, pdwDataType : LongWord): HResult; stdcall;
    function GetComponentByIndex(dwComponentID : LongWord; pwszName : PWChar; var pdwNameLen : LongWord; pvBuffer : Pointer; var pdwBufferSize, pdwDataType : LongWord) : HResult; stdcall;
    function AddComponent(pwszName : PWChar; lpvData : Pointer; dwDataSize : LongWord; dwDataType : LongWord) : HResult; stdcall;
    function GetDevice(var pguidDevice : TGUID) : HResult; stdcall;
    function SetDevice(var pguidDevice : TGUID) : HResult; stdcall;
    function BuildFromDPADDRESS(pvAddress : Pointer; dwDataSize : LongWord) : HResult; stdcall;
  end;

//
// COM definition for IDirectPlay8AddressIP Generic Interface
//
  IDirectPlay8AddressIP = interface (IUnknown)
    ['{E5A0E990-2BAD-430b-87DA-A142CF75DE58}']
    function BuildFromSockAddr(const pSockAddr : TSockAddr) : HResult; stdcall;
    function BuildAddress(wszAddress : PWChar; usPort : Word) : HResult; stdcall;
    function BuildLocalAddress(const pguidAdapter : TGUID; usPort : Word) : HResult; stdcall;
    function GetSockAddress(psockAddress : PSockAddr; var pdwAddressBufferSize : LongWord) : HResult; stdcall;
    function GetLocalAddress(var pguidAdapter : TGUID; var pusPort : Word) : HResult; stdcall;
    function GetAddress(wszAddress : PWChar; var pdwAddressLength : LongWord; var psPort : Word) : HResult; stdcall;
  end;

(****************************************************************************
 *
 * DirectPlay8Address Interface IIDs
 *
 ****************************************************************************)

  IID_IDirectPlay8Address     = IDirectPlay8Address;
  IID_IDirectPlay8AddressIP   = IDirectPlay8AddressIP;

(****************************************************************************
 *
 * DirectPlay8Address CLSIDs
 *
 ****************************************************************************)

const
  CLSID_DirectPlay8Address : TGUID = '{934A9523-A3CA-4bc5-ADA0-D6D95D979421}';

(****************************************************************************
 *
 * DirectPlay8Address Functions
 *
 ****************************************************************************)

(*)
 * This function is no longer supported.  It is recommended that CoCreateInstance be used to create
 * DirectPlay8 lobby objects.
(*)
{$IFDEF DX8}
var
  DirectPlay8AddressCreate : function(const pcIID : TGUID; out ppvInterface; pUnknown : IUnknown) : HResult; stdcall;
{$ENDIF}

(*==========================================================================
 *
 *  Copyright (C) 2000 Microsoft Corporation.  All Rights Reserved.
 *
 *  File:       DPLobby8.h
 *  Content:    DirectPlay8 Lobby Include File
 *
 ***************************************************************************)


(****************************************************************************
 *
 * DirectPlay8 Lobby Message IDs
 *
 ****************************************************************************)
const                          
  DPL_MSGID_LOBBY               = $8000;
  DPL_MSGID_RECEIVE             = $0001 or DPL_MSGID_LOBBY;
  DPL_MSGID_CONNECT             = $0002 or DPL_MSGID_LOBBY;
  DPL_MSGID_DISCONNECT          = $0003 or DPL_MSGID_LOBBY;
  DPL_MSGID_SESSION_STATUS      = $0004 or DPL_MSGID_LOBBY;
  DPL_MSGID_CONNECTION_SETTINGS = $0005 or DPL_MSGID_LOBBY;

(****************************************************************************
 *
 * DirectPlay8Lobby Constants
 *
 ****************************************************************************)

//
// Specifies that operation should be performed on all open connections
//
  DPLHANDLE_ALLCONNECTIONS = $FFFFFFFF;

//
// The associated game session has suceeded in connecting / hosting
//
  DPLSESSION_CONNECTED = $0001;

// The associated game session failed connecting / hosting
//
  DPLSESSION_COULDNOTCONNECT = $0002;

//
// The associated game session has disconnected
//
  DPLSESSION_DISCONNECTED = $0003;

//
// The associated game session has terminated
//
  DPLSESSION_TERMINATED = $0004;

//
// The associated game session's host has migrated
//
  DPLSESSION_HOSTMIGRATED = $0005;

//
// The associated game session's host has migrated to the local client
//
  DPLSESSION_HOSTMIGRATEDHERE = $0006;


(****************************************************************************
 *
 * DirectPlay8 Lobby Flags
 *
 ****************************************************************************)

//
// Do not automatically make the lobby app unavailable when a connection is established
//
  DPLAVAILABLE_ALLOWMULTIPLECONNECT = $0001;

//
// Launch a new instance of the application to connect to
//
  DPLCONNECT_LAUNCHNEW      = $0001;

//
// Launch a new instance of the application if one is not waiting
//
  DPLCONNECT_LAUNCHNOTFOUND = $0002;

//
// When starting the associated game session, start it as a host
//
  DPLCONNECTSETTINGS_HOST   = $0001;

//
// Disable parameter validation
//
  DPLINITIALIZE_DISABLEPARAMVAL = $0001;

(****************************************************************************
 *
 * DirectPlay8Lobby Structures (Non-Message)
 *
 ****************************************************************************)

type
//
// Information on a registered game
//
  PDPLApplicationInfo = ^TDPLApplicationInfo;
  TDPLApplicationInfo = packed record
    guidApplication     : TGUID;         // GUID of the application
    pwszApplicationName : PWChar;        // Name of the application
    dwNumRunning        : LongWord;      // # of instances of this application running
    dwNumWaiting        : LongWord;      // # of instances of this application waiting
    dwFlags             : LongWord;      // Flags
  end;

  PDPL_Application_Info = ^TDPL_Application_Info;
  TDPL_Application_Info = TDPLApplicationInfo;

//
// Application description
//
  PDPNApplicationDesc = ^TDPNApplicationDesc;
  TDPNApplicationDesc = packed record
    dwSize                        : LongWord;  // Size of this structure
    dwFlags                       : LongWord;  // Flags (DPNSESSION_...)
    guidInstance                  : TGUID;     // Instance GUID
    guidApplication               : TGUID;     // Application GUID
    dwMaxPlayers                  : LongWord;  // Maximum # of players allowed (0=no limit)
    dwCurrentPlayers              : LongWord;  // Current # of players allowed
    pwszSessionName               : PWChar;    // Name of the session
    pwszPassword                  : PWChar;    // Password for the session
    pvReservedData                : Pointer;
    dwReservedDataSize            : LongWord;
    pvApplicationReservedData     : Pointer;
    dwApplicationReservedDataSize : LongWord;
  end;

  PDPN_Application_Desc = ^TDPN_Application_Desc;
  TDPN_Application_Desc = TDPNApplicationDesc;

//
// Settings to be used for connecting / hosting a game session
//
  PDPLConnectionSettings = ^TDPLConnectionSettings;
  TDPLConnectionSettings = packed record
    dwSize               : LongWord;                // Size of this structure
    dwFlags              : LongWord;                // Connection settings flags (DPLCONNECTSETTINGS_...)
    dpnAppDesc           : TDPNApplicationDesc;     // Application desc for the associated DirectPlay session
    pdp8HostAddress      : IDirectPlay8Address;     // Address of host to connect to
    ppdp8DeviceAddresses : PIDirectPlay8Addresses;  // Address of device to connect from / host on
    cNumDeviceAddresses  : LongWord;                // # of addresses specified in ppdp8DeviceAddresses
    pwszPlayerName       : PWChar;                  // Name to give the player
  end;

  PDPL_Connection_Settings = ^TDPL_Connection_Settings;
  TDPL_Connection_Settings = TDPLConnectionSettings;

//
// Information for performing a lobby connect
// (ConnectApplication)
//
  PDPLConnectInfo = ^TDPLConnectInfo;
  TDPLConnectInfo = packed record
    dwSize                 : LongWord;                   // Size of this structure
    dwFlags                : LongWord;                   // Flags (DPLCONNECT_...)
    guidApplication        : TGUID;                      // GUID of application to launch
    pdplConnectionSettings : PDPLConnectionSettings;     // Settings application should use
    pvLobbyConnectData     : Pointer;                    // User defined data block
    dwLobbyConnectDataSize : LongWord;                   // Size of user defined data block
  end;

  PDPL_Connect_Info = ^TDPL_Connect_Info;
  TDPL_Connect_Info = TDPLConnectInfo;

//
// Information for registering an application
// (RegisterApplication)
//
  PDPLProgramDesc = ^TDPLProgramDesc;
  TDPLProgramDesc = packed record
    dwSize                 : LongWord;
    dwFlags                : LongWord;
    guidApplication        : TGUID;        // Application GUID
    pwszApplicationName    : PWChar;       // Unicode application name
    pwszCommandLine        : PWChar;       // Unicode command line arguments
    pwszCurrentDirectory   : PWChar;       // Unicode current directory
    pwszDescription        : PWChar;       // Unicode application description
    pwszExecutableFilename : PWChar;       // Unicode filename of application executable
    pwszExecutablePath     : PWChar;       // Unicode path of application executable
    pwszLauncherFilename   : PWChar;       // Unicode filename of launcher executable
    pwszLauncherPath       : PWChar;       // Unicode path of launcher executable
  end;

  PDPL_Program_Desc = ^TDPL_Program_Desc;
  TDPL_Program_Desc = TDPLProgramDesc;

(****************************************************************************
 *
 * DirectPlay8 Lobby Message Structures
 *
 ****************************************************************************)

//
// A connection was established 
// (DPL_MSGID_CONNECT)
//
  PDPLMessageConnect = ^TDPLMessageConnect;
  TDPLMessageConnect = packed record
    dwSize                 : LongWord;                 // Size of this structure
    hConnectId             : TDPNHandle;               // Handle of new connection
    pdplConnectionSettings : PDPLConnectionSettings;   // Connection settings for this connection
    pvLobbyConnectData     : Pointer;                  // User defined lobby data block
    dwLobbyConnectDataSize : LongWord;                 // Size of user defined lobby data block
    pvConnectionContext    : Pointer;                  // Context value for this connection (user set)
  end;

  PDPL_Message_Connect = ^TDPL_Message_Connect;
  TDPL_Message_Connect = TDPLMessageConnect;

//
// Connection settings have been updated
// (DPL_MSGID_CONNECTION_SETTINGS)
//
  PDPLMessageConnectionSettings = ^TDPLMessageConnectionSettings;
  TDPLMessageConnectionSettings = packed record
    dwSize                 : LongWord;                    // Size of this structure
    hSender                : TDPNHandle;                  // Handle of the connection for these settings
    pdplConnectionSettings : PDPLConnectionSettings;      // Connection settings
    pvConnectionContext    : Pointer;                     // Context value for this connection
  end;

  PDPL_Message_Connection_Settings = ^TDPL_Message_Connection_Settings;
  TDPL_Message_Connection_Settings = TDPLMessageConnectionSettings;

//
// A connection has been disconnected
// (DPL_MSGID_DISCONNECT)
//
  PDPLMessageDisconnect = ^TDPLMessageDisconnect;
  TDPLMessageDisconnect = packed record
    dwSize              : LongWord;                     // Size of this structure
    hDisconnectId       : TDPNHandle;                   // Handle of the connection that was terminated
    hrReason            : HResult;                      // Reason the connection was broken
    pvConnectionContext : Pointer;                      // Context value for this connection
  end;

  PDPL_Message_Disconnect = ^TDPL_Message_Disconnect;
  TDPL_Message_Disconnect = TDPLMessageDisconnect;

//
// Data was received through a connection
// (DPL_MSGID_RECEIVE)
//
  PDPLMessageReceive = ^TDPLMessageReceive;
  TDPLMessageReceive = packed record
    dwSize              : LongWord;                     // Size of this structure
    hSender             : TDPNHandle;                   // Handle of the connection that is from
    pBuffer             : PByte;                        // Contents of the message
    dwBufferSize        : LongWord;                     // Size of the message context
    pvConnectionContext : Pointer;                      // Context value for this connection
  end;

  PDPL_Message_Receive = ^TDPL_Message_Receive;
  TDPL_Message_Receive = TDPLMessageReceive;

//
// Current status of the associated connection
// (DPL_MSGID_SESSION_STATUS)
//
  PDPLMessageSessionStatus = ^TDPLMessageSessionStatus;
  TDPLMessageSessionStatus = packed record
    dwSize              : LongWord;                     // Size of this structure
    hSender             : TDPNHandle;                   // Handle of the connection that this is from
    dwStatus            : LongWord;                     // Status (DPLSESSION_...)
    pvConnectionContext : Pointer;                      // Context value for this connection
  end;

  PDPL_Message_Session_Status = ^TDPL_Message_Session_Status;
  TDPL_Message_Session_Status = TDPLMessageSessionStatus;

(****************************************************************************
 *
 * DirectPlay8 Functions
 *
 ****************************************************************************)

type
//
// COM definition for DirectPlayLobbyClient
//
  IDirectPlay8LobbyClient = interface (IUnknown)
    ['{819074A2-016C-11d3-AE14-006097B01411}']
    function Initialize(pvUserContext : Pointer; pfn : TDPNMessageHandler; dwFlags : LongWord) : HResult; stdcall;
    function EnumLocalPrograms(pGuidApplication : PGUID; pEnumData : PByte; var pdwEnumData : LongWord; var pdwItems : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function ConnectApplication(const pdplConnectionInfo : TDPLConnectInfo; pvUserApplicationContext : Pointer; phApplication : PDPNHandle; dwTimeOut : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function Send(hConnection : TDPNHandle; pBuffer : PByte; pBufferSize, dwFlags : LongWord) : HResult; stdcall;
    function ReleaseApplication(hApplication : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function Close(dwFlags : LongWord) : HResult; stdcall;
    function GetConnectionSettings(hConnection : TDPNHandle; pdplConnectSettings : PDPLConnectionSettings; var pdwInfoSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetConnectionSettings(hConnection : TDPNHandle; const pdplConnectSettings : TDPLConnectionSettings; dwFlags : LongWord) : HResult; stdcall;
  end;

//
// COM definition for DirectPlayLobbiedApplication
//
  IDirectPlay8LobbiedApplication = interface (IUnknown)
    ['{819074A3-016C-11d3-AE14-006097B01411}']
    function Initialize(pvUserContext : Pointer; pfn : TDPNMessageHandler; pdpnhConnection : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function RegisterProgram(const pdplProgramDesc : TDPLProgramDesc; dwFlags : LongWord) : HResult; stdcall;
    function UnRegisterProgram(const pguidApplication : TGUID; dwFlags : LongWord) : HResult; stdcall;
    function Send(hConnection : TDPNHandle; pBuffer : PByte; pBufferSize, dwFlags : LongWord) : HResult; stdcall;
    function SetAppAvailable(fAvailable : BOOL; dwFlags : LongWord) : HResult; stdcall;
    function UpdateStatus(hConnection : TDPNHandle; dwStatus, dwFlags : LongWord) : HResult; stdcall;
    function Close(dwFlags : LongWord) : HResult; stdcall;
    function GetConnectionSettings(hLobbyClient : TDPNHandle; pdplSessionInfo : PDPLConnectionSettings; var pdwInfoSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetConnectionSettings(hConnection : TDPNHandle; const pdplConnectSettings : TDPLConnectionSettings; dwFlags : LongWord) : HResult; stdcall;
  end;

(****************************************************************************
 *
 * DirectPlay8Lobby Interface IIDs
 *
 ****************************************************************************)

 IID_IDirectPlay8LobbyClient        = IDirectPlay8LobbyClient;
 IID_IDirectPlay8LobbiedApplication = IDirectPlay8LobbiedApplication;

(****************************************************************************
 *
 * DirectPlay8Lobby CLSIDs
 *
 ****************************************************************************)
const
  CLSID_DirectPlay8LobbiedApplication : TGUID = '{667955AD-6B3B-43ca-B949-BC69B5BAFF7F}';
  CLSID_DirectPlay8LobbyClient        : TGUID = '{3B2B6775-70B6-45af-8DEA-A209C69559F3}';

(****************************************************************************
 *
 * DirectPlay8Lobby Create
 *
 ****************************************************************************)

(*)
 * This function is no longer supported.  It is recommended that CoCreateInstance be used to create
 * DirectPlay8 lobby objects.
(*)
{$IFDEF DX8}
 var
  DirectPlay8LobbyCreate : function (const pcIID : TGUID; out ppvInterface; pUnknown : IUnknown) : HResult; stdcall;
{$ENDIF}


(*==========================================================================;
 *
 *  Copyright (C) 1998-2000 Microsoft Corporation.  All Rights Reserved.
 *
 *  File:		DPlay8.h
 *  Content:	DirectPlay8 include file
 *
 ***************************************************************************)

(****************************************************************************
 *
 * DirectPlay8 Message Identifiers
 *
 ****************************************************************************)

const
  DPN_MSGID_OFFSET                    = $FFFF0000;
  DPN_MSGID_ADD_PLAYER_TO_GROUP       = DPN_MSGID_OFFSET or $0001;
  DPN_MSGID_APPLICATION_DESC          = DPN_MSGID_OFFSET or $0002;
  DPN_MSGID_ASYNC_OP_COMPLETE         = DPN_MSGID_OFFSET or $0003;
  DPN_MSGID_CLIENT_INFO               = DPN_MSGID_OFFSET or $0004;
  DPN_MSGID_CONNECT_COMPLETE          = DPN_MSGID_OFFSET or $0005;
  DPN_MSGID_CREATE_GROUP              = DPN_MSGID_OFFSET or $0006;
  DPN_MSGID_CREATE_PLAYER             = DPN_MSGID_OFFSET or $0007;
  DPN_MSGID_DESTROY_GROUP             = DPN_MSGID_OFFSET or $0008;
  DPN_MSGID_DESTROY_PLAYER            = DPN_MSGID_OFFSET or $0009;
  DPN_MSGID_ENUM_HOSTS_QUERY          = DPN_MSGID_OFFSET or $000a;
  DPN_MSGID_ENUM_HOSTS_RESPONSE       = DPN_MSGID_OFFSET or $000b;
  DPN_MSGID_GROUP_INFO                = DPN_MSGID_OFFSET or $000c;
  DPN_MSGID_HOST_MIGRATE              = DPN_MSGID_OFFSET or $000d;
  DPN_MSGID_INDICATE_CONNECT          = DPN_MSGID_OFFSET or $000e;
  DPN_MSGID_INDICATED_CONNECT_ABORTED = DPN_MSGID_OFFSET or $000f;
  DPN_MSGID_PEER_INFO                 = DPN_MSGID_OFFSET or $0010;
  DPN_MSGID_RECEIVE                   = DPN_MSGID_OFFSET or $0011;
  DPN_MSGID_REMOVE_PLAYER_FROM_GROUP  = DPN_MSGID_OFFSET or $0012;
  DPN_MSGID_RETURN_BUFFER             = DPN_MSGID_OFFSET or $0013;
  DPN_MSGID_SEND_COMPLETE             = DPN_MSGID_OFFSET or $0014;
  DPN_MSGID_SERVER_INFO               = DPN_MSGID_OFFSET or $0015;
  DPN_MSGID_TERMINATE_SESSION         = DPN_MSGID_OFFSET or $0016;

(****************************************************************************
 *
 * DirectPlay8 Constants
 *
 ****************************************************************************)

  DPNID_ALL_PLAYERS_GROUP = 0;

//
// DESTROY_GROUP reasons
//
  DPNDESTROYGROUPREASON_NORMAL            = $0001;
  DPNDESTROYGROUPREASON_AUTODESTRUCTED    = $0002;
  DPNDESTROYGROUPREASON_SESSIONTERMINATED = $0003;

//
// DESTROY_PLAYER reasons
//
  DPNDESTROYPLAYERREASON_NORMAL              = $0001;
  DPNDESTROYPLAYERREASON_CONNECTIONLOST      = $0002;
  DPNDESTROYPLAYERREASON_SESSIONTERMINATED   = $0003;
  DPNDESTROYPLAYERREASON_HOSTDESTROYEDPLAYER = $0004;

(****************************************************************************
 *
 * DirectPlay8 Flags
 *
 ****************************************************************************)

//
// Asynchronous operation flags (For Async Ops)
//
  DPNOP_SYNC = $80000000;

//
// Add player to group flags (For AddPlayerToGroup)
//
  DPNADDPLAYERTOGROUP_SYNC = DPNOP_SYNC;

//
// Cancel flags
//
  DPNCANCEL_CONNECT        = $0001;
  DPNCANCEL_ENUM           = $0002;
  DPNCANCEL_SEND           = $0004;
  DPNCANCEL_ALL_OPERATIONS = $8000;

//
// Connect flags (For Connect)
//
  DPNCONNECT_SYNC                   = DPNOP_SYNC;
  DPNCONNECT_OKTOQUERYFORADDRESSING = $0001;

//
// Create group flags (For CreateGroup)
//
  DPNCREATEGROUP_SYNC = DPNOP_SYNC;

//
// Destroy group flags (For DestroyGroup)
//
  DPNDESTROYGROUP_SYNC = DPNOP_SYNC;

//
// Enumerate clients and groups flags (For EnumPlayersAndGroups)
//
  DPNENUM_PLAYERS = $0001;
  DPNENUM_GROUPS  = $0010;

//
// Enum hosts flags (For EnumHosts)
//
  DPNENUMHOSTS_SYNC                   = DPNOP_SYNC;
  DPNENUMHOSTS_OKTOQUERYFORADDRESSING = $0001;
  DPNENUMHOSTS_NOBROADCASTFALLBACK    = $0002;

//
// Enum service provider flags (For EnumSP)
//
  DPNENUMSERVICEPROVIDERS_ALL = $0001;

//
// Get send queue info flags (For GetSendQueueInfo)
//
  DPNGETSENDQUEUEINFO_PRIORITY_NORMAL = $0001;
  DPNGETSENDQUEUEINFO_PRIORITY_HIGH   = $0002;
  DPNGETSENDQUEUEINFO_PRIORITY_LOW    = $0004;

//
// Group information flags (For Group Info)
//
  DPNGROUP_AUTODESTRUCT = $0001;

//
// Host flags (For Host)
//
  DPNHOST_OKTOQUERYFORADDRESSING = $0001;

//
// Set info
//
  DPNINFO_NAME = $0001;
  DPNINFO_DATA = $0002;

//
// Initialize flags (For Initialize)
//
  DPNINITIALIZE_DISABLEPARAMVAL = $0001;

//
// Register Lobby flags
//
  DPNLOBBY_REGISTER   = $0001;
  DPNLOBBY_UNREGISTER = $0002;

//
// Player information flags (For Player Info / Player Messages)
//
  DPNPLAYER_LOCAL = $0002;
  DPNPLAYER_HOST  = $0004;

//
// Remove player from group flags (For RemovePlayerFromGroup)
//
  DPNREMOVEPLAYERFROMGROUP_SYNC = DPNOP_SYNC;

//
// Send flags (For Send/SendTo)
//                          
  DPNSEND_SYNC              = DPNOP_SYNC;
  DPNSEND_NOCOPY            = $0001;
  DPNSEND_NOCOMPLETE        = $0002;
  DPNSEND_COMPLETEONPROCESS = $0004;
  DPNSEND_GUARANTEED        = $0008;
  DPNSEND_NONSEQUENTIAL     = $0010;
  DPNSEND_NOLOOPBACK        = $0020;
  DPNSEND_PRIORITY_LOW      = $0040;
  DPNSEND_PRIORITY_HIGH     = $0080;

//
// Session Flags (for DPN_APPLICATION_DESC)
//
  DPNSESSION_CLIENT_SERVER   = $0001;
  DPNSESSION_MIGRATE_HOST    = $0004;
  DPNSESSION_NODPNSVR        = $0040;
  DPNSESSION_REQUIREPASSWORD = $0080;

//
// Set client info flags (For SetClientInfo)
//
  DPNSETCLIENTINFO_SYNC = DPNOP_SYNC;

//
// Set group info flags (For SetGroupInfo)
//
  DPNSETGROUPINFO_SYNC = DPNOP_SYNC;

//
// Set peer info flags (For SetPeerInfo)
//
  DPNSETPEERINFO_SYNC = DPNOP_SYNC;

//
// Set server info flags (For SetServerInfo)
//
  DPNSETSERVERINFO_SYNC = DPNOP_SYNC;

//
// SP capabilities flags
//
  DPNSPCAPS_SUPPORTSDPNSRV      = $0001;
  DPNSPCAPS_SUPPORTSBROADCAST   = $0002;
  DPNSPCAPS_SUPPORTSALLADAPTERS = $0004;

(****************************************************************************
 *
 * DirectPlay8 Structures (Non-Message)
 *
 ****************************************************************************)
type
//
// Generic Buffer Description
//
  PDPNBufferDesc = ^TDPNBufferDesc;
  TDPNBufferDesc = packed record
    dwBufferSize : LongWord;
    pBufferData  : PByte;
  end;

  PDPN_Buffer_Desc = ^TDPN_Buffer_Desc;
  TDPN_Buffer_Desc = TDPNBufferDesc;

  PBufferDesc = ^TBufferDesc;
  TBufferDesc = TDPNBufferDesc;

//
// DirectPlay8 capabilities
//
  PDPNCaps = ^TDPNCaps;
  TDPNCaps = packed record
    dwSize                  : LongWord;  // Size of this structure
    dwFlags                 : LongWord;  // Flags
    dwConnectTimeout        : LongWord;  // ms before a connect request times out
    dwConnectRetries        : LongWord;  // # of times to attempt the connection
    dwTimeoutUntilKeepAlive : LongWord;  // ms of inactivity before a keep alive is sent
  end;

  PDPN_Caps = ^TDPN_Caps;
  TDPN_Caps = TDPNCaps;

//
// Connection Statistics information
//
  PDPNConnectionInfo = ^TDPNConnectionInfo;
  TDPNConnectionInfo = packed record
    dwSize                              : LongWord;
    dwRoundTripLatencyMS                : LongWord;
    dwThroughputBPS                     : LongWord;
    dwPeakThroughputBPS                 : LongWord;

    dwBytesSentGuaranteed               : LongWord;
    dwPacketsSentGuaranteed             : LongWord;
    dwBytesSentNonGuaranteed            : LongWord;
    dwPacketsSentNonGuaranteed          : LongWord;

    dwBytesRetried                      : LongWord;  // Guaranteed only
    dwPacketsRetried                    : LongWord;  // Guaranteed only
    dwBytesDropped                      : LongWord;  // Non Guaranteed only
    dwPacketsDropped                    : LongWord;  // Non Guaranteed only

    dwMessagesTransmittedHighPriority   : LongWord;
    dwMessagesTimedOutHighPriority      : LongWord;
    dwMessagesTransmittedNormalPriority : LongWord;
    dwMessagesTimedOutNormalPriority    : LongWord;
    dwMessagesTransmittedLowPriority    : LongWord;
    dwMessagesTimedOutLowPriority       : LongWord;

    dwBytesReceivedGuaranteed           : LongWord;
    dwPacketsReceivedGuaranteed         : LongWord;
    dwBytesReceivedNonGuaranteed        : LongWord;
    dwPacketsReceivedNonGuaranteed      : LongWord;
    dwMessagesReceived                  : LongWord;
  end;

  PDPN_Connection_Info = ^TDPN_Connection_Info;
  TDPN_Connection_Info = TDPNConnectionInfo;

//
// Group information strucutre
//
  PDPNGroupInfo = ^TDPNGroupInfo;
  TDPNGroupInfo = packed record
    dwSize       : LongWord;  // size of this structure
    dwInfoFlags  : LongWord;  // information contained
    pwszName     : LongWord;  // Unicode Name
    pvData       : LongWord;  // data block
    dwDataSize   : LongWord;  // size in BYTES of data block
    dwGroupFlags : LongWord;  // group flags (DPNGROUP_...)
  end;

  PDPN_Group_Info = ^TDPN_Group_Info;
  TDPN_Group_Info = TDPNGroupInfo;

//
// Player information structure
//
  PDPNPlayerInfo = ^TDPNPlayerInfo;
  TDPNPlayerInfo = packed record
    dwSize        : LongWord;  // size of this structure
    dwInfoFlags   : LongWord;  // information contained
    pwszName      : PWChar;    // Unicode Name
    pvData        : Pointer;   // data block
    dwDataSize    : LongWord;  // size in BYTES of data block
    dwPlayerFlags : LongWord;  // player flags (DPNPLAYER_...)
  end;

  PDPN_Player_Info = ^TDPN_Player_Info;
  TDPN_Player_Info = TDPNPlayerInfo;

{typedef struct _DPN_SECURITY_CREDENTIALS	DPN_SECURITY_CREDENTIALS, *PDPN_SECURITY_CREDENTIALS;
typedef struct _DPN_SECURITY_DESC			DPN_SECURITY_DESC, *PDPN_SECURITY_DESC;}

  PDPNSecurityDesc = Pointer;
  PDPNSecurityCredentials = Pointer;

  PDPN_Security_Desc = PDPNSecurityDesc;
  PDPN_Security_Credentials = PDPNSecurityCredentials;

//
// Service provider & adapter enumeration structure
//
  PDPNServiceProviderInfo = ^TDPNServiceProviderInfo;
  TDPNServiceProviderInfo = packed record
    dwFlags    : LongWord;
    guid       : TGUID;     // SP Guid
    pwszName   : PWChar;    // Friendly Name
    pvReserved : Pointer;
    dwReserved : LongWord;
  end;

  PDPN_Service_Provider_Info = ^TDPN_Service_Provider_Info;
  TDPN_Service_Provider_Info = TDPNServiceProviderInfo;

  PDPNSPCaps = ^TDPNSPCaps;
  TDPNSPCaps = packed record
    dwSize                     : LongWord;  // Size of this structure
    dwFlags                    : LongWord;  // Flags ((DPNSPCAPS_...)
    dwNumThreads               : LongWord;  // # of worker threads to use
    dwDefaultEnumCount         : LongWord;  // default # of enum requests
    dwDefaultEnumRetryInterval : LongWord;  // default ms between enum requests
    dwDefaultEnumTimeout       : LongWord;  // default enum timeout
    dwMaxEnumPayloadSize       : LongWord;  // maximum size in bytes for enum payload data
    dwBuffersPerThread         : LongWord;  // number of receive buffers per thread
    dwSystemBufferSize         : LongWord;  // amount of buffering to do in addition to posted receive buffers
  end;

  PDPN_SP_Caps = ^TDPN_SP_Caps;
  TDPN_SP_Caps = TDPNSPCaps;

(****************************************************************************
 *
 * IDirectPlay8 message handler call back structures
 *
 ****************************************************************************)

//
// Add player to group strucutre for message handler
// (DPN_MSGID_ADD_PLAYER_TO_GROUP)
//

  PDPNMsgAddPlayerToGroup = ^TDPNMsgAddPlayerToGroup;
  TDPNMsgAddPlayerToGroup = packed record
    dwSize          : LongWord;  // Size of this structure
    dpnidGroup      : TDPNID;    // DPNID of group
    pvGroupContext  : Pointer;   // Group context value
    dpnidPlayer     : TDPNID;    // DPNID of added player
    pvPlayerContext : Pointer;   // Player context value
  end;

  PDPNMsg_Add_Player_To_Group = ^TDPNMsg_Add_Player_To_Group;
  TDPNMsg_Add_Player_To_Group = TDPNMsgAddPlayerToGroup;

//
// Async operation completion structure for message handler
// (DPN_MSGID_ASYNC_OP_COMPLETE)
//
  PDPNMsgASyncOpComplete = ^TDPNMsgASyncOpComplete;
  TDPNMsgASyncOpComplete = packed record
    dwSize        : LongWord;    // Size of this structure
    hAsyncOp      : TDPNHandle;  // DirectPlay8 async operation handle
    pvUserContext : Pointer;     // User context supplied
    hResultCode   : HResult;     // HRESULT of operation
  end;

  PDPNMsg_ASync_Op_Complete = ^TDPNMsg_ASync_Op_Complete;
  TDPNMsg_ASync_Op_Complete = TDPNMsgASyncOpComplete;

//
// Client info structure for message handler
// (DPN_MSGID_CLIENT_INFO)
//
  PDPNMsgClientInfo = ^TDPNMsgClientInfo;
  TDPNMsgClientInfo = packed record
    dwSize          : LongWord;  // Size of this structure
    dpnidClient     : TDPNID;    // DPNID of client
    pvPlayerContext : Pointer;   // Player context value
  end;

  PDPNMsg_Client_Info = ^TDPNMsg_Client_Info;
  TDPNMsg_Client_Info = TDPNMsgClientInfo;

//
// Connect complete structure for message handler
// (DPN_MSGID_CONNECT_COMPLETE)
//
  PDPNMsgConnectComplete = ^TDPNMsgConnectComplete;
  TDPNMsgConnectComplete = packed record
    dwSize                     : LongWord;    // Size of this structure
    hAsyncOp                   : TDPNHandle;  // DirectPlay8 Async operation handle
    pvUserContext              : Pointer;     // User context supplied at Connect
    hResultCode                : HResult;     // HRESULT of connection attempt
    pvApplicationReplyData     : Pointer;     // Connection reply data from Host/Server
    dwApplicationReplyDataSize : LongWord;    // Size (in bytes) of pvApplicationReplyData
  end;

  PDPNMsg_Connect_Complete = ^TDPNMsg_Connect_Complete;
  TDPNMsg_Connect_Complete = TDPNMsgConnectComplete;

//
// Create group structure for message handler
// (DPN_MSGID_CREATE_GROUP)
//
  PDPNMsgCreateGroup = ^TDPNMsgCreateGroup;
  TDPNMsgCreateGroup = packed record
    dwSize         : LongWord;  // Size of this structure
    dpnidGroup     : TDPNID;    // DPNID of new group
    dpnidOwner     : TDPNID;    // Owner of newgroup
    pvGroupContext : Pointer;   // Group context value
  end;

  PDPNMsg_Create_Group = ^TDPNMsg_Create_Group;
  TDPNMsg_Create_Group = TDPNMsgCreateGroup;

//
// Create player structure for message handler
// (DPN_MSGID_CREATE_PLAYER)
//
  PDPNMsgCreatePlayer = ^TDPNMsgCreatePlayer;
  TDPNMsgCreatePlayer = packed record
    dwSize          : LongWord;  // Size of this structure
    dpnidPlayer     : TDPNID;    // DPNID of new player
    pvPlayerContext : Pointer;   // Player context value
  end;

  PDPNMsg_Create_Player = ^TDPNMsg_Create_Player;
  TDPNMsg_Create_Player = TDPNMsgCreatePlayer;

//
// Destroy group structure for message handler
// (DPN_MSGID_DESTROY_GROUP)
//
  PDPNMsgDestroyGroup = ^TDPNMsgDestroyGroup;
  TDPNMsgDestroyGroup = packed record
    dwSize         : LongWord;  // Size of this structure
    dpnidGroup     : TDPNID;    // DPNID of destroyed group
    pvGroupContext : Pointer;   // Group context value
    dwReason       : LongWord;  // Information only
  end;

  PDPNMsg_Destroy_Group = ^TDPNMsg_Destroy_Group;
  TDPNMsg_Destroy_Group = TDPNMsgDestroyGroup;

//
// Destroy player structure for message handler
// (DPN_MSGID_DESTROY_PLAYER)
//
  PDPNMsgDestroyPlayer = ^TDPNMsgDestroyPlayer;
  TDPNMsgDestroyPlayer = packed record
    dwSize          : LongWord;  // Size of this structure
    dpnidPlayer     : TDPNID;    // DPNID of leaving player
    pvPlayerContext : Pointer;   // Player context value
    dwReason        : LongWord;  // Information only
  end;

  PDPNMsg_Destroy_Player = ^TDPNMsg_Destroy_Player;
  TDPNMsg_Destroy_Player = TDPNMsgDestroyPlayer;

//
// Enumeration request received structure for message handler
// (DPN_MSGID_ENUM_HOSTS_QUERY)
//
  PDPNMsgEnumHostsQuery = ^TDPNMsgEnumHostsQuery;
  TDPNMsgEnumHostsQuery = packed record
    dwSize                : LongWord;             // Size of this structure.
    pAddressSender        : IDirectPlay8Address;  // Address of client who sent the request
    pAddressDevice        : IDirectPlay8Address;  // Address of device request was received on
    pvReceivedData        : Pointer;              // Request data (set on client)
    dwReceivedDataSize    : LongWord;             // Request data size (set on client)
    dwMaxResponseDataSize : LongWord;             // Max allowable size of enum response
    pvResponseData        : Pointer;              // Optional query repsonse (user set)
    dwResponseDataSize    : LongWord;             // Optional query response size (user set)
    pvResponseContext     : Pointer;              // Optional query response context (user set)
  end;

  PDPNMsg_Enum_Hosts_Query = ^TDPNMsg_Enum_Hosts_Query;
  TDPNMsg_Enum_Hosts_Query = TDPNMsgEnumHostsQuery;

//
// Enumeration response received structure for message handler
// (DPN_MSGID_ENUM_HOSTS_RESPONSE)
//
  PDPNMsgEnumHostsResponse = ^TDPNMsgEnumHostsResponse;
  TDPNMsgEnumHostsResponse = packed record
    dwSize                  : LongWord;               // Size of this structure
    pAddressSender          : IDirectPlay8Address;    // Address of host who responded
    pAddressDevice          : IDirectPlay8Address;    // Device response was received on
    pApplicationDescription : PDPNApplicationDesc;    // Application description for the session
    pvResponseData          : Pointer;                // Optional response data (set on host)
    dwResponseDataSize      : LongWord;               // Optional response data size (set on host)
    pvUserContext           : Pointer;                // Context value supplied for enumeration
    dwRoundTripLatencyMS    : LongWord;               // Round trip latency in MS
  end;

  PDPNMsg_Enum_Hosts_Response = ^TDPNMsg_Enum_Hosts_Response;
  TDPNMsg_Enum_Hosts_Response = TDPNMsgEnumHostsResponse;

//
// Group info structure for message handler
// (DPN_MSGID_GROUP_INFO)
//
  PDPNMsgGroupInfo = ^TDPNMsgGroupInfo;
  TDPNMsgGroupInfo = packed record
    dwSize         : LongWord;    // Size of this structure
    dpnidGroup     : TDPNID;      // DPNID of group
    pvGroupContext : Pointer;     // Group context value
  end;

  PDPNMsg_Group_Info = ^TDPNMsg_Group_Info;
  TDPNMsg_Group_Info = TDPNMsgGroupInfo;

//
// Migrate host structure for message handler
// (DPN_MSGID_HOST_MIGRATE)
//
  PDPNMsgHostMigrate = ^TDPNMsgHostMigrate;
  TDPNMsgHostMigrate = packed record
    dwSize          : LongWord;      // Size of this structure
    dpnidNewHost    : TDPNID;        // DPNID of new Host player
    pvPlayerContext : Pointer;       // Player context value
  end;

  PDPNMsg_Host_Migrate = ^TDPNMsg_Host_Migrate;
  TDPNMsg_Host_Migrate = TDPNMsgHostMigrate;

//
// Indicate connect structure for message handler
// (DPN_MSGID_INDICATE_CONNECT)
//
  PDPNMsgIndicateConnect = ^TDPNMsgIndicateConnect;
  TDPNMsgIndicateConnect = packed record
    dwSize                : LongWord;             // Size of this structure
    pvUserConnectData     : Pointer;              // Connecting player data
    dwUserConnectDataSize : LongWord;             // Size (in bytes) of pvUserConnectData
    pvReplyData           : Pointer;              // Connection reply data
    dwReplyDataSize       : LongWord;             // Size (in bytes) of pvReplyData
    pvReplyContext        : Pointer;              // Buffer context for pvReplyData
    pvPlayerContext       : Pointer;              // Player context preset
    pAddressPlayer        : IDirectPlay8Address;  // Address of connecting player
    pAddressDevice        : IDirectPlay8Address;  // Address of device receiving connect attempt
  end;

  PDPNMsg_Indicate_Connect = ^TDPNMsg_Indicate_Connect;
  TDPNMsg_Indicate_Connect = TDPNMsgIndicateConnect;

//
// Indicated connect aborted structure for message handler
// (DPN_MSGID_INDICATED_CONNECT_ABORTED)
//
  PDPNMsgIndicatedConnectAborted = ^TDPNMsgIndicatedConnectAborted;
  TDPNMsgIndicatedConnectAborted = packed record
    dwSize          : LongWord;  // Size of this structure
    pvPlayerContext : Pointer;   // Player context preset from DPNMSG_INDICATE_CONNECT
  end;

  PDPNMsg_Indicated_Connect_Aborted = ^TDPNMsg_Indicated_Connect_Aborted;
  TDPNMsg_Indicated_Connect_Aborted = TDPNMsgIndicatedConnectAborted;

//
// Peer info structure for message handler
// (DPN_MSGID_PEER_INFO)
//
  PDPNMsgPeerInfo = ^TDPNMsgPeerInfo;
  TDPNMsgPeerInfo = packed record
    dwSize          : LongWord;   // Size of this structure
    dpnidPeer       : TDPNID;     // DPNID of peer
    pvPlayerContext : Pointer;    // Player context value
  end;

  PDPNMsg_Peer_Info = ^TDPNMsg_Peer_Info;
  TDPNMsg_Peer_Info = TDPNMsgPeerInfo;

//
// Receive structure for message handler
// (DPN_MSGID_RECEIVE)
//
  PDPNMsgReceive = ^TDPNMsgReceive;
  TDPNMsgReceive = packed record
    dwSize            : LongWord;    // Size of this structure
    dpnidSender       : TDPNID;      // DPNID of sending player
    pvPlayerContext   : Pointer;     // Player context value of sending player
    pReceiveData      : PByte;       // Received data
    dwReceiveDataSize : LongWord;    // Size (in bytes) of pReceiveData
    hBufferHandle     : TDPNHandle;  // Buffer handle for pReceiveData
  end;

  PDPNMsg_Receive = ^TDPNMsg_Receive;
  TDPNMsg_Receive = TDPNMsgReceive;

//
// Remove player from group structure for message handler
// (DPN_MSGID_REMOVE_PLAYER_FROM_GROUP)
//
  PDPNMsgRemovePlayerFromGroup = ^TDPNMsgRemovePlayerFromGroup;
  TDPNMsgRemovePlayerFromGroup = packed record
    dwSize          : LongWord;     // Size of this structure
    dpnidGroup      : TDPNID;       // DPNID of group
    pvGroupContext  : Pointer;      // Group context value
    dpnidPlayer     : TDPNID;       // DPNID of deleted player
    pvPlayerContext : Pointer;      // Player context value
  end;

  PDPNMsg_Remove_Player_From_Group = ^TDPNMsg_Remove_Player_From_Group;
  TDPNMsg_Remove_Player_From_Group = TDPNMsgRemovePlayerFromGroup;

//
// Returned buffer structure for message handler
// (DPN_MSGID_RETURN_BUFFER)
//
  PDPNMsgReturnBuffer = ^TDPNMsgReturnBuffer;
  TDPNMsgReturnBuffer = packed record
    dwSize        : LongWord;  // Size of this structure
    hResultCode   : HResult;   // Return value of operation
    pvBuffer      : Pointer;   // Buffer being returned
    pvUserContext : Pointer;   // Context associated with buffer
  end;

  PDPNMsg_Return_Buffer = ^TDPNMsg_Return_Buffer;
  TDPNMsg_Return_Buffer = TDPNMsgReturnBuffer;

//
// Send complete structure for message handler
// (DPN_MSGID_SEND_COMPLETE)
//
  PDPNMsgSendComplete = ^TDPNMsgSendComplete;
  TDPNMsgSendComplete = packed record
    dwSize        : LongWord;    // Size of this structure
    hAsyncOp      : TDPNHandle;  // DirectPlay8 Async operation handle
    pvUserContext : Pointer;     // User context supplied at Send/SendTo
    hResultCode   : HResult;     // HRESULT of send
    dwSendTime    : LongWord;    // Send time in ms
  end;

  PDPNMsg_Send_Complete = ^TDPNMsg_Send_Complete;
  TDPNMsg_Send_Complete = TDPNMsgSendComplete;

//
// Server info structure for message handler
// (DPN_MSGID_SERVER_INFO)
//
  PDPNMsgServerInfo = ^TDPNMsgServerInfo;
  TDPNMsgServerInfo = packed record
    dwSize          : LongWord;    // Size of this structure
    dpnidServer     : TDPNID;      // DPNID of server
    pvPlayerContext : Pointer;     // Player context value
  end;

  PDPNMsg_Server_Info = ^TDPNMsg_Server_Info;
  TDPNMsg_Server_Info = TDPNMsgServerInfo;

//
// Terminated session structure for message handler
// (DPN_MSGID_TERMINATE_SESSION)
//
  PDPNMsgTerminateSession = ^TDPNMsgTerminateSession;
  TDPNMsgTerminateSession = packed record
    dwSize              : LongWord;  // Size of this structure
    hResultCode         : HResult;   // Reason
    pvTerminateData     : Pointer;   // Data passed from Host/Server
    dwTerminateDataSize : LongWord;  // Size (in bytes) of pvTerminateData
  end;

  PDPNMsg_Terminate_Session = ^TDPNMsg_Terminate_Session;
  TDPNMsg_Terminate_Session = TDPNMsgTerminateSession;

(****************************************************************************
 *
 * DirectPlay8 Forward Declarations For External Types
 *
 ****************************************************************************)
type
  IDirectPlay8Peer   = interface;
  IDirectPlay8Server = interface;
  IDirectPlay8Client = interface;

(****************************************************************************
 *
 * DirectPlay8 Application Interfaces
 *
 ****************************************************************************)

//
// COM definition for DirectPlay8 Client interface
//
  IDirectPlay8Client = interface (IUnknown)
    ['{5102DACD-241B-11d3-AEA7-006097B01411}']
    function Initialize (pvUserContext : Pointer; pfn : TDPNMessageHandler; dwFlags : LongWord) : HResult; stdcall;
    function EnumServiceProviders (pguidServiceProvider, pguidApplication : PGUID; pSPInfoBuffer : PDPNServiceProviderInfo; var pcbEnumData : LongWord; var pcReturned : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function EnumHosts (var pApplicationDesc : TDPNApplicationDesc; pAddrHost, pDeviceInfo : IDirectPlay8Address; pvUserEnumData : Pointer; dwUserEnumDataSize, dwEnumCount, dwRetryInterval, dwTimeOut : LongWord; pvUserContext : Pointer; pAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function CancelAsyncOperation (hAsyncHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function Connect (var pdnAppDesc : TDPNApplicationDesc; pAddrHost, pDeviceInfo : IDirectPlay8Address; pdnSecurity : PDPNSecurityDesc; pdnCredentials : PDPNSecurityCredentials; pvUserConnectData : Pointer; dwUserConnectDataSize : LongWord; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function Send (const prgBufferDesc : TDPNBufferDesc; cBufferDesc, dwTimeOut : LongWord; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetSendQueueInfo (pdwNumMsgs, pdwNumBytes : PLongWord; dwFlags : LongWord) : HResult; stdcall;
    function GetApplicationDesc (pAppDescBuffer : PDPNApplicationDesc; var pcbDataSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetClientInfo (const pdpnPlayerInfo : TDPNPlayerInfo; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetServerInfo (pdpnPlayerInfo : PDPNPlayerInfo; var pdwSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function GetServerAddress (out pAddress : IDirectPlay8Address; dwFlags : LongWord) : HResult; stdcall;
    function Close (dwFlags : LongWord) : HResult; stdcall;
    function ReturnBuffer (hBufferHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetCaps (var pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetCaps (const pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetSPCaps (const pguidSP : TGUID; const pdpnSPCaps : TDPNSPCaps) : HResult; stdcall;
    function GetSPCaps (const pguidSP : TGUID; var pdpnSPCaps : TDPNSPCaps; dwFlags : LongWord) : HResult; stdcall;
    function GetConnectionInfo (var pdpConnectionInfo : TDPNConnectionInfo; dwFlags : LongWord) : HResult; stdcall;
    function RegisterLobby (dpnHandle : TDPNHandle; pIDP8LobbiedApplication : IDirectPlay8LobbiedApplication; dwFlags : LongWord) : HResult; stdcall;
  end;

//
// COM definition for DirectPlay8 Server interface
//
  IDirectPlay8Server = interface (IUnknown)
    ['{5102DACE-241B-11d3-AEA7-006097B01411}']
    function Initialize(pvUserContext : Pointer; pfn : TDPNMessageHandler; dwFlags : LongWord) : HResult; stdcall;
    function EnumServiceProviders(pguidServiceProvider, pguidApplication : PGUID; pSPInfoBuffer : PDPNServiceProviderInfo; var pcbEnumData : LongWord; var pcReturned : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function CancelAsyncOperation(hAsyncHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetSendQueueInfo(dpnid : TDPNID; pdwNumMsgs, pdwNumBytes : PLongWord; dwFlags : LongWord) : HResult; stdcall;
    function GetApplicationDesc(pAppDescBuffer : PDPNApplicationDesc; var pcbDataSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetServerInfo(var pdpnPlayerInfo : TDPNPlayerInfo; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetClientInfo(dpnid : TDPNID; pdpnPlayerInfo : PDPNPlayerInfo; pdwSize : PLongWord; dwFlags : LongWord) : HResult; stdcall;
    function GetClientAddress(dpnid : TDPNID; out pAddress : IDirectPlay8Address; dwFlags : LongWord) : HResult; stdcall;
    function GetLocalHostAddresses(prgpAddress : PIDirectPlay8Addresses; var pcAddress : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetApplicationDesc(const pad : TDPNApplicationDesc; dwFlags : LongWord) : HResult; stdcall;
    function Host(var pdnAppDesc : TDPNApplicationDesc;  prgpDeviceInfo : PIDirectPlay8Addresses; cDeviceInfo : LongWord; pdpSecurity : PDPNSecurityDesc; pdpCredentials : PDPNSecurityCredentials; pvPlayerContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function SendTo(dpnid : TDPNID; const pBufferDesc : TDPNBufferDesc; cBufferDesc, dwTimeOut : LongWord; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function CreateGroup(const pdpnGroupInfo : TDPNGroupInfo; pvGroupContext : Pointer; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function DestroyGroup(idGroup : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function AddPlayerToGroup(idGroup, idClient : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function RemovePlayerFromGroup(idGroup, idClient : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function SetGroupInfo(dpnid : TDPNID; const pdpnGroupInfo : TDPNGroupInfo; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetGroupInfo(dpnid : TDPNID; pdpnGroupInfo : PDPNGroupInfo; var pdwSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function EnumPlayersAndGroups(prgdpnid : PDPNID; var pcdpnid : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function EnumGroupMembers(dpnid : TDPNID; prgdpnid : PDPNID; var pcdpnid : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function Close(dwFlags : LongWord) : HResult; stdcall;
    function DestroyClient(dpnidClient : TDPNID; pDestroyInfo : Pointer; dwDestroyInfoSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function ReturnBuffer(hBufferHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetPlayerContext(dpnid : TDPNID; var ppvPlayerContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function GetGroupContext(dpnid : TDPNID; var ppvGroupContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function GetCaps(var pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetCaps(const pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetSPCaps(const pguidSP : TGUID; const pdpnSPCaps : TDPNSPCaps) : HResult; stdcall;
    function GetSPCaps(const pguidSP : TGUID; var pdpnSPCaps : TDPNSPCaps; dwFlags : LongWord) : HResult; stdcall;
    function GetConnectionInfo(dpnidEndPoint : TDPNID; var pdpConnectionInfo : TDPNConnectionInfo; dwFlags : LongWord) : HResult; stdcall;
    function RegisterLobby(dpnHandle : TDPNHandle; pIDP8LobbiedApplication : IDirectPlay8LobbiedApplication; dwFlags : LongWord) : HResult; stdcall;
  end;

//
// COM definition for DirectPlay8 Peer interface
//
  IDirectPlay8Peer = interface (IUnknown)
    ['{5102DACF-241B-11d3-AEA7-006097B01411}']
    function Initialize(pvUserContext : Pointer; pfn : TDPNMessageHandler; dwFlags : LongWord) : HResult; stdcall;
    function EnumServiceProviders(pguidServiceProvider, pguidApplication : PGUID; pSPInfoBuffer : PDPNServiceProviderInfo; var pcbEnumData : LongWord; var pcReturned : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function CancelAsyncOperation(hAsyncHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function Connect(const pdnAppDesc : PDPNApplicationDesc; pHostAddr, pDeviceInfo : IDirectPlay8Address; pdnSecurity : PDPNSecurityDesc; pdnCredentials : PDPNSecurityCredentials; pvUserConnectData : Pointer; dwUserConnectDataSize : LongWord; pvPlayerContext : Pointer; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function SendTo(dpnid : TDPNID; const pBufferDesc : TDPNBufferDesc; cBufferDesc, dwTimeOut : LongWord; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetSendQueueInfo(pdwNumMsgs, pdwNumBytes : PLongWord; dwFlags : LongWord) : HResult; stdcall;
    function Host(const pdnAppDesc : PDPNApplicationDesc; prgpDeviceInfo : PIDirectPlay8Addresses; cDeviceInfo : LongWord; pdpSecurity : PDPNSecurityDesc; pdpCredentials : PDPNSecurityCredentials; pvPlayerContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function GetApplicationDesc(pAppDescBuffer : PDPNApplicationDesc; var pcbDataSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetApplicationDesc(const pad : TDPNApplicationDesc; dwFlags : LongWord) : HResult; stdcall;
    function CreateGroup(const pdpnGroupInfo : TDPNGroupInfo; pvGroupContext : Pointer; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function DestroyGroup(idGroup : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function AddPlayerToGroup(idGroup, idClient : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function RemovePlayerFromGroup(idGroup, idClient : TDPNID; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function SetGroupInfo(dpnid : TDPNID; const pdpnGroupInfo : TDPNGroupInfo; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetGroupInfo(dpnid : TDPNID; pdpnGroupInfo : PDPNGroupInfo; var pdwSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function EnumPlayersAndGroups(prgdpnid : PDPNID; var pcdpnid : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function EnumGroupMembers(dpnid : TDPNID; prgdpnid : PDPNID; var pcdpnid : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetPeerInfo(const pdpnPlayerInfo : PDPNPlayerInfo; pvAsyncContext : Pointer; phAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall; stdcall;
    function GetPeerInfo(dpnid : TDPNID; pdpnPlayerInfo : PDPNPlayerInfo; var pdwSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function GetPeerAddress(dpnid : TDPNID; out pAddress : IDirectPlay8Address; dwFlags : LongWord) : HResult; stdcall;
    function GetLocalHostAddresses(prgpAddress : PIDirectPlay8Addresses; var pcAddress : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function Close(dwFlags : LongWord) : HResult; stdcall;
    function EnumHosts(const pApplicationDesc : TDPNApplicationDesc; pAddrHost, pDeviceInfo : IDirectPlay8Address; pvUserEnumData : Pointer; dwUserEnumDataSize, dwEnumCount, dwRetryInterval, dwTimeOut : LongWord; pvUserContext : Pointer; pAsyncHandle : PDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function DestroyPeer(dpnidClient : TDPNID; pDestroyInfo : Pointer; dwDestroyInfoSize : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function ReturnBuffer(hBufferHandle : TDPNHandle; dwFlags : LongWord) : HResult; stdcall;
    function GetPlayerContext(dpnid : TDPNID; var ppvPlayerContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function GetGroupContext(dpnid : TDPNID; var ppvGroupContext : Pointer; dwFlags : LongWord) : HResult; stdcall;
    function GetCaps(var pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetCaps(const pdpCaps : TDPNCaps; dwFlags : LongWord) : HResult; stdcall;
    function SetSPCaps(const pguidSP : TGUID; const pdpnSPCaps : TDPNSPCaps) : HResult; stdcall;
    function GetSPCaps(const pguidSP : PGUID; var pdpnSPCaps : TDPNSPCaps; dwFlags : LongWord) : HResult; stdcall;
    function GetConnectionInfo(dpnidEndPoint : TDPNID; var pdpConnectionInfo : TDPNConnectionInfo; dwFlags : LongWord) : HResult; stdcall;
    function RegisterLobby(dpnHandle : TDPNHandle; pIDP8LobbiedApplication : IDirectPlay8LobbiedApplication; dwFlags : LongWord) : HResult; stdcall;
    function TerminateSession(pvTerminateData : Pointer; dwTerminateDataSize, dwFlags : LongWord) : HResult; stdcall;
  end;

(***************************************************************************
 *
 * DirectPlay8 Interface IIDs
 *
 ****************************************************************************)

  IID_IDirectPlay8Peer   = IDirectPlay8Peer;
  IID_IDirectPlay8Server = IDirectPlay8Server;
  IID_IDirectPlay8Client = IDirectPlay8Client;

(****************************************************************************
 *
 * DirectPlay8 CLSIDs
 *
 ****************************************************************************)
const
  CLSID_DirectPlay8Client : TGUID = '{743F1DC6-5ABA-429f-8BDF-C54D03253DC2}';
  CLSID_DirectPlay8Peer   : TGUID = '{286F484D-375E-4458-A272-B138E2F80A6A}';
  CLSID_DirectPlay8Server : TGUID = '{DA825E1B-6830-43d7-835D-0B5AD82956A2}';

(****************************************************************************
 *
 * DirectPlay8 Service Provider GUIDs
 *
 ****************************************************************************)

  CLSID_DP8SP_IPX         : TGUID = '{53934290-628D-11D2-AE0F-006097B01411}';
  CLSID_DP8SP_MODEM       : TGUID = '{6D4A3650-628D-11D2-AE0F-006097B01411}';
  CLSID_DP8SP_SERIAL      : TGUID = '{743B5D60-628D-11D2-AE0F-006097B01411}';
  CLSID_DP8SP_TCPIP       : TGUID = '{EBFE7BA0-628D-11D2-AE0F-006097B01411}';

(****************************************************************************
 *
 * DirectPlay8 Functions
 *
 ****************************************************************************)

(*)
 * This function is no longer supported. It is recommended that
 * CoCreateInstance be used to create DirectPlay8 lobby objects.
(*)
{$IFDEF DX8}
var
  DirectPlay8Create : function(const pcIID : TGUID; out ppvInterface; pUnknown : IUnknown) : HResult; stdcall;
{$ENDIF}

(****************************************************************************
 *
 * DIRECTPLAY8 ERRORS
 *
 * Errors are represented by negative values and cannot be combined.
 *
 ****************************************************************************)

const
  _DPN_FACILITY_CODE       = $015;
  _DPNHRESULT_BASE         = $8000;
  MAKE_DPNHRESULT          = (1 shl 31) or (_DPN_FACILITY_CODE shl 16) or _DPNHRESULT_BASE;

  DPN_OK   = S_OK;

  DPNSUCCESS_EQUAL       = (0 shl 31) or (_DPN_FACILITY_CODE shl 16) or _DPNHRESULT_BASE + $05;
  DPNSUCCESS_NOTEQUAL    = (0 shl 31) or (_DPN_FACILITY_CODE shl 16) or _DPNHRESULT_BASE + $0A;
  DPNSUCCESS_PENDING     = (0 shl 31) or (_DPN_FACILITY_CODE shl 16) or _DPNHRESULT_BASE + $0E;

  DPNERR_ABORTED                 = MAKE_DPNHRESULT + $030 ;
  DPNERR_ADDRESSING              = MAKE_DPNHRESULT + $040 ;
  DPNERR_ALREADYCLOSING          = MAKE_DPNHRESULT + $050 ;
  DPNERR_ALREADYCONNECTED        = MAKE_DPNHRESULT + $060 ;
  DPNERR_ALREADYDISCONNECTING    = MAKE_DPNHRESULT + $070 ;
  DPNERR_ALREADYINITIALIZED      = MAKE_DPNHRESULT + $080 ;
  DPNERR_ALREADYREGISTERED       = MAKE_DPNHRESULT + $090 ;
  DPNERR_BUFFERTOOSMALL          = MAKE_DPNHRESULT + $100 ;
  DPNERR_CANNOTCANCEL            = MAKE_DPNHRESULT + $110 ;
  DPNERR_CANTCREATEGROUP         = MAKE_DPNHRESULT + $120 ;
  DPNERR_CANTCREATEPLAYER        = MAKE_DPNHRESULT + $130 ;
  DPNERR_CANTLAUNCHAPPLICATION   = MAKE_DPNHRESULT + $140 ;
  DPNERR_CONNECTING              = MAKE_DPNHRESULT + $150 ;
  DPNERR_CONNECTIONLOST          = MAKE_DPNHRESULT + $160 ;
  DPNERR_CONVERSION              = MAKE_DPNHRESULT + $170 ;
  DPNERR_DATATOOLARGE            = MAKE_DPNHRESULT + $175 ;
  DPNERR_DOESNOTEXIST            = MAKE_DPNHRESULT + $180 ;
  DPNERR_DUPLICATECOMMAND        = MAKE_DPNHRESULT + $190 ;
  DPNERR_ENDPOINTNOTRECEIVING    = MAKE_DPNHRESULT + $200 ;
  DPNERR_ENUMQUERYTOOLARGE       = MAKE_DPNHRESULT + $210 ;
  DPNERR_ENUMRESPONSETOOLARGE    = MAKE_DPNHRESULT + $220 ;
  DPNERR_EXCEPTION               = MAKE_DPNHRESULT + $230 ;
  DPNERR_GENERIC                 = E_FAIL;
  DPNERR_GROUPNOTEMPTY           = MAKE_DPNHRESULT + $240 ;
  DPNERR_HOSTING                 = MAKE_DPNHRESULT + $250 ;
  DPNERR_HOSTREJECTEDCONNECTION  = MAKE_DPNHRESULT + $260 ;
  DPNERR_HOSTTERMINATEDSESSION   = MAKE_DPNHRESULT + $270 ;
  DPNERR_INCOMPLETEADDRESS       = MAKE_DPNHRESULT + $280 ;
  DPNERR_INVALIDADDRESSFORMAT    = MAKE_DPNHRESULT + $290 ;
  DPNERR_INVALIDAPPLICATION      = MAKE_DPNHRESULT + $300 ;
  DPNERR_INVALIDCOMMAND          = MAKE_DPNHRESULT + $310 ;
  DPNERR_INVALIDDEVICEADDRESS    = MAKE_DPNHRESULT + $320 ;
  DPNERR_INVALIDENDPOINT         = MAKE_DPNHRESULT + $330 ;
  DPNERR_INVALIDFLAGS            = MAKE_DPNHRESULT + $340 ;
  DPNERR_INVALIDGROUP            = MAKE_DPNHRESULT + $350 ;
  DPNERR_INVALIDHANDLE           = MAKE_DPNHRESULT + $360 ;
  DPNERR_INVALIDHOSTADDRESS      = MAKE_DPNHRESULT + $370 ;
  DPNERR_INVALIDINSTANCE         = MAKE_DPNHRESULT + $380 ;
  DPNERR_INVALIDINTERFACE        = MAKE_DPNHRESULT + $390 ;
  DPNERR_INVALIDOBJECT           = MAKE_DPNHRESULT + $400 ;
  DPNERR_INVALIDPARAM            = E_INVALIDARG;
  DPNERR_INVALIDPASSWORD         = MAKE_DPNHRESULT + $410 ;
  DPNERR_INVALIDPLAYER           = MAKE_DPNHRESULT + $420 ;
  DPNERR_INVALIDPOINTER          = E_POINTER;
  DPNERR_INVALIDPRIORITY         = MAKE_DPNHRESULT + $430 ;
  DPNERR_INVALIDSTRING           = MAKE_DPNHRESULT + $440 ;
  DPNERR_INVALIDURL              = MAKE_DPNHRESULT + $450 ;
  DPNERR_INVALIDVERSION          = MAKE_DPNHRESULT + $460 ;
  DPNERR_NOCAPS                  = MAKE_DPNHRESULT + $470 ;
  DPNERR_NOCONNECTION            = MAKE_DPNHRESULT + $480 ;
  DPNERR_NOHOSTPLAYER            = MAKE_DPNHRESULT + $490 ;
  DPNERR_NOINTERFACE             = E_NOINTERFACE;
  DPNERR_NOMOREADDRESSCOMPONENTS = MAKE_DPNHRESULT + $500 ;
  DPNERR_NORESPONSE              = MAKE_DPNHRESULT + $510 ;
  DPNERR_NOTALLOWED              = MAKE_DPNHRESULT + $520 ;
  DPNERR_NOTHOST                 = MAKE_DPNHRESULT + $530 ;
  DPNERR_NOTREADY                = MAKE_DPNHRESULT + $540 ;
  DPNERR_NOTREGISTERED           = MAKE_DPNHRESULT + $550 ;
  DPNERR_OUTOFMEMORY             = E_OUTOFMEMORY;
  DPNERR_PENDING                 = DPNSUCCESS_PENDING;
  DPNERR_PLAYERALREADYINGROUP    = MAKE_DPNHRESULT + $560 ;
  DPNERR_PLAYERLOST              = MAKE_DPNHRESULT + $570 ;
  DPNERR_PLAYERNOTINGROUP        = MAKE_DPNHRESULT + $580 ;
  DPNERR_PLAYERNOTREACHABLE      = MAKE_DPNHRESULT + $590 ;
  DPNERR_SENDTOOLARGE            = MAKE_DPNHRESULT + $600 ;
  DPNERR_SESSIONFULL             = MAKE_DPNHRESULT + $610 ;
  DPNERR_TABLEFULL               = MAKE_DPNHRESULT + $620 ;
  DPNERR_TIMEDOUT                = MAKE_DPNHRESULT + $630 ;
  DPNERR_UNINITIALIZED           = MAKE_DPNHRESULT + $640 ;
  DPNERR_UNSUPPORTED             = E_NOTIMPL;
  DPNERR_USERCANCEL              = MAKE_DPNHRESULT + $650;



(*==========================================================================;
 *
 *  Copyright (C) 1999 Microsoft Corporation.  All Rights Reserved.
 *
 *  File:       dpvoice.h
 *  Content:    DirectPlayVoice include file
 ***************************************************************************)

(****************************************************************************
 *
 * DirectPlayVoice Callback Functions
 *
 ****************************************************************************)
type
  TDVMessageHandler = function(pvUserContext : Pointer; dwMessageType : LongWord; lpMessage : Pointer) : HResult; stdcall;

(****************************************************************************
 *
 * DirectPlayVoice Datatypes (Non-Structure / Non-Message)
 *
 ****************************************************************************)

  PDVID = ^TDVID;
  TDVID = LongWord;

(****************************************************************************
 *
 * DirectPlayVoice Message Types
 *
 ****************************************************************************)
const
  DVMSGID_BASE                        = $0000;

  DVMSGID_CREATEVOICEPLAYER           = DVMSGID_BASE + $0001;
  DVMSGID_DELETEVOICEPLAYER           = DVMSGID_BASE + $0002;
  DVMSGID_SESSIONLOST                 = DVMSGID_BASE + $0003;
  DVMSGID_PLAYERVOICESTART            = DVMSGID_BASE + $0004;
  DVMSGID_PLAYERVOICESTOP             = DVMSGID_BASE + $0005;
  DVMSGID_RECORDSTART                 = DVMSGID_BASE + $0006;
  DVMSGID_RECORDSTOP                  = DVMSGID_BASE + $0007;
  DVMSGID_CONNECTRESULT               = DVMSGID_BASE + $0008;
  DVMSGID_DISCONNECTRESULT            = DVMSGID_BASE + $0009;
  DVMSGID_INPUTLEVEL                  = DVMSGID_BASE + $000A;
  DVMSGID_OUTPUTLEVEL                 = DVMSGID_BASE + $000B;
  DVMSGID_HOSTMIGRATED                = DVMSGID_BASE + $000C;
  DVMSGID_SETTARGETS                  = DVMSGID_BASE + $000D;
  DVMSGID_PLAYEROUTPUTLEVEL           = DVMSGID_BASE + $000E;
  DVMSGID_LOSTFOCUS                   = DVMSGID_BASE + $0010;
  DVMSGID_GAINFOCUS                   = DVMSGID_BASE + $0011;
  DVMSGID_LOCALHOSTSETUP              = DVMSGID_BASE + $0012;
  DVMSGID_MAXBASE                     = DVMSGID_LOCALHOSTSETUP;
  DVMSGID_MINBASE                     = DVMSGID_CREATEVOICEPLAYER;

(****************************************************************************
 *
 * DirectPlayVoice Constants
 *
 ****************************************************************************)

//
// Buffer Aggresiveness Value Ranges
//
  DVBUFFERAGGRESSIVENESS_MIN          = $00000001;
  DVBUFFERAGGRESSIVENESS_MAX          = $00000064;
  DVBUFFERAGGRESSIVENESS_DEFAULT      = $00000000;

//
// Buffer Quality Value Ranges
//
  DVBUFFERQUALITY_MIN                 = $00000001;
  DVBUFFERQUALITY_MAX                 = $00000064;
  DVBUFFERQUALITY_DEFAULT             = $00000000;

  DVID_SYS                            = 0;

//
// Used to identify the session host in client/server
//
  DVID_SERVERPLAYER                   = 1;

//
// Used to target all players
//
  DVID_ALLPLAYERS                     = 0;

//
// Used to identify the main buffer
//
  DVID_REMAINING                      = $FFFFFFFF;

// 
// Input level range
//
  DVINPUTLEVEL_MIN                    = $00000000;
  DVINPUTLEVEL_MAX                    = $00000063;  // 99 decimal

  DVNOTIFYPERIOD_MINPERIOD            = 20;


  DVPLAYBACKVOLUME_DEFAULT            = DSBVOLUME_MAX;

  DVRECORDVOLUME_LAST                 = $00000001;


//
// Use the default value
//
  DVTHRESHOLD_DEFAULT                 = $FFFFFFFF ;

//
// Threshold Ranges
//
  DVTHRESHOLD_MIN                     = $00000000;
  DVTHRESHOLD_MAX                     = $00000063;  // 99 decimal

//
// Threshold field is not used
//
  DVTHRESHOLD_UNUSED                  = $FFFFFFFE;

//
// Session Types
//
  DVSESSIONTYPE_PEER                  = $00000001;
  DVSESSIONTYPE_MIXING                = $00000002;
  DVSESSIONTYPE_FORWARDING            = $00000003;
  DVSESSIONTYPE_ECHO                  = $00000004;

(****************************************************************************
 *
 * DirectPlayVoice Flags
 *
 ****************************************************************************)

//
// Enable automatic adjustment of the recording volume
//
  DVCLIENTCONFIG_AUTORECORDVOLUME     = $00000008;

//
// Enable automatic voice activation
//
  DVCLIENTCONFIG_AUTOVOICEACTIVATED   = $00000020;

//
// Enable echo suppression
//
  DVCLIENTCONFIG_ECHOSUPPRESSION      = $08000000;

//
// Voice Activation manual mode
//
  DVCLIENTCONFIG_MANUALVOICEACTIVATED = $00000004;

// 
// Only playback voices that have buffers created for them
//
  DVCLIENTCONFIG_MUTEGLOBAL           = $00000010;

// 
// Mute the playback
//
  DVCLIENTCONFIG_PLAYBACKMUTE         = $00000002;

//
// Mute the recording 
//
  DVCLIENTCONFIG_RECORDMUTE           = $00000001;

// 
// Complete the operation before returning
//
  DVFLAGS_SYNC                        = $00000001;

// 
// Just check to see if wizard has been run, and if so what it's results were
//
  DVFLAGS_QUERYONLY                   = $00000002;

//
// Shutdown the voice session without migrating the host
//
  DVFLAGS_NOHOSTMIGRATE               = $00000008;

//
// Allow the back button to be enabled in the wizard
//
  DVFLAGS_ALLOWBACK                   = $00000010;

//
// Disable host migration in the voice session
//
  DVSESSION_NOHOSTMIGRATION           = $00000001;

// 
// Server controlled targetting
//
  DVSESSION_SERVERCONTROLTARGET       = $00000002;

//
// Use DirectSound Normal Mode instead of priority
//
  DVSOUNDCONFIG_NORMALMODE            = $00000001;

//
// Automatically select the microphone
//
  DVSOUNDCONFIG_AUTOSELECT            = $00000002;

// 
// Run in half duplex mode
//
  DVSOUNDCONFIG_HALFDUPLEX            = $00000004;

// 
// No volume controls are available for the recording device
//
  DVSOUNDCONFIG_NORECVOLAVAILABLE     = $00000010;

// 
// Disable capture sharing
//
  DVSOUNDCONFIG_NOFOCUS               = $20000000;

//
// Set system conversion quality to high
//
  DVSOUNDCONFIG_SETCONVERSIONQUALITY  = $00000008;

//
// Enable strict focus mode
//
  DVSOUNDCONFIG_STRICTFOCUS           = $40000000;

//
// Player is in half duplex mode
//
  DVPLAYERCAPS_HALFDUPLEX             = $00000001;

//
// Specifies that player is the local player
//
  DVPLAYERCAPS_LOCAL                  = $00000002;

(****************************************************************************
 *
 * DirectPlayVoice Forward Declarations For External Types
 *
 ****************************************************************************)
type
  IDirectPlayVoiceClient = interface;
  IDirectPlayVoiceServer = interface;
  IDirectPlayVoiceTest   = interface;

(****************************************************************************
 *
 * DirectPlayVoice Structures (Non-Message)
 *
 ****************************************************************************)
//
// DirectPlayVoice Caps
// (GetCaps / SetCaps)
//
  PDVCaps = ^TDVCaps;
  TDVCaps = packed record
    dwSize  : LongWord;   // Size of this structure
    dwFlags : LongWord;   // Caps flags
  end;

//
// DirectPlayVoice Client Configuration
// (Connect / GetClientConfig)
//
  PDVClientConfig = ^TDVClientConfig;
  TDVClientConfig = packed record
    dwSize                 : LongWord;    // Size of this structure
    dwFlags                : LongWord;    // Flags for client config (DVCLIENTCONFIG_...)
    lRecordVolume          : Longint;     // Recording volume
    lPlaybackVolume        : Longint;     // Playback volume
    dwThreshold            : LongWord;    // Voice Activation Threshold
    dwBufferQuality        : LongWord;    // Buffer quality
    dwBufferAggressiveness : LongWord;    // Buffer aggressiveness
    dwNotifyPeriod         : LongWord;    // Period of notification messages (ms)
  end;

//
// DirectPlayVoice Compression Type Information
// (GetCompressionTypes)
//
  PDVCompressionInfo = ^TDVCompressionInfo;
  TDVCompressionInfo = packed record
    dwSize             : LongWord;   // Size of this structure
    guidType           : TGUID;      // GUID that identifies this compression type
    lpszName           : PWChar;     // String name of this compression type
    lpszDescription    : PWChar;     // Description for this compression type
    dwFlags            : LongWord;   // Flags for this compression type
    dwMaxBitsPerSecond : LongWord;   // Maximum # of bit/s this compression type uses
  end;

//
// DirectPlayVoice Session Description
// (Host / GetSessionDesc)
//
  PDVSessionDesc = ^TDVSessionDesc;
  TDVSessionDesc = packed record
    dwSize                 : LongWord;    // Size of this structure
    dwFlags                : LongWord;    // Session flags (DVSESSION_...)
    dwSessionType          : LongWord;    // Session type (DVSESSIONTYPE_...)
    guidCT                 : TGUID;       // Compression Type to use
    dwBufferQuality        : LongWord;    // Buffer quality
    dwBufferAggressiveness : LongWord;    // Buffer aggresiveness
  end;

// 
// DirectPlayVoice Client Sound Device Configuration
// (Connect / GetSoundDeviceConfig)
//
  PDVSoundDeviceConfig = ^TDVSoundDeviceConfig;
  TDVSoundDeviceConfig = packed record
    dwSize               : LongWord;               // Size of this structure
    dwFlags              : LongWord;               // Flags for sound config (DVSOUNDCONFIG_...)
    guidPlaybackDevice   : TGUID;                  // GUID of the playback device to use
    lpdsPlaybackDevice   : IDirectSound;           // DirectSound Object to use (optional)
    guidCaptureDevice    : TGUID;                  // GUID of the capture device to use
    lpdsCaptureDevice    : IDirectSoundCapture;    // DirectSoundCapture Object to use (optional)
    hwndAppWindow        : hWnd;                   // HWND of your application's top-level window
    lpdsMainBuffer       : IDirectSoundBuffer;     // DirectSoundBuffer to use for playback (optional)
    dwMainBufferFlags    : LongWord;               // Flags to pass to Play() on the main buffer
    dwMainBufferPriority : LongWord;               // Priority to set when calling Play() on the main buffer
  end;

(****************************************************************************
 *
 * DirectPlayVoice message handler call back structures
 *
 ****************************************************************************)

//
// Result of the Connect() call.  (If it wasn't called Async)
// (DVMSGID_CONNECTRESULT)
//
  PDVMsgConnectResult = ^TDVMsgConnectResult;
  TDVMsgConnectResult = packed record
    dwSize   : LongWord;    // Size of this structure
    hrResult : HResult;     // Result of the Connect() call
  end;

  PDVMsg_ConnectResult = ^TDVMsg_ConnectResult;
  TDVMsg_ConnectResult = TDVMsgConnectResult;

//
// A new player has entered the voice session
// (DVMSGID_CREATEVOICEPLAYER)
//
  PDVMsgCreateVoicePlayer = ^TDVMsgCreateVoicePlayer;
  TDVMsgCreateVoicePlayer = packed record
    dwSize          : LongWord;          // Size of this structure
    dvidPlayer      : TDVID;             // DVID of the player who joined
    dwFlags         : LongWord;          // Player flags (DVPLAYERCAPS_...)
    pvPlayerContext : Pointer;           // Context value for this player (user set)
  end;

  PDVMsg_CreateVoicePlayer = ^TDVMsg_CreateVoicePlayer;
  TDVMsg_CreateVoicePlayer = TDVMsgCreateVoicePlayer;

//
// A player has left the voice session
// (DVMSGID_DELETEVOICEPLAYER)
//
  PDVMsgDeleteVoicePlayer = ^TDVMsgDeleteVoicePlayer;
  TDVMsgDeleteVoicePlayer = packed record
    dwSize          : LongWord;     // Size of this structure
    dvidPlayer      : TDVID;        // DVID of the player who left
    pvPlayerContext : Pointer;      // Context value for the player
  end;

  PDVMsg_DeleteVoicePlayer = ^TDVMsg_DeleteVoicePlayer;
  TDVMsg_DeleteVoicePlayer = TDVMsgDeleteVoicePlayer;

//
// Result of the Disconnect() call.  (If it wasn't called Async)
// (DVMSGID_DISCONNECTRESULT)
//
  PDVMsgDisconnectResult = ^TDVMsgDisconnectResult;
  TDVMsgDisconnectResult = packed record
    dwSize   : LongWord;        // Size of this structure
    hrResult : HResult;         // Result of the Disconnect() call
  end;

  PDVMsg_DisconnectResult = ^TDVMsg_DisconnectResult;
  TDVMsg_DisconnectResult = TDVMsgDisconnectResult;

// 
// The voice session host has migrated.
// (DVMSGID_HOSTMIGRATED) 
//
  PDVMsgHostMigrated = ^TDVMsgHostMigrated;
  TDVMsgHostMigrated = packed record
    dwSize             : LongWord;                // Size of this structure
    dvidNewHostID      : TDVID;                   // DVID of the player who is now the host
    pdvServerInterface : IDirectPlayVoiceServer;  // Pointer to the new host object (if local player is now host)
  end;

  PDVMsg_HostMigrated = ^TDVMsg_HostMigrated;
  TDVMsg_HostMigrated = TDVMsgHostMigrated;

//
// The current input level / recording volume on the local machine
// (DVMSGID_INPUTLEVEL)
//
  PDVMsgInputLevel = ^TDVMsgInputLevel;
  TDVMsgInputLevel = packed record
    dwSize               : LongWord;     // Size of this structure
    dwPeakLevel          : LongWord;     // Current peak level of the audio
    lRecordVolume        : Longint;      // Current recording volume
    pvLocalPlayerContext : Pointer;      // Context value for the local player
  end;

  PDVMsg_InputLevel = ^TDVMsg_InputLevel;
  TDVMsg_InputLevel = TDVMsgInputLevel;

//
// The local client is about to become the new host
// (DVMSGID_LOCALHOSTSETUP)
//
  PDVMsgLocalHostSetup = ^TDVMsgLocalHostSetup;
  TDVMsgLocalHostSetup = packed record
    dwSize          : LongWord;           // Size of this structure
    pvContext       : Pointer;            // Context value to be passed to Initialize() of new host object
    pMessageHandler : TDVMessageHandler;  // Message handler to be used by new host object
  end;

  PDVMsg_LocalHostSetup = ^TDVMsg_LocalHostSetup;
  TDVMsg_LocalHostSetup = TDVMsgLocalHostSetup;

//
// The current output level for the combined output of all incoming streams.
// (DVMSGID_OUTPUTLEVEL)
//
  PDVMsgOutputLevel = ^TDVMsgOutputLevel;
  TDVMsgOutputLevel = packed record
    dwSize               : LongWord;          // Size of this structure
    dwPeakLevel          : LongWord;          // Current peak level of the output
    lOutputVolume        : Longint;           // Current playback volume
    pvLocalPlayerContext : Pointer;           // Context value for the local player
  end;

  PDVMsg_OutputLevel = ^TDVMsg_OutputLevel;
  TDVMsg_OutputLevel = TDVMsgOutputLevel;

//
// The current peak level of an individual player's incoming audio stream as it is
// being played back.
// (DVMSGID_PLAYEROUTPUTLEVEL)
//
  PDVMsgPlayerOutputLevel = ^TDVMsgPlayerOutputLevel;
  TDVMsgPlayerOutputLevel = packed record
    dwSize             : LongWord;    // Size of this structure
    dvidSourcePlayerID : TDVID;       // DVID of the player
    dwPeakLevel        : LongWord;    // Peak level of the player's stream
    pvPlayerContext    : Pointer;     // Context value for the player
  end;

  PDVMsg_PlayerOutputLevel = ^TDVMsg_PlayerOutputLevel;
  TDVMsg_PlayerOutputLevel = TDVMsgPlayerOutputLevel;

//
// An audio stream from the specified player has started playing back on the local client.
// (DVMSGID_PLAYERVOICESTART).
//
  PDVMsgPlayerVoiceStart = ^TDVMsgPlayerVoiceStart;
  TDVMsgPlayerVoiceStart = packed record
    dwSize             : LongWord;        // Size of this structure
    dvidSourcePlayerID : TDVID;           // DVID of the Player
    pvPlayerContext    : Pointer;         // Context value for this player
  end;

  PDVMsg_PlayerVoiceStart = ^TDVMsg_PlayerVoiceStart;
  TDVMsg_PlayerVoiceStart = TDVMsgPlayerVoiceStart;

//
// The audio stream from the specified player has stopped playing back on the local client.
// (DVMSGID_PLAYERVOICESTOP)
//
  PDVMsgPlayerVoiceStop = ^TDVMsgPlayerVoiceStop;
  TDVMsgPlayerVoiceStop = packed record
    dwSize             : LongWord;       // Size of this structure
    dvidSourcePlayerID : TDVID;          // DVID of the player
    pvPlayerContext    : Pointer;        // Context value for this player
  end;

  PDVMsg_PlayerVoiceStop = ^TDVMsg_PlayerVoiceStop;
  TDVMsg_PlayerVoiceStop = TDVMsgPlayerVoiceStop;

//
// Transmission has started on the local machine
// (DVMSGID_RECORDSTART)
//
  PDVMsgRecordStart = ^TDVMsgRecordStart;
  TDVMsgRecordStart = packed record
    dwSize               : LongWord;      // Size of this structure
    dwPeakLevel          : LongWord;      // Peak level that caused transmission to start
    pvLocalPlayerContext : Pointer;       // Context value for the local player
  end;

  PDVMsg_RecordStart = ^TDVMsg_RecordStart;
  TDVMsg_RecordStart = TDVMsgRecordStart;

// 
// Transmission has stopped on the local machine
// (DVMSGID_RECORDSTOP)
//
  PDVMsgRecordStop = ^TDVMsgRecordStop;
  TDVMsgRecordStop = packed record
    dwSize               : LongWord;    // Size of this structure
    dwPeakLevel          : LongWord;    // Peak level that caused transmission to stop
    pvLocalPlayerContext : Pointer;     // Context value for the local player
  end;

  PDVMsg_RecordStop = ^TDVMsg_RecordStop;
  TDVMsg_RecordStop = TDVMsgRecordStop;

// 
// The voice session has been lost
// (DVMSGID_SESSIONLOST)
//
  PDVMsgSessionLost = ^TDVMsgSessionLost;
  TDVMsgSessionLost = packed record
    dwSize   : LongWord;        // Size of this structure
    hrResult : HResult;         // Reason the session was disconnected
  end;

  PDVMsg_SessionLost = ^TDVMsg_SessionLost;
  TDVMsg_SessionLost = TDVMsgSessionLost;

//
// The target list has been updated for the local client
// (DVMSGID_SETTARGETS)
//
  PDVMsgSetTargets = ^TDVMsgSetTargets;
  TDVMsgSetTargets = packed record
    dwSize       : LongWord;   // Size of this structure
    dwNumTargets : LongWord;   // # of targets
    pdvidTargets : TDVID;      // An array of DVIDs specifying the current targets
  end;

  PDVMsg_SetTargets = ^TDVMsg_SetTargets;
  TDVMsg_SetTargets = TDVMsgSetTargets;

(****************************************************************************
 *
 * DirectPlay8 Application Interfaces
 *
 ****************************************************************************)
  IDirectPlayVoiceClient = interface (IUnknown)
    ['{1DFDC8EA-BCF7-41d6-B295-AB64B3B23306}']
    function Initialize(pVoid : IUnknown; pMessageHandler : TDVMessageHandler; pUserContext : Pointer; pdwMessageMask : PLongWord; dwMessageMaskElements : LongWord) : HResult; stdcall;
    function Connect(const pSoundDeviceConfig : PDVSoundDeviceConfig; const pdvClientConfig : PDVClientConfig; dwFlags : LongWord) : HResult; stdcall;
    function Disconnect(dwFlags : LongWord) : HResult; stdcall;
    function GetSessionDesc(var pvSessionDesc : TDVSessionDesc) : HResult; stdcall;
    function GetClientConfig(var pClientConfig : TDVClientConfig) : HResult; stdcall;
    function SetClientConfig(const pClientConfig : PDVClientConfig) : HResult; stdcall;
    function GetCaps(var pDVCaps : TDVCaps) : HResult; stdcall;
    function GetCompressionTypes(pData : Pointer; var pdwDataSize : LongWord; var pdwNumElements : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetTransmitTargets(pdvIDTargets : PDVID; dwNumTargets, dwFlags : LongWord) : HResult; stdcall;
    function GetTransmitTargets(pdvIDTargets : PDVID; var dwNumTargets : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function Create3DSoundBuffer(dvID : TDVID; lpdsSourceBuffer : IDirectSoundBuffer; dwPriority, dwFlags : LongWord; out lpUserBuffer : IDirectSound3DBuffer) : HResult; stdcall;
    function Delete3DSoundBuffer(dvID : TDVID; lpUserBuffer : IDirectSound3DBuffer) : HResult; stdcall;
    function SetNotifyMask(pdwMessageMask : PLongWord; dwMessageMaskElements : LongWord) : HResult; stdcall;
    function GetSoundDeviceConfig(pSoundDeviceConfig : PDVSoundDeviceConfig; var pdwSize : LongWord) : HResult; stdcall;
  end;

  IDirectPlayVoiceServer = interface (IUnknown)
    ['{FAA1C173-0468-43b6-8A2A-EA8A4F2076C9}']
    function Initialize(pVoid : IUnknown; pMessageHandler : TDVMessageHandler; pUserContext : Pointer; pdwMessageMask : PLongWord; dwMessageMaskElements : LongWord) : HResult; stdcall;
    function StartSession(const pSessionDesc : TDVSessionDesc; dwFlags : LongWord) : HResult; stdcall;
    function StopSession(dwFlags : LongWord) : HResult; stdcall;
    function GetSessionDesc(var pvSessionDesc : TDVSessionDesc) : HResult; stdcall;
    function SetSessionDesc(const pvSessionDesc : TDVSessionDesc) : HResult; stdcall;
    function GetCaps(var pDVCaps : TDVCaps) : HResult; stdcall;
    function GetCompressionTypes(pData : Pointer; var pdwDataSize : LongWord; var pdwNumElements : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetTransmitTargets(dvSource : TDVID; pdvIDTargets : PDVID; dwNumTargets, dwFlags : LongWord) : HResult; stdcall;
    function GetTransmitTargets(dvSource : TDVID; pdvIDTargets : PDVID; var dwNumTargets : LongWord; dwFlags : LongWord) : HResult; stdcall;
    function SetNotifyMask(pdwMessageMask : PLongWord; dwMessageMaskElements : LongWord) : HResult; stdcall;
  end;

  IDirectPlayVoiceTest = interface (IUnknown)
    ['{D26AF734-208B-41da-8224-E0CE79810BE1}']
    function CheckAudioSetup(pguidPlaybackDevice, pguidCaptureDevice : PGUID; hwndParent : hWND; dwFlags : LongWord) : HResult; stdcall;
  end;


(****************************************************************************
 *
 * DirectPlayVoice Interface IIDs
 *
 ****************************************************************************)
  IID_IDirectPlayVoiceClient = IDirectPlayVoiceClient;
  IID_IDirectPlayVoiceServer = IDirectPlayVoiceServer;
  IID_IDirectPlayVoiceTest   = IDirectPlayVoiceTest;


(****************************************************************************
 *
 * DirectPlayVoice CLSIDs
 *
 ****************************************************************************)
const
  CLSID_DirectPlayVoiceClient : TGUID = '{B9F3EB85-B781-4ac1-8D90-93A05EE37D7D}';
  CLSID_DirectPlayVoiceServer : TGUID = '{D3F5B8E6-9B78-4a4c-94EA-CA2397B663D3}';
  CLSID_DirectPlayVoiceTest   : TGUID = '{0F0F094B-B01C-4091-A14D-DD0CD807711A}';

(****************************************************************************
 *
 * DirectPlayVoice Compression Type GUIDs
 *
 ****************************************************************************)

// MS-ADPCM 32.8 kbit/s
//
// {699B52C1-A885-46a8-A308-97172419ADC7}
  DPVCTGUID_ADPCM      : TGUID = '{699B52C1-A885-46a8-A308-97172419ADC7}';

// Microsoft GSM 6.10 13 kbit/s
//
// {24768C60-5A0D-11d3-9BE4-525400D985E7}
  DPVCTGUID_GSM        : TGUID = '{24768C60-5A0D-11d3-9BE4-525400D985E7}';

// MS-PCM 64 kbit/s
//
// {8DE12FD4-7CB3-48ce-A7E8-9C47A22E8AC5}
  DPVCTGUID_NONE       : TGUID = '{8DE12FD4-7CB3-48ce-A7E8-9C47A22E8AC5}';

// Voxware SC03 3.2kbit/s
//
// {7D82A29B-2242-4f82-8F39-5D1153DF3E41}
  DPVCTGUID_SC03       : TGUID = '{7D82A29B-2242-4f82-8F39-5D1153DF3E41}';

// Voxware SC06 6.4kbit/s
//
// {53DEF900-7168-4633-B47F-D143916A13C7}
  DPVCTGUID_SC06       : TGUID = '{53DEF900-7168-4633-B47F-D143916A13C7}';

// TrueSpeech(TM) 8.6 kbit/s
//
// {D7954361-5A0B-11d3-9BE4-525400D985E7}
  DPVCTGUID_TRUESPEECH : TGUID = '{D7954361-5A0B-11d3-9BE4-525400D985E7}';

// Voxware VR12 1.4kbit/s
//
// {FE44A9FE-8ED4-48bf-9D66-1B1ADFF9FF6D}
  DPVCTGUID_VR12       : TGUID = '{FE44A9FE-8ED4-48bf-9D66-1B1ADFF9FF6D}';

// Define the default compression type
  DPVCTGUID_DEFAULT    : TGUID = '{7D82A29B-2242-4f82-8F39-5D1153DF3E41}'; // = DPVCTGUID_SC03

(****************************************************************************
 *
 * DirectPlayVoice Functions
 *
 ****************************************************************************)

(*)
 * This function is no longer supported.  It is recommended that CoCreateInstance be used to create
 * DirectPlay8 lobby objects.
(*)
{$IFDEF DX8}
var
  DirectPlayVoiceCreate : function(const pcIID : TGUID; out ppvInterface; pUnknown : IUnknown) : HResult; stdcall;
{$ENDIF}
(****************************************************************************
 *
 * DIRECTPLAYVOICE ERRORS
 *
 * Errors are represented by negative values and cannot be combined.
 *
 ****************************************************************************)

const
  _FACDPV                         = $15;
  MAKE_DVHRESULT                  = (1 shl 31) or (_FACDPV shl 16);

  DV_OK                           = S_OK;
  DV_FULLDUPLEX                   = (0 shl 31) or (_FACDPV shl 16) or $0005;
  DV_HALFDUPLEX                   = (0 shl 31) or (_FACDPV shl 16) or $000A;
  DV_PENDING                      = (0 shl 31) or (_FACDPV shl 16) or $0010;

  DVERR_BUFFERTOOSMALL            = MAKE_DVHRESULT + $001E ;
  DVERR_EXCEPTION                 = MAKE_DVHRESULT + $004A ;
  DVERR_GENERIC                   = E_FAIL;
  DVERR_INVALIDFLAGS              = MAKE_DVHRESULT + $0078 ;
  DVERR_INVALIDOBJECT             = MAKE_DVHRESULT + $0082 ;
  DVERR_INVALIDPARAM              = E_INVALIDARG;
  DVERR_INVALIDPLAYER             = MAKE_DVHRESULT + $0087 ;
  DVERR_INVALIDGROUP              = MAKE_DVHRESULT + $0091 ;
  DVERR_INVALIDHANDLE             = MAKE_DVHRESULT + $0096 ;
  DVERR_OUTOFMEMORY               = E_OUTOFMEMORY;
  DVERR_PENDING                   = DV_PENDING;
  DVERR_NOTSUPPORTED              = E_NOTIMPL;
  DVERR_NOINTERFACE               = E_NOINTERFACE;
  DVERR_SESSIONLOST               = MAKE_DVHRESULT + $012C ;
  DVERR_NOVOICESESSION            = MAKE_DVHRESULT + $012E ;
  DVERR_CONNECTIONLOST            = MAKE_DVHRESULT + $0168 ;
  DVERR_NOTINITIALIZED            = MAKE_DVHRESULT + $0169 ;
  DVERR_CONNECTED                 = MAKE_DVHRESULT + $016A ;
  DVERR_NOTCONNECTED              = MAKE_DVHRESULT + $016B ;
  DVERR_CONNECTABORTING           = MAKE_DVHRESULT + $016E ;
  DVERR_NOTALLOWED                = MAKE_DVHRESULT + $016F ;
  DVERR_INVALIDTARGET             = MAKE_DVHRESULT + $0170 ;
  DVERR_TRANSPORTNOTHOST          = MAKE_DVHRESULT + $0171 ;
  DVERR_COMPRESSIONNOTSUPPORTED   = MAKE_DVHRESULT + $0172 ;
  DVERR_ALREADYPENDING            = MAKE_DVHRESULT + $0173 ;
  DVERR_SOUNDINITFAILURE          = MAKE_DVHRESULT + $0174 ;
  DVERR_TIMEOUT                   = MAKE_DVHRESULT + $0175 ;
  DVERR_CONNECTABORTED            = MAKE_DVHRESULT + $0176 ;
  DVERR_NO3DSOUND                 = MAKE_DVHRESULT + $0177 ;
  DVERR_ALREADYBUFFERED	          = MAKE_DVHRESULT + $0178 ;
  DVERR_NOTBUFFERED               = MAKE_DVHRESULT + $0179 ;
  DVERR_HOSTING                   = MAKE_DVHRESULT + $017A ;
  DVERR_NOTHOSTING                = MAKE_DVHRESULT + $017B ;
  DVERR_INVALIDDEVICE             = MAKE_DVHRESULT + $017C ;
  DVERR_RECORDSYSTEMERROR         = MAKE_DVHRESULT + $017D ;
  DVERR_PLAYBACKSYSTEMERROR       = MAKE_DVHRESULT + $017E ;
  DVERR_SENDERROR                 = MAKE_DVHRESULT + $017F ;
  DVERR_USERCANCEL                = MAKE_DVHRESULT + $0180 ;
  DVERR_RUNSETUP                  = MAKE_DVHRESULT + $0183 ;
  DVERR_INCOMPATIBLEVERSION       = MAKE_DVHRESULT + $0184 ;
  DVERR_INITIALIZED               = MAKE_DVHRESULT + $0187 ;
  DVERR_INVALIDPOINTER            = E_POINTER;
  DVERR_NOTRANSPORT               = MAKE_DVHRESULT + $0188 ;
  DVERR_NOCALLBACK                = MAKE_DVHRESULT + $0189 ;
  DVERR_TRANSPORTNOTINIT          = MAKE_DVHRESULT + $018A ;
  DVERR_TRANSPORTNOSESSION        = MAKE_DVHRESULT + $018B ;
  DVERR_TRANSPORTNOPLAYER         = MAKE_DVHRESULT + $018C ;
  DVERR_USERBACK                  = MAKE_DVHRESULT + $018D ;
  DVERR_NORECVOLAVAILABLE         = MAKE_DVHRESULT + $018E ;
  DVERR_INVALIDBUFFER             = MAKE_DVHRESULT + $018F ;
  DVERR_LOCKEDBUFFER              = MAKE_DVHRESULT + $0190 ;


function DPErrorString(Value : HResult) : String;
function DVErrorString(Value : HResult) : String;

implementation

function DPErrorString(Value : HResult) : String;
begin
  case Value of
    S_OK                                   : Result := 'The operation completed successfully.';
    HResult(DPNERR_ABORTED)                : Result := 'The operation was canceled before it could be completed.';
    HResult(DPNERR_ADDRESSING)             : Result := 'The address specified is invalid.';
    HResult(DPNERR_ALREADYCONNECTED)       : Result := 'The object is already connected to the session.';
    HResult(DPNERR_ALREADYCLOSING)         : Result := 'An attempt to call the Close method on a session has been made more than once.';
    HResult(DPNERR_ALREADYDISCONNECTING)   : Result := 'The client is already disconnecting from the session.';
    HResult(DPNERR_ALREADYINITIALIZED)     : Result := 'The object has already been initialized.';
    HResult(DPNERR_BUFFERTOOSMALL)         : Result := 'The supplied buffer is not large enough to contain the requested data.';
    HResult(DPNERR_CANNOTCANCEL)           : Result := 'The operation could not be canceled.';
    HResult(DPNERR_CANTCREATEGROUP)        : Result := 'A new group cannot be created.';
    HResult(DPNERR_CANTCREATEPLAYER)       : Result := 'A new player cannot be created.';
    HResult(DPNERR_CANTLAUNCHAPPLICATION)  : Result := 'The lobby cannot launch the specified application.';
    HResult(DPNERR_CONNECTING)             : Result := 'The method is in the process of connecting to the network.';
    HResult(DPNERR_CONNECTIONLOST)         : Result := 'The service provider connection was reset while data was being sent.';
    HResult(DPNERR_DATATOOLARGE)           : Result := 'The application data is too large for the service provider''s Maximum Transmission Unit.';
    HResult(DPNERR_DOESNOTEXIST)           : Result := 'Requested element is not part of the address.';
    HResult(DPNERR_ENUMQUERYTOOLARGE)      : Result := 'The query data specified is too large.';
    HResult(DPNERR_ENUMRESPONSETOOLARGE)   : Result := 'The response to an enumeration query is too large.';
    HResult(DPNERR_EXCEPTION)              : Result := 'An exception occurred when processing the request.';
    HResult(DPNERR_GENERIC)                : Result := 'An undefined error condition occurred.';
    HResult(DPNERR_GROUPNOTEMPTY)          : Result := 'The specified group is not empty.';
    HResult(DPNERR_HOSTREJECTEDCONNECTION) : Result := 'The DPN_MSGID_INDICATE_CONNECT system message returned something other than S_OK in response to a connect request.';
    HResult(DPNERR_HOSTTERMINATEDSESSION)  : Result := 'The host in a peer session (with host migration enabled) terminated the session.';
    HResult(DPNERR_INCOMPLETEADDRESS)      : Result := 'The address specified is not complete.';
    HResult(DPNERR_INVALIDADDRESSFORMAT)   : Result := 'Address format is invalid.';
    HResult(DPNERR_INVALIDAPPLICATION)     : Result := 'The GUID supplied for the application is invalid.';
    HResult(DPNERR_INVALIDCOMMAND)         : Result := 'The command specified is invalid.';
    HResult(DPNERR_INVALIDDEVICEADDRESS)   : Result := 'The address for the local computer or adapter is invalid.';
    HResult(DPNERR_INVALIDFLAGS)           : Result := 'The flags passed to this method are invalid.';
    HResult(DPNERR_INVALIDGROUP)           : Result := 'The group ID is not recognized as a valid group ID for this game session.';
    HResult(DPNERR_INVALIDHANDLE)          : Result := 'The handle specified is invalid.';
    HResult(DPNERR_INVALIDHOSTADDRESS)     : Result := 'The specified remote address is invalid.';
    HResult(DPNERR_INVALIDINSTANCE)        : Result := 'The GUID for the application instance is invalid.';
    HResult(DPNERR_INVALIDINTERFACE)       : Result := 'The interface parameter is invalid. This value will be returned in a connect request if the connecting player was not a client in a client/server game or a peer in a peer-to-peer game.';
    HResult(DPNERR_INVALIDOBJECT)          : Result := 'The DirectPlay object pointer is invalid.';
    HResult(DPNERR_INVALIDPARAM)           : Result := 'One or more of the parameters passed to the method are invalid.';
    HResult(DPNERR_INVALIDPASSWORD)        : Result := 'An invalid password was supplied when attempting to join a session that requires a password.';
    HResult(DPNERR_INVALIDPLAYER)          : Result := 'The player ID is not recognized as a valid player ID for this game session.';
    HResult(DPNERR_INVALIDPOINTER)         : Result := 'Pointer specified as a parameter is invalid.';
    HResult(DPNERR_INVALIDPRIORITY)        : Result := 'The specified priority is not within the range of allowed priorities, which is inclusively from 0 through 65535.';
    HResult(DPNERR_INVALIDSTRING)          : Result := 'String specified as a parameter is invalid.';
    HResult(DPNERR_INVALIDURL)             : Result := 'Specified string is not a valid DirectPlay URL.';
    HResult(DPNERR_INVALIDVERSION)         : Result := 'There was an attempt to connect to an invalid version of DirectPlay.';
    HResult(DPNERR_NOCAPS)                 : Result := 'The communication link that DirectPlay is attempting to use is not capable of this function.';
    HResult(DPNERR_NOCONNECTION)           : Result := 'No communication link was established.';
    HResult(DPNERR_NOHOSTPLAYER)           : Result := 'There is currently no player acting as the host of the session.';
    HResult(DPNERR_NOINTERFACE)            : Result := 'The interface is not supported.';
    HResult(DPNERR_NORESPONSE)             : Result := 'There was no response from the specified target.';
    HResult(DPNERR_NOTALLOWED)             : Result := 'Object is read-only; this function is not allowed on this object.';
    HResult(DPNERR_NOTHOST)                : Result := 'An attempt by the client to connect to a nonhost computer. Additionally, this error value may be returned by a nonhost that tries to set the application description.';
    HResult(DPNERR_OUTOFMEMORY)            : Result := 'There is insufficient memory to perform the requested operation.';
    HResult(DPNERR_PENDING)                : Result := 'Not an error, this return indicates that an asynchronous operation has reached the point where it is successfully queued. SUCCEEDED(HResult(DPNERR_PENDING) will return TRUE. '+'This error value has been superseded by HResult(DPNERR_SUCCESS, which should be used by all new applications. HResult(DPNERR_PENDING is only included for backward compatibility.';
    HResult(DPNERR_PLAYERLOST)             : Result := 'A player has lost the connection to the session.';
    HResult(DPNERR_PLAYERNOTREACHABLE)     : Result := 'A player has tried to join a peer-peer session where at least one other existing player in the session cannot connect to the joining player.';
    HResult(DPNERR_SESSIONFULL)            : Result := 'The request to connect to the host or server failed because the maximum number of players allotted for the session has been reached.';
    HResult(DPNERR_TIMEDOUT)               : Result := 'The operation could not complete because it has timed out.';
    HResult(DPNERR_UNINITIALIZED)          : Result := 'The requested object has not been initialized.';
    HResult(DPNERR_UNSUPPORTED)            : Result := 'The function or feature is not available in this implementation or on this service provider.';
    HResult(DPNERR_USERCANCEL)             : Result := 'The user canceled the operation.';
    else Result := DVErrorString(Value);
  end;

end;

function DVErrorString(Value : HResult) : String;
begin
  case Value of
    DV_OK                                  : Result := 'The request completed successfully.';
    HResult(DV_FULLDUPLEX)                 : Result := 'The sound card is capable of full-duplex operation.';
    HResult(DV_HALFDUPLEX)                 : Result := 'The sound card can only be run in half-duplex mode.';
    HResult(DVERR_BUFFERTOOSMALL)          : Result := 'The supplied buffer is not large enough to contain the requested data.';
    HResult(DVERR_EXCEPTION)               : Result := 'An exception occurred when processing the request.';
    HResult(DVERR_GENERIC)                 : Result := 'An undefined error condition occurred.';
    HResult(DVERR_INVALIDFLAGS)            : Result := 'The flags passed to this method are invalid.';
    HResult(DVERR_INVALIDOBJECT)           : Result := 'The DirectPlay object pointer is invalid.';
    HResult(DVERR_INVALIDPARAM)            : Result := 'One or more of the parameters passed to the method are invalid.';
    HResult(DVERR_INVALIDPLAYER)           : Result := 'The player ID is not recognized as a valid player ID for this game session.';
    HResult(DVERR_INVALIDGROUP)            : Result := 'The group ID is not recognized as a valid group ID for this game session.';
    HResult(DVERR_INVALIDHANDLE)           : Result := 'The handle specified is invalid.';
    HResult(DVERR_OUTOFMEMORY)             : Result := 'There is insufficient memory to perform the requested operation.';
    HResult(DVERR_PENDING)                 : Result := 'Not an error, this return indicates that an asynchronous operation has reached the point where it is successfully queued.';
    HResult(DVERR_NOTSUPPORTED)            : Result := 'The operation is not supported.';
    HResult(DVERR_NOINTERFACE)             : Result := 'The specified interface is not supported. Could indicate using the wrong version of DirectPlay.';
    HResult(DVERR_SESSIONLOST)             : Result := 'The transport has lost the connection to the session.';
    HResult(DVERR_NOVOICESESSION)          : Result := 'The session specified is not a voice session.';
    HResult(DVERR_CONNECTIONLOST)          : Result := 'The connection to the voice session has been lost.';
    HResult(DVERR_NOTINITIALIZED)          : Result := 'The IDirectPlayVoiceClient::Initialize or IDirectPlayVoiceServer::Initialize method must be called before calling this method.';
    HResult(DVERR_CONNECTED)               : Result := 'The DirectPlayVoice object is connected.';
    HResult(DVERR_NOTCONNECTED)            : Result := 'The DirectPlayVoice object is not connected.';
    HResult(DVERR_CONNECTABORTING)         : Result := 'The connection is being disconnected.';
    HResult(DVERR_NOTALLOWED)              : Result := 'The object does not have the permission to perform this operation.';
    HResult(DVERR_INVALIDTARGET)           : Result := 'The specified target is not a valid player ID or group ID for this voice session.';
    HResult(DVERR_TRANSPORTNOTHOST)        : Result := 'The object is not the host of the voice session.';
    HResult(DVERR_COMPRESSIONNOTSUPPORTED) : Result := 'The specified compression type is not supported on the local computer.';
    HResult(DVERR_ALREADYPENDING)          : Result := 'An asynchronous call of this type is already pending.';
//    HResult(DVERR_ALREADYINITIALIZED)      : Result := 'The object has already been initialized.';
    HResult(DVERR_SOUNDINITFAILURE)        : Result := 'A failure was encountered initializing the sound card.';
    HResult(DVERR_TIMEOUT)                 : Result := 'The operation could not be performed in the specified time.';
    HResult(DVERR_CONNECTABORTED)          : Result := 'The connect operation was canceled before it could be completed.';
    HResult(DVERR_NO3DSOUND)               : Result := 'The local computer does not support 3-D sound.';
    HResult(DVERR_ALREADYBUFFERED)         : Result := 'There is already a user buffer for the specified ID.';
    HResult(DVERR_NOTBUFFERED)             : Result := 'There is no user buffer for the specified ID.';
    HResult(DVERR_HOSTING)                 : Result := 'The object is the host of the session.';
    HResult(DVERR_NOTHOSTING)              : Result := 'The object is not the host of the session.';
    HResult(DVERR_INVALIDDEVICE)           : Result := 'The specified device is invalid.';
    HResult(DVERR_RECORDSYSTEMERROR)       : Result := 'An error in the recording system occurred.';
    HResult(DVERR_PLAYBACKSYSTEMERROR)     : Result := 'An error in the playback system occurred.';
    HResult(DVERR_SENDERROR)               : Result := 'An error occurred while sending data.';
    HResult(DVERR_USERCANCEL)              : Result := 'The user canceled the operation.';
//    HResult(DVERR_UNKNOWN)                 : Result := 'An unknown error occurred.';
    HResult(DVERR_RUNSETUP)                : Result := 'The specified audio configuration has not been tested. Call the IDirectPlayVoiceTest::CheckAudioSetup method.';
    HResult(DVERR_INCOMPATIBLEVERSION)     : Result := 'The client connected to a voice session that is incompatible with the host.';
    HResult(DVERR_INITIALIZED)             : Result := 'The Initialize method failed because the object has already been initialized.';
    HResult(DVERR_INVALIDPOINTER)          : Result := 'The pointer specified is invalid.';
    HResult(DVERR_NOTRANSPORT)             : Result := 'The specified object is not a valid transport.';
    HResult(DVERR_NOCALLBACK)              : Result := 'This operation cannot be performed because no callback function was specified.';
    HResult(DVERR_TRANSPORTNOTINIT)        : Result := 'Specified transport is not yet initialized.';
    HResult(DVERR_TRANSPORTNOSESSION)      : Result := 'Specified transport is valid but is not connected/hosting.';
    HResult(DVERR_TRANSPORTNOPLAYER)       : Result := 'Specified transport is connected/hosting but no local player exists.';
    else Result := 'Unknown Error';
  end;
end;

initialization
begin
{$IFDEF DX8}
  DPlayDLL := LoadLibrary('dpnet.dll');
  DPlayDLLAddr := LoadLibrary('dpnaddr.dll');
  DPlayDLLLobby := LoadLibrary('dpnlobby.dll');
  DPlayDLLVoice := LoadLibrary('dpvoice.dll');

  DirectPlay8Create := GetProcAddress(DPlayDLL, 'DirectPlay8Create');
  DirectPlay8AddressCreate := GetProcAddress(DPlayDLLAddr, 'DirectPlay8AddressCreate');
  DirectPlay8LobbyCreate := GetProcAddress(DPlayDLLLobby, 'DirectPlay8LobbyCreate');
  DirectPlayVoiceCreate := GetProcAddress(DPlayDLLVoice, 'DirectPlayVoiceCreate');
{$ENDIF}
end;

finalization
begin
{$IFDEF DX8}
  if DPlayDLL <> 0 then FreeLibrary(DPlayDLL);
  if DPlayDLLAddr <> 0 then FreeLibrary(DPlayDLLAddr);
  if DPlayDLLLobby <> 0 then FreeLibrary(DPlayDLLLobby);
  if DPlayDLLVoice <> 0 then FreeLibrary(DPlayDLLVoice);
{$ENDIF}
end;

end.
