/// <remarks>
/// 一些字符串校验单元
/// </remarks>
unit GLStrValidation;

interface
uses Classes,GLBinaryTree;

/// <remarks>
/// 是否是整数
/// </remarks>
function IsInteger(const s: AnsiString): Boolean;

/// <remarks>
/// 是否是手机号       
/// </remarks>
function IsValidCnMobilePhoneNumber(const PhoneNumber: AnsiString): Boolean;

/// <remarks>
/// 15位身份证转18位身份证
/// </remarks>
function IdentityCard15to18(const idc15: AnsiString; out idc18: AnsiString): Boolean;

/// <remarks>
/// 是否是身份证号
/// </remarks>
function IsValidIdentityCard(const idc: AnsiString): Boolean;

/// <remarks>
/// 是否是车牌号
/// </remarks>
function IsValidPlateNumber(const number: WideString): Boolean;

var
  CnMobilePhonePrefix:TGLIntegerRBTree;
implementation

function IsInteger(const s: AnsiString): Boolean;
var
  i: Integer;
begin
  for i := 1 to Length(s) do
  begin
    if (not (s[i] in ['0'..'9'])) then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function IsValidCnMobilePhoneNumber(const PhoneNumber: AnsiString): Boolean;
var
  prefix: Integer;
begin
  Result := False;
  if ((Length(PhoneNumber) <> 11) or not IsInteger(PhoneNumber)) then Exit;
  prefix := (Ord(PhoneNumber[1]) and $0f) * 100 +
    (Ord(PhoneNumber[2]) and $0f) * 10 +
    (Ord(PhoneNumber[3]) and $0f);
  Result := CnMobilePhonePrefix.Exists(prefix);
end;

function IsValidIdentityCard18(const idc18: AnsiString): Boolean;
const
  IDCBITS: array[1..18] of Integer =
    (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1);
  CHECKSUMBITS: array[0..10] of ansiChar =
    ('1', '0', 'x', '9', '8', '7', '6', '5', '4', '3', '2');
var
  checksum, i: Integer;
  ch: AnsiChar;
begin
  Result := False;
  if Length(idc18) <> 18 then Exit;
  if idc18[18] in ['x', 'X'] then
  begin
    if not IsInteger(Copy(idc18, 1, 17)) then Exit;
  end
  else if not IsInteger(idc18) then Exit;
  checksum := 0;
  for i := 1 to 17 do
  begin
    ch := idc18[i];
    Inc(checksum, (Byte(ch) and $0f) * IDCBITS[i]);
  end;
  if (idc18[18] = 'X') then ch := 'x'
  else ch := idc18[18];
  Result := CHECKSUMBITS[checksum mod 11] = ch;
end;

function IsValidIdentityCard(const idc: AnsiString): Boolean;
begin
  if (Length(idc) = 15) then Result := IsInteger(idc)
  else if (Length(idc) = 18) then Result := IsValidIdentityCard18(idc)
  else Result := False;
end;

function IdentityCard15to18(const idc15: AnsiString;
  out idc18: AnsiString): Boolean;
const
  IDCBITS: array[1..18] of Integer =
    (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1);
  CHECKSUMBITS: array[0..10] of AnsiChar =
    ('1', '0', 'x', '9', '8', '7', '6', '5', '4', '3', '2');
var
  checksum, i: Integer;
  ch: AnsiChar;
begin
  Result := False;
  if ((Length(idc15) <> 15) or not IsInteger(idc15)) then Exit;
  SetLength(idc18, 18);
  for i := 1 to 6 do idc18[i] := idc15[i];
  idc18[7] := '1';
  idc18[8] := '9';
  for i := 7 to 15 do idc18[i + 2] := idc15[i];
  checksum := 0;
  for i := 1 to 17 do
  begin
    ch := idc18[i];
    Inc(checksum, (Byte(ch) and $0f) * IDCBITS[i]);
  end;
  idc18[18] := CHECKSUMBITS[checksum mod 11];
  Result := True;
end;

function IsValidPlateNumber(const number: WideString): Boolean;
const
  ChinaProvinceShortNames: WideString = '湘京津冀晋蒙辽吉黑沪苏浙皖闽赣鲁豫鄂粤桂' +
    '琼渝川贵云藏陕甘青宁新';
var
  i: Integer;
  found: Boolean;
begin
  Result := False;
  if (Length(number) <> 7) then Exit;
  found := False;
  for i := 1 to Length(ChinaProvinceShortNames) do 
    if (ChinaProvinceShortNames[i] = number[1]) then
    begin
      found := True;
      Break;
    end;
  if (not found) then Exit;
  if (Ord(number[2]) < Ord('A')) or (Ord(number[2]) > Ord('Z'))  then Exit;
  for i := 3 to 7 do
    if not (((Ord(number[i]) >= Ord('A')) and
      (Ord(number[i]) <= Ord('Z'))) or
      ((Ord(number[i]) >= Ord('0')) and
      (Ord(number[i]) <= Ord('9')))) then Exit;
  Result := True;
end;

procedure AddDefaultMobilePrefix;
var
  i: Integer;
begin
  //CMCC
  for i := 134 to 139 do CnMobilePhonePrefix.Add(i, TObject(0));
  CnMobilePhonePrefix.Add(147, TObject(0));
  for i := 150 to 152 do CnMobilePhonePrefix.Add(i, TObject(0));
  for i := 157 to 159 do CnMobilePhonePrefix.Add(i, TObject(0));
  CnMobilePhonePrefix.Add(182, TObject(0));
  CnMobilePhonePrefix.Add(187, TObject(0));
  CnMobilePhonePrefix.Add(188, TObject(0));

  //CUCC
  for i := 130 to 132 do CnMobilePhonePrefix.Add(i, TObject(1));
  CnMobilePhonePrefix.Add(155, TObject(1));
  CnMobilePhonePrefix.Add(156, TObject(1));
  CnMobilePhonePrefix.Add(186, TObject(1));

  //CTCC
  CnMobilePhonePrefix.Add(133, TObject(2));
  CnMobilePhonePrefix.Add(153, TObject(2));
  CnMobilePhonePrefix.Add(180, TObject(2));
  CnMobilePhonePrefix.Add(189, TObject(2));
end;

initialization
  CnMobilePhonePrefix := TGLIntegerRBTree.Create;
  AddDefaultMobilePrefix;
  
finalization
  CnMobilePhonePrefix.Free;

end.
