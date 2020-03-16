{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Replay Unit                            *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssAnim;

interface

uses
  Classes, D3DX8, SysUtils, Math, TssFiles, TssUtils;

type
  TAnimation = class;

  PMatrices = ^TMatrices;
  TMatrices = array[0..0] of TD3DXMatrix;

  TAnimFileHeader = packed record
    Name: string[31];
    TrackCount: Word;
    FrameCount: Word;
    FrameLen: Single;
  end;

  TAnimTrackHeader = packed record
    Name: string[31];
  end;

  TAnimTrack = class(TPersistent)
  private
    FAnim: TAnimation;
    FName: string;
    FFrames: PMatrices;
  public
    constructor Create(var Buffer: Pointer; Animation: TAnimation);
    destructor Destroy; override;
    function Matrix: TD3DXMatrix;
  published
    property Name: string read FName;
  end;

  TAnimation = class(TPersistent)
  private
    FHeader: TAnimFileHeader;
    FTracks: TList;
    FFrame: integer;
    FLength: Single;
    FName: string;
  public
    constructor Create(Buffer: Pointer);
    destructor Destroy; override;
    function GetTrack(const Name: string): TAnimTrack;
    procedure SetPosition(var Value: Single);
  published
    property Tracks: TList read FTracks;
    property Name: string read FName write FName;
  end;

  TAnimations = class(TList)
  public
    function GetAnim(const Name: string): TAnimation;
    constructor Create(const Path, FileName: string);
    destructor Destroy; override;
  end;

implementation

uses
  TssEngine;

{ TAnimation }

constructor TAnimation.Create(Buffer: Pointer);
var I: integer;
begin
 inherited Create;
 FTracks:=TList.Create;
 FHeader:=TAnimFileHeader(Buffer^);
 FLength:=FHeader.FrameCount*FHeader.FrameLen;
 Inc(Integer(Buffer), SizeOf(TAnimFileHeader));
 for I:=0 to FHeader.TrackCount-1 do
  FTracks.Add(TAnimTrack.Create(Buffer, Self));
end;

destructor TAnimation.Destroy;
var I: integer;
begin
 for I:=0 to FTracks.Count-1 do
  TAnimTrack(FTracks[I]).Free;
 FTracks.Free;
 inherited;
end;

function TAnimation.GetTrack(const Name: string): TAnimTrack;
var I: integer;
begin
 for I:=0 to FTracks.Count-1 do
  if TAnimTrack(FTracks[I]).FName=Name then begin
   Result:=FTracks[I];
   Exit;
  end;
 Result:=nil;
end;

procedure TAnimation.SetPosition(var Value: Single);
begin
 if FLength=0 then Exit;
 while Value<0.0 do
  Value:=Value+FLength;
 while Value>=FLength do
  Value:=Value-FLength;
 FFrame:=Trunc(Value/FLength*FHeader.FrameCount);
end;

{ TAnimTrack }

constructor TAnimTrack.Create(var Buffer: Pointer; Animation: TAnimation);
var I: integer;
begin
 inherited Create;
 FAnim:=Animation;
 with TAnimTrackHeader(Buffer^) do FName:=Name;
 Inc(Integer(Buffer), SizeOf(TAnimTrackHeader));
 FFrames:=AllocMem(Animation.FHeader.FrameCount*SizeOf(TD3DXMatrix));
 for I:=0 to Animation.FHeader.FrameCount-1 do begin
  FFrames[I]:=TD3DXMatrix(Buffer^);
  Inc(Integer(Buffer), SizeOf(TD3DXMatrix));
 end;
end;

destructor TAnimTrack.Destroy;
begin
 if FFrames<>nil then FreeMem(FFrames);
 inherited;
end;

function TAnimTrack.Matrix: TD3DXMatrix;
begin
 Result:=FFrames[FAnim.FFrame];
end;

{ TAnimations }

constructor TAnimations.Create(const Path, FileName: string);
var I: integer;
    FilePack: TTssFilePack;
    P: Pointer;
    Anim: TAnimation;
begin
 FilePack:=TTssFilePack.Create(Path, FileName, Options.LockData, Options.PreferPacked);
 for I:=0 to FilePack.Count-1 do begin
  FilePack.LoadToMemByIndex(I, P);
  Anim:=TAnimation.Create(P);
  Anim.Name:=FilePack.Header[I].FileName;
  Add(Anim);
  FreeMem(P);
 end;
 FilePack.Free;
end;

destructor TAnimations.Destroy;
var I: integer;
begin
 for I:=0 to Count-1 do
  TAnimation(Items[I]).Free;
 inherited;
end;

function TAnimations.GetAnim(const Name: string): TAnimation;
var I: integer;
begin
 Result:=nil;
 for I:=0 to Count-1 do
  if TAnimation(Items[I]).Name=Name then begin
   Result:=Items[I];
   Exit;
  end;   
end;

end.
 