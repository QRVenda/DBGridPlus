object FrmPrincipal: TFrmPrincipal
  Left = 0
  Top = 0
  Caption = 'FrmPrincipal'
  ClientHeight = 614
  ClientWidth = 1038
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 1032
    Height = 57
    Align = alTop
    BevelKind = bkTile
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 0
    object Button1: TButton
      Left = 16
      Top = 15
      Width = 100
      Height = 25
      Caption = 'Teste'
      TabOrder = 0
      OnClick = Button1Click
    end
    object btnAbrirFechar: TButton
      Left = 160
      Top = 15
      Width = 100
      Height = 25
      Caption = 'Fechar/Abrir'
      TabOrder = 1
      OnClick = btnAbrirFecharClick
    end
    object Button3: TButton
      Left = 312
      Top = 15
      Width = 100
      Height = 25
      Caption = 'Fixar Coluna 1'
      TabOrder = 2
      OnClick = Button3Click
    end
    object DBLookupComboBox1: TDBLookupComboBox
      Left = 536
      Top = 15
      Width = 145
      Height = 24
      TabOrder = 3
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 63
    Width = 1038
    Height = 551
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'TDBGridPlus'
      object GridDados: TDBGridPlus
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1024
        Height = 515
        Align = alClient
        DataSource = dsDocumentos
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = []
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ParentFont = False
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = ANSI_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -13
        TitleFont.Name = 'Calibri'
        TitleFont.Style = []
        StyleName = 'Windows'
        Flat = False
        Bands.Strings = (
          'Identifica'#231#227'o'
          'Localiza'#231#227'o'
          'Data')
        BandsFont.Charset = DEFAULT_CHARSET
        BandsFont.Color = clWindowText
        BandsFont.Height = -11
        BandsFont.Name = 'Tahoma'
        BandsFont.Style = []
        GridStyle.Bands.Direction = fdLeftToRight
        GridStyle.StyleColorGrid = gsBrick
        GridStyle.OddColor = 13623263
        GridStyle.EvenColor = 10534847
        TitleHeight.PixelCount = 24
        FooterColor = 4074784
        FooterFont.Charset = DEFAULT_CHARSET
        FooterFont.Color = clLime
        FooterFont.Height = -13
        FooterFont.Name = 'Consolas'
        FooterFont.Style = [fsBold]
        OptionsEx = [eoBandsActive, eoEnterToTab, eoKeepSelection, eoShowGlyphs]
        WidthOfIndicator = 11
        DefaultRowHeight = 18
        GridLineWidth = 0
        Columns = <
          item
            Expanded = False
            FieldName = 'codigo'
            Visible = True
            BandIndex = 0
            SortType = stAscending
            FooterText = '%total%'
            CheckBox.CheckedValue = 'S'
            CheckBox.GrayedValue = 'U'
            CheckBox.UnCheckedValue = 'N'
          end
          item
            Expanded = False
            FieldName = 'nome'
            Width = 682
            Visible = True
            BandIndex = 0
            SortType = stAscending
            FooterText = '%total%'
            CheckBox.CheckedValue = 'S'
            CheckBox.GrayedValue = 'U'
            CheckBox.UnCheckedValue = 'N'
            ColunaAjuste.ColMinSize = 300
          end
          item
            Expanded = False
            FieldName = 'cep'
            Width = 100
            Visible = True
            BandIndex = 1
            SortType = stAscending
            FooterText = '%total%'
            CheckBox.CheckedValue = 'S'
            CheckBox.GrayedValue = 'U'
            CheckBox.UnCheckedValue = 'N'
          end
          item
            Expanded = False
            FieldName = 'data'
            Width = 127
            Visible = True
            BandIndex = 2
            SortType = stAscending
            FooterText = '%total%'
            CheckBox.CheckedValue = 'S'
            CheckBox.GrayedValue = 'U'
            CheckBox.UnCheckedValue = 'N'
          end>
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'TDBGrid'
      ImageIndex = 1
      object DBGrid1: TDBGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1024
        Height = 515
        Align = alClient
        DataSource = dsDocumentos
        DrawingStyle = gdsGradient
        FixedColor = clBackground
        GradientEndColor = clMaroon
        GradientStartColor = clLime
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgMultiSelect, dgTitleClick, dgTitleHotTrack]
        TabOrder = 0
        TitleFont.Charset = ANSI_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -12
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
        OnDrawColumnCell = DBGrid1DrawColumnCell
      end
    end
  end
  object DBConexao: TFDConnection
    Params.Strings = (
      'Database=qrsistema'
      'User_Name=root'
      'DriverID=MySQL')
    FormatOptions.AssignedValues = [fvFmtDisplayDate, fvFmtDisplayTime]
    FormatOptions.FmtDisplayDate = 'dd/mm/yyyy'
    FormatOptions.FmtDisplayTime = 'hh:mm:ss'
    ResourceOptions.AssignedValues = [rvAutoReconnect]
    ResourceOptions.AutoReconnect = True
    LoginPrompt = False
    Transaction = FDTransacao
    Left = 128
    Top = 320
  end
  object FDTransacao: TFDTransaction
    Connection = DBConexao
    Left = 192
    Top = 320
  end
  object FDPhysFBDriverLink: TFDPhysFBDriverLink
    Left = 160
    Top = 320
  end
  object qryDocumentos: TFDQuery
    Connection = DBConexao
    FetchOptions.AssignedValues = [evAutoClose]
    FetchOptions.AutoClose = False
    UpdateOptions.AutoIncFields = 'CODIGO'
    SQL.Strings = (
      'SELECT * FROM cad_pessoa ')
    Left = 128
    Top = 264
  end
  object dsDocumentos: TDataSource
    DataSet = qryDocumentos
    Left = 160
    Top = 264
  end
  object ClientDataSet1: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 232
    Top = 264
  end
  object PopupMenu1: TPopupMenu
    Left = 196
    Top = 264
    object A1: TMenuItem
      Caption = 'A'
      OnClick = A1Click
    end
    object A2: TMenuItem
      Caption = 'b'
      OnClick = A2Click
    end
    object v1: TMenuItem
      Caption = 'v'
      OnClick = v1Click
    end
  end
end
