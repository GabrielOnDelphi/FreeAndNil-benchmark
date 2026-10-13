program FreeAndNilBenchConsole;

{=============================================================================================================
   www.GabrielMoraru.com
--------------------------------------------------------------------------------------------------------------
   Runs the FreeAndNil benchmark, prints the report to the console and saves it beside the exe
   as "Results - Win32.txt" or "Results - Win64.txt". RTL units only.
=============================================================================================================}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  FreeAndNilBench.Core in 'FreeAndNilBench.Core.pas';

const
  {$IFDEF WIN64}
  ResultFile = 'Results - Win64.txt';
  {$ELSE}
  ResultFile = 'Results - Win32.txt';
  {$ENDIF}

var
  Report: string;

begin
  try
    Report := RunFreeAndNilBenchmark;
    Write(Report);
    TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + ResultFile, Report, TEncoding.UTF8);
  except
    on E: Exception do
      begin
        WriteLn('EXCEPTION: ', E.ClassName, ': ', E.Message);
        ExitCode := 1;
      end;
  end;
end.
