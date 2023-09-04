unit GLMemoryTbl;

interface
uses GLHashTableEx,SyncObjs,SysUtils;

Type
  TPtrCmpFunc = function(first, second: Pointer): Integer of object;         //比较函数
  TPtrFunc = procedure (first, second: Pointer);
  TDeleteItem = procedure (first, second: Pointer) of object;

  TTblItem = record
    Key:Pointer;
    Index:Cardinal;               //在动态数组中的位置,删除时找到了这个数据,再去找动态数组中的位置
    Data:Pointer;                //数据
  end;
  PTblItem = ^TTblItem;
  TblItemRecLst = array of TTblItem;
  TblItemLst = array of PTblItem;

  TGLMemoryTbl = class
  private
    FLocker:TMREWSync;
    FTblData : TblItemLst;
    FDataCount:Cardinal;
    FSize:integer;
  public
    constructor Create(Asize:Integer);
    destructor Destroy; override;

    function LockRead:TblItemLst;
    procedure UnLockRead;

    procedure LockWrite;
    procedure UnLockWrite;

    property DataCount: Cardinal read FDataCount write FDataCount;
    property Size: integer read FSize write FSize;
  end;

  /// <remarks>
  /// Key为Str的内存表
  /// </remarks>
  TGLMemoryTblStr = class(TGLMemoryTbl)
  private
    FKeyHash:TGLStrHashTable;
    FSortCompareFunc: TPtrCmpFunc;
    FOnDelItem:TDeleteItem;
    function GetCount: Integer;
    function GetItemByKey(Key: String): Pointer;
    function GetItems(Index: Integer): Pointer;
    function SortCompare(first, second: Pointer): Integer;
  public
    constructor Create(Asize:Integer);
    destructor Destroy; override;
    
    function Add(Key:string;Value:Pointer): Boolean;
    function Del(Key:String; AllAfter: Boolean = false):Pointer;
    procedure Sort;

    property Count: Integer read GetCount;
    property ItemsByKey[Key: String]: Pointer read GetItemByKey;
    property Items[Index: Integer]: Pointer read GetItems;
    property SortCompareFunc: TPtrCmpFunc read FSortCompareFunc write
        FSortCompareFunc;
    property OnDelItem:TDeleteItem read FOnDelItem write FOnDelItem;
  end;


  /// <remarks>
  /// Key为Str的内存表
  /// </remarks>
  TGLMemoryTblInt = class(TGLMemoryTbl)
  private
    FKeyHash:TGLIntHashTable;
    FSortCompareFunc: TPtrCmpFunc;
    FOnDelItem:TDeleteItem;
    function GetCount: Integer;
    function GetItemByKey(Key: Integer): Pointer;
    function GetItems(Index: Integer): Pointer;
    function SortCompare(first, second: Pointer): Integer;
  public
    constructor Create(Asize:Integer);
    destructor Destroy; override;
    
    function Add(Key: Integer; Value: Pointer): Boolean;
    function Del(Key: Integer; AllAfter: Boolean = false): Pointer;
    procedure Sort;

    property Count: Integer read GetCount;
    property ItemsByKey[Key: integer]: Pointer read GetItemByKey;
    property Items[Index: Integer]: Pointer read GetItems;
    property SortCompareFunc: TPtrCmpFunc read FSortCompareFunc write
        FSortCompareFunc;
    property OnDelItem:TDeleteItem read FOnDelItem write FOnDelItem;
  end;

implementation

uses GLPubFunc,GLLogger;


procedure Swap(first, second: Pointer);
var
  tem:Pointer;
  Index1,Index2:integer;
begin
  Index1 := PTblItem(first^)^.Index;
  index2 := PTblItem(second^)^.Index;

  tem := PTblItem(first^);
  PTblItem(first^) := PTblItem(second^);
  PTblItem(second^) := tem;
  PTblItem(first^)^.Index := index1;
  PTblItem(second^)^.Index := index2;

