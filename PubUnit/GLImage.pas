unit GLImage;

interface
uses Windows,jpeg,Graphics;

/// <remarks>
/// 缩放图片，DecWidth,DecHeight，长宽，以大的为准
/// </remarks>
function ScaleZoomBitMap(Source:TBitmap;DecWidth,DecHeight:Word):TBitmap;
function ScaleZoomJpeg(Source:TJPEGImage;DecWidth,DecHeight:Word):TJPEGImage;

implementation

function ScaleZoomBitMap(Source:TBitmap;DecWidth,DecHeight:Word):TBitmap;
var
   Height: INTEGER;
   TargetArea: TRect;
   Width: INTEGER;
begin
   Result := TBitmap.Create;
   try
      Result.Width := DecWidth;
      Result.Height := DecHeight;
      //创建新的位图以及设置大小
      Result.PixelFormat := pf24bit;
      //象素格式
      Result.Canvas.Brush := Source.Canvas.Brush;
      Result.Canvas.FillRect(Result.Canvas.ClipRect);


      if Source.Width / Source.Height < DecWidth / DecHeight
         //也可以是等于的情况
      then begin

            // 拉伸到匹配
            TargetArea.Top := 0;
            TargetArea.Bottom := Result.Height;

            Width := MulDiv(Result.Height, Source.Width, Source.Height);

            TargetArea.Left := 0;
            TargetArea.Right := TargetArea.Left + Width;
         end
      else begin
            // 拉伸到匹配
            TargetArea.Left := 0;
            TargetArea.Right := Result.Width;

            Height := MulDiv(Result.Width, Source.Height, Source.Width);

            TargetArea.Top := 0;
            TargetArea.Bottom := TargetArea.Top + Height;
               //确定目标区域
      end;

      result.Width := TargetArea.Right-TargetArea.Left;
      Result.Height := TargetArea.Bottom-TargetArea.Top;
      Result.Canvas.StretchDraw(TargetArea, Source);
      //进行拉伸
   finally

   end
end;

function ScaleZoomJpeg(Source:TJPEGImage;DecWidth,DecHeight:Word):TJPEGImage;
var
  BitMap,NewBitMap:TBitmap;
begin
  Result := nil;
  BitMap := TBitmap.Create;
  try
    BitMap.Assign(Source);
    NewBitMap := ScaleZoomBitMap(BitMap,DecWidth,DecHeight);
    try
      Result := TJPEGImage.Create;
      Result.Assign(NewBitMap);
    finally
      NewBitMap.Free;
    end;
  finally
    BitMap.Free;
  end;
end;
end.
