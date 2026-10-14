UNIT MainForm;

{=============================================================================================================
   2026.10.11
   www.GabrielMoraru.com
--------------------------------------------------------------------------------------------------------------
   GUI of the FreeAndNil benchmark. The measuring code is in FreeAndNilBench.Core.pas.
   Started with /run, the program skips this form (see the .dpr).
=============================================================================================================}

INTERFACE

uses
  System.SysUtils, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    btnRun: TButton;
    mmoReport: TMemo;
    procedure btnRunClick(Sender: TObject);
  private
  public
  end;

var
  frmMain: TfrmMain;


IMPLEMENTATION {$R *.dfm}

uses
  FreeAndNilBench.Core;


procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  btnRun.Enabled := FALSE;
  Screen.Cursor := crHourGlass;
  try
    mmoReport.Lines.Text := RunFreeAndNilBenchmark;
  finally
    Screen.Cursor := crDefault;
    btnRun.Enabled := TRUE;
  end;
end;


end.
