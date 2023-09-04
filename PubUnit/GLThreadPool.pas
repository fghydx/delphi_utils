/// <remarks>
/// CnVcl中弄过来的。
/// </remarks>
unit GLThreadPool;
(*
单元说明：
    该单元实现了线程池的功能



设计：
    实现线程池，首先要抽象出任务，最简单的就是使用一个指
  向某一结构的指针，不过这样做显然不是一个好的方法，还有
  一种比较简单的方法就是使用对象；有了抽象的任务之后，就
  要有一个对任务的管理列表，这可以简单的用TList实现，尽管
  TList的事件少了一些；然后就要有执行处理任务的线程，这最
  好要从TThread继承；然后要有通知机制，任务量，计算时间的
  估算，任务平衡机制。
    最简单的实现是工作线程作完一次任务之后就休眠，管理线
  程使用一个定时器定期给这些线程进行分配，管理，不过这样
  效率不高；也可以在增加任务的时候就进行一次分配，不过这
  样的主动分配对于线程的任务均衡，效率等都不是好的解决方
  法，而信号量则会比较好的解决这个问题。而线程池中线程的
  释放则可以简单通过计时器实现。
    真正的问题是如何估计工作量，线程池的工作强度，然后决
  定何时需要增加线程，何时需要减少线程:)

限制：
    考虑到线程池的使用范围，所以在实现中采用了不少只有在
  NT系列才实现的API，所以该组件在NT系列操作系统上会有最好
  的效果，当然也不支持非Windows环境。
    因为使用了WaitableTimer，所以在9x环境下线程池不会减少
  线程池中的线程数目，应该是可以通过SetTimer替代，不过
  SetTimer需要一个消息循环处理WM_TIMER消息，开销较大且不
  容易实现:)
    另外还有一个替代的方法就是mmsystem的timesetevent函数,
  不过这个函数的开销应该比其他的更大
    不过如果通过TTimer来实现的话，应该就可以实现跨平台的
  组件了...

内存泄漏：
    一般情况下该组件不会有内存泄露，然而当线程池被释放时
  线程池中还有正在工作的线程，且这些线程依赖的外部环境被
  破坏时，为了线程能够正常退出不得已使用了TerminateThread
  函数，而这个函数不会清理线程分配的内存，就可能造成内存
  泄露，幸运的是这种情形一般发生在应用程序退出时破坏了外
  部环境所致，所以一旦应用程序退出，操作系统会做相应的清
  理工作，所以实际上应该不算内存泄露:)
    即使是使用了TerminateThread，也不应该会造成程序退出时
  的种种异常，如RunTime Error 216

类及函数：

  TGLCriticalSection -- 临界区的封装
    在NT中实现了TryEnterCriticalSection，在SyncObjs.pas中
  的TCriticalSection没有封装这个函数，TGLCriticalSection
  封装了它，且直接从TObject继承，开销应该小一些:)
    TryEnter -- TryEnterCriticalSection
    TryEnterEx -- 9x时候就是Enter，NT就是TryEnter

  TGLTaskDataObject -- 线程池线程处理数据的封装
    线程池中的线程处理任务所需的数据的基类
    一般情况下，要实现某种特定的任务就需要实现相应的一个
  从该类继承的类
    Duplicate -- 是否与另一个处理数据相同，相同则不处理
    Info -- 信息，用于调试输出

  TGLPoolingThread -- 线程池中的线程
    线程池中的线程的基类，一般情况下不需要继承该类就可以
  实现大部分的操作，但在线程需要一些外部环境时可以继承该
  类的构造和析构函数，另一种方法是可以在线程池的相关事件
  中进行这些配置
    AverageWaitingTime -- 平均等待时间
    AverageProcessingTime -- 平均处理时间
    Duplicate -- 是否正在处理相同的任务
    Info -- 信息，用于调试输出
    IsDead -- 是否已死
    IsFinished -- 是否执行完成
    IsIdle -- 是否空闲
    NewAverage -- 计算平均值（特殊算法）
    StillWorking -- 表明线程仍然在运行
    Execute -- 线程执行函数，一般不需继承
    Create -- 构造函数
    Destroy -- 析构函数
    Terminate -- 结束线程

  TCnThreadPool -- 线程池
    控件的事件并没有使用同步方式封装，所以这些事件的代码
  要线程安全才可以
    HasSpareThread -- 有空闲的线程
    AverageWaitingTime -- 平均等待时间
    AverageProcessingTime -- 平均计算时间
    TaskCount -- 任务数目
    ThreadCount -- 线程数目
    CheckTaskEmpty -- 检查任务是否都已经完成
    GetRequest -- 从队列中获取任务
    DecreaseThreads -- 减少线程
    IncreaseThreads -- 增加线程
    FreeFinishedThreads -- 释放完成的线程
    KillDeadThreads -- 清除死线程
    Info -- 信息，用于调试输出
    OSIsWin9x -- 操作系统是Win9x
    AddRequest -- 增加任务
    RemoveRequest -- 从队列中删除任务
    CreateSpecial -- 创建自定义线程池线程的构造函数
    AdjustInterval -- 减少线程的时间间隔
    DeadTaskAsNew -- 将死线程的任务重新加到队列
    MinAtLeast -- 线程数不少于最小数目
    ThreadDeadTimeout -- 线程死亡超时
    ThreadsMinCount -- 最少线程数
    ThreadsMaxCount -- 最大线程数
    OnGetInfo -- 获取信息事件
    OnProcessRequest -- 处理任务事件
    OnQueueEmpty -- 队列空事件
    OnThreadInitializing -- 线程初始化事件
    OnThreadFinalizing -- 线程终止化事件
