{*******************************************************************************
* CRÉDITOS       : CRÉDITOS ao autor do "TSMDBGrid"                            *
*                  Site: https://www.scalabium.com/smdbgrid.htm                *
* Componente     : "TSMDBGrid"                                                 *
* Herança        : Herdado do TDBGrid (nativo do Delphi)                       *
*******************************************************************************}

{==============================================================================]
[ Unit           : DBGridPlus.pas                                              ]
[ Componente     : "TDBGridPlus"                                               ]
[ Herança        : "TDBGrid" (nativo do Delphi)                                ]
[ Antecessor     : TSMDBGrid - Herdado do TDBGrid                              ]
[ Escopo         : Componente DBGrid para formatar colunas e linhas.           ]
[------------------------------------------------------------------------------]
[ Versão         : 1.0.2                                                       ]
[ Criado em      : julho/2024                                                  ]
[ Última mod.    : março/2026                                                  ]
[------------------------------------------------------------------------------]
[ Coautoria      : (c) 2024-2026 Adriano Zanini                                ]
[ Licença        : Apache License 2.0                                          ]
[                  https://www.apache.org/licenses/LICENSE-2.0                 ]
[ GitHub         : https://github.com/QRVenda                                  ]
[==============================================================================}

{==============================================================================]
[ NOVAS FUNCIONALIDADES:                                                       ]
[     1. "ColunaAjuste" com essas 'subpropriedades':                           ]
[     1.1 ComMaxSize: Define largura máximo da coluna                          ]
[     1.2 ComMinSize: Define largura mínima da coluna                          ]
[     1.3 ColAutoWidth: Permite coluna ser Autoajustável.                      ]
[        Se ComMaxSize for > 0, autoajusta mas não deixa ultrapassar o valor   ]
[        ComMaxSize. Se ComMaxSize for 0, não tem limite de largura            ]
[        quando se autoajustar. Mesmo assim irá respeitar o ComMaxSize         ]
[        das outras colunas. Muita atenção ao combinar essa "concorrencia"     ]
[        de largura entre elas.                                                ]
[     2. "DisplayFormat":                                                      ]
[     2.1 Permite formatar a coluna de acordo com mascara que você definir     ]
[     2.1.1 Testado e validado com inteiros, valores e datas.                  ]
[     3. "CheckBox": Defina aqui o valor que é usado no seu banco de dados.    ]
[         Exemplos: Se pra coluna verdadeira (true) você usa "S", defina       ]
[         em "CheckedValue" o valor: "S" (sem aspas). E assim por diante.      ]
[     3.1 CheckedValue: Valor que faz o checkbox ficar marcado                 ]
[     3.2 UnCheckedValue: Valor que faz o checkbox ficar desmarcado            ]
[                                                                              ]
[==============================================================================}

unit DBGridPlus;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Clipbrd, System.TypInfo, System.UITypes, Vcl.Themes,
  System.Types, Vcl.ExtDlgs, System.IniFiles, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls,
  Vcl.Menus, Data.DB, Datasnap.DBClient, Vcl.DBCtrls, System.Math,
  FireDAC.Comp.Client,
  DBGridPlusConst,
  DBGridPlusUtil,
  DBGridPlusDraw;

type

  THackLink     = class(TGridDataLink);
  THackGrid     = class(TCustomGrid);
  THackDBGrid   = class(TCustomDBGrid);
  TBookmarks    = class(TBookmarkList);
  TDBGridPlus   = class;
  TPlusDBColumn = class;

  TCheckTitleBtnEvent      = procedure(Sender: TObject; ACol: Longint; Field: TField; var Enabled: Boolean) of object;
  TGetCellParamsEvent      = procedure(Sender: TObject; Field: TField; AFont: TFont; var Background: TColor; Highlight: Boolean) of object;
  TGetBtnParamsEvent       = procedure(Sender: TObject; Field: TField; AFont: TFont; var Background: TColor; IsDown: Boolean) of object;

  TGetGlyphEvent           = procedure(Sender: TObject; var Bitmap: TBitmap) of object;
  TGetCellHint             = procedure(Sender: TObject; Column: TColumn; var HintStr: string; var HintInfo: THintInfo) of object;

  TGetRecordCountEvent     = procedure(Sender: TObject; var RecordCount: Integer) of object;
  TPlusSortChangedEvent    = procedure(Sender: TObject; Column: TColumn) of object;

  TDrawFooterCellEvent     = procedure(Sender: TObject; Canvas: TCanvas; FooterCellRect: TRect; Field: TField; var FooterText: String; var DefaultDrawing: Boolean) of object;

  TGetParsedExpression     = procedure(Sender: TObject; Expression: TPlusString; var Text: TPlusString; var Value: Boolean) of object;
  TAccentStringConvert     = function(Sender: TObject; const S: string): string of object;

  // CheckBox
  TGridPlusColumnCheckBox = class(TPersistent)
  private
    FColumn: TPlusDBColumn;
    FCheckedValue: string;
    FUnCheckedValue: string;
    FGrayedValue: string;
  public
    constructor Create(Column: TPlusDBColumn);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property CheckedValue   : string read FCheckedValue   write FCheckedValue;
    property GrayedValue    : string read FGrayedValue    write FGrayedValue;
    property UnCheckedValue : string read FUnCheckedValue write FUnCheckedValue;
  end;

  // AutoAjuste
  TColunaAjuste = class(TPersistent)
  private
    FColumn           : TPlusDBColumn;
    FColAutoWidth     : Boolean;
    FColMinSize       : Integer;
    FColMaxSize       : Integer;
    procedure SetColAutoWidth(const Value: Boolean);
    procedure SetColMaxSize(const Value: Integer);
    procedure SetColMinSize(const Value: Integer);
  public
    constructor Create(Column: TPlusDBColumn);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property ColAutoWidth       : Boolean    read FColAutoWidth  write SetColAutoWidth      default False;
    property ColMinSize         : Integer    read FColMinSize    write SetColMinSize        default _MIN_COLMINSIZE;
    property ColMaxSize         : Integer    read FColMaxSize    write SetColMaxSize        default 0;
  end;

  // Coluna (TColumn)
  TPlusDBColumn = class(TColumn)
  private
    FBandIndex            : Integer;
    FSortCaption          : TPlusString;
    FSortType             : TPlusSortType;
    FInplaceEditor        : TPlusInplaceEditorType;
    FFooterValue          : Variant;
    FFooterType           : TPlusFooterType;
    FFooterText           : String;
    FTag                  : Longint;
    FTextEllipsis         : TPlusTextEllipsis;
    FVerticalAlignment    : TPlusGVerticalAlignment;
    FDisplayFormat        : String;
    FCheckBox             : TGridPlusColumnCheckBox;
    FColunaAjuste         : TColunaAjuste;

    procedure SetFooterValue(Value: Variant);
    procedure SetFooterType(Value: TPlusFooterType);
    procedure SetSortCaption(Value: TPlusString);
    procedure SetSortType(Value: TPlusSortType);
    procedure SetInplaceEditor(Value: TPlusInplaceEditorType);
    procedure SetFooterText(const Value: String);
    procedure SetDisplayFormat(const Value: String);
  protected
    intInternalCount: Integer;
    function GetGrid: TDBGridPlus;
    function CreateCheckBox: TGridPlusColumnCheckBox; dynamic;
    function CreateColunaAjuste: TColunaAjuste; dynamic;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure RestoreDefaults; override;
    procedure DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean); virtual;
    property Grid               : TDBGridPlus read GetGrid;
  published
    property BandIndex          : Integer                   read FBandIndex                write FBandIndex default -1;
    property SortCaption        : TPlusString               read FSortCaption              write SetSortCaption;
    property SortType           : TPlusSortType             read FSortType                 write SetSortType default stNone;
    property InplaceEditor      : TPlusInplaceEditorType    read FInplaceEditor            write SetInplaceEditor default ieNormal;
    property FooterValue        : Variant                   read FFooterValue              write SetFooterValue;
    property FooterType         : TPlusFooterType           read FFooterType               write SetFooterType default ftCustom;
    property FooterText         : String                    read FFooterText               write SetFooterText;
    property Tag                : Longint                   read FTag                      write FTag default 0;
    property TextEllipsis       : TPlusTextEllipsis         read FTextEllipsis             write FTextEllipsis default teNone;
    property VerticalAlignment  : TPlusGVerticalAlignment   read FVerticalAlignment        write FVerticalAlignment default gvaTop;
    property DisplayFormat      : String                    read FDisplayFormat            write SetDisplayFormat;
    property CheckBox           : TGridPlusColumnCheckBox   read FCheckBox                 write FCheckBox;
    property ColunaAjuste       : TColunaAjuste             read FColunaAjuste             write FColunaAjuste;

  end;

  TPlusDBProgressColumn = class(TPlusDBColumn)
  private
    FMin: Integer;
    FMax: Integer;
    FColor: TColor;
  protected
  public
    constructor Create(Collection: TCollection); override;
    procedure DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean); override;
  published
    property Min: Integer read FMin write FMin;
    property Max: Integer read FMax write FMax;
    property Color: TColor read FColor write FColor;
  end;

  TPlusDBCheckboxColumn = class(TPlusDBColumn)
  private
    FValueChecked: TPlusString;
    FValueUnChecked: TPlusString;
  protected
    procedure SetValueChecked(const AValue: TPlusString);
    procedure SetValueUnChecked(const AValue: TPlusString);
  public
    constructor Create(Collection: TCollection); override;
    procedure DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean); override;
  published
    property ValueChecked: TPlusString read FValueChecked write FValueChecked;
    property ValueUnChecked: TPlusString read FValueUnChecked write FValueUnChecked;
  end;

  TDBGridPlusColumns = class(TDBGridColumns)
  private
    function GetColumn(Index: Integer): TPlusDBColumn;
    procedure SetColumn(Index: Integer; Value: TPlusDBColumn);
  protected
  public
    function Add: TPlusDBColumn;
    property Items[Index: Integer]: TPlusDBColumn read GetColumn write SetColumn; default;
  end;


  TPlusGradientDraw = class(TPersistent)
  private
    FGrid: TDBGridPlus;
    FDirection: TPlusGradientDirection;
    FStartColor: TColor;
    FEndColor: TColor;

    procedure SetDirection(Value: TPlusGradientDirection);
    procedure SetStartColor(AValue: TColor);
    procedure SetEndColor(AValue: TColor);
  public
    constructor Create(AGrid: TDBGridPlus); virtual;
  published
    property Direction: TPlusGradientDirection read FDirection write SetDirection default fdNone;
    property StartColor: TColor read FStartColor write SetStartColor default clWhite;
    property EndColor: TColor read FEndColor write SetEndColor default $00DDDDDD;
  end;

  TDBGridPlusStyle = class(TPersistent)
  private
    FGrid: TDBGridPlus;
    FStyleColorGrid: TStyleColorGrid;
    FOddColor: TColor;
    FEvenColor: TColor;
    FBackground: TBitmap;
    FBandGradientDraw: TPlusGradientDraw;
    FTitle: TPlusGradientDraw;
    FFooter: TPlusGradientDraw;
    FWallpaper: TPlusGradientDraw;
    FGrouping: TPlusGradientDraw;
    FSelection: TPlusGradientDraw;

    procedure SetBackground(Value: TBitmap);
    procedure SetStyleColorGrid(Value: TStyleColorGrid);
    procedure SetOddColor(AValue: TColor);
    procedure SetEvenColor(AValue: TColor);

    function GetGradient(Index: Integer): TPlusGradientDraw;
    procedure SetGradient(Index: Integer; Value: TPlusGradientDraw);
  public
    constructor Create(AGrid: TDBGridPlus); virtual;
    destructor Destroy; override;

    function IsDefaultBackground: Boolean;
  published
    property Bands            : TPlusGradientDraw   index 0 read GetGradient        write SetGradient;
    property Title            : TPlusGradientDraw   index 1 read GetGradient        write SetGradient;
    property Footer           : TPlusGradientDraw   index 2 read GetGradient        write SetGradient;
    property Wallpaper        : TPlusGradientDraw   index 3 read GetGradient        write SetGradient;
    property Grouping         : TPlusGradientDraw   index 4 read GetGradient        write SetGradient;
    property Selection        : TPlusGradientDraw   index 5 read GetGradient        write SetGradient;
    property StyleColorGrid   : TStyleColorGrid             read FStyleColorGrid    write SetStyleColorGrid;
    property OddColor         : TColor                      read FOddColor          write SetOddColor;
    property EvenColor        : TColor                      read FEvenColor         write SetEvenColor;
    property Background       : TBitmap                     read FBackground        write SetBackground;
  end;

  TPlusDBGTitleHeight = class(TPersistent)
  private
    { Private declarations }
    FGrid: TDBGridPlus;
    FKind: TPlusDBGTitleHeightKind;
    FLineCount: Integer;
    FPixelCount: Integer;

    procedure SetKind(Value: TPlusDBGTitleHeightKind);
    procedure SetLineCount(Value: Integer);
    procedure SetPixelCount(Value: Integer);
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AGrid: TDBGridPlus); virtual;
    procedure Assign(Source: TPersistent); override;
  published
    { Published declarations }
    property Kind         : TPlusDBGTitleHeightKind read FKind        write SetKind default hkAuto;
    property LineCount    : Integer                 read FLineCount   write SetLineCount default 1;
    property PixelCount   : Integer                 read FPixelCount  write SetPixelCount default 0;
  end;

  TDBGridPlus = class(TDBGrid)
  private
    { Private declarations }
    FBands: TStrings;
    FBandsFont: TFont;

    FFlat: Boolean;
    FOptionsEx: TOptionsEx;
    FGridStyle: TDBGridPlusStyle;
    FTitleHeight: TPlusDBGTitleHeight;
    FFooterColor: TColor;
    FFooterFont: TFont;
    FFooterHeight: Integer;
    FOnUpdateFooter: TNotifyEvent;
    FOnDrawFooterCell: TDrawFooterCellEvent;
    FOnCellHint: TGetCellHint;
    FOnExpression: TGetParsedExpression;
    FOnGetRecordCount: TGetRecordCountEvent;
    FOnSortChanged: TPlusSortChangedEvent;
    FHintField: TPlusString;
    FImages: TImageList;
    FMultiSelect: Boolean;
    FSelecting: Boolean;
    FMsIndicators: TImageList;
    FSelectionAnchor:TBytes;
    FDisableCount: Integer;
    FFixedCols: Integer;
    FSwapButtons: Boolean;
    FOnCheckButton: TCheckTitleBtnEvent;
    FTracking: Boolean;
    FPressedCol: Longint;
    FPressed: Boolean;
    FOnGetCellParams: TGetCellParamsEvent;
    FOnGetBtnParams: TGetBtnParamsEvent;

    FOnAppendRecord: TNotifyEvent;
    FOnInsertRecord: TNotifyEvent;
    FOnEditRecord: TNotifyEvent;
    FOnDeleteRecord: TNotifyEvent;
    FOnPostData: TNotifyEvent;
    FOnCancelData: TNotifyEvent;
    FOnRefreshData: TNotifyEvent;
    FOnPrintData: TNotifyEvent;
    FOnExportData: TNotifyEvent;
    FOnSetupGrid: TNotifyEvent;
    FOnSelectionChange: TNotifyEvent;
    FOnSelectionChanging: TNotifyEvent;
    FOnEditChange: TNotifyEvent;
    FOnTopLeftChanged: TNotifyEvent;
    FOnDrawColumnTitle: TDrawColumnCellEvent;
    FOnGetGlyph: TGetGlyphEvent;
    FWidthOfIndicator: Integer;
    FAutoFitIsLocked: Boolean;
    StartOfSelect: TBookmark;
    FScrollHintWnd: THintWindow;
    FLastRect: TRect;
    FLastRow, FLastCol: Integer;
    FLastXPDrawn: Boolean;
    HScrollbar: Boolean;
    VScrollbar: Boolean;
    FOnColWidthsChanged: TNotifyEvent;
    FOnDrawBackground: TNotifyEvent;
    FIsFlagAlwaysShowEditor: Boolean;
    FOnAccentStringConvert: TAccentStringConvert;
    FIsHighlighted: boolean;

    function GetScrollBars: TScrollStyle;
    procedure SetScrollBars(Value: TScrollStyle);
    function GetCalculatedDefaultRowHeight: Integer;
    function GetDefaultRowHeight: Integer;
    procedure SetDefaultRowHeight(Value: Integer);
    procedure SetRowHeight;
    procedure SetBandsFont(Value: TFont);
    procedure SetBands(Value: TStrings);
    function GetBandRect(ACol: Integer): TRect;
    procedure FreeStartOfSelect;
    procedure SetGridStyle(Value: TDBGridPlusStyle);
    procedure SetTitleHeight(Value: TPlusDBGTitleHeight);
    procedure SetFooterColor(Value: TColor);
    procedure SetFooterFont(const Value: TFont);
    procedure SetFooterHeight(Value: Integer);
    function ColumnIsCheckbox(AColumn: TColumn): Boolean;
    procedure SetIndicatorWidth(Value: Integer);
    procedure AppendClick(Sender: TObject);
    procedure InsertClick(Sender: TObject);
    procedure EditClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure PrintClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure PostClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure SetupGridClick(Sender: TObject);
    procedure SetFixedCols(Value: Integer);
    function GetFixedCols: Integer;
    function GetTitleOffset: Byte;
    procedure StopTracking;
    procedure TrackButton(X, Y: Integer);
    function AcquireFocus: Boolean;
    function ActiveRowSelected: Boolean;
    function GetOptions: TDBGridOptions;
    procedure SetOptions(Value: TDBGridOptions);
    function GetImageIndex(Field: TField): Integer;
    procedure SetOptionsEx(Val: TOptionsEx);
    procedure SetTitlesHeight;
    procedure CMHintShow(var Msg: TMessage); message CM_HINTSHOW;
    function GetSortImageWidth: Integer;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPaint;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure SetFlat(Value: Boolean);
    function IsMouseInRect(ARect: TRect): Boolean;
    function GetColumns: TDBGridPlusColumns;
    procedure SetColumns(Value: TDBGridPlusColumns);
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED; {MS1} // Work-A-Round for QC #74520
    procedure SetOnChangeSelection(Value: TNotifyEvent);
    function IsReading: boolean;

  protected
    { Protected declarations }
    procedure Paint; override;
    procedure DblClick; override;
    procedure Loaded; override;

    procedure DrawGridBackground; virtual;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    function CreateColumns: TDBGridColumns; override;
    function CreateEditor: TInplaceEdit; override;
    procedure EditChanged(Sender: TObject); dynamic;
    procedure TitleClick(Column: TColumn); override;

    {Aqui Auto ajusta colunas}
    procedure UpdateColWidths; virtual;
    procedure AjustarTamanhoMinimo;
    procedure AjustarTamanhoMaximo;
    procedure ConfigurarMascara;
    function CalcTitleRect1(Col: TColumn; ARow: Integer; var MasterCol: TColumn): TRect;

    {for footer support}
    function GetClientRect: TRect; override;
    procedure DoUpdateFooter; virtual;
    function GetFooterRect: TRect; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function HighlightCell(DataCol, DataRow: Integer; const Value: string; AState: TGridDrawState): Boolean; override;
    procedure Scroll(Distance: Integer); override;
    procedure DoTabChange(Sender: TObject);
    procedure LayoutChanged; override;
    procedure ColWidthsChanged; override;
    procedure SizeChanged(OldColCount, OldRowCount: Integer); override;
    procedure RowHeightsChanged; override;
    procedure SetColumnAttributes; override;
    procedure TopLeftChanged; override;
    function CanEditShow: Boolean; override;

    procedure CheckTitleButton(ACol: Longint; var Enabled: Boolean); dynamic;
    procedure GetCellProps(ACol, ARow: Integer; Field: TField; AFont: TFont; var Background: TColor;
      Highlight: Boolean); dynamic;

    procedure CellClick(Column: TColumn); override;
    function CellRectForDraw(R: TRect; ACol: Longint): TRect;
    function ApplyBackroundColorToCanvas(DataCol, ARow: Integer; AColumn: TColumn; State: TGridDrawState): TColor;
    procedure DrawColumnCell(const Rect: TRect; DataCol: Integer;  Column: TColumn; State: TGridDrawState); override;
    function GetGlyph: TBitmap; virtual;
    procedure DrawComboArrow(R: TRect);
    function GetCheckBoxValue(AField: TField; Value: Variant; ValueChecked: TPlusString; aColumn: TColumn = nil): TCheckBoxState;
    procedure DrawCheckBox(R: TRect; AState: TCheckBoxState; al: TAlignment); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function GetVerticalAlignment(AColumn: TColumn): TPlusGVerticalAlignment;
    procedure DefDrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
    procedure WMHScroll(var Message: TWMHSCroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMVSCroll); message WM_VSCROLL;
    function GetRecordCount: Integer;
    procedure ApplyStyleColors(ACanvas: TCanvas); virtual;
    procedure DrawFooterRow;
    procedure SMSelectionChanging; virtual;
    procedure SMSelectionChanged; virtual;
    procedure ChangeScale(M, D: Integer); override;
    property IsHighlighted: boolean read FIsHighlighted write FIsHighlighted;


  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DeleteData;
    procedure RefreshData;
    procedure InvalideTab;
    procedure InvalidateFooter;
    procedure CalculateTotals(OnlySelected: Boolean = False);
    procedure SelectOneClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure UnSelectOneClick(Sender: TObject);
    procedure UnSelectAllClick(Sender: TObject);
    procedure SaveLayoutClick(Sender: TObject);
    procedure RestoreLayoutClick(Sender: TObject);
    procedure ToggleRowSelection;
    procedure GotoSelection(Index: Longint);
    procedure DisableScroll;
    procedure EnableScroll;
    function ScrollDisabled: Boolean;
    procedure ClearSort;
    procedure SetSortField(AField: TField; ASortType: TPlusSortType);
    procedure ResyncIndicator;
    procedure UpdateLayout;
    property IndicatorOffset;
    property TitleOffset: Byte read GetTitleOffset;
    property Columns: TDBGridPlusColumns read GetColumns write SetColumns;
    property Col;
    property Row;
    property ColCount;
    property RowCount;
    property VisibleColCount;
    property VisibleRowCount;
  published
    { Published declarations }
    property Flat                   : Boolean                   read FFlat                   write SetFlat;
    property Bands                  : TStrings                  read FBands                  write SetBands;
    property BandsFont              : TFont                     read FBandsFont              write SetBandsFont;
    property GridStyle              : TDBGridPlusStyle          read FGridStyle              write SetGridStyle;
    property TitleHeight            : TPlusDBGTitleHeight       read FTitleHeight            write SetTitleHeight;
    property FooterColor            : TColor                    read FFooterColor            write SetFooterColor;
    property FooterFont             : TFont                     read FFooterFont             write SetFooterFont;
    property FooterHeight           : Integer                   read FFooterHeight           write SetFooterHeight default 0;
    property OptionsEx              : TOptionsEx                read FOptionsEx              write SetOptionsEx;
    property HintField              : TPlusString               read FHintField              write FHintField;
    property Images                 : TImageList                read FImages                 write FImages;
    property Options                : TDBGridOptions            read GetOptions              write SetOptions;
    property FixedCols              : Integer                   read GetFixedCols            write SetFixedCols default 0;
    property WidthOfIndicator       : Integer                   read FWidthOfIndicator       write SetIndicatorWidth;
    property OnGetCellParams        : TGetCellParamsEvent       read FOnGetCellParams        write FOnGetCellParams;
    property OnAppendRecord         : TNotifyEvent              read FOnAppendRecord         write FOnAppendRecord;
    property OnInsertRecord         : TNotifyEvent              read FOnInsertRecord         write FOnInsertRecord;
    property OnEditRecord           : TNotifyEvent              read FOnEditRecord           write FOnEditRecord;
    property OnDeleteRecord         : TNotifyEvent              read FOnDeleteRecord         write FOnDeleteRecord;
    property OnPostData             : TNotifyEvent              read FOnPostData             write FOnPostData;
    property OnCancelData           : TNotifyEvent              read FOnCancelData           write FOnCancelData;
    property OnRefreshData          : TNotifyEvent              read FOnRefreshData          write FOnRefreshData;
    property OnPrintData            : TNotifyEvent              read FOnPrintData            write FOnPrintData;
    property OnExportData           : TNotifyEvent              read FOnExportData           write FOnExportData;
    property OnCheckButton          : TCheckTitleBtnEvent       read FOnCheckButton          write FOnCheckButton;
    property OnCellHint             : TGetCellHint              read FOnCellHint             write FOnCellHint;
    property OnExpression           : TGetParsedExpression      read FOnExpression           write FOnExpression;
    property OnGetRecordCount       : TGetRecordCountEvent      read FOnGetRecordCount       write FOnGetRecordCount;
    property OnEditChange           : TNotifyEvent              read FOnEditChange           write FOnEditChange;
    property OnTopLeftChanged       : TNotifyEvent              read FOnTopLeftChanged       write FOnTopLeftChanged;
    property OnSelectionChanging    : TNotifyEvent              read FOnSelectionChanging    write FOnSelectionChanging;
    property OnSelectionChange      : TNotifyEvent              read FOnSelectionChange      write FOnSelectionChange;
    property OnChangeSelection      : TNotifyEvent              read FOnSelectionChange      write SetOnChangeSelection;
    property OnSetupGrid            : TNotifyEvent              read FOnSetupGrid            write FOnSetupGrid;
    property OnDrawColumnTitle      : TDrawColumnCellEvent      read FOnDrawColumnTitle      write FOnDrawColumnTitle;
    property OnGetGlyph             : TGetGlyphEvent            read FOnGetGlyph             write FOnGetGlyph;
    property OnDrawFooterCell       : TDrawFooterCellEvent      read FOnDrawFooterCell       write FOnDrawFooterCell;
    property OnUpdateFooter         : TNotifyEvent              read FOnUpdateFooter         write FOnUpdateFooter;
    property OnSortChanged          : TPlusSortChangedEvent     read FOnSortChanged          write FOnSortChanged;
    property OnColWidthsChanged     : TNotifyEvent              read FOnColWidthsChanged     write FOnColWidthsChanged;
    property OnDrawBackground       : TNotifyEvent              read FOnDrawBackground       write FOnDrawBackground;
    property DefaultRowHeight       : Integer                   read GetDefaultRowHeight     write SetDefaultRowHeight;
    property OnAccentStringConvert  : TAccentStringConvert      read FOnAccentStringConvert  write FOnAccentStringConvert;
    property ScrollBars             : TScrollStyle              read GetScrollBars           write SetScrollBars default ssBoth;
    property GridLineWidth;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property ParentBiDiMode;
  end;
  procedure SaveGridToIni(grid: TCustomDBGrid; const FileName: string; const SectionName: string = '');
  procedure LoadGridFromIni(grid: TCustomDBGrid; const FileName: string; const SectionName: string = '' );
  function IsXPThemesEnabled: Boolean; forward;

  procedure Register;

