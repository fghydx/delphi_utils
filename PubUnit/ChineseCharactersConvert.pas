unit ChineseCharactersConvert;
 interface
 uses
   Classes, Windows;
 type
   TGBBIG5Convert = class(TObject)
   public
     class function BIG5ToGB(BIG5Str : String): AnsiString;
     class function GBToBIG5(GBStr : String): AnsiString;
     class function GBChs2Cht(GBStr: String): AnsiString;
     class function GBCht2Chs(GBStr: String): AnsiString;
 end;

implementation

class function TGBBIG5Convert.BIG5ToGB(BIG5Str : String): AnsiString;
 var
   Len: Integer;
   pBIG5Char: PChar;
   pGBCHSChar: PChar;
   pGBCHTChar: PChar;
   pUniCodeChar: PWideChar;
 begin
   //String -> PChar
   pBIG5Char := PChar(BIG5Str);
   Len := MultiByteToWideChar(950,0,pansichar(pBIG5Char),-1,nil,0);
   GetMem(pUniCodeChar,Len*2);
   ZeroMemory(pUniCodeChar,Len*2);
   //Big5 -> UniCode
   MultiByteToWideChar(950,0,pansichar(pBIG5Char),-1,pUniCodeChar,Len);
   Len := WideCharToMultiByte(936,0,pUniCodeChar,-1,nil,0,nil,nil);
   GetMem(pGBCHTChar,Len*2);
   GetMem(pGBCHSChar,Len*2);
   ZeroMemory(pGBCHTChar,Len*2);
   ZeroMemory(pGBCHSChar,Len*2);
   //UniCode->GB CHT
   WideCharToMultiByte(936,0,pUniCodeChar,-1,pansichar(pGBCHTChar),Len,nil,nil);
   //GB CHT -> GB CHS
   LCMapString($804,LCMAP_SIMPLIFIED_CHINESE,pGBCHTChar,-1,pGBCHSChar,Len);
   Result := String(pGBCHSChar);
   FreeMem(pGBCHTChar);
   FreeMem(pGBCHSChar);
   FreeMem(pUniCodeChar);
 end;
 {进行GBK简体转繁体}
 class function TGBBIG5Convert.GBChs2Cht(GBStr: String): AnsiString;
 Var
   Len: integer;
   pGBCHTChar: PChar;
   pGBCHSChar: PChar;
 Begin
   pGBCHSChar := PChar(GBStr);
   Len := MultiByteToWideChar(936, 0, pansichar(pGBCHSChar), -1, Nil, 0);
   GetMem(pGBCHTChar, Len * 2 + 1);
   ZeroMemory(pGBCHTChar, Len * 2 + 1);
   LCMapString($804, LCMAP_TRADITIONAL_CHINESE, pGBCHSChar, -1, pGBCHTChar, Len * 2);
   result := String(pGBCHTChar);
   FreeMem(pGBCHTChar);
 end;
 {进行GBK繁体转简体}
 class function TGBBIG5Convert.GBCht2Chs(GBStr: String): AnsiString;
 Var
   Len: integer;
   pGBCHTChar: PChar;
   pGBCHSChar: PChar;
 Begin
   pGBCHTChar := PChar(GBStr);
   Len := MultiByteToWideChar(936, 0, pansichar(pGBCHTChar), -1, Nil, 0);
   GetMem(pGBCHSChar, Len * 2 + 1);
   ZeroMemory(pGBCHSChar, Len * 2 + 1);
   LCMapString($804, LCMAP_SIMPLIFIED_CHINESE, pGBCHTChar, -1, pGBCHSChar, Len * 2);
   result := String(pGBCHSChar);
   FreeMem(pGBCHSChar);
 end;
 class function TGBBIG5Convert.GBToBIG5(GBStr : String): AnsiString;
 var
   Len: Integer;
   pGBCHTChar: PChar;
   pGBCHSChar: PChar;
   pUniCodeChar: PWideChar;
   pBIG5Char: PChar;
 begin
   pGBCHSChar := PChar(GBStr);
   Len := MultiByteToWideChar(936,0,pansichar(pGBCHSChar),-1,nil,0);
   GetMem(pGBCHTChar,Len*2+1);
   ZeroMemory(pGBCHTChar,Len*2+1);
   //GB CHS -> GB CHT
   LCMapString($804,LCMAP_TRADITIONAL_CHINESE,pGBCHSChar,-1,pGBCHTChar,Len*2);
   GetMem(pUniCodeChar,Len*2);
   ZeroMemory(pUniCodeChar,Len*2);
   //GB CHT -> UniCode
   MultiByteToWideChar(936,0,pansichar(pGBCHTChar),-1,pUniCodeChar,Len*2);
   Len := WideCharToMultiByte(950,0,pUniCodeChar,-1,nil,0,nil,nil);
   GetMem(pBIG5Char,Len);
   ZeroMemory(pBIG5Char,Len);
   //UniCode -> Big5
   WideCharToMultiByte(950,0,pUniCodeChar,-1,pansichar(pBIG5Char),Len,nil,nil);
   Result := String(pBIG5Char);
   FreeMem(pBIG5Char);
   FreeMem(pGBCHTChar);
   FreeMem(pUniCodeChar);
 end;

end.