********************************************************)

interface

uses
  SysUtils, Windows, Classes,GLSyncObj;

type
  TGLTaskDataObject = class
  public
    function Clone: TGLTaskDataObject; virtual; abstract;
    function Duplicate(DataObj: TGLTaskDataObject;
      const Processing: Boolean): Boolean; virtual;
    function Info: string; virtual;
  end;

  { TGLPoolingThread }

  TGLThreadPool = class;

  TGLThreadState = (ctsInitializing, ctsWaiting,
    ctsGetting,
    ctsProcessing, ctsProcessed,
    ctsTerminating, ctsForReduce);

  TGLPoolingThread = class(TThread)
  private
    hInitFinished: THandle;
    sInitError: string;
    procedure ForceTerminate;
  protected
    FAverageWaitingTime: Integer;
    FAverageProcessing: Integer;
    FWaitingTime:Int64;                    //总共等待时间
    FProcessingTime:Int64;                 //总共任务执行时的消耗时间
    uWaitingStart: DWORD;
    uProcessingStart: DWORD;
    uStillWorking: DWORD;
    FWorkCount: Int64;
    FCurState: TGLThreadState;
    hThreadTerminated: THandle;
    FPool: TGLThreadPool;
    FProcessingDataObject: TGLTaskDataObject;

    csProcessingDataObject: TGLCriticalSection;

    function AverageProcessingTime: DWORD;
    function AverageWaitingTime: DWORD;
    function CloneData: TGLTaskDataObject;
    function Duplicate(DataObj: TGLTaskDataObject): Boolean; virtual;
    function Info: string; virtual;
    function IsDead: Boolean; virtual;
    function IsFinished: Boolean; virtual;
    function IsIdle: Boolean; virtual;
    function NewAverage(OldAvg, NewVal: Integer): Integer; virtual;

    procedure Execute; override;
  public
    constructor Create(aPool: TGLThreadPool); virtual;
    destructor Destroy; override;

    procedure StillWorking;
    procedure Terminate(const Force: Boolean = False);
  end;

  TGLPoolingThreadClass = class of TGLPoolingThread;

  { TCnThreadPool }

  TCheckDuplicate = (cdQueue, cdProcessing);
  TCheckDuplicates = set of TCheckDuplicate;

  TGetInfo = procedure(Sender: TGLThreadPool;
    var InfoText: string) of object;
  TProcessRequest = procedure(Sender: TGLThreadPool;
    aDataObj: TGLTaskDataObject; aThread: TGLPoolingThread) of object;

  TEmptyKind = (ekQueueEmpty, ekTaskEmpty);
  TQueueEmpty = procedure(Sender: TGLThreadPool;
    EmptyKind: TEmptyKind) of object;

  TThreadInPoolInitializing = procedure(Sender: TGLThreadPool;
    aThread: TGLPoolingThread) of object;
  TThreadInPoolFinalizing = procedure(Sender: TGLThreadPool;
    aThread: TGLPoolingThread) of object;

  TGLThreadPool = class(TComponent)
  private
    csQueueManagment: TGLCriticalSection;
    csThreadManagment: TGLCriticalSection;

    FQueue: TList;
    FThreads: TList;
    FThreadsKilling: TList;
    FThreadsMinCount, FThreadsMaxCount: Integer;
    FThreadDeadTimeout: DWORD;
    FThreadClass: TGLPoolingThreadClass;
    FAdjustInterval: DWORD;
    FDeadTaskAsNew: Boolean;
    FMinAtLeast: Boolean;
    FIdleThreadCount, FTaskCount,FAddedTaskCount: Integer;

    FThreadInitializing: TThreadInPoolInitializing;
    FThreadFinalizing: TThreadInPoolFinalizing;
    FProcessRequest: TProcessRequest;
    FQueueEmpty: TQueueEmpty;
    FGetInfo: TGetInfo;

    procedure SetAdjustInterval(const Value: DWORD);
  protected
    FLastGetPoint: Integer;
    hSemRequestCount: THandle;
    hTimReduce: THandle;

    function HasSpareThread: Boolean;
    function HasTask: Boolean;
    function FinishedThreadsAreFull: Boolean; virtual;
    procedure CheckTaskEmpty;
    procedure GetRequest(var Request: TGLTaskDataObject);
    procedure DecreaseThreads;
    procedure IncreaseThreads;
    procedure FreeFinishedThreads;
    procedure KillDeadThreads;

    procedure DoProcessRequest(aDataObj: TGLTaskDataObject;
      aThread: TGLPoolingThread); virtual;
    procedure DoQueueEmpty(EmptyKind: TEmptyKind); virtual;
    procedure DoThreadInitializing(aThread: TGLPoolingThread); virtual;
    procedure DoThreadFinalizing(aThread: TGLPoolingThread); virtual;

  public
    uTerminateWaitTime: DWORD;
    QueuePackCount: Integer;

    constructor Create(AOwner: TComponent); override;
    constructor CreateSpecial(AOwner: TComponent;
      AClass: TGLPoolingThreadClass);
    destructor Destroy; override;

    function AverageWaitingTime: Integer;
    function AverageProcessingTime: Integer;
    function Info: string;
    function TaskCount: Integer;
    function ThreadCount: Integer;
    function ThreadInfo(const i: Integer): string;
    function ThreadKillingCount: Integer;
    function ThreadKillingInfo(const i: Integer): string;
    procedure DefaultGetInfo(Sender: TGLThreadPool; var InfoText: string);

    function AddRequest(aDataObject: TGLTaskDataObject;
      CheckDuplicate: TCheckDuplicates = [cdQueue]): Boolean;
    procedure AddRequests(aDataObjects: array of TGLTaskDataObject;
      CheckDuplicate: TCheckDuplicates = [cdQueue]);
    procedure RemoveRequest(aDataObject: TGLTaskDataObject);
  published
    property AdjustInterval: DWORD read FAdjustInterval write SetAdjustInterval
      default 10000;
    property DeadTaskAsNew: Boolean read FDeadTaskAsNew write FDeadTaskAsNew
      default True;
    property MinAtLeast: Boolean read FMinAtLeast write FMinAtLeast
      default False;
    property ThreadDeadTimeout: DWORD read FThreadDeadTimeout
      write FThreadDeadTimeout default 0;
    property ThreadsMinCount: Integer read FThreadsMinCount write FThreadsMinCount default 0;
    property ThreadsMaxCount: Integer read FThreadsMaxCount write FThreadsMaxCount default 10;

    property OnGetInfo: TGetInfo read FGetInfo write FGetInfo;
    property OnProcessRequest: TProcessRequest read FProcessRequest
      write FProcessRequest;
    property OnQueueEmpty: TQueueEmpty read FQueueEmpty write FQueueEmpty;
    property OnThreadInitializing: TThreadInPoolInitializing
      read FThreadInitializing write FThreadInitializing;
    property OnThreadFinalizing: TThreadInPoolFinalizing read FThreadFinalizing
      write FThreadFinalizing;
  end;

