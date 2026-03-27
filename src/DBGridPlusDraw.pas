{---------------------------------------------------------------------------+
|                                                                           |
|  Unit.........: DBGridPlus.pas                                            |
|  Componente...: "DBGridPlus"                                              |
|  Descrição....: Configurações para cores das grids                        |
|  Data.........: 15/07/2024 - 22:03h                                       |
|  Autoria......: Adriano Zanini                                            |
|                                                                           |
+---------------------------------------------------------------------------}

unit DBGridPlusDraw;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Data.DB, System.UITypes,
  Vcl.GraphUtil,
  DBGridPlusConst;

type

  TGridPlusGradient = class(TPersistent)
  private
    FOwner: TControl;
    FBeginColor: TColor;
    FEndColor: TColor;
    FStyle: TGridPlusGradientStyle;
    FOnGradientChange: TNotifyEvent;

    procedure SetBeginColor(const Value: TColor);
    procedure SetEndColor(const Value: TColor);
    procedure SetStyle(const Value: TGridPlusGradientStyle);

  protected
    procedure DoGradientChange; dynamic;
    procedure DrawHorzGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure DrawHorzCenterGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure DrawVertGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure DrawVertCenterGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure DrawEllipticGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure DrawRectangleGradient(Dest: TBitmap; RGBBegin, RGBDif: TGridPlusRGBArray; Factor:TGridPlusFactorArray); dynamic;
    procedure FillBitmap(Bitmap: TBitmap; AColor: TColor); dynamic;
    procedure PrepareRGB(ABeginColor, AEndColor: TColor; var RGBBegin, RGBEnd, RGBDif: TGridPlusRGBArray; var Factor: TGridPlusFactorArray); dynamic;
    property Owner: TControl read FOwner write FOwner;

  public
    constructor Create(AOwner: TControl); dynamic;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure DrawGradient(Bitmap: TBitmap; SwapColors: boolean);

    property OnGradientChange: TNotifyEvent read FOnGradientChange write FOnGradientChange;

  published
    property BeginColor: TColor read FBeginColor write SetBeginColor  default clBtnFace;
    property EndColor: TColor read FEndColor write SetEndColor default clActiveCaption;
    property Style: TGridPlusGradientStyle read FStyle write SetStyle default gsRectangle;
  end;

  TGridPlusTexture = class(TPersistent)
  private
    FOwner: TControl;
    FColor: TColor;
    FHighlightColor: TColor;
    FTextureColor1: TColor;
    FTextureColor2: TColor;
    FTextureSize: integer;
    FOnTextureChange: TNotifyEvent;

    procedure SetColor(const Value: TColor);
    procedure SetHighlightColor(const Value: TColor);
    procedure SetTextureColor1(const Value: TColor);
    procedure SetTextureColor2(const Value: TColor);
    procedure SetTextureSize(const Value: integer);

  protected
    procedure DoTextureChange; dynamic;

    property Owner: TControl read FOwner write FOwner;

  public
    constructor Create(AOwner: TControl); dynamic;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure DrawTexture(Bitmap: TBitmap; Highlighted: boolean);

    property OnTextureChange: TNotifyEvent read FOnTextureChange write FOnTextureChange;

  published
    property Color: TColor read FColor write SetColor default clBtnFace;
    property HighlightColor: TColor read FHighlightColor write SetHighlightColor default clActiveCaption;
    property TextureColor1: TColor read FTextureColor1 write SetTextureColor1 default clWhite;
    property TextureColor2: TColor read FTextureColor2 write SetTextureColor2 default clNavy;
    property TextureSize: integer read FTextureSize write SetTextureSize default 5;
  end;

  TGridPlusTab = class(TPersistent)
  private
    FOwner: TControl;
    FAlignment: TAlignment;
    FBorderWidth: integer;
    FColor: TColor;
    FFont: TFont;
    FHighlightFont: TFont;
    FHeight: integer;
    FTabBevel: TGridPlusTabBevel;
    FTitle: TCaption;
    FVisible: boolean;
    FOnTabChange: TNotifyEvent;

    procedure SetAlignment(const Value: TAlignment);
    procedure SetBorderWidth(const Value: integer);
    procedure SetColor(const Value: TColor);
    procedure SetFont(const Value: TFont);
    procedure SetHighlightFont(const Value: TFont);
    procedure SetHeight(const Value: integer);
    procedure SetStyle(const Value: TGridPlusTabBevel);
    procedure SetTitle(const Value: TCaption);
    procedure SetVisible(const Value: boolean);

  protected
    procedure DoTabChange; dynamic;
    procedure DoFontChange(Sender: TObject); dynamic;
    procedure DoHighlightFontChange(Sender: TObject); dynamic;

    property Owner: TControl read FOwner;

  public
    constructor Create(AOwner: TControl); dynamic;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;

  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property BorderWidth: integer read FBorderWidth write SetBorderWidth default 1;

    property Color: TColor read FColor write SetColor default clBtnFace;
    property Font: TFont read FFont write SetFont;
    property HighlightFont: TFont read FHighlightFont write SetHighlightFont;
    property Height: integer read FHeight write SetHeight default 30;
    property TabBevel: TGridPlusTabBevel read FTabBevel write SetStyle default tgFlat;
    property Title: TCaption read FTitle write SetTitle;
    property Visible: boolean read FVisible write SetVisible default False;
    property OnTabChange: TNotifyEvent read FOnTabChange write FOnTabChange;
  end;


