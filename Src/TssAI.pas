{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Artificial Intelligence Unit           *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssAI;

interface

uses
  Windows, TssObjects, Direct3D8, D3DX8, TssUtils, Math,
  SysUtils, TssWeapons, TssMap, Classes, TssCars, G2Types, G2Script, G2Variants,
  TssAnim;

const
  WayPointLength = 2.0;

type
  TAIMode = (amPed);

  TTssAI = class(TTssHuman)
  public
    FLastPos: TD3DXVector3;
    FTarget: TTssHuman;
    FLaneQueue: TList;
    FDirQueue: TList;
    FNextPoint: integer;
    FWayPoints: array[0..7] of TD3DXVector3;
    FKickStart: Boolean;
    FCars: TList;
    FMode: TAIMode;
    FSimulate: Boolean;
    FLanePos: Single;
    FSpeed, FWalkSpeed: Single;
    FDrivePos: TD3DXVector3;
    FLastAngle, FTyreAngle: Single;
    FTargetSpeed: Single;
    FNextReaction: Single;
    FUnTouched: Boolean;
    FForward: Boolean;
  public
    constructor Create(AParent: TTssObject; AAutoHandle: Boolean); override;
    destructor Destroy; override;
    procedure Move(TickCount: Single); override;
    procedure PedMove(TickCount: Single);
    procedure CarCtrl(TickCount: Single; var Ctrl: TTssCarControls); override;
    procedure TargetDrive(TickCount: Single; var Ctrl: TTssCarControls); 
    procedure PedDrive(TickCount: Single; var Ctrl: TTssCarControls);
  published
    property Target: TTssHuman read FTarget write FTarget;
  end;

  TAISystem = class(TPersistent)
  private
    FList: TList;
    FCarPool: TList;
    FPedPool: TList;
    AITimer: Single;
    FCarNames, FAINames: TG2Variant;
  public
    AICount: integer;
    constructor Create;
    destructor Destroy; override;
    procedure Move(TickCount: Single);
  published
  end;

implementation

uses
  TssEngine;

procedure TTssAI.Move(TickCount: Single);
var Temp: Single;
    Vector: TD3DXVector3;
begin
 Manual:=Stopped and FUnTouched;
 if FTarget<>nil then if Car=nil then begin
  D3DXVec3Subtract(Vector, FTarget.TopObj.RPos, RPos);
  Temp:=D3DXVec3Length(Vector);
  if Temp<15.0 then begin
   Stopped:=False;
   hitStyle:=hsMeshLow1;
   FNoRot:=True;
   OwnMass:=15.0;
   Manual:=False;
   Gravitation:=20.0;
   if FStandAni=nil then FStandAni:=Engine.Animations.GetAnim('chr_bonus_walk.ani');
   if FWalkAni=nil then FWalkAni:=Engine.Animations.GetAnim('chr_bonus_walk.ani');
   if FRunAni=nil then FRunAni:=FWalkAni;
   if FJumpAni=nil then FJumpAni:=Engine.Animations.GetAnim('chr_player_jump.ani');
   if Temp<5.0 then Controls.WalkZ:=Max(0.0, (Temp-4.0)*0.75)
    else Controls.WalkZ:=0.75;
   Temp:=GetVectorYAngle(Vector)-GetYAngle(RRot);
   while Temp>g_PI do Temp:=Temp-g_2_PI;
   while Temp<-g_PI do Temp:=Temp+g_2_PI;
   Controls.TurnY:=Temp*g_INV_PI*0.05;
  end else Stopped:=True;
  //SetCar(TTssCar(Engine.FObjects.Obj[0]));
 end;
 if Stopped and FUnTouched then begin
  if (FTarget=nil) and (Car=nil) then PedMove(TickCount);
 end else FUnTouched:=False;
 
 inherited;

 if Car=nil then if FUnTouched then
  if FKillTimer>500.0 then begin
   Engine.Objects.Remove(Self);
   Engine.FAISystem.FPedPool.Add(Self);
   Dec(Engine.FAISystem.AICount);
  end;
end;

procedure TTssAI.PedMove(TickCount: Single);
var Temp: Single;
    Vector, Vector2, Vector3, Vector4: TD3DXVector3;
    Stop: Boolean;
begin
  AnimSpeed:=FWalkSpeed*0.5;
  if FWalkSpeed=0.0 then Animation:=Self.FStandAni
   else Animation:=FWalkAni;
  FLanePos:=FLanePos+TickCount*FWalkSpeed*0.001;
  //if FNextPoint<1 then FNextPoint:=1;
  Vector3:=RPos;
  Stop:=False;
  if (FLastPos.X=0.0) and (FLastPos.Y=0.0) and (FLastPos.Z=0.0) then FLastPos:=RPos;
  if FLaneQueue.Count=1 then
   if FForward then begin
    if TTrafficLane(FLaneQueue.Last).CCount>0 then with TTrafficLane(FLaneQueue.Last).Connections[Random(TTrafficLane(FLaneQueue.Last).CCount)] do begin
     FLaneQueue.Add(Lane);
     FDirQueue.Add(Pointer(Start));
    end;
   end else begin
    if TTrafficLane(FLaneQueue.Last).C2Count>0 then with TTrafficLane(FLaneQueue.Last).Connections2[Random(TTrafficLane(FLaneQueue.Last).C2Count)] do begin
     FLaneQueue.Add(Lane);
     FDirQueue.Add(Pointer(Start));
    end;
   end;
  if FLaneQueue.Count>1 then
   with TTrafficLane(FLaneQueue.Items[1]) do
    if RoundTime<>0.0 then begin
     Temp:=FloatRemainder(Engine.FSecondTimer, RoundTime);
     if ((Temp<=EnabFrom) or (Temp>=EnabTo)) and ((Temp<=EnabFrom2) or (Temp>=EnabTo2)) then
      if Boolean(FDirQueue[0]) then Stop:=Stop or (D3DXVec3LengthSq(VectorSubtract(Points[0], VectorSubtract(RPos, FDrivePos)))<3.0)
       else Stop:=Stop or (D3DXVec3LengthSq(VectorSubtract(Points[PCount-1], VectorSubtract(RPos, FDrivePos)))<3.0);
    end;

  if Stop then FWalkSpeed:=Max(0.0, FWalkSpeed-TickCount*0.01)
   else FWalkSpeed:=Min(2.5*FSpeed, FWalkSpeed+TickCount*0.01);

  if FLaneQueue.Count>0 then begin

   while TTrafficLane(FLaneQueue[0]).PCount>FNextPoint do
    with TTrafficLane(FLaneQueue[0]) do begin
     Temp:=D3DXVec3Length(VectorSubtract(Points[FNextPoint+Ord(not FForward)], Points[FNextPoint-Ord(FForward)]));
     if FLanePos>=Temp then begin
      FLanePos:=FLanePos-Temp;
      FLastPos:=Points[FNextPoint+1-2*Ord(FForward)];
      if FForward then Inc(FNextPoint) else Dec(FNextPoint);
      if FNextPoint>=PCount then begin
       FNextPoint:=1;
       if FLaneQueue.Count=1 then
        if CCount>0 then with Connections[Random(CCount)] do begin
         FLaneQueue.Add(Lane);
         FDirQueue.Add(Pointer(Start));
        end else Break;
       FForward:=Boolean(FDirQueue.Items[0]);
       if not FForward then FNextPoint:=TTrafficLane(FLaneQueue[1]).PCount-2;
       FDirQueue.Delete(0);
       FLaneQueue.Delete(0);
      end else if FNextPoint<0 then begin
       FNextPoint:=1;
       if FLaneQueue.Count=1 then
        if C2Count>0 then with Connections2[Random(C2Count)] do begin
         FLaneQueue.Add(Lane);
         FDirQueue.Add(Pointer(Start));
        end else Break;
       FForward:=Boolean(FDirQueue.Items[0]);
       if not FForward then FNextPoint:=TTrafficLane(FLaneQueue[1]).PCount-2;
       FDirQueue.Delete(0);
       FLaneQueue.Delete(0);
      end;
     end else Break;
    end;

   if (FLaneQueue.Count>0) and (FWalkSpeed>0.001) then with TTrafficLane(FLaneQueue[0]) do begin
    {J:=FNextPoint-1+2*Ord(FForward);
    if J>=PCount then begin
     J:=1;
     if FLaneQueue.Count=1 then if CCount>0 then with Connections[Random(CCount)] do begin
      FLaneQueue.Add(Lane);
      FDirQueue.Add(Pointer(Start));
     end;
     if FLaneQueue.Count>1 then begin
      if not Boolean(FDirQueue[0]) then J:=TTrafficLane(FLaneQueue[1]).PCount-2;
      Vector:=TTrafficLane(FLaneQueue[1]).Points[J];
     end;
    end else if J<0 then begin
     J:=1;
     if FLaneQueue.Count=1 then if C2Count>0 then with Connections2[Random(C2Count)] do begin
      FLaneQueue.Add(Lane);
      FDirQueue.Add(Pointer(Start));
     end;
     if FLaneQueue.Count>1 then begin
      if not Boolean(FDirQueue[0]) then J:=TTrafficLane(FLaneQueue[1]).PCount-2;
      Vector:=TTrafficLane(FLaneQueue[1]).Points[J];
     end;
    end else Vector:=Points[J];}

    Temp:=D3DXVec3Length(VectorSubtract(Points[FNextPoint], Points[FNextPoint+1-2*Ord(FForward)]));
    Vector4:=VectorInterpolate(Points[FNextPoint+1-2*Ord(FForward)], Points[FNextPoint], FLanePos/Temp);
    Vector4.X:=Vector4.X+FDrivePos.X;
    Vector4.Y:=Vector4.Y-MinPos.Y;
    Vector4.Z:=Vector4.Z+FDrivePos.Z;
    
    if (D3DXVec3LengthSq(VectorSubtract(Vector4, RPos))>Sqr(0.0001*TickCount)) and FVisible then begin
     Vector:=VectorSubtract(Points[FNextPoint], Points[FNextPoint+1-2*Ord(FForward)]);
     Vector2:=D3DXVector3(0.0, 0.0, 1.0);
     D3DXVec3Normalize(Vector3, D3DXVector3(Vector.X, 0.0, Vector.Z));
     D3DXMatrixRotationY(RRot, (1-2*Ord(Vector3.X<0))*ArcCos(D3DXVec3Dot(Vector2, Vector3)));
    end;
    RPos:=Vector4;
   end;
  end;

end;

procedure TTssAI.CarCtrl(TickCount: Single; var Ctrl: TTssCarControls);
begin
 if FTarget<>nil then TargetDrive(TickCount, Ctrl)
  else PedDrive(TickCount, Ctrl);

 if FUnTouched then
  if Car.FKillTimer>500.0 then begin
   Engine.Objects.Remove(Car);
   Engine.FAISystem.FCarPool.Add(Car);
   Dec(Engine.FAISystem.AICount);
  end;
end;

procedure TTssAI.TargetDrive(TickCount: Single; var Ctrl: TTssCarControls);
var Temp, TargetSpeed: Single;
    Vector: TD3DXVector3;
    I: integer;
    LeftAir, RightAir: Boolean;
begin
  if Car.Gear=0 then begin Car.Gear:=1; Car.GearDelay:=300; end;
  D3DXVec3Subtract(Vector, FTarget.TopObj.RPos, Car.RPos);
  Temp:=D3DXVec3Length(Vector);
  if Temp<10.0 then TargetSpeed:=0.0
   else TargetSpeed:=FTarget.Car.CarSpeed+Temp-10.0;

  Temp:=GetVectorYAngle(Vector)-GetYAngle(Car.RRot);
  while Temp>g_PI do Temp:=Temp-g_2_PI;
  while Temp<-g_PI do Temp:=Temp+g_2_PI;
  if (Abs(Temp)>g_PI_DIV_2) or Ctrl.HandBrake then begin
   if Car.Gear>-1 then begin Car.Gear:=-1; Car.GearDelay:=300; end;
   if (Car.CarSpeed>20.0) and (Car.CarSpeed<25.0) then Ctrl.HandBrake:=True;
   if Car.CarSpeed<5.0 then Ctrl.HandBrake:=False;
   if Ctrl.HandBrake then begin
    TargetSpeed:=0.0;
    if Abs(Temp)<g_PI_DIV_2 then Temp:=-Temp;
   end else Temp:=-Temp;
  end else begin
   if (Car.Gear<1) and (Abs(Temp)<g_PI_DIV_4*1.5) then begin Car.Gear:=1; Car.GearDelay:=300; end;
   if Car.Gear>-1 then Ctrl.HandBrake:=False;
  end;

  LeftAir:=True;
  RightAir:=True;
  for I:=0 to Car.TyreCount-1 do
   if Car.Tyres[I]<>nil then if Car.Tyres[I].OnGround then if Car.Tyres[I].RPos.X<0.0 then LeftAir:=False
    else if Car.Tyres[I].RPos.X>0.0 then RightAir:=False;
  if LeftAir and (not RightAir) then Temp:=1.0;
  if RightAir and (not LeftAir) then Temp:=-1.0;

  Ctrl.Steering:=(Ctrl.Steering*(100-TickCount)-Min(g_PI_DIV_4, Max(-g_PI_DIV_4, Temp))*g_INV_PI*4.0*TickCount)*0.01;
  if Temp<>0 then TargetSpeed:=Min(TargetSpeed, 13.0/Abs(Temp));

  Ctrl.Accelerate:=Max(0.0, Min(0.9, (Abs(TargetSpeed)-Abs(Car.CarSpeed))*0.25));
  Ctrl.Brake:=Max(0.0, Min(0.9, (Abs(Car.CarSpeed)-Abs(TargetSpeed))*0.25));
end;

procedure TTssAI.PedDrive(TickCount: Single; var Ctrl: TTssCarControls);
var Temp, Temp2, Temp3, Temp4: Single;
    Vector, Vector2, Vector3, Vector4, Vector5, TargetPos: TD3DXVector3;
    I, J, K, QueueIndex: integer;
    LeftAir, RightAir: Boolean;
    M1, M2: TD3DXMatrix;

  function GetLanePos(Lane, Index: integer): TD3DXVector3;
  var Seed: Cardinal;
  begin
   Seed:=RandSeed;
   with TTrafficLane(FLaneQueue[Lane]) do begin
    RandSeed:=Round(Points[Index].X*0.05+Points[Index].Z*0.05)+Cardinal(@Car);
    Result.X:=Points[Index].X+(Random(2000)-1000)*0.0005;
    Result.Y:=Points[Index].Y;
    Result.Z:=Points[Index].Z+(Random(2000)-1000)*0.0005;
   end;
   RandSeed:=Seed;
  end;
begin
 if FKickStart then Car.CarSpeed:=30;
 //if Random(5)=0 then begin
  FCars.Clear;
  D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 0.0, Car.CarSpeed+4.0), Car.RRot);
  D3DXVec3Add(Vector2, Vector, Car.RPos);
  for I:=0 to Engine.Objects.Count-1 do
   if {(Engine.Objects.Obj[I] is TTssCar) and} (Engine.Objects.Obj[I]<>Car) then
    if D3DXVec3LengthSq(VectorSubtract(Engine.Objects.Obj[I].RPos, Vector2))<Sqr(Car.CarSpeed+4.0) then
     FCars.Add(Engine.Objects[I]);
 //end;

 if not Car.Stopped then FUnTouched:=False;
 if not FUnTouched then begin
  J:=FNextPoint;
  FTargetSpeed:=20.0;//100.0;
  if (FLastPos.X=0.0) and (FLastPos.Y=0.0) and (FLastPos.Z=0.0) then FLastPos:=Car.RPos;
  Vector3:=Car.RPos;
  Temp3:=Max(8.0, Car.CarSpeed*1.0+1.0);
  QueueIndex:=0;
  Temp4:=0.0;
  if FKickStart then begin
   D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 0.0, 1.0), Car.RRot);
   D3DXVec3Scale(Car.PosMove, Vector, Car.CarSpeed);
  end;
  D3DXVec3Normalize(Vector4, Car.PosMove);
  for I:=Low(FWayPoints) to High(FWayPoints) do begin
   Temp2:=WayPointLength*(I+1);
   while True do begin
    if QueueIndex>=FLaneQueue.Count then begin
     if FLaneQueue.Count=0 then begin
      Engine.Map.CollectItems(FLaneQueue, TopObj.X-50.0, TopObj.Z-50.0, TopObj.X+50.0, TopObj.Z+50.0, TTrafficLane);
      while FLaneQueue.Count>1 do
       FLaneQueue.Delete(Random(FLaneQueue.Count));
     end else if TTrafficLane(FLaneQueue.Last).CCount=0 then Engine.Map.CollectItems(FLaneQueue, TopObj.X-25.0, TopObj.Z-25.0, TopObj.X+25.0, TopObj.Z+25.0, TTrafficLane)
      else FLaneQueue.Add(TTrafficLane(FLaneQueue.Last).Connections[Random(TTrafficLane(FLaneQueue.Last).CCount)].Lane);
     if QueueIndex>=FLaneQueue.Count then begin
      FTargetSpeed:=0;
      Break;
     end;
    end;
    D3DXVec3Subtract(Vector, TTrafficLane(FLaneQueue.Items[QueueIndex]).Points[J], Vector3);
    Vector.Y:=0.0;
    Temp:=D3DXVec3Length(Vector);
    D3DXVec3Normalize(Vector2, Vector);
    if Temp3>0.0 then
     if Temp3<Temp then begin
      D3DXVec3Add(TargetPos, Vector3, VectorScale(Vector2, Temp3));
      Temp3:=0.0;
     end;
    Temp3:=Temp3-Temp;
    if Temp2>=Temp then begin
     Temp2:=Temp2-Temp;
     Vector3:=TTrafficLane(FLaneQueue.Items[QueueIndex]).Points[J];
     Inc(J);
     if Temp3>0.0 then begin
      FLastPos:=Vector3;
      Inc(FNextPoint);
     end;
     if J>=TTrafficLane(FLaneQueue.Items[QueueIndex]).PCount then begin
      if Temp3>0.0 then begin
       FLaneQueue.Delete(0);
       FNextPoint:=0;
      end else Inc(QueueIndex);
      J:=0;
     end;
    end else Break;
   end;
   D3DXVec3Add(FWayPoints[I], Vector3, VectorScale(Vector2, Temp2));
   //if I>0 then Vector:=FWayPoints[I-1] else Vector:=Car.APos;
   if I>0 then
    for K:=0 to FCars.Count-1 do
     if SegmentPointDistanceSq(FWayPoints[I-1], FWayPoints[I], TTssCar(FCars[K]).RPos)<4.0 then
      FTargetSpeed:=Min(FTargetSpeed, ScalarProject(TTssCar(FCars[K]).PosMove, Car.PosMove)+D3DXVec3Length(VectorSubtract(TTssCar(FCars[K]).RPos, Car.RPos))-Car.CarSpeed*1.5-10.0);
   D3DXVec3Subtract(Vector, FWayPoints[I], Car.RPos);
   if D3DXVec3Length(Vector)*0.2<Car.CarSpeed then begin
    Temp:=Min(g_PI_DIV_4, ArcCos(D3DXVec3Dot(Vector2, Vector4))/(I+1)*(1.0+Car.CarSpeed*0.075));
    if IsNaN(Temp) then Temp:=0.0;
    FTargetSpeed:=Min(FTargetSpeed, Max(5.0, 100.0-120.0*Sqrt(Temp+Temp4)));
    Temp4:=Temp;
   end;
   Vector4:=Vector2;
   Vector3:=FWayPoints[I];
  end;
  if FKickStart then begin
   D3DXVec3TransformCoord(Vector, D3DXVector3(0.0, 0.0, 1.0), Car.RRot);
   D3DXVec3Scale(Car.PosMove, Vector, FTargetSpeed);
   FKickStart:=False;
  end;

  if Car.Gear=0 then begin Car.Gear:=1; Car.GearDelay:=300; end;
  D3DXVec3Subtract(Vector, TargetPos, Car.RPos);

  Temp:=GetVectorYAngle(Vector)-GetYAngle(Car.RRot);
  while Temp>g_PI do Temp:=Temp-g_2_PI;
  while Temp<-g_PI do Temp:=Temp+g_2_PI;

  LeftAir:=True;
  RightAir:=True;
  for I:=0 to Car.TyreCount-1 do
   if Car.Tyres[I]<>nil then if Car.Tyres[I].OnGround then if Car.Tyres[I].RPos.X<0.0 then LeftAir:=False
    else if Car.Tyres[I].RPos.X>0.0 then RightAir:=False;
  if LeftAir and (not RightAir) then Temp:=1.0;
  if RightAir and (not LeftAir) then Temp:=-1.0;

  Ctrl.Steering:=(Ctrl.Steering*(200.0-TickCount)-Min(g_PI_DIV_4, Max(-g_PI_DIV_4, Temp*0.9))*g_INV_PI*5.0*TickCount)*0.005;
  //if Temp<>0 then TargetSpeed:=Min(TargetSpeed, 13.0/Abs(Temp));

  Ctrl.Accelerate:=Max(0.0, Min(0.9, (Ctrl.Accelerate*(200.0-TickCount)+(FTargetSpeed-Car.CarSpeed)*0.25*TickCount)*0.005));
  Ctrl.Brake:=Max(0.0, Min(0.9, (Ctrl.Brake*(200.0-TickCount)+(Car.CarSpeed-FTargetSpeed)*0.25*TickCount)*0.005));

 end else begin

  FNextReaction:=FNextReaction-TickCount*0.001;
  if FNextReaction<=0.0 then begin
   if FNextPoint<1 then FNextPoint:=1;
   Vector3:=Car.RPos;
   FTargetSpeed:=Min(50.0, FTargetSpeed+10.0);//100.0;
   if FKickStart then Car.CarSpeed:=12.5;
   J:=FNextPoint;
   QueueIndex:=0;                                
   Temp4:=0.0;
   D3DXVec3Normalize(Vector4, Car.PosMove);
   for I:=Low(FWayPoints) to High(FWayPoints) do begin
    Temp2:=WayPointLength*(I+1);
    while True do begin
     if QueueIndex>=FLaneQueue.Count then begin
      if TTrafficLane(FLaneQueue.Last).CCount>0 then FLaneQueue.Add(TTrafficLane(FLaneQueue.Last).Connections[Random(TTrafficLane(FLaneQueue.Last).CCount)].Lane);
      if QueueIndex>=FLaneQueue.Count then Break;
     end;
     FTargetSpeed:=Min(FTargetSpeed, TTrafficLane(FLaneQueue.Items[QueueIndex]).SpeedLimit);
     if QueueIndex>0 then with TTrafficLane(FLaneQueue.Items[QueueIndex]) do
      if RoundTime<>0.0 then begin
       Temp:=FloatRemainder(Engine.FSecondTimer, RoundTime);
       if ((Temp<=EnabFrom) or (Temp>=EnabTo)) and ((Temp<=EnabFrom2) or (Temp>=EnabTo2)) then FTargetSpeed:=Min(FTargetSpeed, (D3DXVec3Length(VectorSubtract(Points[0], Car.RPos))-Max(Car.Range*0.001, Car.CarSpeed*2.25))*10.0);
      end;
     D3DXVec3Subtract(Vector, TTrafficLane(FLaneQueue.Items[QueueIndex]).Points[J], Vector3);
     Temp:=D3DXVec3Length(Vector);
     D3DXVec3Scale(Vector2, Vector, 1.0/Temp);
     if Temp2>=Temp then begin
      Temp2:=Temp2-Temp;
      Vector3:=TTrafficLane(FLaneQueue.Items[QueueIndex]).Points[J];
      Inc(J);
      if J>=TTrafficLane(FLaneQueue.Items[QueueIndex]).PCount then begin
       Inc(QueueIndex);
       J:=0;
      end;
     end else Break;
    end;
    D3DXVec3Add(FWayPoints[I], Vector3, VectorScale(Vector2, Temp2));
    if I>0 then
     for K:=0 to FCars.Count-1 do
      if SegmentPointDistanceSq(FWayPoints[I-1], FWayPoints[I], TTssObject(FCars[K]).RPos)<4.0 then
       FTargetSpeed:=Min(FTargetSpeed, (ScalarProject(TTssObject(FCars[K]).PosMove, {Car.PosMove}VectorSubtract(FWayPoints[I], FWayPoints[I-1]))-Car.CarSpeed)*50.0+Car.CarSpeed+(D3DXVec3Length(VectorSubtract(TTssObject(FCars[K]).RPos, Car.RPos))-Max((Car.Range+TTssObject(FCars[K]).Range)*0.001+1.0, Car.CarSpeed*1.0+1.0))*30.0);
    D3DXVec3Subtract(Vector, FWayPoints[I], Car.RPos);
    if D3DXVec3Length(Vector)*0.2<Car.CarSpeed then begin
     Temp:=Min(g_PI_DIV_4, ArcCos(D3DXVec3Dot(Vector2, Vector4))/(I*0.25+1.5));
     if IsNaN(Temp) then Temp:=0.0;
     FTargetSpeed:=Min(FTargetSpeed, Max(5.0, 90.0-140.0*Sqrt(Temp+Temp4)));
     Temp4:=Temp;
    end;
    Vector4:=Vector2;
    Vector3:=FWayPoints[I];
   end;
   FNextReaction:=(Random(100000)*0.000003+0.3)*Min(1.0, ((FTargetSpeed*FSpeed-Car.CarSpeed)*0.5+1.0));
  end;

  if FKickStart then Car.CarSpeed:=Max(0.0, FTargetSpeed*FSpeed);

  FLanePos:=FLanePos+TickCount*Car.CarSpeed*0.001;
  Temp:=FTargetSpeed*FSpeed;
  if Temp>Car.CarSpeed then Car.CarSpeed:=Min(Temp, Car.CarSpeed+TickCount*0.0005*Min((Temp-Car.CarSpeed)*0.5, 7.5));
  if Temp<Car.CarSpeed then Car.CarSpeed:=Max(0.0, Car.CarSpeed-TickCount*0.0005*Min(Car.CarSpeed-Temp, 20.0));

  if FLaneQueue.Count>0 then begin

   while TTrafficLane(FLaneQueue[0]).PCount>FNextPoint do
    with TTrafficLane(FLaneQueue[0]) do begin
     Temp:=D3DXVec3Length(VectorSubtract(GetLanePos(0, FNextPoint), GetLanePos(0, FNextPoint-1)));
     if FLanePos>=Temp then begin
      FLanePos:=FLanePos-Temp;
      FLastPos:=GetLanePos(0, FNextPoint-1);
      Inc(FNextPoint);
      if FNextPoint>=PCount then begin
       FNextPoint:=1;
       if FLaneQueue.Count=1 then
        if CCount>0 then FLaneQueue.Add(Connections[Random(CCount)].Lane)
         else Break;
       FLaneQueue.Delete(0);
      end;
     end else Break;
    end;

   if (FLaneQueue.Count>0) and ((Car.CarSpeed>0.001) or FKickStart) then with TTrafficLane(FLaneQueue[0]) do begin
    J:=FNextPoint+1;
    if J>=PCount then begin
     J:=1;
     if FLaneQueue.Count=1 then if CCount>0 then FLaneQueue.Add(Connections[Random(CCount)].Lane);
     if FLaneQueue.Count>1 then Vector:=GetLanePos(1, J);
    end else Vector:=GetLanePos(0, J);

    Vector5:=GetLanePos(0, FNextPoint-1);
    TargetPos:=GetLanePos(0, FNextPoint);

    Temp:=D3DXVec3Length(VectorSubtract(TargetPos, Vector5));
    D3DXVec3Subtract(Vector4, TargetPos, FLastPos);
    Vector2:=VectorScale(Vector4, Temp/(D3DXVec3Length(Vector4)*3));
    D3DXVec3Subtract(Vector4, Vector5, Vector);
    Vector3:=VectorScale(Vector4, Temp/(D3DXVec3Length(Vector4)*3));
    Vector4:=CubicBezier(Vector5, VectorAdd(Vector5, Vector2), VectorAdd(TargetPos, Vector3), TargetPos, FLanePos/Temp);
    //D3DXVec3Subtract(Vector, Points[FNextPoint], Points[FNextPoint-1]);
    //Vector4:=VectorInterPolate(Points[FNextPoint-1], Points[FNextPoint], FLanePos/D3DXVec3Length(Vector));
    //FDrivePos.X:=(FDrivePos.X+(Random(2001)-1000)*0.0000001)*(1.0-TickCount*0.0000001);
    //FDrivePos.Z:=(FDrivePos.Z+(Random(2001)-1000)*0.0000001)*(1.0-TickCount*0.0000001);

    if Car.Tyres[0]<>nil then Vector4.Y:=Vector4.Y-Car.Tyres[0].RPos.Y-Car.Tyres[0].MinPos.Y;
    if (D3DXVec3LengthSq(VectorSubtract(Vector4, Car.RPos))>Sqr(0.0001*TickCount)) or FKickStart {and (Car.FVisible)} then begin
     Vector:=CubicBezierTangent(Vector5, VectorAdd(Vector5, Vector2), VectorAdd(TargetPos, Vector3), TargetPos, FLanePos/Temp);
     Vector5:=CubicBezierTangent2(Vector5, VectorAdd(Vector5, Vector2), VectorAdd(TargetPos, Vector3), TargetPos, FLanePos/Temp);
     Vector5.Y:=0.0;
     //D3DXVec3Subtract(Vector, Vector4, Car.RPos);
     Vector2:=D3DXVector3(0.0, 0.0, 1.0);
     D3DXVec3Normalize(Vector3, D3DXVector3(Vector.X, 0.0, Vector.Z));
     Temp2:=D3DXVec3Dot(VectorNormalize(Vector), Vector3);
     if Temp2>1.0 then Temp2:=1.0; if Temp2<-1.0 then Temp2:=-1.0;
     D3DXMatrixRotationX(M1, (1-2*Ord(Vector.Y>Vector3.Y))*ArcCos(Temp2));
     Temp2:=D3DXVec3Dot(Vector2, Vector3);
     if Temp2>1.0 then Temp2:=1.0; if Temp2<-1.0 then Temp2:=-1.0;
     D3DXMatrixRotationY(M2, (1-2*Ord(Vector3.X<0))*ArcCos(Temp2));
     D3DXMatrixMultiply(Car.RRot, M1, M2);

     FTyreAngle:=(1-2*Ord((Vector.X*Vector5.Z-Vector.Z*Vector5.X)>0))*D3DXVec3Length(Vector5)/Temp*0.4;//(GetVectorYAngle(Vector5)-GetVectorYAngle(Vector));//FTyreAngle*(1.0-TickCount*0.01)+10.0*Vector5.Y*TickCount*0.01;
     D3DXVec3Scale(Car.PosMove, VectorSubtract(Vector4, Car.RPos), 1000.0/TickCount);
     for I:=0 to Car.TyreCount-1 do if Car.Tyres[I]<>nil then
      with Car.Tyres[I] do begin
       RotPos:=RotPos+Self.Car.CarSpeed*TickCount*0.0015;
       D3DXMatrixRotationX(M1, RotPos);
       if Steer then begin
        D3DXMatrixRotationY(M2, FTyreAngle);
        D3DXMatrixMultiply(M1, M1, M2);
       end;
       D3DXMatrixMultiply(RRot, OrigRot, M1);
      end;                                                                        
     FLastAngle:=Temp;
    end;
    FKickStart:=False;
    Car.RPos:=Vector4;
   end;
  end;
  
 end;