const
//  CCnTHREADSTATE: array[TGLThreadState] of string = (
//    'ctsInitializing', 'ctsWaiting',
//    'ctsGetting',
//    'ctsProcessing', 'ctsProcessed',
//    'ctsTerminating', 'ctsForReduce');
  CCnTHREADSTATE: array[TGLThreadState] of string = (
    '初始化', '等待',
    '获取任务',
    '处理任务', '处理完毕',
    '释放', '校验线程数');
implementation

uses
  Math;

const
  MaxInt64 = High(Int64);

function GetTickDiff(const AOldTickCount, ANewTickCount : Cardinal):Cardinal;
begin
  if ANewTickCount >= AOldTickCount then
  begin
    Result := ANewTickCount - AOldTickCount;
  end
  else
  begin
    Result := High(Cardinal) - AOldTickCount + ANewTickCount;
  end;
end;

{ TGLTaskDataObject }

function TGLTaskDataObject.Duplicate(DataObj: TGLTaskDataObject;
  const Processing: Boolean): Boolean;
begin
  Result := False
end;

function TGLTaskDataObject.Info: string;
begin
  Result := IntToHex(Cardinal(Self), 8)
end;

{ TGLPoolingThread }

constructor TGLPoolingThread.Create(aPool: TGLThreadPool);
begin

  inherited Create(True);
  FPool := aPool;

  FAverageWaitingTime := 0;
  FAverageProcessing := 0;
  FWorkCount := 0;
  sInitError := '';
  FreeOnTerminate := False;
  hInitFinished := CreateEvent(nil, True, False, nil);
  hThreadTerminated := CreateEvent(nil, True, False, nil);
  csProcessingDataObject := TGLCriticalSection.Create;
  try
    Resume;
    WaitForSingleObject(hInitFinished, INFINITE);
    if sInitError <> '' then
      raise Exception.Create(sInitError);
  finally
    CloseHandle(hInitFinished);
  end;
