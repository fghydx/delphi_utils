unit GLStreamPatch;

interface

uses Classes,SysUtils,GLCrossPlatformDef{$ifdef MSWINDOWS},Windows{$endif};

type

  /// <remarks>
  /// ��Stream�򲹶� ����һЩ�������ݵĶ�д
  /// </remarks>
  TGLStreamPatch = class Helper for TStream
  private
  public
    procedure WriteEx(Value:Byte);overload;
    procedure WriteEx(Value:Char);overload;
    procedure WriteEx(Value:Boolean);overload;
    procedure WriteEx(Value:Word);overload;
    procedure WriteEx(Value:Integer);overload;
    procedure WriteEx(Value:Cardinal);overload;
    procedure WriteEx(Value:TDateTime);overload;
    procedure WriteEx(Value:Double);overload;
    procedure WriteEx(Value:Single);overload;
    procedure WriteEx(Value:Extended);overload;
    procedure WriteEx(Value:Int64);overload;
    procedure WriteEx(Value:NativeInt);overload;
    procedure WriteEx(Value:NativeUInt);overload;
    procedure WriteEx(Value:TGUID);overload;

    procedure WriteByte(Value:Byte);
    procedure WriteChar(Value:Char);
    procedure WriteBoolean(Value:Boolean);
    procedure WriteWord(Value:Word);
    procedure writeInteger(Value:Integer);
    procedure writeSmallInt(Value:SmallInt);
    procedure writeShortInt(Value:ShortInt);
    procedure WriteCardinal(Value:Cardinal);
    procedure WriteTDateTime(Value:TDateTime);
    procedure WriteDouble(Value:Double);
    procedure WriteSingle(Value:Single);
    procedure WriteExtended(Value:Extended);
    procedure WriteInt64(Value:Int64);
    procedure WriteNativeInt(Value:NativeInt);
    procedure WriteNativeUInt(Value:NativeUInt);
    procedure WriteTGUID(Value:TGUID);
    /// <param name="Value"> (AnsiString) </param>
    /// <param name="WriteLen">�Ƿ���ǰ��д���ַ����ĳ���</param>
    procedure WriteAnsiString(Value: AnsiString; WriteLen: Boolean = True); overload;
    procedure WriteAnsiString(Value: string; WriteLen: Boolean = True); overload;
    /// <param name="Value"> (String) </param>
    /// <param name="WriteLen">�Ƿ���ǰ��д���ַ����ĳ���</param>
    procedure WriteString(Value: String; WriteLen: Boolean = True);
    procedure WriteStringEx(Value: String; WriteLen: Boolean = True; Encoding:TEncoding = nil; WriteBom: Boolean = false);
    procedure WriteTStream(value:TStream;WriteLen:Boolean = True);
    /// <remarks>
    /// ����������д����
    /// </remarks>
    procedure WriteVariant(Value:Variant;WriteLen:Boolean = True);
    function ReadByte(CheckLen: Boolean = True): Byte;
    function ReadChar(CheckLen: Boolean = True): Char;
    function ReadBoolean(CheckLen: Boolean = True): Boolean;
    function ReadWord(CheckLen: Boolean = True): Word;
    function ReadInteger(CheckLen: Boolean = True): Integer;
    function ReadSmallInt(CheckLen: Boolean = True): SmallInt;
    function ReadShortInt(CheckLen: Boolean = True): ShortInt;
    function ReadCardinal(CheckLen: Boolean = True): Cardinal;
    function ReadTDateTime(CheckLen: Boolean = True): TDateTime;
    function ReadDouble(CheckLen: Boolean = True): Double;
    function ReadSingle(CheckLen: Boolean = True): Single;
    function ReadExtended(CheckLen: Boolean = True): Extended;
    function ReadInt64(CheckLen: Boolean = True): int64;
    function ReadNativeInt(CheckLen: Boolean = True): NativeInt;
    function ReadNativeUInt(CheckLen: Boolean = True): NativeUInt;
    function ReadTGUID(CheckLen: Boolean = True): TGUID;
    /// <param name="ReadLen">��ȡ���ȣ����Ϊ0�����ȶ�ȡ�����ٶ�ȡ���� </param>
    /// <param name="CheckLen">У���ȡ�ĳ����᲻��Խ��</param>
    function ReadAnsiString(ReadLen: Integer = 0; CheckLen: Boolean = True): string;
    function ReadString(ReadLen: Integer = 0; CheckLen: Boolean = True): String;
    function ReadStringEx(ReadLen:Integer = 0;CHeckLen:Boolean = True;Encoding:TEncoding = nil):String;
    function ReadTStream(ReadLen:Int64 = 0; CheckLen: Boolean = True):
        TMemoryStream;
    /// <remarks>
    /// �����ж�ȡһ��Variant���͵�����
    /// </remarks>
    function ReadVariant(ReadLen:Integer = 0):Variant;
    procedure First;
    procedure Last;
    function Eof:Boolean;

  end;

  TGLMemStreamPatch = class Helper for TMemoryStream
  public
    procedure WriteLine(Value:AnsiString);
    procedure WriteLineW(Value: String);

    function ReadLineA(out Data: String): Boolean;
    function ReadLineW(out Data: String): Boolean;
    procedure FreePre;
  end;