end;

constructor TTssAI.Create(AParent: TTssObject; AAutoHandle: Boolean);
begin
 inherited;
 FMode:=amPed;
 FSimulate:=False;
 FLaneQueue:=TList.Create;
 FCars:=TList.Create;
 FDirQueue:=TList.Create;
end;

destructor TTssAI.Destroy;
begin
 Dec(Engine.FAISystem.AICount);
 FDirQueue.Free;
 FCars.Free;
 FLaneQueue.Free;
 inherited;
end;

{ TAISystem }

constructor TAISystem.Create;
begin
 inherited;
 FList:=TList.Create;
 FCarNames:=TG2VArray.Create;
 FAINames:=TG2VArray.Create;
 Engine.Script.SetVariable(FCarNames.Reference, 'carNames');
 Engine.Script.SetVariable(FAINames.Reference, 'aiNames');
 FCarPool:=TList.Create;
 FPedPool:=TList.Create;
end;

destructor TAISystem.Destroy;
var I: integer;
begin
 for I:=0 to FCarPool.Count-1 do
  TTssObject(FCarPool[I]).Free;
 for I:=0 to FPedPool.Count-1 do
  TTssObject(FPedPool[I]).Free;
 FCarPool.Free;
 FPedPool.Free;
 FCarNames.Release;
 FAINames.Release;
 FList.Free;
 inherited;
