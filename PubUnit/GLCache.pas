/// <remarks>
/// ���LoadFromFileʱ���ڴ�й©�����ù��߲�
/// </remarks>
unit GLCache;

interface

uses SyncObjs,Windows,Classes,IniFiles,DateUtils,SysUtils,GLTypeDef;

const
  CacheFileStart = 'Cache:';
  CacheFileEnd = 'CacheEnd.';

type
  PHashTableItem = ^THashTableItem;
  /// <author>Hash���ݴ������</author>
  THashTableItem = record
         Key : string;                  //�ַ���Keyֵ
        Data : Pointer;                 //���ݴ�ŵ�ַ
        DataLen:integer;                //���ݳ���
        TimeOut:Int64;                  //��ʱʱ��
    NextItem : PHashTableItem;          //���Hashֵ��ͬ������������һ����ַ
  end;

  /// <author>�ڵ���Ϣ����һ�ڵ㣬��ǰ�ڵ�,����ɾ����ʱ����</author>
  THashItemInfo = record
    FrontItem:PHashTableItem;
     CurrItem:PHashTableItem;
  end;
  
  /// <remarks>
  /// �Զ���Hash�㷨
  /// </remarks>
  TCustomHashMethod = function(Akey:string;TableSize:Cardinal):Integer of object;
  /// <remarks>
  /// �Ƴ�ִ���¼�
  /// </remarks>
  TOnRemoveItem = procedure(HashTableItem:THashTableItem) of object;

Type
  TTimeoutCheckThread = class;

  TGLCacheCustom = class
  private
    FCharCase: Boolean;
    Flocker:TCriticalSection;  //���ɾ����ʱ����ͬ������
    Fsize,FContentSize:Cardinal;
    FHashList : array of PHashTableItem;
    FCustomHashMethod : TCustomHashMethod;
    FHashAlgorithm: THashAlgorithm;
    FItemCount: cardinal;
    TimeoutCheckThread:TTimeoutCheckThread;
    /// <remarks>
    /// ��ʱList���г�ʱ��CacheData�ż���������
    /// </remarks>
    TimeoutCacheDataList: THashedStringList;
    /// <remarks>
    /// �Ƴ�ִ���¼�
    /// </remarks>
    FOnRemoveItem:TOnRemoveItem;
    function GetHashCode(AKey:string):Cardinal;
    procedure AddHashItem(HashCode:Cardinal;HashItem:PHashTableItem);
    function GetHashItem(AKey:string):THashItemInfo;
    procedure DisposeHashItem(AHashItem:PHashTableItem);
  public
    constructor Create(size:Cardinal);
    destructor Destroy; override;
    /// <remarks>
    /// ���һ��Hash���ݣ����DataLen>0������ͨ��CopyMem�ģ����Ե�������Ӻ�ԭʼDataҪ�ͷŵ�,������ӵ���ԭʼ��ַ
    ///  TimeOutֵ���������0��������볬ʱ����  ����Ϊ��Ϊ
    /// </remarks>
    procedure Add(AKey: string; Data: Pointer; DataLen: Cardinal; TimeOut: int64 = 60);
    /// <remarks>
    /// ����Key�ҵ���Ӧ���û�Data����
    /// </remarks>
    function  Find(AKey:string):Pointer;
    /// <remarks>
    /// ���DataLen=0������Hahsh�����Ƴ��������Data��Դ��Ҫ�����ͷ�,��� DataLen>0��˵���ǿ��������ģ��������ͷ�Data��Դ
    /// </remarks>
    procedure Remove(AKey:string);

    /// <remarks>
    /// �������ó�ʱʱ��  //����û��Ҫ���Ȳ�ʵ��
    /// </remarks>
