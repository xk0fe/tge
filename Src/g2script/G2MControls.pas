unit G2MControls;

interface

uses
  Math, Classes, G2Types, G2Execute, G2Consts, Windows, SysUtils, Dialogs,
  TypInfo;

type
  TG2Mdl_Controls = class(TG2Module)
  published
    function Message(const P: G2Array; const Script: TG2Execute): TG2Variant;
  end;

implementation

uses
  G2Script;

{ TG2Mdl_Controls }

function TG2Mdl_Controls.Message(const P: G2Array; const Script: TG2Execute): TG2Variant;
var DlgType: TMsgDlgType;
    Buttons: TMsgDlgButtons;
begin
 Result:=nil;
 if G2ParamRangeError(1, 3, P, Script) then Exit;
 DlgType:=mtInformation;
 Buttons:=[mbOK];
 MessageDlg(P[0].Str, DlgType, Buttons, 0);
 G2Release(P);
end;

initialization
G2RegisterModule(TG2Mdl_Controls);
end.