implementation

//TGridPlusGradient
constructor TGridPlusGradient.Create(AOwner: TControl);
begin
  inherited Create;
  FOwner        := AOwner;
  FBeginColor   := clTeal;
  FEndColor     := clMoneyGreen;
  FStyle        := gsRectangle;
end;

destructor TGridPlusGradient.Destroy;
begin
  FOwner:= nil;
  inherited Destroy;
end;

procedure TGridPlusGradient.SetBeginColor(const Value: TColor);
begin
  if FBeginColor <> Value then
  begin
    FBeginColor:= Value;
    DoGradientChange;
  end;
end;

procedure TGridPlusGradient.SetEndColor(const Value: TColor);
begin
  if FEndColor <> Value then
  begin
    FEndColor:= Value;
    DoGradientChange;
  end;
end;

procedure TGridPlusGradient.SetStyle(const Value: TGridPlusGradientStyle);
begin
  if FStyle <> Value then
  begin
    FStyle:= Value;
    DoGradientChange;
  end;
end;

procedure TGridPlusGradient.DoGradientChange;
begin
  if Assigned(FOnGradientChange) then
    FOnGradientChange(Self);
end;

procedure  TGridPlusGradient.Assign(Source: TPersistent);
begin
  if Source is TGridPlusGradient then
    with TGridPlusGradient(Source) do
    begin
      Self.FBeginColor:= FBeginColor;
      Self.FEndColor:= FEndColor;
      Self.FStyle:= FStyle;
    end;

  inherited Assign(Source);
end;

procedure TGridPlusGradient.DrawHorzGradient(Dest: TBitmap;
                                        RGBBegin, RGBDif: TGridPlusRGBArray;
                                        Factor:TGridPlusFactorArray);
var
  i, Red, Green, Blue: byte;
  Band : TRect;
begin
  Band.Left:= 0;
  Band.Right:= Dest.Width;

  with Dest.Canvas do
  begin
    Pen.Style:= psSolid;
    Pen.Mode:= pmCopy;

    for i:= 0 to 255 do
    begin
      Band.Top:= MulDiv(i, Dest.Height, 256);
      Band.Bottom:= MulDiv(i + 1, Dest.Height, 256);
      Red:= RGBBegin[0] + Factor[0] * MulDiv(i, RGBDif[0], 255);
      Green:= RGBBegin[1] + Factor[1] * MulDiv(i, RGBDif[1], 255);
      Blue:= RGBBegin[2] + Factor[2] * MulDiv(i, RGBDif[2], 255);
      Brush.Color:= RGB(Red, Green, Blue);
      FillRect(Band);
    end;
  end;
