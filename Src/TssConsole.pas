{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Console Unit                           *
 *  (C) Aukiogames 2003                    *
(*-----------------------------------------*}

unit TssConsole;

interface

uses
  Windows, TssControls, DirectInput8, Direct3D8, D3DX8, TssUtils, Math,
  SysUtils, Classes, {TypInfo,} TssFiles{, ClipBrd}, TssScript,
  G2Types, G2Script;

const
  ConsoleBufferSize = 256; // Lines of text

type
  {TTssFunc1 = function: Boolean of object;
  TTssFunc2 = function(Params: string): Boolean of object;
  TCommand = packed record
    Name: string[31];
    Func1: TTssFunc1;
    Func2: TTssFunc2;
  end;
  PCommands = ^TCommands;
  TCommands = array[0..0] of TCommand;}

  {TObjArrayItem = packed record
    Name: string[31];
    Obj: TPersistent;
  end;
  PObjArrayItems = ^TObjArrayItems;
  TObjArrayItems = array[0..0] of TObjArrayItem;
  TObjectArray = class(TPersistent)
  private
    Count, Size: integer;
    Items: PObjArrayItems;
  public
    procedure SetSize(ACount: integer);
    procedure Add(const Name: string; Obj: TPersistent);
    destructor Destroy; override;
  end;}
  
  TTssConsole = class(TObject)
  private
    FBuffer, FOldCommands: TStringList;
    FCommandIndex: integer;
    FVisible: Boolean;
    FBlinkTime: Single;
    FCursorPos: integer;
    FCommandStr: string;
    //FCommandCount: integer;
    //FCommands: PCommands;
    FTickCount: TG2Variant;
    FInfo: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    procedure MoveScripts(TickCount: Single);
    procedure Draw;
    procedure ExecuteCommand(Add: Boolean; const Text: string);
    procedure Add(const Text: string);
    //function Add(Params: string): Boolean;
    //procedure AddCommand(const Name: string; Func: TTssFunc1); overload;
    //procedure AddCommand(const Name: string; Func: TTssFunc2); overload;
    //procedure RemoveCommand(const Name: string);
    procedure WriteCommand(KeyVk: Cardinal; KeyChr: Char);
    //function Help(Params: string): Boolean;
    //function GetProp(Params: string): Boolean;
    //function SetProp(Params: string): Boolean;
  end;

  {TTssScripts = class;
  TTssScript = class(TObject)
  private
    FName: string;
    FOwner: TTssScripts;
    FData: TStrings;
  public
    constructor Create(AOwner: TTssScripts; const FileName: string);
    destructor Destroy; override;
    property Name: string read FName;
  end;
  TTssScripts = class(TObject)
  private
    FScriptFile: TTssFilePack;
    FScripts: TList;
  public
    constructor Create(const Path, FileName: string);
    destructor Destroy; override;
    procedure Move(TickCount: Single);
    function Run(Params: string): Boolean;
  end;}

//function GetNextStr(var S: string): string;

implementation

uses
  TssEngine;

constructor TTssConsole.Create;
begin
 inherited Create;
 FBuffer:=TStringList.Create;
 FOldCommands:=TStringList.Create;
 FCursorPos:=0;
 FInfo:=True;
 FTickCount:=G2Var(0.0);
 //Add('Console Initialized.');
 //Add('Type "/help" for more info.');
 //AddCommand('Help', Help);
 //AddCommand('Get', GetProp);
 //AddCommand('Set', SetProp);
 //AddCommand('Echo', Add);
end;

{destructor TObjectArray.Destroy;
begin
 if Count>0 then FreeMem(Items);
 inherited;
end;

procedure TObjectArray.SetSize(ACount: integer);
begin
 Size:=ACount;
 ReAllocMem(Items, Size*SizeOf(TObjArrayItem));
end;

procedure TObjectArray.Add(const Name: string; Obj: TPersistent);
begin
 if Count>=Size then begin
  ReAllocMem(Items, (Count+1)*SizeOf(TObjArrayItem));
  Size:=Count+1;
 end;
 Items[Count].Name:=Name;
 Items[Count].Obj:=Obj;
 Inc(Count);
end;}

{function GetObjectPropEx(Obj: TObject; const Name: string): TObject;
var I: integer;
begin
 if Obj is TObjectArray then begin
  Result:=nil; 
  if Name='' then begin Obj.Free; Exit; end;
  if Name[1]='[' then begin
   I:=Pos(']', Name);
   Result:=TObjectArray(Obj).Items[StrToIntDef(Copy(Name, 2, I-2), 0)].Obj;
  end else for I:=0 to TObjectArray(Obj).Count-1 do
   if AnsiLowerCase(TObjectArray(Obj).Items[I].Name)=Name then begin
    Result:=TObjectArray(Obj).Items[I].Obj;
    Obj.Free;
    Exit;
   end;
  Obj.Free;
 end else begin
  if GetPropInfo(Obj, Name)=nil then Result:=nil
   else Result:=GetObjectProp(Obj, Name);
 end;
end;

function StrGetParent(var ObjName: string): TObject;
var I: integer;
begin
 Result:=nil;
 if (ObjName='') then Exit
  else if (ObjName[1]='.') then Delete(ObjName, 1, 1) else Exit;
 Result:=Engine;
 I:=Pos('.', ObjName);
 while I>0 do begin
  Result:=GetObjectPropEx(Result, AnsiLowerCase(Copy(ObjName, 1, I-1)));
  Delete(ObjName, 1, I);
  if Result=nil then Break;
  I:=Pos('.', ObjName);
 end;
end;

function TTssConsole.GetProp(Params: string): Boolean;
var S, S2: string;
    Obj: TObject;
begin
 S2:=GetNextStr(Params);
 S:=AnsiLowerCase(S2);
 Obj:=StrGetParent(S);
 if Obj=nil then Add('Invalid Property!')
 else if GetPropInfo(Obj, S)<>nil then
 case GetPropInfo(Obj, S).PropType^.Kind of
  tkFloat: Add(Format('%s = %.5f', [S2, GetFloatProp(Obj, S)]));
  tkEnumeration: Add(Format('%s = %s', [S2, GetEnumProp(Obj, S)]));
  tkClass: begin
    Obj:=GetObjectProp(Obj, S);
    if Obj=nil then Add(Format('%s = nil', [S2]))
     else Add(Format('%s = %s', [S2, Obj.ClassName]));
  end;
  else Add('Invalid Property!');
 end else Add('Invalid Property!');
 Result:=False;
end;

function TTssConsole.SetProp(Params: string): Boolean;
  function GetFloatValue(S: string): Extended;
  var Obj: TObject;
  begin
   Result:=0.0;
   if S<>'' then if S[1]='.' then begin
    Obj:=StrGetParent(S);
    if Obj=nil then Add('Invalid Property!')
     else if GetPropInfo(Obj, S)=nil then Add('Invalid Property!')
      else Result:=GetFloatProp(Obj, S);
   end else Result:=StrToFloatDef(S, 0.0);
  end;
  function GetObjectValue(S: string): TObject;
  var Obj: TObject;
  begin
   Result:=nil;
   if S<>'' then if S[1]='.' then begin
    Obj:=StrGetParent(S);
    if Obj=nil then Add('Invalid Property!')
     else Result:=GetObjectPropEx(Obj, S);
   end;
  end;
  function GetBooleanValue(S: string): string;
  var Obj: TObject;
      Change: Boolean;
  begin
   Result:='False';
   Change:=False;
   if S<>'' then begin
    if S[1]='!' then begin Delete(S, 1, 1); Change:=True; end;
    if S[1]='.' then begin
     Obj:=StrGetParent(S);
     if Obj=nil then Add('Invalid Property!')
      else if GetPropInfo(Obj, S)=nil then Add('Invalid Property!')
       else Result:=GetEnumProp(Obj, S);
    end else if (AnsiLowerCase(S)='true') or (S='1') then Result:='True';
   end;
   if Change then if AnsiLowerCase(Result)='true' then Result:='False' else Result:='True';
  end;
var S, S2: string;
    Obj: TObject;
begin
 S2:=GetNextStr(Params);
 S:=AnsiLowerCase(S2);
 Obj:=StrGetParent(S);
 if Obj=nil then Add('Invalid Property!')
 else if GetPropInfo(Obj, S)<>nil then
 case GetPropInfo(Obj, S).PropType^.Kind of
  tkFloat: begin
    SetFloatProp(Obj, S, GetFloatValue(GetNextStr(Params)));
    if FInfo then Add(S2+' Updated');
  end;
  tkEnumeration: begin
    SetEnumProp(Obj, S, GetBooleanValue(GetNextStr(Params)));
    if FInfo then Add(S2+' Updated');
  end;
  tkClass: begin
    SetObjectProp(Obj, S, GetObjectValue(GetNextStr(Params)));
    if FInfo then Add(S2+' Updated');
    //Add('Cannot Set Class Property!');
  end;
  else Add('Invalid Property!');
 end else Add('Invalid Property!');
 Result:=False;
end;

function TTssConsole.Help(Params: string): Boolean;
  procedure EnumClass(Obj: TObject);
  var PropList: PPropList;
      I, Count: integer;
  begin
   if Obj is TObjectArray then begin
    for I:=0 to TObjectArray(Obj).Count-1 do
     Add('  .['+IntToStr(I)+']  .'+TObjectArray(Obj).Items[I].Name);
    Obj.Free;
   end else begin
    New(PropList);
    Count:=GetPropList(Obj.ClassType.ClassInfo, tkAny, PropList, True);
    for I:=0 to Count-1 do
     if PropList^[I]^.PropType^.Kind=tkClass then Add('  .'+PropList^[I]^.Name)
      else Add('  .'+PropList^[I]^.Name+': '+PropList^[I]^.PropType^.Name);
    Dispose(PropList);
   end;
  end;
var I: integer;
    S: string;
    Obj: TObject;
begin
 S:=AnsiLowerCase(GetNextStr(Params));
 if S='-c' then begin
  Add('Commands:');
  Add('----------------------');
  for I:=0 to FCommandCount-1 do
   Add('  /'+FCommands[I].Name);
  Add('----------------------');
 end else if S='-p' then begin
  Add('Properties:');
  Add('----------------------');
  EnumClass(Engine);
  Add('----------------------');
 end else if S<>'' then begin
  Add('Properties of '+S+':');
  Add('----------------------');
  Obj:=StrGetParent(S);
  if Obj<>nil then begin
   Obj:=GetObjectPropEx(Obj, S);
   if Obj<>nil then EnumClass(Obj);
  end;
  Add('----------------------');
 end else begin
  Add('Type "/help -c" to see available commands.');
  Add('Type "/help -p" to see available properties.');
  Add('Type "/help .<name>" to see info about a property.');
  Add('Refer property of property as ".<name1>.<name2>"');
 end;
 Result:=False;
end; }

destructor TTssConsole.Destroy;
begin
 FTickCount.Free;
 FBuffer.Free;
 FOldCommands.Free;
 //FreeMem(FCommands);
 inherited;
end;

{function GetNextStr(var S: string): string;
var I: integer;
begin
 I:=Pos(' ', S);
 if I<=0 then I:=Length(S)+1;
 Result:=Copy(S, 1, I-1);
 Delete(S, 1, I);
end;

procedure TTssConsole.AddCommand(const Name: string; Func: TTssFunc1);
begin
 Inc(FCommandCount);
 ReAllocMem(FCommands, SizeOf(TCommand)*FCommandCount);
 FCommands[FCommandCount-1].Name:=AnsiLowerCase(Name);
 FCommands[FCommandCount-1].Func1:=Func;
 FCommands[FCommandCount-1].Func2:=nil;
end;
procedure TTssConsole.AddCommand(const Name: string; Func: TTssFunc2);
begin
 Inc(FCommandCount);
 ReAllocMem(FCommands, SizeOf(TCommand)*FCommandCount);
 FCommands[FCommandCount-1].Name:=AnsiLowerCase(Name);
 FCommands[FCommandCount-1].Func1:=nil;
 FCommands[FCommandCount-1].Func2:=Func;
end;

procedure TTssConsole.RemoveCommand(const Name: string);
var S: string;
    I: integer;
begin
 S:=AnsiLowerCase(Name);
 for I:=0 to FCommandCount-1 do
  if FCommands[I].Name=S then begin
   FCommands[I]:=FCommands[FCommandCount-1];
   Dec(FCommandCount);
   ReAllocMem(FCommands, SizeOf(TCommand)*FCommandCount);
   Exit;
  end;
end;}

procedure TTssConsole.ExecuteCommand(Add: Boolean; const Text: string);
begin
 if Text='' then Exit;
 if Add then begin
  if FOldCommands.Count>=ConsoleBufferSize then FOldCommands.Delete(0);
  FOldCommands.Add(Text);
 end;
 Engine.Script.RunCommand(Text);
end;

{procedure TTssConsole.ExecuteCommand(const Text: string);
var Command: string;
    I, J, K: integer;
    B: Boolean;
begin
 if Text='' then Exit;
 if Text[1]<>'/' then Exit;
 I:=Pos(' ', Text);
 if I<=0 then I:=Length(Text)+1;
 if FInfo then begin
  if FOldCommands.Count>=ConsoleBufferSize then FOldCommands.Delete(0);
  FOldCommands.Add(Text);
 end;
 Command:=AnsiLowerCase(Copy(Text, 2, I-2));
 for J:=0 to FCommandCount-1 do
  if FCommands[J].Name=Command then begin
   B:=True;
   K:=FBuffer.Count;
   if Assigned(FCommands[J].Func1) then B:=FCommands[J].Func1;
   if Assigned(FCommands[J].Func2) then B:=FCommands[J].Func2(Copy(Text, I+1, Length(Text)-I));
   if (not B) and FInfo then begin
    if FBuffer.Count>=ConsoleBufferSize then FBuffer.Delete(0);
    FBuffer.Insert(K, '>> '+Copy(Text, 2, Length(Text)-1));
   end;
   Exit;
  end;
 Add('Invalid Command!');
end;}

procedure TTssConsole.Move(TickCount: Single);
//var I: integer;
begin
 Engine.Controls.Enabled:=True;
 if Engine.Controls.DIKKeyDown(DIK_F11, -1) or Engine.Controls.DIKKeyDown(DIK_F12, -1) then begin
  //EnumClass(Engine.ClassType);
  FVisible:=not FVisible;
  if FVisible then Engine.KeyDown:=WriteCommand else Engine.KeyDown:=nil;
 end;

 if FVisible then begin
  FBlinkTime:=FBlinkTime+TickCount*0.001;
  if FBlinkTime>=1.0 then FBlinkTime:=FBlinkTime-1.0;
  Engine.Controls.Enabled:=False;
 end;
end;

procedure TTssConsole.WriteCommand(KeyVk: Cardinal; KeyChr: Char);
begin
 case KeyVk of
  vk_Delete: begin
   Delete(FCommandStr, FCursorPos+1, 1);
   FCursorPos:=Min(Length(FCommandStr), FCursorPos);
  end;
  vk_Back: begin
   Delete(FCommandStr, FCursorPos, 1);
   FCursorPos:=Max(0, FCursorPos-1);
  end;
  vk_Left: FCursorPos:=Max(0, FCursorPos-1);
  vk_Right: FCursorPos:=Min(Length(FCommandStr), FCursorPos+1);
  vk_Up: begin
   if FCommandIndex<0 then FCommandIndex:=FOldCommands.Count-1
    else FCommandIndex:=FCommandIndex-1;
   if (FCommandIndex<FOldCommands.Count) and (FCommandIndex>=0) then FCommandStr:=FOldCommands[FCommandIndex]
    else FCommandStr:='';
  end;
  vk_Down: begin
   if FCommandIndex>=FOldCommands.Count then FCommandIndex:=0
    else FCommandIndex:=FCommandIndex+1;
   if (FCommandIndex<FOldCommands.Count) and (FCommandIndex>=0) then FCommandStr:=FOldCommands[FCommandIndex]
    else FCommandStr:=''; 
  end;
  vk_Return: begin
   if FCommandStr<>'' then ExecuteCommand(True, FCommandStr);
   //if FCommandStr<>'' then if FCommandStr[1]='/' then ExecuteCommand(FCommandStr)
   // else ExecuteCommand('/Say '+FCommandStr);
   FCommandStr:='';
   FCommandIndex:=FOldCommands.Count;
  end;
  0: if (KeyChr=' ') or (Engine.Textures.Fonts[0].Letters[KeyChr].Width>0) then begin
   Insert(KeyChr, FCommandStr, FCursorPos+1);
   FCursorPos:=Min(Length(FCommandStr), FCursorPos+1);
  end;
 end;
end;

procedure TTssConsole.Draw;
var I: integer;
    S: string;
    Vertices: array[0..3] of T2DVertex;
    CursorOffset: Single;
begin
 if FVisible then begin
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TFACTOR);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TFACTOR);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(128, 0, 0, 0));
  Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
  Vertices[0]:=Make2DVertex(Engine.vp.Width*0.15, Engine.vp.Width*0.15, 0.9, 1.0, 0.0, 0.0);
  Vertices[1]:=Make2DVertex(Engine.vp.Width*0.85, Engine.vp.Width*0.15, 0.9, 1.0, 1.0, 0.0);
  Vertices[2]:=Make2DVertex(Engine.vp.Width*0.15, Engine.vp.Width*0.60, 0.9, 1.0, 0.0, 1.0);
  Vertices[3]:=Make2DVertex(Engine.vp.Width*0.85, Engine.vp.Width*0.60, 0.9, 1.0, 1.0, 1.0);
  Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex));
  Engine.IncPolyCounter(2);
  if FBlinkTime<0.5 then begin
   CursorOffset:=Engine.Textures.TextWidth(0, 0.02, 0.0, Copy(FCommandStr, 1, FCursorPos));
   Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(192, 255, 255, 255));
   Engine.m_pd3dDevice.SetVertexShader(D3DFVF_TSSVERTEX_2D);
   Vertices[0]:=Make2DVertex(Engine.vp.Width*(0.199+CursorOffset), Engine.vp.Width*0.535, 0.9, 1.0, 0.0, 0.0);
   Vertices[1]:=Make2DVertex(Engine.vp.Width*(0.201+CursorOffset), Engine.vp.Width*0.535, 0.9, 1.0, 1.0, 0.0);
   Vertices[2]:=Make2DVertex(Engine.vp.Width*(0.199+CursorOffset), Engine.vp.Width*0.555, 0.9, 1.0, 0.0, 1.0);
   Vertices[3]:=Make2DVertex(Engine.vp.Width*(0.201+CursorOffset), Engine.vp.Width*0.555, 0.9, 1.0, 1.0, 1.0);
   Engine.m_pd3dDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Vertices, SizeOf(T2DVertex));
   Engine.IncPolyCounter(2);
  end;
  S:='';
  for I:=Max(0, FBuffer.Count-16) to FBuffer.Count-1 do begin
   if S<>'' then S:=S+#13;
   S:=S+FBuffer[I];
  end;           
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(255, 255, 255, 255));
  Engine.Textures.DrawText2D(0, 0.20, 0.525-Min(16, FBuffer.Count)*0.02, 0.0, 0.0, 0.02, 0.02, S);
  Engine.m_pd3dDevice.SetRenderState(D3DRS_TEXTUREFACTOR, D3DCOLOR_ARGB(255, 255, 128, 128));
  Engine.Textures.DrawText2D(0, 0.20, 0.535, 0.0, 0.0, 0.02, 0.02, FCommandStr);
  Engine.m_pd3dDevice.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
 end;