{$IFDEF MSWINDOWS}
//�ڴ�ӳ��
  TGLMemoryMap = record
  private
    fBuf: PAnsiChar;
    fBufSize: NativeUInt;
    fFile: THandle;
    fMap: THandle;
    fFileSize: Int64;
    fFileLocal: boolean;
  public
    function Map(aFile: THandle; aCustomSize: NativeUInt=0; aCustomOffset: Int64=0): boolean; overload;
    function Map(const aFileName: TFileName): boolean; overload;
    procedure Map(aBuffer: pointer; aBufferSize: NativeUInt); overload;
    procedure UnMap;
    property Buffer: PAnsiChar read fBuf;
    property Size: NativeUInt read fBufSize;
  end;

//�ڴ�ӳ���FileStream
  TGLMapFileStream = class(TMemoryStream)
  protected
    fMap: TGLMemoryMap;
    fFileStream: TFileStream;
  public
    constructor Create(const aFileName: TFileName); overload;
    constructor Create(aFile: THandle); overload;
    destructor Destroy; override;
  end;
{$ENDIF}

implementation

uses Variants,System.RTLConsts;
{ TGLStreamPatch }

function TGLStreamPatch.Eof: Boolean;
begin
  Result := Position>=Size;
end;

procedure TGLStreamPatch.First;
begin
  Position := 0;
end;

procedure TGLStreamPatch.Last;
begin
  Position := Size;
end;

function TGLStreamPatch.ReadAnsiString(ReadLen: Integer = 0; CheckLen: Boolean
    = True): string;
var
  Len:integer;
  index:integer;
  Res:AnsiString;
begin
  index := 1;
{$IFNDEF MSWINDOWS}
  Index := 0;
{$ENDIF}
  Res.Empty;
  if ReadLen>0 then
    len := ReadLen
  else
    len := ReadInteger;
  if len>0 then
  begin
    if CheckLen and (Len>size-Position) then
    begin
      raise Exception.Create('��ȡ���ݳ����������ȣ���ʣ�೤��:'+inttostr(size-Position)+'   ��ȡ����:'+inttostr(Len));
      Exit;
    end;
    SetLength(Res,len);
    ReadBuffer(Res[index],len);
  end;
  Result := Res.toString;
end;

function TGLStreamPatch.ReadBoolean(CheckLen: Boolean = True): Boolean;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadByte(CheckLen: Boolean = True): Byte;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadCardinal(CheckLen: Boolean = True): Cardinal;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadChar(CheckLen: Boolean = True): Char;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadTDateTime(CheckLen: Boolean = True): TDateTime;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadDouble(CheckLen: Boolean = True): Double;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadExtended(CheckLen: Boolean = True): Extended;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadInt64(CheckLen: Boolean = True): int64;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadInteger(CheckLen: Boolean = True): Integer;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadNativeInt(CheckLen: Boolean): NativeInt;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadNativeUInt(CheckLen: Boolean): NativeUInt;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadShortInt(CheckLen: Boolean): ShortInt;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadSingle(CheckLen: Boolean = True): Single;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadSmallInt(CheckLen: Boolean): SmallInt;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  ReadBuffer(Result,SizeOf(Result));
end;

