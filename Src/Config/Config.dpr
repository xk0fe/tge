program Config;

uses
  Windows,
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm};

{$R *.res}

begin
  CreateMutex(nil, False, PChar('TSSConfigTool'));  //  Allow only one
  if GetLastError = ERROR_ALREADY_EXISTS then Exit; //  instance of application

  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