implementation

{$R *.RES}

procedure Register;
begin
  RegisterComponents('Samples', [TDBGridPlus]);
end;

procedure ListIntersect(OldList, NewList: TStrings);
var
  i: Integer;
begin
  i := OldList.Count-1;
  while i > -1 do
  begin
    if NewList.IndexOf(OldList[i]) < 0 then
      OldList.Delete(i);

    Dec(i);
  end;
end;

function GetIndexDefs(ds: TDataSet): TIndexDefs;
var
  i: Integer;
  PropInfoIndices: PPropInfo;
begin
  Result := nil;
  PropInfoIndices := GetPropInfo(ds.ClassInfo, 'IndexDefs');
  if Assigned(PropInfoIndices) and
    (PropInfoIndices.PropType^.Kind = tkClass) then
  begin
    i := GetOrdProp(ds, PropInfoIndices);
    if TObject(i) is TIndexDefs then
      Result := TIndexDefs(i)
  end;
end;

function GetIndexDef(IndexDefs: TIndexDefs; const sName: string): TIndexDef;
var
  i: Integer;
begin
  Result := nil;

  if Assigned(IndexDefs) then
  begin
    i := IndexDefs.IndexOf(sName);
    if i <> -1 then
      Result := IndexDefs[i]
  end;
end;

procedure SetIndexName(ds: TDataSet; const strValue: string);
var
  PropInfo: PPropInfo;
begin
  PropInfo := GetPropInfo(ds.ClassInfo, 'IndexName');

  if Assigned(PropInfo) then
  begin
    case PropInfo^.PropType^^.Kind of
      tkUString,
      tkString,
      tkLString,
      tkWString: SetStrProp(ds, PropInfo, strValue);
    end;
  end
end;

function GetCommaText(const List: TStrings; ch: Char): string;
var
  i, j: integer;
begin
  j := List.Count;

  if j > 0 then
  begin
    Result := List[0];
    for i := 1 to j-1 do
      Result := Result + ch + List[i];
  end
  else
    Result := '';
end;

procedure SortGrid(Column: TColumn);
var
  OrdemCampo : String;
begin
  OrdemCampo := ':N';

  if not Assigned(Column.Field.DataSet) then
    Exit;

  if not Column.Field.DataSet.Active then
    Exit;

  if not Assigned(Column) then
    Exit;

  if not Assigned(Column.Field) then
    Exit;

  if TPlusDBColumn(Column).SortType = stNone then // stNone = Não pode ser ordenado
    Exit;

  TFDQuery(Column.Field.Dataset).DisableControls;
  try
    if (Column is TPlusDBColumn) then
    begin
      case TPlusDBColumn(Column).SortType of
        stAscending  : begin
                         OrdemCampo := ':A';
                         TPlusDBColumn(Column).SortType := stDescending; // Inverso para a próxima seleção
                       end;

        stDescending : begin
                         OrdemCampo := ':D';
                         TPlusDBColumn(Column).SortType := stAscending; // Inverso para a próxima seleção
                       end;
      end;
    end;

    TFDQuery(Column.Field.Dataset).IndexFieldNames := Column.FieldName + OrdemCampo;
  finally
    TFDQuery(Column.Field.Dataset).First;
    TFDQuery(Column.Field.Dataset).EnableControls;
  end;
end;

function Font2String(smFont: TFont; cl: TColor; al: TAlignment): string;
begin
  Result := smFont.Name + ',' +
            IntToStr(smFont.CharSet) + ',' +
            IntToStr(smFont.Color) + ',' +
            IntToStr(smFont.Size) + ',' +
            IntToStr(Byte(smFont.Style)) + ',' +
            IntToStr(cl) + ','+
            IntToStr(Ord(al));
end;

procedure String2Font(Value: string; smFont: TFont; var Background: TColor; var al: TAlignment);
var
  Data: string;
  i: Integer;
begin
  try
    i := Pos(',', Value);
    if i > 0 then
    begin
      {Name}
      Data := Trim(Copy(Value, 1, i-1));
      if Data <> '' then
        smFont.Name := Data;
      Delete(Value, 1, i);
      i := Pos(',', Value);
      if i > 0 then
      begin
        {CharSet}
        Data := Trim(Copy(Value, 1, i-1));
        if Data <> '' then
          smFont.Charset := TFontCharSet(StrToIntDef(Data, smFont.Charset));
        Delete(Value, 1, i);
        i := Pos(',', Value);
        if i > 0 then
        begin
          {Color}
          Data := Trim(Copy(Value, 1, i-1));
          if Data <> '' then
            smFont.Color := TColor(StrToIntDef(Data, smFont.Color));
          Delete(Value, 1, i);
          i := Pos(',', Value);
          if i > 0 then
          begin
            {Size}
            Data := Trim(Copy(Value, 1, i-1));
            if Data <> '' then
              smFont.Size := StrToIntDef(Data, smFont.Size);
            Delete(Value, 1, i);
            i := Pos(',', Value);
            if i > 0 then
            begin
              {Style}
              Data := Trim(Copy(Value, 1, i-1));
              if Data <> '' then
                smFont.Style := TFontStyles(Byte(StrToIntDef(Data, Byte(smFont.Style))));
              Delete(Value, 1, i);
              i := Pos(',', Value);
              if i > 0 then
              begin
                {Background}
                Data := Trim(Copy(Value, 1, i-1));
                if Data <> '' then
                  Background := TColor(StrToIntDef(Data, Background));
                Delete(Value, 1, i);
                {alignment}
                Data := Trim(Value);
                if Data <> '' then
                  al := TAlignment(StrToIntDef(Data, Ord(al)));
              end
            end
          end
        end
      end
    end;
  except
  end;
end;

function NormalizedText(const s: string): string;
begin
  if (Pos(',', s) > 0) then
    Result := '"' + s + '"'
  else
    Result := s
end;

function GetValueFromKey(var strValues: string): string;
var
  P: PChar;
  intStart, intEnd: Integer;
  IsBody: Boolean;
begin
  if (strValues = '') then
  begin
    Result := '';
    exit;
  end;

  P := PChar(strValues);
  intStart := 1;
  intEnd := 1;
  IsBody := (P^ = '"');
  if IsBody then
    Inc(intStart);
  while (P <> nil) and (P^ <> #0) do
  begin
    if (P^ = ',') and not IsBody then
      break
    else
    if IsBody and (P^ = '"') then
      IsBody := False;

    Inc(P);
    Inc(intEnd);
  end;
  Result := Copy(strValues, intStart, intEnd-intStart);
  Delete(strValues, 1, intEnd);

  intEnd := Length(Result);
  if (intEnd > 0) then
    if (Result[intEnd] = '"') then
      Delete(Result, intEnd, 1);

end;

procedure SaveGridToIni(grid: TCustomDBGrid; const FileName: string; const SectionName: string = '');
var
  i: Integer;
  strSection, strAttr: string;
begin
  if (SectionName = '') then
    strSection := grid.Name
  else
    strSection := SectionName;
  with TIniFile.Create(FileName) do
    try
      WriteInteger(strSection, 'Count', THackDBGrid(grid).Columns.Count);
      for i := 0 to THackDBGrid(grid).Columns.Count-1 do
      begin
        with THackDBGrid(grid).Columns.Items[i] do
        begin
          if ReadOnly then
            strAttr := 'R'
          else
            strAttr := '';
          WriteString(strSection, IntToStr(i),
                      Format('%s,%d,%s,%s', [FieldName, Width, NormalizedText(Title.Caption), strAttr]));

          WriteString(strSection, IntToStr(i) + '_Title', Font2String(Title.Font, Title.Color, Title.Alignment));
          WriteString(strSection, IntToStr(i) + '_Data', Font2String(Font, Color, Alignment));
        end;
        if (grid is TDBGridPlus) and (THackDBGrid(grid).Columns.Items[i] is TPlusDBColumn) then
          with TPlusDBColumn(THackDBGrid(grid).Columns.Items[i]) do
          begin
            WriteString(strSection,
                        IntToStr(i) + '_Sort',
                        Format('%d,%s,%d,%d,%s,%d,%d', [Ord(SortType), NormalizedText(SortCaption), BandIndex, Ord(InplaceEditor), NormalizedText(VarToStr(FooterValue)), Ord(FooterType), Tag]));
          end;
      end;
    finally
      Free;
    end
end;

procedure LoadGridFromIni(grid: TCustomDBGrid; const FileName: string; const SectionName: string  = '');
var
  i, Count, aWidth: Integer;
  s, strSection, strAttr: string;
  cl: TColor;
  col: TColumn;
  al: TAlignment;
begin
  THackDBGrid(grid).BeginLayout;
  if grid is TDBGridPlus then
    TDBGridPlus(grid).FAutoFitIsLocked := True;

  if (SectionName = '') then
    strSection := grid.Name
  else
    strSection := SectionName;

  with TIniFile.Create(FileName) do
    try
      Count := ReadInteger(strSection, 'Count', 0);
      if (Count > 0) then
      begin
        THackDBGrid(grid).Columns.Clear;
        for i := 0 to Count-1 do
        begin
          s := ReadString(strSection, IntToStr(i), '');
          if (s <> '') then
          begin
            col := THackDBGrid(grid).Columns.Add;
            col.FieldName := GetValueFromKey(s);
            aWidth := StrToIntDef(GetValueFromKey(s), 64);
            if (aWidth > -1) then
              col.Width := aWidth
            else
              col.Visible := False;

            col.Title.Caption := GetValueFromKey(s);
            strAttr := GetValueFromKey(s);
            col.ReadOnly := (Pos('R', strAttr) > 0);

            s := ReadString(strSection, IntToStr(i) + '_Title', '');
            if (s <> '') then
            begin
              cl := col.Title.Color;
              al := col.Title.Alignment;
              String2Font(s, col.Title.Font, cl, al);
              col.Title.Color := cl;
              col.Title.Alignment := al;
            end;
            s := ReadString(strSection, IntToStr(i) + '_Data', '');
            if (s <> '') then
            begin
              cl := col.Color;
              al := col.Alignment;
              String2Font(s, col.Font, cl, al);
              col.Color := cl;
              col.Alignment := al;
            end;

            if col is TPlusDBColumn then
            begin
              s := ReadString(strSection, IntToStr(i) + '_Sort', '');
              if (s <> '') then
                with TPlusDBColumn(col) do
                begin
                  SortType := TPlusSortType(StrToIntDef(GetValueFromKey(s), 0));
                  SortCaption := GetValueFromKey(s);

                  BandIndex := StrToIntDef(GetValueFromKey(s), 0);
                  FInplaceEditor := TPlusInplaceEditorType(StrToIntDef(GetValueFromKey(s), 0));
                  FooterValue := GetValueFromKey(s);
                  FooterType := TPlusFooterType(StrToIntDef(GetValueFromKey(s), 0));
                  Tag := StrToIntDef(GetValueFromKey(s), 0);
                end
            end;
          end;
        end;
      end;
    finally
      Free;

      if grid is TDBGridPlus then
        TDBGridPlus(grid).FAutoFitIsLocked := False;
      THackDBGrid(grid).EndLayout;
    end;
end;


function GetGridBitmap(BmpType: TGridPicture): TBitmap;
begin
  if GridBitmaps[BmpType] = nil then
  begin
    GridBitmaps[BmpType] := TBitmap.Create;
    GridBitmaps[BmpType].Handle := LoadBitmap(HInstance, GridBmpNames[BmpType]);
  end;
  Result := GridBitmaps[BmpType];
end;

procedure DestroyLocals; far;
var
  i: TGridPicture;
begin
  for i := Low(TGridPicture) to High(TGridPicture) do
    GridBitmaps[i].Free;
end;

procedure GridInvalidateRow(Grid: TDBGridPlus; Row: Longint);
var
  i: Longint;
begin
  for i := 0 to Grid.ColCount - 1 do
    Grid.InvalidateCell(i, Row);
end;

procedure GetCheckBoxSize;
begin
  with TBitmap.Create do
    try
      Handle := LoadBitmap(0, PChar(OBM_CHECKBOXES));
      FCheckWidth := Width div 4;
      FCheckHeight := Height div 3;
    finally
      Free;
    end;
end;

procedure WriteTitleText(ACanvas: TCanvas; ARect: TRect; DX, DY: Integer;
  const Text: TPlusString; Alignment: TAlignment; VAlignment: TPlusGVerticalAlignment; TextEllipsis: TPlusTextEllipsis; IsWordBreak: Boolean; ARightToLeft: Boolean);
const
  EllipsisFlags: array [TPlusTextEllipsis] of Integer = (0, DT_END_ELLIPSIS, DT_PATH_ELLIPSIS);
  WordBreaks: array [Boolean] of Integer = (0, DT_WORDBREAK);
  AlignFlags: array [TAlignment] of Integer =
     (DT_LEFT or DT_EXPANDTABS or DT_NOPREFIX or DT_VCENTER,
      DT_RIGHT or DT_EXPANDTABS or DT_NOPREFIX or DT_VCENTER,
      DT_CENTER or DT_EXPANDTABS or DT_NOPREFIX or DT_VCENTER);

  VAlignFlags: array [TPlusGVerticalAlignment] of Integer =
     (0,
      DT_VCENTER,
      0);

  RTL: array [Boolean] of Integer = (0, DT_RTLREADING);

var
  B, R: TRect;
  Flags, intTextHeight: Integer;
  Hold: Integer;
  Left: Integer;
  I: TColorRef;

 DrawBitmap: TBitmap;
begin
  I := ColorToRGB(ACanvas.Brush.Color);
  if (TextEllipsis = teNone) and (GetNearestColor(ACanvas.Handle, I) = I) then
  begin
    if (ACanvas.CanvasOrientation = coRightToLeft) and
       (not ARightToLeft) then
      ChangeBiDiModeAlignment(Alignment);

    if (ACanvas.CanvasOrientation = coRightToLeft) and
       (not ARightToLeft) then
      ChangeBiDiModeAlignment(Alignment);

    ACanvas.Brush.Style := bsClear;
    if (ACanvas.CanvasOrientation = coRightToLeft) and
       ARightToLeft then
    begin
      case Alignment of
        taLeftJustify:
          Left := ARect.Left + DX;
        taRightJustify:
          Left := ARect.Right - ACanvas.TextWidth(Text) - 3;
      else
        Left := ARect.Left + (ARect.Right - ARect.Left) shr 1
          - (ACanvas.TextWidth(Text) shr 1);
      end;
      ACanvas.TextRect(ARect, Left, ARect.Top + DY, Text)
    end
    else
    begin
      Inc(ARect.Left, DX);
      Dec(ARect.Right, DX);
      Inc(ARect.Top, DY);
      Dec(ARect.Bottom, DY);

      Flags := EllipsisFlags[TextEllipsis] or
               AlignFlags[Alignment] or VAlignFlags[VAlignment] or
               WordBreaks[IsWordBreak]
               or RTL[ARightToLeft];

      if (VAlignment = gvaBottom) then
      begin
        Flags := Flags or DT_CALCRECT;

        intTextHeight := DrawText(ACanvas.Handle, PChar(Text), Length(Text), ARect, Flags);
        ARect.Top := ARect.Bottom - intTextHeight;
        if (ARect.Top < 0) then
          ARect.Top := 0;
      end;

      DrawText(ACanvas.Handle, PChar(Text), Length(Text), ARect, Flags);
    end
  end
  else
  begin
    DrawBitmap := TBitmap.Create;
    try
      with DrawBitmap, ARect do { Use offscreen bitmap to eliminate flicker and }
      begin                     { brush origin tics in painting / scrolling.    }
        Width := Max(Width, Right - Left);
        Height := Max(Height, Bottom - Top);
        R := Rect(DX, DY, Right - Left - 1, Bottom - Top - 1);
        B := Rect(0, 0, Right - Left, Bottom - Top);
      end;
      with DrawBitmap.Canvas do
      begin
        Font := ACanvas.Font;
        Font.Color := ACanvas.Font.Color;
        Brush := ACanvas.Brush;
        Brush.Style := bsSolid;
        FillRect(B);
        SetBkMode(Handle, TRANSPARENT);

        if (ACanvas.CanvasOrientation = coRightToLeft) then
          ChangeBiDiModeAlignment(Alignment);


      Flags := EllipsisFlags[TextEllipsis] or AlignFlags[Alignment]   or RTL[ARightToLeft] ;
      if (VAlignment = gvaBottom) then
      begin
        Flags := Flags or DT_CALCRECT;

        intTextHeight := DrawText(Handle, PChar(Text), Length(Text), R, Flags);
        R.Top := R.Bottom - intTextHeight;
        if (R.Top < 0) then
          R.Top := 0;
      end;

        DrawText(Handle, PChar(Text), Length(Text), R, Flags);
      end;
      if (ACanvas.CanvasOrientation = coRightToLeft) then
      begin
        Hold := ARect.Left;
        ARect.Left := ARect.Right;
        ARect.Right := Hold;
      end;
      ACanvas.CopyRect(ARect, DrawBitmap.Canvas, B);
    finally
//      DrawBitmap.Canvas.Unlock;
      DrawBitmap.Free;
    end;
  end;
end;

{ TPlusDBColumn }
function GetColumnEllipsis(col: TColumn): TPlusTextEllipsis;
begin
  if (col is TPlusDBColumn) then
    Result := TPlusDBColumn(col).TextEllipsis
  else
    Result := teNone
end;

constructor TPlusDBColumn.Create(Collection: TCollection);
begin
  inherited Create(Collection);

  FColunaAjuste         := CreateColunaAjuste;
  FCheckBox             := CreateCheckBox;

  FSortCaption          := '';
  FSortType             := stNone;
  FInplaceEditor        := ieNormal;
  FFooterType           := ftCustom;
  FFooterText           := LowerCase(_FOOTER_TROCA_STRING);

  FTag                  := 0;
  FBandIndex            := -1;
  FTextEllipsis         := teNone;
  FVerticalAlignment    := gvaTop;

  FDisplayFormat        := '';

end;

function TPlusDBColumn.CreateCheckBox: TGridPlusColumnCheckBox;
begin
  Result:= TGridPlusColumnCheckBox.Create(Self);
end;

function TPlusDBColumn.CreateColunaAjuste: TColunaAjuste;
begin
  Result:= TColunaAjuste.Create(Self);
end;

destructor TPlusDBColumn.Destroy;
begin
  if Assigned(FCheckBox) then begin
    FCheckBox.Free;
    FCheckBox := nil;
  end;

  if Assigned(FColunaAjuste) then begin
    FColunaAjuste.Free;
    FColunaAjuste := nil;
  end;

  inherited;
end;

procedure TPlusDBColumn.Assign(Source: TPersistent);
var
  colSource: TPlusDBColumn;
begin
  inherited Assign(Source);

  if Source is TPlusDBColumn then
  begin
    colSource := TPlusDBColumn(Source);
    if Assigned(Collection) then
      Collection.BeginUpdate;
    try

      DisplayFormat    := colSource.DisplayFormat;
      CheckBox         := colSource.CheckBox;
      ColunaAjuste     := colSource.ColunaAjuste;

      SortCaption      := colSource.SortCaption;
      SortType         := colSource.SortType;
      FInplaceEditor   := colSource.InplaceEditor;
      Tag              := colSource.Tag;
      BandIndex        := colSource.BandIndex;
      TextEllipsis     := colSource.TextEllipsis;

      FooterText       := colSource.FooterText;
      FooterType       := colSource.FooterType;
      FooterValue      := colSource.FooterValue;
      FooterValue.Type := colSource.FooterValue.Type;

    finally
      if Assigned(Collection) then
        Collection.EndUpdate;
    end;
  end;
end;

procedure TPlusDBColumn.RestoreDefaults;
begin
  inherited RestoreDefaults;
end;

procedure TPlusDBColumn.DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean);
begin
  //