//  tem := PTblItem(first^)^;
//  PTblItem(first^)^.Data := PTblItem(second^)^.Data;
////  PTblItem(first^)^.Index := PTblItem(second^)^.Index;
//  PTblItem(second^)^.Data := tem.Data;
////  PTblItem(second^)^.Index := tem.Index;
end;


//function DeleteArrItem(PArray:Pointer;DelIndex:Integer;ItemSize:integer;DelCount:integer;
//    Count:integer):Boolean;
//var
//  P:Pinteger;
//begin
//  Result := False;
//  if DelIndex+Delcount>Count then Exit;
//
//  P := Pinteger(Integer(PArray)-sizeof(Integer));
//  if DelIndex+DelCount = Count then    //删除的最后的数据
//  begin
//    P^ := Count-DelCount;
//  end else
//  begin
//    Move(Pointer(Integer(PArray)+(DelIndex+DelCount)*ItemSize)^,Pointer(Integer(PArray)+(DelIndex)*ItemSize)^,(Count - DelIndex-DelCount)*ItemSize);
//    P^ := Count-DelCount;
//  end;
//end;

constructor TGLMemoryTbl.Create(Asize:Integer);
begin
  inherited create;
  FSize := Asize;
  FDataCount := 0;
  SetLength(FTblData,Asize);
  FLocker := TMREWSync.Create;
end;

{ TGLMemoryTblStr }

function TGLMemoryTblStr.Add(Key:string;Value:Pointer): Boolean;
var
  TblItem:PTblItem;
begin
  Result := False;
  New(TblItem);
  FillChar(TblItem^,SizeOf(TTblItem),0);
  TblItem.Data := Value;
  TblItem.Key := PAnsiChar(Key);

  LockWrite;
  try
    if not FKeyHash.Add(Key,TblItem,0) then
    begin
      Dispose(TblItem);
      Exit;
    end;
//    SetLength(FTblData,Length(FTblData)+1);
    TblItem.Index := FDataCount;
    FTblData[FDataCount] := TblItem;
    Inc(FDataCount);
    Result := True;
  finally
    UnLockWrite;
  end;
end;

constructor TGLMemoryTblStr.Create(Asize:Integer);
begin
  inherited Create(Asize);
  FKeyHash := TGLStrHashTable.Create(Asize);
end;

function TGLMemoryTblStr.Del(Key: String; AllAfter: Boolean = false): Pointer;
var
  TblItem:PTblItem;
  I:Integer;
  ADataLen:Cardinal;
begin
  Result := nil;
  LockWrite;
  try
    TblItem := FKeyHash.Find(Key,ADataLen);
    if TblItem <>nil then
    begin
      Result := TblItem.Data;
      if AllAfter then      //删除后面所有的．
      begin
        deleteArrItem(FTblData,TblItem.Index,SizeOf(PTblItem),Length(FTblData),Length(FTblData)-TblItem.Index);
        for I := TblItem.Index to Length(FTblData) - 1 do
        begin
          FKeyHash.Remove(StrPas(PAnsiChar(FTblData[I].key)));
          if Assigned(FOnDelItem) then
            FOnDelItem(FTblData[I].key,FTblData[I].Data);
          Dispose(FTblData[I]);
        end;
      end
      else
      begin
        deleteArrItem(FTblData,TblItem.Index,SizeOf(PTblItem),Length(FTblData),1);
        for I := TblItem.Index to Length(FTblData) - 1 do
        begin
          FTblData[I].Index := FTblData[I].Index-1;
        end;
        if Assigned(FOnDelItem) then
          FOnDelItem(FTblData[I].key,FTblData[I].Data);
        Dispose(TblItem);
        FKeyHash.Remove(Key);
      end;
    end;
  finally
    UnLockWrite;
  end;
end;

destructor TGLMemoryTblStr.Destroy;
begin
  FKeyHash.Free;
  inherited;