end;

destructor TGLPoolingThread.Destroy;
begin
  FreeAndNil(FProcessingDataObject);
  CloseHandle(hThreadTerminated);
  csProcessingDataObject.Free;
  inherited;
end;

function TGLPoolingThread.AverageProcessingTime: DWORD;
begin
  if FCurState in [ctsProcessing] then
    Result := NewAverage(FAverageProcessing, GetTickDiff(uProcessingStart, GetTickCount))
  else
    Result := FAverageProcessing
end;

function TGLPoolingThread.AverageWaitingTime: DWORD;
begin
  if FCurState in [ctsWaiting, ctsForReduce] then
    Result := NewAverage(FAverageWaitingTime, GetTickDiff(uWaitingStart, GetTickCount))
  else
    Result := FAverageWaitingTime
end;

function TGLPoolingThread.Duplicate(DataObj: TGLTaskDataObject): Boolean;
begin
  csProcessingDataObject.Enter;
  try
    Result := (FProcessingDataObject <> nil) and
      DataObj.Duplicate(FProcessingDataObject, True);
  finally
    csProcessingDataObject.Leave
  end
end;

procedure TGLPoolingThread.ForceTerminate;
begin
  TerminateThread(Handle, 0)
end;

procedure TGLPoolingThread.Execute;
type
  THandleID = (hidRequest, hidReduce, hidTerminate);
var
  TemTime: Integer;
  Handles: array[THandleID] of THandle;
begin
  FCurState := ctsInitializing;
  try
    FPool.DoThreadInitializing(Self);
  except
    on E: Exception do
      sInitError := E.Message;
  end;
  SetEvent(hInitFinished);

  Handles[hidRequest] := FPool.hSemRequestCount;
  Handles[hidReduce] := FPool.hTimReduce;
  Handles[hidTerminate] := hThreadTerminated;

  uWaitingStart := GetTickCount;
  FProcessingDataObject := nil;

  while not Terminated do
  begin
    if not (FCurState in [ctsWaiting, ctsForReduce]) then
      InterlockedIncrement(FPool.FIdleThreadCount);
    FCurState := ctsWaiting;
    case WaitForMultipleObjects(Length(Handles), @Handles, False, INFINITE) of
      WAIT_OBJECT_0 + Ord(hidRequest):
        begin
          TemTime := GetTickDiff(uWaitingStart, GetTickCount);
          FAverageWaitingTime := NewAverage(FAverageWaitingTime, TemTime);
          FWaitingTime := FWaitingTime + TemTime;

          if FCurState in [ctsWaiting, ctsForReduce] then
            InterlockedDecrement(FPool.FIdleThreadCount);
          FCurState := ctsGetting;
          FPool.GetRequest(FProcessingDataObject);
          if FWorkCount < MaxInt64 then
            FWorkCount := FWorkCount + 1;
          uProcessingStart := GetTickCount;
          uStillWorking := uProcessingStart;

          FCurState := ctsProcessing;
          try
            FPool.DoProcessRequest(FProcessingDataObject, Self)
          except

          end;

          csProcessingDataObject.Enter;
          try
            FreeAndNil(FProcessingDataObject)
          finally
            csProcessingDataObject.Leave
          end;
          TemTime := GetTickDiff(uProcessingStart, GetTickCount);
          FAverageProcessing := NewAverage(FAverageProcessing, TemTime);
          FProcessingTime := FProcessingTime + TemTime;

          FCurState := ctsProcessed;
          FPool.CheckTaskEmpty;
          uWaitingStart := GetTickCount;
        end;
      WAIT_OBJECT_0 + Ord(hidReduce):
        begin
          if not (FCurState in [ctsWaiting, ctsForReduce]) then
            InterlockedIncrement(FPool.FIdleThreadCount);
          FCurState := ctsForReduce;
          FPool.DecreaseThreads;
        end;
      WAIT_OBJECT_0 + Ord(hidTerminate):
        begin
          if FCurState in [ctsWaiting, ctsForReduce] then
            InterlockedDecrement(FPool.FIdleThreadCount);

          FCurState := ctsTerminating;
          Break
        end;
    end;
  end;

  if FCurState in [ctsWaiting, ctsForReduce] then
    InterlockedDecrement(FPool.FIdleThreadCount);
  FCurState := ctsTerminating;
  FPool.DoThreadFinalizing(Self);
