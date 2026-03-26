unit FPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, System.IOUtils,
  FireDAC.Comp.Client, FireDAC.Phys.IBBase, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.DBGrids, System.ImageList, Vcl.ImgList, DBGridPlus, Vcl.DBCtrls,
  Datasnap.DBClient, System.Generics.Collections, Vcl.Menus, Vcl.ComCtrls,
  FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef;

type
  TFrmPrincipal = class(TForm)
    DBConexao: TFDConnection;
    FDTransacao: TFDTransaction;
    FDPhysFBDriverLink: TFDPhysFBDriverLink;
    Panel1: TPanel;
    Button1: TButton;
    btnAbrirFechar: TButton;
    Button3: TButton;
    DBLookupComboBox1: TDBLookupComboBox;
    qryDocumentos: TFDQuery;
    dsDocumentos: TDataSource;
    ClientDataSet1: TClientDataSet;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    DBGrid1: TDBGrid;
    GridDados: TDBGridPlus;
    PopupMenu1: TPopupMenu;
    A1: TMenuItem;
    A2: TMenuItem;
    v1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnAbrirFecharClick(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure A1Click(Sender: TObject);
    procedure A2Click(Sender: TObject);
    procedure v1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

procedure TFrmPrincipal.Button1Click(Sender: TObject);
begin
  GridDados.CalculateTotals;
end;

procedure TFrmPrincipal.Button3Click(Sender: TObject);
begin
  GridDados.FixedCols := 1;
end;

procedure TFrmPrincipal.DBGrid1DrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  {
  if not odd(Column.Field.DataSet.RecNo) then
  begin
    //if not (gdSelected in State) then
    if not (gdFocused in State) then
      begin
      DBGrid1.Canvas.Brush.Color := clMoneyGreen;
      DBGrid1.Canvas.FillRect(Rect);
      DBGrid1.DefaultDrawDataCell(rect,Column.Field,state);
    end;
  end;
  }

  if not (gdSelected in State) then
  begin
    if Column.Field.DataSet.RecNo mod 2 = 1 then
      DBGrid1.Canvas.Brush.Color := clAqua
    else
      DBGrid1.Canvas.Brush.Color := clMoneyGreen;
  end;
  DBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TFrmPrincipal.A1Click(Sender: TObject);
begin
  ShowMessage('A');
end;

procedure TFrmPrincipal.A2Click(Sender: TObject);
begin
  ShowMessage('B');

end;

procedure TFrmPrincipal.btnAbrirFecharClick(Sender: TObject);
begin
  qryDocumentos.Active := not qryDocumentos.Active;
  if qryDocumentos.Active then
    btnAbrirFechar.Caption := 'Fechar Tabela'
  else
    btnAbrirFechar.Caption := 'Abrir Tabela';

end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  PageControl1.TabIndex := 0;
  DBConexao.Close;
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  qryDocumentos.Open;
end;

procedure TFrmPrincipal.v1Click(Sender: TObject);
begin
  ShowMessage('V');
end;

end.