end;

procedure TPlusDBColumn.SetSortCaption(Value: TPlusString);
begin
  if FSortCaption <> Value then
  begin
    FSortCaption := Value;
    Changed(False);
    GridInvalidateRow(Grid, 0);
  end;
end;

procedure TPlusDBColumn.SetInplaceEditor(Value: TPlusInplaceEditorType);
begin
  if FInplaceEditor <> Value then
  begin
    FInplaceEditor := Value;
    Changed(False)
  end;
end;

procedure TPlusDBColumn.SetDisplayFormat(const Value: String);
begin
  FDisplayFormat := Value;
  Changed(False);
  Grid.ConfigurarMascara();
end;

procedure TPlusDBColumn.SetSortType(Value: TPlusSortType);
begin
  if FSortType <> Value then
  begin
    FSortType := Value;
    Changed(False);

    if Assigned(Grid) and Assigned(Grid.OnSortChanged) then
      Grid.OnSortChanged(Grid, Self);

    GridInvalidateRow(Grid, 0);
  end;
end;

procedure TPlusDBColumn.SetFooterValue(Value: Variant);
begin
  begin
    FFooterValue := Value;
    Changed(False);
    Grid.DoUpdateFooter;
  end;
end;

procedure TPlusDBColumn.SetFooterType(Value: TPlusFooterType);
begin
  if (FFooterType <> Value) then
  begin
    FFooterType := Value;
    Changed(False);
    Grid.DoUpdateFooter;
  end;
end;

function TPlusDBColumn.GetGrid: TDBGridPlus;
begin
  if Assigned(Collection) and (Collection is TDBGridPlusColumns) then
    Result := TDBGridPlus(inherited Grid)
  else
    Result := nil;
end;

procedure TPlusDBColumn.SetFooterText(const Value: String);
begin
  if FFooterText <> Value then
  begin
    FFooterText := Value;
    Changed(False);

    Grid.DoUpdateFooter;
  end;
end;

{ TPlusDBProgressColumn }
constructor TPlusDBProgressColumn.Create(Collection: TCollection);
begin
  inherited;

  FInplaceEditor := ieProgressbar
end;

procedure TPlusDBProgressColumn.DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean);
var
  bmp: TBitmap;

  intValue, iSize: Longint;
begin
  inherited;

  if VarIsNull(Value) or VarIsEmpty(Value) then
    intValue := 0
  else
    intValue := Value;

  with ACanvas do
  begin
    bmp := TBitmap.Create;
    try
      bmp.Height := ARect.Bottom-ARect.Top;
      bmp.Width := ARect.Right-ARect.Left;
      bmp.Canvas.Brush.Color := Background;
      bmp.Canvas.FillRect(bmp.Canvas.ClipRect);

      if Max-Min = 0 then
        iSize := 0
      else
        iSize := LongInt(Trunc(bmp.Width * ((intValue-Min)*100/Max-Min)*0.01));
      if iSize > bmp.Width then
        iSize := bmp.Width;
      if iSize > 0 then
      begin
        bmp.Canvas.Brush.Color := Self.Color;
        bmp.Canvas.FillRect(Rect(0, 0, iSize, bmp.Height));
      end;

      Draw(ARect.Left, ARect.Top, bmp);
      Done := True
    finally
      bmp.Free;
    end;
  end;
end;


{ TPlusDBCheckboxColumn }
constructor TPlusDBCheckboxColumn.Create(Collection: TCollection);
begin
  inherited;
  FInplaceEditor := ieCheckbox
end;

procedure TPlusDBCheckboxColumn.SetValueChecked(const AValue: TPlusString);
begin
  if (FValueChecked <> AValue) then
  begin
    FValueChecked := AValue;
    Changed(False)
  end
end;

procedure TPlusDBCheckboxColumn.SetValueUnChecked(const AValue: TPlusString);
begin
  if (FValueUnChecked <> AValue) then
  begin
    FValueUnChecked := AValue;
    Changed(False)
  end
end;

procedure TPlusDBCheckboxColumn.DrawItem(ACanvas: TCanvas; ARect: TRect; Value: Variant; Background: TColor; AState: TGridDrawState; var Done: Boolean);
var
  CheckState: TCheckBoxState;
begin
  inherited;

  ACanvas.FillRect(ARect);
  InflateRect(ARect, -2, -2);

  CheckState := grid.GetCheckBoxValue(Field, Value, ValueChecked);
  Grid.DrawCheckBox(ARect, CheckState, taCenter);
  InflateRect(ARect, 2, 2);
  Done := True
end;

{ TDBGridPlusColumns }
function TDBGridPlusColumns.Add: TPlusDBColumn;
begin
  Result := TPlusDBColumn(inherited Add);
end;

function TDBGridPlusColumns.GetColumn(Index: Integer): TPlusDBColumn;
begin
  Result := TPlusDBColumn(inherited Items[Index]);
end;

procedure TDBGridPlusColumns.SetColumn(Index: Integer; Value: TPlusDBColumn);
begin
  Items[Index].Assign(Value);
end;

{ TSMGradientDraw }
constructor TPlusGradientDraw.Create(AGrid: TDBGridPlus);
begin
  inherited Create;

  FDirection := fdNone;
  FStartColor := clWhite;
  FEndColor := $00DDDDDD;
  FGrid := AGrid;
end;

procedure TPlusGradientDraw.SetStartColor(AValue: TColor);
begin
  if (FStartColor <> AValue) then
  begin
    FStartColor := AValue;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

procedure TPlusGradientDraw.SetEndColor(AValue: TColor);
begin
  if (FEndColor <> AValue) then
  begin
    FEndColor := AValue;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

procedure TPlusGradientDraw.SetDirection(Value: TPlusGradientDirection);
begin
  if (FDirection <> Value) then
  begin
    FDirection := Value;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

{ TDBGridPlusStyle }
constructor TDBGridPlusStyle.Create(AGrid: TDBGridPlus);
begin
  inherited Create;

  FBackground := TBitmap.Create;
  FBandGradientDraw := TPlusGradientDraw.Create(AGrid);
  FTitle := TPlusGradientDraw.Create(AGrid);
  FFooter := TPlusGradientDraw.Create(AGrid);
  FWallpaper := TPlusGradientDraw.Create(AGrid);
  FGrouping := TPlusGradientDraw.Create(AGrid);
  FSelection := TPlusGradientDraw.Create(AGrid);

  FGrid := AGrid;
  FStyleColorGrid := gsNormal;
end;

destructor TDBGridPlusStyle.Destroy;
begin
  FBackground.Free;

  FBandGradientDraw.Free;
  FTitle.Free;
  FFooter.Free;
  FWallpaper.Free;
  FGrouping.Free;
  FSelection.Free;

  inherited Destroy;
end;

function TDBGridPlusStyle.IsDefaultBackground: Boolean;
begin
  Result := Assigned(Background) and Background.Empty and
           (Wallpaper.Direction = fdNone)
end;

function TDBGridPlusStyle.GetGradient(Index: Integer): TPlusGradientDraw;
begin
  case Index of
    0: Result := FBandGradientDraw;
    1: Result := FTitle;
    2: Result := FFooter;
    3: Result := FWallpaper;
    4: Result := FGrouping;
    5: Result := FSelection;
  else
    Result := nil
  end;
end;

procedure TDBGridPlusStyle.SetGradient(Index: Integer; Value: TPlusGradientDraw);
begin
  case Index of
    0: FBandGradientDraw.Assign(Value);
    1: FTitle.Assign(Value);
    2: FFooter.Assign(Value);
    3: FWallpaper.Assign(Value);
    4: FGrouping.Assign(Value);
    5: FSelection.Assign(Value);
  else
  end;
  if (FGrid <> nil) then
    FGrid.Invalidate;
end;

procedure TDBGridPlusStyle.SetOddColor(AValue: TColor);
begin
  if (FOddColor <> AValue) then
  begin
    FOddColor := AValue;
    if (FOddColor = FGrid.Color) and (FEvenColor = FGrid.Color) then
      FStyleColorGrid := gsNormal
    else
      FStyleColorGrid := gsCustom;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

procedure TDBGridPlusStyle.SetEvenColor(AValue: TColor);
begin
  if (FEvenColor <> AValue) then
  begin
    FEvenColor := AValue;
    if (FOddColor = FGrid.Color) and (FEvenColor = FGrid.Color) then
      FStyleColorGrid := gsNormal
    else
      FStyleColorGrid := gsCustom;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

procedure TDBGridPlusStyle.SetBackground(Value: TBitmap);
begin
  FBackground.Assign(Value);

  if (FGrid <> nil) then
    FGrid.Invalidate;
end;

procedure TDBGridPlusStyle.SetStyleColorGrid(Value: TStyleColorGrid);
begin
  if FStyleColorGrid <> Value then
  begin
    FStyleColorGrid := Value;

    case FStyleColorGrid of
      gsNormal: begin
                  FOddColor := FGrid.Color;
                  FEvenColor := FGrid.Color;
                end;
      gsPriceList: begin
                     FOddColor := cl3DLight;
                     FEvenColor := clWindow;
                   end;
      gsMSMoney: begin
                   FOddColor := clSkyBlue;
                   FEvenColor := clWindow;
                 end;
      gsBrick: begin
                 FOddColor := TColor($CFDFDF);
                 FEvenColor := TColor($A0BFBF);
               end;
      gsDesert: begin
                  FOddColor := TColor($B8CCD8);
                  FEvenColor := TColor($688CA0);
                end;
      gsEggplant: begin
                    FOddColor := TColor($A8B090);
                    FEvenColor := TColor($788058);
                  end;
      gsLilac: begin
                 FOddColor := TColor($D8A8B0);
                 FEvenColor := TColor($B05058);
               end;
      gsMaple: begin
                 FOddColor := TColor($A8D8EB);
                 FEvenColor := TColor($48A8C8);
               end;
      gsMarine: begin
                  FOddColor := TColor($B8C088);
                  FEvenColor := TColor($889048);
                end;
      gsRose: begin
                FOddColor := TColor($B8B0D0);
                FEvenColor := TColor($7060A0);
              end;
      gsSpruce: begin
                  FOddColor := TColor($A8C8A0);
                  FEvenColor := TColor($689858);
                end;
      gsWheat: begin
                 FOddColor := TColor($A0E0E0);
                 FEvenColor := TColor($40BCC0);
               end;

      gsSoftWheat: begin
                     FOddColor := TColor($00ACE3E3);
                     FEvenColor := TColor($00C5EAEB);
                   end;

      gsSoftRose: begin
                    FOddColor := TColor($00DCD7EA);
                    FEvenColor := TColor($00E3E0ED);
                  end;

      gsAquaBlue: begin
                    FOddColor := TColor($00FFF4D9);
                    FEvenColor := TColor($00FFDFBF);
                  end;

      gsSoftMaple: begin
                     FOddColor := TColor($00C6E6F2);
                     FEvenColor := TColor($009BD0E1);
                   end;

      gsSoftLilac: begin
                     FOddColor := TColor($00E7CBD0);
                     FEvenColor := TColor($00ECD5D7);
                   end;

      gsSoftDesert: begin
                      FOddColor := TColor($00DFE9EE);
                      FEvenColor := TColor($00BCCDD6);
                    end;

      gsSoftEggPlant: begin
                        FOddColor := TColor($00D7DACB);
                        FEvenColor := TColor($00C2C7AD);
                      end;

      gsSoftBrick: begin
                     FOddColor := TColor($00DFEEEE);
                     FEvenColor := TColor($00CDE4E4);
                   end;

      gsSoftSpruce: begin
                      FOddColor := TColor($00D3E3CE);
                      FEvenColor := TColor($00BAD1B1);
                    end;

      gsSoftYellowGreen: begin
                           FOddColor := TColor($00E6FFFF);
                           FEvenColor := TColor($00DCE9D8);
                         end;

      gsSoftGray: begin
                    FOddColor := TColor($00E4E4E4);
                    FEvenColor := TColor($00F5F5F5);
                  end;

    end;
    if (FGrid <> nil) then
      FGrid.Invalidate;
  end;
end;

{ TPlusDBGTitleHeight }
constructor TPlusDBGTitleHeight.Create(AGrid: TDBGridPlus);
begin
  inherited Create;

  FGrid := AGrid;
end;

procedure TPlusDBGTitleHeight.Assign(Source: TPersistent);
var
  th: TPlusDBGTitleHeight;
begin
  inherited Assign(Source);

  if (Source is TPlusDBGTitleHeight) then
  begin
    th := TPlusDBGTitleHeight(Source);

    Kind := th.Kind;
    LineCount := th.LineCount;
    PixelCount := th.PixelCount;
  end;
end;

procedure TPlusDBGTitleHeight.SetKind(Value: TPlusDBGTitleHeightKind);
begin
  if (FKind <> Value) then
  begin
    FKind := Value;
    FGrid.SetTitlesHeight
  end;
end;

procedure TPlusDBGTitleHeight.SetLineCount(Value: Integer);
begin
  if (FLineCount <> Value) then
  begin
    FLineCount := Value;
    FGrid.SetTitlesHeight
  end;
end;

procedure TPlusDBGTitleHeight.SetPixelCount(Value: Integer);
begin
  if (FPixelCount <> Value) then
  begin
    FPixelCount := Value;
    FGrid.SetTitlesHeight
  end;
end;

{ TDBGridPlus }
constructor TDBGridPlus.Create(AOwner: TComponent);
var
  NewItem: TMenuItem;
  j, h
  : Integer;
  Bmp: TBitmap;
begin
  inherited Create(AOwner);

  if not Assigned(FFooterFont) then
    FFooterFont := TFont.Create;

  FFooterFont.Name   := 'Consolas';
  FFooterFont.Size   := 9;
  FFooterFont.Color  := clBlack;

  DefaultRowHeight := GetCalculatedDefaultRowHeight;

  FBands := TStringList.Create;
  FBandsFont := TFont.Create;
  FBandsFont.Assign(TitleFont);

  FAutoFitIsLocked := True;

  FGridStyle := TDBGridPlusStyle.Create(Self);
  FGridStyle.OddColor := Color;
  FGridStyle.EvenColor := Color;

  FTitleHeight := TPlusDBGTitleHeight.Create(Self);
  FTitleHeight.Kind := hkAuto;
  FTitleHeight.LineCount := 1;
  FTitleHeight.PixelCount := DefaultRowHeight;
  FFooterColor  := clBtnFace;

  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromResourceName(HInstance, bmArrow);
    FMsIndicators := TImageList.CreateSize(Bmp.Width, Bmp.Height);
    FMsIndicators.AddMasked(Bmp, clWhite);
    Bmp.LoadFromResourceName(HInstance, bmEdit);
    FMsIndicators.AddMasked(Bmp, clWhite);
    Bmp.LoadFromResourceName(HInstance, bmInsert);
    FMsIndicators.AddMasked(Bmp, clWhite);
    Bmp.LoadFromResourceName(HInstance, bmMultiDot);
    FMsIndicators.AddMasked(Bmp, clWhite);
    Bmp.LoadFromResourceName(HInstance, bmMultiArrow);
    FMsIndicators.AddMasked(Bmp, clWhite);

  finally
    Bmp.Free;
  end;
  FScrollHintWnd := THintWindow.Create(Self);
  FScrollHintWnd.Color := clInfoBk;
  FPressedCol := -1;

  GetCheckBoxSize;
  FWidthOfIndicator := IndicatorWidth;

  FOptionsEx := [eoEnterToTab,
                 eoShowGlyphs,
                 eoKeepSelection,
                 eoTitleWordWrap];

  HScrollbar := True;
  VScrollbar := True;
  ScrollBars := ssBoth;

end;

procedure TDBGridPlus.Loaded;
begin
  inherited Loaded;

  if (eoAutoLoadLayout in OptionsEx) then
  begin
    LoadGridFromIni(Self, GetLocalFile(Self) );
  end;

  FAutoFitIsLocked := False;
  if (eoAutoWidth in OptionsEx) then
    UpdateColWidths;

   if FIsFlagAlwaysShowEditor then
   begin
     FIsFlagAlwaysShowEditor := False;
     Options := Options + [dgAlwaysShowEditor];
   end;
end;

destructor TDBGridPlus.Destroy;
begin
  FreeStartOfSelect;

  if Assigned(FScrollHintWnd) then
    FScrollHintWnd.Free;

  if Assigned(FMsIndicators) then
    FMsIndicators.Free;

  if Assigned(FGridStyle) then
    FGridStyle.Free;

  if Assigned(FTitleHeight) then
    FTitleHeight.Free;

  if Assigned(FBands) then
    FBands.Free;

  if Assigned(FBandsFont) then
    FBandsFont.Free;

  if Assigned(FFooterFont) then
    FFooterFont.Free;

  inherited Destroy;
end;

procedure TDBGridPlus.SetOnChangeSelection(Value: TNotifyEvent);
begin
  FOnSelectionChange := Value;
end;

