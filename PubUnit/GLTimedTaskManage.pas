/// <remarks>
/// ��ʱ����
/// </remarks>
unit GLTimedTaskManage;

interface

uses GLTimeWheel,GLBinaryTree,GLSyncObj,Classes;

const
  MaxCardinal = 4294967295;
  OneDatMillonSecond = 1000*60*60*24;
type
  TTaskType = (TTMultRun,TTAtDateTime,TTAtTime);

  TGLTimedTaskManage = class;

  TGLTimeTask = class
  private
    FSynExec : Boolean;
    RunTimes:Cardinal;
    Running:Boolean;
    TimeOut:Cardinal;
    TaskName:string;
    repeatTask:boolean;
    TaskType : TTaskType;
    LastRunTime:TDateTime;
    RunTime:TDateTime;                          //ָ�����ڻ�ʱ�����е�ֵ ,����ʱ���ִ�м��
  public
    constructor Create(SynExec: Boolean = true);
    procedure run;virtual;abstract;
  end;

  TonRun = procedure of object;

  TRunTaskThread = class(TThread)
  private
    FOnRun: TonRun;
    FTask:TGLTimeTask;
    FOwner:TGLTimedTaskManage;
  protected
    procedure Execute; override;
    property OnRun: TonRun read FOnRun write FOnRun;
  public
    constructor Create(AOwner:TGLTimedTaskManage;ATask : TGLTimeTask);
  end;

  TGLTimedTaskManage = class
  private
    TimeWheel:TGLTimeWheelStr;
    TaskManageFree:Boolean;
    TaskDatas:TGLStringRBTree;
    Locker:TGLCriticalSection;
    RunningTaskThread:TGLStringRBTree;
    function OnTimeOut(Key:Pointer;Data:Pointer): Boolean;

    procedure OnDeleteItem(Data:pointer);

    procedure AddRunningTask(TemTaskName:String;ATask:TGLTimeTask);
    procedure RemoveRunningTask(TemTaskName:String;ATask:TGLTimeTask);
  public
    function GetTasksInfo:string;
    constructor Create;
    destructor Destroy; override;
    /// <summary>��Ӷ�����е�����
    /// </summary>
    /// <param name="ATask"> ������� </param>
    /// <param name="RunTimes"> ���д��� -1ʱΪ��������0��1����ִ��һ��</param>
    /// <param name="Interval"> ���м��ʱ�� </param>
    /// <param name="TaskName"> �������� </param>
    procedure AddTask(ATask: TGLTimeTask; RunTimes: Integer; Interval: Cardinal;
        TaskName: string); overload;
    /// <summary>��ָ��ʱ����������
    /// </summary>
    /// <param name="ATask"> ������� </param>
    /// <param name="AtRunTime"> ָ������ʱ�� ���ֻ��ʱ�䲿�ݣ�����ÿ������</param>
    /// <param name="TaskName"> �������� </param>
    procedure AddTask(ATask:TGLTimeTask;AtRunTime:TDateTime;TaskName:String);
        overload;
  end;

implementation

uses DateUtils,SysUtils;

constructor TGLTimedTaskManage.Create;
begin
  inherited;
  TimeWheel := TGLTimeWheelStr.Create(9997);
  TimeWheel.Caption := 'TGLTimedTaskManage';
  TaskDatas := TGLStringRBTree.Create;
  RunningTaskThread := TGLStringRBTree.Create;
  Locker := TGLCriticalSection.Create;
  TimeWheel.OnTimeOut := OnTimeOut;
  TimeWheel.RollRate := 10;
  TimeWheel.ScaleCount := 97;
  TimeWheel.OnDeleteItem := OnDeleteItem;
  TaskManageFree := False;
  TimeWheel.Start;
end;

destructor TGLTimedTaskManage.Destroy;
var
  I: Integer;