//    procedure ReSetTimeOut(AKey:string;TimeOut:Int64);

    /// <remarks>
    /// ���
    /// </remarks>
    procedure Clear;

    /// <remarks>
    /// �Ƴ���ʱ��
    /// </remarks>
    procedure RemoveTimeOutItems;

    /// <remarks>
    /// ���ó�ʱʱ��
    /// </remarks>
    procedure UpdateCacheTimeOut(AKey: string; Timeout: Cardinal = 60);

    /// <remarks>
    /// ��Cache�ļ�д���ļ�����ļ���ȡ������д�ļ�ʱ�������в���Ƕ��ָ�����͵����ݣ�ֻ��ͨ��CopyMemory��AddʱDataLen>0����Data�Żᱻд���ļ�
    /// </remarks>
    procedure SaveToFile(FileName:string);virtual;
    procedure LoadFromFile(FileName:string);virtual;

    property CharCase: Boolean read FCharCase write FCharCase default True;
    property HashAlgorithm: THashAlgorithm read FHashAlgorithm write FHashAlgorithm;
    /// <remarks>
    /// ��ǰ������Ԫ�ظ���
    /// </remarks>
    property ItemCount: cardinal read FItemCount;
    /// <remarks>
    /// ����ռ���ڴ��С��ָ��Ļ�ΪsizeOf(Integer)
    /// </remarks>
    property ContentSize: cardinal read FContentSize;
    property CustomHashMethod : TCustomHashMethod read FCustomHashMethod write FCustomHashMethod;
    property OnRemoveItem:TOnRemoveItem read FOnRemoveItem write FOnRemoveItem;
  end;

  TTimeoutCheckThread = class(TThread)
  private
    Owner:TGLCacheCustom;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner:TGLCacheCustom);
  end;

  TGLCache = class(TGLCacheCustom)
  public
    procedure AddString(AKey, AStrData: string; Timeout: Cardinal = 60);
    function GetString(AKey:string):string;
    procedure AddInteger(AKey:string;I:Integer;Timeout: Cardinal = 60);
    function GetInteger(AKey:string):integer;
    procedure AddFloat(AKey:string;value:Extended;Timeout:Cardinal = 60);
    function GetFloat(AKey:string):Extended;
    procedure AddInt64(Akey:string;Value:Int64;Timeout: Cardinal = 60);
    function GetInt64(Akey:string):Int64;
    procedure AddPointer(AKey:string;Data:Pointer;DataLen:Integer;Timeout: Cardinal = 60);
    function GetPointer(AKey:string;Out DataLen:Integer): Pointer;
  end;

implementation

uses GLHashAlgorithm;

{ TGLCacheCustom }

procedure TGLCacheCustom.Add(AKey: string; Data: Pointer; DataLen: Cardinal; TimeOut:
    int64 = 60);
var
  HashCode:Cardinal;
  HashItem:PHashTableItem;
begin
  HashCode := GetHashCode(AKey);

  New(HashItem);
  FillChar(HashItem^,SizeOf(THashTableItem),0);
  HashItem.Key := AKey;

  if DataLen<=0 then
  begin
    HashItem.Data := Data;
  end else
  begin
    HashItem.Data := GetMemory(DataLen);
    CopyMemory(HashItem.Data,Data,DataLen);
  end;
  HashItem.DataLen := DataLen;
  if TimeOut>0 then
    HashItem.TimeOut := DateTimeToUnix(Now) + TimeOut;
  HashItem.NextItem := nil;
  AddHashItem(HashCode,HashItem);
end;

procedure TGLCacheCustom.AddHashItem(HashCode: Cardinal;
  HashItem: PHashTableItem);
var
  TemHashItem:PHashTableItem;
begin
  Flocker.Enter;
  try
    if FHashList[HashCode]=nil then
    begin
      FHashList[HashCode] := HashItem;
    end else
    begin
      TemHashItem := FHashList[HashCode];
      while TemHashItem.NextItem<>nil do
      begin
        TemHashItem := TemHashItem.NextItem;
      end;
      TemHashItem.NextItem := HashItem;
    end;
    if HashItem.TimeOut>0 then             //��ʱʱ�����0�����볬ʱ�б�
    begin
      TimeoutCacheDataList.AddObject(HashItem.Key,TObject(HashItem.TimeOut));
    end;
    inc(FItemCount);
    if HashItem.DataLen>0 then
    begin
      Inc(FContentSize,Hashitem.DataLen);
    end else
    begin
      Inc(FContentSize,SizeOf(Integer));
    end;
  finally
    Flocker.Leave;
  end;
