{---------------------------------------------------------------------------+
|                                                                           |
|  Unit.........: DBGridPlus.pas                                            |
|  Componente...: "DBGridPlus"                                              |
|  Descrição....: Tipos e constantes                                        |
|  Data.........: 15/07/2024 - 22:03h                                       |
|  Autoria......: Adriano Zanini                                            |
|                                                                           |
+---------------------------------------------------------------------------}

unit DBGridPlusConst;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Data.DB, System.UITypes;

Type

  TColunas = Record
    Coluna            : Integer;
    Caption           : String;
    AutoAjustar       : Boolean;
    ColMinSize        : Integer;
    ColMaxSize        : Integer;
    Width             : Integer;
    LarguraMaxima     : Integer;

    procedure Limpar();
  end;

  TOptionsEx    = set of (eoAutoLoadLayout,
                          eoAutoSaveLayout,
                          eoAutoWidth,
                          eoBandsActive,
                          eoBandsOverTitles,
                          eoBooleanAsCheckBox,
                          eoCellHint,
                          eoCellWordWrap,
                          eoCheckBoxSelect,
                          eoDisableDelete,
                          eoDisableInsert,
                          eoEnterToTab,
                          eoFixedLikeColumn,
                          eoHotTrack,
                          eoKeepSelection,
                          eoRowHeightAutofit,
                          eoRowSizing,
                          eoSelectedTitle,
                          eoShowFooter,
                          eoShowGlyphs,
                          eoTitleButtons,
                          eoTitleLines,
                          eoTitleWordWrap
                          );


  TPlusGradientDirection = (fdNone, fdTopToBottom, fdBottomToTop, fdLeftToRight, fdRightToLeft);

  TPlusSortType = (stNone, stAscending, stDescending);
  TPlusInplaceEditorType = (ieNormal, ieProgressbar, ieCheckbox);

  TPlusFooterType = (ftCustom, ftSum, ftCount, ftAverage, ftMin, ftMax);
  TPlusTextEllipsis = (teNone, teEnd, teMiddle);

  TPlusGVerticalAlignment = (gvaTop, gvaCenter, gvaBottom);

  TPlusDBGTitleHeightKind  = (hkAuto, hkLineCount, hkPixelCount);
  TPlusString              = String;
  TStyleColorGrid          = (gsNormal, gsCustom, gsPriceList, gsMSMoney, gsBrick, gsDesert, gsEggplant, gsLilac, gsMaple, gsMarine, gsRose, gsSpruce, gsWheat, gsSoftWheat, gsSoftRose, gsAquaBlue, gsSoftMaple, gsSoftLilac, gsSoftDesert, gsSoftEggPlant, gsSoftBrick, gsSoftSpruce, gsSoftYellowGreen, gsSoftGray);

  ThemeHandle   = THandle;
  TGridPicture  = (gpBlob, gpMemo, gpPicture, gpOle, gpSortAsc, gpSortDesc);

  TCheckTitleBtnEvent = procedure (Sender: TObject; ACol: Longint; Field: TField; var Enabled: Boolean) of object;
  TGetCellParamsEvent = procedure (Sender: TObject; Field: TField; AFont: TFont; var Background: TColor; Highlight: Boolean) of object;
  TGetBtnParamsEvent  = procedure (Sender: TObject; Field: TField; AFont: TFont; var Background: TColor; IsDown: Boolean) of object;

  TGetGlyphEvent      = procedure (Sender: TObject; var Bitmap: TBitmap) of object;
  TGetCellHint        = procedure (Sender: TObject; Column: TColumn; var HintStr: string;
                           var HintInfo: THintInfo) of object;

  TGetRecordCountEvent = procedure (Sender: TObject; var RecordCount: Integer) of object;
  TPlusSortChangedEvent  = procedure (Sender: TObject; Column: TColumn) of object;

  TOnFilterApply = procedure (Sender: TObject; Field: TField; const FilterString: string; var Accept: boolean) of object;

  //----------------------------------------------------------
  TGridPlusRGBArray      = array[0..2] of byte;
  TGridPlusFactorArray   = array[0..2] of integer;
  TGridPlusGradientStyle = (gsHorizontal, gsVertical, gsHorzCenter, gsVertCenter, gsElliptic, gsRectangle);
  TGridPlusTabBevel      = (tgRaised, tgLowered, tgFlat);

  TGridPlusTabFillStyle = (tfColor, tfGradient, tfTexture);

