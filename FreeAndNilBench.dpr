program FreeAndNilBench;

uses
  {$IFDEF DEBUG}FastMM4, {$ENDIF}

  System.SysUtils,
  System.IOUtils,
  Vcl.Themes,
  Vcl.Styles,
  MainForm in 'MainForm.pas' {frmMain},
  FreeAndNilBench.Core in 'FreeAndNilBench.Core.pas',
  LightVcl.Visual.AppData in 'c:\Projects\LightSaber\FrameVCL\LightVcl.Visual.AppData.pas',
  LightVcl.Visual.AppDataForm in 'c:\Projects\LightSaber\FrameVCL\LightVcl.Visual.AppDataForm.pas',
  LightCore.AppData in 'c:\Projects\LightSaber\LightCore.AppData.pas',
  Autopilot.Bridge.Vcl in 'c:\Projects\Projects AI\Autopilot for Delphi\Source\Bridge\Autopilot.Bridge.Vcl.pas',
  Vcl.Forms;

{$R *.res}


{ Command line "/run": run the benchmark, save the report beside the exe, end without a GUI. }
procedure RunFromCommandLine;
const
  {$IFDEF WIN64}
  ResultFile = 'Results - Win64.txt';
  {$ELSE}
  ResultFile = 'Results - Win32.txt';
  {$ENDIF}
begin
  TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + ResultFile, RunFreeAndNilBenchmark, TEncoding.UTF8);
end;


begin
  CONST
     MultiThreaded= FALSE;                 // True => Only if we need to use multithreading in the Log.
  CONST
     AppName= 'FreeAndNilBench';           // Absolutely critical if you use the SaveForm/LoadForm functionality. This string will be used as the name of the INI file.

  if System.SysUtils.FindCmdLineSwitch('run')   // LightCore.AppData has a deprecated FindCmdLineSwitch that hides the RTL one
  then RunFromCommandLine
  else
    begin
      AppData:= TAppData.Create(AppName, '', MultiThreaded);
      Application.MainFormOnTaskbar:= TRUE;
      AppData.CreateMainForm(TfrmMain, asFull);

      { Autopilot for Delphi hands the controls of this running app to an AI assistant such as Claude: it clicks controls, types text, reads labels, sets and reads properties, takes screenshots. The AI tests the GUI for you, no human at the keyboard.
        https://gabrielmoraru.com/autopilot-for-delphi/ }
      Autopilot.Bridge.Vcl.StartBridge;    // Safe no-op unless AUTOPILOT is defined (Debug only)
      AppData.Run;
    end;
end.