function TGLStreamPatch.ReadTStream(ReadLen:Int64 = 0; CheckLen: Boolean =
    True): TMemoryStream;
var
  len:Int64;
begin
  Result := nil;
  if ReadLen>0 then
    len := ReadLen
  else
    len := ReadInt64;
  if len>0 then
  begin
    if CheckLen and (Size-Position<SizeOf(Result)) then
    begin
      raise Exception.Create('��ȡ���ݳ����������ȣ�');
      Exit;
    end;
    
    Result := TMemoryStream.Create;
    Result.CopyFrom(Self,len);
  end;
end;

function TGLStreamPatch.ReadVariant(ReadLen: Integer): Variant;
var 
  p : pointer;
  VariantLen:integer;
  Vtype:Integer;
begin
  if ReadByte=1 then
  begin
    if ReadLen>0 then
      VariantLen := ReadLen
    else
      VariantLen := ReadInteger;
    Result := VarArrayCreate ([0, VariantLen-1], varByte);   //Ҳѧϰһ�����������������������һ����������
    p := VarArrayLock (Result);   //������û��ʲô�ˣ���������������෴��!
    ReadBuffer(p^, VariantLen);   //��ʵ���������̵�����ڴ��ˣ�ָ���Ӧ�ã�������
    VarArrayUnlock (Result);
  end else
  begin
    Vtype := ReadInteger;
    case VType and varTypeMask of
      varEmpty, varNull:begin
        Result := varNull;
      end;
      varString:begin
        Result := ReadAnsiString();
      end;
      varOleStr:begin
        Result := ReadString();
      end;
      varBoolean:begin
        Result := ReadBoolean;
      end;
      varInteger:begin
        Result := ReadInteger;
      end;
      varDouble:begin
        Result := ReadDouble;
      end;
      varInt64:begin
        Result := ReadInt64;
      end;
    end;
  end;
end;

function TGLStreamPatch.ReadTGUID(CheckLen: Boolean = True): TGUID;
var
  GUID:TGUID;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  
  ReadBuffer(GUID,SizeOf(TGUID));
  Result := GUID;
end;

function TGLStreamPatch.ReadString(ReadLen: Integer = 0; CheckLen: Boolean
    = True): String;
var
  len:integer;
begin
  Result := '';
  if ReadLen>0 then
    len := ReadLen
  else
    len := ReadInteger(CheckLen);
  if len>0 then
  begin
    if CheckLen and (Len * SizeOf(Char) >size-Position) then
    begin
      raise Exception.Create('��ȡ���ݳ����������ȣ�');
      Exit;
    end;
    SetLength(Result,len);
    ReadBuffer(Result[1],len*SizeOf(Char));
  end;
end;

function TGLStreamPatch.ReadStringEx(ReadLen: Integer; CHeckLen: Boolean;
  Encoding: TEncoding): String;
var
  Buffer: TBytes;
  len:integer;
begin
  result := '';
  if ReadLen>0 then
    Len := ReadLen
  else
    Len := ReadInteger(CHeckLen);

  if len>0 then
  begin
    if CheckLen and (Len >size-Position) then
    begin
      raise Exception.Create('��ȡ���ݳ����������ȣ�');
      Exit;
    end;
    SetLength(Buffer, Len);
    ReadBuffer(Buffer[0],len);
    len := TEncoding.GetBufferEncoding(Buffer,Encoding,TEncoding.Default);
    Result := Encoding.GetString(Buffer,len,Length(Buffer)-Len);
  end;
end;

function TGLStreamPatch.ReadWord(CheckLen: Boolean = True): Word;
begin
  if CheckLen and (Size-Position<SizeOf(Result)) then
  begin
    raise Exception.Create('��ȡ���ݳ����������ȣ�');
    Exit;
  end;
  
  ReadBuffer(Result,SizeOf(Word));
