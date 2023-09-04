unit GLCrossPlatformDef;

interface

uses
  System.SysUtils;

type
{$IFNDEF MSWINDOWS}
  AnsiString = Tbytes;
{$ENDIF}

  TAnsiStringHelper = record helper for AnsiString
  private
    function GetLength: Integer; inline;
  public
    procedure Assign(str: string);
    function toString: string;
    procedure Append(str: string);
    procedure Empty;
    property Length: Integer read GetLength;
  end;

implementation

{ TAnsiStringHelper }

procedure TAnsiStringHelper.Append(str: string);
{$IFNDEF MSWINDOWS}
var
  bytes: TBytes;
  OldLen, ByteLen, I: integer;
{$ENDIF}
begin
{$IFNDEF MSWINDOWS}
  Bytes := TEncoding.ANSI.GetBytes(str);
  ByteLen := System.Length(Bytes);
  if ByteLen > 0 then
  begin
    OldLen := Length-1;
    SetLength(Self, self.Length + ByteLen);
    for I := 1 to ByteLen  do
    begin
      Self[OldLen + I] := bytes[I];
    end;
  end;
{$ELSE}
  Self := Self + str;
{$ENDIF}
end;

procedure TAnsiStringHelper.Assign(str: string);
begin
{$IFNDEF MSWINDOWS}
  Self := TEncoding.ANSI.GetBytes(str);
{$ELSE}
  Self := str;
{$ENDIF}
end;

procedure TAnsiStringHelper.Empty;
begin
{$IFNDEF MSWINDOWS}
  SetLength(Self, 0);
{$ELSE}
  Self := '';
{$ENDIF}
end;

function TAnsiStringHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;

function TAnsiStringHelper.toString: string;
begin
{$IFNDEF MSWINDOWS}
  Result := Trim(TEncoding.ANSI.GetString(Self));
{$ELSE}
  Result := self;
{$ENDIF}
end;

end.