end;

procedure TGridPlusGradient.DrawHorzCenterGradient(Dest: TBitmap;
                                              RGBBegin, RGBDif: TGridPlusRGBArray;
                                              Factor:TGridPlusFactorArray);
var
  i, x, Red, Green, Blue: byte;
  Band : TRect;
begin
  x:= Dest.Width Div 2;
  Band.Top:= 0;
  Band.Bottom:= Dest.Height;

  with Dest.Canvas do
  begin
    Pen.Style:= psSolid;
    Pen.Mode:= pmCopy;

    for i:= 0 to x do
    begin
      Band.Left := Muldiv (i, x, x);
      Band.Right := Muldiv (i + 1, x, x);
      Red := RGBBegin[0] + Factor[0] * Muldiv(i, RGBDif[0], x);
      Green := RGBBegin[1] + Factor[1] * Muldiv(i, RGBDif[1], x);
      Blue := RGBBegin[2] + Factor[2] * Muldiv(i, RGBDif[2], x);
      Brush.Color := RGB(Red, Green, Blue);
      FillRect(Band);
      Band.Left := Dest.Width - (Muldiv (i, x, x));
      Band.Right := Dest.Width - (Muldiv (i + 1, x, x));
      FillRect(Band);
    end;
  end;
end;

procedure TGridPlusGradient.DrawVertGradient(Dest: TBitmap;
                                        RGBBegin, RGBDif: TGridPlusRGBArray;
                                        Factor: TGridPlusFactorArray);
var
  i, Red, Green, Blue: byte;
  Band : TRect;
begin
  Band.Top:= 0;
  Band.Bottom:= Dest.Height;

  with Dest.Canvas do
  begin
    Pen.Style:= psSolid;
    Pen.Mode:= pmCopy;

    for i:= 0 to 255 do
    begin
      Band.Left:= MulDiv(i, Dest.Width, 256);
      Band.Right:= MulDIv(i + 1, Dest.Width, 256);
      Red:= RGBBegin[0] + Factor[0] * MulDiv(i, RGBDif[0], 255);
      Green:= RGBBegin[1] + Factor[1] * MulDiv(i, RGBDif[1], 255);
      Blue:= RGBBegin[2]  + Factor[2] * MulDiv(i, RGBDif[2], 255);
      Brush.Color:= RGB(Red, Green, Blue);
      FillRect(Band);
    end;
  end;
end;

procedure TGridPlusGradient.DrawVertCenterGradient(Dest: TBitmap;
                                              RGBBegin, RGBDif: TGridPlusRGBArray;
                                              Factor:TGridPlusFactorArray);
var
  i, y, Red, Green, Blue: byte;
  Band : TRect;
begin
  y := Dest.Height Div 2;
  Band.Left := 0;
  Band.Right := Dest.Width;

  with Dest.Canvas do
  begin
    Pen.Style:= psSolid;
    Pen.Mode:= pmCopy;

    for i:= 0 to y do
    begin
      Band.Top:= Muldiv (i, y, y);
      Band.Bottom:= Muldiv (i + 1, y, y);
      Red:= RGBBegin[0] + Factor[0] * Muldiv(i, RGBDif[0], y);
      Green:= RGBBegin[1] + Factor[1] * Muldiv(i, RGBDif[1], y);
      Blue:= RGBBegin[2] + Factor[2] * Muldiv(i, RGBDif[2], y);
      Brush.Color := RGB(Red, Green, Blue);
      FillRect(Band);
      Band.Top:= Dest.Height - (Muldiv (i, y, y));
      Band.Bottom:= Dest.Height - (Muldiv (i + 1, y, y));
      FillRect(Band);
    end;
  end;