end;

function TGLPoolingThread.Info: string;
begin
  Result := '共等待时间 ：' + IntToStr(FWaitingTime) +
    #13#10'共消耗时间 ：' + IntToStr(FProcessingTime) +
    #13#10'当前状态 ：' + CCnTHREADSTATE[FCurState] + 
    #13#10'共执行次数 ：' + IntToStr(FWorkCount);
  if csProcessingDataObject.TryEnter then
  try
    Result := Result + #13#10'当前执行任务地址 ：';
    if FProcessingDataObject = nil then
      Result := Result + 'nil'
    else
      Result := Result + FProcessingDataObject.Info
  finally
    csProcessingDataObject.Leave
  end
end;

function TGLPoolingThread.IsDead: Boolean;
begin
  Result := Terminated or
    ((FPool.ThreadDeadTimeout > 0) and
    (FCurState = ctsProcessing) and
    (GetTickDiff(uStillWorking, GetTickCount) > FPool.ThreadDeadTimeout));
end;

function TGLPoolingThread.IsFinished: Boolean;
begin
  Result := WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0
end;

function TGLPoolingThread.IsIdle: Boolean;
begin
  Result := (FCurState in [ctsWaiting, ctsForReduce]) and
    (AverageWaitingTime > 200) and
    (AverageWaitingTime * 2 > AverageProcessingTime)
end;

function TGLPoolingThread.NewAverage(OldAvg, NewVal: Integer): Integer;
begin
  if FWorkCount >= 8 then
    Result := (OldAvg * 7 + NewVal) div 8
  else if FWorkCount > 0 then
    Result := (OldAvg * FWorkCount + NewVal) div FWorkCount
  else
    Result := NewVal
end;

procedure TGLPoolingThread.StillWorking;
begin
  uStillWorking := GetTickCount
end;

procedure TGLPoolingThread.Terminate(const Force: Boolean);
begin
  inherited Terminate;

  if Force then
  begin
    ForceTerminate;
    Free
  end
  else
    SetEvent(hThreadTerminated)
end;


function TGLPoolingThread.CloneData: TGLTaskDataObject;
begin
  csProcessingDataObject.Enter;
  try
    Result := nil;
    if FProcessingDataObject <> nil then
      Result := FProcessingDataObject.Clone;
  finally
    csProcessingDataObject.Leave;
  end;
end;

{ TCnThreadPool }

constructor TGLThreadPool.Create(AOwner: TComponent);
var
  DueTo: Int64;
begin
  inherited;

  csQueueManagment := TGLCriticalSection.Create;
  csThreadManagment := TGLCriticalSection.Create;
  FQueue := TList.Create;
  FThreads := TList.Create;
  FThreadsKilling := TList.Create;
  FThreadsMinCount := 0;
  FThreadsMaxCount := 1;
  FThreadDeadTimeout := 0;
  FThreadClass := TGLPoolingThread;
  FAdjustInterval := 10000;
  FDeadTaskAsNew := True;
  FMinAtLeast := False;
  FLastGetPoint := 0;
  uTerminateWaitTime := 10000;
  QueuePackCount := 127;
  FIdleThreadCount := 0;
  FTaskCount := 0;
  FAddedTaskCount := 0;
  hSemRequestCount := CreateSemaphore(nil, 0, $7FFFFFFF, nil);

  DueTo := -1;
  hTimReduce := CreateWaitableTimer(nil, False, nil);

  if hTimReduce = 0 then
    hTimReduce := CreateEvent(nil, False, False, nil)
  else
    SetWaitableTimer(hTimReduce, DueTo, FAdjustInterval, nil, nil, False);
end;

constructor TGLThreadPool.CreateSpecial(AOwner: TComponent;
  AClass: TGLPoolingThreadClass);
begin
  Create(AOwner);
  if AClass <> nil then
    FThreadClass := AClass
end;

destructor TGLThreadPool.Destroy;
var
  i, n: Integer;
  Handles: array of THandle;