end;

procedure CreateCars;
var I: integer;
    AIName, CarName: TG2Variant;
    AI: TTssAI;
begin
 if Engine.FAISystem.FCarNames.Count=0 then Exit;
 if Engine.FAISystem.FAINames.Count=0 then Exit;

 for I:=0 to 99 do begin
  AI:=TTssAI.Create(nil, False);
  AI.AutoHandle:=True;
  with Engine.FAISystem.FAINames do AIName:=IndexedItem[Random(Count)];
  AI.LoadData(AIName.Str);
  AIName.Release;
  AI.Car:=TTssCar.Create(nil, False);
  AI.Car.AutoHandle:=True;
  Engine.FAISystem.FCarPool.Add(AI.Car);
  with Engine.FAISystem.FCarNames do CarName:=IndexedItem[Random(Count)];
  AI.Car.LoadData(CarName.Str);
  CarName.Release;
 end;
end;

procedure CreatePeds;
var I: integer;
    AIName: TG2Variant;
    AI: TTssAI;
begin
 if Engine.FAISystem.FAINames.Count=0 then Exit;

 for I:=0 to 99 do begin
  AI:=TTssAI.Create(nil, False);
  with Engine.FAISystem.FAINames do AIName:=IndexedItem[Random(Count)];
  AI.LoadData(AIName.Str);
  AI.AutoHandle:=True;
  AI.FStandAni:=Engine.Animations.GetAnim(ChangeFileExt(AIName.Str, '')+'_stand.ani');
  AI.FWalkAni:=Engine.Animations.GetAnim(ChangeFileExt(AIName.Str, '')+'_walk.ani');
  AI.FRunAni:=Engine.Animations.GetAnim(ChangeFileExt(AIName.Str, '')+'_run.ani');
  AIName.Release;
  Engine.FAISystem.FPedPool.Add(AI);
 end;
