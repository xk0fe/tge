{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Physics Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssPhysics;

interface

uses
  TssObjects, D3DX8, Direct3D8, TssUtils, Classes, TssMap, SysUtils, TssCars, Math, TssParticles,
  TssWeapons, TssAI;

type
  TBoxData = record
    AbsCorners: array[0..1, 0..1, 0..1] of TD3DXVector3;
    AbsMin, AbsMax: TD3DXVector3;
  end;

procedure Physics_CalculateOrientation(Obj: TTssObject);
procedure Physics_CalculateVertices(Obj: TTssObject; MeshLevel: integer; Matrix: PD3DMatrix);
procedure Physics_CalculateBox(Obj: TTssObject; Matrix: PD3DMatrix; var BoxData: TBoxData);

procedure Physics_AddForce(Obj: TTssObject; Dir, Orig: TD3DXVector3);
procedure Physics_MoveObject(Obj: TTssObject; TickCount: Single);

//function Physics_GetYPosInFace(Face: TMapPoly; X, Z: Double; var Normal: TD3DXVector3): Double;
function Physics_GetYPos(X, Z, MinY, MaxY: Single): Double;
function Physics_GetYPosInGroup(Group: TObject; X, Z, MinY, MaxY: Single; var ANormal: TD3DXVector3): Double;
procedure Physics_MoveCar(Obj: TTssCar; List: TList; TickCount: Single);
procedure Physics_MoveHuman(Obj: TTssHuman; List: TList; TickCount: Single);

implementation

uses
  TssEngine, TssTextures, TssControls;


procedure Physics_CalculateOrientation(Obj: TTssObject);
var V: TD3DXVector3;
begin
 with Obj do begin
  D3DXMatrixMultiply(ARot, RRot, Parent.ARot);
  D3DXVec3TransformCoord(V, RPos, Parent.ARot);
  D3DXVec3Add(APos, Parent.APos, V);
 end;
end;

procedure Physics_CalculateVertices(Obj: TTssObject; MeshLevel: integer; Matrix: PD3DMatrix);
var I, J: integer;
    V: PObjDataVertices;
begin
 if Obj.Parent=nil then begin
  Obj.ARot:=Obj.RRot;
  Obj.APos:=Obj.RPos;
 end else Physics_CalculateOrientation(Obj);
 if Matrix=nil then begin
  Obj.Matrix:=Obj.ARot;
  Obj.Matrix._41:=Obj.Matrix._41+Obj.APos.X;
  Obj.Matrix._42:=Obj.Matrix._42+Obj.APos.Y;
  Obj.Matrix._43:=Obj.Matrix._43+Obj.APos.Z;
  Matrix:=@(Obj.Matrix);
 end;
 Obj.AMinPos:=D3DXVector3( 16384, 16384, 16384);
 Obj.AMaxPos:=D3DXVector3(-16384,-16384,-16384);
 with Obj.Details[MeshLevel] do begin
  if Obj.SharedBuffers then V:=Obj.Parent.Details[MeshLevel].Vertices
   else V:=Vertices;
  for J:=0 to GroupCount-1 do with TMeshData(MeshData[J]) do
   for I:=0 to VertexCount-1 do
    with V[StartVertex+I] do begin
     D3DXVec3TransformCoord(V2, V1, Matrix^);
     Obj.AMinPos.X:=Min(Obj.AMinPos.X, V2.X);
     Obj.AMinPos.Y:=Min(Obj.AMinPos.Y, V2.Y);
     Obj.AMinPos.Z:=Min(Obj.AMinPos.Z, V2.Z);
     Obj.AMaxPos.X:=Max(Obj.AMaxPos.X, V2.X);
     Obj.AMaxPos.Y:=Max(Obj.AMaxPos.Y, V2.Y);
     Obj.AMaxPos.Z:=Max(Obj.AMaxPos.Z, V2.Z);
    end;
  PreCalculated:=Matrix^;
 end;
 if Obj.Parent<>nil then begin
  Obj.Parent.AMinPos.X:=Min(Obj.AMinPos.X, Obj.Parent.AMinPos.X);
  Obj.Parent.AMinPos.Y:=Min(Obj.AMinPos.Y, Obj.Parent.AMinPos.Y);
  Obj.Parent.AMinPos.Z:=Min(Obj.AMinPos.Z, Obj.Parent.AMinPos.Z);
  Obj.Parent.AMaxPos.X:=Max(Obj.AMaxPos.X, Obj.Parent.AMaxPos.X);
  Obj.Parent.AMaxPos.Y:=Max(Obj.AMaxPos.Y, Obj.Parent.AMaxPos.Y);
  Obj.Parent.AMaxPos.Z:=Max(Obj.AMaxPos.Z, Obj.Parent.AMaxPos.Z);
 end;
end;

procedure Physics_CalculateBox(Obj: TTssObject; Matrix: PD3DMatrix; var BoxData: TBoxData);
var X, Y, Z: integer;
begin
 with BoxData do begin
  AbsMin:=D3DXVector3( 16384, 16384, 16384);
  AbsMax:=D3DXVector3(-16384,-16384,-16384);
  D3DXVec3TransformCoord(AbsCorners[0,0,0], D3DXVector3(Obj.MinPos.X, Obj.MinPos.Y, Obj.MinPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[0,1,0], D3DXVector3(Obj.MinPos.X, Obj.MaxPos.Y, Obj.MinPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[0,0,1], D3DXVector3(Obj.MinPos.X, Obj.MinPos.Y, Obj.MaxPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[0,1,1], D3DXVector3(Obj.MinPos.X, Obj.MaxPos.Y, Obj.MaxPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[1,0,0], D3DXVector3(Obj.MaxPos.X, Obj.MinPos.Y, Obj.MinPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[1,1,0], D3DXVector3(Obj.MaxPos.X, Obj.MaxPos.Y, Obj.MinPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[1,0,1], D3DXVector3(Obj.MaxPos.X, Obj.MinPos.Y, Obj.MaxPos.Z), Matrix^);
  D3DXVec3TransformCoord(AbsCorners[1,1,1], D3DXVector3(Obj.MaxPos.X, Obj.MaxPos.Y, Obj.MaxPos.Z), Matrix^);
  for X:=0 to 1 do for Y:=0 to 1 do for Z:=0 to 1 do begin
   //D3DXVec3TransformCoord(AbsCorners[X,Y,Z], D3DXVector3(Single(Pointer(Integer(@Obj.MinPos.X)+X*12)^), Single(Pointer(Integer(@Obj.MinPos.Y)+Y*12)^), Single(Pointer(Integer(@Obj.MinPos.Z)+Z*12)^)), Matrix^);
   AbsMin.X:=Min(AbsMin.X, AbsCorners[X,Y,Z].X);
   AbsMin.Y:=Min(AbsMin.Y, AbsCorners[X,Y,Z].Y);
   AbsMin.Z:=Min(AbsMin.Z, AbsCorners[X,Y,Z].Z);
   AbsMax.X:=Max(AbsMax.X, AbsCorners[X,Y,Z].X);
   AbsMax.Y:=Max(AbsMax.Y, AbsCorners[X,Y,Z].Y);
   AbsMax.Z:=Max(AbsMax.Z, AbsCorners[X,Y,Z].Z);
  end;
 end;
end;

procedure Physics_AddForce(Obj: TTssObject; Dir, Orig: TD3DXVector3);
begin
 with Obj do begin
  if Dir.Y<>0 then Moment.X:=Moment.X-(Orig.Z-Dir.Z/Dir.Y*Orig.Y)*Dir.Y;
  if Dir.Z<>0 then Moment.X:=Moment.X+(Orig.Y-Dir.Y/Dir.Z*Orig.Z)*Dir.Z;

  if Dir.X<>0 then Moment.Y:=Moment.Y+(Orig.Z-Dir.Z/Dir.X*Orig.X)*Dir.X;
  if Dir.Z<>0 then Moment.Y:=Moment.Y-(Orig.X-Dir.X/Dir.Z*Orig.Z)*Dir.Z;

  if Dir.X<>0 then Moment.Z:=Moment.Z-(Orig.Y-Dir.Y/Dir.X*Orig.X)*Dir.X;
  if Dir.Y<>0 then Moment.Z:=Moment.Z+(Orig.X-Dir.X/Dir.Y*Orig.Y)*Dir.Y;

  if Dir.X<>0 then Force.X:=Force.X+Dir.X;
  if Dir.Y<>0 then Force.Y:=Force.Y+Dir.Y;
  if Dir.Z<>0 then Force.Z:=Force.Z+Dir.Z;
 end;
end;

{function Physics_CheckMapCollisions(Obj: TTssObject; P: TList; M: PD3DMatrix; TickCount: Single; CallCount: integer): Boolean;
var Nearest: record Poly: TMapPoly; SqrDistance: Single; CPos, Move, TN: TD3DXVector3; end;
  function CheckRectPolyCollision(RA, RB, RC: PD3DVector; Poly: TMapPoly): Boolean;
  var I, J: integer;
      TA, TB, TC: PMapVertex;
      O, A, B, A2, B2, RN, TN, Move: TD3DXVector3;
      IPos: array[0..3] of TD3DXVector3;
      Value: Single;
  begin
   Result:=False;
   A2:=MakeD3DVector(RB.X-RA.X,RB.Y-RA.Y,RB.Z-RA.Z);
   B2:=MakeD3DVector(RC.X-RA.X,RC.Y-RA.Y,RC.Z-RA.Z);
   //Check Every Triangle
   for I:=0 to Poly.VertexCount-3 do if Poly.Vertices[I].Extra=1 then begin
    case Poly.Style of
     0: if I mod 2=0 then begin //Vertex Order is Edge, I = 0,2,4... -> CW
         TA:=@Poly.Vertices[(Poly.VertexCount-I div 2) mod Poly.VertexCount];
         TB:=@Poly.Vertices[(I+2) div 2];
         TC:=@Poly.Vertices[(Poly.VertexCount-(I+2) div 2) mod Poly.VertexCount];
        end else begin          //Vertex Order is Edge, I = 1,3,5... -> CCW
         TA:=@Poly.Vertices[(I+3) div 2];
         TB:=@Poly.Vertices[(Poly.VertexCount-(I+1) div 2) mod Poly.VertexCount];
         TC:=@Poly.Vertices[(I+1) div 2];
        end;
     1,3: begin                 //Vertex Order is Triangle-Strip (First CW)
         TA:=@Poly.Vertices[I+2*Ord(I mod 2=1)];
         TB:=@Poly.Vertices[I+1];
         TC:=@Poly.Vertices[I+2*Ord(I mod 2=0)];
        end;
     else {2:}{ begin            //Vertex Order is Triangle-Strip (First CCW)
         TA:=@Poly.Vertices[I+2*Ord(I mod 2=0)];
         TB:=@Poly.Vertices[I+1];
         TC:=@Poly.Vertices[I+2*Ord(I mod 2=1)];
        end;
    end;
    O:=MakeD3DVector(TA.X*0.001,TA.Y*0.001,TA.Z*0.001);
    A:=MakeD3DVector((TB.X-TA.X)*0.001,(TB.Y-TA.Y)*0.001,(TB.Z-TA.Z)*0.001);
    B:=MakeD3DVector((TC.X-TA.X)*0.001,(TC.Y-TA.Y)*0.001,(TC.Z-TA.Z)*0.001);
    J:=0;
    Value:=VectorTriangleIntersect(@O, @A, @B, RA, MakeD3DVector(RB.X-RA.X,RB.Y-RA.Y,RB.Z-RA.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(RA.X+(RB.X-RA.X)*Value,RA.Y+(RB.Y-RA.Y)*Value,RA.Z+(RB.Z-RA.Z)*Value);
     Inc(J);
    end;
    Value:=VectorTriangleIntersect(@O, @A, @B, RA, MakeD3DVector(RC.X-RA.X,RC.Y-RA.Y,RC.Z-RA.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(RA.X+(RC.X-RA.X)*Value,RA.Y+(RC.Y-RA.Y)*Value,RA.Z+(RC.Z-RA.Z)*Value);
     Inc(J);
    end;
    Value:=VectorTriangleIntersect(@O, @A, @B, RC, MakeD3DVector(RB.X-RA.X,RB.Y-RA.Y,RB.Z-RA.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(RC.X+(RB.X-RA.X)*Value,RC.Y+(RB.Y-RA.Y)*Value,RC.Z+(RB.Z-RA.Z)*Value);
     Inc(J);
    end;
    Value:=VectorTriangleIntersect(@O, @A, @B, RB, MakeD3DVector(RC.X-RA.X,RC.Y-RA.Y,RC.Z-RA.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(RB.X+(RC.X-RA.X)*Value,RB.Y+(RC.Y-RA.Y)*Value,RB.Z+(RC.Z-RA.Z)*Value);
     Inc(J);
    end;
    O:=MakeD3DVector(TA.X*0.001,TA.Y*0.001,TA.Z*0.001);
    Value:=VectorRectIntersect(RA, @A2, @B2, @O, MakeD3DVector(TB.X*0.001-O.X,TB.Y*0.001-O.Y,TB.Z*0.001-O.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(O.X*(1-Value)+TB.X*0.001*Value,O.Y*(1-Value)+TB.Y*0.001*Value,O.Z*(1-Value)+TB.Z*0.001*Value);
     Inc(J);
    end;
    O:=MakeD3DVector(TB.X*0.001,TB.Y*0.001,TB.Z*0.001);
    Value:=VectorRectIntersect(RA, @A2, @B2, @O, MakeD3DVector(TC.X*0.001-O.X,TC.Y*0.001-O.Y,TC.Z*0.001-O.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(O.X*(1-Value)+TC.X*0.001*Value,O.Y*(1-Value)+TC.Y*0.001*Value,O.Z*(1-Value)+TC.Z*0.001*Value);
     Inc(J);
    end;
    O:=MakeD3DVector(TC.X*0.001,TC.Y*0.001,TC.Z*0.001);
    Value:=VectorRectIntersect(RA, @A2, @B2, @O, MakeD3DVector(TA.X*0.001-O.X,TA.Y*0.001-O.Y,TA.Z*0.001-O.Z));
    if Value>=0 then begin
     IPos[J]:=MakeD3DVector(O.X*(1-Value)+TA.X*0.001*Value,O.Y*(1-Value)+TA.Y*0.001*Value,O.Z*(1-Value)+TA.Z*0.001*Value);
     Inc(J);
    end;
    if J>0 then begin
     D3DXVec3Normalize(RN, MakeD3DVector(B2.Y*A2.Z-B2.Z*A2.Y, B2.Z*A2.X-B2.X*A2.Z, B2.X*A2.Y-B2.Y*A2.X)); //Rect Normal
     D3DXVec3Normalize(TN, MakeD3DVector(A.Y*B.Z-A.Z*B.Y, A.Z*B.X-A.X*B.Z, A.X*B.Y-A.Y*B.X));             //Triangle Normal
     Move:=GetMove(Obj.PosMove, Obj.RotMove, MakeD3DVector(IPos[0].X-M._41,IPos[0].Y-M._42,IPos[0].Z-M._43), TickCount);
     //engine.TestValue:=format('(%f , %f , %f) (%f , %f , %f)',[Move.X,Move.Y,Move.Z,IPos[0].X-M._41,IPos[0].Y-M._42,IPos[0].Z-M._43]);
     if (D3DXVec3Dot(RN, TN)>=-0.00001) and (D3DXVec3Dot(VectorNormalize(Move), TN)<=0.00001) then begin
      Value:=Sqr(IPos[0].X-M._41)+Sqr(IPos[0].Y-M._42)+Sqr(IPos[0].Z-M._43);
      if (Nearest.SqrDistance<0) or (Value<Nearest.SqrDistance) then begin
       Nearest.Poly:=Poly;
       Nearest.SqrDistance:=Value;
       Nearest.CPos:=IPos[0];
       Nearest.Move:=Move;
       Nearest.TN:=TN;
       Result:=True;
      end;
     end;
     if J>1 then begin
      Move:=GetMove(Obj.PosMove, Obj.RotMove, MakeD3DVector(IPos[1].X-M._41,IPos[1].Y-M._42,IPos[1].Z-M._43), TickCount);
      if (D3DXVec3Dot(RN, TN)>=-0.00001) and (D3DXVec3Dot(VectorNormalize(Move), TN)<=0.00001) then begin
       Value:=Sqr(IPos[1].X-M._41)+Sqr(IPos[1].Y-M._42)+Sqr(IPos[1].Z-M._43);
       if (Nearest.SqrDistance<0) or (Value<Nearest.SqrDistance) then begin
        Nearest.Poly:=Poly;
        Nearest.SqrDistance:=Value;
        Nearest.CPos:=IPos[1];
        Nearest.Move:=Move;
        Nearest.TN:=TN;
        Result:=True;
       end;
      end;
     end;
     if J>2 then begin
      Move:=GetMove(Obj.PosMove, Obj.RotMove, MakeD3DVector(IPos[2].X-M._41,IPos[2].Y-M._42,IPos[2].Z-M._43), TickCount);
      if (D3DXVec3Dot(RN, TN)>=-0.00001) and (D3DXVec3Dot(VectorNormalize(Move), TN)<=0.00001) then begin
       Value:=Sqr(IPos[2].X-M._41)+Sqr(IPos[2].Y-M._42)+Sqr(IPos[2].Z-M._43);
       if (Nearest.SqrDistance<0) or (Value<Nearest.SqrDistance) then begin
        Nearest.Poly:=Poly;
        Nearest.SqrDistance:=Value;
        Nearest.CPos:=IPos[2];
        Nearest.Move:=Move;
        Nearest.TN:=TN;
        Result:=True;
       end;
      end;
     end;
     if J>3 then begin
      Move:=GetMove(Obj.PosMove, Obj.RotMove, MakeD3DVector(IPos[3].X-M._41,IPos[3].Y-M._42,IPos[3].Z-M._43), TickCount);
      if (D3DXVec3Dot(RN, TN)>=-0.00001) and (D3DXVec3Dot(VectorNormalize(Move), TN)<=0.00001) then begin
       Value:=Sqr(IPos[3].X-M._41)+Sqr(IPos[3].Y-M._42)+Sqr(IPos[3].Z-M._43);
       if (Nearest.SqrDistance<0) or (Value<Nearest.SqrDistance) then begin
        Nearest.Poly:=Poly;
        Nearest.SqrDistance:=Value;
        Nearest.CPos:=IPos[3];
        Nearest.Move:=Move;
        Nearest.TN:=TN;
        Result:=True;
       end;
      end;
     end;
    end;
   end;
  end;
var New: array[0..1,0..1,0..1] of TD3DXVector3;
    MinY, MaxY: Single;
    I: integer;
    O, Temp, Temp2: TD3DXVector3;
begin
 Result:=False;

 //Calculate Object-Block Corners
 D3DXVec3TransformCoord(New[0,0,0], Obj.MinPos, M^);
 D3DXVec3TransformCoord(New[0,0,1], MakeD3DVector(Obj.MinPos.X,Obj.MinPos.Y,Obj.MaxPos.Z), M^);
 D3DXVec3TransformCoord(New[0,1,0], MakeD3DVector(Obj.MinPos.X,Obj.MaxPos.Y,Obj.MinPos.Z), M^);
 D3DXVec3TransformCoord(New[0,1,1], MakeD3DVector(Obj.MinPos.X,Obj.MaxPos.Y,Obj.MaxPos.Z), M^);
 D3DXVec3TransformCoord(New[1,0,0], MakeD3DVector(Obj.MaxPos.X,Obj.MinPos.Y,Obj.MinPos.Z), M^);
 D3DXVec3TransformCoord(New[1,0,1], MakeD3DVector(Obj.MaxPos.X,Obj.MinPos.Y,Obj.MaxPos.Z), M^);
 D3DXVec3TransformCoord(New[1,1,0], MakeD3DVector(Obj.MaxPos.X,Obj.MaxPos.Y,Obj.MinPos.Z), M^);
 D3DXVec3TransformCoord(New[1,1,1], Obj.MaxPos, M^);

 MinY:=FloatMin(FloatMin(FloatMin(New[0,0,0].Y,New[0,0,1].Y),FloatMin(New[0,1,0].Y,New[0,1,1].Y)),FloatMin(FloatMin(New[1,0,0].Y,New[1,0,1].Y),FloatMin(New[1,1,0].Y,New[1,1,1].Y)));
 MaxY:=FloatMax(FloatMax(FloatMax(New[0,0,0].Y,New[0,0,1].Y),FloatMax(New[0,1,0].Y,New[0,1,1].Y)),FloatMax(FloatMax(New[1,0,0].Y,New[1,0,1].Y),FloatMax(New[1,1,0].Y,New[1,1,1].Y)));

 Nearest.SqrDistance:=-1;
 for I:=0 to P.Count-1 do if (MinY<=TMapPoly(P.Items[I]).MaxPos.Y*0.001) and (MaxY>=TMapPoly(P.Items[I]).MinPos.Y*0.001) then begin
  if CheckRectPolyCollision(@New[1,0,0],@New[1,1,0],@New[1,0,1], TMapPoly(P.Items[I])) then Result:=True;
  if CheckRectPolyCollision(@New[0,0,0],@New[0,0,1],@New[0,1,0], TMapPoly(P.Items[I])) then Result:=True;
  if CheckRectPolyCollision(@New[0,1,0],@New[0,1,1],@New[1,1,0], TMapPoly(P.Items[I])) then Result:=True;
  if CheckRectPolyCollision(@New[0,0,0],@New[1,0,0],@New[0,0,1], TMapPoly(P.Items[I])) then Result:=True;
  if CheckRectPolyCollision(@New[0,0,1],@New[0,1,1],@New[1,0,1], TMapPoly(P.Items[I])) then Result:=True;
  if CheckRectPolyCollision(@New[0,0,0],@New[1,0,0],@New[0,1,0], TMapPoly(P.Items[I])) then Result:=True;
 end;

 if Result then with Nearest do begin
  O:=VectorProjectionNormalized(Move,TN);    
  MinY:=0.6/(0.5*Sqrt(Sqrt(Sqr(Move.X)+Sqr(Move.Y)+Sqr(Move.Z)))+0.5);
  if CallCount<2 then MaxY:=500 else MaxY:=1000;
  Physics_AddForce(Obj, MakeD3DVector(-O.X/TickCount*MaxY*Obj.Mass,-O.Y/TickCount*MaxY*Obj.Mass,-O.Z/TickCount*MaxY*Obj.Mass), MakeD3DVector((CPos.X-Obj.RPos.X)*MinY,(CPos.Y-Obj.RPos.Y)*MinY,(CPos.Z-Obj.RPos.Z)*MinY));
  if CallCount=0 then begin
   Temp2:=MakeD3DVector(Move.Y*TN.Z-Move.Z*TN.Y,Move.Z*TN.X-Move.X*TN.Z,Move.X*TN.Y-Move.Y*TN.X);
   Temp:=VectorNormalize(MakeD3DVector(Temp2.Y*TN.Z-Temp2.Z*TN.Y,Temp2.Z*TN.X-Temp2.X*TN.Z,Temp2.X*TN.Y-Temp2.Y*TN.X));
   Temp2:=VectorProjectionNormalized(Move,Temp);
   if Nearest.Poly.PolyType=3 then MaxY:=0.8 else MaxY:=0.4;
   Physics_AddForce(Obj, MakeD3DVector(-Temp2.X*MaxY*Obj.Mass,-Temp2.Y*MaxY*Obj.Mass,-Temp2.Z*MaxY*Obj.Mass), MakeD3DVector((CPos.X-Obj.RPos.X)*1.0,(CPos.Y-Obj.RPos.Y)*1.0,(CPos.Z-Obj.RPos.Z)*1.0));
   {if Nearest.Poly.PolyType<=1 then
    for I:=1 to 4*Random(Round(Sqrt(Sqrt(Sqr(Temp2.X)+Sqr(Temp2.Y)+Sqr(Temp2.Z))))) do
     with TSpark.Create(Engine.Particles) do begin
      LifeTime:=Random(1024)+512;
      Pos:=MakeD3DVector(CPos.X+(Random(256)-128)/1024,CPos.Y+(Random(256)-128)/1024,CPos.Z+(Random(256)-128)/1024);
      MinY:=Random(256)/256;
      MaxY:=Random(256)/512;
      Obj.PosMove:=MakeD3DVector(Temp2.X*MinY-O.X*MaxY,Temp2.Y*MinY-O.Y*MaxY,Temp2.Z*MinY-O.Z*MaxY);
     end;}{
  end;
 end;
end;}

var QuickMove: Boolean;

function Physics_CheckCollisions(Obj: TTssObject; Groups: TList; Matrix: PD3DMatrix; TickCount: Single; CallCount: integer): Boolean;
var BoxData, BoxData2: TBoxData;
    CollPointCount: integer;
    CollPoint, CollNormal, CollNormal2: TD3DXVector3;
    TestTarget, CollTarget: TObject;
    VerticesCalculated: Boolean;
  procedure Physics_CheckTriangle(const V1, V2, V3: TD3DXVector3);
  var V21, V31, V32: TD3DXVector3;
      A, B, C: PD3DXVector3;
    procedure Physics_CollisionPoint(const P: TD3DXVector3);
    var Move, N1: TD3DXVector3;
        tV1, tV2: TD3DXVector3;
    begin
     D3DXVec3Subtract(tV1, C^, A^);
     D3DXVec3Subtract(tV2, B^, A^);
     D3DXVec3Cross(N1, tV1, tV2);
     D3DXVec3Normalize(tV1, N1);
     Move:=GetMove(Obj.PosMove, Obj.RotMove, D3DXVector3(P.X-Matrix._41, P.Y-Matrix._42, P.Z-Matrix._43), TickCount);
     D3DXVec3Cross(N1, V21, V31);
     D3DXVec3Normalize(tV2, N1);
     if D3DXVec3Dot(VectorNormalize(Move), tV2)<=0.00001 then begin
      CollPoint.X:=(CollPoint.X*CollPointCount+P.X)/(CollPointCount+1);
      CollPoint.Y:=(CollPoint.Y*CollPointCount+P.Y)/(CollPointCount+1);
      CollPoint.Z:=(CollPoint.Z*CollPointCount+P.Z)/(CollPointCount+1);
      CollNormal.X:=CollNormal.X+tV2.X;
      CollNormal.Y:=CollNormal.Y+tV2.Y;
      CollNormal.Z:=CollNormal.Z+tV2.Z;
      CollNormal2.X:=CollNormal2.X+tV1.X;
      CollNormal2.Y:=CollNormal2.Y+tV1.Y;
      CollNormal2.Z:=CollNormal2.Z+tV1.Z;
      CollTarget:=TestTarget;
      Inc(CollPointCount);
     end;
    end;
    procedure Physics_CheckMeshTriangles;
    var I: integer;
        Temp: Single;
        HitLevel: integer;
    begin
     HitLevel:=0;
     case Obj.HitStyle of
      hsMeshLow1: HitLevel:=-1;
      hsMeshHigh1: HitLevel:=1;
     end;
     if not VerticesCalculated then begin
      Physics_CalculateVertices(Obj, HitLevel, Matrix);
      VerticesCalculated:=True;
     end;
      with Obj.Details[HitLevel] do
       for I:=0 to IndexCount div 3-1 do begin
        A:=@Vertices[Indices[I*3+0]].V2;
        B:=@Vertices[Indices[I*3+1]].V2;
        C:=@Vertices[Indices[I*3+2]].V2;
        if Min3Singles(A.X, B.X, C.X)<Max3Singles(V1.X, V2.X, V3.X) then
         if Min3Singles(A.Y, B.Y, C.Y)<Max3Singles(V1.Y, V2.Y, V3.Y) then
          if Min3Singles(A.Z, B.Z, C.Z)<Max3Singles(V1.Z, V2.Z, V3.Z) then
           if Max3Singles(A.X, B.X, C.X)>Min3Singles(V1.X, V2.X, V3.X) then
            if Max3Singles(A.Y, B.Y, C.Y)>Min3Singles(V1.Y, V2.Y, V3.Y) then
             if Max3Singles(A.Z, B.Z, C.Z)>Min3Singles(V1.Z, V2.Z, V3.Z) then begin
        Temp:=VectorTriangleIntersect(V1, V21, V31, A^, VectorSubtract(B^, A^));
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(A^, B^, Temp));
        Temp:=VectorTriangleIntersect(V1, V21, V31, B^, VectorSubtract(C^, B^));
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(B^, C^, Temp));
        Temp:=VectorTriangleIntersect(V1, V21, V31, C^, VectorSubtract(A^, C^));
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(C^, A^, Temp));

        Temp:=VectorTriangleIntersect(A^, VectorSubtract(B^, A^), VectorSubtract(C^, A^), V1, V21);
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(V1, V2, Temp));
        Temp:=VectorTriangleIntersect(A^, VectorSubtract(B^, A^), VectorSubtract(C^, A^), V1, V31);
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(V1, V3, Temp));
        Temp:=VectorTriangleIntersect(A^, VectorSubtract(B^, A^), VectorSubtract(C^, A^), V2, V32);
        if (Temp>=0) and (Temp<=1) then Physics_CollisionPoint(VectorInterpolate(V2, V3, Temp));
             end;
       end;
    end;
    function Physics_CheckTriangleSide(const P1, P2, P3: TD3DXVector3): Boolean;
    var Temp: Single;
        PA, PB: TD3DXVector3;
    begin
     Result:=False;
     D3DXVec3Subtract(PA, P2, P1);
     D3DXVec3Subtract(PB, P3, P1);
     Temp:=VectorRectIntersect(P1, PA, PB, V1, V21);
     if Obj.HitStyle<>hsBox then begin
      if (Temp>=0) and (Temp<=1) then Result:=True;
      if not Result then begin
       Temp:=VectorRectIntersect(P1, PA, PB, V2, V32);
       if (Temp>=0) and (Temp<=1) then Result:=True;
      end;
      if not Result then begin
       Temp:=VectorRectIntersect(P1, PA, PB, V1, V31);
       if (Temp>=0) and (Temp<=1) then Result:=True;
      end;
      if not Result then begin
       Temp:=VectorTriangleIntersect(V1, V21, V31, P1, PA);
       if (Temp>=0) and (Temp<=1) then Result:=True;
      end;
      if not Result then begin
       Temp:=VectorTriangleIntersect(V1, V21, V31, P1, PB);
       if (Temp>=0) and (Temp<=1) then Result:=True;
      end;
     end else begin
      A:=@P1;
      B:=@P2;
      C:=@P3;
      Temp:=VectorRectIntersect(P1, PA, PB, V1, V21);
      if (Temp>=0.0) and (Temp<=1.0) then Physics_CollisionPoint(VectorInterpolate(V1, V2, Temp));
      Temp:=VectorRectIntersect(P1, PA, PB, V2, V32);
      if (Temp>=0.0) and (Temp<=1.0) then Physics_CollisionPoint(VectorInterpolate(V2, V3, Temp));
      Temp:=VectorRectIntersect(P1, PA, PB, V1, V31);
      if (Temp>=0.0) and (Temp<=1.0) then Physics_CollisionPoint(VectorInterpolate(V1, V3, Temp));
      Temp:=VectorTriangleIntersect(V1, V21, V31, P1, PA);
      if (Temp>=0.0) and (Temp<=1.0) then Physics_CollisionPoint(VectorInterpolate(P1, P2, Temp));
      Temp:=VectorTriangleIntersect(V1, V21, V31, P1, PB);
      if (Temp>=0.0) and (Temp<=1.0) then Physics_CollisionPoint(VectorInterpolate(P1, P3, Temp));
     end;
    end;
  var Coll: Boolean;
  begin
   {if (Min3Singles(V1.Y, V2.Y, V3.Y)<BoxData.AbsMax.Y) and (Max3Singles(V1.Y, V2.Y, V3.Y)>BoxData.AbsMin.Y) then
    if (Min3Singles(V1.X, V2.X, V3.X)<BoxData.AbsMax.X) and (Max3Singles(V1.X, V2.X, V3.X)>BoxData.AbsMin.X) then
     if (Min3Singles(V1.Z, V2.Z, V3.Z)<BoxData.AbsMax.Z) and (Max3Singles(V1.Z, V2.Z, V3.Z)>BoxData.AbsMin.Z) then}
   if ((V1.Y<BoxData.AbsMax.Y) or (V2.Y<BoxData.AbsMax.Y) or (V3.Y<BoxData.AbsMax.Y)) and ((V1.Y>BoxData.AbsMin.Y) or (V2.Y>BoxData.AbsMin.Y) or (V3.Y>BoxData.AbsMin.Y)) then
    if ((V1.X<BoxData.AbsMax.X) or (V2.X<BoxData.AbsMax.X) or (V3.X<BoxData.AbsMax.X)) and ((V1.X>BoxData.AbsMin.X) or (V2.X>BoxData.AbsMin.X) or (V3.X>BoxData.AbsMin.X)) then
     if ((V1.Z<BoxData.AbsMax.Z) or (V2.Z<BoxData.AbsMax.Z) or (V3.Z<BoxData.AbsMax.Z)) and ((V1.Z>BoxData.AbsMin.Z) or (V2.Z>BoxData.AbsMin.Z) or (V3.Z>BoxData.AbsMin.Z)) then
      with BoxData do begin
       D3DXVec3Subtract(V21, V2, V1);
       D3DXVec3Subtract(V31, V3, V1);
       D3DXVec3Subtract(V32, V3, V2);
       Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[0, 0, 0], BoxData.AbsCorners[0, 0, 1], BoxData.AbsCorners[0, 1, 0]);
       if not Coll then Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[1, 0, 0], BoxData.AbsCorners[0, 0, 0], BoxData.AbsCorners[1, 1, 0]);
       if not Coll then Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[1, 0, 1], BoxData.AbsCorners[0, 0, 1], BoxData.AbsCorners[1, 0, 0]);
       if not Coll then Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[1, 1, 1], BoxData.AbsCorners[1, 0, 1], BoxData.AbsCorners[1, 1, 0]);
       if not Coll then Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[0, 1, 1], BoxData.AbsCorners[0, 0, 1], BoxData.AbsCorners[1, 1, 1]);
       if not Coll then Coll:=Physics_CheckTriangleSide(BoxData.AbsCorners[0, 1, 0], BoxData.AbsCorners[0, 1, 1], BoxData.AbsCorners[1, 1, 0]);
       if Coll then Physics_CheckMeshTriangles;
      end;
  end;
  procedure Physics_Collision_Response;
  var AForce, Move, Move1, Move2, V: TD3DXVector3;     
      Temp: Single;
      IsMoveable: Boolean;
  begin
   if CollTarget is TTssObject then with TTssObject(CollTarget) do
    if OwnMass>0 then if Static then Engine.GameMap.MakeIndividual(TTssObject(CollTarget));
   D3DXVec3Normalize(AForce, CollNormal);
   //Move2:=D3DXVector3(0,0,0);
   //Move1:=GetMove(Obj.PosMove, Obj.RotMove, D3DXVector3(CollPoint.X-Matrix._41, CollPoint.Y-Matrix._42, CollPoint.Z-Matrix._43), TickCount);
   IsMoveable:=False;
   {if CallCount<3 then} if CollTarget is TTssObject then if not TTssObject(CollTarget).Static then IsMoveable:=True;
   if IsMoveable then begin
    Move1:=GetMove(Obj.PosMove, Obj.RotMove, D3DXVector3(CollPoint.X-Matrix._41, CollPoint.Y-Matrix._42, CollPoint.Z-Matrix._43), TickCount);
    with TTssObject(CollTarget) do Move2:=GetMove(PosMove, RotMove, VectorSubtract(CollPoint, APos), TickCount);
    Move.X:=Move1.X-(Move1.X*Obj.TotMass+Move2.X*TTssObject(CollTarget).TotMass)/(Obj.TotMass+TTssObject(CollTarget).TotMass);
    Move.Y:=Move1.Y-(Move1.Y*Obj.TotMass+Move2.Y*TTssObject(CollTarget).TotMass)/(Obj.TotMass+TTssObject(CollTarget).TotMass);
    Move.Z:=Move1.Z-(Move1.Z*Obj.TotMass+Move2.Z*TTssObject(CollTarget).TotMass)/(Obj.TotMass+TTssObject(CollTarget).TotMass);
   end else Move:=GetMove(Obj.PosMove, Obj.RotMove, D3DXVector3(CollPoint.X-Matrix._41, CollPoint.Y-Matrix._42, CollPoint.Z-Matrix._43), TickCount);
   V:=VectorProjectionNormalized(Move, AForce);
   //if CallCount=0 then Temp:=250 else if CallCount=1 then Temp:=500 else Temp:=1100;
   Temp:=Min(1250, 500*(CallCount+1));
   Physics_AddForce(Obj, D3DXVector3(-V.X/TickCount*Obj.TotMass*Temp, -V.Y/TickCount*Obj.TotMass*Temp, -V.Z/TickCount*Obj.TotMass*Temp), D3DXVector3((CollPoint.X-Matrix._41)*1.0, (CollPoint.Y-Matrix._42)*1.0, (CollPoint.Z-Matrix._43)*1.0));
   Obj.Crash(CollPoint, V);
   if CallCount<3 then if CollTarget is TTssObject then with TTssObject(CollTarget) do
    if OwnMass>0 then begin
     if Static then Engine.GameMap.MakeIndividual(TTssObject(CollTarget));
     Stopped:=False;
     Physics_AddForce(TTssObject(CollTarget), D3DXVector3(V.X/TickCount*Obj.TotMass*Temp, V.Y/TickCount*Obj.TotMass*Temp, V.Z/TickCount*Obj.TotMass*Temp), D3DXVector3((CollPoint.X-APos.X)*1.0, (CollPoint.Y-APos.Y)*1.0, (CollPoint.Z-APos.Z)*1.0));
     TTssObject(CollTarget).Crash(CollPoint, VectorScale(VectorInvert(V), Obj.TotMass/TTssObject(CollTarget).TotMass));
    end else if Model.ObjType=100 then WindMove:=D3DXVector3(WindMove.X+V.Z*0.03, 0, WindMove.Z-V.X*0.03);
   if CallCount=0 then begin
    D3DXVec3Cross(AForce, Move, CollNormal);
    D3DXVec3Cross(V, AForce, CollNormal);
    AForce:=VectorProjectionNormalized(Move, VectorNormalize(V));
    Physics_AddForce(Obj, D3DXVector3(-AForce.X/TickCount*Obj.TotMass*15, -AForce.Y/TickCount*Obj.TotMass*15, -AForce.Z/TickCount*Obj.TotMass*15), D3DXVector3((CollPoint.X-Matrix._41)*2.0, (CollPoint.Y-Matrix._42)*2.0, (CollPoint.Z-Matrix._43)*2.0));
    if CollTarget is TTssObject then with TTssObject(CollTarget) do
     if OwnMass>0 then begin
      if Static then Engine.GameMap.MakeIndividual(TTssObject(CollTarget));
      Stopped:=False;
      Physics_AddForce(TTssObject(CollTarget), D3DXVector3(AForce.X/TickCount*Obj.TotMass*15, AForce.Y/TickCount*Obj.TotMass*15, AForce.Z/TickCount*Obj.TotMass*15), D3DXVector3((CollPoint.X-APos.X)*2.0, (CollPoint.Y-APos.Y)*2.0, (CollPoint.Z-APos.Z)*2.0));
     end;
   end;
   if CallCount<3 then if CollTarget is TTssObject then with TTssObject(CollTarget) do if not Static then
    if not QuickMove then begin
     QuickMove:=True;
     Move(TickCount);
     QuickMove:=False;
    end;
  end;
var I, J: integer;
begin
 Result:=False;
 CollPointCount:=0;
 VerticesCalculated:=False;
 CollPoint:=D3DXVector3(0.0, 0.0, 0.0);
 CollNormal:=D3DXVector3(0.0, 0.0, 0.0);
 Physics_CalculateBox(Obj, Matrix, BoxData);
 for I:=0 to Groups.Count-1 do begin
  TestTarget:=TObject(Groups.Items[I]);
  if TestTarget.ClassType=TMapGroup then begin with TMapGroup(TestTarget) do
   //for J:=0 to IndexCount div 3-1 do
   for J:=BitsFrom to BitsTo do
    if Bits[J] then
     Physics_CheckTriangle(Vertices[Indices[J*3+0]].V, Vertices[Indices[J*3+1]].V, Vertices[Indices[J*3+2]].V);
  end else with TTssObject(TestTarget) do begin
   if (CollPointCount>0) and (not Static) then begin
    Physics_Collision_Response;
    Result:=True;
    CollPointCount:=0;
    CollPoint:=D3DXVector3(0.0, 0.0, 0.0);
    CollNormal:=D3DXVector3(0.0, 0.0, 0.0);
   end;
   if HitStyle=hsBox then begin
    Physics_CalculateBox(TTssObject(TestTarget), @Matrix, BoxData2);
    Physics_CheckTriangle(BoxData2.AbsCorners[0, 0, 0], BoxData2.AbsCorners[0, 0, 1], BoxData2.AbsCorners[0, 1, 0]);
    Physics_CheckTriangle(BoxData2.AbsCorners[0, 1, 1], BoxData2.AbsCorners[0, 1, 0], BoxData2.AbsCorners[0, 0, 1]);

    Physics_CheckTriangle(BoxData2.AbsCorners[1, 0, 0], BoxData2.AbsCorners[0, 0, 0], BoxData2.AbsCorners[1, 1, 0]);
    Physics_CheckTriangle(BoxData2.AbsCorners[0, 1, 0], BoxData2.AbsCorners[1, 1, 0], BoxData2.AbsCorners[0, 0, 0]);

    Physics_CheckTriangle(BoxData2.AbsCorners[1, 0, 1], BoxData2.AbsCorners[0, 0, 1], BoxData2.AbsCorners[1, 0, 0]);
    Physics_CheckTriangle(BoxData2.AbsCorners[0, 0, 0], BoxData2.AbsCorners[1, 0, 0], BoxData2.AbsCorners[0, 0, 1]);

    Physics_CheckTriangle(BoxData2.AbsCorners[1, 1, 1], BoxData2.AbsCorners[1, 0, 1], BoxData2.AbsCorners[1, 1, 0]);
    Physics_CheckTriangle(BoxData2.AbsCorners[1, 0, 0], BoxData2.AbsCorners[1, 1, 0], BoxData2.AbsCorners[1, 0, 1]);

    Physics_CheckTriangle(BoxData2.AbsCorners[0, 1, 1], BoxData2.AbsCorners[0, 0, 1], BoxData2.AbsCorners[1, 1, 1]);
    Physics_CheckTriangle(BoxData2.AbsCorners[1, 0, 1], BoxData2.AbsCorners[1, 1, 1], BoxData2.AbsCorners[0, 0, 1]);

    Physics_CheckTriangle(BoxData2.AbsCorners[0, 1, 0], BoxData2.AbsCorners[0, 1, 1], BoxData2.AbsCorners[1, 1, 0]);
    Physics_CheckTriangle(BoxData2.AbsCorners[1, 1, 1], BoxData2.AbsCorners[1, 1, 0], BoxData2.AbsCorners[0, 1, 1]);
   end else with CollDetails^ do
    for J:=BitsFrom to BitsTo do
     if Bits[J] then
      Physics_CheckTriangle(Vertices[Indices[J*3+0]].V2, Vertices[Indices[J*3+1]].V2, Vertices[Indices[J*3+2]].V2);
  end;
 end;
 if CollPointCount>0 then begin
  Physics_Collision_Response;
  Result:=True;
 end;
end;

function Physics_CheckCollisionsRay(Obj: TTssObject; Groups: TList; Matrix: PD3DMatrix; TickCount: Single; CallCount: integer): Boolean;
var TestTarget: TObject;
    vFrom, vTo: TD3DXVector3;
  procedure Physics_CheckTriangle(const V1, V2, V3: TD3DXVector3);
  var Temp: Single;
  begin
   Temp:=VectorTriangleIntersect(V1, VectorSubtract(V2, V1), VectorSubtract(V3, V1), vFrom, VectorSubtract(vTo, vFrom));
   if (Temp>=0) and (Temp<=1) then Obj.Stopped:=True;//Physics_CollisionPoint(VectorInterpolate(V2, V3, Temp));
  end;
var I, J: integer;
begin
 vFrom:=Obj.RPos;
 vTo:=D3DXVector3(Matrix._41, Matrix._42, Matrix._43);
 for I:=0 to Groups.Count-1 do begin
  TestTarget:=TObject(Groups.Items[I]);
  if TestTarget is TMapGroup then begin with TMapGroup(TestTarget) do
   for J:=BitsFrom to BitsTo do
    if Bits[J] then
     Physics_CheckTriangle(Vertices[Indices[J*3+0]].V, Vertices[Indices[J*3+1]].V, Vertices[Indices[J*3+2]].V);
  end else if TestTarget is TTssObject then begin with TTssObject(TestTarget).CollDetails^ do
   for J:=BitsFrom to BitsTo do
    if Bits[J] then
     Physics_CheckTriangle(Vertices[Indices[J*3+0]].V2, Vertices[Indices[J*3+1]].V2, Vertices[Indices[J*3+2]].V2);
  end;
 end;
 Result:=False;
end;

var
  FirstMove: Boolean;
  NeedCollect: Boolean;

procedure Physics_MoveObject(Obj: TTssObject; TickCount: Single);
var NewPos: TD3DXVector3;
    NewRot: TD3DMatrix;
    CallCount: integer;
    MaxEnergy: Single;
    Groups: TList;

  procedure ProcessForce;
  begin
   with Obj do begin
    PosMove.X:=PosMove.X+Force.X/TotMass*TickCount*0.001;
    PosMove.Y:=PosMove.Y+Force.Y/TotMass*TickCount*0.001;
    PosMove.Z:=PosMove.Z+Force.Z/TotMass*TickCount*0.001;
    Force:=MakeD3DVector(0,0,0);
    if not FNoRot then begin
     RotMove.X:=RotMove.X+Moment.X/TotMass*TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
     RotMove.Y:=RotMove.Y+Moment.Y/TotMass*TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
     RotMove.Z:=RotMove.Z+Moment.Z/TotMass*TickCount*0.001/Max(Max(MaxPos.Z-MinPos.Z, MaxPos.X-MinPos.X), MaxPos.Y-MinPos.Y);
    end;
    Moment:=MakeD3DVector(0,0,0);
   end;
  end;
  function DoMove(Check: Boolean): Boolean;
  var NowEnergy: Single;
      mat: TD3DMatrix;
      Vector: TD3DXVector3;
      B: Boolean;
  begin
   with Obj do begin
    ProcessForce;
    {PosMove.X:=PosMove.X+Force.X/Mass*TickCount*0.001;
    PosMove.Y:=PosMove.Y+Force.Y/Mass*TickCount*0.001;
    PosMove.Z:=PosMove.Z+Force.Z/Mass*TickCount*0.001;
    Force:=MakeD3DVector(0,0,0);
    RotMove.X:=RotMove.X+Moment.X/Mass*TickCount*0.0004;
    RotMove.Y:=RotMove.Y+Moment.Y/Mass*TickCount*0.0004;
    RotMove.Z:=RotMove.Z+Moment.Z/Mass*TickCount*0.0004;
    Moment:=MakeD3DVector(0,0,0);}

    if CallCount=0 then MaxEnergy:=Sqrt(Sqr(PosMove.X)+Sqr(PosMove.Y)+Sqr(PosMove.Z))+0.01*Sqrt(Sqr(RotMove.X)+Sqr(RotMove.Y)+Sqr(RotMove.Z))
     else begin
      NowEnergy:=Sqrt(Sqr(PosMove.X)+Sqr(PosMove.Y)+Sqr(PosMove.Z))+0.01*Sqrt(Sqr(RotMove.X)+Sqr(RotMove.Y)+Sqr(RotMove.Z));
      if NowEnergy>MaxEnergy then begin
       PosMove.X:=PosMove.X*MaxEnergy/NowEnergy;
       PosMove.Y:=PosMove.Y*MaxEnergy/NowEnergy;
       PosMove.Z:=PosMove.Z*MaxEnergy/NowEnergy;
       RotMove.X:=RotMove.X*MaxEnergy/NowEnergy;      
       RotMove.Y:=RotMove.Y*MaxEnergy/NowEnergy;
       RotMove.Z:=RotMove.Z*MaxEnergy/NowEnergy;
      end;
     end;
    NewPos:=RPos;
    NewRot:=RRot;
     if Abs(PosMove.X)>0.0 then NewPos.X:=RPos.X+PosMove.X*(TickCount/1000);
     if Abs(PosMove.Y)>0.0 then NewPos.Y:=RPos.Y+PosMove.Y*(TickCount/1000);
     if Abs(PosMove.Z)>0.0 then NewPos.Z:=RPos.Z+PosMove.Z*(TickCount/1000);
     {if Abs(RotMove.X)>0.0 then begin
      matOld:=NewRot;
      D3DXMatrixRotationX(mat, RotMove.X*(TickCount/1000));
      D3DXMatrixMultiply(NewRot, matOld, mat);
     end;
     if Abs(RotMove.Y)>0.0 then begin
      matOld:=NewRot;
      D3DXMatrixRotationY(mat, RotMove.Y*(TickCount/1000));
      D3DXMatrixMultiply(NewRot, matOld, mat);
     end;
     if Abs(RotMove.Z)>0.0 then begin
      matOld:=NewRot;
      D3DXMatrixRotationZ(mat, RotMove.Z*(TickCount/1000));
      D3DXMatrixMultiply(NewRot, matOld, mat);
     end;}
     D3DXMatrixRotationYawPitchRoll(mat, RotMove.Y*TickCount*0.001, RotMove.X*TickCount*0.001, RotMove.Z*TickCount*0.001);
     D3DXMatrixMultiply(NewRot, RRot, mat);
    if CallCount=0 then begin
     if ((PosMove.X<>0) or (PosMove.Y<>0) or (PosMove.Z<>0)) and (TotMass>0) then begin
      Vector:=VectorNormalize(PosMove);
      Force.X:=Force.X-(PosMove.X*AirResistance+Vector.X*AirResistance*13.33)*TotMass*0.001;
      Force.Y:=Force.Y-(PosMove.Y*AirResistance+Vector.Y*AirResistance*13.33)*TotMass*0.001;
      Force.Z:=Force.Z-(PosMove.Z*AirResistance+Vector.Z*AirResistance*13.33)*TotMass*0.001;
     end;
     B:=Obj is TTssCar;
     if B then B:=TTssCar(Obj).Controls.HandBrake;
     if not B then begin
      RotMove.Y:=RotMove.Y*Power(0.999,TickCount);
      RotMove.Y:=RotMove.Y-(1-2*Ord(RotMove.Y<0))*TickCount*0.0003;
     end;
    end;
    mat:=NewRot;
    mat._41:=NewPos.X;
    mat._42:=NewPos.Y;
    mat._43:=NewPos.Z;
    //Result:=not Physics_CheckMapCollisions(Obj, Polygons, @mat, TickCount, CallCount);
    if Check then begin
     case Obj.HitStyle of
      hsRay: Result:=not Physics_CheckCollisionsRay(Obj, Groups, @mat, TickCount, CallCount);
      else Result:=not Physics_CheckCollisions(Obj, Groups, @mat, TickCount, CallCount);
     end;
    end else Result:=True;
   end;
  end;

begin
 // Check if object is really moving
 if (Abs(Obj.RotMove.X)>0.2) or (Abs(Obj.RotMove.Y)>0.2) or (Abs(Obj.RotMove.Z)>0.2) or
    (Abs(Obj.PosMove.X)>0.2) or (Abs(Obj.PosMove.Y)>0.2) or (Abs(Obj.PosMove.Z)>0.2)
 then Obj.LastMove:=0
 else begin
  Obj.LastMove:=Obj.LastMove+TickCount;
  if Obj.LastMove>1000 then begin
   Obj.LastMove:=0;
   Obj.Stopped:=True;
   Exit;
  end;
 end;

 Groups:=TList.Create;
 //Engine.GameMap.CollectPolygonsEx(Polygons, Round(Obj.RPos.X*1000), Round(Obj.RPos.Z*1000), Obj.Range);
 if Obj.IgnoreObj then Engine.Map.CollectGroups(Groups, Obj.RPos.X, Obj.RPos.Y, Obj.RPos.Z, Obj.Range*0.001+D3DXVec3Length(Obj.PosMove)*TickCount*0.001)
  else Engine.CollectGroups(Groups, Obj, Obj.RPos.X, Obj.RPos.Y, Obj.RPos.Z, Obj.Range*0.001+D3DXVec3Length(Obj.PosMove)*TickCount*0.001);
 
 FirstMove:=True;
 NeedCollect:=False;
 if QuickMove then begin
  CallCount:=0;
  if DoMove(True) then begin
   Obj.RPos:=NewPos;
   Obj.RRot:=NewRot;
  end;
  NeedCollect:=True;
 end else begin
  CallCount:=0;
  if Obj is TTssCar then begin
   TickCount:=TickCount/2;
   Physics_MoveCar(TTssCar(Obj), Groups, TickCount);
   Obj.Force.Y:=Obj.Force.Y-Obj.Gravitation*Obj.TotMass;
   while (not DoMove(True)) and (CallCount<6) do Inc(CallCount);
   Obj.RPos:=NewPos;
   Obj.RRot:=NewRot;
   FirstMove:=False;
   if NeedCollect then Engine.CollectGroups(Groups, Obj, Obj.RPos.X, Obj.RPos.Y, Obj.RPos.Z, Obj.Range*0.001+D3DXVec3Length(Obj.PosMove)*TickCount*0.001);
   Physics_MoveCar(TTssCar(Obj), Groups, TickCount);
  end else if ((Obj is TTssAI) and (Obj.ScriptCreated)) or (Obj is TTssPlayer) then Physics_MoveHuman(TTssHuman(Obj), Groups, TickCount);
  if not Obj.Manual then begin
   Obj.Force.Y:=Obj.Force.Y-Obj.Gravitation*Obj.TotMass;
   while (not DoMove(True)) and (CallCount<6) do Inc(CallCount);
   Obj.RPos:=NewPos;
   Obj.RRot:=NewRot;
  end;
 end;

 Groups.Free;
end;

{function Physics_GetYPosInFace(Face: TMapPoly; X, Z: Double; var Normal: TD3DXVector3): Double;
var V1, V2: TD3DXVector3;
    X1, Z1, X2, Z2, X3, Z3: Single;
    L, A, B, C: integer;
    Diff: Double;
begin
 Result:=-256*256*256;
 for L:=0 to Face.VertexCount-3 do if Face.Vertices[L].Extra=1 then begin
   case Face.Style of
     0: if L mod 2=0 then begin //Vertex Order is Edge, I = 0,2,4... -> CW
         A:=(Face.VertexCount-L div 2) mod Face.VertexCount;
         B:=(L+2) div 2;
         C:=(Face.VertexCount-(L+2) div 2) mod Face.VertexCount;
        end else begin          //Vertex Order is Edge, I = 1,3,5... -> CCW
         A:=(L+3) div 2;
         B:=(Face.VertexCount-(L+1) div 2) mod Face.VertexCount;
         C:=(L+1) div 2;
        end;
     1,3: begin                 //Vertex Order is Triangle-Strip (First CW)
         A:=L+2*Ord(L mod 2=1);
         B:=L+1;
         C:=L+2*Ord(L mod 2=0);
        end;
     else {2:}{ begin            //Vertex Order is Triangle-Strip (First CCW)
         A:=L+2*Ord(L mod 2=0);
         B:=L+1;
         C:=L+2*Ord(L mod 2=1);
        end;
   end;
   X1:=X-Face.Vertices[A].X/1000;
   Z1:=Z-Face.Vertices[A].Z/1000;
   Diff:=Sqrt(Sqr(X1)+Sqr(Z1));
   if Diff=0 then Diff:=0.000001;
   X1:=X1/Diff;                                                                      
   Z1:=Z1/Diff;
   X2:=X-Face.Vertices[B].X/1000;
   Z2:=Z-Face.Vertices[B].Z/1000;
   Diff:=Sqrt(Sqr(X2)+Sqr(Z2));
   if Diff=0 then Diff:=0.000001;
   X2:=X2/Diff;
   Z2:=Z2/Diff;
   X3:=X-Face.Vertices[C].X/1000;
   Z3:=Z-Face.Vertices[C].Z/1000;
   Diff:=Sqrt(Sqr(X3)+Sqr(Z3));
   if Diff=0 then Diff:=0.000001;                       
   X3:=X3/Diff;
   Z3:=Z3/Diff;
   if Abs(ArcSin(X1*X2+Z1*Z2)+ArcSin(X2*X3+Z2*Z3)+ArcSin(X3*X1+Z3*Z1)+g_PI_DIV_2)<=0.001 then begin
    V1:=MakeD3DVector((Face.Vertices[B].X-Face.Vertices[A].X)/1000,(Face.Vertices[B].Y-Face.Vertices[A].Y)/1000,(Face.Vertices[B].Z-Face.Vertices[A].Z)/1000);
    V2:=MakeD3DVector((Face.Vertices[C].X-Face.Vertices[A].X)/1000,(Face.Vertices[C].Y-Face.Vertices[A].Y)/1000,(Face.Vertices[C].Z-Face.Vertices[A].Z)/1000);
    Normal:=VectorNormalize(MakeD3DVector((V1.Y*V2.Z-V2.Y*V1.Z),(V1.Z*V2.X-V2.Z*V1.X),(V1.X*V2.Y-V2.X*V1.Y)));
    if Normal.Y=0 then Normal.Y:=0.000001;
    Result:=Face.Vertices[A].Y/1000+Normal.X/Normal.Y*(Face.Vertices[A].X/1000-X)+Normal.Z/Normal.Y*(Face.Vertices[A].Z/1000-Z);
    case Face.PolyType of
     0: if (Round(X*8) mod 8=0) or (Round(Z*8) mod 8=0) then Result:=Result-0.025;
     1: Result:=Result+96*IJ_AsphaltBumps-(Abs(48-Round(X*24) mod 96)+Abs(48-Round(Z*24) mod 96))*IJ_AsphaltBumps-(Abs(48-Round(X*10) mod 96)+Abs(48-Round(Z*10) mod 96))*IJ_AsphaltBumps;
     2: Result:=Result+96*IJ_GrassBumbs-(Abs(48-Round(X*24) mod 96)+Abs(48-Round(Z*24) mod 96))*IJ_GrassBumbs-(Abs(48-Round(X*10) mod 96)+Abs(48-Round(Z*10) mod 96))*IJ_GrassBumbs;
     3: Result:=Result+24*0.001+24*0.002-(Abs(48-Round(X*24) mod 96)+Abs(48-Round(Z*24) mod 96))*0.0015-(Abs(48-Round(X*10) mod 96)+Abs(48-Round(Z*10) mod 96))*0.003;
    end;
    Break;
   end;                           
 end;
end;}

function Physics_GetYPos(X, Z, MinY, MaxY: Single): Double;
var Normal: TD3DXVector3;
    Temp: Double;
    I: integer;
    List: TList;
begin
 Result:=MinY;
 List:=TList.Create;
 Engine.CollectGroups(List, nil, X, (MinY+MaxY)/2, Z, (MaxY-MinY)/2);
 for I:=0 to List.Count-1 do begin
  Temp:=Physics_GetYPosInGroup(TObject(List.Items[I]), X, Z, MinY, MaxY, Normal);
  if Temp>=Result then Result:=Temp;
 end;
 List.Free;
end;

function Physics_GetYPosInGroup(Group: TObject; X, Z, MinY, MaxY: Single; var ANormal: TD3DXVector3): Double;
var I: integer;
    A, B, C: PD3DXVector3;
    Temp: Double;
    Normal: TD3DXVector3;
    Material: TTssMaterial;
  function CheckPoly: Double;
  var V1, V2: TD3DXVector3;
      {X1, Z1, X2, Z2, X3, Z3: Single;
      Diff: Double;}
      Temp: Single;
  begin
  { X1:=X-A.X;
   Z1:=Z-A.Z;
   Diff:=Sqrt(Sqr(X1)+Sqr(Z1));
   if Diff=0 then Diff:=0.000001;
   X1:=X1/Diff;
   Z1:=Z1/Diff;
   X2:=X-B.X;
   Z2:=Z-B.Z;
   Diff:=Sqrt(Sqr(X2)+Sqr(Z2));
   if Diff=0 then Diff:=0.000001;
   X2:=X2/Diff;
   Z2:=Z2/Diff;
   X3:=X-C.X;
   Z3:=Z-C.Z;
   Diff:=Sqrt(Sqr(X3)+Sqr(Z3));
   if Diff=0 then Diff:=0.000001;
   X3:=X3/Diff;
   Z3:=Z3/Diff;
   Result:=-16384;
   if Abs(ArcSin(X1*X2+Z1*Z2)+ArcSin(X2*X3+Z2*Z3)+ArcSin(X3*X1+Z3*Z1)+g_PI_DIV_2)<=0.001 then begin}
   Result:=-16384;
   Temp:=VectorTriangleIntersect(A^, VectorSubtract(B^, A^), VectorSubtract(C^, A^), D3DXVector3(X, MaxY, Z), D3DXVector3(0.0, MinY-MaxY, 0.0));
   if (Temp>=0) and (Temp<=1.0) then begin
    V1:=MakeD3DVector(B.X-A.X,B.Y-A.Y,B.Z-A.Z);
    V2:=MakeD3DVector(C.X-A.X,C.Y-A.Y,C.Z-A.Z);
    Normal:=VectorNormalize(MakeD3DVector((V1.Y*V2.Z-V2.Y*V1.Z),(V1.Z*V2.X-V2.Z*V1.X),(V1.X*V2.Y-V2.X*V1.Y)));
    if Normal.Y=0 then Normal.Y:=0.000001;
    Result:=A.Y+Normal.X/Normal.Y*(A.X-X)+Normal.Z/Normal.Y*(A.Z-Z);
    if (Material.BumpVert>0) and (Material.BumpHorz>0) then
     Result:=Result+Abs(1.0-(FloatRemainder(X, Material.BumpHorz*0.1)+FloatRemainder(Z, Material.BumpHorz*0.1))/Material.BumpHorz*10)*Material.BumpVert*0.001-Material.BumpVert*0.0005+Abs(1.0-(FloatRemainder(X, Material.BumpHorz*0.5)+FloatRemainder(Z, Material.BumpHorz*0.5))/Material.BumpHorz*2)*Material.BumpVert*0.001-Material.BumpVert*0.0005;
    if (Material.MatType=MATTYPE_SAND) or (Material.MatType=MATTYPE_GRASS) then Result:=Result-0.05;
   end;
  end;
begin
 Result:=-16384;
 if Group.ClassType=TMapGroup then begin
  Material:=TMapGroup(Group).Material;
  with TMapGroup(Group) do begin
  //for I:=0 to IndexCount div 3-1 do
  for I:=BitsFrom to BitsTo do
   if Bits[I] then begin
    A:=@(Vertices[Indices[I*3+0]].V);
    B:=@(Vertices[Indices[I*3+1]].V);
    C:=@(Vertices[Indices[I*3+2]].V);                
    //if (Min3Singles(A.X, B.X, C.X)<X) and (Min3Singles(A.Z, B.Z, C.Z)<Z) and (Min3Singles(A.Y, B.Y, C.Y)<MaxY) and (Max3Singles(A.X, B.X, C.X)>X) and (Max3Singles(A.Z, B.Z, C.Z)>Z) and (Max3Singles(A.Y, B.Y, C.Y)>MinY) then begin
    if ((A.Y<MaxY) or (B.Y<MaxY) or (C.Y<MaxY)) and ((A.Y>MinY) or (B.Y>MinY) or (C.Y>MinY)) then
     if ((A.X<X) or (B.X<X) or (C.X<X)) and ((A.X>X) or (B.X>X) or (C.X>X)) then
      if ((A.Z<Z) or (B.Z<Z) or (C.Z<Z)) and ((A.Z>Z) or (B.Z>Z) or (C.Z>Z)) then begin
     Temp:=CheckPoly;
     if Temp>Result then begin
      Result:=Temp;
      ANormal:=Normal;
      if ANormal.X=0 then ANormal.X:=0.0001;
      if ANormal.Z=0 then ANormal.Z:=0.0001;
     end;
     //if Result>-16384 then Exit;
    end;
   end;
  end;
 end else {if Group is TTssObject then} begin
  Material:=Engine.Material;
  with TTssObject(Group).CollDetails^ do
  for I:=BitsFrom to BitsTo do
   if Bits[I] then begin
    A:=@(Vertices[Indices[I*3+0]].V2);
    B:=@(Vertices[Indices[I*3+1]].V2);
    C:=@(Vertices[Indices[I*3+2]].V2);
    //if (Min3Singles(A.X, B.X, C.X)<X) and (Min3Singles(A.Z, B.Z, C.Z)<Z) and (Min3Singles(A.Y, B.Y, C.Y)<MaxY) and (Max3Singles(A.X, B.X, C.X)>X) and (Max3Singles(A.Z, B.Z, C.Z)>Z) and (Max3Singles(A.Y, B.Y, C.Y)>MinY) then begin
    if ((A.Y<MaxY) or (B.Y<MaxY) or (C.Y<MaxY)) and ((A.Y>MinY) or (B.Y>MinY) or (C.Y>MinY)) then
     if ((A.X<X) or (B.X<X) or (C.X<X)) and ((A.X>X) or (B.X>X) or (C.X>X)) then
      if ((A.Z<Z) or (B.Z<Z) or (C.Z<Z)) and ((A.Z>Z) or (B.Z>Z) or (C.Z>Z)) then begin
     Temp:=CheckPoly;
     if Temp>Result then begin
      Result:=Temp;
      ANormal:=Normal;
     end;
     //if Result>-16384 then Exit;
    end;
   end;
 end;
end;

procedure Physics_MoveHuman(Obj: TTssHuman; List: TList; TickCount: Single);
var I: integer;
    Temp, Temp2: Single;
    Vector: TD3DXVector3;
begin
 Temp2:=-16384.0;
 for I:=0 to List.Count-1 do begin
   Temp:=Physics_GetYPosInGroup(TObject(List.Items[I]), Obj.RPos.X, Obj.RPos.Z, Obj.RPos.Y+Obj.MinPos.Y-0.1, Obj.RPos.Y, Vector);
   if (Temp>=Obj.RPos.Y+Obj.MinPos.Y-0.1) and (Temp<=Obj.RPos.Y+0.5) and (Temp-Obj.MinPos.Y>Temp2) then begin
    Temp2:=Temp-Obj.MinPos.Y-0.1;
   end;
 end;
 if Temp2>Obj.RPos.Y then Obj.RPos.Y:=Temp2;      
 if Obj.Animation=Obj.FJumpAni then begin
  Obj.AnimSpeed:=2.0-Obj.AnimPos;
  if Obj.AnimPos>0.9 then Obj.Animation:=nil;                        
 end else begin
  if Obj.Animation=Obj.FRunAni then Obj.AnimSpeed:=Obj.Controls.WalkZ*1.75
   else Obj.AnimSpeed:=Obj.Controls.WalkZ*3.5;
 end;
 D3DXMatrixRotationY(Obj.RRot, GetYAngle(Obj.RRot)+Obj.Controls.TurnY*4);
 if Obj.Controls.WalkZ=0.0 then begin
  D3DXVec3TransformCoord(Vector, D3DXVector3(Obj.Controls.WalkX*5.0, 0.0, 0.0), Obj.RRot);
  if Obj.Animation<>Obj.FJumpAni then Obj.Animation:=Obj.FStandAni;
 end else if Obj.Controls.WalkZ>0.8 then begin
  D3DXVec3TransformCoord(Vector, D3DXVector3(Obj.Controls.WalkX*5.0, 0.0, Obj.Controls.WalkZ*7.5), Obj.RRot);
  if Obj.Animation<>Obj.FJumpAni then Obj.Animation:=Obj.FRunAni;
 end else begin
  engine.TestValue:=inttostr(integer(Obj.Animation))+', '+inttostr(integer(Obj.FJumpAni));
  D3DXVec3TransformCoord(Vector, D3DXVector3(Obj.Controls.WalkX*5.0, 0.0, Obj.Controls.WalkZ*7.5), Obj.RRot);
  if Obj.Animation<>Obj.FJumpAni then Obj.Animation:=Obj.FWalkAni;
 end; 
 Obj.PosMove.X:=Vector.X;
 Obj.PosMove.Z:=Vector.Z;
 if Temp2>-16384.0 then if Obj is TTssPlayer then if Engine.Controls.GameKeyDown(keyWalkJump, -1) then begin
  Obj.PosMove.Y:=7.5;
  Obj.AnimPos:=0.0;
  Obj.Animation:=Obj.FJumpAni;
 end; 
end;

procedure Physics_MoveCar(Obj: TTssCar; List: TList; TickCount: Single);
var Vector, Vector2, Vector3, Vector4, Normal: TD3DXVector3;
    Speed, TargetRPM, Temp1, Temp2, Temp3, TyreY, SusForce, SideForce: Single;
    mat, mat2, Rot: TD3DMatrix;
    I, J: integer;
    //CollFace: TMapPoly;
    Material: TTssMaterial;
    TotalAccGrip: Single;
begin
 with Obj do begin
 APos:=RPos;
 ARot:=RRot;
 //CollFace:=nil;

 Speed:=Sqrt(PosMove.X*PosMove.X+PosMove.Y*PosMove.Y+PosMove.Z*PosMove.Z);

 if GearDelay>0 then GearDelay:=Max(0, GearDelay-TickCount);
 D3DXVec3TransformCoord(Vector2, MakeD3DVector(0,0,1), RRot);
 Vector.X:=Vector2.X*Speed;
 Vector.Y:=Vector2.Y*Speed;
 Vector.Z:=Vector2.Z*Speed;
 if Abs(PosMove.X)<Abs(Vector.X) then Vector.X:=PosMove.X;
 if Abs(PosMove.Y)<Abs(Vector.Y) then Vector.Y:=PosMove.Y;
 if Abs(PosMove.Z)<Abs(Vector.Z) then Vector.Z:=PosMove.Z;
 CarSpeed:=Sqrt(Vector.X*Vector.X+Vector.Y*Vector.Y+Vector.Z*Vector.Z);
 Physics_AddForce(Obj, MakeD3DVector(0, -Obj.Misc_DownForce*CarSpeed, 0), MakeD3DVector(0, 0, 0));

 Forw:=Sqrt(Sqr(Vector2.X-PosMove.X)+Sqr(Vector2.Y-PosMove.Y)+Sqr(Vector2.Z-PosMove.Z))<Speed+0.8;

 Obj.GearChanged:=Obj.GearChanged+TickCount*0.001;
 if Gear<>0 then TargetRPM:=Abs(CarSpeed/Obj.FGears_Ratio[Gear])
  else TargetRPM:=0;
 //if Obj.GearChanged>2.0 then begin
  if (TargetRPM>Obj.Gears_NextRPM+Max(1000-Obj.GearChanged*1000, 0)) and (Gear<Obj.FGears_Count) and (Gear>0) then begin Inc(Gear); GearDelay:=Round(Obj.Gears_ChangeDelay); Obj.GearChanged:=0.0; end;
  if (TargetRPM<Obj.Gears_PrevRPM-Max(1000-Obj.GearChanged*500, 0)+(Gear-2)*250-500) and (Gear>1) then begin Dec(Gear); GearDelay:=Round(Obj.Gears_ChangeDelay); Obj.GearChanged:=0.0; end;
 //end;

 //RotMove.Y:=RotMove.Y-(1-2*Ord(RotMove.Y<0))*0.005*Sqr(RotMove.Y);

 TotalAccGrip:=1;
 for I:=0 to TyreCount-1 do if Tyres[I]<>nil then
  if Tyres[I].Accelerate then TotalAccGrip:=TotalAccGrip+Max(10.0, Tyres[I].BadGrip);

 for I:=0 to TyreCount-1 do if Tyres[I]<>nil then begin
  Tyres[I].RPos.Y:=Tyres[I].OrigY;
  if Tyres[I].Steer then begin
   if ((Tyres[I].RPos.X>0) and (Controls.Steering>0)) or ((Tyres[I].RPos.X<0) and (Controls.Steering<0)) then D3DXMatrixRotationY(mat, -(1-2*Ord(Tyres[I].RPos.Z<0))*0.75*Controls.Steering/(CarSpeed*Obj.Steering_Adjust+Obj.Steering_MaxInv))
    else D3DXMatrixRotationY(mat, -(1-2*Ord(Tyres[I].RPos.Z<0))*Controls.Steering/(Ord(Forw)*CarSpeed*Obj.Steering_Adjust+Obj.Steering_MaxInv));
  end else mat:=Engine.IdentityMatrix;
  D3DXMatrixMultiply(Rot, mat, Obj.ARot);
  Physics_CalculateOrientation(Tyres[I]);
  D3DXVec3TransformCoord(Vector, MakeD3DVector(0, Min(Tyres[I].MinPos.X, Min(Tyres[I].MinPos.Y, Tyres[I].MinPos.Z)), 0), RRot);
  TyreY:=Vector.Y;

  Material.MatType:=0;
  Temp2:=-256*256*256;
  Vector:=D3DXVector3(0,1,0);                
  for J:=0 to List.Count-1 do begin
   //if TObject(List.Items[J]) is TMapGroup then begin
    Temp1:=Physics_GetYPosInGroup(TObject(List.Items[J]),Tyres[I].APos.X, Tyres[I].APos.Z, Tyres[I].APos.Y+TyreY, Tyres[I].APos.Y-TyreY, Vector);
    //Temp1:=Physics_GetYPosInFace(TMapPoly(List.Items[J]),Tyres[I].APos.X,Tyres[I].APos.Z,Vector);
    if Temp1<Tyres[I].APos.Y-TyreY then
     if Temp1>Temp2 then begin
      Temp2:=Temp1;
      if TObject(List.Items[J]) is TMapGroup then Material:=TMapGroup(List.Items[J]).Material
       else Material.MatType:=0;
      //CollFace:=TMapPoly(List.Items[J]);
      Normal:=Vector;
     end;
   //end;
  end;
  if Normal.Y>0.9999999 then Normal:=D3DXVector3(0.000001, 1.0, 0.000001);
  Tyres[I].OnGround:=(Temp2>Tyres[I].APos.Y+TyreY) and (Temp2<Tyres[I].APos.Y-TyreY);
  if Tyres[I].OnGround then begin
   D3DXVec3TransformCoord(Vector2, MakeD3DVector(Tyres[I].RPos.X, Tyres[I].RPos.Y, Tyres[I].RPos.Z), RRot);
   D3DXVec3TransformCoord(Vector3, MakeD3DVector(Tyres[I].RPos.X, Tyres[I].RPos.Y, Tyres[I].RPos.Z), WasRot);
   SusForce:=FloatMin(TotMass*Obj.Suspension_MaxM,Sqr((Temp2-Tyres[I].APos.Y-TyreY)/3)*Obj.Suspension_Strength-Normal.X*(PosMove.X+(Vector2.X-Vector3.X)/(TickCount/3000))*Obj.Suspension_AntiBounce-Normal.Y*(PosMove.Y+(Vector2.Y-Vector3.Y)/(TickCount/3000))*Obj.Suspension_AntiBounce-Normal.Z*(PosMove.Z+(Vector2.Z-Vector3.Z)/(TickCount/3000))*Obj.Suspension_AntiBounce);
   Physics_AddForce(Obj, MakeD3DVector(Normal.X*SusForce,Normal.Y*SusForce,Normal.Z*SusForce),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y,Tyres[I].APos.Z-APos.Z));
   Tyres[I].Force:=MakeD3DVector(Normal.X*SusForce,Normal.Y*SusForce,Normal.Z*SusForce);

   Temp3:=Obj.Grip_Relation;
   D3DXVec3Normalize(Vector, MakeD3DVector((Vector3.X-Vector2.X)/(TickCount/Temp3)-PosMove.X,(Vector3.Y-Vector2.Y)/(TickCount/Temp3)-PosMove.Y,(Vector3.Z-Vector2.Z)/(TickCount/Temp3)-PosMove.Z));

   if Controls.HandBrake and (not Tyres[I].Steer) then begin
    Temp3:=(SusForce*Obj.Brake_HBForce+Obj.Brake_HBAddition)*Tyres[I].GetGrip(Material.MatType)*0.00390625;
    Physics_AddForce(Obj, MakeD3DVector(Vector.X*Temp3*(1-Abs(Normal.X)),Vector.Y*Temp3*(1-Abs(Normal.Y)),Vector.Z*Temp3*(1-Abs(Normal.Z))),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y-TyreY-0.6,Tyres[I].APos.Z-APos.Z));
    Tyres[I].HandBrakeBadGrip:=Min(255,(Tyres[I].HandBrakeBadGrip+Round(TickCount)));
   end else Tyres[I].HandBrakeBadGrip:=Max(0,(Tyres[I].HandBrakeBadGrip-Round(TickCount*Obj.Brake_HBGripReturnSpeed)));

   D3DXVec3TransformCoord(Vector3, MakeD3DVector(1,0,0), Rot);
   Temp3:=(SusForce*Obj.Grip_SideForce+Obj.Grip_SideAddition)*Tyres[I].GetGrip(Material.MatType)*0.00390625*0.75;

   D3DXVec3TransformCoord(Vector2, MakeD3DVector(0,Temp2-Tyres[I].APos.Y-TyreY,0), RRot);
   Tyres[I].RPos.Y:=Tyres[I].RPos.Y+Vector2.Y;

   Vector2:=VectorProjectionNormalized(GetMove(D3DXVector3(PosMove.X+Obj.Force.X/Obj.TotMass*TickCount*0.001, PosMove.Y+Obj.Force.Y/Obj.TotMass*TickCount*0.001, PosMove.Z+Obj.Force.Z/Obj.TotMass*TickCount*0.001), MakeD3DVector(RotMove.X*3,RotMove.Y*3,RotMove.Z*3), MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y,Tyres[I].APos.Z-APos.Z), TickCount),Vector3);
   Temp1:=Sqrt(Sqr(Vector2.X)+Sqr(Vector2.Y)+Sqr(Vector2.Z))*TotMass*Obj.Grip_MaxSide;
   SideForce:=Temp1/Temp3;
   Temp3:=Min(Temp3,Temp1);
   if Controls.HandBrake and (not Tyres[I].Steer) then Temp3:=Temp3/Max(1,Tyres[I].HandBrakeBadGrip*Obj.Brake_HBGripEffect);
   if Tyres[I].BadGrip>0 then Temp3:=Temp3*Max(0, (1.0-Tyres[I].BadGrip*0.005))/Max(1, Controls.Brake*6);
   if not Tyres[I].Steer then Temp3:=Temp3*Obj.Grip_RearSide;

   if Sqrt((Vector.X-Vector3.X)*(Vector.X-Vector3.X)+(Vector.Y-Vector3.Y)*(Vector.Y-Vector3.Y)+(Vector.Z-Vector3.Z)*(Vector.Z-Vector3.Z))<1.414213562373 then
    Physics_AddForce(Obj, MakeD3DVector(Vector3.X*Temp3,Vector3.Y*Temp3,Vector3.Z*Temp3),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y,Tyres[I].APos.Z-APos.Z))
   else Physics_AddForce(Obj, MakeD3DVector(-Vector3.X*Temp3,-Vector3.Y*Temp3,-Vector3.Z*Temp3),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y,Tyres[I].APos.Z-APos.Z));

   Tyres[I].BadGrip:=Tyres[I].BadGrip*Power(0.999, TickCount);//Max(0,(Tyres[I].BadGrip-Round(TickCount*Obj.Grip_ReturnSpeed*1.5)));

   if not (Controls.HandBrake and (not Tyres[I].Steer)) then begin
    if Tyres[I].Accelerate then
     if (Controls.Accelerate>Controls.Brake) and (Gear<>0) then begin
      Temp3:=(Obj.Engine_EngineMax-Abs(Obj.Engine_PeakRPM-Max(3500, RPM)))/Obj.FGears_Ratio[Max(1,Gear)]*Obj.Engine_EngineForce*Max(10.0,Tyres[I].BadGrip)/TotalAccGrip;
      if Temp3>(SusForce*Obj.Accelerate_Force+Obj.Accelerate_Addition)*Tyres[I].GetGrip(Material.MatType)*0.00390625 then begin
       Temp3:=(1-Obj.Accelerate_GripOver)*(SusForce*Obj.Accelerate_Force+Obj.Accelerate_Addition)*Tyres[I].GetGrip(Material.MatType)*0.00390625+Temp3*Obj.Accelerate_GripOver;
       if Controls.Accelerate=1.0 then begin Temp1:=Min(Round(Obj.Accelerate_BurnOutGripEffect)-Round(CarSpeed*Obj.Accelerate_BurnOutGripSpeedAdjust),Round(Tyres[I].BadGrip+TickCount)); end
        else if Tyres[I].GetGrip(Material.MatType)<=60 then Temp1:=Controls.Accelerate*Min(Round(Obj.Accelerate_GripEffectSlip),Round(Tyres[I].BadGrip+TickCount))
         else Temp1:=Controls.Accelerate*Min(Max(0,Round(Obj.Accelerate_GripEffectFC)-Round(CarSpeed*Obj.Accelerate_GripEffectFCSpeedAdjust)),Round(Tyres[I].BadGrip+TickCount));
       if Temp1>Tyres[I].BadGrip then Tyres[I].BadGrip:=Temp1
        ;//else Tyres[I].BadGrip:=Max(0,(Tyres[I].BadGrip+Round(TickCount*Obj.Grip_ReturnSpeed*0.5)));
      end else Tyres[I].BadGrip:=Min(Max(0,Round(Obj.Accelerate_GripEffect)-Round(CarSpeed*Obj.Accelerate_GripEffectSpeedAdjust)),Round(Tyres[I].BadGrip+TickCount));
      LastMove:=0;
      if GearDelay=0 then begin
       Temp3:=Temp3/(1+Tyres[I].BadGrip/512);
       D3DXVec3TransformCoord(Vector2, MakeD3DVector(0,0,(2*Ord(Gear>0)-1)*Temp3), Rot);
       Vector3:=VectorProjectionNormalized(Vector2,MakeD3DVector(Normal.X,Normal.Y,Normal.Z));
       Vector2.X:=Vector2.X-Vector3.X;
       Vector2.Y:=Vector2.Y-Vector3.Y;
       Vector2.Z:=Vector2.Z-Vector3.Z;
       Physics_AddForce(Obj, Vector2,MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y,Tyres[I].APos.Z-APos.Z));
      end;
     end;
    if Tyres[I].Brake then
     if Controls.Brake>=Controls.Accelerate*Ord(Tyres[I].Accelerate) then begin
      Temp3:=Tyres[I].GetGrip(Material.MatType)*Obj.Brake_Force*Controls.Brake*0.75;
      Physics_AddForce(Obj, D3DXVector3(Vector.X*Temp3*(1-Abs(Normal.X)),Vector.Y*Temp3*(1-Abs(Normal.Y)),Vector.Z*Temp3*(1-Abs(Normal.Z))),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y-0.15,Tyres[I].APos.Z-APos.Z));
      Tyres[I].BadGrip:=Tyres[I].BadGrip*0.1;
     end;
    D3DXVec3TransformCoord(Vector3, D3DXVector3(0,0,1), Rot);
    Vector2:=VectorProjectionNormalized(D3DXVector3(Tyres[I].APos.X-Tyres[I].WasPos.X,Tyres[I].APos.Y-Tyres[I].WasPos.Y,Tyres[I].APos.Z-Tyres[I].WasPos.Z),Vector3);
    Tyres[I].Rotation:=(1-2*Ord(Forw))*Sqrt(Sqr(Vector2.X)+Sqr(Vector2.Y)+Sqr(Vector2.Z))/TickCount/(Tyres[I].MaxPos.Y-Min(Tyres[I].MinPos.X, Min(Tyres[I].MinPos.Y, Tyres[I].MinPos.Z)))+(1-2*Ord(Gear>0))*Sqr(Sqr(Tyres[I].BadGrip*0.0025));
   end else Tyres[I].Rotation:=0;

   Tyres[I].MatType:=Material.MatType;
   if (Material.MatType=MATTYPE_SAND) or (Material.MatType=MATTYPE_GRASS) then begin
    Physics_AddForce(Obj, MakeD3DVector(Vector.X*750*(1-Abs(Normal.X)),Vector.Y*750*(1-Abs(Normal.Y)),Vector.Z*750*(1-Abs(Normal.Z))),MakeD3DVector(Tyres[I].APos.X-APos.X,Tyres[I].APos.Y-APos.Y-0.15,Tyres[I].APos.Z-APos.Z));
    Tyres[I].Sliding:=0.75;
    Temp3:=Min(0.75, Max(0.0,(Tyres[I].BadGrip-100)*0.1)*(0.5+0.5*Ord(GearDelay=0)));
    if (Temp3>0.25) then begin
     if Tyres[I].Sand=nil then begin Tyres[I].Sand:=TFlyingSand.Create(Engine.Particles, True); Tyres[I].Sand.Tyre:=Tyres[I]; end;
     if Tyres[I].Sand.LastTime>=0.05/(Speed*0.5+1) then begin
      D3DXVec3TransformCoord(Vector, D3DXVector3(Random(1000)*0.0002-0.1,(Abs(Ord(Gear>0)-Ord(Tyres[I].RPos.Z>0))*0.75+0.25)*Random(1000)*0.002+3,(1-2*Ord(Gear>0))*(Random(1000)*0.003+3)), Rot);
      Tyres[I].Sand.AddItem(D3DXVector3(Tyres[I].APos.X+(Random(1000)-500)*0.0001, Tyres[I].APos.Y+Min(Tyres[I].MinPos.X, Min(Tyres[I].MinPos.Y, Tyres[I].MinPos.Z)), Tyres[I].APos.Z+(Random(1000)-500)*0.0001), D3DXVector3(Vector.X+PosMove.X, Vector.Y+PosMove.Y, Vector.Z+PosMove.Z));
     end;
    end;
   end else begin
    Tyres[I].Sliding:=Min(0.75, Max3Singles(Tyres[I].HandBrakeBadGrip/512,Max(0.0,Sqrt(SideForce)-1.75),Max(0.0,(Tyres[I].BadGrip-100)/156)*Ord(GearDelay=0))*Sqrt(SusForce/TotMass*0.15));
    Temp3:=Min(0.75, Max3Singles(Tyres[I].HandBrakeBadGrip*Sqrt(Speed)*0.001,Max(0.0,Sqrt(SideForce)-1.3),Max(0.0,(Tyres[I].BadGrip-100)*0.1)*Ord(GearDelay=0))*Sqrt(SusForce/TotMass*0.15));
    if (Temp3>0.25) then begin
     if Tyres[I].Smoke=nil then begin Tyres[I].Smoke:=TTyreSmoke.Create(Engine.Particles, True); Tyres[I].Smoke.Tyre:=Tyres[I]; end;
     Tyres[I].Smoke.AddItem(Tyres[I].APos, (Temp3-0.25)*0.75, TickCount);
    end;
   end;
   {if (Tyres[I].BadGrip>150) or (Tyres[I].Sliding>0.25) then begin
    if Tyres[I].Smoke=nil then begin Tyres[I].Smoke:=TTyreSmoke.Create(Engine.Particles, True); Tyres[I].Smoke.Tyre:=Tyres[I]; end;
    if Tyres[I].Smoke.LastTime>=0.05/(Speed*0.5+1) then Tyres[I].Smoke.AddItem(D3DXVector3((Random(1001)-500)*0.0002,Tyres[I].MinPos.Y+0.1,(Random(1001)-500)*0.0002), (Tyres[I].BadGrip-100)/155+(Tyres[I].Sliding-0.25)*0.25);
   end;}
  end else begin
   Tyres[I].Force:=MakeD3DVector(0.0, 0.0, 0.0);
   Tyres[I].Sliding:=0.0;
   if Tyres[I].Accelerate and (Controls.Accelerate>0) then begin
    Tyres[I].BadGrip:=Min(Round(Obj.Grip_AirEffect),Round(Tyres[I].BadGrip+TickCount));
    Tyres[I].Rotation:=(1-2*Ord(Gear>0))*Sqr(Tyres[I].BadGrip*0.001);
   end else Tyres[I].BadGrip:=Tyres[I].BadGrip*Power(0.999, TickCount);
   if (Controls.HandBrake and (not Tyres[I].Steer)) or (Tyres[I].Brake and (Controls.Brake>0)) then Tyres[I].Rotation:=0;
  end;
  D3DXVec3TransformCoord(Vector, D3DXVector3(1,0,0), mat);
  Tyres[I].RotPos:=Tyres[I].RotPos+Tyres[I].Rotation*TickCount;
  while Tyres[I].RotPos>g_2_PI do Tyres[I].RotPos:=Tyres[I].RotPos-g_2_PI;
  while Tyres[I].RotPos<-g_2_PI do Tyres[I].RotPos:=Tyres[I].RotPos+g_2_PI;
  D3DXMatrixRotationAxis(Tyres[I].RRot, Vector, -Tyres[I].RotPos);
  D3DXMatrixMultiply(mat2, mat, Tyres[I].RRot);
  D3DXMatrixMultiply(Tyres[I].RRot, Tyres[I].OrigRot, mat2);
  Tyres[I].WasPos:=Tyres[I].APos;
 end;                                                       

 {if (Controls.Accelerate>=Controls.Brake) then RPM:=(7000*TickCount+RPM*1000)/(TickCount+1000)
  else RPM:=(2000*TickCount+RPM*1000)/(TickCount+1000);
 if TargetRPM>0 then RPM:=(FloatMax(2000,TargetRPM)*TickCount+RPM*TotalAccGrip*0.02)/(TickCount+TotalAccGrip*0.02);}
 RPM:=RPM*(1.0-TickCount*0.01)+(Max(2000.0+Controls.Accelerate*1000, TargetRPM)+TotalAccGrip*7.0)*(TickCount*0.01);

 //else if (Forw and (Gear<0)) or (not Forw and (Gear>0)) then if CarSpeed>1.0 then Gear:=Ord(Forw)*2-1;

 //Waves.Items[0].Volume:=Max(-10000,-);
 //if Driver is TOPlayer then
 // Engine.Waves.Items[0].Frequency:=Round(RPM*10+2000);
 WasRot:=RRot;
 
 end;
end;

end.