begin
  csThreadManagment.Enter;
  try
    SetLength(Handles, FThreads.Count);
    n := 0;
    for i := 0 to FThreads.Count - 1 do
      if FThreads[i] <> nil then
      begin
        Handles[n] := TGLPoolingThread(FThreads[i]).Handle;
        TGLPoolingThread(FThreads[i]).Terminate(False);
        Inc(n);
      end;
    WaitForMultipleObjects(n, @Handles[0], True, uTerminateWaitTime);

    for i := 0 to FThreads.Count - 1 do
    begin
      {if FThreads[i] <> nil then
        TGLPoolingThread(FThreads[i]).Terminate(True)
      else}
      TGLPoolingThread(FThreads[i]).Free;
    end;

    FThreads.Free;

    FreeFinishedThreads;
    for i := 0 to FThreadsKilling.Count - 1 do
    begin
      {if FThreadsKilling[i] <> nil then
        TGLPoolingThread(FThreadsKilling[i]).Terminate(True)
      else}
      TGLPoolingThread(FThreadsKilling[i]).Free;
    end;

    FThreadsKilling.Free;
  finally
    csThreadManagment.Free;
  end;

  csQueueManagment.Enter;
  try
    for i := FQueue.Count - 1 downto 0 do
      TObject(FQueue[i]).Free;
    FQueue.Free;
  finally
    csQueueManagment.Free;
  end;

  CloseHandle(hSemRequestCount);
  CloseHandle(hTimReduce);

  inherited;
end;

function TGLThreadPool.AddRequest(aDataObject: TGLTaskDataObject;
  CheckDuplicate: TCheckDuplicates): Boolean;
var
  i: Integer;
begin
  Result := False;

  csQueueManagment.Enter;
  try
    if cdQueue in CheckDuplicate then
      for i := 0 to FQueue.Count - 1 do
        if (FQueue[i] <> nil) and
          aDataObject.Duplicate(TGLTaskDataObject(FQueue[i]), False) then
        begin
          FreeAndNil(aDataObject);
          Exit
        end;

    csThreadManagment.Enter;
    try
      IncreaseThreads;

      if cdProcessing in CheckDuplicate then
        for i := 0 to FThreads.Count - 1 do
          if TGLPoolingThread(FThreads[i]).Duplicate(aDataObject) then
          begin
            FreeAndNil(aDataObject);
            Exit
          end
    finally
      csThreadManagment.Leave;
    end;

    FQueue.Add(aDataObject);
    Inc(FTaskCount);
    Inc(FAddedTaskCount);
    ReleaseSemaphore(hSemRequestCount, 1, nil);
    Result := True;

  finally
    csQueueManagment.Leave;
  end;
end;

procedure TGLThreadPool.AddRequests(
  aDataObjects: array of TGLTaskDataObject;
  CheckDuplicate: TCheckDuplicates);
var
  i: Integer;
begin
  for i := 0 to Length(aDataObjects) - 1 do
    AddRequest(aDataObjects[i], CheckDuplicate)
end;

procedure TGLThreadPool.CheckTaskEmpty;
var
  i: Integer;
begin
  csQueueManagment.Enter;
  try
    if (FLastGetPoint < FQueue.Count) then
      Exit;

    csThreadManagment.Enter;
    try
      for i := 0 to FThreads.Count - 1 do
        if TGLPoolingThread(FThreads[i]).FCurState in [ctsProcessing] then
          Exit
    finally
      csThreadManagment.Leave
    end;

    DoQueueEmpty(ekTaskEmpty)

  finally
    csQueueManagment.Leave
  end
end;

procedure TGLThreadPool.DecreaseThreads;
var
  i: Integer;
begin

  if csThreadManagment.TryEnter then
  try
    KillDeadThreads;
    FreeFinishedThreads;

    for i := FThreads.Count - 1 downto FThreadsMinCount do
      if TGLPoolingThread(FThreads[i]).IsIdle then
      begin
        TGLPoolingThread(FThreads[i]).Terminate(False);
        FThreadsKilling.Add(FThreads[i]);
        FThreads.Delete(i);
        Break
      end
  finally
    csThreadManagment.Leave
  end
end;

procedure TGLThreadPool.DefaultGetInfo(Sender: TGLThreadPool;
  var InfoText: string);
var
  i: Integer;
  sLine: string;
begin
//  sLine := StringOfChar('=', 15);
  sLine := '————————————————————————————————————————';
  with Sender do
  begin
    FreeFinishedThreads;
    InfoText := '线程下限 ：' + IntToStr(ThreadsMinCount) +
      #13#10'线程上限 ：' + IntToStr(ThreadsMaxCount) +
      #13#10'探测减少线程的时间间隔 ：' + IntToStr(AdjustInterval) +
      #13#10'线程超时销毁时长 ：' + IntToStr(ThreadDeadTimeout) +
      #13#10'当前线程数 ：' + IntToStr(ThreadCount) +