procedure TDBGridPlus.SetBands(Value: TStrings);
begin
  FBands.Assign(Value);

  if not (csLoading in ComponentState) then
    Invalidate
end;

procedure TDBGridPlus.SetBandsFont(Value: TFont);
begin
  FBandsFont.Assign(Value);
  if not (csLoading in ComponentState) then
    Invalidate
end;

procedure TDBGridPlus.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) then
  begin
    if Assigned(DataLink) and
       (AComponent = DataLink.DataSet) then
      FreeStartOfSelect
  end;

  inherited Notification(AComponent, Operation);
end;

procedure TDBGridPlus.FreeStartOfSelect;
begin
  if Assigned(StartOfSelect) and
     Assigned(DataLink.DataSet) then
  begin
    DataLink.DataSet.FreeBookmark(StartOfSelect);
    StartOfSelect := nil;
  end;
end;

procedure TDBGridPlus.SetGridStyle(Value: TDBGridPlusStyle);
begin
  FGridStyle.Assign(Value);
end;

procedure TDBGridPlus.SetTitleHeight(Value: TPlusDBGTitleHeight);
begin
  FTitleHeight.Assign(Value);
end;

procedure TDBGridPlus.SetFooterColor(Value: TColor);
begin
  if (FFooterColor <> Value) then
  begin
    FFooterColor := Value;
    LayoutChanged;
  end;
end;

procedure TDBGridPlus.SetFooterFont(const Value: TFont);
begin
  FFooterFont.Assign(Value);
  if not (csLoading in ComponentState) then
    Invalidate
end;

procedure TDBGridPlus.SetFlat(Value: Boolean);
begin
  if (FFlat <> Value) then
  begin
    FFlat := Value;
    RecreateWnd;
  end;
end;

procedure TDBGridPlus.SetFooterHeight(Value: Integer);
begin
  if (FFooterHeight <> Value) then
  begin
    if Value < 0 then
      Value := 0;
    FFooterHeight := Value;
    LayoutChanged;
  end;
end;

function TDBGridPlus.CreateColumns: TDBGridColumns;
begin
  Result := TDBGridPlusColumns.Create(Self, TPlusDBColumn);
end;

function TDBGridPlus.CreateEditor: TInplaceEdit;
begin
  Result := inherited CreateEditor;

  with TEdit(Result) do
  begin
    Color := Self.Color;
    OnChange := EditChanged;
  end;
end;

procedure TDBGridPlus.EditChanged(Sender: TObject);
begin
  if Assigned(FOnEditChange) then
    FOnEditChange(Self);
end;
procedure TDBGridPlus.TitleClick(Column: TColumn);
begin
  inherited;

  if DataLink.Active and not Assigned(OnTitleClick) then
    SortGrid(Column);

  if (eoAutoSaveLayout in OptionsEx) then
  begin
    SaveGridToIni(Self, GetLocalFile(Self) );
  end;
end;

procedure TDBGridPlus.CalculateTotals(OnlySelected: Boolean = False);
var
  ABookmark: TBookmark;
  i: Integer;
  ExistInfoForUpdate: Boolean;

  procedure CalcRowTotal;
  var
    i:integer;
  begin
    with Datalink.Dataset do
    begin
      for i := 0 to Columns.Count - 1 do
      begin
        if (Columns[i] is TPlusDBColumn) and
          Assigned(Columns[i].Field) then
        begin
          with TPlusDBColumn(Columns[i]) do
          begin
            case FooterType of
              ftSum,
              ftAverage: begin
                           if (Field is TNumericField) then
                             FFooterValue := FFooterValue + TNumericField(Field).AsFloat;
                           Inc(intInternalCount);
                         end;
              ftCount: FFooterValue := FFooterValue + 1;
              ftMin: if FFooterValue > Field.Value then
                       FFooterValue := Field.Value;
              ftMax: if FFooterValue < Field.Value then
                       FFooterValue := Field.Value;
            end;
          end;
        end;
      end;
    end;
  end;

begin
  if not (eoShowFooter in OptionsEx) then
    Exit;

  with Datalink.Dataset do
  begin

    ExistInfoForUpdate := False;
    for i := 0 to Columns.Count-1 do
    begin
      if (Columns[i] is TPlusDBColumn) then
      begin
        with TPlusDBColumn(Columns[i]) do
        begin
          case FooterType of
            ftSum,
            ftCount,
            ftAverage,
            ftMin,
            ftMax: begin
                     FFooterValue := 0;
                     intInternalCount := 0;
                     ExistInfoForUpdate := True;
                   end;
          end
        end
      end
    end;

    if (BOF and EOF) or not ExistInfoForUpdate then
    else
    begin
      DisableControls;
      try
        ABookmark := GetBookmark;
        try
          First;
          if OnlySelected then
          begin
            for i:= 0 to SelectedRows.Count-1 do
            begin
              GotoBookmark(TBookmark(SelectedRows[i]));
              CalcRowTotal;
            end;
          end
          else
          begin
            while not EOF do
            begin
              CalcRowTotal;
              Next;
            end
          end;
        finally
          try
            GotoBookmark(ABookmark);
          except
          end;
          FreeBookmark(ABookmark);
        end;

        {update an avg value}
        for i := 0 to Columns.Count-1 do
        begin
          if (Columns[i] is TPlusDBColumn) then
          begin
            with TPlusDBColumn(Columns[i]) do
            begin
              case FooterType of
                ftAverage: begin
                             if (intInternalCount > 0) then
                               FFooterValue := FFooterValue / intInternalCount;
                           end;
              end
            end
          end
        end
      finally
        EnableControls;
      end;
    end
  end;
  InvalidateFooter
end;

procedure TDBGridPlus.InvalidateFooter;
var
  FooterRect: TRect;
begin
  if not Showing then
    Exit;

  FooterRect := GetFooterRect;
  DrawFooterRow;
end;

procedure TDBGridPlus.InvalideTab;
begin
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOACTIVATE or
               SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER);
end;

function TDBGridPlus.GetClientRect: TRect;
begin
  Result := inherited GetClientRect;

  if (eoShowFooter in OptionsEx) then
  begin
    if (FooterHeight = 0) then
      Result.Bottom := Result.Bottom - (DefaultRowHeight+4)
    else
      Result.Bottom := Result.Bottom - FooterHeight;
  end
end;

function TDBGridPlus.GetFooterRect: TRect;
var
  FooterRect: TRect;
begin
  FooterRect.Left := 0;
  FooterRect.Right := ClientWidth;
  FooterRect.Top := ClientRect.Bottom;
  if (FooterHeight = 0) then
    FooterRect.Bottom := FooterRect.Top + DefaultRowHeight + 3
  else
    FooterRect.Bottom := FooterRect.Top + FooterHeight - 1;
  Result := FooterRect;
end;

procedure TDBGridPlus.DoUpdateFooter;
begin
  if Assigned(FOnUpdateFooter) then
    FOnUpdateFooter(Self);
  InvalidateFooter;
end;

function TDBGridPlus.GetCalculatedDefaultRowHeight: Integer;
var
  K: Integer;
  RestoreCanvas: Boolean;
begin
  RestoreCanvas := not HandleAllocated;
  if RestoreCanvas then
    Canvas.Handle := GetDC(0);
  try
    Canvas.Font := Font;
    K := Canvas.TextHeight('Wg') + 3;
    if dgRowLines in Options then
      Inc(K, GridLineWidth);
    Result := K;
  finally
    if RestoreCanvas then
    begin
      ReleaseDC(0,Canvas.Handle);
      Canvas.Handle := 0;
    end;
  end;
end;

function TDBGridPlus.GetDefaultRowHeight: Integer;
begin
  Result := inherited DefaultRowHeight;
end;

procedure TDBGridPlus.SetDefaultRowHeight(Value: Integer);
var
  i: Integer;
begin
  if (Value = inherited DefaultRowHeight) then
    exit;

  i := Value;
  if (RowCount > 0) then
    i := RowHeights[0];
  if Value = 0 then
    Value := inherited DefaultRowHeight;

  if (DataSource <> nil) and (DataSource.DataSet <> nil) and DataSource.DataSet.Active then
    inherited DefaultRowHeight := Value;

  if (RowCount > 0) then
  begin
    if HandleAllocated and (dgTitles in Options) then
    begin
      try
        RowHeights[0] := i;
      except
      end
    end
  end
end;

procedure TDBGridPlus.SetRowHeight;
const
  WordBreaks: array [Boolean] of Integer = (0, DT_WORDBREAK);
var
  i, j, MaxHeight: Integer;
  RRect: TRect;
  oldActiveRecord: Integer;
  s: TPlusString;
begin
  if not (csDestroying in ComponentState) and
     Assigned(Parent) and
     (eoRowHeightAutofit in OptionsEx) then
  begin
    if not (dgRowLines in Options) and (eoTitleLines in OptionsEx) then
      RowHeights[0] := RowHeights[0] + GridLineWidth;

    if not DataLink.Active then exit;

    {save current position}
    oldActiveRecord := DataLink.ActiveRecord;
    if dgTitles in Options then
      DataLink.ActiveRecord:= TopRow-1
    else
      DataLink.ActiveRecord:= TopRow;
    j := 1;
    while not DataLink.DataSet.Eof and
          (DataLink.ActiveRecord < TopRow+VisibleRowCount) and
          (j < RowCount) do
    begin
      MaxHeight := 0;
      for i := 0 to Columns.Count-1 do
      begin
        if Columns[i].Visible and Assigned(Columns[i].Field) then
        begin
          RRect := CellRect(0, 0);
          RRect.Right := Columns[i].Width - 1;
          RRect.Left := 0;
          RRect := CellRectForDraw(RRect, i);

          Canvas.Font := Columns[i].Font;
          s := Columns[i].Field.AsString;
          MaxHeight := Max(MaxHeight,
                           DrawText(Canvas.Handle,
                                    PChar(s),
                                    Length(s),
                                    RRect,
                                    DT_EXPANDTABS or DT_CALCRECT or WordBreaks[eoCellWordWrap{eoTitleWordWrap} in OptionsEx]));
        end;
      end;

      if (MaxHeight <> 0) then
      begin
        if (dgRowLines in Options) then
          Inc(MaxHeight, 3)
        else
          Inc(MaxHeight, 2);

        RowHeights[j] := MaxHeight + 2
      end;
      DataLink.ActiveRecord := DataLink.ActiveRecord+1;
      Inc(j);
    end;
    DataLink.ActiveRecord := oldActiveRecord
  end;
end;

procedure TDBGridPlus.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  with Params do
  begin
    Style := Style or WS_TABSTOP;
  end;
end;

procedure TDBGridPlus.CreateWnd;
begin
  inherited;
end;

function TDBGridPlus.GetScrollBars: TScrollStyle;
begin
  Result := inherited ScrollBars
end;

procedure TDBGridPlus.SetScrollBars(Value: TScrollStyle);
begin
  HScrollbar := (Value in [ssBoth, ssHorizontal]);
  VScrollbar := (Value in [ssBoth, ssVertical]);

  inherited ScrollBars := Value;

  RecreateWnd;
end;

procedure TDBGridPlus.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  Style: Integer;
begin
  if eoAutoWidth in OptionsEx then
  begin
    Style := GetWindowLong(Handle, GWL_STYLE) and not WS_HSCROLL;
    SetWindowLong(Handle, GWL_STYLE, Style);
  end;

  inherited;
end;

procedure TDBGridPlus.WMSize(var Message: TWMSize);
begin
  inherited;
  if not (csLoading in ComponentState) then
  begin
    Invalidate;
    InvalidateFooter;
  end;
end;

procedure TDBGridPlus.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  inherited;
  InvalidateFooter
end;

procedure TDBGridPlus.WMNCPaint(var Message: TMessage);
begin
  inherited;
  DrawFooterRow;
end;

procedure TDBGridPlus.ApplyStyleColors(ACanvas: TCanvas);
begin
  if TStyleManager.IsCustomStyleActive then
  begin
    if  (seClient in StyleElements)  then
      ACanvas.Brush.Color := StyleServices.GetStyleColor(scGrid)
    else
      ACanvas.Brush.Color := Color;
    if (seFont in StyleElements)  then
      ACanvas.Font.Color := StyleServices.GetStyleFontColor(sfGridItemNormal)
    else
      ACanvas.Font.Color := Font.Color
  end
end;

procedure TDBGridPlus.DrawFooterRow;
var
  DrawBitmap: TBitmap;
  FooterRect, TempRect, FooterCellRect, LastFooterCellRect: TRect;
  ACol: Integer;
  ACanvas: TCanvas;

  function GetFooterCellRect(Col: Integer): TRect;
  var
    FooterCellRect: TRect;
  begin
    FooterCellRect := CellRect(ACol, RowCount-1);
    if (FooterCellRect.Left <> FooterCellRect.Right) then
    begin
      FooterCellRect.Top := FooterRect.Top;
      FooterCellRect.Bottom := FooterRect.Bottom;
    end;
    Result := FooterCellRect;
  end;


  procedure DrawFooterLines(Rect: TRect; Col, Row: Integer);
  begin
    with ACanvas do
    begin
      Pen.Color := clBtnShadow;
      MoveTo(Rect.Left + 1, Rect.Bottom - 2);
      LineTo(Rect.Left + 1, Rect.Top + 1);
      LineTo(Rect.Right - 1, Rect.Top + 1);

      Pen.Color := clBtnHighlight;
      MoveTo(Rect.Left + 2, Rect.Bottom - 2);
      LineTo(Rect.Right - 1, Rect.Bottom - 2);
      LineTo(Rect.Right - 1, Rect.Top + 1);
    end
  end;

  procedure ProcessFooterCell(ACol: Integer);
  var
    strFooter: TPlusString;
    i: Integer;
    BCol: Integer;
    DefaultDrawing: Boolean;
    al: TAlignment;
  begin
    if dgIndicator in Options then
      BCol := ACol - 1
    else
      BCol := ACol;

    FooterCellRect := CellRect(ACol, RowCount-1);
    if (BCol >-1) and
       (FooterCellRect.Left <> FooterCellRect.Right) then
    begin
      if (Columns[BCol] is TPlusDBColumn) then
        with TPlusDBColumn(Columns[BCol]) do
        begin
          if (Field is TNumericField) and (Columns[BCol].DisplayFormat <> '') and
             (VarType(FooterValue) in [varSmallInt, varInteger, varSingle, varDouble, varCurrency, varByte]) then
            strFooter := FormatFloat(Columns[BCol].DisplayFormat, FooterValue)
          else
          if (Field is TDateTimeField) and (Columns[BCol].DisplayFormat <> '') and
              (VarType(FooterValue) in [varDate]) then
            DateTimeToString(strFooter, Columns[BCol].DisplayFormat, FooterValue)
          else
            strFooter := VarToStr(FooterValue);

          if Trim(FFooterText) <> '' then
          begin
            strFooter := StringReplace(FFooterText, LowerCase(_FOOTER_TROCA_STRING), strFooter, [rfReplaceAll]);
          end;

          al := Alignment
        end
      else
      begin
        strFooter := '';
        al := taLeftJustify
      end;

      DefaultDrawing := True;
      ACanvas.Brush.Color := FFooterColor;
      ACanvas.Font.Assign(Font);

      FooterCellRect := GetFooterCellRect(ACol);
      InflateRect(FooterCellRect, 0, -2);

      if Assigned(FOnDrawFooterCell) then
      begin
        FOnDrawFooterCell(Self, ACanvas, FooterCellRect,
                          Columns[BCol].Field, strFooter, DefaultDrawing);
      end;

      if not DefaultDrawing or (strFooter = '') then
        Exit;

      ApplyStyleColors(ACanvas);

      // Fill with brush color for cell
      if (GridStyle.Footer.Direction = fdNone) then
        ACanvas.FillRect(FooterCellRect)
      else
        PlusDrawGradient(ACanvas, FooterCellRect, GridStyle.Footer.StartColor, GridStyle.Footer.EndColor, GridStyle.Footer.Direction, 255);

      FooterCellRect.Top := FooterRect.Top + 1;
      FooterCellRect.Bottom := FooterRect.Bottom - 1;
      FooterCellRect.Left := FooterCellRect.Left - 1;
      DrawFooterLines(FooterCellRect, ACol, RowCount);

      FooterCellRect.Top := FooterCellRect.Top + 2;
      FooterCellRect.Bottom := FooterRect.Bottom - 4;
      FooterCellRect.Left := FooterCellRect.Left + 2;
      FooterCellRect.Right := FooterCellRect.Left + ColWidths[ACol] - 4;

      if Assigned(FFooterFont) then
        ACanvas.Font.Assign(FFooterFont); // aqui ?

      WriteTitleText(ACanvas,
                     FooterCellRect,
                     0,
                     0,
                     strFooter,
                     al,
                     gvaCenter,
                     teNone,
                     False,
                     (BiDiMode <> bdLeftToRight)
                     );

    end
  end;
begin
  inherited;

  if FAutoFitIsLocked or not (eoShowFooter in OptionsEx) then exit;

  DrawBitmap := TBitmap.Create;
  ACanvas := DrawBitmap.Canvas;
  with DrawBitmap do
  begin
    Width := Self.Width;
    Height := Self.Height;
  end;

  for ACol := LeftCol to ColCount-1 do
  begin
    FooterCellRect := CellRect(ACol, RowCount-1);
    if FooterCellRect.Left = FooterCellRect.Right then
      break;
    LastFooterCellRect := FooterCellRect;
  end;

  FooterRect := GetFooterRect;
  FooterRect.Top := FooterRect.Top - 1;
  FooterRect.Bottom := FooterRect.Bottom + 1;
  ACanvas.Brush.Color := Color;
  ACanvas.FillRect(FooterRect);

  ACanvas.Brush.Color := FFooterColor;

  FooterRect := GetFooterRect;
  FooterRect.Right := LastFooterCellRect.Right + 1;
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(FooterRect.Left, FooterRect.Top - 1);
  ACanvas.LineTo(FooterRect.Right, FooterRect.Top - 1);
  if TStyleManager.IsCustomStyleActive   and (seClient in StyleElements)  then
    ACanvas.Brush.Color := StyleServices.GetStyleColor(scGrid);

  ACanvas.FillRect(FooterRect);

  ACanvas.Pen.Color := clWhite;
  ACanvas.MoveTo(FooterRect.Left, FooterRect.Top);
  ACanvas.LineTo(FooterRect.Right, FooterRect.Top);
  ACanvas.MoveTo(FooterRect.Left, FooterRect.Top);
  ACanvas.LineTo(FooterRect.Left, FooterRect.Bottom);
  ACanvas.Pen.Color := clBlack;
  ACanvas.MoveTo(FooterRect.Left, FooterRect.Bottom);
  ACanvas.LineTo(FooterRect.Right, FooterRect.Bottom);

  if Datalink.Active then
  begin
    for ACol := IndicatorOffset to (inherited FixedCols)-IndicatorOffset do
      ProcessFooterCell(ACol);
    for ACol := LeftCol to ColCount-1 do
      ProcessFooterCell(ACol);
  end;

  FooterRect := GetFooterRect;
  FooterRect.Top := FooterRect.Top - 1;//10;
  FooterRect.Bottom := FooterRect.Bottom + 1;

  if Assigned(FFooterFont) then
    ACanvas.Font.Assign(FFooterFont); // aqui ?

  TempRect := FooterRect;
  Canvas.CopyRect(TempRect, ACanvas, TempRect);

  DrawBitmap.Free;
end;

procedure TDBGridPlus.DrawGridBackground;
begin
  if GridStyle.Background.Empty then
  begin
    if (GridStyle.Wallpaper.Direction <> fdNone) then
      PlusDrawGradient(Canvas, ClientRect, GridStyle.Wallpaper.StartColor, GridStyle.Wallpaper.EndColor, GridStyle.Wallpaper.Direction, 255)
  end
  else
  begin
    Canvas.Brush.Bitmap := FGridStyle.Background;
    Canvas.FillRect(ClientRect);
    Canvas.Brush.Bitmap := nil;
  end;

  if Assigned(OnDrawBackground) then
    OnDrawBackground(Self)
end;

procedure TDBGridPlus.Paint;
var
  ARect: TRect;
begin
  if not (csLoading in ComponentState) then
    DrawGridBackground;

  inherited Paint;

  if IsXPThemesEnabled then
  if (FInternalDrawingStyle = gdsThemed) then
  begin
    with TStringGrid(Self) do
      Options := Options - [goFixedVertLine, goFixedHorzLine];
  end;

  if not Assigned(Datalink) or not Assigned(Datalink.Dataset) or
     not Datalink.Dataset.Active then
  begin
    ARect := ClientRect;
    DrawText(Canvas.Handle, PChar(SNoDataToDisplay), -1, ARect,
               DT_CENTER or DT_NOPREFIX or DT_VCENTER or DT_SINGLELINE);
  end;

  if (eoShowFooter in OptionsEx) then
    InvalidateFooter;
end;

procedure TDBGridPlus.WMHScroll(var Message: TWMHSCroll);
begin
  inherited;
end;

procedure TDBGridPlus.WMVScroll(var Message: TWMVSCroll);
var
  HintTxt: string;
  pt: TPoint;
  rHint: TRect;
begin
  if (Message.ScrollCode = SB_THUMBTRACK) then
    Message.ScrollCode := SB_THUMBPOSITION;

  inherited;

