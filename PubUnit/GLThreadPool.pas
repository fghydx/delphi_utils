/// <remarks>
/// CnVcl��Ū�����ġ�
/// </remarks>
unit GLThreadPool;
(*
��Ԫ˵����
    �õ�Ԫʵ�����̳߳صĹ���



��ƣ�
    ʵ���̳߳أ�����Ҫ�����������򵥵ľ���ʹ��һ��ָ
  ��ĳһ�ṹ��ָ�룬������������Ȼ����һ���õķ���������
  һ�ֱȽϼ򵥵ķ�������ʹ�ö������˳��������֮�󣬾�
  Ҫ��һ��������Ĺ����б�����Լ򵥵���TListʵ�֣�����
  TList���¼�����һЩ��Ȼ���Ҫ��ִ�д���������̣߳�����
  ��Ҫ��TThread�̳У�Ȼ��Ҫ��֪ͨ���ƣ�������������ʱ���
  ���㣬����ƽ����ơ�
    ��򵥵�ʵ���ǹ����߳�����һ������֮������ߣ�������
  ��ʹ��һ����ʱ�����ڸ���Щ�߳̽��з��䣬������������
  Ч�ʲ��ߣ�Ҳ���������������ʱ��ͽ���һ�η��䣬������
  ����������������̵߳�������⣬Ч�ʵȶ����ǺõĽ����
  �������ź������ȽϺõĽ��������⡣���̳߳����̵߳�
  �ͷ�����Լ�ͨ����ʱ��ʵ�֡�
    ��������������ι��ƹ��������̳߳صĹ���ǿ�ȣ�Ȼ���
  ����ʱ��Ҫ�����̣߳���ʱ��Ҫ�����߳�:)

���ƣ�
    ���ǵ��̳߳ص�ʹ�÷�Χ��������ʵ���в����˲���ֻ����
  NTϵ�в�ʵ�ֵ�API�����Ը������NTϵ�в���ϵͳ�ϻ������
  ��Ч������ȻҲ��֧�ַ�Windows������
    ��Ϊʹ����WaitableTimer��������9x�������̳߳ز������
  �̳߳��е��߳���Ŀ��Ӧ���ǿ���ͨ��SetTimer���������
  SetTimer��Ҫһ����Ϣѭ������WM_TIMER��Ϣ�������ϴ��Ҳ�
  ����ʵ��:)
    ���⻹��һ������ķ�������mmsystem��timesetevent����,
  ������������Ŀ���Ӧ�ñ������ĸ���
    �������ͨ��TTimer��ʵ�ֵĻ���Ӧ�þͿ���ʵ�ֿ�ƽ̨��
  �����...

�ڴ�й©��
    һ������¸�����������ڴ�й¶��Ȼ�����̳߳ر��ͷ�ʱ
  �̳߳��л������ڹ������̣߳�����Щ�߳��������ⲿ������
  �ƻ�ʱ��Ϊ���߳��ܹ������˳�������ʹ����TerminateThread
  ������������������������̷߳�����ڴ棬�Ϳ�������ڴ�
  й¶�����˵�����������һ�㷢����Ӧ�ó����˳�ʱ�ƻ�����
  ���������£�����һ��Ӧ�ó����˳�������ϵͳ������Ӧ����
  ����������ʵ����Ӧ�ò����ڴ�й¶:)
    ��ʹ��ʹ����TerminateThread��Ҳ��Ӧ�û���ɳ����˳�ʱ
  �������쳣����RunTime Error 216