end;

procedure TGLStreamPatch.WriteEx(Value: Byte);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Char);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteAnsiString(Value: AnsiString; WriteLen: Boolean =
    True);
var
  Len:Integer;
  index:integer;
begin
  Index := 1;
{$IFNDEF MSWINDOWS}
  Index := 0;
{$ENDIF}
  len := Length(Value);
  if WriteLen then
    writeInteger(Len);
  WriteBuffer(Value[index],Len);
end;

procedure TGLStreamPatch.WriteAnsiString(Value: string; WriteLen: Boolean);
var
  ansi:AnsiString;
begin
{$IFNDEF MSWINDOWS}
  ansi := TEncoding.ANSI.GetBytes(Value);
  WriteAnsiString(ansi,WriteLen);
{$ELSE}
  ansi := Value;
  WriteAnsiString(ansi,WriteLen);
{$ENDIF}
end;

procedure TGLStreamPatch.WriteBoolean(Value: Boolean);
begin
  WriteBuffer(value,SizeOf(Boolean));
end;

procedure TGLStreamPatch.WriteByte(Value: Byte);
begin
  WriteBuffer(Value,SizeOf(Byte));
end;

procedure TGLStreamPatch.WriteCardinal(Value: Cardinal);
begin
  WriteBuffer(Value,SizeOf(Cardinal));
end;

procedure TGLStreamPatch.WriteChar(Value: Char);
begin
  WriteBuffer(Value,SizeOf(Char));
end;

procedure TGLStreamPatch.WriteTDateTime(Value: TDateTime);
begin
  WriteBuffer(Value,SizeOf(TDateTime));
end;

procedure TGLStreamPatch.WriteDouble(Value: Double);
begin
  WriteBuffer(Value,SizeOf(Double));
end;

procedure TGLStreamPatch.WriteExtended(Value: Extended);
begin
  WriteBuffer(Value,SizeOf(Extended));
end;

procedure TGLStreamPatch.WriteInt64(Value: Int64);
begin
  WriteBuffer(Value,SizeOf(Int64));
end;

procedure TGLStreamPatch.writeInteger(Value: Integer);
begin
  WriteBuffer(Value,SizeOf(Integer));
end;

procedure TGLStreamPatch.WriteNativeInt(Value:NativeInt);
begin
  WriteBuffer(Value,SizeOf(NativeInt));
end;

procedure TGLStreamPatch.WriteNativeUInt(Value: NativeUInt);
begin
  WriteBuffer(Value,SizeOf(NativeUInt));
end;

procedure TGLStreamPatch.writeShortInt(Value: ShortInt);
begin
  WriteBuffer(Value,SizeOf(ShortInt));
end;

procedure TGLStreamPatch.WriteSingle(Value: Single);
begin
  WriteBuffer(Value,SizeOf(Single));
end;

procedure TGLStreamPatch.writeSmallInt(Value: SmallInt);
begin
   WriteBuffer(Value,SizeOf(SmallInt));
end;

procedure TGLStreamPatch.WriteTStream(value:TStream;WriteLen:Boolean = True);
begin
  if WriteLen then
    WriteInt64(value.Size);
  CopyFrom(value,0);
end;

procedure TGLStreamPatch.WriteVariant(Value: Variant; WriteLen: Boolean);
var
  p : pointer;
  VariantSize:integer;
  VarData:TVarData;
