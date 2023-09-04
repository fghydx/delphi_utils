unit GLThreadPoolNew;

interface

uses Classes,Windows,GLCircleQueue,SysUtils,GLLogger,GLWindowsAPI;

const
  Thread_State_Processing = $01;            //处理任务
  Thread_State_Waiting = $02;               //等待
  Thread_State_Getting = $04;               //获取任务
  Thread_State_Freeing = $08;               //释放线程
Type
  TTask = class
  public
    constructor Create; virtual;
  end;

  TTaskClass = class of TTask;

  TArrTask = array of TTask;

  TGLThreadPoolManage = class;
  TGLThreadPoolManageClass = class of TGLThreadPoolManage;

  TProcessThread = class;

  TOnProcessTask = procedure(Thread:TProcessThread;Task:TTask) of object;

  TProcessThread=class(TThread)
  private
    FOwner : TGLThreadPoolManage;
    FCurState : Byte;
    ProcessCount:Cardinal;
    FWaitTime:Cardinal;                                    //总共等待时长
    FLastWaitTime:Cardinal;                                //最后一次等待时长  用于判断是否要释放他
    FOtherInfo: string;
    FProcessTime:Cardinal;                                 //处理任务所用总时长
///暂时没处理任务死锁，下面两个方法计划用于处理这个事
    LastActiveTime:TDateTime;
    FCurProcessStartTime:Cardinal;                         //此次任务执行开时的时间，用来判断任务执行时间太长时销毁线程
    procedure ForceDestroy;                                //强制终止线程，

  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TGLThreadPoolManage);
    property OtherInfo: string read FOtherInfo write FOtherInfo;
  end;

  TGLThreadPoolManage = class
  private
    ThreadRunningCount:Integer;   //正在执行任务的线程个数 
    Threads : TThreadList;
    IncThreadTag:Integer;      //在这个标识达到某个值时才添加线程
    CircleQueue:TGLCircleQueue;
    FOnProcessTask: TOnProcessTask;
    FCurrentThreadCount:integer;     //用来判断要不要添加线程，没做临界保护，以便在任务添加始终大于处理时少进临界区
    FAddCount: Int64;
    FAddFaildCount:Int64;          //添加任务失败个数
    FBatchTaskPop: Boolean;
    FMaxCount: Word;
    FMinCount: Word;
    FNoTaskThenFreeTime: Cardinal;
    FTaskClass: TTaskClass;

    procedure SetMinCount(const Value: Word);
    function GetATask:TTask;
    function GetTaskArr:TArrTask;

    procedure CheckIncThread;
    procedure CheckDecThread(CurThread: TProcessThread);
    function GetCurCount: Integer;
    function GetTreadStateStr(I:integer):string;

    procedure GLCircleQueueFreeItem(Data:Pointer);
    procedure SetBatchTaskPop(const Value: Boolean);
    function GetCircleQueueSize: Cardinal;
    procedure setCircleQueueSize(const Value: Cardinal);
  protected
    procedure DoProcessTask(Thread:TProcessThread;Task:TTask);virtual;
  public

    constructor Create;virtual;
    destructor Destroy; override;
    function AddATask(Task: TTask): Boolean;virtual;

    function GetInfo:string;

    property CurCount: Integer read GetCurCount;
    property OnProcessTask: TOnProcessTask read FOnProcessTask write FOnProcessTask;
    property BatchTaskPop: Boolean read FBatchTaskPop write SetBatchTaskPop;
    property MaxCount: Word read FMaxCount write FMaxCount;              //最大线程数
    property MinCount: Word read FMinCount write SetMinCount;            //最小线程数
    property NoTaskThenFreeTime: Cardinal read FNoTaskThenFreeTime write     //多长时间没有接到任务就退出线程
        FNoTaskThenFreeTime;
    property TaskClass: TTaskClass read FTaskClass write FTaskClass;
    property MaxWaitTask:Cardinal read GetCircleQueueSize write setCircleQueueSize;//最大任务队列个数，超过这个数，添加任务会失败
  end;

implementation

uses GLPubFunc;

constructor TProcessThread.Create(Owner: TGLThreadPoolManage);
begin
  inherited Create(False);
  FOwner := Owner;
  FreeOnTerminate := True;
end;

procedure TProcessThread.Execute;
var
  ATask:TTask;
  AtaskArr:TArrTask;          //批量弹出模式
  Time:Cardinal;
  I,ArrLen: Integer;
  P:Pointer;
