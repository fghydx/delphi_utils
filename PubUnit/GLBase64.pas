unit GLBase64;

interface
uses GLTypeDef;

function Base64Encode(Input: Pointer; InputSize: Integer;
  Output: Pointer): Integer; overload;
function Base64Encode(Input: Pointer; InputSize: Integer): AnsiString; overload;
function Base64Encode(const Input: AnsiString): AnsiString; overload;
function Base64Decode(Input: Pointer; InputSize: Integer;
  Output: Pointer): Integer; overload;
function Base64Decode(const Input: AnsiString;
  Output: Pointer): Integer; overload;
function Base64Decode(const Input: AnsiString): AnsiString; overload;

implementation

type
  FourBytes = array [0..3] of Byte;
  ThreeBytes = array [0..2] of Byte;
  PFourBytes = ^FourBytes;
  PThreeBytes = ^ThreeBytes;

function Base64Encode(Input: Pointer; InputSize: Integer;
  Output: Pointer): Integer;
var
  IPtr: PThreeBytes;
  OPtr: PFourBytes;
  IEnd: LongInt;
begin
  Result := (InputSize + 2) div 3 * 4;
  if Output = nil then Exit;
  IPtr := PThreeBytes(Input);
  OPtr := PFourBytes(Output);
  IEnd := LongInt(Input) + InputSize;
  while IEnd > Integer(IPtr) do
  begin
    OPtr[0] := IPtr[0] shr 2;
    OPtr[1] :=(IPtr[0] shl 4) and $30;
    if IEnd - Integer(IPtr) > 2 then
    begin
      OPtr[1] := OPtr[1] or(IPtr[1] shr 4);
      OPtr[2] :=(IPtr[1] shl 2) and $3f;
      OPtr[2] := OPtr[2] or IPtr[2] shr 6;
      OPtr[3] := IPtr[2] and $3f;
    end
    else if IEnd - Integer(IPtr) > 1 then
    begin
      OPtr[1] := OPtr[1] or(IPtr[1] shr 4);
      OPtr[2] :=(IPtr[1] shl 2) and $3f;
      OPtr[3] := 64;
    end
    else begin
      OPtr[2] := 64;
      OPtr[3] := 64;
    end;
    
    OPtr[0] := Ord(BASE64_ALPHABETS[OPtr[0]]);
    OPtr[1] := Ord(BASE64_ALPHABETS[OPtr[1]]);
    OPtr[2] := Ord(BASE64_ALPHABETS[OPtr[2]]);
    OPtr[3] := Ord(BASE64_ALPHABETS[OPtr[3]]);

    Inc(IPtr);
    Inc(OPtr);
  end;
end;

function Base64Encode(Input: Pointer; InputSize: Integer): AnsiString; overload;
begin
  SetLength(Result,(InputSize + 2) div 3 * 4);
  Base64Encode(Input, InputSize, Pointer(Result));
end;

function Base64Encode(const Input: AnsiString): AnsiString; overload;
begin
  SetLength(Result,(Length(Input) + 2) div 3 * 4);
  Base64Encode(Pointer(Input), Length(Input), Pointer(Result));
end;

function Base64Decode(Input: Pointer; InputSize: Integer;
  Output: Pointer): Integer;
var
  IPtr: PFourBytes;
  OPtr: PThreeBytes;
  i: Integer;
begin
  Result :=(InputSize div 4) * 3;
  if PAnsiChar(Input)[InputSize - 2] = '=' then Dec(Result, 2)
  else if PAnsiChar(Input)[InputSize - 1] = '=' then Dec(Result);
  if Output = nil then Exit;
  IPtr := PFourBytes(Input);
  OPtr := PThreeBytes(Output);
  for i := 1 to InputSize div 4 do 
  begin
    IPtr[0] := BASE64_ALPHABET_INDEXES[IPtr[0]];
    IPtr[1] := BASE64_ALPHABET_INDEXES[IPtr[1]];
    IPtr[2] := BASE64_ALPHABET_INDEXES[IPtr[2]];
    IPtr[3] := BASE64_ALPHABET_INDEXES[IPtr[3]];
    OPtr[0] :=(IPtr[0] shl 2) or(IPtr[1] shr 4);
    if(IPtr[2] <> 64) then
    begin
      OPtr[1] :=(IPtr[1] shl 4) or(IPtr[2] shr 2);
    end;

    if(IPtr[3] <> 64) then
    begin
      OPtr[2] :=(IPtr[2] shl 6) or IPtr[3];
    end;

    Inc(IPtr);
    Inc(OPtr);
  end;
end;

function Base64Decode(const Input: AnsiString;
  Output: Pointer): Integer; overload;
begin
  Result := Base64Decode(Pointer(Input), Length(Input), Output);
end;

function Base64Decode(const Input: AnsiString): AnsiString; overload;
var
  InputSize: Integer;
  OutputSize: Integer;
begin
  InputSize := Length(Input);
  if Input[InputSize] = #0 then Dec(InputSize);
  OutputSize :=(InputSize div 4) * 3;
  if Input[InputSize - 1] = '=' then Dec(OutputSize, 2)
  else if Input[InputSize] = '=' then Dec(OutputSize);
  SetLength(Result, OutputSize);
  Base64Decode(Pointer(Input), InputSize, Pointer(Result));
end;

end.