end;

{Standard popup menu events}
procedure TDBGridPlus.AppendClick(Sender: TObject);
begin
  if Assigned(FOnAppendRecord) then
    FOnAppendRecord(Self)
  else
    Datalink.DataSet.Append;
end;

procedure TDBGridPlus.InsertClick(Sender: TObject);
begin
  if Assigned(FOnInsertRecord) then
    FOnInsertRecord(Self)
  else
    Datalink.DataSet.Insert;
end;

procedure TDBGridPlus.ClearSort;
var
  i: Integer;
begin
  for i := 0 to Columns.Count-1 do
    if Columns[i] is TPlusDBColumn then
      TPlusDBColumn(Columns[i]).SortType := stNone;
end;

procedure TDBGridPlus.SetSortField(AField: TField; ASortType: TPlusSortType);
var
  i: Integer;
begin
  if not Assigned(AField) then
    exit;

  for i := 0 to Columns.Count-1 do
    if Columns[i] is TPlusDBColumn then
      with TPlusDBColumn(Columns[i]) do
      if Assigned(Field) then
      begin
        if CompareText(AField.FieldName, FieldName) = 0 then
          SortType := ASortType
        else
          SortType := stNone;
      end
end;

procedure TDBGridPlus.DblClick;
begin
  if Assigned(OnDblClick) then
    inherited DblClick;
end;

procedure TDBGridPlus.EditClick(Sender: TObject);
begin
  if Assigned(FOnEditRecord) then
    FOnEditRecord(Self)
  else
    Datalink.DataSet.Edit;
end;

procedure TDBGridPlus.DeleteClick(Sender: TObject);
begin
  if Assigned(FOnDeleteRecord) then
    FOnDeleteRecord(Self)
  else
    DeleteData;
end;

procedure TDBGridPlus.PrintClick(Sender: TObject);
begin
  if Assigned(FOnPrintData) then
    FOnPrintData(Self)
end;

procedure TDBGridPlus.ExportClick(Sender: TObject);
begin
  if Assigned(FOnExportData) then
    FOnExportData(Self)
end;

procedure TDBGridPlus.PostClick(Sender: TObject);
begin
  if Assigned(FOnPostData) then
    FOnPostData(Self)
  else
    Datalink.DataSet.Post;
end;

procedure TDBGridPlus.CancelClick(Sender: TObject);
begin
  if Assigned(FOnCancelData) then
    FOnCancelData(Self)
  else
    Datalink.DataSet.Cancel;
end;

procedure TDBGridPlus.RefreshClick(Sender: TObject);
begin
  if Assigned(FOnRefreshData) then
    FOnRefreshData(Self)
  else
    RefreshData;
end;

procedure TDBGridPlus.SetupGridClick(Sender: TObject);
begin
  if Assigned(FOnSetupGrid) then
    FOnSetupGrid(Self)
end;

function TDBGridPlus.GetImageIndex(Field: TField): Integer;
var
  AOnGetText: TFieldGetTextEvent;
  AOnSetText: TFieldSetTextEvent;
begin
  Result := -1;
  if (eoShowGlyphs in FOptionsEx) and Assigned(Field) then
  begin
    if (not ReadOnly) and Field.CanModify then
    begin
      AOnGetText := Field.OnGetText;
      AOnSetText := Field.OnSetText;
      if Assigned(AOnSetText) and Assigned(AOnGetText) then Exit;
    end;
    case Field.DataType of
      ftBytes, ftVarBytes, ftBlob: Result := Integer(gpBlob);
      ftMemo,
      ftFmtMemo,
      ftWideMemo : Result := Integer(gpMemo);
      ftGraphic: Result := Integer(gpPicture);
      ftTypedBinary: Result := Integer(gpBlob);
      ftParadoxOle, ftDBaseOle: Result := Integer(gpOle);
    end;
  end;
end;

function TDBGridPlus.ActiveRowSelected: Boolean;
var
  Index: Integer;
begin
  Result := False;
  if Datalink.Active and ((dgMultiSelect in Options) or (eoCheckBoxSelect in OptionsEx)) then
    Result := SelectedRows.Find(Datalink.DataSet.Bookmark, Index);
end;

function TDBGridPlus.HighlightCell(DataCol, DataRow: Integer;
  const Value: string; AState: TGridDrawState): Boolean;
begin
  Result := ActiveRowSelected;
  if not Result then
    Result := inherited HighlightCell(DataCol, DataRow, Value, AState);
end;

procedure TDBGridPlus.SMSelectionChanging;
begin
  if Assigned(FOnSelectionChanging) then
    FOnSelectionChanging(Self);
end;

procedure TDBGridPlus.SMSelectionChanged;
begin
  if Assigned(OnSelectionChange) then
    OnSelectionChange(Self);
end;

procedure TDBGridPlus.ToggleRowSelection;
var
  WasSelected: Boolean;
begin
  if Datalink.Active and ((dgMultiSelect in Options) or (eoCheckBoxSelect in OptionsEx)) then
  begin
    SMSelectionChanging;

    if not (dgMultiSelect in Options) then
    begin
      WasSelected := SelectedRows.CurrentRowSelected;
      SelectedRows.Clear;
      if WasSelected then
        SelectedRows.CurrentRowSelected := True;
    end;

    with SelectedRows do
      CurrentRowSelected := not CurrentRowSelected;

    SMSelectionChanged;
  end;
end;

procedure TDBGridPlus.GotoSelection(Index: Longint);
begin
  if (dgMultiSelect in Options) and DataLink.Active and (Index < SelectedRows.Count) and (Index >= 0) then
    Datalink.DataSet.GotoBookmark(TBookmark(SelectedRows[Index]));
end;

function TDBGridPlus.CalcTitleRect1(Col: TColumn; ARow: Integer;
  var MasterCol: TColumn): TRect;
var
  I, J : Integer;
begin
  Result := CalcTitleRect(Col, ARow, MasterCol);
  exit;
end;

function TDBGridPlus.GetBandRect(ACol: Integer): TRect;
var
  MasterCol: TColumn;
  ColIndex, Shift, Count, i, intBandIndex: Integer;
  r: TRect;
begin
  if [dgColLines] * Options = [dgColLines] then
    Shift := 1
  else
    Shift := 0;

  ColIndex := ACol;
  Count := 1;
  if (Columns[ACol] is TPlusDBColumn) then
    intBandIndex := TPlusDBColumn(Columns[ACol]).BandIndex
  else
    intBandIndex := -1;
  if (intBandIndex > -1) then
  begin
    while (ColIndex > 0) and
          (Columns[ColIndex-1] is TPlusDBColumn) and
          (TPlusDBColumn(Columns[ColIndex-1]).BandIndex = intBandIndex) do
    begin
      Dec(ColIndex);
      Inc(Count);
    end;
    i := ACol+1;
    while (i < Columns.Count) and
          (Columns[i] is TPlusDBColumn) and
          (TPlusDBColumn(Columns[I]).BandIndex = intBandIndex) do
    begin
      Inc(Count);
      Inc(i);
    end;
  end;

  if ColIndex + Count > Columns.Count then
  begin
    ColIndex := ACol;
    Count := 1;
  end;

  if (ColIndex < Columns.Count) then
    Result := CalcTitleRect1(Columns[ColIndex], 0, MasterCol)
  else
    Result := Rect(0, 0, 0, 0);
  for i := ColIndex + 1 to ColIndex + Count - 1 do
    if (i < Columns.Count) then
    begin
      r := CalcTitleRect1(Columns[i], 0, MasterCol);
      Result.Right := Result.Right + r.Right - r.Left + Shift;
    end;
end;

procedure TDBGridPlus.SetTitlesHeight;
const
  WordBreaks: array [Boolean] of Integer = (0, DT_WORDBREAK);
var
  i, MaxHeight: Integer;
  RRect: TRect;
  pt: Integer;
  s: TPlusString;
begin
  if not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) and
     Assigned(Parent) and (dgTitles in Options) then
  begin
    MaxHeight := 0;
    if (TitleHeight.Kind = hkAuto) then
    begin
      for i := 0 to Columns.Count-1 do
      begin
        RRect := CellRect(0, 0);
        RRect.Right := Columns[i].Width - 1;
        RRect.Left := 0;
        RRect := CellRectForDraw(RRect, i);

        Canvas.Font := Columns[i].Title.Font;

        s := Columns[i].Title.Caption;
        pt := Pos('|', s);
        if pt > 0 then
        begin
          while pt <> 0 do
          begin
            s[pt] := #13;
            pt := Pos('|', s);
          end;
          Columns[i].Title.Caption := s;
        end;

        MaxHeight := Max(MaxHeight, DrawText(Canvas.Handle,
                         PChar(s),
                         Length(s),
                         RRect,
                         DT_EXPANDTABS or DT_CALCRECT or WordBreaks[eoTitleWordWrap in OptionsEx]));
      end;
    end
    else
    if (TitleHeight.Kind = hkLineCount) then
    begin
      Canvas.Font := TitleFont;
      MaxHeight := Canvas.TextHeight('W')*TitleHeight.LineCount;
    end
    else
    if (TitleHeight.Kind = hkPixelCount) then
    begin
      MaxHeight := TitleHeight.FPixelCount
    end;

    if (MaxHeight <> 0) then
    begin
      if (dgRowLines in Options) then
        Inc(MaxHeight, 3)
      else
        Inc(MaxHeight, 2);
      if (eoTitleButtons in OptionsEx) then
        Inc(MaxHeight, 2);

      if (eoBandsActive in OptionsEx) and (Bands.Count > 0) and
         not (eoBandsOverTitles in OptionsEx) then
        Inc(MaxHeight, DefaultRowHeight);

      if (RowCount > 0) then
        RowHeights[0] := MaxHeight + 2
    end;
  end;
end;

procedure TDBGridPlus.CMFontChanged(var Message: TMessage);
begin
  inherited;
  LayoutChanged;
end;

procedure TDBGridPlus.CMHintShow(var Msg: TMessage);
var
  ACol, ARow: Integer;
  OldActive: Integer;
  fld: TField;
begin
 if (eoCellHint in FOptionsEx) or
    (HintField <> '') then
   with PHintInfo(Msg.LParam)^  do
     try
       HintStr := Hint;

       Msg.Result := 1;
       if not DataLink.Active then Exit;
       TDrawGrid(Self).MouseToCell(CursorPos.X, CursorPos.Y, ACol, ARow);
       CursorRect := CellRect(ACol, ARow);
       ACol := ACol - IndicatorOffset;
       if (ACol < 0) then Exit;
       ARow := ARow - TitleOffset;
       HintPos := ClientToScreen(CursorRect.TopLeft);
       InflateRect(CursorRect, 1, 1);
       if (ARow = -1) then
       begin
         HintStr := Columns[ACol].Title.Caption;

         if Assigned(OnCellHint) then
           OnCellHint(Self, Columns[ACol], HintStr, PHintInfo(Msg.LParam)^);
         if Canvas.TextWidth(HintStr) < Columns[ACol].Width then Exit;
         Msg.Result := 0;
         Exit;
      end;
      if ARow < 0 then exit;
      OldActive := DataLink.ActiveRecord;
      DataLink.ActiveRecord := ARow;
      if HintField <> '' then
        fld := DataLink.DataSet.FindField(HintField)
      else
        fld := Columns[ACol].Field;
      if Assigned(fld) then
        if fld.IsBlob and (fld.DataType <> ftGraphic) then
          HintStr := fld.AsString
        else
          HintStr := fld.DisplayText;
      if Assigned(OnCellHint) then
        OnCellHint(Self, Columns[ACol], HintStr, PHintInfo(Msg.LParam)^);
      DataLink.ActiveRecord := OldActive;
      if (((CursorRect.Right - CursorRect.Left) >=  Columns[ACol].Width) and
          (Canvas.TextWidth(HintStr) < Columns[ACol].Width)) or
         ((Canvas.TextWidth(HintStr) < (CursorRect.Right - CursorRect.Left)) and
          (Columns[ACol].Alignment = taLeftJustify)) then exit;
        Msg.Result := 0;
    except
      Msg.Result := 1;
    end;
end;

procedure TDBGridPlus.UpdateLayout;
begin
  BeginLayout;
  LayoutChanged;
  EndLayout;
end;

function TDBGridPlus.ColumnIsCheckbox(AColumn: TColumn): Boolean;
begin
  if not Assigned(AColumn) or not Assigned(AColumn.Field) then
    Result := False
  else
  begin
    Result := (TPlusDBColumn(AColumn).InplaceEditor = ieCheckbox);
  end;
end;

procedure TDBGridPlus.LayoutChanged;
var
  ACol: Longint;

  oldDefaultRowHeight: Integer;
  PropInfo: PPropInfo;
begin
  ACol := Col;

  PropInfo := GetPropInfo(ClassInfo, 'DefaultRowHeight');
  {if such property exists}
  if not Assigned(PropInfo) or
     IsDefaultPropertyValue(Self, PropInfo, nil) then
    oldDefaultRowHeight := -1
  else
    oldDefaultRowHeight := DefaultRowHeight;

  inherited LayoutChanged;

  if (oldDefaultRowHeight > 0) then
    DefaultRowHeight := oldDefaultRowHeight;

  if Datalink.Active and (FixedCols > 0) then
    Col := Min(Max(inherited FixedCols, ACol), ColCount - 1);

  if (eoAutoWidth in OptionsEx) then
    UpdateColWidths;


  AjustarTamanhoMinimo;
  AjustarTamanhoMaximo;
  ConfigurarMascara();

  {recalculate a title height}
  SetTitlesHeight;
  SetRowHeight;

  if (eoShowFooter in OptionsEx) then
    InvalidateFooter;

end;

procedure TDBGridPlus.ColWidthsChanged;
var
  ACol: Longint;
begin
  ACol := Col;
  inherited ColWidthsChanged;

  if Datalink.Active and (FixedCols > 0) then
    Col := Min(Max(inherited FixedCols, ACol), ColCount - 1);

  if (eoAutoWidth in OptionsEx) then
    UpdateColWidths;

  if Assigned(OnColWidthsChanged) then
    OnColWidthsChanged(Self)
end;

procedure TDBGridPlus.SizeChanged(OldColCount, OldRowCount: Integer);
begin
  inherited SizeChanged(OldColCount, OldRowCount);

  if (eoAutoWidth in OptionsEx) then
    UpdateColWidths;

end;

procedure TDBGridPlus.RowHeightsChanged;
var
  i: Integer;
begin
  if not (csLoading in ComponentState) then
    inherited;

  if not Assigned(Parent) then exit;

  for i := TopRow to TopRow + VisibleRowCount + 1 do
    if (RowHeights[i] <> DefaultRowHeight) then
    begin
      if RowHeights[i] < Canvas.TextHeight('Wg') + 2 then
        RowHeights[i] := Canvas.TextHeight('Wg') + 2;
      if not (eoRowHeightAutofit in OptionsEx) then
        DefaultRowHeight := RowHeights[i];
      break;
    end;
end;

procedure TDBGridPlus.SetIndicatorWidth(Value: Integer);
var
  FrameOffs: Byte;
begin
  if (Value <> FWidthOfIndicator) then
  begin
    if ([dgRowLines, dgColLines] * Options = [dgRowLines, dgColLines]) then
      FrameOffs := 1
    else
      FrameOffs := 2;

    if (eoCheckBoxSelect in OptionsEx) and
       (Value < FCheckWidth + 4*FrameOffs + FMsIndicators.Width) then
      Value := FCheckWidth + 4*FrameOffs + FMsIndicators.Width;

    if Value < IndicatorWidth then
      Value := IndicatorWidth;
    FWidthOfIndicator := Value;

    SetColumnAttributes
  end;
end;

procedure TDBGridPlus.SetColumnAttributes;
begin
  inherited SetColumnAttributes;

  if (dgIndicator in Options) then
    if (ColCount > 0) then
      ColWidths[0] := FWidthOfIndicator;

  SetFixedCols(FFixedCols);
end;

function TDBGridPlus.GetTitleOffset: Byte;
begin
  Result := 0;
  if dgTitles in Options then
    Inc(Result);
end;

procedure TDBGridPlus.SetFixedCols(Value: Integer);
var
  FixCount, i, intRow: Integer;
begin
  FixCount := Max(Value, 0) + IndicatorOffset;
  if DataLink.Active and not (csLoading in ComponentState) and
    (ColCount > IndicatorOffset + 1) then
  begin
    FixCount := Min(FixCount, ColCount - 1);
    intRow := Row;
    inherited FixedCols := FixCount;
    for i := 1 to Min(FixedCols, ColCount - 1) do
      TabStops[i] := False;
    Row := intRow;
  end;
  FFixedCols := FixCount - IndicatorOffset;
end;

function TDBGridPlus.GetFixedCols: Integer;
begin
  if DataLink.Active then
    Result := inherited FixedCols - IndicatorOffset
  else
    Result := FFixedCols;
end;

procedure TDBGridPlus.SelectOneClick(Sender: TObject);
begin
  if (dgMultiSelect in Options) and Datalink.Active then
  begin
    SMSelectionChanging;
    SelectedRows.CurrentRowSelected := True;
    SMSelectionChanged;
  end
end;

procedure TDBGridPlus.SelectAllClick(Sender: TObject);
var
  ABookmark: TBookmark;
begin
  if (dgMultiSelect in Options) and DataLink.Active then
  begin
    with Datalink.Dataset do
    begin
      if (BOF and EOF) then Exit;
      DisableControls;
      try
        ABookmark := GetBookmark;
        try
          SMSelectionChanging;
          First;
          while not EOF do
          begin
            SelectedRows.CurrentRowSelected := True;
            Next;
          end;
        finally
          try
            if BookmarkValid(ABookmark) then
              GotoBookmark(ABookmark);
          except
          end;
          FreeBookmark(ABookmark);
        end;
      finally
        SMSelectionChanged;
        EnableControls;
      end;
    end;
  end;
end;

procedure TDBGridPlus.UnSelectOneClick(Sender: TObject);
begin
  if (dgMultiSelect in Options) and Datalink.Active then
  begin
    SMSelectionChanging;
    SelectedRows.CurrentRowSelected := False;
    SMSelectionChanged;
  end
end;

procedure TDBGridPlus.UnSelectAllClick(Sender: TObject);
begin
  if (dgMultiSelect in Options) then
  begin
    SMSelectionChanging;
    SelectedRows.Clear;
    FSelecting := False;
    SMSelectionChanged;
  end;
end;

procedure TDBGridPlus.SaveLayoutClick(Sender: TObject);
begin
  SaveGridToIni(Self, GetLocalFile(Self) );
end;

procedure TDBGridPlus.RestoreLayoutClick(Sender: TObject);
begin
  LoadGridFromIni(Self, GetLocalFile(Self) );
end;

procedure TDBGridPlus.ResyncIndicator;
var
  r: Integer;
begin
  try
    Repaint;
    r := DataLink.ActiveRecord + Self.TitleOffset;
    if (r >= 0) and (r < RowCount) then
      Row := r
  except
  end;
end;

procedure TDBGridPlus.DeleteData;

  function DeletePrompt: Boolean;
  var S: TPlusString;
  begin
    if (SelectedRows.Count > 1) then
      S := SDeleteMultipleRecordsQuestion
    else
      S := SDeleteRecordQuestion;
    Result := not (dgConfirmDelete in Options) or
      (MessageDlg(S, mtConfirmation, [mbYes, mbNo], 0) = mrYes);
  end;

begin
  if DeletePrompt then
  begin
    if SelectedRows.Count > 0 then
      SelectedRows.Delete
    else
      Datalink.DataSet.Delete;
  end;
end;

procedure TDBGridPlus.RefreshData;
var
  bookPosition: TBookMark;
  boolContinue: Boolean;
begin
  boolContinue := True;
  if Assigned(Datalink.DataSet) then
  begin
     with Datalink.DataSet do
     begin
       if (State in [dsInsert, dsEdit]) and CanModify then
        Post;

       if boolContinue then
       begin
         bookPosition := GetBookmark;
         Close;
         Open;
         try
           GotoBookmark(bookPosition);
         except
           First;
         end;
         FreeBookmark(bookPosition);
       end;
     end;
  end;
end;

procedure TDBGridPlus.SetOptionsEx(Val: TOptionsEx);
var
  FrameOffs: Byte;
begin
  if (FOptionsEx <> Val) then
  begin
    FOptionsEx := Val;

   if (eoRowSizing in Val) then
     THackGrid(Self).Options := THackGrid(Self).Options + [goRowSizing]
   else
     THackGrid(Self).Options := THackGrid(Self).Options - [goRowSizing];

    if ([dgRowLines, dgColLines] * Options = [dgRowLines, dgColLines]) then
      FrameOffs := 1
    else
      FrameOffs := 2;

    if (eoCheckBoxSelect in Val) then
    begin
      if (FWidthOfIndicator = IndicatorWidth) then
        WidthOfIndicator := FCheckWidth + 4*FrameOffs + FMsIndicators.Width;
    end
    else
    begin
      if (WidthOfIndicator = FCheckWidth + 4*FrameOffs + FMsIndicators.Width) then
        WidthOfIndicator := IndicatorWidth;
    end;

    if (eoAutoWidth in Val) then
      UpdateColWidths;

    SetTitlesHeight;
    SetRowHeight;

    InvalidateFooter;

    Invalidate;
  end;