�༰������

  TGLCriticalSection -- �ٽ����ķ�װ
    ��NT��ʵ����TryEnterCriticalSection����SyncObjs.pas��
  ��TCriticalSectionû�з�װ���������TGLCriticalSection
  ��װ��������ֱ�Ӵ�TObject�̳У�����Ӧ��СһЩ:)
    TryEnter -- TryEnterCriticalSection
    TryEnterEx -- 9xʱ�����Enter��NT����TryEnter

  TGLTaskDataObject -- �̳߳��̴߳������ݵķ�װ
    �̳߳��е��̴߳���������������ݵĻ���
    һ������£�Ҫʵ��ĳ���ض����������Ҫʵ����Ӧ��һ��
  �Ӹ���̳е���
    Duplicate -- �Ƿ�����һ������������ͬ����ͬ�򲻴���
    Info -- ��Ϣ�����ڵ������

  TGLPoolingThread -- �̳߳��е��߳�
    �̳߳��е��̵߳Ļ��࣬һ������²���Ҫ�̳и���Ϳ���
  ʵ�ִ󲿷ֵĲ����������߳���ҪһЩ�ⲿ����ʱ���Լ̳и�
  ��Ĺ����������������һ�ַ����ǿ������̳߳ص�����¼�
  �н�����Щ����
    AverageWaitingTime -- ƽ���ȴ�ʱ��
    AverageProcessingTime -- ƽ������ʱ��
    Duplicate -- �Ƿ����ڴ�����ͬ������
    Info -- ��Ϣ�����ڵ������
    IsDead -- �Ƿ�����
    IsFinished -- �Ƿ�ִ�����
    IsIdle -- �Ƿ����
    NewAverage -- ����ƽ��ֵ�������㷨��
    StillWorking -- �����߳���Ȼ������
    Execute -- �߳�ִ�к�����һ�㲻��̳�
    Create -- ���캯��
    Destroy -- ��������
    Terminate -- �����߳�

  TCnThreadPool -- �̳߳�
    �ؼ����¼���û��ʹ��ͬ����ʽ��װ��������Щ�¼��Ĵ���
  Ҫ�̰߳�ȫ�ſ���
    HasSpareThread -- �п��е��߳�
    AverageWaitingTime -- ƽ���ȴ�ʱ��
    AverageProcessingTime -- ƽ������ʱ��
    TaskCount -- ������Ŀ
    ThreadCount -- �߳���Ŀ
    CheckTaskEmpty -- ��������Ƿ��Ѿ����
    GetRequest -- �Ӷ����л�ȡ����
    DecreaseThreads -- �����߳�
    IncreaseThreads -- �����߳�
    FreeFinishedThreads -- �ͷ���ɵ��߳�
    KillDeadThreads -- ������߳�
    Info -- ��Ϣ�����ڵ������
    OSIsWin9x -- ����ϵͳ��Win9x
    AddRequest -- ��������
    RemoveRequest -- �Ӷ�����ɾ������
    CreateSpecial -- �����Զ����̳߳��̵߳Ĺ��캯��
    AdjustInterval -- �����̵߳�ʱ����
    DeadTaskAsNew -- �����̵߳��������¼ӵ�����
    MinAtLeast -- �߳�����������С��Ŀ
    ThreadDeadTimeout -- �߳�������ʱ
    ThreadsMinCount -- �����߳���
    ThreadsMaxCount -- ����߳���
    OnGetInfo -- ��ȡ��Ϣ�¼�
    OnProcessRequest -- ���������¼�
    OnQueueEmpty -- ���п��¼�
    OnThreadInitializing -- �̳߳�ʼ���¼�
    OnThreadFinalizing -- �߳���ֹ���¼�
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
    FWaitingTime:Int64;                    //�ܹ��ȴ�ʱ��
    FProcessingTime:Int64;                 //�ܹ�����ִ��ʱ������ʱ��
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
    '��ʼ��', '�ȴ�',
    '��ȡ����',
    '��������', '�������',
    '�ͷ�', 'У���߳���');
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
  Result := '���ȴ�ʱ�� ��' + IntToStr(FWaitingTime) +
    #13#10'������ʱ�� ��' + IntToStr(FProcessingTime) +
    #13#10'��ǰ״̬ ��' + CCnTHREADSTATE[FCurState] + 
    #13#10'��ִ�д��� ��' + IntToStr(FWorkCount);
  if csProcessingDataObject.TryEnter then
  try
    Result := Result + #13#10'��ǰִ�������ַ ��';
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
  sLine := '��������������������������������������������������������������������������������';
  with Sender do
  begin
    FreeFinishedThreads;
    InfoText := '�߳����� ��' + IntToStr(ThreadsMinCount) +
      #13#10'�߳����� ��' + IntToStr(ThreadsMaxCount) +
      #13#10'̽������̵߳�ʱ���� ��' + IntToStr(AdjustInterval) +
      #13#10'�̳߳�ʱ����ʱ�� ��' + IntToStr(ThreadDeadTimeout) +
      #13#10'��ǰ�߳��� ��' + IntToStr(ThreadCount) +
//      #13#10'���������߳��� ��' + IntToStr(ThreadKillingCount) +
      #13#10'Ъ�����߳��� ��' + IntToStr(FIdleThreadCount) +
      #13#10'�ȴ��е�������� ��' + IntToStr(TaskCount) +
      #13#10'�������������' + IntToStr(FAddedTaskCount) +
//      #13#10'ƽ���ȴ�ʱ�� ��' + IntToStr(AverageWaitingTime) +
//      #13#10'ƽ������ʱ�� ��' + IntToStr(AverageProcessingTime) + #13#10 +
      #13#10'�������е��߳���Ϣ ��' + sLine;
    for i := 0 to ThreadCount - 1 do
      InfoText := InfoText + #13#10 + ThreadInfo(i);
    InfoText := InfoText + #13#10 + {sLine +} '����ɾ�����߳���Ϣ��' + sLine;
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
    Result := 'Ӧ�ó���æ�������»�ȡ�̳߳�״̬��Ϣ.';
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

