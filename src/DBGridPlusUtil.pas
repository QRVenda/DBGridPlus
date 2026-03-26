{---------------------------------------------------------------------------+
|                                                                           |
|  Unit.........: DBGridPlus.pas                                            |
|  Componente...: "DBGridPlus"                                              |
|  Descrição....: Propriedades extras                                       |
|  Data.........: 15/07/2024 - 22:03h                                       |
|  Autoria......: Adriano Zanini                                            |
|                                                                           |
+---------------------------------------------------------------------------}

unit DBGridPlusUtil;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Data.DB, System.UITypes,
  Vcl.GraphUtil,
  DBGridPlusConst;

  procedure PlusDrawGradient(Canvas: TCanvas; ARect: TRect; StartColor,  EndColor: TColor; Direction: TPlusGradientDirection; NumColors: Byte);
  procedure DrawBitmapTransparent(Dest: TCanvas; DstX, DstY: Integer;   Bitmap: TBitmap; TransparentColor: TColor);
  function GetLocalFile(Sender: TWinControl): String;

implementation

procedure PlusDrawGradient(Canvas: TCanvas; ARect: TRect; StartColor,
  EndColor: TColor; Direction: TPlusGradientDirection; NumColors: Byte);
var
  Brush: HBrush;
  StartRGB: array[0..2] of Byte;    { Start RGB values }
  RGBDelta: array[0..2] of Integer; { Difference between start and end RGB values }
  ColorBand: TRect;                 { Color band rectangular coordinates }
  I, Delta: Integer;
begin
  if (Direction=fdNone) then exit;

  if IsRectEmpty(ARect) then Exit;
  if NumColors < 2 then
  begin
    Brush := CreateSolidBrush(ColorToRGB(StartColor));
    FillRect(Canvas.Handle, ARect, Brush);
    DeleteObject(Brush);
    Exit;
  end;
  
  case Direction of
    fdTopToBottom: GradientFillCanvas(Canvas, StartColor, EndColor, ARect, gdVertical);
    fdBottomToTop: GradientFillCanvas(Canvas, EndColor, StartColor, ARect, gdVertical);
    fdLeftToRight: GradientFillCanvas(Canvas, StartColor, EndColor, ARect, gdHorizontal);
    fdRightToLeft: GradientFillCanvas(Canvas, EndColor, StartColor, ARect, gdHorizontal);
  end;
end;

function PaletteColor(Color: TColor): Longint;
const
  PaletteMask = $02000000;
begin
  Result := ColorToRGB(Color) or PaletteMask;
end;

{ Transparent bitmap }
procedure StretchBltTransparent(DstDC: HDC; DstX, DstY, DstW, DstH: Integer;
  SrcDC: HDC; SrcX, SrcY, SrcW, SrcH: Integer; Palette: HPalette;
  TransparentColor: TColorRef);
var
  Color: TColorRef;
  bmAndBack, bmAndObject, bmAndMem, bmSave: HBitmap;
  bmBackOld, bmObjectOld, bmMemOld, bmSaveOld: HBitmap;
  MemDC, BackDC, ObjectDC, SaveDC: HDC;
  palDst, palMem, palSave, palObj: HPalette;
