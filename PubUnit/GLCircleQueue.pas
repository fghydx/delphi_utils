/// <remarks>
/// 环形队列
/// </remarks>
unit GLCircleQueue;

interface

uses GLSyncObj,Windows,GLLogger,SysUtils;

Type
  ArrayPoint = array of Pointer;

  PQueueData = ^TQueueData;
  TQueueData = record
    Data : Pointer;
    Next:PQueueData;
  end;

  TOnFreeItem = procedure(Data:Pointer) of object;

  TGLCircleQueue = class
  private
    FPopArr:Boolean;                          //是否批量弹出
    FAutoExpansion: Boolean;
    FCount: Cardinal;
    FSynobj:TGLCriticalSection;
    FSemaphore:THandle;
    FSize: Cardinal;
    FHead: PQueueData;                          //队头指针
    FMaxSize: Cardinal;
    FOnFreeItem: TOnFreeItem;
    FPopBlock: Boolean;
    FTail: PQueueData;
    procedure InitLinkTbl;
    Procedure ReSetCircle;
    procedure SetSize(const Value: Cardinal);                      //对这个圈扩容

  public
    constructor Create(size: cardinal);
    destructor Destroy; override;
    procedure SetEvent(EventCount: Integer = 1);
    
    function Pop: Pointer;
    function Push(Data: Pointer): Boolean;
    function PushArrData(Data:ArrayPoint):ArrayPoint;
    function PopArrData:ArrayPoint;
    /// <remarks>
    /// 是否自动扩容，否的话，达到队列上限会把之后的数据抛弃
    /// </remarks>
    property AutoExpansion: Boolean read FAutoExpansion write FAutoExpansion
        default True;
    property Count: Cardinal read FCount;
    /// <remarks>
    /// 如果自动扩容，最大上限不能超过这个值
    /// </remarks>
    property MaxSize: Cardinal read FMaxSize write FMaxSize;
    property PopArr : boolean read FPopArr write FPopArr;
    property PopBlock: Boolean read FPopBlock write FPopBlock;
    property Size: Cardinal read FSize write SetSize;
    property OnFreeItem : TOnFreeItem read FOnFreeItem write FOnFreeItem;
  end;

implementation

uses GLPubFunc;

constructor TGLCircleQueue.Create(size: cardinal);
begin
  FSemaphore := CreateSemaphore(nil,0,MAXLONG,nil);
  FSynobj := TGLCriticalSection.Create;
  FSize := size;
  FMaxSize := FSize * 4;
  FAutoExpansion := True;
  FPopArr := False;
  InitLinkTbl;
end;

destructor TGLCircleQueue.Destroy;
var
  tem:PQueueData;
  I: Integer;
begin
  for I := 0 to FSize - 1 do
  begin
    tem := FHead;
    if Assigned(FOnFreeItem) and (tem.Data<>nil) then
      FOnFreeItem(tem.Data);
    FHead := FHead.Next;
    Dispose(tem);
  end;
  CloseHandle(FSemaphore);
  FSynobj.Free;
  inherited;
end;

procedure TGLCircleQueue.InitLinkTbl;
var
  I:cardinal;
  QueueData : PQueueData;
  Head,Tail:PQueueData;
begin
  New(QueueData);
  FillChar(QueueData^,SizeOf(TQueueData),0);
  Head := QueueData;
  Tail := QueueData;
  Head.Next := Tail;
  Tail.Next := Head;

  FHead := Head;
  FTail := Head;

  for I := 1 to Size-1 do                   //减一个头部
  begin
    New(QueueData);
    FillChar(QueueData^,SizeOf(TQueueData),0);

    QueueData.Next := Head;
    Head := QueueData;
    Tail.Next := Head;
  end;
end;

function TGLCircleQueue.Pop: Pointer;
begin
  Result := nil;
  if (FCount<=0) and FPopBlock then
  begin
    WaitForSingleObject(FSemaphore,500);
  end;
  FSynobj.Enter;
  try
    if FTail = FHead then Exit;         //如果这两个相等，说明没有数据

    Result := FHead.Data;
    FHead.Data := nil;
    FHead := FHead.Next;
    Dec(FCount);
  finally
    FSynobj.Leave;
  end;