end;

procedure CreateCarAI(Lane: TTrafficLane; Index: integer);
var Vector, Vector2, Vector3: TD3DXVector3;
    I: integer;
    AI: TTssAI;
    //Matrix1, Matrix2: TD3DXMatrix;
begin
 if Engine.FAiSystem.FCarPool.Count=0 then CreateCars;
 if Engine.FAiSystem.FCarPool.Count=0 then Exit;
 for I:=0 to Engine.FObjects.Count-1 do
  if D3DXVec3LengthSq(VectorSubtract(Engine.FObjects.Obj[I].RPos, Lane.Points[Index]))<Sqr((Engine.FObjects.Obj[I].Range)*0.002) then
   Exit;

 AI:=TTssAI(TTssCar(Engine.FAiSystem.FCarPool[0]).Humans[0]);
 Engine.FAiSystem.FCarPool.Delete(0);
 Engine.FObjects.Add(AI.Car);
 AI.FLaneQueue.Clear;
 AI.FLaneQueue.Add(Lane);
 AI.Car.RPos:=Lane.Points[Index];
 AI.Car.RPos.Y:=AI.Car.RPos.Y-AI.Car.MinPos.Y+0.4;
 AI.FLastPos:=VectorAdd(Lane.Points[Index], VectorSubtract(Lane.Points[Index], Lane.Points[Index+1]));
 AI.Car.OrigPos:=AI.Car.RPos;
 AI.Car.Stopped:=True;
 AI.Car.FKillTimer:=0.0;
 AI.FTargetSpeed:=2.5;
 AI.FSpeed:=Random(1000)*0.0003+0.85;
 AI.FUnTouched:=True;
 AI.FLanePos:=0.0001;
 AI.FNextReaction:=0.0;
 AI.Car.APos:=AI.Car.RPos;

 {D3DXVec3Subtract(Vector1, Lane.Points[Index+1], Lane.Points[Index]);
 Vector1.Y:=0.0;
 D3DXVec3Cross(Vector2, D3DXVector3(0.0, 0.0, 1.0), Vector1);
 if (Vector2.X=0.0) and (Vector2.Y=0.0) and (Vector2.Z=0.0) then Vector2:=D3DXVector3(0.0, 1.0, 0.0);
 D3DXMatrixRotationAxis(Matrix1, VectorNormalize(Vector2), ArcCos(D3DXVec3Dot(VectorNormalize(Vector1), D3DXVector3(0.0, 0.0, 1.0))));

 D3DXVec3Subtract(Vector3, Lane.Points[Index+1], Lane.Points[Index]);
 D3DXVec3Cross(Vector2, Vector1, Vector3);
 if (Vector2.X=0.0) and (Vector2.Y=0.0) and (Vector2.Z=0.0) then Matrix2:=Engine.IdentityMatrix
  else D3DXMatrixRotationAxis(Matrix2, VectorNormalize(Vector2), ArcCos(D3DXVec3Dot(VectorNormalize(Vector3), VectorNormalize(Vector1))));
 }
 Vector:=VectorSubtract(Lane.Points[Index+1], Lane.Points[Index]);
 Vector2:=D3DXVector3(0.0, 0.0, 1.0);
 D3DXVec3Normalize(Vector3, D3DXVector3(Vector.X, 0.0, Vector.Z));
 D3DXMatrixRotationY(AI.Car.RRot, {g_PI+}(1-2*Ord(Vector3.X<0))*ArcCos(Max(-0.99999, Min(0.99999, D3DXVec3Dot(Vector2, Vector3)))));
 AI.Car.ARot:=AI.Car.RRot;
 
 AI.Car.PosMove:=VectorScale(VectorNormalize(Vector), 12.5);
 Ai.Car.RotMove:=D3DXVector3(0.0, 0.0, 0.0);
 //D3DXMatrixMultiply(AI.Car.RRot, Matrix1, Matrix2);

 AI.FNextPoint:=Index+1;
 AI.FKickStart:=True;
 AI.Stopped:=True;
 AI.FVisible:=False;
           
 Inc(Engine.FAISystem.AICount);
