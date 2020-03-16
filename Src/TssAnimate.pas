{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Human Animation Unit                   *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssAnimate;

interface

uses
  Windows, Direct3D8, D3DX8, TssUtils, TssObjects, SysUtils,
  TssFiles, Classes, Math;

const
  SkeletonPoints = 16;
  MaxAnims = 4;

type
  TAnimation = class;
  
  TVertexLink = packed record
    PrimaryBone, SecondaryBone: Byte;
    Blend: Byte;
  end;
  PVertexLinks = ^TVertexLinks;
  TVertexLinks = array[0..0] of TVertexLink;

  TAnimData = class(TObject)
  public
    Obj: TTssObject;
    DetailsAnim: array[-DETAILS_LOW..DETAILS_HIGH] of record
      VertexLinks: PVertexLinks;
    end;
    Skeleton: array[0..SkeletonPoints-1] of record
      Position: TD3DXVector3;
      Orientation: TD3DMatrix;
      Transform: TD3DMatrix;
    end;
    Animations: array[0..MaxAnims-1] of record
      Used: Boolean;
      Anim: TAnimation;
      Position, Speed: Single;
      Morphing: Single;
      PlayCount: integer;
    end;
    procedure Move(TickCount: Single);
    procedure Transform(Details: integer);
    constructor Create(AObj: TTssObject; Data: Pointer);
    destructor Destroy; override;
  end;

  PAniFramePoint = ^TAniFramePoint;
  TAniFramePoint = packed record
    Point: Byte;
    Tweening: Byte;
    Morphing: Single;
    Orientation: TD3DXQuaternion;
  end;
  PAniFramePoints = ^TAniFramePoints;
  TAniFramePoints = array[0..0] of TAniFramePoint;
  TAniFrame = packed record
    PointCount: Byte;
    Points: PAniFramePoints;
  end;
  PAniFrames = ^TAniFrames;
  TAniFrames = array[0..0] of TAniFrame;
  TAnimation = class(TObject)
  public
    Name: string;
    FrameCount: Word;
    Length: Single;
    Frames: PAniFrames;
    constructor Create(Data: Pointer);
    destructor Destroy; override;
    function GetOrientation(Bone: Byte; Position: Single): TD3DXQuaternion;
  end;

  TAnimations = class(TObject)
  private
    Anims: TList;
    function GetAnim(Index: integer): TAnimation;
  public
    constructor Create(const Path, FileName: string);
    destructor Destroy; override;
    function GetIndex(Name: string): integer;
    property Anim[Index: integer]: TAnimation read GetAnim;
  end;

procedure Animate_MakeAnimationMatrix(var BoneTransform, BoneOrientation: TD3DMatrix; const ParentPos: TD3DXVector3; const ParentTransform, ParentOrientation, RelativeOrientation: TD3DMatrix);
procedure Animate_HandleBone(const AnimData: TAnimData; Index: integer);

procedure Animate_TransForm(Obj: TTssObject; AnimData: TAnimData; Details: integer);

const
  ParentPoint: array[1..SkeletonPoints-1] of Byte = (
    0 ,  // 1  Human
    1 ,  // 2  Upper Body
    2 ,  // 3  Head
    1 ,  // 4  Right Foot 0
    1 ,  // 5  Left Foot 0
    2 ,  // 6  Right Hand 0
    2 ,  // 7  Left Hand 0
    4 ,  // 8  Right Foot 1
    5 ,  // 9  Left Foot 1
    6 ,  // 10 Right Hand 1
    7 ,  // 11 Left Hand 1
    8 ,  // 12 Right Foot 2
    9 ,  // 13 Left Foot 2
    10,  // 14 Right Hand 2
    11   // 15 Left Hand 2
  );

implementation

uses
  TssEngine;

constructor TAnimations.Create(const Path, FileName: string);
var I: integer;
    FilePack: TTssFilePack;
    Anim: TAnimation;
    Data: Pointer;
begin
 inherited Create;
 Anims:=TList.Create;
 FilePack:=TTssFilePack.Create(Path, FileName, Options.LockData, Options.PreferPacked);
 for I:=0 to FilePack.Count-1 do begin
  FilePack.LoadToMemByIndex(I, Data);
  Anim:=TAnimation.Create(Data);
  FreeMem(Data);
  Anim.Name:=FilePack.Header[I].FileName;
  Anims.Add(Anim);
 end;
 FilePack.Free;
end;

destructor TAnimations.Destroy;
var I: integer;
begin
 for I:=0 to Anims.Count-1 do
  TAnimation(Anims.Items[I]).Free;
 Anims.Free;
 inherited;
end;

function TAnimations.GetAnim(Index: integer): TAnimation;
begin
 Result:=TAnimation(Anims.Items[Index]);
end;

function TAnimations.GetIndex(Name: string): integer;
var I: integer;
begin
 Result:=0;
 for I:=0 to Anims.Count-1 do
  if Anim[I].Name=Name then begin
   Result:=I;
   Exit;
  end;
end;

constructor TAnimation.Create(Data: Pointer);
var I: integer;
begin
 inherited Create;
 FrameCount:=Word(Data^);
 Length:=FrameCount/20;
 Inc(Integer(Data), 2);
 Frames:=AllocMem(FrameCount*SizeOf(TAniFrame));
 for I:=0 to FrameCount-1 do with Frames[I] do begin
  PointCount:=Byte(Data^);
  Inc(Integer(Data));
  Points:=AllocMem(PointCount*SizeOf(TAniFramePoint));
  if PointCount>0 then begin
   CopyMemory(@(Points[0].Point), Data, PointCount*SizeOf(TAniFramePoint));
   Inc(Integer(Data), PointCount*SizeOf(TAniFramePoint));
  end;
 end;
end;

destructor TAnimation.Destroy;
var I: integer;
begin
 for I:=0 to FrameCount-1 do with Frames[I] do
  if PointCount>0 then FreeMem(Points);
 FreeMem(Frames);
 inherited;
end;

function TAnimation.GetOrientation(Bone: Byte; Position: Single): TD3DXQuaternion;
var Found: Boolean;
    PrevFrame: Word;
    J, N: integer;
    PrevPoint: PAniFramePoint;
    Q: TD3DXQuaternion;
    PrevBlend, NextBlend, TweeningPos: Single;
begin
 D3DXQuaternionIdentity(Result);
 Found:=False;
 PrevFrame:=0;
 PrevPoint:=nil;
 for J:=Min(FrameCount-1,Round(Position*20-0.4999)) downto 0 do begin
  for N:=0 to Frames[J].PointCount-1 do
   if Frames[J].Points[N].Point=Bone then begin
    Result:=Frames[J].Points[N].Orientation;
    Found:=True;
    PrevFrame:=J;
    PrevPoint:=@(Frames[J].Points[N]);
    Break;
   end;
  if Found then Break;
 end;
 Found:=False;
 for J:=Round(Position*20+0.4999) to FrameCount do begin
  for N:=0 to Frames[J mod FrameCount].PointCount-1 do
   if Frames[J mod FrameCount].Points[N].Point=Bone then with Frames[J mod FrameCount].Points[N] do begin
    if J>PrevFrame then begin
     if PrevPoint<>nil then begin
      TweeningPos:=(1-(J/20-Position)/((J-PrevFrame)/20));
      if Tweening=1 then PrevBlend:=Sqr(1-TweeningPos) else PrevBlend:=1-TweeningPos;
      if PrevPoint.Tweening=1 then NextBlend:=Sqr(TweeningPos) else NextBlend:=TweeningPos;
      Q:=Result;
      D3DXQuaternionSlerp(Result, Q, Orientation, NextBlend/(PrevBlend+NextBlend));
     end else Result:=Orientation;
    end;
    Found:=True;
    Break;
   end;
  if Found then Break;
 end;
end;

constructor TAnimData.Create(AObj: TTssObject; Data: Pointer);
var VertexCount: Word;
    I: integer;
begin
 inherited Create;
 Obj:=AObj;
 if Data<>nil then begin
  VertexCount:=Word(Data^);
  Inc(Integer(Data), 2);
  DetailsAnim[0].VertexLinks:=AllocMem(VertexCount*SizeOf(TVertexLink));
  CopyMemory(@(DetailsAnim[0].VertexLinks[0].PrimaryBone), Data, VertexCount*SizeOf(TVertexLink));
  Inc(Integer(Data), VertexCount*SizeOf(TVertexLink));
  for I:=1 to SkeletonPoints-1 do begin
   CopyMemory(@(Skeleton[I].Position.X), Data, 12);
   Inc(Integer(Data), 12);
  end;
 end;
end;

destructor TAnimData.Destroy;
var I: integer;
begin
 for I:=-DETAILS_LOW to DETAILS_HIGH do
  FreeMem(DetailsAnim[I].VertexLinks);
 inherited;
end;

procedure TAnimData.Move(TickCount: Single);
var I: integer;
begin
 for I:=0 to MaxAnims-1 do
  with Animations[I] do if Used then begin
   Position:=Position+TickCount*0.001*Speed;
   if Position>=Anim.Length then begin Position:=Position-Anim.Length; Inc(PlayCount); end;
   if Position<0 then begin Position:=Position+Anim.Length; Inc(PlayCount); end;
  end;
 inherited;
end;

procedure Animate_MakeAnimationMatrix(var BoneTransform, BoneOrientation: TD3DMatrix; const ParentPos: TD3DXVector3; const ParentTransform, ParentOrientation, RelativeOrientation: TD3DMatrix);
var TransFormedPos: TD3DXVector3;
    M1, M2: TD3DMatrix;
begin
 D3DXVec3TransformCoord(TransFormedPos, ParentPos, ParentTransform);
 D3DXMatrixTranslation(BoneTransform,-ParentPos.X,-ParentPos.Y,-ParentPos.Z);
 D3DXMatrixTranslation(M2, TransFormedPos.X, TransFormedPos.Y, TransFormedPos.Z);
 D3DXMatrixMultiply(BoneOrientation, RelativeOrientation, ParentOrientation);
 D3DXMatrixMultiply(M1, BoneTransform, BoneOrientation);
 D3DXMatrixMultiply(BoneTransform, M1, M2);                          
end;

procedure Animate_HandleBone(const AnimData: TAnimData; Index: integer);
var AnimOrientation: TD3DMatrix;
begin             
 AnimOrientation:=Engine.IdentityMatrix;
 with AnimData do
  Animate_MakeAnimationMatrix(Skeleton[Index].Transform, Skeleton[Index].Orientation, Skeleton[ParentPoint[Index]].Position, Skeleton[ParentPoint[Index]].Transform, Skeleton[ParentPoint[Index]].Orientation, AnimOrientation);
end;

procedure TAnimData.Transform(Details: integer);
  function GetOrientation(Bone: Byte): TD3DXQuaternion;
  var I, Count: integer;
      Q: TD3DXQuaternion;
  begin
   Count:=0;
   for I:=0 to MaxAnims-1 do
    if Animations[I].Used and ((Animations[I].Morphing>0.0) or (Count=0)) then begin
     Inc(Count);
     if Count=1 then Result:=Animations[I].Anim.GetOrientation(Bone, Animations[I].Position)
      else begin
       Q:=Result;
       D3DXQuaternionSlerp(Result, Q, Animations[I].Anim.GetOrientation(Bone, Animations[I].Position), Animations[I].Morphing);
      end;
    end;
  end;
var Q: TD3DXQuaternion;
    AnimOrientation: TD3DMatrix;
    PVB: P3DVertex2TxColor;
    V2: TD3DXVector3;
    I: integer;
begin
 Skeleton[0].Transform:=Engine.IdentityMatrix;
 with GetOrientation(0) do begin
  Skeleton[0].Transform._41:=X;
  Skeleton[0].Transform._42:=Y;
  Skeleton[0].Transform._43:=Z;
 end;
 Skeleton[0].Orientation:=Engine.IdentityMatrix;
 for I:=1 to SkeletonPoints-1 do begin
  D3DXQuaternionNormalize(Q, GetOrientation(I));
  D3DXMatrixRotationQuaternion(AnimOrientation, Q);
  Animate_MakeAnimationMatrix(Skeleton[I].Transform, Skeleton[I].Orientation, Skeleton[ParentPoint[I]].Position, Skeleton[ParentPoint[I]].Transform, Skeleton[ParentPoint[I]].Orientation, AnimOrientation);
 end;
           
 with Obj.Details[Details] do begin
  if VB=nil then Obj.MakeBuffers;
  VB.Lock(0, 0, PByte(PVB), 0);
  for I:=0 to VertexCount-1 do begin
   with DetailsAnim[Details].VertexLinks[I] do begin
    D3DXVec3TransformCoord(PVB.V, Vertices[I].V1, Skeleton[PrimaryBone+1].Transform);
    D3DXVec3TransformCoord(PVB.N, D3DXVector3((Vertices[I].nX-128)*0.007874015748031496, (Vertices[I].nY-128)*0.007874015748031496, (Vertices[I].nZ-128)*0.007874015748031496), Skeleton[PrimaryBone+1].Orientation);
    if Blend>0 then begin
     D3DXVec3TransformCoord(V2, Vertices[I].V1, Skeleton[SecondaryBone+1].Transform);
     PVB.V.X:=PVB.V.X*(1-Blend*0.00390625)+V2.X*Blend*0.00390625;
     PVB.V.Y:=PVB.V.Y*(1-Blend*0.00390625)+V2.Y*Blend*0.00390625;
     PVB.V.Z:=PVB.V.Z*(1-Blend*0.00390625)+V2.Z*Blend*0.00390625;
     D3DXVec3TransformCoord(V2, D3DXVector3((Vertices[I].nX-128)*0.007874015748031496, (Vertices[I].nY-128)*0.007874015748031496, (Vertices[I].nZ-128)*0.007874015748031496), Skeleton[SecondaryBone+1].Orientation);
     PVB.N.X:=PVB.N.X*(1-Blend*0.00390625)+V2.X*Blend*0.00390625;
     PVB.N.Y:=PVB.N.Y*(1-Blend*0.00390625)+V2.Y*Blend*0.00390625;
     PVB.N.Z:=PVB.N.Z*(1-Blend*0.00390625)+V2.Z*Blend*0.00390625;
    end;
   end;
   Inc(PVB);
  end;
  VB.Unlock;
 end;
end;

procedure Animate_TransForm(Obj: TTssObject; AnimData: TAnimData; Details: integer);
var I: integer;
    //M1, M2, M3, M4: TD3DMatrix;
    PVB: P2TxColorVertices;
    V2: TD3DXVector3;
begin
 AnimData.Skeleton[0].Transform:=Engine.IdentityMatrix;
 AnimData.Skeleton[0].Orientation:=Engine.IdentityMatrix;
 for I:=1 to SkeletonPoints-1 do
  Animate_HandleBone(AnimData, I);

 with Obj.Details[Details] do begin
  if VB=nil then Obj.MakeBuffers;
  VB.Lock(0, 0, PByte(PVB), D3DLOCK_NOSYSLOCK or D3DLOCK_DISCARD);
  for I:=0 to VertexCount-1 do with AnimData.DetailsAnim[Details].VertexLinks[I] do begin
   D3DXVec3TransformCoord(PVB[I].V, Vertices[I].V1, AnimData.Skeleton[PrimaryBone].Transform);
   if Blend>0 then begin
    D3DXVec3TransformCoord(V2, Vertices[I].V1, AnimData.Skeleton[SecondaryBone].Transform);
    PVB[I].V.X:=PVB[I].V.X*(1-Blend*0.00390625)+V2.X*Blend*0.00390625;
    PVB[I].V.Y:=PVB[I].V.Y*(1-Blend*0.00390625)+V2.Y*Blend*0.00390625;
    PVB[I].V.Z:=PVB[I].V.Z*(1-Blend*0.00390625)+V2.Z*Blend*0.00390625;
   end;
  end;
  VB.Unlock;
 end;
 {with Obj.Details[Details] do begin
  if VB=nil then Obj.MakeBuffers;
  VB.Lock(0, 0, PByte(PVB), 0);
  D3DXMatrixTranslation(M1,-AnimData.Skeleton[6].Position.X,-AnimData.Skeleton[6].Position.Y,-AnimData.Skeleton[6].Position.Z);
  D3DXMatrixRotationZ(M4, (Round(Obj.RPos.Z*1000) mod 5000)*0.0002*g_PI-g_PI_DIV_2);
  D3DXMatrixMultiply(M3, M1, M4);
  D3DXMatrixTranslation(M2, AnimData.Skeleton[6].Position.X, AnimData.Skeleton[6].Position.Y, AnimData.Skeleton[6].Position.Z);
  D3DXMatrixMultiply(M1, M3, M2);
  for I:=0 to VertexCount-1 do
   with AnimData.DetailsAnim[0].VertexLinks[I] do if PrimaryBone=10 then begin
    D3DXVec3TransformCoord(PVB[I].vV, Vertices[I].V1, M1);
    if (Blend>0) and (SecondaryBone<10) then begin
     D3DXVec3TransformCoord(V2, Vertices[I].V1, Engine.IdentityMatrix);
     PVB[I].vV.X:=PVB[I].vV.X*(1-Blend*0.00390625)+V2.X*Blend*0.00390625;
     PVB[I].vV.Y:=PVB[I].vV.Y*(1-Blend*0.00390625)+V2.Y*Blend*0.00390625;
     PVB[I].vV.Z:=PVB[I].vV.Z*(1-Blend*0.00390625)+V2.Z*Blend*0.00390625;
    end;
   end;
  D3DXMatrixRotationY(M3, (Round(Obj.RPos.X*1000) mod 5000)*0.0002*g_PI-g_PI_DIV_2);
  MakeAnimationMatrix(M1, M2, AnimData.Skeleton[10].Position, M1, M4, M3);
  D3DXVec3TransformCoord(V2, AnimData.Skeleton[10].Position, M1);
  D3DXMatrixTranslation(M3,-AnimData.Skeleton[10].Position.X,-AnimData.Skeleton[10].Position.Y,-AnimData.Skeleton[10].Position.Z);

  D3DXMatrixRotationZ(M1, (Round(Obj.RPos.Z*1000) mod 5000)*0.0002*g_PI-g_PI_DIV_2);
  D3DXMatrixRotationY(M2, (Round(Obj.RPos.X*1000) mod 5000)*0.0002*g_PI-g_PI_DIV_2);
  D3DXMatrixMultiply(M4, M2, M1);

  D3DXMatrixMultiply(M2, M3, M4);
  D3DXMatrixTranslation(M3, V2.X, V2.Y, V2.Z);
  D3DXMatrixMultiply(M1, M2, M3);
  for I:=0 to VertexCount-1 do
   with AnimData.DetailsAnim[0].VertexLinks[I] do if PrimaryBone=14 then begin
    D3DXVec3TransformCoord(PVB[I].vV, Vertices[I].V1, M1);
   end;
  VB.Unlock;
 end;}
end;

end.