end;

function TDBGridPlus.CanEditShow: Boolean;
var
  i: Integer;
  str: TPlusString;
  CalcExpResult: Boolean;
begin
  Result := inherited CanEditShow;

  if (FieldCount > 0) and
     (SelectedIndex > -1) and
     Assigned(Columns[SelectedIndex].Field) then
  begin
    Result := Result and not Columns[SelectedIndex].ReadOnly; // Edit in the case the column is not read-only

    if Result and
       (Datalink <> nil) and
       Datalink.Active then
      Result := (GetImageIndex(Columns[SelectedIndex].Field) < 0);
    if Result and
       ColumnIsCheckbox(Columns[SelectedIndex]) then
      Result := False;
    if Result and (SelectedIndex < FixedCols) then
      Result := False;

  end;
end;

function TDBGridPlus.AcquireFocus: Boolean;
begin
  Result := True;
  if FAcquireFocus and CanFocus and not (csDesigning in ComponentState) then
  begin
    SetFocus;
    Result := Focused or (InplaceEditor <> nil) and InplaceEditor.Focused;
  end;
end;

function TDBGridPlus.GetOptions: TDBGridOptions;
begin
  Result := inherited Options;

  FIsFlagAlwaysShowEditor := (dgAlwaysShowEditor in Result) and (csLoading in ComponentState);
  if FIsFlagAlwaysShowEditor then
  begin
    Result := Result - [dgAlwaysShowEditor];
    inherited Options := Result;
  end;

  if FMultiSelect then
    Result := Result + [dgMultiSelect]
  else
    Result := Result - [dgMultiSelect];
end;

procedure TDBGridPlus.SetOptions(Value: TDBGridOptions);
begin
  inherited Options := Value - [dgMultiSelect];

  if FMultiSelect <> (dgMultiSelect in Value) then
  begin
    FMultiSelect := (dgMultiSelect in Value);
    if not FMultiSelect then
      SelectedRows.Clear;
  end;
end;

procedure TDBGridPlus.GetCellProps(ACol, ARow: Integer; Field: TField; AFont: TFont;
  var Background: TColor; Highlight: Boolean);
begin
  if not Highlight then
  begin
    if (eoFixedLikeColumn in OptionsEx) or
       (((dgIndicator in Options) and (ACol >= FixedCols)) or
        (not (dgIndicator in Options) and (ACol > FixedCols-1))) then
      if (GridStyle.StyleColorGrid <> gsNormal) then
      begin
        if (ARow mod 2 = 0) then
          Background := GridStyle.OddColor
        else
          Background := GridStyle.EvenColor;
      end
  end;

  if Assigned(FOnGetCellParams) then
    FOnGetCellParams(Self, Field, AFont, Background, Highlight)

end;

procedure TDBGridPlus.CheckTitleButton(ACol: Longint; var Enabled: Boolean);
begin
  if (ACol >= 0) and (ACol < Columns.Count) then
  begin
    if Assigned(FOnCheckButton) then
      FOnCheckButton(Self, ACol, Columns[ACol].Field, Enabled);
  end
  else
    Enabled := False;
end;

procedure TDBGridPlus.DisableScroll;
begin
  Inc(FDisableCount);
end;

procedure TDBGridPlus.EnableScroll;
begin
  if FDisableCount <> 0 then
  begin
    Dec(FDisableCount);
    if FDisableCount = 0 then
      THackLink(DataLink).DataSetScrolled(0);
  end;
end;

function TDBGridPlus.ScrollDisabled: Boolean;
begin
  Result := FDisableCount <> 0;
end;

procedure TDBGridPlus.Scroll(Distance: Integer);
var
  IndicatorRect: TRect;
begin
  if FDisableCount = 0 then
  begin
    inherited Scroll(Distance);

    if (dgIndicator in Options) and
       HandleAllocated and
       (dgMultiSelect in Options) then
    begin
      IndicatorRect := BoxRect(0, 0, 0, RowCount - 1);
      InvalidateRect(Handle, @IndicatorRect, False);
    end;
  end;
end;

procedure TDBGridPlus.DoTabChange(Sender: TObject);
begin
  if not IsReading then
    InvalideTab;
end;

procedure TDBGridPlus.KeyDown(var Key: Word; Shift: TShiftState);
var
  KeyDownEvent: TKeyEvent;

  function ItAddLastRecord: Boolean;
  begin
    Result := (eoDisableInsert in FOptionsEx) and
              (Datalink.ActiveRecord >= GetRecordCount-1);
  end;

  procedure ClearSelections;
  begin
    if (dgMultiSelect in Options) then
    begin
      if not (eoKeepSelection in OptionsEx) then
        SelectedRows.Clear;
      FSelecting := False;
    end;
  end;

  procedure DoSelection(Select: Boolean; Direction: Integer);
  var
    AddAfter: Boolean;
  begin
    AddAfter := False;
    BeginUpdate;
    try
      if (dgMultiSelect in Options) and DataLink.Active then
        if Select and (ssShift in Shift) then
        begin
          if not FSelecting then
          begin
            FSelectionAnchor := TBookmarks(SelectedRows).CurrentRow;
            SelectedRows.CurrentRowSelected := True;
            FSelecting := True;
            AddAfter := True;
          end
          else
            with TBookmarks(SelectedRows) do
            begin
              AddAfter := Compare(CurrentRow, FSelectionAnchor) <> -Direction;
              if not AddAfter then
                CurrentRowSelected := False;
            end
        end
        else
          ClearSelections;
      if Direction <> 0 then
        if Datalink.DataSet.State = dsInsert then
          Datalink.DataSet.MoveBy(0)
        else
          Datalink.DataSet.MoveBy(Direction);
      if AddAfter then
        SelectedRows.CurrentRowSelected := True;
    finally
      EndUpdate;
    end;
  end;

  procedure NextRow(Select: Boolean);
  begin
    with Datalink.Dataset do
    begin
      if (State = dsInsert) and not Modified then
      begin
        if EOF then
          Exit
        else
          Cancel
      end
      else
        DoSelection(Select, 1);
      if EOF and CanModify and (not ReadOnly) and (dgEditing in Options) then
        if not (eoDisableInsert in FOptionsEx) and not ItAddLastRecord then
          AppendClick(Self)
        else
          Key := 0;
    end;
  end;

  procedure PriorRow(Select: Boolean);
  begin
    DoSelection(Select, -1);
  end;

  procedure CheckTab(GoForward: Boolean);
  var
    ACol, Original: Integer;
  begin
    if DataLink.Active then
    begin
      SelectedIndex := Col - 1;
      ACol := Col;
      Original := ACol;
      BeginUpdate;
      try
        while True do
        begin
          if GoForward then
            Inc(ACol)
          else
            Dec(ACol);
          if ACol >= ColCount then
          begin
            ClearSelections;
            NextRow(False);
            if Key = 0 then
              ACol := Original
            else
              ACol := IndicatorOffset;
          end
          else
            if ACol < IndicatorOffset then
            begin
              ClearSelections;
              PriorRow(False);
              if not DataLink.DataSet.Bof then
                ACol := ColCount - IndicatorOffset{1}
              else
                ACol := Original;
            end;

          if (ACol = Original) or (not Columns[ACol-1].ReadOnly and Columns[ACol-1].Visible) then
          begin
            if Col <> ACol then
            begin
              ColExit;
              Col := ACol;
              ColEnter;
            end;
            Key := 0;
            break;
          end;
          if TabStops[ACol] then
          begin
            Exit;
          end;
        end;
      finally
        EndUpdate;
      end
    end
  end;

const
  RowMovementKeys = [VK_UP, VK_PRIOR, VK_DOWN, VK_NEXT, VK_HOME, VK_END];

var
  oldSelectedRowCount: Integer;
begin

  if (dgMultiSelect in Options) and Assigned(OnSelectionChange) then
    oldSelectedRowCount := SelectedRows.Count
  else
    oldSelectedRowCount := 0;
  SMSelectionChanging;

  KeyDownEvent := OnKeyDown;
  if Assigned(KeyDownEvent) then
    KeyDownEvent(Self, Key, Shift);
  if not Datalink.Active or not CanGridAcceptKey(Key, Shift) then Exit;

  with Datalink.DataSet do
    if (ssCtrl in Shift) then
    begin
      if (Key in RowMovementKeys) then
        ClearSelections;

      case Key of
        VK_LEFT: if FixedCols > 0 then
                 begin
                   SelectedIndex := FixedCols;
                   Key := 0;
                 end;
        VK_DELETE: begin
                     Key := 0;
                     if not (eoDisableDelete in FOptionsEx) then
                       if not ReadOnly and CanModify then
                         DeleteClick(nil);
                   end;
      end
    end
    else
    begin
      case Key of
        VK_LEFT: if (FixedCols > 0) and not (dgRowSelect in Options) then
                 begin
                   if SelectedIndex <= FFixedCols then Key := 0;
                 end;
        VK_HOME: if (FixedCols > 0) and (ColCount <> IndicatorOffset + 1) and
                    not (dgRowSelect in Options) then
                 begin
                   SelectedIndex := FixedCols;
                   Key := 0;
                 end;
        VK_SPACE: if (Datalink <> nil) and Datalink.Active and
                     (SelectedIndex > -1) and
                     ColumnIsCheckbox(Columns[SelectedIndex]) then
                  begin
                    CellClick(Columns[SelectedIndex]);
                  end;
        VK_DOWN: begin
                   NextRow(True);
                   if (eoDisableInsert in FOptionsEx) and
                      (DataLink.Dataset.Eof) and (DataLink.Dataset.State = dsInsert) then
                     DataLink.Dataset.Cancel;
                   Key := 0;
                 end;
        VK_INSERT: if (eoDisableInsert in FOptionsEx) then Key := 0;
      end;
      if (Datalink.DataSet.State = dsBrowse) then
      begin
        case Key of
          VK_UP: begin
                   PriorRow(True);
                   Key := 0;
                 end;
          VK_RETURN: if (eoEnterToTab in FOptionsEx)  then
                     begin
                       if (SelectedIndex < Columns.Count-1) then
                       begin
                         SelectedIndex := SelectedIndex + 1;

                         while (SelectedIndex < Columns.Count-1) and (not Columns[SelectedIndex].Visible) do
                           SelectedIndex := SelectedIndex + 1;
                       end
                       else
                       begin
                         if not (eoDisableInsert in OptionsEx) and
                            Datalink.DataSet.EOF and Datalink.DataSet.CanModify then
                           Datalink.DataSet.Append
                         else
                           Datalink.DataSet.Next;

                         SelectedIndex := FixedCols;
                       end;
                     end;
        end;
      end;
      if ((Key in [VK_LEFT, VK_RIGHT]) and (dgRowSelect in Options)) or
         ((Key in [VK_HOME, VK_END]) and ((ColCount = IndicatorOffset + 1)
          or (dgRowSelect in Options))) or (Key in [VK_ESCAPE, VK_NEXT,
          VK_PRIOR]) or ((Key = VK_INSERT) and (CanModify and
          (not ReadOnly) and (dgEditing in Options))) then
        ClearSelections
      else
        if ((Key = VK_TAB) and not (ssAlt in Shift)) then
          CheckTab(not (ssShift in Shift));
    end;
  OnKeyDown := nil;
    inherited KeyDown(Key, Shift);
  OnKeyDown := KeyDownEvent;

  if (dgMultiSelect in Options) then
  begin
    if (oldSelectedRowCount <> SelectedRows.Count) then
      SMSelectionChanged
  end
end;

procedure TDBGridPlus.TopLeftChanged;
begin
  if (dgRowSelect in Options) and DefaultDrawing then
    GridInvalidateRow(Self, Self.Row);

  inherited TopLeftChanged;
  if FTracking then StopTracking;

  if (eoAutoWidth in OptionsEx) then
    UpdateColWidths;

  if (eoShowFooter in OptionsEx) then
    InvalidateFooter;

  if Assigned(FOnTopLeftChanged) then
    FOnTopLeftChanged(Self);
end;

procedure TDBGridPlus.StopTracking;
begin
  if FTracking then
  begin
    TrackButton(-1, -1);
    FTracking := False;
    MouseCapture := False;
  end;
end;

procedure TDBGridPlus.TrackButton(X, Y: Integer);
var
  Cell: TGridCoord;
  NewPressed: Boolean;
begin
  Cell := MouseCoord(X, Y);
  NewPressed := PtInRect(Rect(0, 0, ClientWidth, ClientHeight), Point(X, Y))
    and (FPressedCol = Cell.X) and (Cell.Y = 0);
  if FPressed <> NewPressed then
  begin
    FPressed := NewPressed;
    GridInvalidateRow(Self, 0);
  end;
end;

function ValueMatch(const ValueList, Value: TPlusString): Boolean;
var
  Pos: Integer;
begin
  Result := False;
  Pos := 1;
  while Pos <= Length(ValueList) do
    if AnsiCompareText(ExtractFieldName(ValueList, Pos), Value) = 0 then
    begin
      Result := True;
      break;
    end;
end;

procedure TDBGridPlus.CellClick(Column: TColumn);
var
  R: TRect;
  BCol, APos: Integer;
begin
  inherited CellClick(Column);

  if (not (dgRowSelect in Options)) and
     (Datalink <> nil) and
     Datalink.Active and
     Assigned(Column.Field) and
     ColumnIsCheckbox(Column) and
     CanEditModify then
  begin
    try
      if (Column.Field.DataType = ftBoolean) then
        Column.Field.AsBoolean := not Column.Field.AsBoolean
      else
      if (Column is TPlusDBCheckboxColumn) then
      begin
        with TPlusDBCheckboxColumn(Column) do
        begin
          APos := -1;
          if ValueMatch(ValueChecked, Field.AsString) then
            Field.AsString := ExtractFieldName(ValueUnchecked, APos)
          else
            Field.AsString := ExtractFieldName(ValueChecked, APos);
        end
      end
      else
      if (Column.Field is TNumericField) then
      begin
        if Column.Field.AsFloat = 1 then
          Column.Field.Value := 0
        else
          Column.Field.Value := 1
      end
      else
      if (Column.Field is TStringField) then
      begin
        if (Column.Field.AsString = '1') then
          Column.Field.AsString := '0'
        else
        if (Column.Field.AsString = '0') then
          Column.Field.Value := '1'
        else
        if (UpperCase(Column.Field.AsString) = 'T') then
          Column.Field.AsString := 'F'
        else
        if (UpperCase(Column.Field.AsString) = 'F') then
          Column.Field.Value := 'T'
        else
        if (UpperCase(Column.Field.AsString) = UpperCase(DefaultTrueBoolStr)) then
          Column.Field.AsString := DefaultFalseBoolStr
        else
        if (UpperCase(Column.Field.AsString) = UpperCase(DefaultFalseBoolStr)) then
          Column.Field.Value := DefaultTrueBoolStr
        else
        if (UpperCase(Column.Field.AsString) = UpperCase(TPlusDBColumn(Column).CheckBox.CheckedValue)) then
          Column.Field.AsString := UpperCase(TPlusDBColumn(Column).CheckBox.UnCheckedValue)
        else
        if (UpperCase(Column.Field.AsString) = UpperCase(UpperCase(TPlusDBColumn(Column).CheckBox.UnCheckedValue))) then
          Column.Field.Value := UpperCase(TPlusDBColumn(Column).CheckBox.CheckedValue)
      end;
    except
      Column.Field.Value := NULL;
    end;

    if (dgIndicator in Options) then
      BCol := Column.Index + 1
    else
      BCol := Column.Index;
    GetEditText(BCol, Row);

    R := CellRect(BCol, Row);
    DrawCell(BCol, Row, R, [{gdSelected, gdFocused}]);
  end;

end;

function TDBGridPlus.GetSortImageWidth: Integer;
begin
  Result := Max(GetGridBitmap(gpSortAsc).Width, GetGridBitmap(gpSortDesc).Width);
end;

function TDBGridPlus.CellRectForDraw(R: TRect; ACol: Longint): TRect;
var
  i: Integer;
begin
  Result := R;

  i := GetSortImageWidth;
  if (Result.Right-Result.Left > i+4) then
  begin
    if (ACol > -1) and
       (Columns[ACol] is TPlusDBColumn) and
       (TPlusDBColumn(Columns[ACol]).SortType <> stNone) then
      Result.Right := Result.Right-i-4;
  end;
  i := 2*(GridLineWidth+1)+1;
  Result.Right := Result.Right-i
end;

function TDBGridPlus.GetGlyph: TBitmap;
begin
  Result := nil;
  if Assigned(FOnGetGlyph) then
    FOnGetGlyph(Self, Result);
end;

function TDBGridPlus.IsMouseInRect(ARect: TRect): Boolean;
var
  r: TRect;
begin
  Result := IntersectRect(r, ARect, FLastRect);
end;

function TDBGridPlus.IsReading: boolean;
begin
  Result:= ComponentState * [csLoading, csReading, csUpdating] <> [];
end;

procedure TDBGridPlus.DrawComboArrow(R: TRect);
const
  CBXS_NORMAL = 1;
  CBXS_HOT = 2;

  CP_DROPDOWNBUTTON = 1;

var
  DrawState: Integer;

  hhTheme: ThemeHandle;
  FMouseInRect: Boolean;
begin
  if IsXPThemesEnabled and
     (FInternalDrawingStyle = gdsThemed) and
     not (csDesigning in ComponentState) then
    hhTheme := OpenThemeData(0, 'Combobox')
  else
    hhTheme := 0;

  if (hhTheme <> 0) then
  begin
    FMouseInRect := IsMouseInRect(R);

    if FMouseInRect then
      DrawState := CBXS_HOT
    else
      DrawState := CBXS_NORMAL;

    try
      FLastXPDrawn := FMouseInRect;
      DrawThemeBackground(hhTheme, Canvas.Handle, CP_DROPDOWNBUTTON, DrawState, @R, nil);
    finally
      CloseThemeData(hhTheme);
    end;
  end
  else
    DrawFrameControl(Canvas.Handle, R, DFC_SCROLL, DFCS_SCROLLCOMBOBOX);
end;

function GetDrawState2010(State: TCheckBoxState; MouseInControl: Boolean; AEnabled: Boolean; APressed: Boolean): TThemedButton;
begin
  Result := tbButtonDontCare;

  if not AEnabled then
    case State of
      cbUnChecked: Result := tbCheckBoxUncheckedDisabled;
      cbChecked: Result := tbCheckBoxCheckedDisabled;
      cbGrayed: Result := tbCheckBoxMixedDisabled;
    end
  else if APressed and MouseInControl then
    case State of
      cbUnChecked: Result := tbCheckBoxUncheckedPressed;
      cbChecked: Result := tbCheckBoxCheckedPressed;
      cbGrayed: Result := tbCheckBoxMixedPressed;
    end
  else if MouseInControl then
    case State of
      cbUnChecked: Result := tbCheckBoxUncheckedHot;
      cbChecked: Result := tbCheckBoxCheckedHot;
      cbGrayed: Result := tbCheckBoxMixedHot;
    end
  else
    case State of
      cbUnChecked: Result := tbCheckBoxUncheckedNormal;
      cbChecked: Result := tbCheckBoxCheckedNormal;
      cbGrayed: Result := tbCheckBoxMixedNormal;
    end;
end;

function TDBGridPlus.GetCheckBoxValue(AField: TField; Value: Variant; ValueChecked: TPlusString; aColumn: TColumn = nil): TCheckBoxState;
begin
  Result := cbUnChecked;
  if not Assigned(TPlusDBColumn(aColumn)) then
    Exit;

  try
    if VarIsNull(Value) or VarIsEmpty(Value) then
      Result := cbGrayed
    else
    if (VarToStr(Value) = ValueChecked) then
      Result := cbChecked
    else
    if (VarType(Value) = varBoolean) then
    begin
      if VarAsType(Value, varBoolean) then
        Result := cbChecked;
    end
    else
    if Assigned(AField) then
    begin
      if (AField is TNumericField) and AField.Value then
        Result := cbChecked
      else
      if (AField is TStringField) and (AField.AsString = UpperCase(Trim(TPlusDBColumn(Columns[TPlusDBColumn(aColumn).Index]).CheckBox.CheckedValue)) ) then
      begin
        Result := cbChecked;
      end;
    end
  except
  end;
end;

procedure TDBGridPlus.DrawCheckBox(R: TRect; AState: TCheckBoxState; al: TAlignment);
const
  CBS_UNCHECKEDNORMAL = 1;
  CBS_UNCHECKEDHOT = 2;
  CBS_CHECKEDNORMAL = 5;
  CBS_CHECKEDHOT = 6;
  CBS_MIXEDNORMAL = 9;
  CBS_MIXEDHOT = 10;

  BP_CHECKBOX = 3;

var
  DrawState: Integer;
  DrawRect: TRect;

  hhTheme: ThemeHandle;
  FMouseInRect, IsControlDrawn: Boolean;

  Details: TThemedElementDetails;
  BoxSize: TSize;
