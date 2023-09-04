unit GLTypeDef;

interface
  uses DateUtils,System.Types{$IFDEF MSWINDOWS},Windows{$Endif};

const
  HEXADECIMAL_CHARS: array [0..$f] of Char =
      ('0', '1', '2', '3', '4', '5', '6', '7',
       '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
const
{$REGION 'GLBase64'}
  BASE64_ALPHABETS: array [0..64] of UTF8Char =
    ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
   'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
   'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
   'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
   'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
   'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
   'w', 'x', 'y', 'z', '0', '1', '2', '3',
   '4', '5', '6', '7', '8', '9', '+', '/', '=');

   BASE64_ALPHABET_INDEXES: array [43..122] of Byte =
    (62, 255, 255, 255, 63, 52, 53, 54,
    55, 56, 57, 58, 59, 60, 61, 255,
    255, 255, 64, 255, 255, 255, 0, 1,
    2, 3, 4, 5, 6, 7, 8, 9,
    10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25,
    255, 255, 255, 255, 255, 255, 26, 27,
    28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43,
    44, 45, 46, 47, 48, 49, 50, 51);
{$ENDREGION}

{$REGION 'GLMD5'}
type
  UINT4 = LongWord;

  TArray4UINT4 = array [0..3] of UINT4;
  PArray4UINT4 = ^TArray4UINT4;

  TArray2UINT4 = array [0..1] of UINT4;
  PArray2UINT4 = ^TArray2UINT4;

  TArray16Byte = array [0..15] of Byte;
  PArray16Byte = ^TArray16Byte;

  TArray64Byte = array [0..63] of Byte;
  PArray64Byte = ^TArray64Byte;

  PByteArray = ^TByteArray;
  TByteArray = array [0..0] of Byte;

  TUINT4Array = array [0..0] of UINT4;
  PUINT4Array = ^TUINT4Array;
  
  TMD5Digest = record
    case Integer of
      0:(Dwords: array [0..3] of LongWord);
      1:(Bytes: array [0..15] of Byte);
    end;
  PMD5Digest = ^TMD5Digest;

  TMD5Context = record
   State: TArray4UINT4;
   Count: TArray2UINT4;
   Buffer: TArray64Byte;
  end;
  PMD5Context = ^TMD5Context;
{$ENDREGION}

{$REGION 'GLSHA'}
type
  UINT32 = LongWord;
  PUINT32 = ^UINT32;

  TSHA1ByteBlock = array [0..63] of Byte;
  PSHA1ByteBlock = ^TSHA1ByteBlock;
  TSHA1UINT32Block = array [0..15] of UINT32;
  PSHA1UINT32Block = ^TSHA1UINT32Block;


  TSHA1Digest = array [0..4] of UINT32;
  PSHA1Digest = ^TSHA1Digest;
  
  TSHA1Context = record
    H: TSHA1Digest;
    BufLen: Integer;
    TtlLen: Int64;
    case Integer of
      1: (Buf: TSHA1ByteBlock);
      4: (Block: TSHA1UINT32Block);
  end;
  PSHA1Context = ^TSHA1Context;
{$ENDREGION}

Type
  TByteOrder = (boLittleEndian, boBigEndian);  //小端字节序，大端字节序
  TCompareResult = (crLess, crEqual, crGreater);  //比较返回值，小于，等于，大于
  
  TStringCompareOption = (coIgnoreCase, coIgnoreNonSpace, coIgnoreSymbols,
    coLinguisticIgnoreCase, coLinguisticIgnoreDiacritic, coStringSort,
    coIgnoreKanaType, coIgnoreWidth, coLinguisticCasing);

  TStringCompareOptions = set of TStringCompareOption;
  
  TLocale = (loSystemDefault, loUserDefault, loNeutral, loInvariant);

  PObject = ^TObject;
  
  THashAlgorithm = (HADefault,HARS,HAJS,HAPJW,HAELF,HABKDR,HASDBM,HADJB,HAAP);

{$REGION 'RBTree'}

{$IFNDEF MSWINDOWS}
const
  SORT_DEFAULT                         = $0;     { sorting default }
  SUBLANG_NEUTRAL                      = $00;    { language neutral }
  LANG_NEUTRAL                         = $00;
  SUBLANG_SYS_DEFAULT                  = $02;
  SUBLANG_DEFAULT                      = $01;
  LANG_SYSTEM_DEFAULT   = (SUBLANG_SYS_DEFAULT shl 10) or LANG_NEUTRAL;
  LANG_USER_DEFAULT     = (SUBLANG_DEFAULT shl 10) or LANG_NEUTRAL;
  LOCALE_SYSTEM_DEFAULT = (SORT_DEFAULT shl 16) or LANG_SYSTEM_DEFAULT;
  LOCALE_USER_DEFAULT   = (SORT_DEFAULT shl 16) or LANG_USER_DEFAULT;
  {$EXTERNALSYM NORM_IGNORECASE}
  NORM_IGNORECASE = 1;                      { ignore case }
  {$EXTERNALSYM NORM_IGNORENONSPACE}
  NORM_IGNORENONSPACE = 2;                  { ignore nonspacing chars }
  {$EXTERNALSYM NORM_IGNORESYMBOLS}
  NORM_IGNORESYMBOLS = 4;                   { ignore symbols }

  {$EXTERNALSYM NORM_IGNOREKANATYPE}
  NORM_IGNOREKANATYPE = $10000;             { linguistically appropriate 'ignore case' }
  {$EXTERNALSYM NORM_IGNOREWIDTH}
  NORM_IGNOREWIDTH = $20000;                { linguistically appropriate 'ignore nonspace' }
type
  LCID = DWORD;
{$ENDIF}

const
  LANG_INVARIANT = $7f;
  Locale_NEUTRAL = (LongWord(SORT_DEFAULT) shl 16) or
    LongWord((Word(SUBLANG_NEUTRAL) shl 10) or LANG_NEUTRAL);
  Locale_INVARIANT = (LongWord(SORT_DEFAULT) shl 16) or
    LongWord((Word(SUBLANG_NEUTRAL) shl 10) or LANG_INVARIANT);

  Locale_IDS : array [TLocale] of LCID =
  (
    Locale_SYSTEM_DEFAULT,
    Locale_USER_DEFAULT,
    Locale_NEUTRAL,
    Locale_INVARIANT
  );
  LINGUISTIC_IGNORECASE = $00000010;
  LINGUISTIC_IGNOREDIACRITIC = $00000020;
  NORM_LINGUISTIC_CASING = $08000000;
  SORT_StrINGSORT = $00001000 ;
  COMPARE_StrING_FLAGS: array [TStringCompareOption] of LongWord =
    (
      NORM_IGNORECASE,
      Locale_USER_DEFAULT,
      NORM_IGNORESYMBOLS,
      LINGUISTIC_IGNORECASE,
      LINGUISTIC_IGNOREDIACRITIC,
      SORT_StrINGSORT,
      NORM_IGNOREKANATYPE,
      NORM_IGNOREWIDTH,
      NORM_LINGUISTIC_CASING
    );
{$ENDREGION}
{$IFDEF MSWINDOWS}
const
  csWndShowFlag: array[Boolean] of DWORD = (SW_HIDE, SW_RESTORE);
{$ENDIF}
implementation

end.
