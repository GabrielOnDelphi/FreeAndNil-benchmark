object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'FreeAndNil benchmark'
  ClientHeight = 420
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object btnRun: TButton
    Left = 8
    Top = 8
    Width = 130
    Height = 28
    Caption = 'Run benchmark'
    TabOrder = 0
    OnClick = btnRunClick
  end
  object mmoReport: TMemo
    Left = 8
    Top = 44
    Width = 624
    Height = 368
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
end
