unit GLImage;

interface
uses Windows,jpeg,Graphics;

/// <remarks>
/// ����ͼƬ��DecWidth,DecHeight�������Դ��Ϊ׼
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
      //�����µ�λͼ�Լ����ô�С
      Result.PixelFormat := pf24bit;
      //���ظ�ʽ
      Result.Canvas.Brush := Source.Canvas.Brush;
      Result.Canvas.FillRect(Result.Canvas.ClipRect);


      if Source.Width / Source.Height < DecWidth / DecHeight
         //Ҳ�����ǵ��ڵ����
      then begin

            // ���쵽ƥ��
            TargetArea.Top := 0;
            TargetArea.Bottom := Result.Height;

            Width := MulDiv(Result.Height, Source.Width, Source.Height);

            TargetArea.Left := 0;
            TargetArea.Right := TargetArea.Left + Width;
         end
      else begin
            // ���쵽ƥ��
            TargetArea.Left := 0;
            TargetArea.Right := Result.Width;

            Height := MulDiv(Result.Width, Source.Height, Source.Width);

            TargetArea.Top := 0;
            TargetArea.Bottom := TargetArea.Top + Height;
               //ȷ��Ŀ������
      end;

      result.Width := TargetArea.Right-TargetArea.Left;
      Result.Height := TargetArea.Bottom-TargetArea.Top;
      Result.Canvas.StretchDraw(TargetArea, Source);
      //��������
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