//      #13#10'正在销毁线程数 ：' + IntToStr(ThreadKillingCount) +
      #13#10'歇凉的线程数 ：' + IntToStr(FIdleThreadCount) +
      #13#10'等待中的任务个数 ：' + IntToStr(TaskCount) +
      #13#10'共添加任务数：' + IntToStr(FAddedTaskCount) +
//      #13#10'平均等待时间 ：' + IntToStr(AverageWaitingTime) +
//      #13#10'平均消耗时间 ：' + IntToStr(AverageProcessingTime) + #13#10 +
      #13#10'正在运行的线程信息 ：' + sLine;
    for i := 0 to ThreadCount - 1 do
      InfoText := InfoText + #13#10 + ThreadInfo(i);
    InfoText := InfoText + #13#10 + {sLine +} '正在删除的线程信息：' + sLine;
    for i := 0 to ThreadKillingCount - 1 do
      InfoText := InfoText + #13#10 + ThreadKillingInfo(i)
  end
end;

procedure TGLThreadPool.DoProcessRequest(aDataObj: TGLTaskDataObject;
  aThread: TGLPoolingThread);
begin
  if Assigned(FProcessRequest) then
    FProcessRequest(Self, aDataObj, aThread)
end;

procedure TGLThreadPool.DoQueueEmpty(EmptyKind: TEmptyKind);
begin
  if Assigned(FQueueEmpty) then
    FQueueEmpty(Self, EmptyKind)
end;

procedure TGLThreadPool.DoThreadFinalizing(aThread: TGLPoolingThread);
begin
  if Assigned(FThreadFinalizing) then
    FThreadFinalizing(Self, aThread)
end;

procedure TGLThreadPool.DoThreadInitializing(aThread: TGLPoolingThread);
begin
  if Assigned(FThreadInitializing) then
    FThreadInitializing(Self, aThread)
end;

procedure TGLThreadPool.FreeFinishedThreads;
var
  i: Integer;
begin
  if csThreadManagment.TryEnter then
  try
    for i := FThreadsKilling.Count - 1 downto 0 do
      if TGLPoolingThread(FThreadsKilling[i]).IsFinished then
      begin
        TGLPoolingThread(FThreadsKilling[i]).Free;
        FThreadsKilling.Delete(i)
      end

  finally
    csThreadManagment.Leave
  end
end;

procedure TGLThreadPool.GetRequest(var Request: TGLTaskDataObject);
begin
  csQueueManagment.Enter;
  try
    while (FLastGetPoint < FQueue.Count) and (FQueue[FLastGetPoint] = nil) do
      Inc(FLastGetPoint);

    if (FQueue.Count > QueuePackCount) and
      (FLastGetPoint >= FQueue.Count * 3 div 4) then
    begin
      FQueue.Pack;
      FTaskCount := FQueue.Count;
      FLastGetPoint := 0
    end;

    Request := TGLTaskDataObject(FQueue[FLastGetPoint]);
    FQueue[FLastGetPoint] := nil;
    Dec(FTaskCount);
    Inc(FLastGetPoint);

    if (FLastGetPoint = FQueue.Count) then
    begin
      DoQueueEmpty(ekQueueEmpty);
      FQueue.Clear;
      FTaskCount := 0;
      FLastGetPoint := 0
    end

  finally
    csQueueManagment.Leave
  end
end;

function TGLThreadPool.HasSpareThread: Boolean;
begin
  Result := FIdleThreadCount > 0
end;

function TGLThreadPool.HasTask: Boolean;
begin
  Result := FTaskCount > 0
end;

function TGLThreadPool.FinishedThreadsAreFull: Boolean;
begin
  csThreadManagment.Enter;
  try
    if FThreadsMaxCount > 0 then
      Result := FThreadsKilling.Count >= FThreadsMaxCount div 2
    else
      Result := FThreadsKilling.Count >= 50;
  finally
    csThreadManagment.Leave
  end
end;

procedure TGLThreadPool.IncreaseThreads;
var
  iAvgWait, iAvgProc: Integer;
  i: Integer;
