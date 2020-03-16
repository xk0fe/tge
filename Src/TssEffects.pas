{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Effects Unit                           *
 *  (C) Aukiogames 2002                    *
(*-----------------------------------------*}

unit TssEffects;

interface

uses
  Windows, SysUtils, TssUtils, Direct3D8, D3DX8, TssMap, Classes, Math, TssTextures, TssObjects;

procedure PaintTyreRect(Group: TMapGroup; Obj: TTssObject; const vFrom, vTo: TD3DXVector3; Width: Single; cFrom, cTo: DWord; var LastC, LastD: TD3DXVector2);

implementation

uses
  TssEngine;

function IsPointInPolygon2D(const P: TD3DXVector2; const Polygon: array of TD3DXVector2): Boolean;
var I: integer;
    A, B: PD3DXVector2;
    D: Single;
    Right, Left, Top, Bottom: Boolean;
begin
 Right:=False; Left:=False; Top:=False; Bottom:=False;
 for I:=Low(Polygon) to High(Polygon) do begin
  A:=@Polygon[I];
  B:=@Polygon[(I+1) mod (High(Polygon)+1)];
  if Abs(A.Y-B.Y)>0.0001 then begin
   D:=(P.Y-A.Y)/(B.Y-A.Y);
   if (D>=0) and (D<=1) then begin
    Right:=Right or (P.X<=A.X*(1-D)+B.X*D);
    Left:=Left or (P.X>=A.X*(1-D)+B.X*D);
   end;
  end;
  if Abs(A.X-B.X)>0.0001  then begin
   D:=(P.X-A.X)/(B.X-A.X);
   if (D>=0) and (D<=1) then begin
    Top:=Top or (P.Y<=A.Y*(1-D)+B.Y*D);
    Bottom:=Bottom or (P.Y>=A.Y*(1-D)+B.Y*D);
   end;
  end;
 end;
 Result:=Left and Right and Top and Bottom;
end;

function GetYInTriangle(const P: TD3DXVector2; const tA, tB, tC: TD3DXVector3): Single;
var V1, V2, Normal: TD3DXVector3;
begin
 V1:=D3DXVector3(tB.X-tA.X,tB.Y-tA.Y,tB.Z-tA.Z);
 V2:=D3DXVector3(tC.X-tA.X,tC.Y-tA.Y,tC.Z-tA.Z);
 D3DXVec3Normalize(Normal, D3DXVector3(V1.Y*V2.Z-V2.Y*V1.Z,V1.Z*V2.X-V2.Z*V1.X,V1.X*V2.Y-V2.X*V1.Y));
 if Normal.Y=0 then Normal.Y:=0.000001;
 Result:=tA.Y+Normal.X/Normal.Y*(tA.X-P.X)+Normal.Z/Normal.Y*(tA.Z-P.Y);
end;

function LineIntersect2D3D(const A1, B1: TD3DXVector3; const A2, B2: TD3DXVector2; var P: TD3DXVector3): Boolean;
//var c1, c2: Single;
var //x, y, k1, k2, c1, c2: Single;
    x, y, k1, k2, c1, c2: Extended;
begin
 if Abs(A1.X-B1.X)<0.0000001 then begin
  x:=A1.X;
  k2:=(B2.Y-A2.Y)/(B2.X-A2.X);
  y:=k2*(x-A2.X)+A2.Y;
  c1:=(y-A1.Z)/(B1.Z-A1.Z);
  c2:=(x-A2.X)/(B2.X-A2.X);             
 end else if Abs(A2.X-B2.X)<0.0000001 then begin
  x:=A2.X;
  k1:=(B1.Z-A1.Z)/(B1.X-A1.X);
  y:=k1*(x-A1.X)+A1.Z;
  c1:=(x-A1.X)/(B1.X-A1.X);
  c2:=(y-A2.Y)/(B2.Y-A2.Y);
 end else begin
  k1:=(B1.Z-A1.Z)/(B1.X-A1.X);
  k2:=(B2.Y-A2.Y)/(B2.X-A2.X);
  x:=(k1*A1.X-A1.Z-k2*A2.X+A2.Y)/(k1-k2);
  c1:=(x-A1.X)/(B1.X-A1.X);
  c2:=(x-A2.X)/(B2.X-A2.X);
 end;
 Result:=(c1>0) and (c1<1) and (c2>0) and (c2<1);
 if Result then P:=D3DXVector3(A1.X+(B1.X-A1.X)*c1, A1.Y+(B1.Y-A1.Y)*c1, A1.Z+(B1.Z-A1.Z)*c1);
 {c1:=((A1.Z-A2.Y)*(B2.X-A2.X)-(A1.X-A2.X)*(B2.Y-A2.Y))/((B1.Z-A1.Z)*(B2.X-A2.X)-(B1.X-A1.X)*(B2.Y-A2.Y));
 c2:=-1;                
 if B2.Y<>A2.Y then c2:=(A1.Z+(B1.Z-A1.Z)*c1-A2.Y)/(B2.Y-A2.Y)
  else if B2.X<>A2.X then c2:=(A1.X+(B1.X-A1.X)*c1-A2.X)/(B2.X-A2.X);
 Result:=(c1>=0) and (c1<=1) and (c2>=0) and (c2<=1);
 if Result then P:=D3DXVector3(A1.X+(B1.X-A1.X)*c1, A1.Y+(B1.Y-A1.Y)*c1, A1.Z+(B1.Z-A1.Z)*c1);}
end;

type
  TVertexItem = class(TObject)
  public
    Pos: TD3DXVector3;
    Angle: Single;
  end;
function VertexItemAngleSort(Item1, Item2: Pointer): Integer;
begin
 if TVertexItem(Item1).Angle<TVertexItem(Item2).Angle then Result:=-1
  else if TVertexItem(Item1).Angle>TVertexItem(Item2).Angle then Result:=1
   else Result:=0;
end;

procedure PaintTyreRect(Group: TMapGroup; Obj: TTssObject; const vFrom, vTo: TD3DXVector3; Width: Single; cFrom, cTo: DWord; var LastC, LastD: TD3DXVector2);
var rA, rB, rC, rD: TD3DXVector2;
    Vector: TD3DXVector2;
  procedure ProcessTriangle(const tA, tB, tC: TD3DXVector3);
  var Normal, Vector: TD3DXVector3;
      Center, Vector2D: TD3DXVector2;
      List: TList;
      MinX, MaxX, MinZ, MaxZ: Single;
    procedure AddVertex(const P: TD3DXVector3);
    begin
     with TVertexItem(List.Items[List.Add(TVertexItem.Create)]) do begin
      Pos:=D3DXVector3(P.X+Normal.X*0.005, P.Y+Normal.Y*0.005, P.Z+Normal.Z*0.005);
      MinX:=Min(MinX, P.X); MaxX:=Max(MaxX, P.X);
      MinZ:=Min(MinZ, P.Z); MaxZ:=Max(MaxZ, P.Z);
     end;
    end;
  var tA2D, tB2D, tC2D: TD3DXVector2;
      I, J: integer;
      y, x, d: Single;
  begin
   D3DXVec3Cross(Vector, VectorSubtract(tB, tA), VectorSubtract(tC, tA));
   D3DXVec3Normalize(Normal, Vector);
   if Abs(Normal.Y)<0.1 then Exit;
   List:=TList.Create;
   MinX:=16384; MaxX:=-16384;
   MinZ:=16384; MaxZ:=-16384;
   tA2D:=D3DXVector2(tA.X, tA.Z);
   tB2D:=D3DXVector2(tB.X, tB.Z);
   tC2D:=D3DXVector2(tC.X, tC.Z);
   if IsPointInPolygon2D(rA, [tA2D, tB2D, tC2D]) then AddVertex(D3DXVector3(rA.X, GetYInTriangle(rA, tA, tB, tC), rA.Y));
   if LineIntersect2D3D(tA, tB, rA, rB, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tB, tC, rA, rB, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tC, tA, rA, rB, Vector) then AddVertex(Vector);
   if IsPointInPolygon2D(rB, [tA2D, tB2D, tC2D]) then AddVertex(D3DXVector3(rB.X, GetYInTriangle(rB, tA, tB, tC), rB.Y));
   if LineIntersect2D3D(tA, tB, rB, rC, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tB, tC, rB, rC, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tC, tA, rB, rC, Vector) then AddVertex(Vector);
   if IsPointInPolygon2D(rC, [tA2D, tB2D, tC2D]) then AddVertex(D3DXVector3(rC.X, GetYInTriangle(rC, tA, tB, tC), rC.Y));
   if LineIntersect2D3D(tA, tB, rC, rD, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tB, tC, rC, rD, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tC, tA, rC, rD, Vector) then AddVertex(Vector);
   if IsPointInPolygon2D(rD, [tA2D, tB2D, tC2D]) then AddVertex(D3DXVector3(rD.X, GetYInTriangle(rD, tA, tB, tC), rD.Y));
   if LineIntersect2D3D(tA, tB, rD, rA, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tB, tC, rD, rA, Vector) then AddVertex(Vector);
   if LineIntersect2D3D(tC, tA, rD, rA, Vector) then AddVertex(Vector);
   if IsPointInPolygon2D(tA2D, [rA, rB, rC, rD]) then AddVertex(tA);
   if IsPointInPolygon2D(tB2D, [rA, rB, rC, rD]) then AddVertex(tB);
   if IsPointInPolygon2D(tC2D, [rA, rB, rC, rD]) then AddVertex(tC);
   if (List.Count>=3) and (Group.VertexCount+List.Count<=255) then begin
    Center:=D3DXVector2(MinX*0.5+MaxX*0.5, MinZ*0.5+MaxZ*0.5);
    for I:=0 to List.Count-1 do
     with TVertexItem(List.Items[I]) do begin
      if (Pos.X<>Center.X) or (Pos.Z<>Center.Y) then begin
       D3DXVec2Normalize(Vector2D, D3DXVector2(Pos.X-Center.X, Pos.Z-Center.Y));
       if Vector2D.X>0.9999 then Angle:=0
        else if Vector2D.X<-0.9999 then Angle:=(1-2*Ord(Vector2D.Y>0))*g_PI
         else Angle:=(1-2*Ord(Vector2D.Y>0))*ArcCos(Vector2D.X);
      end else Angle:=0;
     end;
    List.Sort(VertexItemAngleSort);
    Inc(Group.VertexCount, List.Count);
    ReAllocMem(Group.Vertices, Group.VertexCount*SizeOf(TMapDataVertex));
    Inc(Group.IndexCount, (List.Count-2)*3);
    ReAllocMem(Group.Indices, Group.IndexCount*SizeOf(TIndex));
    Group.Bits.Count:=Group.IndexCount div 3;
    for I:=1 to List.Count-2 do begin
     Group.Indices[Group.IndexCount-(List.Count-2-I)*3-3]:=Group.VertexCount-List.Count+0;
     Group.Indices[Group.IndexCount-(List.Count-2-I)*3-2]:=Group.VertexCount-List.Count+I;
     Group.Indices[Group.IndexCount-(List.Count-2-I)*3-1]:=Group.VertexCount-List.Count+I+1;
    end;
    d:=D3DXVec2Length(D3DXVector2(vFrom.X-vTo.X, vFrom.Z-vTo.Z));
    for I:=0 to List.Count-1 do
     with Group.Vertices[Group.VertexCount-List.Count+I] do begin
      V:=TVertexItem(List.Items[I]).Pos;
      if V.X<Group.MinPos.X then Group.MinPos.X:=V.X; if V.X>Group.MaxPos.X then Group.MaxPos.X:=V.X;
      if V.Y<Group.MinPos.Y then Group.MinPos.Y:=V.Y; if V.Y>Group.MaxPos.Y then Group.MaxPos.Y:=V.Y;
      if V.Z<Group.MinPos.Z then Group.MinPos.Z:=V.Z; if V.Z>Group.MaxPos.Z then Group.MaxPos.Z:=V.Z;
      nX:=Round(128+Normal.X*127);
      nY:=Round(128+Normal.Y*127);
      nZ:=Round(128+Normal.Z*127);
      y:=(D3DXVec2LengthSq(D3DXVector2(V.X-vTo.X, V.Z-vTo.Z))-D3DXVec2LengthSq(D3DXVector2(vFrom.X-V.X, vFrom.Z-V.Z))+Sqr(d))/(2*d);
      x:=Sqrt(D3DXVec2LengthSq(D3DXVector2(V.X-vTo.X, V.Z-vTo.Z))-Sqr(y));
      if vTo.X>vFrom.X+0.0001 then begin
       if (V.X-vFrom.X)/(vTo.X-vFrom.X)*(vTo.Z-vFrom.Z)+vFrom.Z<V.Z then x:=-x;
      end else if vTo.X<vFrom.X-0.0001 then begin
       if (V.X-vFrom.X)/(vTo.X-vFrom.X)*(vTo.Z-vFrom.Z)+vFrom.Z>V.Z then x:=-x;
      end else if vTo.Z>vFrom.Z+0.0001 then begin
       if (V.Z-vFrom.Z)/(vTo.Z-vFrom.Z)*(vTo.X-vFrom.X)+vFrom.X<V.X then x:=-x;
      end else if vTo.Z<vFrom.Z-0.0001 then begin
       if (V.Z-vFrom.Z)/(vTo.Z-vFrom.Z)*(vTo.X-vFrom.X)+vFrom.X>V.X then x:=-x;
      end;
      Color:=D3DCOLOR_ARGB(Round((cFrom shr 24)*(y/d)+(cTo shr 24)*(1-y/d)), 128, 128, 128);
      tU:=Round(32768+(0.5+x/Width*0.5)*128);
      tV:=Round(32768+(-y/Width*0.5)*128);
     end;
    Group.MinPos.X:=Min(Group.MinPos.X, vTo.X); Group.MaxPos.X:=Max(Group.MaxPos.X, vTo.X);
    Group.MinPos.Y:=Min(Group.MinPos.Y, vTo.Y); Group.MaxPos.Y:=Max(Group.MaxPos.Y, vTo.Y);
    Group.MinPos.Z:=Min(Group.MinPos.Z, vTo.Z); Group.MaxPos.Z:=Max(Group.MaxPos.Z, vTo.Z);
    I:=Trunc(vTo.X/64);
    J:=Trunc(vTo.Z/64);
    if (I>=0) and (I<256) and (J>=0) and (J<256) then 
     with Engine.GameMap.Tiles[I, J] do
      if IndexOf(Group)=-1 then Add(Group);
   end;
   for I:=0 to List.Count-1 do
    TVertexItem(List.Items[I]).Free;
   List.Free;
  end;
var List: TList;
    I, J: integer;
    MinY: Single;
begin
 MinY:=D3DXVec3LengthSq(VectorSubtract(vFrom, vTo));
 if (MinY>2500) or (MinY<0.01) then Exit;
 D3DXVec2Normalize(Vector, D3DXVector2(vTo.Z-vFrom.Z, vFrom.X-vTo.X));
 Vector.X:=Vector.X*Width; Vector.Y:=Vector.Y*Width;
 if LastC.X>=0 then begin
  rA:=LastD;
  rB:=LastC;
 end else begin
  rA:=D3DXVec2Add(D3DXVector2(vFrom.X, vFrom.Z), Vector);
  rB:=D3DXVec2Subtract(D3DXVector2(vFrom.X, vFrom.Z), Vector);
 end;
 rC:=D3DXVec2Subtract(D3DXVector2(vTo.X, vTo.Z), Vector);
 rD:=D3DXVec2Add(D3DXVector2(vTo.X, vTo.Z), Vector);
 LastC:=rC;
 LastD:=rD;
 List:=TList.Create;
 MinY:=Sqrt(D3DXVec3LengthSq(VectorSubtract(vFrom, vTo))*0.25+Sqr(Width));
 //Engine.GameMap.CollectGroupsMap(List, (vFrom.X+vTo.X)*0.5, (vFrom.Y+vTo.Y)*0.5, (vFrom.Z+vTo.Z)*0.5, MinY);
 Engine.Map.CollectGroups(List, {Obj,} (vFrom.X+vTo.X)*0.5, (vFrom.Y+vTo.Y)*0.5, (vFrom.Z+vTo.Z)*0.5, MinY);
 MinY:=Min(vFrom.Y, vTo.Y);
 for I:=0 to List.Count-1 do
  if TObject(List.Items[I]) is TMapGroup then begin with TMapGroup(List.Items[I]) do
   if (IsMaterialHard(Material.MatType) and (Group.Material.Name<>'SandLn1')) or (((Material.MatType=MATTYPE_SAND) or (Material.MatType=MATTYPE_GRASS)) and (Group.Material.Name='SandLn1')) then
    for J:=BitsFrom to BitsTo do
     if Bits[J] then
      if Max3Singles(Vertices[Indices[J*3+0]].V.Y, Vertices[Indices[J*3+1]].V.Y, Vertices[Indices[J*3+2]].V.Y)+0.01>=MinY then
       ProcessTriangle(Vertices[Indices[J*3+0]].V, Vertices[Indices[J*3+1]].V, Vertices[Indices[J*3+2]].V);
  end else if TObject(List.Items[I]) is TTssObject then begin with TTssObject(List.Items[I]).CollDetails^ do begin
   for J:=0 to IndexCount div 3-1 do
    if Bits[J] then
     ProcessTriangle(Vertices[Indices[J*3+0]].V2, Vertices[Indices[J*3+1]].V2, Vertices[Indices[J*3+2]].V2);
  end end;
 List.Free;
end;

end.
 