begin
  if VarIsArray(Value) then
  begin
    WriteByte(1);                                       //˵���Ǳ�������
    VariantSize := VarArrayHighBound (Value, 1) - VarArrayLowBound (Value, 1) + 1;
    Size := Size + VariantSize;  //��ʵ����ֱ��ȡ��ά��Ϊ����С����Ϊһ������±���������άΪ0��
    p := VarArrayLock (Value);   //��д����ʱ�����ǵ��˿�ס�ˣ���Ϊ����������һ�ְ�ȫ���飬�������������ݵ����飬v[0]����������ʵ��ʼ��ַ�������Ǻ��ѵõ����ĵ�ַ������������պô������������!
    if WriteLen then
      writeInteger(VariantSize);
    WriteBuffer(p^, VariantSize);  //�˾����������ѧ�߾�̾��Ҳ����û�������ù���ֻ��û������������������ù����Ǻǣ�ѧϰѧϰ!
    VarArrayUnlock (Value);   //��ʹ����VarArratLock()�����Ժ�һ��Ҫ�ô˺�����Ȼ�ᱨ���!
  end else
  begin
    WriteByte(2);                                    //˵������������
    VarData := TVarData(Value);
    case VarData.VType and varTypeMask of
      varEmpty, varNull:begin
        writeInteger(varEmpty);
      end;
      varString:begin
        writeInteger(varString);
        WriteAnsiString(Value);
      end;
      varOleStr:begin
        writeInteger(varOleStr);
        WriteString(Value);
      end;
      varSmallint, varInteger,varError, varBoolean, varShortInt,
       varByte, varWord,varLongWord:begin
        writeInteger(varInteger);
        writeInteger(Value);
      end;
      varSingle, varDouble, varCurrency,varDate:begin
        writeInteger(varDouble);
        WriteDouble(Value);
      end;
      varInt64:begin
        writeInteger(varInt64);
        WriteInt64(value);
      end;
    end;
  end;
end;

procedure TGLStreamPatch.WriteTGUID(Value: TGUID);
begin
  WriteBuffer(Value,SizeOf(TGUID));
end;

procedure TGLStreamPatch.WriteString(Value: String; WriteLen: Boolean = True);
var
  len:integer;
begin
  len := Length(Value);
  if WriteLen then
    writeInteger(len);
  WriteBuffer(Value[1],len*sizeof(Char));
end;

procedure TGLStreamPatch.WriteStringEx(Value: String; WriteLen: Boolean;
  Encoding: TEncoding; WriteBom: Boolean);
var
  bytesH,BytesC:TBytes;
  len:Integer;
begin
  len := 0;
  if Encoding=nil then
    Encoding := TEncoding.Default;
  if WriteBom then
  begin
    bytesH := Encoding.GetPreamble;
    len := Length(bytesH);
  end;
  BytesC := Encoding.GetBytes(Value);
  len := len + Length(BytesC);
  if WriteLen then
  begin
    writeInteger(len);
  end;
  if WriteBom then
    WriteBuffer(bytesH[0],Length(bytesH));
  WriteBuffer(BytesC[0],Length(BytesC));
end;

procedure TGLStreamPatch.WriteWord(Value: Word);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Cardinal);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: TDateTime);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Integer);
begin
 WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Boolean);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Word);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Int64);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: NativeInt);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Extended);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Double);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: Single);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: TGUID);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

procedure TGLStreamPatch.WriteEx(Value: NativeUInt);
begin
  WriteBuffer(Value,SizeOf(Value));
end;

{ TGLMemStreamPatch }

procedure TGLMemStreamPatch.FreePre;
var
  NewSize:int64;
  newMemory:Pointer;
begin
  NewSize := Size - Position;
  newMemory := Memory;
  MoveMemory(newMemory,Pointer(Integer(Memory)+Position),NewSize);
  Position := 0;
  SetSize(NewSize);
end;

function TGLMemStreamPatch.ReadLineA(out Data: String): Boolean;
var
  EndTag:Word;
  I: Integer;
begin
  Result := False;
  Data := '';
  for I := Position to Size - 1 do
  begin
    EndTag := PWord(Integer(Memory)+i)^;
    if EndTag=$0A0D then
    begin
      if I>Position then
        Data := ReadAnsiString(I-Position);
      Result := True;
      Position := Position+2;
      Exit;
    end;
  end;
  if Position<Size then
    Data := ReadAnsiString(Size-Position);
end;

function TGLMemStreamPatch.ReadLineW(out Data: String): Boolean;
var
  EndTag:Word;
  I: Integer;