end;

procedure TGridPlusGradient.DrawEllipticGradient(Dest: TBitmap;
                                            RGBBegin, RGBDif: TGridPlusRGBArray;
                                            Factor:TGridPlusFactorArray);
var
  i: Integer;
  Red, Green, Blue : Byte;
  Pw, Ph, Dw, Dh : integer;
  x1,y1,x2,y2 : integer;
begin
  x1:= Dest.Width div -3;
  x2:= Dest.Width + (Dest.Width div 3);
  y1:= Dest.Height div -3;
  y2:= Dest.Height + (Dest.Height div 3);
  Pw:= x2 - x1;
  Ph:= y2 - y1;

  with Dest.Canvas do
  begin
    Pen.Style:= psClear;
    Pen.Mode:= pmCopy;

    for i:= 0 to 50 do
    begin
      Red:= RGBBegin[0] + Factor[0] * Muldiv(i, RGBDif[0], 50);
      Green:= RGBBegin[1] + Factor[1] * Muldiv(i, RGBDif[1], 50);
      Blue:= RGBBegin[2] + Factor[2] * Muldiv(i, RGBDif[2], 50);
      Brush.Color:= RGB(Red, Green, Blue);
      Dw:= Pw * i div 100;
      Dh:= Ph * i div 100;
      Ellipse(x1 + Dw, y1 + Dh, x2 - Dw, y2 - Dh);
    end;

    Pen.Style := psSolid;
  end;
end;

procedure TGridPlusGradient.DrawRectangleGradient(Dest: TBitmap;
                                             RGBBegin, RGBDif: TGridPlusRGBArray;
                                             Factor:TGridPlusFactorArray);
var
  i: Integer;
  Red, Green, Blue : Byte;
  Pw, Ph : Real;
  x1, y1, x2, y2 : Real;
begin
  x1:= 0;
  x2:= Dest.Width + 2;
  y1:= 0;
  y2:= Dest.Height + 2;
  Pw:= (Dest.Width / 2) / 255;
  Ph:= (Dest.Height / 2) / 255;

  with Dest.Canvas do
  begin
    Pen.Style := psClear;
    Pen.Mode := pmCopy;

    for i := 0 to 255 do
    begin
      x1:= x1 + Pw;
      x2:= x2 - Pw;
      y1:= y1 + Ph;
      y2:= y2 - Ph;
      Red:= RGBBegin[0] + Factor[0] * Muldiv(i, RGBDif[0], 255);
      Green:= RGBBegin[1] + Factor[1] * Muldiv(i, RGBDif[1], 255);
      Blue:= RGBBegin[2] + Factor[2] * Muldiv(i, RGBDif[2], 255);
      Brush.Color := RGB(Red, Green, Blue);
      FillRect(Rect(Trunc(x1), Trunc(y1), Trunc(x2), Trunc(y2)));
    end;

    Pen.Style := psSolid;
  end;
end;

procedure TGridPlusGradient.FillBitmap(Bitmap: TBitmap; AColor: TColor);
begin
  with Bitmap.Canvas do
  begin
    Brush.Color:= FEndColor;
    Brush.Style:= bsSolid;
    FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
  end;
end;

procedure TGridPlusGradient.PrepareRGB(ABeginColor, AEndColor: TColor;
                                  var RGBBegin, RGBEnd, RGBDif: TGridPlusRGBArray;
                                  var Factor: TGridPlusFactorArray);
var
  i: integer;