begin
  { Create some DCs to hold temporary data }
  BackDC := CreateCompatibleDC(DstDC);
  ObjectDC := CreateCompatibleDC(DstDC);
  MemDC := CreateCompatibleDC(DstDC);
  SaveDC := CreateCompatibleDC(DstDC);

  { Create a bitmap for each DC }
  bmAndObject := CreateBitmap(SrcW, SrcH, 1, 1, nil);
  bmAndBack := CreateBitmap(SrcW, SrcH, 1, 1, nil);
  bmAndMem := CreateCompatibleBitmap(DstDC, DstW, DstH);
  bmSave := CreateCompatibleBitmap(DstDC, SrcW, SrcH);

  { Each DC must select a bitmap object to store pixel data }
  bmBackOld := SelectObject(BackDC, bmAndBack);
  bmObjectOld := SelectObject(ObjectDC, bmAndObject);
  bmMemOld := SelectObject(MemDC, bmAndMem);
  bmSaveOld := SelectObject(SaveDC, bmSave);

  { Select palette }
  palDst := 0; palMem := 0; palSave := 0; palObj := 0;
  if Palette <> 0 then begin
    palDst := SelectPalette(DstDC, Palette, True);
    RealizePalette(DstDC);
    palSave := SelectPalette(SaveDC, Palette, False);
    RealizePalette(SaveDC);
    palObj := SelectPalette(ObjectDC, Palette, False);
    RealizePalette(ObjectDC);
    palMem := SelectPalette(MemDC, Palette, True);
    RealizePalette(MemDC);
  end;

  { Set proper mapping mode }
  SetMapMode(SrcDC, GetMapMode(DstDC));
  SetMapMode(SaveDC, GetMapMode(DstDC));

  { Save the bitmap sent here }
  BitBlt(SaveDC, 0, 0, SrcW, SrcH, SrcDC, SrcX, SrcY, SRCCOPY);

  { Set the background color of the source DC to the color,         }
  { contained in the parts of the bitmap that should be transparent }
  Color := SetBkColor(SaveDC, PaletteColor(TransparentColor));

  { Create the object mask for the bitmap by performing a BitBlt()  }
  { from the source bitmap to a monochrome bitmap                   }
  BitBlt(ObjectDC, 0, 0, SrcW, SrcH, SaveDC, 0, 0, SRCCOPY);

  { Set the background color of the source DC back to the original  }
  SetBkColor(SaveDC, Color);

  { Create the inverse of the object mask }
  BitBlt(BackDC, 0, 0, SrcW, SrcH, ObjectDC, 0, 0, NOTSRCCOPY);

  { Copy the background of the main DC to the destination }
  BitBlt(MemDC, 0, 0, DstW, DstH, DstDC, DstX, DstY, SRCCOPY);

  { Mask out the places where the bitmap will be placed }
  StretchBlt(MemDC, 0, 0, DstW, DstH, ObjectDC, 0, 0, SrcW, SrcH, SRCAND);

  { Mask out the transparent colored pixels on the bitmap }
  BitBlt(SaveDC, 0, 0, SrcW, SrcH, BackDC, 0, 0, SRCAND);

  { XOR the bitmap with the background on the destination DC }
  StretchBlt(MemDC, 0, 0, DstW, DstH, SaveDC, 0, 0, SrcW, SrcH, SRCPAINT);

  { Copy the destination to the screen }
  BitBlt(DstDC, DstX, DstY, DstW, DstH, MemDC, 0, 0, SRCCOPY);

  { Restore palette }
  if Palette <> 0 then begin
    SelectPalette(MemDC, palMem, False);
    SelectPalette(ObjectDC, palObj, False);
    SelectPalette(SaveDC, palSave, False);
    SelectPalette(DstDC, palDst, True);
  end;

  { Delete the memory bitmaps }
  DeleteObject(SelectObject(BackDC, bmBackOld));
  DeleteObject(SelectObject(ObjectDC, bmObjectOld));
  DeleteObject(SelectObject(MemDC, bmMemOld));
  DeleteObject(SelectObject(SaveDC, bmSaveOld));

  { Delete the memory DCs }
  DeleteDC(MemDC);
  DeleteDC(BackDC);
  DeleteDC(ObjectDC);
  DeleteDC(SaveDC);
end;

procedure StretchBitmapTransparent(Dest: TCanvas; Bitmap: TBitmap;
  TransparentColor: TColor; DstX, DstY, DstW, DstH, SrcX, SrcY,
  SrcW, SrcH: Integer);
var
  CanvasChanging: TNotifyEvent;
  Temp: TBitmap;
begin
  if DstW <= 0 then DstW := Bitmap.Width;
  if DstH <= 0 then DstH := Bitmap.Height;
  if (SrcW <= 0) or (SrcH <= 0) then
  begin
    SrcX := 0; SrcY := 0;
    SrcW := Bitmap.Width;
    SrcH := Bitmap.Height;
  end;
  if not Bitmap.Monochrome then
    SetStretchBltMode(Dest.Handle, STRETCH_DELETESCANS);
  CanvasChanging := Bitmap.Canvas.OnChanging;
  try
    Bitmap.Canvas.OnChanging := nil;
    Temp := Bitmap;
    try
      if TransparentColor = clNone then
      begin
        StretchBlt(Dest.Handle, DstX, DstY, DstW, DstH, Temp.Canvas.Handle,
          SrcX, SrcY, SrcW, SrcH, Dest.CopyMode);
      end
      else
      begin
        if Temp.Monochrome then
          TransparentColor := clWhite
        else
          TransparentColor := ColorToRGB(TransparentColor);

        if Assigned(Temp.Canvas) then
          StretchBltTransparent(Dest.Handle, DstX, DstY, DstW, DstH,
            Temp.Canvas.Handle, SrcX, SrcY, SrcW, SrcH, Temp.Palette,
            TransparentColor);
      end;
    finally
    end;
  finally
    Bitmap.Canvas.OnChanging := CanvasChanging;
  end;
end;

procedure DrawBitmapTransparent(Dest: TCanvas; DstX, DstY: Integer;
  Bitmap: TBitmap; TransparentColor: TColor);
begin
  StretchBitmapTransparent(Dest, Bitmap, TransparentColor, DstX, DstY,
    Bitmap.Width, Bitmap.Height, 0, 0, Bitmap.Width, Bitmap.Height);
end;


function GetLocalFile(Sender: TWinControl): String;
begin
  Result := IncludeTrailingPathDelimiter(GetCurrentDir());
  Result := Result +  Sender.Name + '_layout.ini';
end;

end.
