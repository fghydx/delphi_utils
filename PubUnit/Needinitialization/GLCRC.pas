unit GLCRC;

interface

uses
  SysUtils, Classes,GLPubFunc;

procedure CRC32_Update(Buf: Pointer; Size: Integer; var Crc: LongWord);
function CRC32(Buf: Pointer; Size: Integer): LongWord; overload;
function CRC32(const Str: AnsiString): LongWord; overload;
function CRC32(Stream: TStream; Len: Int64 = 0): LongWord; overload;
function CRC32File(const FileName: string): LongWord; 

implementation

var
  CRC32_TABLE: array[0..255] of LongWord;

procedure CRC32_Update(Buf: Pointer; Size: Integer; var Crc: LongWord);
var
  i, j: Integer;
  b: LongWord;
begin
  for i := 0 to Size - 1 do
  begin
    j := Byte(Crc xor Ord(PChar(Buf)[i]));
    b := CRC32_TABLE[j];
    Crc := b xor(Crc shr 8) and $ffffff;
  end;
end;

function CRC32(Buf: Pointer; Size: Integer): LongWord;
begin
  Result := $ffffffff;
  CRC32_Update(Buf, Size, Result);
  Result := not Result;
end;

function CRC32(const Str: AnsiString): LongWord;
begin
  Result := CRC32(Pointer(Str), Length(Str));
end;

function CRC32(Stream: TStream; Len: Int64): LongWord;
var
  Buf: array [0..255] of Byte;
  BufLen: Integer;
begin
  Result := $ffffffff;
  if Stream is TMemoryStream then
  begin
    BufLen := Stream.Size - Stream.Position;
    if(Len <= 0) or (Len > BufLen) then Len := BufLen;
    CRC32_Update(Pointer(LongInt(TMemoryStream(Stream).Memory) +
      Stream.Position), Len, Result);
  end
  else begin
    if (Len <= 0) or (Len > Stream.Size - Stream.Position) then
      Len := Stream.Size - Stream.Position;
    while Len > 0 do
    begin
      if Len < SizeOf(Buf) then BufLen := Len
      else BufLen := SizeOf(Buf);
      BufLen := Stream.Read(Buf, BufLen);
      CRC32_Update(@Buf, BufLen, Result);
      Dec(Len, BufLen);
    end;
  end;
  Result := not Result;
end;

function CRC32File(const FileName: string): LongWord;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    Result := CRC32(Stream);
  finally
    Stream.Free;
  end;
end;

procedure CRC32_InitTable;
var
  crc, i, j: LongWord;
begin
  for i := 0 to 255 do
  begin
    crc := i;
    for j := 0 to 7 do
    begin
      if crc and 1 = 1 then crc :=(crc shr 1) xor $edb88320
      else crc := crc shr 1;
    end;
    CRC32_TABLE[i] := crc;
  end;
end;

initialization
  CRC32_InitTable;

end.