end;

procedure TGLCacheCustom.Clear;
var
  I: Integer;
  HashItem:PHashTableItem;  
begin
  Flocker.Enter;
  try
    for I := 0 to Fsize - 1 do
    begin
      if FHashList[I]<>nil then
      begin
        HashItem := FHashList[I];
        DisposeHashItem(HashItem);
      end;
      FHashList[I]:= nil;
    end;
  finally
    Flocker.Leave;
  end;
end;

constructor TGLCacheCustom.Create(size: Cardinal);
begin
  FHashAlgorithm := HADefault;
  FCharCase := True;
  Fsize := size;
  SetLength(FHashList,Fsize);
  FillChar(FHashList[0],sizeof(PHashTableItem)*Fsize,0);
  Flocker := TCriticalSection.Create;
  TimeoutCacheDataList := THashedStringList.Create;
  TimeoutCheckThread := TTimeoutCheckThread.Create(Self);
end;

destructor TGLCacheCustom.Destroy;
begin
  TimeoutCheckThread.Terminate;
  WaitForSingleObject(TimeoutCheckThread.Handle,1000);
  Clear;
  Flocker.Free;
  TimeoutCacheDataList.Free;
  inherited;
end;

procedure TGLCacheCustom.DisposeHashItem(AHashItem: PHashTableItem);
var
  str:string;
begin
  if AHashItem<>nil then
  begin
    if AHashItem.NextItem<>nil then
    begin
      DisposeHashItem(AHashItem.NextItem);
    end;
    str := AHashItem.Key;
    AHashItem.Key := '';
    if AHashItem.DataLen>0 then
    begin
      TimeoutCacheDataList.Delete(TimeoutCacheDataList.IndexOf(str));
      FreeMemory(AHashItem.Data);
    end;
    Dispose(AHashItem);
  end;
end;

function TGLCacheCustom.Find(AKey: string): Pointer;
var
  HashItem:PHashTableItem;
begin
  Result := nil;

  HashItem := GetHashItem(AKey).CurrItem;
  if HashItem<>nil then
  begin
    Result := HashItem.Data;
  end;
end;

function TGLCacheCustom.GetHashCode(AKey: string): Cardinal;
begin
  if Assigned(CustomHashMethod) then
    Result := FCustomHashMethod(AKey,Fsize)
  else
  begin
    case FHashAlgorithm of
      HADefault: Result := DefultHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
           HARS: Result := RSHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
           HAJS: Result := JSHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
          HAPJW: Result := PJWHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
          HAELF: Result := ELFHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
         HABKDR: Result := BKDRHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
         HASDBM: Result := SDBMHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
          HADJB: Result := DJBHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
           HAAP: Result := APHash(MarshaledAString(Akey),ByteLength(Akey),CharCase) mod Fsize;
    end;
  end;
end;

function TGLCacheCustom.GetHashItem(AKey: string): THashItemInfo;
var
  HashCode:Cardinal;
  HashItem:PHashTableItem;
begin
  Result.FrontItem := nil;
  Result.CurrItem := nil;
  
  HashCode := GetHashCode(AKey);

  HashItem := FHashList[HashCode];
  if HashItem<>nil then
  begin
    if HashItem.Key=AKey then
    begin
      Result.CurrItem := HashItem;
    end else
    begin
      while HashItem.NextItem<>nil do
      begin
        if HashItem.NextItem.Key=AKey then
        begin
          Result.FrontItem := HashItem;
          Result.CurrItem := HashItem.NextItem;
          Break;
        end;
        HashItem := HashItem.NextItem;
      end;
    end;
  end;
end;

procedure TGLCacheCustom.LoadFromFile(FileName: string);
var
  FileStream:TFileStream;
  str:string;
  len:integer;
  Key:string;
  DataLen:integer;
  Timeout:int64;
  Data:Pointer;