begin

  case AState of
    cbChecked: DrawState := DFCS_BUTTONCHECK or DFCS_CHECKED;
    cbUnchecked: DrawState := DFCS_BUTTONCHECK;
  else // cbGrayed
    DrawState := DFCS_BUTTON3STATE or DFCS_CHECKED;
  end;
  if Flat then
    DrawState := DrawState or DFCS_FLAT;

  if StyleServices.Available and StyleServices.Enabled then
  begin
    if StyleServices.GetElementSize(Canvas.Handle, StyleServices.GetElementDetails(tbCheckBoxCheckedNormal),
        DrawRect, esActual, BoxSize, CurrentPPI) then
    begin
      FCheckWidth := BoxSize.cx;
      FCheckHeight := BoxSize.cy;
    end
  end;

  case al of
    taRightJustify: begin
                      DrawRect.Left := R.Right - FCheckWidth;
                      DrawRect.Right := R.Right;
                    end;
    taCenter: begin
                DrawRect.Left := R.Left + (R.Right - R.Left - FCheckWidth) div 2;
                DrawRect.Right := DrawRect.Left + FCheckWidth;
              end;
  else // taLeftJustify
    DrawRect.Left := R.Left;
    DrawRect.Right := DrawRect.Left + FCheckWidth;
  end;
  DrawRect.Top := R.Top + (R.Bottom - R.Top - FCheckWidth) div 2;
  DrawRect.Bottom := DrawRect.Top + FCheckHeight;

  IsControlDrawn := False;

  if StyleServices.Available and StyleServices.Enabled then
  begin
    FMouseInRect := IsMouseInRect(R);
    Details := StyleServices.GetElementDetails(GetDrawState2010(AState, FMouseInRect, True, False));
    StyleServices.DrawElement(Canvas.Handle, Details, DrawRect, nil, CurrentPPI);
    IsControlDrawn := True;
  end;

  if not IsControlDrawn then
  begin
    if IsXPThemesEnabled and
       (FInternalDrawingStyle = gdsThemed) and
       not (csDesigning in ComponentState) then
      hhTheme := OpenThemeData(0, 'Button')
    else
      hhTheme := 0;

    if (hhTheme <> 0) then
    begin
      FMouseInRect := IsMouseInRect(R);

      case AState of
        cbChecked: if FMouseInRect then
                     DrawState := CBS_CHECKEDHOT
                   else
                     DrawState := CBS_CHECKEDNORMAL;
        cbUnchecked: if FMouseInRect then
                       DrawState := CBS_UNCHECKEDHOT
                     else
                       DrawState := CBS_UNCHECKEDNORMAL;
        else // cbGrayed
          if FMouseInRect then
            DrawState := CBS_MIXEDHOT
          else
            DrawState := CBS_MIXEDNORMAL
      end;

      try
        FLastXPDrawn := FMouseInRect;//True;
        DrawThemeBackground(hhTheme, Canvas.Handle, BP_CHECKBOX, DrawState, @DrawRect, nil);
      finally
        CloseThemeData(hhTheme);
      end;
    end
    else
      DrawFrameControl(Canvas.Handle, DrawRect, DFC_BUTTON, DrawState);
  end
end;

function TDBGridPlus.GetVerticalAlignment(AColumn: TColumn): TPlusGVerticalAlignment;
begin
  Result := gvaCenter;
  if Assigned(AColumn) and (AColumn is TPlusDBColumn) then
    Result := TPlusDBColumn(AColumn).VerticalAlignment
end;

procedure TDBGridPlus.DefDrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
var
  OldActive: Integer;
  Highlight: Boolean;
  Value: TPlusString;
  DrawColumn:  TColumn;
  FrameOffs: Byte;

  CheckState: TCheckBoxState;

  IsCustomStyle: Boolean;
  Style: TCustomStyleServices;
begin

  Style := StyleServices;
  IsCustomStyle := TStyleManager.IsCustomStyleActive;
  if csLoading in ComponentState then
  begin
    if IsCustomStyle  and (seClient in StyleElements)  then
      Canvas.Brush.Color := Style.GetStyleColor(scGrid)
    else
      Canvas.Brush.Color := Color;
    Canvas.FillRect(ARect);
    exit;
  end;

  Dec(ARow, TitleOffset);
  Dec(ACol, IndicatorOffset);

  if IsXPThemesEnabled and
    (FInternalDrawingStyle = gdsThemed) and
     (gdFixed in AState) and ([dgRowLines, dgColLines] * Options =
    [dgRowLines, dgColLines]) then
  begin
    InflateRect(ARect, -1, -1);
    FrameOffs := 1;
  end
  else
    FrameOffs := 0;

  DrawColumn := Columns[ACol];

  if DrawColumn <> nil then
  begin
    if DrawColumn.Field <> nil then
      if not DrawColumn.Field.DataSet.Active then
        Exit;
  end;

  with Canvas do
  begin
    if (gdFixed in AState) then
    begin
      Font := DrawColumn.Title.Font;
    end
    else
    begin
      Font := DrawColumn.Font;
    end;
    Brush.Color := ApplyBackroundColorToCanvas(ACol, ARow, DrawColumn, AState);

    if IsCustomStyle then
    begin
      if (seFont in StyleElements)  then
        Font.Color := Style.GetStyleFontColor(sfGridItemNormal)
      else
        Font.Color := Self.Font.Color;
      if (seClient in StyleElements)  then
        Brush.Color := Style.GetStyleColor(scGrid)
      else
        Brush.Color := Color;
    end;

    if (ARow < 0) then
    begin
      with DrawColumn.Title do
        WriteTitleText(Canvas, ARect, FrameOffs, FrameOffs, Caption, Alignment, GetVerticalAlignment(DrawColumn),
                       teNone,
                       eoTitleWordWrap in OptionsEx,
                       (BiDiMode <> bdLeftToRight) )
    end
    else
      if (DataLink = nil) or not DataLink.Active then
        FillRect(ARect)
      else
      begin
        Value := '';
        OldActive := DataLink.ActiveRecord;
        try
          DataLink.ActiveRecord := ARow;
          if Assigned(DrawColumn.Field) then
            Value := DrawColumn.Field.DisplayText;
          Highlight := HighlightCell(ACol, ARow, Value, AState);
          if Highlight then
          begin
            DrawCellHighlight(ARect, AState, ACol, ARow);
          end;

          if DefaultDrawing then
          begin
            if not Highlight then
              Canvas.FillRect(ARect);
            if ColumnIsCheckbox(DrawColumn) then
            begin
              CheckState := GetCheckBoxValue(DrawColumn.Field, DrawColumn.Field.Value, '');
              DrawCheckBox(ARect, CheckState, taCenter);
            end
            else
            begin
              WriteTitleText(Canvas, ARect, 2, 2, Value, DrawColumn.Alignment, GetVerticalAlignment(DrawColumn),
                             GetColumnEllipsis(DrawColumn),
                             (eoCellWordWrap in OptionsEx),
                             (BiDiMode <> bdLeftToRight)
                             );
            end
          end;

          if (Columns.State = csDefault) then
            DrawDataCell(ARect, DrawColumn.Field, AState);
        finally
          DataLink.ActiveRecord := OldActive;
        end;
        if DefaultDrawing and (gdSelected in AState) and
           ((dgAlwaysShowSelection in Options) or Focused) and
           not (csDesigning in ComponentState) and
           not (dgRowSelect in Options) and
           (UpdateLock = 0) and
           (ValidParentForm(Self).ActiveControl = Self) then
              Winapi.Windows.DrawFocusRect(Handle, ARect);
      end;
  end;

  if IsXPThemesEnabled and
     (FInternalDrawingStyle = gdsThemed) and
     (gdFixed in AState) and ([dgRowLines, dgColLines] * Options =
     [dgRowLines, dgColLines]) then
  begin
    InflateRect(ARect, 1, 1);
    if Flat then
      DrawEdge(Canvas.Handle, ARect, BDR_RAISEDINNER, BF_FLAT)
    else
    if not TStyleManager.IsCustomStyleActive then
    begin
      DrawEdge(Canvas.Handle, ARect, BDR_RAISEDINNER, BF_BOTTOMRIGHT);
      DrawEdge(Canvas.Handle, ARect, BDR_RAISEDINNER, BF_TOPLEFT);
    end
  end;
end;

procedure TDBGridPlus.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
const
  HP_HEADERITEM = 1;
  HIS_NORMAL = 1;
  HIS_HOT = 2;

var
  TitleText: TPlusString;
  i, j, idxSort, BCol: LongInt;
  bmp: TBitmap;
  BRect: TRect;

  IsCustomStyle: Boolean;
  Style: TCustomStyleServices;

  procedure DrawTitleColumn(DrawColumn: TColumn);
  var
    HRect: TRect;
    smeColumn: TPlusDBColumn;
    hhTheme: ThemeHandle;
  begin
    if (eoBandsActive in OptionsEx) and (DrawColumn is TPlusDBColumn) then
    begin
      smeColumn := TPlusDBColumn(DrawColumn);
      if (smeColumn.BandIndex > -1) and (smeColumn.BandIndex < Bands.Count) then
      begin
        HRect := GetBandRect(DrawColumn.Index);

        HRect.Bottom := HRect.Top + DefaultRowHeight;

        InflateRect(HRect, -1, -1);
        DrawCellBackground(HRect, DrawColumn.Color, AState, ACol, ARow);
        InflateRect(HRect, 1, 1);

        if (GridStyle.Bands.Direction = fdNone) then
          Canvas.FillRect(HRect)
        else
          PlusDrawGradient(Canvas, HRect, GridStyle.Bands.StartColor, GridStyle.Bands.EndColor, GridStyle.Bands.Direction, 255);

        Canvas.Font.Assign(fBandsFont);
        InflateRect(HRect, -1, -1);

        ApplyStyleColors(Canvas);

        WriteTitleText(Canvas, HRect, 2, 2, Bands[smeColumn.BandIndex], taCenter, gvaCenter,
                       teNone,
                       eoTitleWordWrap in OptionsEx,
                       (BiDiMode <> bdLeftToRight)
                       );

        InflateRect(HRect, 1, 1);
        HRect.Bottom := HRect.Bottom+1;

      end;

      ARect.Top := ARect.Top + DefaultRowHeight + 1
    end;

    TitleText := DrawColumn.Title.Caption;

    {draw a column sorted image}
    if (ARect.Right-ARect.Left > j) then
    begin
      if (DrawColumn is TPlusDBColumn) and (TPlusDBColumn(DrawColumn).SortType <> stNone) then
        ARect.Right := ARect.Right-j;
    end;

    //draw title.caption
    if DefaultDrawing  and (TitleText <> '') then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Font := DrawColumn.Title.Font;

      ApplyStyleColors(Canvas);

      if not (eoTitleButtons in OptionsEx) then
        WriteTitleText(Canvas, ARect, 2, 2, TitleText, DrawColumn.Title.Alignment, GetVerticalAlignment(DrawColumn),
                       teNone,
                       eoTitleWordWrap in OptionsEx,
                       (BiDiMode <> bdLeftToRight));

      if (DrawColumn is TPlusDBColumn) and (TPlusDBColumn(DrawColumn).SortType <> stNone) then
      begin
        ARect.Right := ARect.Right+j;

        i := (ARect.Bottom - ARect.Top - j);
        i := i div 2;

        if (TPlusDBColumn(DrawColumn).SortType = stAscending) then
          Bmp := GetGridBitmap(gpSortAsc)
        else
          Bmp := GetGridBitmap(gpSortDesc);
        BRect := Bounds(ARect.Right - 4 - j, ARect.Top+i, j, j);
        Canvas.FillRect(BRect);
        DrawBitmapTransparent(Canvas, (BRect.Left + BRect.Right - Bmp.Width) div 2,
                                      (BRect.Top + BRect.Bottom - Bmp.Height) div 2, Bmp, clSilver);
        TitleText := TPlusDBColumn(DrawColumn).SortCaption;
        if (TitleText <> '') then
        begin
          BRect.Right := ARect.Right - 4;
          BRect.Left := BRect.Right - j;
          BRect.Top := ARect.Top + i;
          BRect.Bottom := ARect.Bottom;
          with Canvas.Font do
          begin
            Name := 'Segoe UI';
            Size := 9;
            Style := [];
          end;
          Canvas.Brush.Style := bsClear;
          DrawText(Canvas.Handle, PChar(TitleText), Length(TitleText),
                   BRect,
                   DT_EXPANDTABS or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
        end;
      end;
    end
  end;

var
  CheckState: TCheckBoxState;

  Down: Boolean;
  SavePen, BackColor: TColor;
  AField: TField;
  OldActive: Longint;
  FrameOffs: Byte;
  Indicator, ALeft: Integer;
  MultiSelected: Boolean;
  FixRect: TRect;
  DrawColumn: TColumn;
  BState: TGridDrawState;

  hhTheme: ThemeHandle;
  ColDrawn: Boolean;

  LColor: TColor;

const
  EdgeFlag: array[Boolean] of UINT = (BDR_RAISEDINNER, BDR_SUNKENINNER);
begin
  if (ARect.Right > ClientWidth) then
    ARect.Right := ClientWidth;

  Style := StyleServices;
  IsCustomStyle := TStyleManager.IsCustomStyleActive;
  if csLoading in ComponentState then
  begin
    if IsCustomStyle  and (seClient in StyleElements) then
      Canvas.Brush.Color := Style.GetStyleColor(scGrid)
    else
      Canvas.Brush.Color := Color;
    Canvas.FillRect(ARect);
    Exit;
  end;

  if (dgIndicator in Options) then
    BCol := ACol - 1
  else
    BCol := ACol;

  if BCol > -1 then
    DrawColumn := Columns[BCol]
  else
    DrawColumn := nil;

  if Assigned(DrawColumn) then
    Canvas.Font := DrawColumn.Font;

  if DrawColumn <> nil then
  begin
    if DrawColumn.Field <> nil then
      if not DrawColumn.Field.DataSet.Active then
        Exit;
  end;

  Down := False;

  if (gdFixed in AState) and
     (((ARow = 0) and (dgTitles in Options)) or
      ((ACol > -1) or ((ACol = 0) and (dgIndicator in Options)  ))) then
  begin

    ColDrawn := False;
    if StyleServices.Enabled  and (seClient in StyleElements)  then
    begin
      if StyleServices.GetElementColor(StyleServices.GetElementDetails(tgFixedCellNormal), ecFillColor, LColor) then
      begin
        if (Assigned(DrawColumn) and (LColor <> clNone) and (DrawColumn.Title.Color = FixedColor)) or
           (not Assigned(DrawColumn) ) then
          ColDrawn := True;
      end
    end;
    if ColDrawn then
    begin
      InflateRect(ARect, -1, -1);
      DrawCellBackground(ARect, FixedColor, AState, ACol, ARow);
      InflateRect(ARect, 1, 1);
    end;

    if (ACol = 0) and (dgIndicator in Options) then
    begin
      Down := False;
      Canvas.Brush.Color := FixedColor
    end
    else
    begin
      Down := (eoSelectedTitle in FOptionsEx) and (BCol = SelectedIndex);
      if Assigned(DrawColumn) then
        Canvas.Brush.Color := DrawColumn.Title.Color;
    end;
    if Flat then
      DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_FLAT)
    else
    begin
      DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_BOTTOMLEFT);
      DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_TOPRIGHT);
    end;

    if not ColDrawn then
    begin
      if ((ACol > 0) or not (dgIndicator in Options)) and
         IsXPThemesEnabled and
         (FInternalDrawingStyle = gdsThemed) and
         not (csDesigning in ComponentState) and
         (not Assigned(DrawColumn) or (DrawColumn.Title.Color = clBtnFace)) and
         (GridStyle.Title.Direction = fdNone) then
        hhTheme := OpenThemeData(0, 'Header')
      else
        hhTheme := 0;

      if (hhTheme <> 0) and
         (not Assigned(DrawColumn) or (Assigned(DrawColumn) and (ColorToRGB(DrawColumn.Title.Color) = ColorToRGB(FixedColor)))) then
      begin
        FixRect := ARect;
        try
          if IsMouseInRect(FixRect) then
          begin
            FLastXPDrawn := True;
            DrawThemeBackground(hhTheme, Canvas.Handle, HP_HEADERITEM, HIS_HOT, @ARect, nil)
          end
          else
            DrawThemeBackground(hhTheme, Canvas.Handle, HP_HEADERITEM, HIS_NORMAL, @ARect, nil);
        finally
          CloseThemeData(hhTheme);
        end;
      end
      else
      begin
        if (dgColLines in Options) then
        begin
          if not Flat then
            InflateRect(ARect, -1, -1);
        end;
        if (GridStyle.Title.Direction = fdNone) then
          Canvas.FillRect(ARect)
        else
          PlusDrawGradient(Canvas, ARect, GridStyle.Title.StartColor, GridStyle.Title.EndColor, GridStyle.Title.Direction, 255);
      end
    end;
    ColDrawn := False;
  end;

  if DefaultDrawing then
  begin
    j := GetSortImageWidth;
    if (ARow = 0) and (dgTitles in Options) and
       (ACol = 0) and
       (dgIndicator in Options)  then
    begin
      Canvas.Brush.Color := clBlack;
      i := (ARect.Bottom - ARect.Top - 7) div 2;
      idxSort := (ARect.Right - ARect.Left - 7) div 2;
      Canvas.Polygon([Point(ARect.Left + idxSort, ARect.Top + i),
                      Point(ARect.Left + idxSort + 7, ARect.Top + i),
                      Point(ARect.Left + idxSort + (7 div 2), ARect.Bottom - i)]);
    end
    else
    if Assigned(DrawColumn) then
    begin
      if (ARow = 0) and (dgTitles in Options) then
        DrawTitleColumn(DrawColumn)
      else
      begin
        BState := AState;
        if (eoFixedLikeColumn in OptionsEx) and
           (ACol > 0) and
           (ACol <= FixedCols) then
          AState := AState - [gdFixed];
          DefDrawCell(ACol, ARow, ARect, AState);
        AState := BState;
      end
    end;

  end;
  if Assigned(FOnDrawColumnTitle) then
    FOnDrawColumnTitle(Self, ARect, ACol, DrawColumn, AState)
  else
  begin
    if (eoTitleLines in OptionsEx) then
    begin
      if not (dgColLines in Options) then
      begin
        if (BiDiMode <> bdLeftToRight) then
        begin
          Canvas.MoveTo(ARect.Right - GridLineWidth + 1, ARect.Bottom - GridLineWidth);
          Canvas.LineTo(ARect.Right - GridLineWidth + 1, ARect.Top - GridLineWidth);
        end
        else
        begin
          Canvas.MoveTo(ARect.Right - GridLineWidth, ARect.Bottom - GridLineWidth);
          Canvas.LineTo(ARect.Right - GridLineWidth, ARect.Top - GridLineWidth);
        end;
      end;
      if not (dgRowLines in Options) then
      begin
        DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_BOTTOMLEFT)
      end;
    end;
  end;

    ColDrawn := False;

    if DefaultDrawing and
       (Datalink <> nil) and
       Datalink.Active and
       Assigned(DrawColumn) and
       Assigned(DrawColumn.Field) and
       (DrawColumn is TPlusDBColumn) and

       (((ARow > 0) and (dgTitles in Options)) or (not (dgTitles in Options))) then
    begin
      OldActive := DataLink.ActiveRecord;
      try
        DataLink.ActiveRecord := ARow - TitleOffset;

        try
          if (FixedCols > 0) and (ACol <= FixedCols) then
            BackColor := FixedColor
          else
          begin
            if HighlightCell(ACol, ARow, '', AState) then
              BackColor := clHighlight
            else
              BackColor := DrawColumn.Color;
            GetCellProps(ACol, DataLink.ActiveRecord, DrawColumn.Field, Canvas.Font, BackColor, HighlightCell(ACol, ARow, TitleText, AState));
          end;

          if Assigned(DataLink.DataSet) and (not DataLink.DataSet.IsEmpty) and Assigned(DrawColumn.Field) then
            TPlusDBColumn(DrawColumn).DrawItem(Canvas, ARect, DrawColumn.Field.Value, BackColor, AState, ColDrawn)
        except
        end
      finally
        DataLink.ActiveRecord := OldActive;
      end;
    end;

    if not ColDrawn then
    begin
      if (gdFixed in AState) then
      begin
        if Assigned(OnDrawColumnCell) and Assigned(DrawColumn) and
           not ((ARow = 0) and (dgTitles in Options)) then
        begin
          OldActive := DataLink.ActiveRecord;
          try
            DataLink.ActiveRecord := ARow - TitleOffset;

            OnDrawColumnCell(Self, ARect, ACol, DrawColumn, AState);
          finally
            DataLink.ActiveRecord := OldActive;
          end;
        end
      end
      else
      begin
        if GridStyle.IsDefaultBackground and
           not (eoCellWordWrap in OptionsEx) and
           (not Assigned(DrawColumn) or ((DrawColumn is TPlusDBColumn) and (TPlusDBColumn(DrawColumn).TextEllipsis = teNone))) then
          inherited DrawCell(ACol, ARow, ARect, AState)
        else
        begin
          inherited DrawCell(ACol, ARow, ARect, AState)
        end
      end;
    end;

  if (dgIndicator in Options) and (ACol = 0)
     and (ARow - TitleOffset >= 0)
     and (DataLink <> nil) and DataLink.Active then
  begin

    FixRect := ARect;
    if ([dgRowLines, dgColLines] * Options = [dgRowLines, dgColLines]) then
    begin
      InflateRect(FixRect, -1, -1);
      FrameOffs := 1;
    end
    else
      FrameOffs := 2;
    CheckState := cbUnChecked;
    OldActive := DataLink.ActiveRecord;
    try
      Datalink.ActiveRecord := ARow - TitleOffset;
      MultiSelected := ActiveRowSelected;
      if ActiveRowSelected then
        CheckState := cbChecked;

      Bmp := GetGlyph;
    finally
      Datalink.ActiveRecord := OldActive;
    end;

    if (eoCheckBoxSelect in OptionsEx) then
    begin
      BRect := FixRect;
      BRect.Right := BRect.Right - 2*FrameOffs - FMsIndicators.Width;
      DrawCheckBox(BRect, CheckState, taRightJustify);
    end;

    if (ARow - TitleOffset = DataLink.ActiveRecord) or MultiSelected then
    begin
      Indicator := 0;
      if DataLink.DataSet <> nil then
        case DataLink.DataSet.State of
          dsEdit: Indicator := 1;
          dsInsert: Indicator := 2;
          dsBrowse:
            if MultiSelected then
              if (ARow - TitleOffset <> Datalink.ActiveRecord) then
                Indicator := 3
              else
                Indicator := 4;
        end;

      if IsCustomStyle and (seClient in StyleElements)  then
        FMsIndicators.BkColor := Style.GetStyleColor(scGrid)
      else
        FMsIndicators.BkColor := FixedColor;

      ALeft := ARect.Right - FMsIndicators.Width - FrameOffs;
      if Canvas.CanvasOrientation = coRightToLeft then
        Inc(ALeft);

      FMsIndicators.Draw(Canvas, ALeft,
        (ARect.Top + ARect.Bottom - FMsIndicators.Height) shr 1, Indicator{, True});
    end;
    if (Bmp <> nil) then
    begin
      BRect.Left := FixRect.Left + FrameOffs;
      BRect.Top := FixRect.Top + FrameOffs;
      if (bmp.Width < FixRect.Right - FixRect.Left) then
        BRect.Right := BRect.Left + bmp.Width
      else
        if (eoCheckBoxSelect in OptionsEx) then
          BRect.Right := FixRect.Right - FCheckWidth - FrameOffs
        else
          BRect.Right := FixRect.Right - FMsIndicators.Width - FrameOffs;
      BRect.Bottom := FixRect.Bottom - FrameOffs;
      Canvas.StretchDraw(BRect, bmp);
      bmp.Free;
    end;
  end;
  if (eoTitleButtons in OptionsEx) and
     not (csLoading in ComponentState) and
     (gdFixed in AState) and
     (dgTitles in Options) and (ARow = 0) then
  begin
    SavePen := Canvas.Pen.Color;
    try
      Down := (FPressedCol = ACol) and FPressed;
      Canvas.Pen.Color := clWindowFrame;
      if not (dgColLines in Options) then
      begin
        Canvas.MoveTo(ARect.Right - 1, ARect.Top);
        Canvas.LineTo(ARect.Right - 1, ARect.Bottom);
        Dec(ARect.Right);
      end;
      if not (dgRowLines in Options) then
      begin
        Canvas.MoveTo(ARect.Left, ARect.Bottom - 1);
        Canvas.LineTo(ARect.Right, ARect.Bottom - 1);
        Dec(ARect.Bottom);
      end;
      if (dgIndicator in Options) then Dec(ACol);
      AField := nil;
      if (DataLink <> nil) and DataLink.Active and (ACol >= 0) and
        (ACol < Columns.Count) then
      begin
        DrawColumn := Columns[ACol];
        AField := DrawColumn.Field;
      end
      else
        DrawColumn := nil;

      if Flat then
        DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_FLAT)
      else
      begin
        DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_BOTTOMRIGHT);
        DrawEdge(Canvas.Handle, ARect, EdgeFlag[Down], BF_TOPLEFT);
      end;
      InflateRect(ARect, -1, -1);
      if Down then
      begin
        Inc(ARect.Left);
        Inc(ARect.Top);
      end;
      Canvas.Font := TitleFont;
      Canvas.Brush.Color := FixedColor;
      if (DrawColumn <> nil) then
      begin
        Canvas.Font := DrawColumn.Title.Font;
        Canvas.Brush.Color := DrawColumn.Title.Color;
      end;
      if (AField <> nil) and Assigned(FOnGetBtnParams) then
      begin
        BackColor := Canvas.Brush.Color;
        FOnGetBtnParams(Self, AField, Canvas.Font, BackColor, Down);
        Canvas.Brush.Color := BackColor;
      end;
      if (DataLink = nil) or not DataLink.Active then
        Canvas.FillRect(ARect)
      else
        if (DrawColumn <> nil) then
          WriteTitleText(Canvas, ARect, 2, 2, DrawColumn.Title.Caption, Columns[BCol].Title.Alignment, GetVerticalAlignment(Columns[BCol]),
                         teNone,
                         eoTitleWordWrap in OptionsEx,
                         (BiDiMode <> bdLeftToRight))
        else
          WriteTitleText(Canvas, ARect, 2, 2, '', taLeftJustify, gvaCenter,
                         teNone,
                         (eoCellWordWrap in OptionsEx),
                         (BiDiMode <> bdLeftToRight)
                         );
    finally
      Canvas.Pen.Color := SavePen;
    end;
  end;