end;

procedure CreateAI(Lane: TTrafficLane; Index: integer; Forw: Boolean);
var I: integer;
    AI: TTssAI;
begin
 if Engine.FAiSystem.FPedPool.Count=0 then CreatePeds;
 if Engine.FAiSystem.FPedPool.Count=0 then Exit;
 for I:=0 to Engine.FObjects.Count-1 do
  if D3DXVec3LengthSq(VectorSubtract(Engine.FObjects.Obj[I].RPos, Lane.Points[Index]))<Sqr((Engine.FObjects.Obj[I].Range)*0.001) then
   Exit;

 AI:=TTssAI(Engine.FAiSystem.FPedPool[0]);
 Engine.FAiSystem.FPedPool.Delete(0);
 Engine.FObjects.Add(AI);
 AI.FDirQueue.Clear;
 AI.FLaneQueue.Clear;
 AI.FLaneQueue.Add(Lane);
 AI.FForward:=Forw;
 AI.RPos:=Lane.Points[Index];
 AI.RPos.Y:=AI.RPos.Y-AI.MinPos.Y;
 AI.FDrivePos:=D3DXVector3((Random(2001)-1000)*0.001, 0.0, (Random(2001)-1000)*0.001);
 AI.FSpeed:=Random(1000)*0.0004+0.7;
 AI.FNextPoint:=Index-1+2*Ord(Forw);
 AI.FUnTouched:=True;
 AI.Stopped:=True;
 Inc(Engine.FAISystem.AICount);