begin
  if not FileExists(FileName) then Exit;

  FileStream := TFileStream.Create(FileName,fmOpenRead or fmShareDenyNone);

  Flocker.Enter;
  try
    SetLength(str,Length(CacheFileStart));
    FileStream.Read(str[1],Length(CacheFileStart));
    if str<>CacheFileStart then Exit; //��ȡ�����Ĳ���Cache�ļ�
    str := '';
    while FileStream.Position<FileStream.Size do
    begin
      FileStream.ReadBuffer(len,SizeOf(integer));
      SetLength(str,len);
      FileStream.Read(str[1],len);
      Key := str;

      FileStream.ReadBuffer(len,SizeOf(integer));
      DataLen := len;
      Data:=GetMemory(len);
      FileStream.ReadBuffer(Data^,len);

      FileStream.ReadBuffer(Timeout,SizeOf(Int64));

      Add(Key,Data,DataLen,Timeout);

      str := '';
      FreeMemory(Data);
    end;
  finally
    Flocker.Leave;
    FileStream.Free;
  end;
end;

procedure TGLCacheCustom.Remove(AKey: string);
var
  HashItemInfo:THashItemInfo;
  HashItem:PHashTableItem;
begin
  Flocker.Enter;
  try
    HashItemInfo := GetHashItem(AKey);
    if HashItemInfo.CurrItem<>nil then
    begin
      HashItem := HashItemInfo.CurrItem;

      if Assigned(FOnRemoveItem) then
        FOnRemoveItem(HashItem^);

      if HashItemInfo.FrontItem<>nil then
        HashItemInfo.FrontItem.NextItem := HashItem.NextItem
      else
        FHashList[GetHashCode(AKey)] := nil;
      if HashItem.DataLen>0 then
      begin
        Dec(FContentSize,HashItem.DataLen);
        TimeoutCacheDataList.Delete(TimeoutCacheDataList.IndexOf(HashItem.Key));
        FreeMemory(HashItem.Data);
      end else
      begin
        Dec(FContentSize,SizeOf(integer));
      end;
      HashItem.Key := '';
      Dispose(HashItem);
      Dec(FItemCount);
    end;
  finally
    Flocker.Leave;
  end;
end;

procedure TGLCacheCustom.RemoveTimeOutItems;
var
  I: Integer;
  Timeout:int64;
  CurTime:Int64;
begin
  Flocker.Enter;
  try
    CurTime := DateTimeToUnix(Now);
    for I := TimeoutCacheDataList.Count - 1 downto 0  do
    begin
      Timeout := int64(TimeoutCacheDataList.Objects[I]);
      if Timeout < CurTime then
      begin
//        if Assigned(FOnTimeOut) then
//        begin
//          FOnTimeOut(GetHashItem(TimeoutCacheDataList[i]).CurrItem);
//        end;
        Remove(TimeoutCacheDataList[i]);
      end;
    end;
  finally
    Flocker.Leave;
  end;
end;

procedure TGLCacheCustom.SaveToFile(FileName: string);
var
  I: Integer;
  HashItem:PHashTableItem;
  FileStream:TFileStream;
  str:string;
  len:integer;
  TimeOut : Int64;
begin
  if not FileExists(FileName) then
  begin
    ForceDirectories(ExtractFileDir(FileName));
    FileStream := TFileStream.Create(FileName,fmCreate or fmOpenWrite or fmShareDenyNone);
  end
  else
    FileStream := TFileStream.Create(FileName,fmOpenWrite or fmShareDenyNone);

  Flocker.Enter;
  try
    str := CacheFileStart;
    FileStream.WriteBuffer(str[1],Length(str));
    for I := 0 to TimeoutCacheDataList.Count - 1 do
    begin
       HashItem := GetHashItem(TimeoutCacheDataList[I]).CurrItem;
       if HashItem.DataLen>0 then
       begin
         //дKey
         str := HashItem.Key;
         len := Length(str);
         FileStream.WriteBuffer(Len,SizeOf(integer));
         FileStream.WriteBuffer(str[1],len);
         //д����
         len := HashItem.DataLen;
         FileStream.WriteBuffer(Len,SizeOf(integer));
         FileStream.WriteBuffer(HashItem.Data^,len);
         //д��ʱ
         TimeOut := HashItem.TimeOut - DateTimeToUnix(Now);
         FileStream.WriteBuffer(TimeOut,SizeOf(Int64));
       end;
    end;