begin
  inherited;
  TaskManageFree := True;
  TimeWheel.Free;
  TaskDatas.Clear;
  TaskDatas.Free;
  RunningTaskThread.Clear;
  RunningTaskThread.Free;
  Locker.Free;
end;

function TGLTimedTaskManage.GetTasksInfo: string;
var
  I: Integer;
  Task:TGLTimeTask;
begin
  if Locker.TryEnter then
  begin
    try
      for I := 0 to TaskDatas.Count - 1 do
      begin
        Task := TGLTimeTask(TaskDatas.List[I]);
        Result := Result + IntToStr(I)+'----'+Task.TaskName+':'#13#10'�������ͣ�';
        case Task.TaskType of
          TTMultRun: begin
            if Task.repeatTask then
              Result := Result + ' ���޴�ѭ��ִ���������д�����'+inttostr(Abs(Task.RunTimes)-1)
            else
              Result := Result + '���ѭ������ʣ�����д�����'+inttostr(Task.RunTimes);
            result := Result + #13#10'ִ�м��ʱ����'+inttostr(Trunc(Task.RunTime)) +' ����';
          end;
          TTAtDateTime:begin
            result := result + 'ָ������������������ ��'+DatetimeTostr(Task.RunTime);
          end;
          TTAtTime:begin
            result := result + 'ָ��ʱ������ÿ������ʱ�� ��'+TimeTostr(Task.RunTime);
          end;
        end;
          result := result + #13#10'�ϴ�ִ��ʱ�䣺'+DateTimeToStr(Task.LastRunTime);
          Result := Result + #13#10'�´�ִ��ʱ�䣺'+ DateTimeToStr(IncMilliSecond(Now,TimeWheel.GetLeaveTimeOutTimes(Task.TaskName)))+#13#10;
      end;
      Result := Result + '����ִ�е������߳�:'#13#10;
      for I := 0 to RunningTaskThread.Count - 1 do
      begin
        Task := TGLTimeTask(RunningTaskThread.List[I]);
        Result := Result + IntToStr(I)+'----��������: '+Task.TaskName+':'#13#10;
      end;
    finally
      Locker.Leave;
    end;
  end;
end;

procedure TGLTimedTaskManage.OnDeleteItem(Data: pointer);
var
  Task:TGLTimeTask;
begin
  Locker.Enter;
  try
    Task := TGLTimeTask(Data);
    if Task<>nil then
    begin
      if (not ((Task.RunTimes>0) or (Task.repeatTask))) or TaskManageFree then
      begin
        TaskDatas.Delete(Task.TaskName);
        Task.Free;
      end;
    end;
  finally
    Locker.Leave;
  end;
end;

function TGLTimedTaskManage.OnTimeOut(Key:Pointer;Data:Pointer): Boolean;
var
  Task:TGLTimeTask;
begin
  Result := True;
  Task := TGLTimeTask(Data);
  if Task<>nil then
  begin
    if Task.Running then Exit;
    Task.Running := True;

    case Task.TaskType of
      TTMultRun:begin
        Dec(Task.RunTimes);
        try
          if Task.FSynExec then
          begin
            TRunTaskThread.Create(Self,Task);
          end else
            Task.run;
          Task.LastRunTime := Now;
        except

        end;

        if (Task.RunTimes>0) or (Task.repeatTask) then
        begin
          Result := False;
          TimeWheel.Update(Task.TimeOut,Task.TaskName);
//          TimeWheel.Add(Task.TimeOut,Task.TaskName,Task,0);
        end;
      end;
      TTAtDateTime:begin
        Dec(Task.RunTimes);
        if (Task.RunTimes>0) then
        begin
          Result := False;
          TimeWheel.Update(MaxCardinal,Task.TaskName)