end;

function TGLCircleQueue.PopArrData: ArrayPoint;
var
  CurGetCount:integer;
  I: Integer;
begin
  Result := nil;
  if (FCount<=0) and FPopBlock then
  begin
    WaitForSingleObject(FSemaphore,500);
  end;
  FSynobj.Enter;
  try
    if FTail = FHead then Exit;         //如果这两个相等，说明没有数据

    CurGetCount := FCount div GetNumberOfProcessor;
    if CurGetCount=0 then
      CurGetCount := FCount;

    SetLength(Result,CurGetCount);
    for I := 0 to CurGetCount - 1 do
    begin
      Result[I] := FHead.Data;
      FHead.Data := nil;
      FHead := FHead.Next;
    end;

    Dec(FCount,CurGetCount);
    SetEvent(-CurGetCount+1);
  finally
    FSynobj.Leave;
  end;
end;

function TGLCircleQueue.Push(Data: Pointer): Boolean;
var
  Tail:PQueueData;
begin
  Result := True;
  FSynobj.Enter;
  try
    if FTail.Next = FHead then                           //证明数据堆积了一圈了，得加大圈以便放更多数据
    begin
      if not FAutoExpansion then
      begin
        Result := False;
        Exit;
      end;
      ReSetCircle;
      Logger.WriteLog(LTInfo,'环形队列扩容: ' + inttostr(Fsize));
    end;

    Tail := FTail;
    Tail.Data := Data;
    FTail := Tail.Next;
    if FPopArr then
    begin
      if FCount = 0 then
        SetEvent;
    end else
    begin
      SetEvent;
    end;
      
    inc(FCount);
  finally
    FSynobj.Leave;
  end;
end;

function TGLCircleQueue.PushArrData(Data: ArrayPoint): ArrayPoint;
var
  Tail:PQueueData;
  AData:Pointer;
  I: Integer;
  Len:integer;
begin
  Result := nil;
  FSynobj.Enter;
  try
    Len := Length(Data);
    for I := 1 to Len do
    begin
      AData := Data[I-1];
      if FTail.Next = FHead then                           //证明数据堆积了一圈了，得加大圈以便放更多数据
      begin
        if not FAutoExpansion then
        begin
          Len := Len - I;
          SetLength(Result,Len);
          CopyMemory(@Result[0],@Data[I],SizeOf(Pointer)*Len);
          Exit;
        end;
        ReSetCircle;
      end;

      Tail := FTail;
      Tail.Data := AData;
      FTail := Tail.Next;
    end;
    inc(FCount,Len);
    SetEvent(Len);
  finally
    FSynobj.Leave
  end;
end;

procedure TGLCircleQueue.ReSetCircle;
var
  QueueData,TemTail : PQueueData;
  I:Integer;
  Addedcount:integer;
begin
  if FMaxSize>FSize*2 then
  begin
    Addedcount := FSize;
  end else
  begin
    Addedcount := FMaxSize - FSize;
  end;
  for I := 1 to Addedcount do                         
  begin
    New(QueueData);
    FillChar(QueueData^,SizeOf(TQueueData),0);

    if I=1 then
    begin
      FTail.Next := QueueData;
      TemTail :=  QueueData;
      Continue;
    end;

    TemTail.Next := QueueData;
    TemTail :=  QueueData;
  end;
  TemTail.Next := FHead;
  FSize := FSize + Addedcount;
end;

procedure TGLCircleQueue.SetEvent(EventCount: Integer = 1);
begin
  if FPopBlock then
    ReleaseSemaphore(FSemaphore,EventCount,nil);
end;

procedure TGLCircleQueue.SetSize(const Value: Cardinal);
var
  I:Integer;
  tem:PQueueData;
begin
  for I := 0 to FSize - 1 do
  begin
    tem := FHead;
    if Assigned(FOnFreeItem) and (tem.Data<>nil) then
      FOnFreeItem(tem.Data);
    FHead := FHead.Next;
    Dispose(tem);
  end;
  FSize := Value;
  InitLinkTbl;
end;

end.