begin
  RGBBegin[0]:= GetRValue(ColorToRGB(ABeginColor));
  RGBBegin[1]:= GetGValue(ColorToRGB(ABeginColor));
  RGBBegin[2]:= GetBValue(ColorToRGB(ABeginColor));
  RGBEnd[0]:= GetRValue(ColorToRGB(AEndColor));
  RGBEnd[1]:= GetGValue(ColorToRGB(AEndColor));
  RGBEnd[2]:= GetBValue(ColorToRGB(AEndColor));

  for i:= 0 to 2 do
  begin
    RGBDif[i]:= Abs(RGBEnd[i] - RGBBegin[i]);

    if RGBEnd[i] > RGBBegin[i] then
      Factor[i]:= 1
    else
      Factor[i]:= -1;
  end;
end;

procedure TGridPlusGradient.DrawGradient(Bitmap: TBitmap; SwapColors: boolean);
var
  RGBBegin, RGBEnd, RGBDif: TGridPlusRGBArray;
  Factor: TGridPlusFactorArray;
begin
  if FBeginColor <> FEndColor then
  begin
    if SwapColors then
      PrepareRGB(FEndColor, FBeginColor, RGBBegin, RGBEnd, RGBDif, Factor)
    else
      PrepareRGB(FBeginColor, FEndColor, RGBBegin, RGBEnd, RGBDif, Factor);

    case FStyle of
      gsHorizontal: DrawHorzGradient(Bitmap, RGBBegin, RGBDif, Factor);
      gsVertical: DrawVertGradient(Bitmap, RGBBegin, RGBDif, Factor);
      gsHorzCenter: DrawHorzCenterGradient(Bitmap, RGBBegin, RGBDif, Factor);
      gsVertCenter: DrawVertCenterGradient(Bitmap, RGBBegin, RGBDif, Factor);
      gsElliptic: DrawEllipticGradient(Bitmap, RGBBegin, RGBDif, Factor);
      gsRectangle: DrawRectangleGradient(Bitmap, RGBBegin, RGBDif, Factor);
    end;
  end
  else
    FillBitmap(Bitmap, FEndColor);
end;

//TGridPlusTexture
constructor TGridPlusTexture.Create(AOwner: TControl);
begin
  inherited Create;
  FOwner:= AOwner;
  FColor:= clBtnFace;
  FHighlightColor:= clActiveCaption;
  FTextureColor1:= clWhite;
  FTextureColor2:= clNavy;
  FTextureSize:= 5;
end;

destructor TGridPlusTexture.Destroy;
begin
  FOwner:= nil;
  inherited Destroy;
end;

procedure TGridPlusTexture.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor:= Value;
    DoTextureChange;
  end;
end;

procedure TGridPlusTexture.SetHighlightColor(const Value: TColor);
begin
  if FHighlightColor <> Value then
  begin
    FHighlightColor:= Value;
    DoTextureChange;
  end;
end;

procedure TGridPlusTexture.SetTextureColor1(const Value: TColor);
begin
  if FTextureColor1 <> Value then
  begin
    FTextureColor1:= Value;
    DoTextureChange;
  end;
end;

procedure TGridPlusTexture.SetTextureColor2(const Value: TColor);
begin
  if FTextureColor2 <> Value then
  begin
    FTextureColor2:= Value;
    DoTextureChange;
  end;
end;

procedure TGridPlusTexture.SetTextureSize(const Value: integer);
begin
  if FTextureSize <> Value then
  begin
    FTextureSize:= Value;
    DoTextureChange;
  end;
end;

procedure TGridPlusTexture.Assign(Source: TPersistent);
begin
  if Source is TGridPlusTexture then
    with TGridPlusTexture(Source) do
    begin
      Self.FColor:= FColor;
      Self.FHighlightColor:= FHighlightColor;
      Self.FTextureColor1:= FTextureColor1;
      Self.FTextureColor2:= FTextureColor2;
      Self.FTextureSize:= FTextureSize;
    end;

  inherited Assign(Source);
end;

procedure TGridPlusTexture.DoTextureChange;
begin
  if Assigned(FOnTextureChange) then
    FOnTextureChange(Self);
end;

