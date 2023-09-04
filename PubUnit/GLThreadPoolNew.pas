unit GLThreadPoolNew;

interface

uses Classes,Windows,GLCircleQueue,SysUtils,GLLogger,GLWindowsAPI;

const
  Thread_State_Processing = $01;            //��������
  Thread_State_Waiting = $02;               //�ȴ�
  Thread_State_Getting = $04;               //��ȡ����
  Thread_State_Freeing = $08;               //�ͷ��߳�
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
    FWaitTime:Cardinal;                                    //�ܹ��ȴ�ʱ��
    FLastWaitTime:Cardinal;                                //���һ�εȴ�ʱ��  �����ж��Ƿ�Ҫ�ͷ���
    FOtherInfo: string;
    FProcessTime:Cardinal;                                 //��������������ʱ��
///��ʱû���������������������������ƻ����ڴ��������
    LastActiveTime:TDateTime;
    FCurProcessStartTime:Cardinal;                         //�˴�����ִ�п�ʱ��ʱ�䣬�����ж�����ִ��ʱ��̫��ʱ�����߳�
    procedure ForceDestroy;                                //ǿ����ֹ�̣߳�

  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TGLThreadPoolManage);
    property OtherInfo: string read FOtherInfo write FOtherInfo;
  end;

  TGLThreadPoolManage = class
  private
    ThreadRunningCount:Integer;   //����ִ��������̸߳��� 
    Threads : TThreadList;
    IncThreadTag:Integer;      //�������ʶ�ﵽĳ��ֵʱ������߳�
    CircleQueue:TGLCircleQueue;
    FOnProcessTask: TOnProcessTask;
    FCurrentThreadCount:integer;     //�����ж�Ҫ��Ҫ����̣߳�û���ٽ籣�����Ա����������ʼ�մ��ڴ���ʱ�ٽ��ٽ���
    FAddCount: Int64;
    FAddFaildCount:Int64;          //�������ʧ�ܸ���
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
    property MaxCount: Word read FMaxCount write FMaxCount;              //����߳���
    property MinCount: Word read FMinCount write SetMinCount;            //��С�߳���
    property NoTaskThenFreeTime: Cardinal read FNoTaskThenFreeTime write     //�೤ʱ��û�нӵ�������˳��߳�
        FNoTaskThenFreeTime;
    property TaskClass: TTaskClass read FTaskClass write FTaskClass;
    property MaxWaitTask:Cardinal read GetCircleQueueSize write setCircleQueueSize;//���������и������������������������ʧ��
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
  AtaskArr:TArrTask;          //��������ģʽ
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
      Logger.WriteLog(LTError,'�����߳��г��ִ��� : '+Exception(ExceptObject).Message);
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
  if (FCurrentThreadCount<FMaxCount) and (CircleQueue.Count>FCurrentThreadCount) then          //û�뵽�õ���㷨
  begin
//    InterlockedIncrement(IncThreadTag);           //��ֵ��
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
      str := '��������ģʽ'
    else
      str := '��������ģʽ';
    Result := '�����̳߳���Ϣ��'#13#10+
              '�߳����ޣ�'+inttostr(FMinCount)+#13#10+
              '�߳����ޣ�'+inttostr(FMaxCount)+#13#10+
              '��ǰ�߳�����'+inttostr(CurCount)+#13#10+
              '�������������'+inttostr(FAddCount)+'  ʧ��: '+inttostr(FAddFaildCount)+#13#10+
              '��ǰ�����������������'+inttostr(CircleQueue.Count)+#13#10+
              '�߳������ͷ�ʱ����'+inttostr(FNoTaskThenFreeTime)+#13#10+
              '���񵯳�ģʽ��'+str+#13#10+
              '���߳�״̬��'#13#10+StringOfChar('=',50)+#13#10;
    List := Threads.LockList;
    try
      for I := 0 to List.Count - 1 do
      begin
        Thread := TProcessThread(List.Items[I]);
        Result := Result + '�߳�ID��'+inttostr(Thread.ThreadID);
        Result := Result + '  ��ǰ״̬��'+GetTreadStateStr(Thread.FCurState);
        Result := Result + '  �ܹ��ȴ�ʱ����'+IntToStr(Thread.FWaitTime)+
                           '  �ܹ���ʱʱ����'+IntToStr(Thread.FProcessTime)+
                           '  ������������'+ IntToStr(Thread.ProcessCount)+
                           '  ���������ʱ�䣺'+DateTimeToStr(Thread.LastActiveTime)+
                           '  ������Ϣ��'+Thread.FOtherInfo+#13#10+
                           StringOfChar('-',50)+#13#10;
      end;
    finally
      Threads.UnlockList;
    end;
  except
    Result := '��ȡTGLThreadPoolManage����Ϣ�쳣 :'+Exception(ExceptObject).Message+Result;
  end;
end;

function TGLThreadPoolManage.GetTaskArr: TArrTask;
begin
  Result := TArrTask(CircleQueue.PopArrData);
end;

function TGLThreadPoolManage.GetTreadStateStr(I: integer): string;
begin
  case I of
    Thread_State_Processing:Result := '��������';
    Thread_State_Getting : result := '���ڻ�ȡ����';
    Thread_State_Waiting : Result := '�ȴ���';
    Thread_State_Freeing : Result := '�����ͷ�';
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