end;

function TGLMemoryTblStr.GetCount: Integer;
begin
  LockRead;
  try
    Result := FDataCount;
  finally
    UnLockRead;
  end;
end;

function TGLMemoryTblStr.GetItemByKey(Key: String): Pointer;
var
  ADataLen:Cardinal;
begin
  LockRead;
  try
    Result := FKeyHash.Find(Key,ADataLen);
    if Result <>nil then
    begin
      Result := PTblItem(Result).Data;
    end;
  finally
    UnLockRead;
  end;
end;

function TGLMemoryTblStr.GetItems(Index: Integer): Pointer;
begin
  result := nil;
  LockRead;
  try
    if (Index<0) or (Index>High(FTblData)) then Exit;
    Result := FTblData[index]^.Data;
  finally
    UnLockRead;
  end;
end;


function TGLMemoryTblStr.SortCompare(first, second: Pointer): Integer;
begin
  Result := FSortCompareFunc(PTblItem(first^).Data,PTblItem(second^).Data);
end;

var
  str:string;

/// <remarks>
/// 快速排序
/// </remarks>
procedure QuickSort(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);
var
  i, j, pidx: LongWord;
  LItem, RItem, Pivot: Pointer;
  LIndex, RIndex: LongWord;
  tem:integer;
begin
  LIndex := 0;
  RIndex := nItemCount - 1;
  while LIndex < RIndex do
  begin
    i := LIndex;
    j := RIndex;
    pidx := (i + j) shr 1;
    Pivot := Pointer(LongWord(pArray) + nItemSize * pidx);
    repeat
      while pCompare(Pointer(LongWord(pArray) + nItemSize * i), Pivot) < 0 do inc(i);
      while pCompare(Pointer(LongWord(pArray) + nItemSize * j), Pivot) > 0 do Dec(j);
      if i < j then
      begin
        LItem := Pointer(LongWord(pArray) + nItemSize * i);
        RItem := Pointer(LongWord(pArray) + nItemSize * j);
        pSwap(LItem, RItem);
        if i = pidx then
        begin
          pidx := j;
          Pivot := RItem;
        end
        else if j = pidx then
        begin
          pidx := i;
          Pivot := LItem;
        end;
        Inc(i);
        Dec(j);
      end
      else if i = j then Inc(i);
    until i >= j;
    if LIndex < j then
      QuickSort(Pointer(LongWord(pArray) + nItemSize * LIndex),
        nItemSize, j - LIndex + 1, pCompare, pSwap);
    LIndex := i;
  end;
end;

procedure TGLMemoryTblStr.Sort;
begin
  LockWrite;
  try
    if Assigned(FSortCompareFunc) then
      QuickSort(FTblData,SizeOf(PTblItem),FDataCount,SortCompare,swap);
  finally
    UnLockWrite;
  end;
end;

destructor TGLMemoryTbl.Destroy;
var
  I:integer;
begin
  FLocker.BeginWrite;
  try
    for I := 0 to Length(FTblData) - 1 do
    begin
      if FTblData[I]<>nil then
        Dispose(FTblData[I]);
    end;
    SetLength(FTblData,0);
  finally
    FLocker.EndWrite;
  end;
  FLocker.Free;
  inherited;
end;

procedure TGLMemoryTbl.LockWrite;
begin
  FLocker.BeginWrite;
end;

function TGLMemoryTbl.LockRead: TblItemLst;
begin
  FLocker.BeginRead;
  Result := FTblData;
end;

procedure TGLMemoryTbl.UnLockRead;
begin
  FLocker.EndRead;
end;

procedure TGLMemoryTbl.UnLockWrite;
begin
  FLocker.EndWrite;
end;

{ TGLMemoryTblInt }

function TGLMemoryTblInt.Add(Key: Integer; Value: Pointer): Boolean;
var
  TblItem:PTblItem;
  str:string;
