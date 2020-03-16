unit GScript;

interface

uses
  GTypes, GConsts, GCompiler, GBlocks, GVariants, Classes, SysUtils, Math,

  GCore, GInOut, GMath, GUtils;

type
  TGScript = class(TGCustomScript)
  protected
    FSrc: TGCustomBlock;
    FFunctions: TGArray;
    FVariables: TGArray;
    FName: string;
    FModules: array of TGCustomModule;
    function GetResult: TGCustomVariant; override;
  public
    constructor Create; overload;
    constructor Create(const Name: string); overload;
    destructor Destroy; override;
    function SetSrc(const Src: string): Boolean; overload;
    function SetSrc(Src: TGCustomBlock): Boolean; overload;
    function SetCommand(const Src: string): Boolean; 
    function Error(Id: Cardinal; const S: string; Sender: TGCustomBlock): Boolean; override;
    function Execute(ResultType: TGResultTypes): Boolean; override;
    function GetFunction(const Name: string): TGFunction; override;
    function GetVariable(const Name: string): TGCustomVariant; override;
    procedure SetVariable(const Name: string; Item: TGCustomVariant); override;
    procedure UnsetVariable(const Name: string); override;
    function LoadModule(Module: TGModuleClass): TGCustomModule; override;
    procedure RegisterFunction(const Name: string; Item: TGFunction); override;
    procedure UnregisterFunction(const Name: string); override;
    property Name: string read FName;
    property Variables: TGArray read FVariables;
    property Src: TGCustomBlock read FSrc;
  end;

implementation

{ TGScript }

constructor TGScript.Create;
var I: integer;
begin
 inherited Create;
 FFunctions:=TGArray.Create(SizeOf(TGFunction));
 FVariables:=TGArray.Create(SizeOf(TGCustomVariant));
 FAbstractSrc:=TGBContainer.Create(Self);
 SetLength(FModules, GDefaultModuleCount);
 for I:=0 to GDefaultModuleCount-1 do
  FModules[I]:=GDefaultModule(I).Create(Self);
end;

constructor TGScript.Create(const Name: string);
begin
 Create;
 FName:=Name;
end;

destructor TGScript.Destroy;
var I: integer;
    Item: TGCustomVariant;
begin
 FAbstractSrc.Free;
 for I:=0 to FVariables.Count-1 do
  if FVariables.GetItem(I, Item) then if not Item.Temp then Item.Free;
 FreeAndNil(FSrc);
 for I:=High(FModules) downto Low(FModules) do
  FModules[I].Free;
 FVariables.Free;
 FFunctions.Free;
 inherited;
end;                  

function TGScript.Execute(ResultType: TGResultTypes): Boolean;
begin
 if FSrc<>nil then begin
  FAbstractSrc.Free;
  FAbstractSrc:=TGBContainer.Create(Self);
  Result:=FSrc.Execute(ResultType);
 end else Result:=False;
end;

function TGScript.SetSrc(const Src: string): Boolean;
var Compiler: TGCompiler;
begin
 FAbstractSrc.Free;
 FAbstractSrc:=TGBContainer.Create(Self);
 FreeAndNil(FSrc);
 if Src='' then Result:=True
  else begin
   Compiler:=TGCompiler.Create(Self, Self);
   Result:=Compiler.Compile(Src, FSrc);
   Compiler.Free;
  end;
end;

function TGScript.SetCommand(const Src: string): Boolean;
var Compiler: TGCompiler;
begin
 FreeAndNil(FSrc);
 if Src='' then Result:=True
  else begin
   Compiler:=TGCompiler.Create(Self, Self);
   Result:=Compiler.Compile(Src, FSrc);
   Compiler.Free;
  end;
end;

function TGScript.SetSrc(Src: TGCustomBlock): Boolean;
begin
 FAbstractSrc.Free;
 FAbstractSrc:=TGBContainer.Create(Self);
 FreeAndNil(FSrc);
 FSrc:=Src;
 Result:=True;
end;

function TGScript.GetResult: TGCustomVariant;
begin
 if FSrc<>nil then Result:=FSrc.Result
  else Result:=nil;
end;

procedure TGScript.RegisterFunction(const Name: string; Item: TGFunction);
begin
 FFunctions.SetItem(Name, @Item);
end;

function TGScript.GetFunction(const Name: string): TGFunction;
begin
 Result:=nil;
 FFunctions.GetItem(Name, @Result);
end;

procedure TGScript.UnregisterFunction(const Name: string);
begin
 FFunctions.Remove(Name);
end;

function TGScript.Error(Id: Cardinal; const S: string; Sender: TGCustomBlock): Boolean;
begin
 Result:=True;
 if FSilentError>0 then Exit;
 Result:=Assigned(FErrorProc);
 if Result then case Id of
  $00000000..$0FFFFFFF: Result:=FErrorProc(Format('Syntax Error (%d): %s'#13#13'%s', [Id, GE_CTStr[Min(High(GE_CTStr), Id)], S]));
  $10000000..$1FFFFFFF: Result:=FErrorProc(Format('Runtime Error (%d): %s'#13#13'%s', [Id-$10000000, GE_RTStr[Min(High(GE_RTStr), Id-$10000000)], S]));
  else Result:=False;
 end;
end;

function TGScript.GetVariable(const Name: string): TGCustomVariant;
begin
 Result:=nil;
 FVariables.GetItem(Name, Result);
end;

procedure TGScript.SetVariable(const Name: string; Item: TGCustomVariant);
begin
 Item.Temp:=False;
 FVariables.SetItem(Name, Item);
end;

function TGScript.LoadModule(Module: TGModuleClass): TGCustomModule;
var I: integer;
begin
 for I:=Low(FModules) to High(FModules) do
  if FModules[I].ClassType=Module then begin
   Result:=FModules[I];
   Exit;
  end;
 SetLength(FModules, High(FModules)+2);
 Result:=Module.Create(Self);
 FModules[High(FModules)]:=Result;
end;

procedure TGScript.UnsetVariable(const Name: string);
begin
 FVariables.Remove(Name);
end;

end.