//          TimeWheel.Add(MaxCardinal,Task.TaskName,Task,0)
        end
        else
        begin
          try
            if Task.FSynExec then
            begin
              TRunTaskThread.Create(Self,Task);
            end else
              Task.run;
            Task.LastRunTime := Now;
          except

          end;
        end;
      end;
      TTAtTime:begin
        Result := False;
        TimeWheel.Update(OneDatMillonSecond,Task.TaskName);
//        TimeWheel.Add(OneDatMillonSecond,Task.TaskName,Task,0);
        try
          if Task.FSynExec then
          begin
            TRunTaskThread.Create(Self,Task);
          end else
            Task.run;
          Task.LastRunTime := Now;
        except

        end;
      end;
    end;
    Task.Running := False;
  end;
end;

procedure TGLTimedTaskManage.RemoveRunningTask(TemTaskName:String;ATask: TGLTimeTask);
begin
  Locker.Enter;
  try
    RunningTaskThread.Delete(TemTaskName);
  finally
    Locker.Leave;
  end;
end;

procedure TGLTimedTaskManage.AddTask(ATask: TGLTimeTask; RunTimes: Integer;
    Interval: Cardinal; TaskName: string);
begin
  ATask.TimeOut := Interval;
  Atask.RunTimes := RunTimes;
  ATask.TaskName := TaskName;
  ATask.TaskType := TTMultRun;
  ATask.Running := False;
  ATask.RunTime := Interval;

  if RunTimes<0 then
    ATask.repeatTask := true;

  TimeWheel.Add(Interval,TaskName,ATask,0);
  TaskDatas.Add(TaskName,ATask);
end;

procedure TGLTimedTaskManage.AddRunningTask(TemTaskName:String;ATask: TGLTimeTask);
begin
  Locker.Enter;
  try
    RunningTaskThread.Add(TemTaskName,ATask);
  finally
    Locker.Leave;
  end;
end;

procedure TGLTimedTaskManage.AddTask(ATask:TGLTimeTask;AtRunTime:TDateTime;
    TaskName:String);
var
  MillonSecond:Int64;
  TimeOut:Cardinal;
begin
  if (Now>AtRunTime) and (AtRunTime>1) then
  begin
    ATask.run;
    ATask.Free;
    Exit;
  end;
  ATask.Running := False;
  ATask.TaskName := TaskName;
  ATask.RunTime := AtRunTime;
  if AtRunTime>1 then
  begin
    ATask.TaskType := TTAtDateTime;
    MillonSecond := MilliSecondsBetween(Now,AtRunTime);

    ATask.RunTimes := Trunc(MillonSecond / MaxCardinal)+1;
    TimeOut := MillonSecond mod MaxCardinal;
  end else
  begin
    ATask.TaskType := TTAtTime;
    if TimeOf(Now)<AtRunTime then    
      TimeOut := MilliSecondsBetween(TimeOf(Now),AtRunTime)
    else
      TimeOut := MilliSecondsBetween(TimeOf(Now),EncodeTime(23,59,59,999))+MilliSecondsBetween(EncodeTime(0,0,0,0),AtRunTime);
  end;
  TimeWheel.Add(TimeOut,TaskName,ATask,0);
  TaskDatas.Add(TaskName,ATask);
end;

constructor TRunTaskThread.Create(AOwner:TGLTimedTaskManage;ATask : TGLTimeTask);
begin
  FreeOnTerminate := True;
  OnRun := ATask.run;
  FTask := ATask;
  FOwner := AOwner;
  inherited Create(False);
end;

procedure TRunTaskThread.Execute;
var
  temstr:String;
begin
  inherited;
  temstr := IntToStr(ThreadID)+'  '+FTask.TaskName;
  FOwner.AddRunningTask(temstr,FTask);
  try
    if Assigned(OnRun) then
      OnRun;
  finally
    FOwner.RemoveRunningTask(temstr,FTask);
  end;
end;

constructor TGLTimeTask.Create(SynExec: Boolean = true);
begin
  inherited Create();
  FSynExec := SynExec;
end;

end.