//    str := CacheFileEnd;                           //��ʱ��д�ļ�β
//    FileStream.WriteBuffer(str[1],Length(str));
  finally
    Flocker.Leave;
    FileStream.Free;
  end;
end;

procedure TGLCacheCustom.UpdateCacheTimeOut(AKey: string; Timeout: Cardinal =
    60);
var
  HashItem:PHashTableItem;
begin
  Flocker.Enter;
  try
    HashItem := GetHashItem(AKey).CurrItem;
    if HashItem<>nil then
    begin
       HashItem.TimeOut := DateTimeToUnix(Now)+Timeout;
    end;
  finally
    Flocker.Leave;
  end;
end;

{ TTimeoutCheckThread }

constructor TTimeoutCheckThread.Create(AOwner: TGLCacheCustom);
begin
  inherited Create(False);
  Owner := AOwner;
  FreeOnTerminate := True;
end;

procedure TTimeoutCheckThread.Execute;
var
  LastCheck:int64;
begin
  inherited;
  LastCheck := DateTimeToUnix(Now);
  while not Terminated do
  begin
    if DateTimeToUnix(Now)-LastCheck>10 then        //10���һ�Σ����Ի���������10������
    begin
      Owner.RemoveTimeOutItems;
      LastCheck := DateTimeToUnix(Now);
    end else
    begin
      Sleep(100);
    end;
  end;
end;

{ TGLCache }

procedure TGLCache.AddFloat(AKey: string; value: Extended; Timeout: Cardinal);
begin
  Add(AKey,@value,SizeOf(Extended),Timeout);
end;

procedure TGLCache.AddInt64(Akey: string; Value: Int64; Timeout: Cardinal);
begin
  Add(AKey,@Value,SizeOf(Int64),Timeout);
end;

procedure TGLCache.AddInteger(AKey: string; I: Integer; Timeout: Cardinal);
begin
  Add(AKey,@I,SizeOf(Integer),Timeout);
end;

procedure TGLCache.AddPointer(AKey: string; Data: Pointer; DataLen: Integer;
  Timeout: Cardinal);
begin
  Add(AKey,Data,DataLen,Timeout);
end;

procedure TGLCache.AddString(AKey, AStrData: string; Timeout: Cardinal = 60);
begin
  if Length(AStrData)<=0 then  Exit;
    Add(AKey,@AstrData[1],Length(AStrData),Timeout);
end;

function TGLCache.GetFloat(AKey: string): Extended;
var
  P:PHashTableItem;
begin
  Result := 0;
  P := GetHashItem(AKey).CurrItem;
  if P<>nil then
  begin
    CopyMemory(@result,p^.Data,p^.DataLen);
  end;
end;

function TGLCache.GetInt64(Akey: string): Int64;
var
  P:PHashTableItem;
begin
  Result := 0;
  P := GetHashItem(AKey).CurrItem;
  if P<>nil then
  begin
    CopyMemory(@result,p^.Data,p^.DataLen);
  end;
end;

function TGLCache.GetInteger(AKey: string): integer;
var
  P:PHashTableItem;
begin
  Result := 0;
  P := GetHashItem(AKey).CurrItem;
  if P<>nil then
  begin
    CopyMemory(@result,p^.Data,p^.DataLen);
  end;
end;

function TGLCache.GetPointer(AKey:string;Out DataLen:Integer): Pointer;
var
  P:PHashTableItem;
begin
  Result := nil;
  DataLen := 0;
  P := GetHashItem(AKey).CurrItem;
  if P<>nil then
  begin
    Result := P.Data;
    DataLen := P.DataLen;
  end;
end;

function TGLCache.GetString(AKey: string): string;
var
  P:PHashTableItem;
begin
  Result := '';
  P := GetHashItem(AKey).CurrItem;
  if P<>nil then
  begin
    SetLength(Result,p^.DataLen);
    CopyMemory(@result[1],p^.Data,p^.DataLen);
  end;
end;

end.
