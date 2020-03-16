{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Replay Unit                            *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssReplay;

interface

uses
  Windows, Direct3D8, DirectInput8, TssUtils, TssTextures, D3DX8, Classes, Math, SysUtils,
  TssMap, TssObjects, TssCars;

type
  TReplayData = packed record
    Item: TVirtualObject;
    Id: Cardinal;
    Size: Cardinal;
    Data: Cardinal;
  end;
  TReplayFrame = packed record
    DataCount: Cardinal;
    Data: Pointer;
    Size: Cardinal;
  end;
  PReplayFrames = ^TReplayFrames;
  TReplayFrames = array[0..0] of TReplayFrame;

  TTssReplay = class(TCustomVirtualEngine)
  private
    FData: Pointer;
    FDataPos: Cardinal;
    FFrames: PReplayFrames;
    FFramePos: Cardinal;
    FDataSize, FFrameCount: Cardinal;
    FFrameLength: Single;
    FFrameTimeRecord, FFrameTimePlay: Single;
    FPlayPos: Cardinal;
    FKeyFrame: Boolean;
    FNextOnOff: Boolean;
    FWasCam: TTssCamera;
    procedure SetPlayPos(Value: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure PlayMove(TickCount: Single); override;
    procedure RecordMove(TickCount: Single); override;
    procedure AddData(Unique: Boolean; AItem: TVirtualObject; AId: Cardinal; AData: Pointer; ASize: Cardinal); override;
    function FrameLength: Single; override;
    function FrameSlerpR: Single; override;
    function FrameSlerpP: Single; override;
    procedure Replay(OnOff: Boolean);
  published
    property Frame: Cardinal read FPlayPos write SetPlayPos;
  end;

implementation

uses TssEngine;

{ TTssReplay }

procedure TTssReplay.AddData(Unique: Boolean; AItem: TVirtualObject; AId: Cardinal; AData: Pointer; ASize: Cardinal);
var I: integer;
begin
 if FKeyFrame or Unique then begin
  if FDataPos+SizeOf(TReplayData)-SizeOf(Cardinal)+ASize>=FDataSize then begin
   Inc(FDataSize, 1024*1024*5);
   ReAllocMem(FData, FDataSize);
   FDataPos:=0;
   for I:=0 to FFramePos do begin
    FFrames[I].Data:=Pointer(Cardinal(FData)+FDataPos);
    Inc(FDataPos, FFrames[I].Size);
   end;
  end;
  with TReplayData((Pointer(Cardinal(FData)+FDataPos))^) do begin
   Item:=AItem;
   Id:=AId;
   Size:=ASize;
   CopyMemory(@Data, AData, ASize);
  end;
  Inc(FFrames[FFramePos].DataCount);
  FFrames[FFramePos].Size:=FFrames[FFramePos].Size+SizeOf(TReplayData)-SizeOf(Cardinal)+ASize;
  Inc(FDataPos, SizeOf(TReplayData)-SizeOf(Cardinal)+ASize);
 end;
end;

constructor TTssReplay.Create;
begin
 inherited;
 FDataSize:=1024*1024*5; // 5 MB
 FFrameLength:=0.1;      // 0.1 Seconds.
 FFrameCount:=12000;     // 12000 Frames = 20 min at 10 frames per second.
 Recording:=False;//True;
 FData:=AllocMem(FDataSize);
 FFrames:=AllocMem(FFrameCount*SizeOf(TReplayFrame));
end;

destructor TTssReplay.Destroy;
begin
 FreeMem(FFrames);
 FreeMem(FData);
 inherited;
end;

function TTssReplay.FrameLength: Single;
begin
 Result:=FFrameLength;
end;

function TTssReplay.FrameSlerpR: Single;
begin
 Result:=FFrameTimeRecord/FFrameLength;
end;

function TTssReplay.FrameSlerpP: Single;
begin
 Result:=FFrameTimePlay/FFrameLength;
end;

procedure TTssReplay.Move(TickCount: Single);
begin
 if (FNextOnOff<>Playing) and FKeyFrame then begin
  Replay(FNextOnOff);
  FNextOnOff:=Playing;
 end;
end;

procedure TTssReplay.PlayMove(TickCount: Single);
var I: integer;
    Pos: Cardinal;
begin
 if Engine.Controls.DIKKeyDown(DIK_BACKSPACE, -1) then FNextOnOff:=False;
 FFrameTimePlay:=FFrameTimePlay+TickCount*0.001;
 FKeyFrame:=FFrameTimePlay>FFrameLength;
 if FKeyFrame then begin
  if not FNextOnOff then begin
   FFrameTimePlay:=FFrameLength;
   Pos:=0;
   for I:=0 to FFrames[FFramePos-1].DataCount-1 do
    with TReplayData(Pointer(Cardinal(FFrames[FFramePos-1].Data)+Pos)^) do begin
     Item.VirtualData(Id, @Data, Size);
     Inc(Pos, SizeOf(TReplayData)-SizeOf(Cardinal)+Size);
    end;
   Pos:=0;
   for I:=0 to FFrames[FFramePos].DataCount-1 do
    with TReplayData(Pointer(Cardinal(FFrames[FFramePos].Data)+Pos)^) do begin
     Item.VirtualData(Id, @Data, Size);
     Inc(Pos, SizeOf(TReplayData)-SizeOf(Cardinal)+Size);
    end;
  end else begin
   FPlayPos:=(FPlayPos+1) mod (FFramePos+1);
   FFrameTimePlay:=FFrameTimePlay-FFrameLength;
   Pos:=0;
   for I:=0 to FFrames[FPlayPos].DataCount-1 do
    with TReplayData(Pointer(Cardinal(FFrames[FPlayPos].Data)+Pos)^) do begin
     Item.VirtualData(Id, @Data, Size);
     Inc(Pos, SizeOf(TReplayData)-SizeOf(Cardinal)+Size);
    end;
  end;
 end;
end;

procedure TTssReplay.RecordMove(TickCount: Single);
begin
 if Engine.Controls.DIKKeyDown(DIK_BACKSPACE, -1) then FNextOnOff:=True;
 FFrameTimeRecord:=FFrameTimeRecord+TickCount*0.001;
 FKeyFrame:=FFrameTimeRecord>FFrameLength;
 if FKeyFrame then begin
  FFramePos:=FFramePos+1;
  if FFramePos>=FFrameCount then begin
   Inc(FFrameCount, 12000);
   ReAllocMem(FFrames, FFrameCount*SizeOf(TReplayFrame));
  end;
  FFrames[FFramePos].DataCount:=0;
  FFrames[FFramePos].Size:=0;
  FFrames[FFramePos].Data:=Pointer(Cardinal(FData)+FDataPos);
  FFrameTimeRecord:=FFrameTimeRecord-FFrameLength;
 end;
 //Engine.TestValue:=IntToStr(FFramePos)+'Frames, '+IntToStr(FDataPos div 1024)+'kB';
end;

procedure TTssReplay.Replay(OnOff: Boolean);
begin
 if not OnOff then begin
  Recording:=True;
  Playing:=False;
  Engine.Camera:=FWasCam;
 end;
 if OnOff then begin
  Recording:=False;
  Playing:=True;
  FPlayPos:=FFramePos;
  FFrameTimePlay:=FFrameLength;
  FWasCam:=Engine.Camera;
  Engine.Camera.Cam:=TTssCam(Engine.Cameras.Items[0]);
 end;
end;

procedure TTssReplay.SetPlayPos(Value: Cardinal);
begin
 FPlayPos:=(Value+1) mod (FFramePos+1);
end;

end.
