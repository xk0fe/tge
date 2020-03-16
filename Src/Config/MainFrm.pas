unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniFiles, fmod, fmodtypes, ShellAPI,
  XPMan;

type
  TMainForm = class(TForm)
    Bevel1: TBevel;
    BtnCancel: TButton;
    BtnStart: TButton;
    VideoBox: TGroupBox;
    Label1: TLabel;
    ModeCombo: TComboBox;
    FullScreenCheck: TCheckBox;
    Bevel2: TBevel;
    Label2: TLabel;
    NoneRadio: TRadioButton;
    BilinearRadio: TRadioButton;
    TrilinearRadio: TRadioButton;
    AnisotropicRadio: TRadioButton;
    AnisotropicCombo: TComboBox;
    Bevel3: TBevel;
    DitheringCheck: TCheckBox;
    AntialiasCheck: TCheckBox;
    AntialiasCombo: TComboBox;
    AudioBox: TGroupBox;
    Label3: TLabel;
    AudioDeviceCombo: TComboBox;
    Label4: TLabel;
    SpeakerCombo: TComboBox;
    SFXBar: TTrackBar;
    Label5: TLabel;
    Label6: TLabel;
    MusicBar: TTrackBar;
    FPSCheck: TCheckBox;
    Bevel4: TBevel;
    SaveBtn: TButton;
    XPManifest: TXPManifest;
    DetailBar: TTrackBar;
    Label7: TLabel;
    procedure BtnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.BtnCancelClick(Sender: TObject);
begin
 Close;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var Ini: TIniFile;
    I, Filtering, Antialiasing: integer;
begin
 Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Settings.ini');

 ModeCombo.ItemIndex:=ModeCombo.Items.IndexOf(Ini.ReadString('Display', 'Mode', ModeCombo.Items[ModeCombo.ItemIndex]));
 if ModeCombo.ItemIndex<0 then ModeCombo.ItemIndex:=0;
 FullScreenCheck.Checked:=not Ini.ReadBool('Display', 'Screen', not FullScreenCheck.Checked);
 Filtering:=Ini.ReadInteger('Options', 'Filtering', 0);
 NoneRadio.Checked:=(Filtering=2);
 BilinearRadio.Checked:=(Filtering=1);
 TrilinearRadio.Checked:=(Filtering=0);
 AnisotropicRadio.Checked:=(Filtering>=3);
 if Filtering>=3 then AnisotropicCombo.ItemIndex:=Filtering-3;
 Antialiasing:=Ini.ReadInteger('Options', 'Antialiasing', 0);
 AntialiasCheck.Checked:=Antialiasing>0;
 if Antialiasing>0 then AntialiasCombo.ItemIndex:=Antialiasing div 2-1;
 DitheringCheck.Checked:=Ini.ReadBool('Options', 'Dithering', DitheringCheck.Checked);

 FSOUND_SetOutput(FSOUND_OUTPUT_DSOUND);
 AudioDeviceCombo.Items.Clear;
 for I:=0 to FSOUND_GetNumDrivers-1 do
  AudioDeviceCombo.Items.Add(FSOUND_GetDriverName(I));
 AudioDeviceCombo.ItemIndex:=Ini.ReadInteger('Options', 'SoundDriver', 0);
 SpeakerCombo.ItemIndex:=Ini.ReadInteger('Options', 'SpeakerMode', SpeakerCombo.ItemIndex);
 SFXBar.Position:=Ini.ReadInteger('Options', 'SoundVolume', SFXBar.Position);
 MusicBar.Position:=Ini.ReadInteger('Options', 'MusicVolume', MusicBar.Position);

 FPSCheck.Checked:=Ini.ReadBool('Options', 'ShowFPS', False);
 DetailBar.Position:=(Ini.ReadInteger('GameOptions', 'VisibleDepth', 150)-100) div 25;

 Ini.Free;
end;

procedure TMainForm.BtnStartClick(Sender: TObject);
begin
 SaveBtnClick(Sender);
 ShellExecute(0, 'open', PChar(ExtractFilePath(Application.ExeName)+'Game.exe'), nil, nil, SW_SHOW);
end;

procedure TMainForm.SaveBtnClick(Sender: TObject);
var Ini: TIniFile;
begin
 Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Settings.ini');

 Ini.WriteString('Display', 'Mode', ModeCombo.Items[ModeCombo.ItemIndex]);
 Ini.WriteBool('Display', 'Screen', not FullScreenCheck.Checked);
 if NoneRadio.Checked then Ini.WriteInteger('Options', 'Filtering', 2)
 else if BilinearRadio.Checked then Ini.WriteInteger('Options', 'Filtering', 1)
 else if TrilinearRadio.Checked then Ini.WriteInteger('Options', 'Filtering', 0)
 else if AnisotropicRadio.Checked then Ini.WriteInteger('Options', 'Filtering', 3+AnisotropicCombo.ItemIndex);
 Ini.WriteInteger('Options', 'Antialiasing', Ord(AntialiasCheck.Checked)*(AntialiasCombo.ItemIndex+1)*2);
 Ini.WriteBool('Options', 'Dithering', DitheringCheck.Checked);

 Ini.WriteInteger('Options', 'SoundDriver', AudioDeviceCombo.ItemIndex);
 Ini.WriteInteger('Options', 'SpeakerMode', SpeakerCombo.ItemIndex);
 Ini.WriteInteger('Options', 'SoundVolume', SFXBar.Position);
 Ini.WriteInteger('Options', 'MusicVolume', MusicBar.Position);

 Ini.WriteBool('Options', 'ShowFPS', FPSCheck.Checked);
 Ini.WriteInteger('GameOptions', 'VisibleDepth', DetailBar.Position*25+100);
 Ini.WriteInteger('GameOptions', 'MaxTraffic', DetailBar.Position*48+64);

 Ini.Free;

 Close;
end;

end.