begin
  inherited;
  while not Terminated do
  begin
    try
      AtaskArr := nil;
      ATask := nil;
      FCurState := Thread_State_Getting;
      Time := GetTickCount;
      if FOwner.FBatchTaskPop then
      begin
        AtaskArr := FOwner.GetTaskArr;
        P := AtaskArr;
      end else
      begin
        ATask := FOwner.GetATask;
        P := ATask;
      end;
      FWaitTime := FWaitTime + GetTickCountDiff(Time,GetTickCount);
      if P<>nil then
      begin
        FCurState := Thread_State_Processing;
        Time := GetTickCount;
        FCurProcessStartTime := Time;
        InterlockedIncrement(FOwner.ThreadRunningCount);
        try
          if AtaskArr<>nil then
          begin
            ArrLen := Length(AtaskArr);
            for I := 0 to ArrLen - 1 do
            begin
              ATask := AtaskArr[I];
              try
                FOwner.DoProcessTask(Self,ATask);
                inc(ProcessCount);
              finally
                ATask.Free;
              end;
            end;
            SetLength(AtaskArr,0);
          end else if ATask<>nil then                 
          begin
            try
              FOwner.DoProcessTask(Self,ATask);
              inc(ProcessCount);
            finally
              ATask.Free;
            end;
          end;
        except
          ;
        end;
        FLastWaitTime := 0;
        FProcessTime := FProcessTime + GetTickCountDiff(Time,GetTickCount);
        InterlockedDecrement(FOwner.ThreadRunningCount);
        LastActiveTime := Now;
      end else
      begin
        FLastWaitTime := FLastWaitTime + GetTickCountDiff(Time,GetTickCount);
        FOwner.CheckDecThread(Self);
      end;
    except
      Logger.WriteLog(LTError,'任务线程中出现错误 : '+Exception(ExceptObject).Message);
    end;
  end;
end;

procedure TProcessThread.forceDestroy;
begin
  TerminateThread(Self.Handle,0);
end;

procedure TGLThreadPoolManage.CheckDecThread(CurThread: TProcessThread);
var
  List:TList;
  I: Integer;
  tem:TProcessThread;
begin
  List := Threads.LockList;
  try
    if List.Count>FMinCount then
    begin
      if CurThread.FLastWaitTime>FNoTaskThenFreeTime then
      begin
        List.Remove(CurThread);
        CurThread.Terminate;
        FCurrentThreadCount := List.Count;

        for I := 0 to List.Count - 1 do
        begin
          tem := List.Items[I];
          tem.FLastWaitTime := 0;
        end;
      end;
    end;
  finally
    Threads.UnlockList;
  end;
end;

procedure TGLThreadPoolManage.CheckIncThread;
var
  List:TList;
  TemThread:TProcessThread;
begin
  if (FCurrentThreadCount<FMaxCount) and (CircleQueue.Count>FCurrentThreadCount) then          //没想到好点的算法
  begin
//    InterlockedIncrement(IncThreadTag);           //阀值，
//    if IncThreadTag>10 then
//    begin
      List := Threads.LockList;
      try
        if List.Count>=FMaxCount then exit;

        TemThread := TProcessThread.Create(Self);
        List.Add(TemThread);
        FCurrentThreadCount := List.Count;
        SetThreadOnCPU(TemThread.Handle,List.Count);
      finally
        Threads.UnlockList;
      end;
//      IncThreadTag := 0;
//    end;
  end;
end;

constructor TGLThreadPoolManage.Create;
begin
  inherited;
  CircleQueue := TGLCircleQueue.Create(10000);
  CircleQueue.PopBlock := True;
  FBatchTaskPop := False;
  Threads := TThreadList.Create;
end;

destructor TGLThreadPoolManage.Destroy;
var
  List:Tlist;
  I:integer;
  TemThread:TProcessThread;
  arrayHandle : array of THandle;
begin
  List := Threads.LockList;
  try
    SetLength(arrayHandle,List.Count);
    for I := (List.Count-1) downto 0  do
    begin
      TemThread := List.Items[I];
      arrayHandle[I]:=TemThread.Handle;
      List.Delete(I);
      TemThread.Terminate;
      CircleQueue.SetEvent;
    end;
  finally
    Threads.UnlockList;
  end;

  WaitForMultipleObjects(Length(arrayHandle),PWOHandleArray(arrayHandle),True,1000);
  SetLength(arrayHandle,0);

  CircleQueue.Free;
  Threads.Free;
  inherited;
end;

procedure TGLThreadPoolManage.DoProcessTask(Thread: TProcessThread;
  Task: TTask);
begin
  if Assigned(FOnProcessTask) then
    FOnProcessTask(Thread,Task);
end;

function TGLThreadPoolManage.GetATask: TTask;
begin
  Result := CircleQueue.Pop;