end;

procedure TTssConsole.Add(const Text: string);
begin
 if FBuffer.Count>=ConsoleBufferSize then FBuffer.Delete(0);
 FBuffer.Add(Text);
end;

{constructor TTssScripts.Create(const Path, FileName: string);
begin
 inherited Create;
 FScriptFile:=TTssFilePack.Create(Path, FileName, Options.LockData, Options.PreferPacked);
 FScripts:=TList.Create;
 Engine.Console.AddCommand('Run', Run);
end;

destructor TTssScripts.Destroy;
var I: integer;
begin
 for I:=FScripts.Count-1 downto 0 do
  TTssScript(FScripts.Items[I]).Free;
 FScripts.Free;
 FScriptFile.Free;
 Engine.Console.RemoveCommand('Run');
 inherited;
end;

procedure TTssScripts.Move(TickCount: Single);
begin
 //
end;

function TTssScripts.Run(Params: string): Boolean;
var I: integer;
begin
 Result:=Engine.Console.FInfo;
 Engine.Console.FInfo:=False;
 with TTssScript.Create(Self, Params) do begin
  for I:=0 to FData.Count-1 do
   Engine.Console.ExecuteCommand(FData[I]);
  Free;
 end;
 Engine.Console.FInfo:=Result;
 if Result then Engine.Console.Add('Script '+Params+' executed');
 Result:=False;
end;

constructor TTssScript.Create(AOwner: TTssScripts; const FileName: string);
var Data: PChar;
begin
 inherited Create;
 FOwner:=AOwner;
 FOwner.FScripts.Add(Self);
 FData:=TStringList.Create;
 if FOwner.FScriptFile.LoadToMemByName(FileName, Pointer(Data))=0 then Engine.Console.Add('Erroneus script: '+FileName);
 FData.Text:=Data;
 FreeMem(Data);
end;

destructor TTssScript.Destroy;
begin
 FData.Free;
 FOwner.FScripts.Remove(Self);
 inherited;
end;}

procedure TTssConsole.MoveScripts(TickCount: Single);
var I: integer;
begin
 FTickCount.Float:=TickCount;
 //Engine.Script.Event(Integer(seFrame), [FTickCount.Reference]);
 for I:=Engine.FTimers.Count-1 downto 0 do
  with TTssTimer(Engine.FTimers[I]) do begin
   Time:=Time-TickCount*0.001;
   if Time<=0.0 then begin
    Engine.Script.RunCommand(Action);
    Free;
    Engine.FTimers.Delete(I);
   end;
  end;
end;

end.