begin
  try
    Result := False;
    str := '1';
    New(TblItem);
    str := '2';
    FillChar(TblItem^,SizeOf(TTblItem),0);
    str := '3';
    TblItem.Data := Value;
    str := '4';
    TblItem.Key := PAnsiChar(Key);
    str := '5';
    LockWrite;
    try
      str := '6';
      if not FKeyHash.Add(Key,TblItem,0) then
      begin
        str := '7';
        Dispose(TblItem);
        Exit;
      end;
      str := '8';
//      SetLength(FTblData,Length(FTblData)+1);
      str := '9';
      TblItem.Index :=FDataCount;
      str := '10';
      FTblData[FDataCount] := TblItem;
      Inc(FDataCount);
      str := '11';
      Result := True;
    finally
      UnLockWrite;
    end;
  except
    logger.WriteLog(LTError,'TGLMemoryTblInt.Add 行:'+LastErrMsg+'  '+str);
  end;
end;

constructor TGLMemoryTblInt.Create(Asize:Integer);
begin
  inherited Create(Asize);
  FKeyHash := TGLIntHashTable.Create(Asize);
end;


function TGLMemoryTblInt.Del(Key: Integer; AllAfter: Boolean = false): Pointer;
var
  TblItem:PTblItem;
  I:Integer;
  tem,ADataLen:Cardinal;
begin
  Result := nil;
  LockWrite;
  try
    TblItem := FKeyHash.Find(Key,ADataLen);
    if TblItem <>nil then
    begin
      tem := tblItem.Index;
      if AllAfter then      //删除后面所有的．
      begin
        for I := tem to Length(FTblData) - 1 do
        begin
          FKeyHash.Remove(Integer(FTblData[I].key));
          if Assigned(FOnDelItem) then
            FOnDelItem(FTblData[I].key,FTblData[I].Data);
          Dispose(FTblData[I]);
        end;
        deleteArrItem(FTblData,tem,SizeOf(PTblItem),Length(FTblData),Length(FTblData)-tem);
      end
      else
      begin
        deleteArrItem(FTblData,tem,SizeOf(PTblItem),Length(FTblData),1);
        for I := tem to Length(FTblData) - 1 do
        begin
          FTblData[I].Index := FTblData[I].Index-1;
        end;
        if Assigned(FOnDelItem) then
           FOnDelItem(TblItem.key,TblItem.Data);
        Dispose(TblItem);
        FKeyHash.Remove(Key);
      end;
    end;
  finally
    UnLockWrite;
  end;
end;

destructor TGLMemoryTblInt.Destroy;
begin
  FKeyHash.Free;
  inherited;
end;

function TGLMemoryTblInt.GetCount: Integer;
begin
  LockRead;
  try
    Result := FDataCount;
  finally
    UnLockRead;
  end;
end;

function TGLMemoryTblInt.GetItemByKey(Key: Integer): Pointer;
var
  ADataLen:Cardinal;
begin
  Result := FKeyHash.Find(Key,ADataLen);
  if Result <>nil then
  begin
    Result := PTblItem(Result).Data;
  end;
end;

function TGLMemoryTblInt.GetItems(Index: Integer): Pointer;
begin
  result := nil;
  LockRead;
  try
    if (Index<0) or (Index>High(FTblData)) then Exit;
    Result := FTblData[index].Data;
  finally
    UnLockRead;
  end;
end;

procedure TGLMemoryTblInt.Sort;
begin
  LockWrite;
  try
    if Assigned(FSortCompareFunc) then
      QuickSort(FTblData,SizeOf(PTblItem),FDataCount,SortCompare,swap);
  finally
    UnLockWrite;
  end;
end;

function TGLMemoryTblInt.SortCompare(first, second: Pointer): Integer;
begin
  Result := FSortCompareFunc(PTblItem(first^).Data,PTblItem(second^).Data);
end;

end.