end;

function TGLThreadPoolManage.AddATask(Task: TTask): Boolean;
begin
  Result := CircleQueue.Push(Task);
  if Result then
    InterlockedIncrement64(FAddCount)
  else
    InterlockedIncrement64(FAddFaildCount);
  CheckIncThread;
end;

function TGLThreadPoolManage.GetCircleQueueSize: Cardinal;
begin
  Result := CircleQueue.Size;
end;

function TGLThreadPoolManage.GetCurCount: Integer;
var
  List:TList;
begin
  List := Threads.LockList;
  try
    Result := List.Count;
  finally
    Threads.UnlockList;
  end;
end;

function TGLThreadPoolManage.GetInfo: string;
var
  List:TList;
  I: Integer;
  Thread:TProcessThread;
  str:string;
begin
  try
    if FBatchTaskPop then
      str := '批量弹出模式'
    else
      str := '单个弹出模式';
    Result := '任务线程池信息：'#13#10+
              '线程下限：'+inttostr(FMinCount)+#13#10+
              '线程上限：'+inttostr(FMaxCount)+#13#10+
              '当前线程数：'+inttostr(CurCount)+#13#10+
              '共添加任务数：'+inttostr(FAddCount)+'  失败: '+inttostr(FAddFaildCount)+#13#10+
              '当前任务队列中任务数：'+inttostr(CircleQueue.Count)+#13#10+
              '线程闲置释放时长：'+inttostr(FNoTaskThenFreeTime)+#13#10+
              '任务弹出模式：'+str+#13#10+
              '各线程状态：'#13#10+StringOfChar('=',50)+#13#10;
    List := Threads.LockList;
    try
      for I := 0 to List.Count - 1 do
      begin
        Thread := TProcessThread(List.Items[I]);
        Result := Result + '线程ID：'+inttostr(Thread.ThreadID);
        Result := Result + '  当前状态：'+GetTreadStateStr(Thread.FCurState);
        Result := Result + '  总共等待时长：'+IntToStr(Thread.FWaitTime)+
                           '  总共耗时时长：'+IntToStr(Thread.FProcessTime)+
                           '  处理任务数：'+ IntToStr(Thread.ProcessCount)+
                           '  最后处理任务时间：'+DateTimeToStr(Thread.LastActiveTime)+
                           '  其它信息：'+Thread.FOtherInfo+#13#10+
                           StringOfChar('-',50)+#13#10;
      end;
    finally
      Threads.UnlockList;
    end;
  except
    Result := '获取TGLThreadPoolManage的信息异常 :'+Exception(ExceptObject).Message+Result;
  end;
end;

function TGLThreadPoolManage.GetTaskArr: TArrTask;
begin
  Result := TArrTask(CircleQueue.PopArrData);
end;

function TGLThreadPoolManage.GetTreadStateStr(I: integer): string;
begin
  case I of
    Thread_State_Processing:Result := '处理任务';
    Thread_State_Getting : result := '正在获取任务';
    Thread_State_Waiting : Result := '等待中';
    Thread_State_Freeing : Result := '正在释放';
  end;
end;

procedure TGLThreadPoolManage.GLCircleQueueFreeItem(Data: Pointer);
var
  Task:TTask;
begin
  Task := TTask(Data);
  if Task<>nil then
    Task.Free;
end;

procedure TGLThreadPoolManage.SetBatchTaskPop(const Value: Boolean);
begin
  if Value<>FBatchTaskPop then
  begin
    FBatchTaskPop := Value;
    CircleQueue.PopArr := FBatchTaskPop;
  end;
end;

procedure TGLThreadPoolManage.setCircleQueueSize(const Value: Cardinal);
begin
  CircleQueue.Size := Value;
  CircleQueue.AutoExpansion := False;
end;

procedure TGLThreadPoolManage.SetMinCount(const Value: Word);
var
  List:TList;
  I: Integer;
  TemThread:TProcessThread;
begin
  FMinCount := Value;
  List := Threads.LockList;
  try
    if List.Count<Value then
    begin
      for I := 0 to Value - List.Count - 1 do
      begin
        TemThread := TProcessThread.Create(Self);
        List.Add(TemThread);
        SetThreadOnCPU(TemThread.Handle,List.Count);
      end;
    end else
    begin
      for I := 0 to List.Count - Value - 1 do
      begin
        TemThread := List.Items[I];
        List.Delete(I);
        TemThread.Terminate;
      end;
    end;
  finally
    Threads.UnlockList;
  end;
end;

constructor TTask.Create;
begin
  inherited;
  // TODO -cMM: TTask.Create default body inserted
end;

end.