end;

function TDBGridPlus.ApplyBackroundColorToCanvas(DataCol, ARow: Integer; AColumn: TColumn; State: TGridDrawState): TColor;
var
  Highlight: Boolean;
  Field: TField;
  LColor: TColor;
begin
  if not Assigned(AColumn) then
    exit;

  Field := AColumn.Field;
  Highlight := (gdSelected in State) and
               ((dgAlwaysShowSelection in Options) or Focused);
  if (gdFixed in State) then
  begin
    Canvas.Font := AColumn.Title.Font;
    Result := AColumn.Title.Color;
  end
  else
  begin
    if Highlight or
       (Assigned(DataLink.DataSet) and (not DataLink.DataSet.IsEmpty) and Assigned(Field) and HighlightCell(DataCol, DataLink.ActiveRecord, Field.AsString, State)) then
    begin
      if not Focused then
        Result := clInactiveCaption
      else
        Result := clHighlight;
      Canvas.Font.Color := clHighlightText;

      if StyleServices.Enabled then
      begin
        if (seClient in StyleElements) and
           StyleServices.GetElementColor(StyleServices.GetElementDetails(tgClassicCellSelected), ecFillColor, LColor) and
           (LColor <> clNone) then
          Result := LColor;
        if  (seFont in StyleElements) and
           StyleServices.GetElementColor(StyleServices.GetElementDetails(tgClassicCellSelected), ecTextColor, LColor) and
           (LColor <> clNone) then
          Canvas.Font.Color := LColor;
      end;
    end
    else
    begin
      Canvas.Font := AColumn.Font;
      if (AColumn.Color = AColumn.DefaultColor) then
        Result := Canvas.Brush.Color
      else
        Result := AColumn.Color;

      if StyleServices.Enabled and (Result = StyleServices.GetStyleColor(scGrid)) and (seClient in StyleElements)  then
      begin
        if StyleServices.GetElementColor(StyleServices.GetElementDetails(tgCellNormal), ecFillColor, LColor) and
           (LColor <> clNone) then
          Result := LColor;
      end;

    end
  end;
  GetCellProps(AColumn.Index, ARow, Field, Canvas.Font, Result, Highlight or ActiveRowSelected);

end;

procedure TDBGridPlus.DrawColumnCell(const Rect: TRect; DataCol: Integer;
  Column: TColumn; State: TGridDrawState);
const
  RowColors: array[Boolean] of TColor = (clSilver, clWhite);
  RowSelectedColors: array[Boolean] of TColor = (clHotLight, clHighlight);
var
  Check                       : Integer;
  i                           : Integer;
  Highlight, ColumnDrawn      : Boolean;
  Bmp                         : TBitmap;
  Field                       : TField;

  RectLookup                  : TRect;
  W, intMidX, intMidY         : Integer;
  CheckState                  : TCheckBoxState;
  Value                       : String;

begin
  Field := Column.Field;
  if Field = nil then
    exit;

  if not (gdSelected in State) then
  begin
    if Column.Field.DataSet.RecNo mod 2 = 1 then
      Canvas.Brush.Color := GridStyle.EvenColor
    else
      Canvas.Brush.Color := GridStyle.OddColor;

    DefaultDrawColumnCell(Rect, DataCol, Column, State);
  end;

  if ColumnIsCheckbox(Column) then
  begin
    Canvas.FillRect(Rect);
    CheckState := GetCheckBoxValue(Column.Field, Column.Field.Value, '', Column);
    DrawCheckBox(Rect, CheckState, taCenter);
    ColumnDrawn := True;
  end;
  inherited;

end;

function TDBGridPlus.GetRecordCount: Integer;
var
  i: Integer;
begin
  i := DataLink.DataSet.RecordCount;
  if Assigned(OnGetRecordCount) then
    OnGetRecordCount(Self, i);
  Result := i;
end;

procedure TDBGridPlus.ChangeScale(M, D: Integer);

  procedure BackupColumnsWidth(out ColumnsWidth: TArray<Integer>);
  var
    I: Integer;
  begin
    SetLength(ColumnsWidth, Columns.Count);
    for I := 0 to Columns.Count - 1 do
      ColumnsWidth[I] := Columns[I].Width;
  end;

  procedure RestoreColumnsWidth(ColumnsWidth: TArray<Integer>);
  var
    I: Integer;
  begin
    for I := 0 to Columns.Count - 1 do
      Columns[I].Width := ColumnsWidth[I];
  end;

var
  ColumnsWidth: TArray<Integer>;
begin
  BackupColumnsWidth(ColumnsWidth);
  inherited ChangeScale(M, D);
  RestoreColumnsWidth(ColumnsWidth);
end;

function TDBGridPlus.GetColumns: TDBGridPlusColumns;
begin
  Result := TDBGridPlusColumns(inherited Columns)
end;

procedure TDBGridPlus.SetColumns(Value: TDBGridPlusColumns);
begin
  TDBGridPlusColumns(Columns).Assign(Value)
end;

function IsXPThemesEnabled: Boolean;
begin
  Result := False; // remover
end;

procedure TDBGridPlus.UpdateColWidths;
var
  i                   : Integer;
  aColunas            : Array of TColunas;
  oClientMetrics      : TNonClientMetrics;
  nLarguraColunas     : Integer;
  nLarguraGrid        : Integer;
  nLarguraCol         : Integer;
  nStartPoint         : Integer;
  nPosicao            : Integer;
  nQtdeColunas        : Integer;
  nQtde               : Integer;
  nColunaID           : Integer;
  nLargMaxima         : Integer;

begin
  nPosicao       := 0;
  nLarguraCol    := 0;
  nQtdeColunas   := 0;
  nQtde          := 0;
  nColunaID      := 0;
  nLargMaxima    := 0;
  nLarguraGrid   := 0;

  if not (eoAutoWidth in OptionsEx) then
    Exit;

  if  (ColCount > 0)
     and not  (csDestroying in ComponentState)
     and not  (csReading in ComponentState)
     and not  (csLoading in ComponentState)
     and not  (FAutoFitIsLocked)
     and      (UpdateLock = 0)
     and      (LayoutLock = 0) then
  begin
    FAutoFitIsLocked := True;

    try
      // ----------------------------------------------------------------------------------------------
      // Pegar a largura da area da Grid
      // ----------------------------------------------------------------------------------------------
      FillChar(oClientMetrics, SizeOf(oClientMetrics), 0);
      oClientMetrics.cbSize := SizeOf(oClientMetrics);
      SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(oClientMetrics), @oClientMetrics, 0);

      // Get the Client Width
      nLarguraGrid := Width - (oClientMetrics.iBorderWidth * 2) - (GridLineWidth* (ColCount + 1));

      // Subtract the Scrollbar's width from the total width if there is a scrollbar.
      if (GetWindowlong(Self.Handle, GWL_STYLE) and WS_VSCROLL) <> 0 then
        nLarguraGrid := nLarguraGrid - oClientMetrics.iScrollWidth;

      // Subtract the indicator if it is being used
      if dgIndicator in Options then
      begin
        nStartPoint := 1;
        nLarguraGrid := nLarguraGrid - WidthOfIndicator;
      end
      else
        nStartPoint := 0;

      // ----------------------------------------------------------------------------------------------
      // Mapear colunas (somente as Visiveis e Auto Width).
      // ----------------------------------------------------------------------------------------------
      nQtdeColunas := 0;
      for i := 0 to Columns.Count-1 do
      begin
        if Columns[i].Visible then
        begin
          //if Columns[i].ColAutoWidth then
          if Columns[i].ColunaAjuste.ColAutoWidth then
          begin
            if Trim(Columns[i].Title.Caption) <> '' then
            begin
              SetLength(aColunas, length(aColunas) + 1);
              aColunas[high(aColunas)].Limpar;
              aColunas[high(aColunas)].Coluna        := i;
              aColunas[high(aColunas)].Caption       := Columns[i].Title.Caption;
              aColunas[high(aColunas)].AutoAjustar   := Columns[i].ColunaAjuste.ColAutoWidth;
              aColunas[high(aColunas)].ColMinSize    := Columns[i].ColunaAjuste.ColMinSize;
              aColunas[high(aColunas)].ColMaxSize    := Columns[i].ColunaAjuste.ColMaxSize;
              aColunas[high(aColunas)].Width         := Columns[i].Width;
              aColunas[high(aColunas)].LarguraMaxima := 0;

              Inc(nQtdeColunas);
            end;
          end
          else
          begin
            nLarguraGrid := nLarguraGrid - Columns[i].Width; // Desconto as colunas que não estão definidas como "AutoWidth = True";
          end;
        end
      end;

      // ----------------------------------------------------------------------------------------------
      // Calcular quanto deve ser a largura de cada coluna (definido como Auto Width).
      // ----------------------------------------------------------------------------------------------
      nQtdeColunas := ifthen(nQtdeColunas < 1, 1, nQtdeColunas);
      nLarguraCol  := (nLarguraGrid div nQtdeColunas);

      // ----------------------------------------------------------------------------------------------
      // Após todo processo acima, redimensionar as colunas que foram configuradas.
      // ----------------------------------------------------------------------------------------------
      nLargMaxima := 0;
      nColunaID   := 0;
      nPosicao    := 0;
      for i := low(aColunas) to high(aColunas)  do
      begin
        nLargMaxima := 0;
        nColunaID   := aColunas[i].Coluna;
        nPosicao    := nColunaID + nStartPoint;
        nLargMaxima := nLarguraCol;

        if (nLarguraCol < aColunas[i].ColMinSize) then
        begin
          nLargMaxima := aColunas[i].ColMinSize;
        end;

        ColWidths[nPosicao]       := nLargMaxima;
        Columns[nColunaID].Width  := nLargMaxima;
      end;
    finally
      FAutoFitIsLocked := False;
    end;
  end;
end;

procedure TDBGridPlus.AjustarTamanhoMinimo;
var
  i                   : Integer;
begin
  // ---------------------------------------------------------------------------------
  // Auto ajustar ao final
  // ---------------------------------------------------------------------------------

  if (csLoading in ComponentState) then
    Exit;

  if  ColCount < 1 then
    Exit;

  for i := 0 to Columns.Count - 1 do
  begin
    if Columns[i].Width < Columns[i].ColunaAjuste.ColMinSize  then
    begin
      Columns[i].Width := Columns[i].ColunaAjuste.ColMinSize;
    end;
  end;

end;

procedure TDBGridPlus.ConfigurarMascara;
var
  i         : Integer;
  Mascara   : String;
begin
  Mascara := '';
  if  ColCount < 1 then
    Exit;

  // --------------------------------------------------------
  // Formatar Mascara
  // --------------------------------------------------------
  for i := 0 to Columns.Count - 1 do
  begin
    if Columns[i] <> nil then
    begin
      if Columns[i].Field <> nil then
      begin
        if (Columns[i].Field.DataType in [ftDate, ftDateTime, ftTime]) then
        begin
          Mascara := TDateTimeField(Columns[i].Field.DataSet.FieldByName(Columns[i].Field.fieldname)).DisplayFormat;
          if (Mascara <> Columns[i].DisplayFormat) then
          begin
            TDateTimeField(Columns[i].Field.DataSet.FieldByName(Columns[i].Field.fieldname)).DisplayFormat := Columns[i].DisplayFormat;
          end;
        end
        else if (Columns[i].Field.DataType in [ftBCD, ftFMTBcd, ftFloat, ftSmallInt,  ftInteger, ftSingle, ftCurrency, ftExtended, ftByte]) then
        begin
          Mascara := TNumericField(Columns[i].Field.DataSet.FieldByName(Columns[i].Field.fieldname)).DisplayFormat;
          if (Mascara <> Columns[i].DisplayFormat) then
            TNumericField(Columns[i].Field.DataSet.FieldByName(Columns[i].Field.fieldname)).DisplayFormat := Columns[i].DisplayFormat;
        end;
      end;
    end;
  end;

end;

procedure TDBGridPlus.AjustarTamanhoMaximo;
var
  i : Integer;
begin

  // ---------------------------------------------------------------------------------
  // Auto ajustar ao final
  // ---------------------------------------------------------------------------------
  if (csLoading in ComponentState) then
    Exit;

  if  ColCount < 1 then
    Exit;

  for i := 0 to Columns.Count - 1 do
  begin
    if not Columns[i].ColunaAjuste.ColAutoWidth then
    begin
      if Columns[i].ColunaAjuste.ColMaxSize < 1 then
        Continue;

      if Columns[i].Width > Columns[i].ColunaAjuste.ColMaxSize  then
        Columns[i].Width := Columns[i].ColunaAjuste.ColMaxSize;

    end;
  end;
end;

procedure LoadXPThemeAPI;
var
  iErrorMode: Integer;
begin
  FThemeAPILoaded := False;

  if (GetFileVersion(comctl32) < ComCtlVersionIE6) then exit;

  iErrorMode := SetErrorMode(SEM_NOOPENFILEERRORBOX);
  hThemeAPI := LoadLibrary(UX_Theme_DLL);
  SetErrorMode(iErrorMode);

  if (hThemeAPI <> 0) then
  begin
    @OpenThemeData := GetProcAddress(hThemeAPI, 'OpenThemeData');
    @CloseThemeData := GetProcAddress(hThemeAPI, 'CloseThemeData');

    @DrawThemeBackground := GetProcAddress(hThemeAPI, 'DrawThemeBackground');

    @IsThemeActive := GetProcAddress(hThemeAPI, 'IsThemeActive');
    @IsAppThemed := GetProcAddress(hThemeAPI, 'IsAppThemed');

    FThemeAPILoaded := True;
  end;
end;

procedure UnloadXPThemeAPI;
begin
  if FThemeAPILoaded then
  begin
    FThemeAPILoaded := False;
    FreeLibrary(hThemeAPI);
  end;
end;

{ TGridPlusColumnCheckBox }

procedure TGridPlusColumnCheckBox.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
end;

constructor TGridPlusColumnCheckBox.Create(Column: TPlusDBColumn);
begin
  inherited Create;
  FColumn           := Column;
  FCheckedValue     := 'S';
  FUnCheckedValue   := 'N';
  FGrayedValue      := 'U';
end;

destructor TGridPlusColumnCheckBox.Destroy;
begin
  inherited Destroy;
end;

{ TColunaAjuste }

procedure TColunaAjuste.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
end;

constructor TColunaAjuste.Create(Column: TPlusDBColumn);
begin
  inherited Create;
  FColumn           := Column;

  FColAutoWidth    := False;
  FColMinSize      := _MIN_COLMINSIZE;
  FColMaxSize      := 0;
end;

destructor TColunaAjuste.Destroy;
begin
  inherited Destroy;
end;

procedure TColunaAjuste.SetColAutoWidth(const Value: Boolean);
begin
  FColAutoWidth := Value;

  FColumn.Changed(False);
  FColumn.Grid.UpdateColWidths;
end;

procedure TColunaAjuste.SetColMaxSize(const Value: Integer);
begin
  FColMaxSize := Value;

  if FColMaxSize < 1 then
    Exit;

  if FColMaxSize < FColMinSize then // Não aceitar se tentar colocar tamanho menor que o minimo definido.
  begin
    ShowMessage('Propriedade ColMaxSize deve ser maior ColMinSize. ');
    FColMaxSize := 0;
    Exit;
  end;

  if FColumn.Width < 1 then
  begin
    FColumn.Grid.AjustarTamanhoMinimo;
    Exit;
  end;

  if FColumn.Width > FColMaxSize then
  begin
    FColumn.Width := FColMaxSize;
    FColumn.Changed(False);
    FColumn.Grid.AjustarTamanhoMaximo;
  end;

end;

procedure TColunaAjuste.SetColMinSize(const Value: Integer);
begin
  FColMinSize := Value;
  FColMinSize := Value;
  if Value < _MIN_COLMINSIZE then
    FColMinSize := _MIN_COLMINSIZE;

  if FColumn.Width < FColMinSize then
  begin
    FColumn.Width := FColMinSize;
    FColumn.Changed(False);
    FColumn.Grid.AjustarTamanhoMinimo;
  end;

end;

end.