begin
  Result := False;
  Data := '';
  for I := Position to Size - 1 do
  begin
    EndTag := PWord(Integer(Memory)+i)^;
    if EndTag=$0A0D then
    begin
      if I>Position then
        Data := ReadString(I-Position);
      Result := True;
      Position := Position+2;
      Exit;
    end;
  end;
  if Position<Size then
    Data := ReadString(Size-Position);
end;

procedure TGLMemStreamPatch.WriteLine(Value: AnsiString);
begin
  Value.Append(#13#10);
  WriteAnsiString(value,False);
end;

procedure TGLMemStreamPatch.WriteLineW(Value: String);
begin
  WriteString(value+#13#10,False);
end;

{$IFDEF MSWINDOWS}

function TGLMemoryMap.Map(aFile: THandle; aCustomSize: NativeUInt; aCustomOffset: Int64): boolean;
  function FileSeek64(Handle: THandle; const Offset: Int64; Origin: DWORD): Int64;
  var R64: packed record Lo, Hi: integer; end absolute Result;
  begin
    Result := Offset;
    R64.Lo := integer(SetFilePointer(Handle,R64.Lo,@R64.Hi,Origin));
    if (R64.Lo=-1) and (GetLastError<>0) then
      R64.Hi := -1; // so result=-1
  end;

var Available: Int64;
begin
  result := false;
  fBuf := nil;
  fMap := 0;
  fFileLocal := false;
  fFile := aFile;
  fFileSize := FileSeek64(fFile,0,soFromEnd);
  if (fFileSize<=0) or (fFileSize>maxInt) then
    /// maxInt = $7FFFFFFF = 1.999 GB (2GB would induce PtrInt errors)
    exit;
  if aCustomSize=0 then
    fBufSize := Int64Rec(fFileSize).Lo else begin
    Available := fFileSize-aCustomOffset;
    if Available<0 then
      exit;
    if aCustomSize>Available then
      fBufSize := Int64Rec(Available).Lo;
      fBufSize := aCustomSize;
  end;
  with Int64Rec(fFileSize) do
    fMap := CreateFileMapping(fFile,nil,PAGE_READONLY,Hi,Lo,nil);
  if fMap=0 then
    raise Exception.Create('MemoryMap.Map');
  with Int64Rec(aCustomOffset) do
    fBuf := MapViewOfFile(fMap,FILE_MAP_READ,Hi,Lo,fBufSize);
  if fBuf=nil then begin
    // Windows failed to find a contiguous VA space -> fall back on direct read
    CloseHandle(fMap);
    fMap := 0;
  end else
    result := true;
end;

procedure TGLMemoryMap.Map(aBuffer: pointer; aBufferSize: NativeUInt);
begin
  fBuf := aBuffer;
  fFileSize := aBufferSize;
  fBufSize := aBufferSize;
  fMap := 0;
  fFile := 0;
  fFileLocal := false;
end;

function TGLMemoryMap.Map(const aFileName: TFileName): boolean;
var F: THandle;
begin
  result := false;
  F := FileOpen(aFileName,fmOpenRead or fmShareDenyNone);
  if F=INVALID_HANDLE_VALUE then
    exit;
  if Map(F)  then
    result := true else
    FileClose(F);
  fFileLocal := result;
end;

procedure TGLMemoryMap.UnMap;
begin
  if fMap<>0 then begin
    UnmapViewOfFile(fBuf);
    CloseHandle(fMap);
    fMap := 0;
    if fFileLocal then
      FileClose(fFile);
    fFile := 0;
  end;
end;

{ TGLMapFileStream }

constructor TGLMapFileStream.Create(const aFileName: TFileName);
begin
  fFileStream := TFileStream.Create(aFileName,fmOpenRead or fmShareDenyNone);
  Create(fFileStream.Handle);
end;

constructor TGLMapFileStream.Create(aFile: THandle);
begin
  if not fMap.Map(aFile) then
    raise Exception.CreateFmt('%s mapping error',[ClassName]);
  inherited Create();
  SetPointer(fMap.fBuf,fMap.fBufSize);
end;

destructor TGLMapFileStream.Destroy;
begin
  fMap.UnMap;
  fFileStream.Free;
  inherited
end;

{$ENDIF}

end.

