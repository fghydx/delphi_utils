unit GLHashTable;

interface

uses SyncObjs,Windows,GLTypeDef;

type
  PHashTableItem = ^THashTableItem;
  /// <author>Hash���ݴ������</author>
  THashTableItem = record
         Key : string;                  //�ַ���Keyֵ
        Data : Pointer;                 //���ݴ�ŵ�ַ
        DataLen:integer;                //���ݳ���
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

Type
  TGLHashTable = class
  private
    FCharCase: Boolean;
    Flocker:TCriticalSection;  //���ɾ����ʱ����ͬ������
    FSize,FContentSize: cardinal;
    FHashList : array of PHashTableItem;
    FCustomHashMethod: TCustomHashMethod;
    FHashAlgorithm: THashAlgorithm;
    FItemCount: cardinal;
    function GetHashCode(AKey:string):Cardinal;
    procedure AddHashItem(HashCode:Cardinal;HashItem:PHashTableItem);
    function GetHashItem(AKey:string):THashItemInfo;
    procedure DisposeHashItem(AHashItem:PHashTableItem);
  public
    constructor Create(size:Cardinal);virtual;
    destructor Destroy; override;
    /// <remarks>
    /// ���һ��Hash���ݣ�������ͨ��CopyMem�ģ����Ե�������Ӻ�ԭʼDataҪ�ͷŵ�
    /// </remarks>
    procedure Add(AKey:string;Data:Pointer;DataLen:Cardinal);
    /// <remarks>
    /// ����Key�ҵ���Ӧ���û�Data����
    /// </remarks>
    function  Find(AKey:string):Pointer;
    /// <remarks>
    /// ������Hahsh�����Ƴ��������Data��Դ��Ҫ�����ͷ�
    /// </remarks>
    procedure Remove(AKey:string);

    procedure Clear;

    /// <remarks>
    /// �Ƿ����ִ�Сд
    /// </remarks>
    property CharCase: Boolean read FCharCase write FCharCase default True;
    /// <remarks>
    /// ѡ������Hash�㷨��������Զ���Hash�㷨�������Զ����
    /// </remarks>
    property HashAlgorithm: THashAlgorithm read FHashAlgorithm write FHashAlgorithm;
    /// <remarks>
    /// Hash���е�ǰ���ڵ�Ԫ�ظ���
    /// </remarks>
    property ItemCount: cardinal read FItemCount;
    /// <remarks> Hash������ռ�ÿռ��С��ָ��ֻ��һ��Integer����
    /// </remarks>
    property ContentSize: cardinal read FContentSize;
    /// <remarks>
    /// �Զ���Hash�㷨
    /// </remarks>
    property CustomHashMethod: TCustomHashMethod read FCustomHashMethod write
        FCustomHashMethod;
  end;

implementation

uses GLHashAlgorithm,System.SysUtils;

{ TGLHashTable }

procedure TGLHashTable.Add(AKey: string; Data: Pointer;DataLen:Cardinal);
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
  HashItem.NextItem := nil;
  AddHashItem(HashCode,HashItem);
end;

procedure TGLHashTable.AddHashItem(HashCode: Cardinal;
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

procedure TGLHashTable.Clear;
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

constructor TGLHashTable.Create(size: Cardinal);
begin
  FHashAlgorithm := HADefault;
  FCharCase := True;
  Fsize := size;
  SetLength(FHashList,Fsize);
  FillChar(FHashList[0],sizeof(PHashTableItem)*Fsize,0);
  Flocker := TCriticalSection.Create;
end;

destructor TGLHashTable.Destroy;
begin
  Clear;
  Flocker.Free;
  inherited;
end;

procedure TGLHashTable.DisposeHashItem(AHashItem: PHashTableItem);
begin
  if AHashItem<>nil then
  begin
    if AHashItem.NextItem<>nil then
    begin
      DisposeHashItem(AHashItem.NextItem);
    end;
    AHashItem.Key := '';
    if AHashItem.DataLen>0 then
      FreeMemory(AHashItem.Data);
    Dispose(AHashItem);
  end;
end;

function TGLHashTable.Find(AKey: string): Pointer;
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

function TGLHashTable.GetHashCode(AKey: string): Cardinal;
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

function TGLHashTable.GetHashItem(AKey: string): THashItemInfo;
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

procedure TGLHashTable.Remove(AKey: string);
var
  HashItemInfo:THashItemInfo;
  HashItem:PHashTableItem;
begin
  HashItemInfo := GetHashItem(AKey);
  if HashItemInfo.CurrItem<>nil then
  begin
    HashItem := HashItemInfo.CurrItem;
    
    Flocker.Enter;
    try
      if HashItemInfo.FrontItem<>nil then    
        HashItemInfo.FrontItem.NextItem := HashItem.NextItem
      else
        FHashList[GetHashCode(AKey)] := nil;
      if HashItem.DataLen>0 then
      begin
        Dec(FContentSize,Hashitem.DataLen);
        FreeMemory(HashItem.Data);
      end else
      begin
        Dec(FContentSize,sizeof(Integer));
      end;
      Dispose(HashItem);
      Dec(FItemCount);

    finally
      Flocker.Leave;
    end;
  end;  
end;

end.