const

  strMessage        = 'Imprimir...';
  strSaveChanges    = 'Deseja realmente salvar alterações no Servidor de Banco de Dados?';
  strErrSaveChanges = 'Não foi possível salvar um dado! Verifique a conexão com o Servidor ou validação de dados.';
  strDeleteWarning  = 'Deseja realmente excluir a tabela %s?';
  strEmptyWarning   = 'Deseja realmente esvaziar a tabela %s?';



  SgbTitle = ' Titulo ';
  SgbData = ' Data ';
  STitleCaption = 'Legenda:';
  STitleAlignment = 'Alinhamento:';
  STitleColor = 'Cor:';
  STitleFont = 'Fonte:';
  SWidth = 'Largura:';
  SWidthFix = 'Fixos';
  SAlignLeft = 'esquerda';
  SAlignRight = 'direita';
  SAlignCenter = 'centro';


  strEqual = 'igual';
  strNonEqual = 'diferente';
  strNonMore = 'não maior';
  strNonLess = 'não menor';
  strLessThan = 'menor que';
  strLargeThan = 'maior que';
  strExist = 'vazio';
  strNonExist = 'preenchido';
  strIn = 'na lista';
  strBetween = 'entre';
  strLike = 'parecido';

  strOR = 'OU';
  strAND = 'E';

  strField = 'Campo';
  strCondition = 'Condição';
  strValue = 'Valor';

  strAddCondition = ' defina a condição adicional:';
  strSelection = ' escolha os regritro pelo próxima condição:';

  strAddToList = 'incluir na lista';
  strEditInList = 'Editar a lista';
  strDeleteFromList = 'Excluir da lista';

  strTemplate = 'Dialogo de filtro padrão';
  strFLoadFrom = 'Carregar de...';
  strFSaveAs = 'Salvar como...';
  strFDescription = 'descrição';
  strFFileName = 'Arquivo';
  strFCreate = 'Criado: %s';
  strFModify = 'Modificado: %s';
  strFProtect = 'Somente leitura';
  strFProtectErr = 'Arquivo esta protegido!';


  SFirstRecord = 'Primeiro registro';
  SPriorRecord = 'Registro anterior';
  SNextRecord = 'Próximo registro';
  SLastRecord = 'Último registro';
  SInsertRecord = 'Inserir registro';
  SCopyRecord = 'Copiar registro';
  SDeleteRecord = 'Excluir registro';
  SEditRecord = 'Alterar registro';
  SFilterRecord = 'Condições de filtragem';
  SFindRecord = 'Localizar registro';
  SPrintRecord = 'Imprimir registros';
  SExportRecord = 'Exportar registros';
  SImportRecord = 'Importar os registros';
  SPostEdit = 'Salvar alterações';
  SCancelEdit = 'Cancelar alterações';
  SRefreshRecord = 'Atualizar dados';
  SChoice = 'Escolher registro';
  SClear = 'Limpar escolha de registro';
  SDeleteRecordQuestion = 'Excluir registro?';
  SDeleteMultipleRecordsQuestion = 'Deseja realmente excluir?';
  SRecordNotFound = 'Registro não encontrado';

  SFirstName = 'Primeiro';
  SPriorName = 'Anterior';
  SNextName = 'Próximo';
  SLastName = 'Último';
  SInsertName = 'Inserir';
  SCopyName = 'Copiar';
  SDeleteName = 'Excluir';
  SEditName = 'Alterar';
  SFilterName = 'Filtrar';
  SFindName = 'Localizar';
  SPrintName = 'Imprimir';
  SExportName = 'Exportar';
  SImportName = 'Importar';
  SPostName = 'Salvar';
  SCancelName = 'Cancelar';
  SRefreshName = 'Atualizar';
  SChoiceName = 'Escolher';
  SClearName = 'Limpar';

  SBtnOk = '&OK';
  SBtnCancel = '&Cancelar';
  SBtnLoad = 'Carregar';
  SBtnSave = 'Salvar';
  SBtnCopy = 'Copiar';
  SBtnPaste = 'Colar';
  SBtnClear = 'Limpar';

  SRecNo = '#';
  SRecOf = ' de ';


  etValidNumber = 'número válido';
  etValidInteger = 'número inteiro válido';
  etValidDateTime = 'data/hora válida';
  etValidDate = 'data válida';
  etValidTime = 'hora válida';
  etValid = 'válido';
  etIsNot = 'não é um';
  etOutOfRange = 'Valor %s está fora dos limites %s..%s';
  SApplyAll = 'Aplicar em todos';

  SNoDataToDisplay = '<sem registros>';

  SPrevYear = 'ano anterior';
  SPrevMonth = 'mês anterior';
  SNextMonth = 'próximo mês';
  SNextYear = 'próximo mês';

  _MIN_COLMINSIZE = 20;

  _FOOTER_TROCA_STRING = '%total%';

  UX_Theme_DLL = 'uxtheme.dll';



  ComCtlVersionIE3 = $00040046;
  ComCtlVersionIE4 = $00040047;
  ComCtlVersionIE401 = $00040048;
  ComCtlVersionIE5 = $00050050;
  ComCtlVersionIE501 = $00050051;
  ComCtlVersionIE6 = $00060000;

  bmArrow = 'SM_DBGARROW';
  bmEdit = 'SM_DBGEDIT';
  bmInsert = 'SM_DBGINSERT';
  bmMultiDot = 'SM_MSDOT';
  bmMultiArrow = 'SM_MSARROW';

  FILTERBAR_HEIGHT = 25;

  clCream         = TColor($A6CAF0);
  clMoneyGreen    = TColor($C0DCC0);
  clSkyBlue       = TColor($FFFBF0);

var
  FThemeAPILoaded              : Boolean;
  hThemeAPI                    : THandle;
  IsThemeActive                : function: BOOL stdcall;
  IsAppThemed                  : function: BOOL stdcall;
  OpenThemeData                : function(hWnd:THandle; pszClassList: LPCWSTR): ThemeHandle stdcall;
  CloseThemeData               : function(hTheme:ThemeHandle): HResult stdcall;
  DrawThemeBackground          : function(hTheme:ThemeHandle; hdc: HDC; iPartId: Integer; iStateId: Integer; const pRect: PRect; const pClipRect: PRect): HResult stdcall;
  FCheckWidth, FCheckHeight    : Integer;
  FrmBlobEdit                  : TForm;
  GridBmpNames                 : array[TGridPicture] of PChar = ('SM_BLOB', 'SM_MEMO', 'SM_PICT', 'SM_OLE', 'SM_ARROWASC', 'SM_ARROWDESC');
  GridBitmaps                  : array[TGridPicture] of TBitmap = (nil, nil, nil, nil, nil, nil);


implementation

{ TColunas }
procedure TColunas.Limpar;
begin
  Coluna            := 0;
  Caption           := '';
  AutoAjustar       := False;
  ColMinSize        := 0;
  Width             := 0;
  LarguraMaxima     := 0;
end;

end.
