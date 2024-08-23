object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 601
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btn1: TButton
    Left = 512
    Top = 56
    Width = 115
    Height = 145
    Caption = 'btn1'
    TabOrder = 0
    OnClick = btn1Click
  end
  object btn2: TButton
    Left = 512
    Top = 216
    Width = 115
    Height = 73
    Caption = 'btn2'
    TabOrder = 1
    OnClick = btn2Click
  end
  object btn3: TButton
    Left = 512
    Top = 295
    Width = 115
    Height = 66
    Caption = 'btn3'
    TabOrder = 2
    OnClick = btn3Click
  end
  object btn4: TButton
    Left = 512
    Top = 367
    Width = 115
    Height = 82
    Caption = 'btn4'
    TabOrder = 3
    OnClick = btn4Click
  end
  object mmo1: TMemo
    Left = 32
    Top = 56
    Width = 401
    Height = 449
    Lines.Strings = (
      'mmo1')
    TabOrder = 4
  end
end
