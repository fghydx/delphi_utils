/// <remarks>
/// 几种Hash算法
/// </remarks>  
unit GLHashAlgorithm;

interface

Type
  TCharCase = (ccUpper, ccNormal, ccLower);

const
  CASE_CHAR_TABLE: array [TCharCase] of array [UTF8Char] of UTF8Char =
  ((#0, #1, #2, #3, #4, #5, #6, #7,
     #8, #9, #10, #11, #12, #13, #14, #15,
     #16, #17, #18, #19, #20, #21, #22, #23,
     #24, #25, #26, #27, #28, #29, #30, #31,
		 #32, #33, #34, #35, #36, #37, #38, #39,
     #40, #41, #42, #43, #44, #45, #46, #47,
     '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
     #58, #59, #60, #61, #62, #63, #64,
     'A', 'B', 'C', 'D', 'E', 'F', 'G',
     'H', 'I', 'J', 'K', 'L', 'M', 'N',
     'O', 'P', 'Q', 'R', 'S', 'T',
     'U', 'V', 'W', 'X', 'Y', 'Z',
     #91, #92, #93, #94, #95, #96,
     'A', 'B', 'C', 'D', 'E', 'F', 'G',
     'H', 'I', 'J', 'K', 'L', 'M', 'N',
     'O', 'P', 'Q', 'R', 'S', 'T',
     'U', 'V', 'W', 'X', 'Y', 'Z',
     #122, #123, #124, #125, #126, #127, #128, #129,
     #130, #131, #132, #133, #134, #135, #136, #137,
     #138, #139, #140, #141, #142, #143, #144, #145,
     #146, #147, #148, #149, #150, #151, #152, #153,
     #154, #155, #156, #157, #158, #159, #160, #161,
     #162, #163, #164, #165, #166, #167, #168, #169,
     #170, #171, #172, #173, #174, #175, #176, #177,
     #178, #179, #180, #181, #182, #183, #184, #185,
     #186, #187, #188, #189, #190, #191, #192, #193,
     #194, #195, #196, #197, #198, #199, #200, #201,
     #202, #203, #204, #205, #206, #207, #208, #209,
     #210, #211, #212, #213, #214, #215, #216, #217,
     #218, #219, #220, #221, #222, #223, #224, #225,
     #226, #227, #228, #229, #230, #231, #233, #234,
     #235, #236, #237, #238, #239, #240, #241, #242,
     #243, #244, #245, #246, #247, #248, #249, #250,
     #251, #252, #253, #254, #255),
    (#0, #1, #2, #3, #4, #5, #6, #7,
     #8, #9, #10, #11, #12, #13, #14, #15,
     #16, #17, #18, #19, #20, #21, #22, #23,
     #24, #25, #26, #27, #28, #29, #30, #31,
		 #32, #33, #34, #35, #36, #37, #38, #39,
     #40, #41, #42, #43, #44, #45, #46, #47,
     '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
     #58, #59, #60, #61, #62, #63, #64,
     'A', 'B', 'C', 'D', 'E', 'F', 'G',
     'H', 'I', 'J', 'K', 'L', 'M', 'N',
     'O', 'P', 'Q', 'R', 'S', 'T',
     'U', 'V', 'W', 'X', 'Y', 'Z',
     #91, #92, #93, #94, #95, #96,
     'a', 'b', 'c', 'd', 'e', 'f', 'g',
     'h', 'i', 'j', 'k', 'l', 'm', 'n',
     'o', 'p', 'q', 'r', 's', 't',
     'u', 'v', 'w', 'x', 'y', 'z',
     #122, #123, #124, #125, #126, #127, #128, #129,
     #130, #131, #132, #133, #134, #135, #136, #137,
     #138, #139, #140, #141, #142, #143, #144, #145,
     #146, #147, #148, #149, #150, #151, #152, #153,
     #154, #155, #156, #157, #158, #159, #160, #161,
     #162, #163, #164, #165, #166, #167, #168, #169,
     #170, #171, #172, #173, #174, #175, #176, #177,
     #178, #179, #180, #181, #182, #183, #184, #185,
     #186, #187, #188, #189, #190, #191, #192, #193,
     #194, #195, #196, #197, #198, #199, #200, #201,
     #202, #203, #204, #205, #206, #207, #208, #209,
     #210, #211, #212, #213, #214, #215, #216, #217,
     #218, #219, #220, #221, #222, #223, #224, #225,
     #226, #227, #228, #229, #230, #231, #233, #234,
     #235, #236, #237, #238, #239, #240, #241, #242,
     #243, #244, #245, #246, #247, #248, #249, #250,
     #251, #252, #253, #254, #255),
    (#0, #1, #2, #3, #4, #5, #6, #7,
     #8, #9, #10, #11, #12, #13, #14, #15,
     #16, #17, #18, #19, #20, #21, #22, #23,
     #24, #25, #26, #27, #28, #29, #30, #31,
		 #32, #33, #34, #35, #36, #37, #38, #39,
     #40, #41, #42, #43, #44, #45, #46, #47,
     '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
     #58, #59, #60, #61, #62, #63, #64,
     'a', 'b', 'c', 'd', 'e', 'f', 'g',
     'h', 'i', 'j', 'k', 'l', 'm', 'n',
     'o', 'p', 'q', 'r', 's', 't',
     'u', 'v', 'w', 'x', 'y', 'z',
     #91, #92, #93, #94, #95, #96,
     'a', 'b', 'c', 'd', 'e', 'f', 'g',
     'h', 'i', 'j', 'k', 'l', 'm', 'n',
     'o', 'p', 'q', 'r', 's', 't',
     'u', 'v', 'w', 'x', 'y', 'z',
     #122, #123, #124, #125, #126, #127, #128, #129,
     #130, #131, #132, #133, #134, #135, #136, #137,
     #138, #139, #140, #141, #142, #143, #144, #145,
     #146, #147, #148, #149, #150, #151, #152, #153,
     #154, #155, #156, #157, #158, #159, #160, #161,
     #162, #163, #164, #165, #166, #167, #168, #169,
     #170, #171, #172, #173, #174, #175, #176, #177,
     #178, #179, #180, #181, #182, #183, #184, #185,
     #186, #187, #188, #189, #190, #191, #192, #193,
     #194, #195, #196, #197, #198, #199, #200, #201,
     #202, #203, #204, #205, #206, #207, #208, #209,
     #210, #211, #212, #213, #214, #215, #216, #217,
     #218, #219, #220, #221, #222, #223, #224, #225,
     #226, #227, #228, #229, #230, #231, #233, #234,
     #235, #236, #237, #238, #239, #240, #241, #242,
     #243, #244, #245, #246, #247, #248, #249, #250,
     #251, #252, #253, #254, #255));


function RSHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function JSHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function PJWHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function ELFHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function BKDRHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function SDBMHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function DJBHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function APHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function DefultHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;

function LazarusHash(AKey:String):Cardinal;     //校验头里用的这个

implementation

Function LazarusHash(AKey : String) : Cardinal;
Var
  thehash,g,I,J : LongWord;
begin
   thehash:=0;
{$IFDEF MSWINDOWS}
  J := 1;
{$ELSE}
  J := 0;
{$ENDIF}
   For I:=J to Length(AKey)-Abs(J-1) do { 0 terminated }
     begin
     thehash:=thehash shl 4;
     inc(theHash,Ord(AKey[i]));
     g:=thehash and LongWord($f shl 28);
     if g<>0 then
       begin
       thehash:=thehash xor (g shr 24);
       thehash:=thehash xor g;
       end;
     end;
   If theHash=0 then
     Result:=$ffffffff
   else
     Result:=TheHash;
end;


function DefultHashA(AKey: MarshaledAString;len:Cardinal; CharCase: TCharCase): Cardinal;
var
  I: Integer;
  tmp:MarshaledAString;
begin
  Result := 0;
  for I := 0 to len do
  begin
    tmp := AKey+I;
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor
      Byte(CASE_CHAR_TABLE[CharCase][tmp^]);
  end;
end;

function DefultHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := DefultHashA(AKey,len,ccNormal)
  else
    Result := DefultHashA(AKey,len,ccLower);
end;

function RSHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  a, b, hash: Cardinal;
  i: Cardinal;
begin
  b  := 378551;
  a := 63689;
  hash := 0;
  for i := 0 to len - 1 do
  begin
    hash := hash * a + Byte(CASE_CHAR_TABLE[CharCase][buf[i]]);
    a := a * b;
  end;
	Result := hash and $7fffffff;
end;

function RSHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := RSHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := RSHashA(PUTF8Char(AKey),len,ccLower);
end;

function JSHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash: Cardinal;
  i: Cardinal;
begin
  hash := 1315423911;
  for i := 0 to len - 1 do
    hash := hash xor
     ((hash shl 5)  +
        Byte(CASE_CHAR_TABLE[CharCase][buf[i]])  +
       (hash shr 2));
	Result := hash and $7fffffff;
end;
function JSHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := JSHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := JSHashA(PUTF8Char(AKey),len,ccLower);
end;

 {  P. J. Weinberger Hash Function  }
function PJWHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
const
  BitsInUnignedInt = SizeOf(Cardinal)  * 8;
  ThreeQuarters =(BitsInUnignedInt * 3) div 4;
  OneEighth = BitsInUnignedInt div 8;
  HighBits = $ffffffff shl(BitsInUnignedInt  -  OneEighth);
var
  hash, flag: Cardinal;
  i: Cardinal;
begin
  hash := 0;
  for i := 0 to len - 1 do
  begin
    hash :=(hash shl OneEighth) + Byte(CASE_CHAR_TABLE[CharCase][buf[i]]);
    flag := hash and HighBits;
    if(flag <> 0) then
      hash :=((hash xor(flag shr ThreeQuarters))
        and(not HighBits));
  end;
  Result := hash and $7fffffff;
end;
function PJWHash(AKey: MarshaledAString;len:Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := PJWHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := PJWHashA(PUTF8Char(AKey),len,ccLower);
end;

function ELFHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash, x: Cardinal;
  i: Cardinal;
begin
	hash := 0;
  for i := 0 to len - 1 do
  begin
		hash :=(hash shl 4) + Byte(CASE_CHAR_TABLE[CharCase][buf[i]]);
    x := hash and $f0000000;
		if x <> 0 then
		begin
			hash := hash xor(x shr 24);
			hash := hash and not x;
		end; 
	end; 
  Result := hash and $7fffffff;
end;
function ELFHash(AKey: MarshaledAString; len: Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := ELFHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := ELFHashA(PUTF8Char(AKey),len,ccLower);
end;

function BKDRHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash, seed: Cardinal;
  i: Cardinal;
begin
  seed := 131;  //  31 131 1313 13131 131313 etc..
  hash := 0;
  for i := 0 to len - 1 do
    hash := hash * seed + Byte(CASE_CHAR_TABLE[CharCase][buf[i]]);
	Result := hash and $7fffffff;
end;
function BKDRHash(AKey: MarshaledAString;len: Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := BKDRHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := BKDRHashA(PUTF8Char(AKey),len,ccLower);
end;

function SDBMHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash: Cardinal;
  i: Cardinal;
begin
  hash := 0;
  for i := 0 to len - 1 do
    hash := Byte(CASE_CHAR_TABLE[CharCase][buf[i]]) +(hash shl 6) +(hash shl 16) - hash;
	Result := hash and $7fffffff;
end;
function SDBMHash(AKey: MarshaledAString;len: Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := SDBMHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := SDBMHashA(PUTF8Char(AKey),len,ccLower);
end;

function DJBHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash: Cardinal;
  i: Cardinal;
begin
  hash := 5381;
  for i := 0 to len - 1 do
    hash := hash +(hash shl 5) + Byte(CASE_CHAR_TABLE[CharCase][buf[i]]);
  Result := hash and $7fffffff;
end;
function DJBHash(AKey: MarshaledAString; len: Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := DJBHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := DJBHashA(PUTF8Char(AKey),len,ccLower);
end;

function APHashA(buf: PUTF8Char; len: Cardinal; CharCase: TCharCase): Cardinal;
var
  hash: Cardinal;
  i: Cardinal;
begin
  hash := 0;
  for i := 0 to len - 1 do
  begin
		if ((i and 1) = 0) then
			hash := hash xor(
       (hash shl 7) xor Byte(CASE_CHAR_TABLE[CharCase][buf[i]]) xor
       (hash shr 3))
      else
			  hash := hash xor(
          not((hash shl 11) xor Byte(CASE_CHAR_TABLE[CharCase][buf[i]]) xor
         (hash shr 5)));
  end;
  Result := hash and $7fffffff;
end;
function APHash(AKey: MarshaledAString; len: Cardinal; CharCase: Boolean): Cardinal;
begin
  if CharCase then
    Result := APHashA(PUTF8Char(AKey),len,ccNormal)
  else
    Result := APHashA(PUTF8Char(AKey),len,ccLower);
end;
end.