end;

procedure TAISystem.Move(TickCount: Single);
var I, J, N, MinX, MaxX, MinZ, MaxZ: integer;
    Item: TMapItem;
    Temp1, Temp2: Single;
    Vector: TD3DXVector3;
    B, W: Boolean;
begin
 AITimer:=Min(1000.0, AITimer+TickCount);
 N:=0;
 while (AICount<Options.MaxTraffic) and (AITimer>=5.0) and (N<10) do begin
  Inc(N);
  W:=Random(4)>0;
  MinX:=Max(0,   Floor((Engine.Camera.Pos.X-80.0)/64.0));
  MaxX:=Min(255, Floor((Engine.Camera.Pos.X+80.0)/64.0));
  MinZ:=Max(0,   Floor((Engine.Camera.Pos.Z-80.0)/64.0));
  MaxZ:=Min(255, Floor((Engine.Camera.Pos.Z+80.0)/64.0));
  FList.Clear;
  for I:=MinX to MaxX do begin
   for J:=0 to Engine.Map.Tiles[I, MinZ].Count-1 do begin
    Item:=TMapItem(Engine.Map.Tiles[I, MinZ].Items[J]);
    if (Item.IType=2) and (not Item.OnList) then if TTrafficLane(Item).Walk=W then begin
     FList.Add(Item);
     Item.OnList:=True;
    end;
   end;
   for J:=0 to Engine.Map.Tiles[I, MaxZ].Count-1 do begin
    Item:=TMapItem(Engine.Map.Tiles[I, MaxZ].Items[J]);
    if (Item.IType=2) and (not Item.OnList) then if TTrafficLane(Item).Walk=W then begin
     FList.Add(Item);
     Item.OnList:=True;
    end;
   end;
  end;
  for I:=MinZ to MaxZ do begin
   for J:=0 to Engine.Map.Tiles[MinX, I].Count-1 do begin
    Item:=TMapItem(Engine.Map.Tiles[MinX, I].Items[J]);
    if (Item.IType=2) and (not Item.OnList) then if TTrafficLane(Item).Walk=W then begin
     FList.Add(Item);
     Item.OnList:=True;
    end;
   end;
   for J:=0 to Engine.Map.Tiles[MaxX, I].Count-1 do begin
    Item:=TMapItem(Engine.Map.Tiles[MaxX, I].Items[J]);
    if (Item.IType=2) and (not Item.OnList) then if TTrafficLane(Item).Walk=W then begin
     FList.Add(Item);
     Item.OnList:=True;
    end;
   end;
  end;
  for I:=0 to FList.Count-1 do
   TTrafficLane(FList.Items[I]).OnList:=False;
  if FList.Count>0 then begin
   Item:=FList.Items[Random(FList.Count)];
   J:=-1;
   with TTrafficLane(Item) do begin
    if RoundTime<>0.0 then begin
     Temp1:=FloatRemainder(Engine.FSecondTimer, RoundTime);
     B:=((Temp1<=EnabFrom) or (Temp1>=EnabTo)) and ((Temp1<=EnabFrom2) or (Temp1>=EnabTo2));
    end else B:=False;
    Temp1:=15.0;
    if not B then
     if not W then begin
      for I:=0 to PCount-2 do begin
       Temp2:=D3DXVec3Length(VectorSubtract(Points[I], Engine.Camera.Pos));
       D3DXVec3Add(Vector, Points[I], VectorScale(VectorNormalize(VectorSubtract(Points[I+1], Points[I])), 15.0));
       if D3DXVec3LengthSq(VectorSubtract(Vector, VectorAdd(Engine.Camera.Pos, Engine.Camera.AMove)))<Temp2*Temp2 then begin
        Temp2:=Abs(Temp2-88.0);
        if Temp2<Temp1 then begin
         Temp1:=Temp2;
         J:=I;
        end;
       end;
      end;
      if J>-1 then begin
       CreateCarAI(TTrafficLane(Item), J);
       AITimer:=AITimer-10.0;
      end;
     end else if Random(2)=0 then begin
      for I:=0 to PCount-2 do begin
       Temp2:=D3DXVec3Length(VectorSubtract(Points[I], Engine.Camera.Pos));
       D3DXVec3Add(Vector, Points[I], VectorScale(VectorNormalize(VectorSubtract(Points[I+1], Points[I])), 5.0));
       if D3DXVec3LengthSq(VectorSubtract(Vector, VectorAdd(Engine.Camera.Pos, Engine.Camera.AMove)))<Temp2*Temp2 then begin
        Temp2:=Abs(Temp2-88.0);
        if Temp2<Temp1 then begin
         Temp1:=Temp2;
         J:=I;
        end;
       end;
      end;
      if J>-1 then begin
       CreateAI(TTrafficLane(Item), J, True);
       AITimer:=AITimer-10.0;
      end;
     end else begin
      for I:=1 to PCount-1 do begin
       Temp2:=D3DXVec3Length(VectorSubtract(Points[I], Engine.Camera.Pos));
       D3DXVec3Add(Vector, Points[I], VectorScale(VectorNormalize(VectorSubtract(Points[I-1], Points[I])), 5.0));
       if D3DXVec3LengthSq(VectorSubtract(Vector, VectorAdd(Engine.Camera.Pos, Engine.Camera.AMove)))<Temp2*Temp2 then begin
        Temp2:=Abs(Temp2-88.0);
        if Temp2<Temp1 then begin
         Temp1:=Temp2;
         J:=I;
        end;
       end;
      end;
      if J>-1 then begin
       CreateAI(TTrafficLane(Item), J, False);
       AITimer:=AITimer-10.0;
      end;
     end;
   end;
  end;
 end;
end;

initialization
RegisterClass(TTssAI);
finalization
UnregisterClass(TTssAI);
end.
