program FreeAndNilBench;

uses
  {$IFDEF DEBUG}FastMM4,{$ENDIF}

  System.SysUtils,
  System.IOUtils,
  Vcl.Themes,
  Vcl.Styles,
  MainForm in 'MainForm.pas' {frmMain},
  FreeAndNilBench.Core in 'FreeAndNilBench.Core.pas',
  {$IFDEF AUTOPILOT}Autopilot.Bridge.Vcl in 'c:\Projects\Projects AI\Autopilot for Delphi\Source\Bridge\Autopilot.Bridge.Vcl.pas',{$ENDIF}{Optional}
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
  if FindCmdLineSwitch('run')
  then RunFromCommandLine
  else
    begin
      Application.Initialize;
      Application.MainFormOnTaskbar:= TRUE;
      Application.CreateForm(TfrmMain, frmMain);

      { Optional: Via Autopilot, Claude can run/debug/test this program for you.
        For example, press "Run benchmark" & check the results in mmoReport.
        Don't have AUTOPILOT? Undefine $AUTOPILOT or get it from www.GabrielMoraru.com }
      {$IFDEF AUTOPILOT}
       Autopilot.Bridge.Vcl.StartBridge;
      {$ENDIF}
      Application.Run;
    end;
end.
