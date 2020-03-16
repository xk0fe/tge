{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Main Program                           *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

program Game;

uses
  Windows,
  TssUnit in 'TssUnit.pas',
  TssEngine in 'TssEngine.pas',
  TssUtils in 'TssUtils.pas',
  TssTextures in 'TssTextures.pas',
  TssFiles in 'TssFiles.pas',
  TssControls in 'TssControls.pas',
  TssObjects in 'TssObjects.pas',
  TssMap in 'TssMap.pas',
  TssSky in 'TssSky.pas',
  TssCars in 'TssCars.pas',
  TssPhysics in 'TssPhysics.pas',
  TssAlpha in 'TssAlpha.pas',
  TssShadows in 'TssShadows.pas',
  TssMenus in 'TssMenus.pas',
  TssCredits in 'TssCredits.pas',
  TssLog in 'TssLog.pas',
  TssParticles in 'TssParticles.pas',
  TssSurface in 'TssSurface.pas',
  TssWeapons in 'TssWeapons.pas',
  TssLights in 'TssLights.pas',
  TssEffects in 'TssEffects.pas',
  TssAI in 'TssAI.pas',
  TssConsole in 'TssConsole.pas',
  TssEditor in 'TssEditor.pas',
  TssScript in 'TssScript.pas',
  TssReplay in 'TssReplay.pas',
  TssAnim in 'TssAnim.pas',
  TssSounds in 'TssSounds.pas';

{$R winmain.res}

{$MAXSTACKSIZE 4194304}

var
  D3DApp: CTssApp;
begin
  CreateMutex(nil, False, PChar('TSSMainProgram')); //  Allow only one
  if GetLastError = ERROR_ALREADY_EXISTS then Exit; //  instance of application

  D3DApp:=CTssApp.Create;
  if FAILED(D3DApp.Create_(HInstance)) then Exit;
  D3DApp.Run;
end.