procedure TGridPlusTexture.DrawTexture(Bitmap: TBitmap; Highlighted: boolean);
var
  x, y: integer;
begin
  with Bitmap.Canvas do
  begin
    if Highlighted then
      Brush.Color:= FHighlightColor
    else
      Brush.Color:= FColor;

    Brush.Style:= bsSolid;
    FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
    Pixels[1,1]:= FTextureColor1;
    Pixels[2,2]:= FTextureColor2;
  end;

  with Bitmap do
  begin
    for x:= 1 to ((Width div FTextureSize) + Ord(Width mod FTextureSize > 0)) do
      Canvas.CopyRect(Bounds(x * FTextureSize, 0, FTextureSize, FTextureSize),
                             Canvas,
                             Rect(0, 0, FTextureSize, FTextureSize)
                             );

    for y:= 1 to ((Height div FTextureSize) + Ord(Height mod FTextureSize > 0)) do
      Canvas.CopyRect(Bounds(0, y * FTextureSize, Width, FTextureSize),
                      Canvas,
                      Rect(0, 0, Width, FTextureSize)
                      );
  end;
end;

//TGridPlusTab
constructor TGridPlusTab.Create(AOwner: TControl);
begin
  inherited Create;
  FOwner                  := AOwner;
  FAlignment              := taCenter;
  FBorderWidth            := 1;
  FColor                  := clBtnFace;
  FFont                   := TFont.Create;
  FFont.Size              := 16;
  FFont.OnChange          := DoFontChange;
  FHighlightFont          := TFont.Create;
  FHighlightFont.Color    := clCaptionText;
  FHighlightFont.OnChange := DoHighlightFontChange;
  FHeight                 := 30;
  FTabBevel               := tgFlat;
  FVisible                := False;
  FTitle                  := '<Title>';
end;

destructor TGridPlusTab.Destroy;
begin
  FFont.Free;
  FFont:= nil;
  FHighlightFont.Free;
  FHighlightFont:= nil;
  inherited Destroy;
end;

procedure TGridPlusTab.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetBorderWidth(const Value: integer);
begin
  if (FBorderWidth <> Value) and (Value >= 0) then
  begin
    FBorderWidth:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetFont(const Value: TFont);
begin
  if (FFont <> Value) and (Value <> nil) then
  begin
    FFont.Assign(Value);
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetHighlightFont(const Value: TFont);
begin
  if (FHighlightFont <> Value) and (Value <> nil) then
  begin
    FHighlightFont.Assign(Value);
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetHeight(const Value: integer);
begin
  if (FHeight <> Value) and (Value >= 0) then
  begin
    FHeight:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetStyle(const Value: TGridPlusTabBevel);
begin
  if FTabBevel <> Value then
  begin
    FTabBevel:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetTitle(const Value: TCaption);
begin
  if FTitle <> Value then
  begin
    FTitle:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.SetVisible(const Value: boolean);
begin
  if FVisible <> Value then
  begin
    FVisible:= Value;
    DoTabChange;
  end;
end;

procedure TGridPlusTab.Assign(Source: TPersistent);
begin
  if Source is TGridPlusTab then
    with TGridPlusTab(Source) do
    begin
      Self.FAlignment:= FAlignment;
      Self.FColor:= FColor;
      Self.FFont.Assign(FFont);
      Self.FHeight:= FHeight;
      Self.FTitle:= FTitle;
      Self.FVisible:= FVisible;
      Self.FTabBevel:= FTabBevel;
    end;

  inherited Assign(Source);
end;

procedure TGridPlusTab.DoTabChange;
begin
  if Assigned(FOnTabChange) then
    FOnTabChange(Self);
end;

procedure TGridPlusTab.DoFontChange(Sender: TObject);
begin
  DoTabChange;
end;

procedure TGridPlusTab.DoHighlightFontChange(Sender: TObject);
begin
  DoTabChange;
end;

end.
