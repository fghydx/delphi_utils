unit GLSHA;

interface

uses
  SysUtils, Classes,GLPubFunc,GLTypeDef;

procedure SHA1Init(out Context: TSHA1Context);
procedure SHA1Update(var Context: TSHA1Context; Buf: Pointer; BufSize: Integer);
procedure SHA1Final(var Context: TSHA1Context; out Digest: TSHA1Digest);
procedure SHA1(Buf: Pointer; BufSize: Integer; out Digest: TSHA1Digest); overload;
function SHA1(Buf: Pointer; BufSize: Integer): AnsiString; overload;
function SHA1(const Str: AnsiString): AnsiString; overload;
function SHA1(const Str: WideString): AnsiString; overload;
procedure SHA1Stream(out Digest: TSHA1Digest; const Stream: TStream; Len: Int64 = 0);
procedure SHA1File(const FileName: string; out Digest: TSHA1Digest);

implementation

procedure SHA1(Buf: Pointer; BufSize: Integer; out Digest: TSHA1Digest);
var
  Context: TSHA1Context;
begin
  SHA1Init(Context);
  SHA1Update(Context, Buf, BufSize);
  SHA1Final(Context, Digest);
end;

function SHA1(Buf: Pointer; BufSize: Integer): AnsiString;
var
  Context: TSHA1Context;
  Digest: TSHA1Digest;
begin
  SHA1Init(Context);
  SHA1Update(Context, Buf, BufSize);
  SHA1Final(Context, Digest);
  Result := MemHex(Digest, SizeOf(Digest));
end;

function SHA1(const Str: AnsiString): AnsiString;
begin
  Result := SHA1(Pointer(Str), Length(Str));
end;

function SHA1(const Str: WideString): AnsiString; overload;
begin
  Result := SHA1(Pointer(Str), Length(Str) * 2);
end;

procedure SHA1Stream(out Digest: TSHA1Digest; const Stream: TStream; Len: Int64);
var
  Context: TSHA1Context;
  Buffer: array [0..4095] of Byte;
  ReadBytes : Integer;
  Bookmark: Int64;
begin
  SHA1Init(Context);
  Bookmark := Stream.Position;
  if (Len <= 0) or (Len > Stream.Size - Bookmark) then Len := Stream.Size - Bookmark;
  try
    while Len > 0 do
    begin
      ReadBytes := SizeOf(Buffer);
      if ReadBytes > Len then ReadBytes := Len;
      ReadBytes := Stream.Read(Buffer, ReadBytes);
      SHA1Update(Context, @Buffer, ReadBytes);
      Dec(Len, ReadBytes);
    end;
    SHA1Final(Context, Digest);
  finally
    Stream.Position := Bookmark; 
  end;
end;

procedure SHA1File(const FileName: string; out Digest: TSHA1Digest);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    SHA1Stream(Digest, Stream);
  finally
    Stream.Free;
  end;
end;

function KT(t: Integer): UINT32;
const
  NO_NAME: array [0..3] of UINT32 = ($5A827999, $6ED9EBA1, $8F1BBCDC, $CA62C1D6);
begin
  Result := NO_NAME[t div 20];
end;

function ROTL(v: UINT32; n: Integer): UINT32;
begin
  Result := (v shl n) or (v shr (32 - n));
end;

function ROTR(v: UINT32; n: Integer): UINT32; 
begin
  Result := (v shr n) or (v shl (32 - n));
end;

function FT(t: Integer; B, C, D: UINT32): UINT32;
begin
  case t div 20 of
    0: Result := (B and C) or ((not B) and D);
    1, 3: Result := B xor C xor D;
    else Result := (B and C) or (B and D) or (C and D);
  end;
end;

procedure SHA1CalcBlock(var Context: TSHA1Context; Block: PSHA1UINT32Block);
var
  W: array [0..79] of UINT32;
  t: Integer;
  A, B, C, D, E, Temp: UINT32;
begin
  for t := 0 to 15 do W[t] := SysToBigEndian(Block[t]);
  for t := 16 to 79 do W[t] := ROTL(W[t-3] xor W[t-8] xor W[t-14] xor W[t-16], 1);
  A := Context.H[0];  B := Context.H[1];  C := Context.H[2];
  D := Context.H[3]; E := Context.H[4];
  for t := 0 to 79 do
  begin
    Temp := ROTL(A, 5) + FT(t, B, C, D) + E + W[t] + KT(t);
    E := D; D := C; C := ROTL(B, 30); B := A; A := Temp;
  end;
  Inc(Context.H[0], A); Inc(Context.H[1], B); Inc(Context.H[2], C); 
  Inc(Context.H[3], D); Inc(Context.H[4], E);
end;

procedure SHA1Init(out Context: TSHA1Context);
begin
  Context.H[0] := $67452301;
  Context.H[1] := $EFCDAB89;
  Context.H[2] := $98BADCFE;
  Context.H[3] := $10325476;
  Context.H[4] := $C3D2E1F0;
  Context.BufLen := 0;
  Context.TtlLen := 0;
end;

procedure SHA1Update(var Context: TSHA1Context; Buf: Pointer; BufSize: Integer);
var
  pBlocks: PSHA1UINT32Block;
begin
  Inc(Context.TtlLen, BufSize);
  if Context.BufLen + BufSize < 64 then
  begin
    Move(Buf^, Context.Buf[Context.BufLen], BufSize);
    Inc(Context.BufLen, BufSize);
    Exit;
  end;
  if Context.BufLen > 0 then
  begin
    Move(Buf^, Context.Buf[Context.BufLen], 64 - Context.BufLen);
    SHA1CalcBlock(Context, @Context.Buf);
    pBlocks := PSHA1UINT32Block(LongInt(Buf) + 64 - Context.BufLen);
    Dec(BufSize, 64 - Context.BufLen);
  end
  else pBlocks := PSHA1UINT32Block(Buf);
  while BufSize >= 64 do
  begin
    SHA1CalcBlock(Context, pBlocks);
    Dec(BufSize, 64);
    Inc(pBlocks);
  end;
  Context.BufLen := BufSize;
  if BufSize > 0 then Move(pBlocks^, Context.Buf, BufSize);
end;

procedure SHA1Final(var Context: TSHA1Context; out Digest: TSHA1Digest);
var
  I: Integer;
begin
  Context.TtlLen := Context.TtlLen * 8;
  Context.Buf[Context.BufLen] := $80;
  Inc(Context.BufLen);
  for I := Context.BufLen to 55 do
  begin
    Context.Buf[I] := 0;
    Inc(Context.BufLen);
  end;
  if Context.BufLen <> 56 then
  begin
    for I := Context.BufLen to 63 do Context.Buf[I] := 0;
    SHA1CalcBlock(Context, @Context.Buf);
    for I := 0 to 13 do Context.Block[I] := 0;
  end;
  Context.Block[14] := Context.TtlLen shr 32;
  Context.Block[15] := Context.TtlLen and $ffffffff;
  Context.Block[14] := SysToBigEndian(Context.Block[14]);
  Context.Block[15] := SysToBigEndian(Context.Block[15]);
  SHA1CalcBlock(Context, @Context.Block);
  for I := 0 to 4 do Digest[I] := SysToBigEndian(Context.H[I]);
end;

end.