begin
  csThreadManagment.Enter;
  try
    KillDeadThreads;
    FreeFinishedThreads;

    if FThreads.Count = 0 then
    begin
      try
        FThreads.Add(FThreadClass.Create(Self));
      except
      end
    end
    else if FMinAtLeast and (FThreads.Count < FThreadsMinCount) then
    begin
      for i := FThreads.Count to FThreadsMinCount - 1 do
      try
        FThreads.Add(FThreadClass.Create(Self));
      except
      end
    end
    else if (FThreads.Count < FThreadsMaxCount) and HasTask and not HasSpareThread then
    begin
      i := TaskCount;
      if i <= 0 then
        Exit;

      iAvgWait := Max(AverageWaitingTime, 1);
      if iAvgWait > 100 then
        Exit;

      iAvgProc := Max(AverageProcessingTime, 2);
      //if i * iAvgWait * 2 > iAvgProc * FThreads.Count then
      if ((iAvgProc + iAvgWait) * i > iAvgProc * FThreads.Count) then
      begin
        try
          FThreads.Add(FThreadClass.Create(Self));
        except

        end
      end
    end

  finally
    csThreadManagment.Leave
  end
end;

function TGLThreadPool.Info: string;
begin
  if csThreadManagment.TryEnter then
  begin
    try
      if Assigned(FGetInfo) then
      begin
        FGetInfo(Self, Result)
      end
      else
        DefaultGetInfo(Self, Result)
    finally
      csThreadManagment.Leave
    end;
  end
  else
  begin
    Result := '应用程序忙，请重新获取线程池状态信息.';
  end;
end;

procedure TGLThreadPool.KillDeadThreads;
var
  i, iLen: Integer;
  LThread: TGLPoolingThread;
  LObjects: array of TGLTaskDataObject;
begin
  if FinishedThreadsAreFull then Exit;

  iLen := 0;
  SetLength(LObjects, iLen);
  if csThreadManagment.TryEnter then
  try
    for i := FThreads.Count - 1 downto 0 do
    begin
      LThread := TGLPoolingThread(FThreads[i]);
      if LThread.IsDead then
      begin
        if FDeadTaskAsNew then
        begin
          Inc(iLen);
          SetLength(LObjects, iLen);
          LObjects[iLen - 1] := LThread.CloneData;
        end;

        LThread.Terminate(False);
        FThreadsKilling.Add(LThread);
        FThreads.Delete(i);
      end
    end
  finally
    csThreadManagment.Leave
  end;
  AddRequests(LObjects, []);
end;

function TGLThreadPool.AverageProcessingTime: Integer;
var
  i: Integer;
begin
  Result := 0;
  if FThreads.Count > 0 then
  begin
    for i := 0 to FThreads.Count - 1 do
      Inc(Result, TGLPoolingThread(FThreads[i]).AverageProcessingTime);
    Result := Result div FThreads.Count
  end
  else
    Result := 20
end;

function TGLThreadPool.AverageWaitingTime: Integer;
var
  i: Integer;
begin
  Result := 0;
  if FThreads.Count > 0 then
  begin
    for i := 0 to FThreads.Count - 1 do
      Inc(Result, TGLPoolingThread(FThreads[i]).AverageWaitingTime);
    Result := Result div FThreads.Count
  end
  else
    Result := 10
end;

procedure TGLThreadPool.RemoveRequest(aDataObject: TGLTaskDataObject);
begin
  csQueueManagment.Enter;
  try
    FQueue.Remove(aDataObject);
    Dec(FTaskCount);
    FreeAndNil(aDataObject)
  finally
    csQueueManagment.Leave
  end
end;

procedure TGLThreadPool.SetAdjustInterval(const Value: DWORD);
var
  DueTo: Int64;
begin
  FAdjustInterval := Value;
  if hTimReduce <> 0 then
    SetWaitableTimer(hTimReduce, DueTo, Value, nil, nil, False)
end;

function TGLThreadPool.TaskCount: Integer;
begin
  Result := FTaskCount;
end;

function TGLThreadPool.ThreadCount: Integer;
begin
  if csThreadManagment.TryEnter then
  try
    Result := FThreads.Count
  finally
    csThreadManagment.Leave
  end
  else
    Result := -1
end;

function TGLThreadPool.ThreadInfo(const i: Integer): string;
begin
  Result := '';

  if csThreadManagment.TryEnter then
  try
    if i < FThreads.Count then
      Result := TGLPoolingThread(FThreads[i]).Info
  finally
    csThreadManagment.Leave
  end
end;

function TGLThreadPool.ThreadKillingCount: Integer;
begin
  if csThreadManagment.TryEnter then
  try
    Result := FThreadsKilling.Count
  finally
    csThreadManagment.Leave
  end
  else
    Result := -1
end;

function TGLThreadPool.ThreadKillingInfo(const i: Integer): string;
begin
  Result := '';

  if csThreadManagment.TryEnter then
  try
    if i < FThreadsKilling.Count then
      Result := TGLPoolingThread(FThreadsKilling[i]).Info
  finally
    csThreadManagment.Leave;
  end;
end;

end.

