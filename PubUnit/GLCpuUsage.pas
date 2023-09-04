unit GLCpuUsage;

interface

uses
  Windows, SysUtils, MMSystem;

const
  bWaitTime = 700;

type
  TCPUUsage = class
  private
    { Private declarations }
    FdtStartByThread: Int64;
    FdtCPUPrevByThread: Int64;
    FdtStartByProcess: Int64;
    FdtCPUPrevByProcess: Int64;
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    function GetThreadCPUUsage(threadHandle: Thandle): Int64;
    function ThreadCPUUsage(threadHandle: Thandle): Int64;
    function GetProcessCPUUsage: Int64;
    function ProcessCPUUsage: Int64;
  end;

implementation

//类初始化
constructor TCPUUsage.Create;
begin
  FdtStartByThread := 0;
  FdtCPUPrevByThread := 0;
  FdtStartByProcess := 0;
  FdtCPUPrevByProcess := 0;
  timeBeginPeriod(1);
end;

//类注销
destructor TCPUUsage.Destroy;
begin
  timeEndPeriod(1);
end;

//取得CPU线程时间
function TCPUUsage.GetThreadCPUUsage(threadHandle: Thandle): Int64;
var
  CreationTime, ExitTime, KernelTime, UserTime: TFileTime;
begin
  try
    Result := 0;
    if GetThreadTimes(threadHandle, CreationTime, ExitTime, KernelTime, UserTime) then
    begin
      Result := Int64(KernelTime.dwLowDateTime or (KernelTime.dwHighDateTime shr 32)) + Int64(UserTime.dwLowDateTime or (UserTime.dwHighDateTime shr 32));
    end;
  except
    Result := 0;
  end;
end;

//取得线程CPU使用率
function TCPUUsage.ThreadCPUUsage(threadHandle: Thandle): Int64;
var
  timespan, dtThread: Int64;
begin
  try
    Result := 0;
    timespan := 0;
    if (FdtStartByThread>0) and (FdtCPUPrevByThread>0) then
    begin
      timespan := timeGetTime() - FdtStartByThread;
      dtThread := GetThreadCPUUsage(threadHandle) - FdtCPUPrevByThread;
      if (timespan>=bWaitTime) and (dtThread>0) then
        Result := Round(((dtThread / timespan) / 100) / 2) //这里就是取CPU使用率了,不知为何总要除以2
      else
        Result := 0;
    end;
    if (timespan<=0) or (timespan>=bWaitTime) then
      FdtStartByThread := timeGetTime();
    FdtCPUPrevByThread := GetThreadCPUUsage(threadHandle);
  except
    Result := 0;
  end;
end;

//取得CPU进程时间
function TCPUUsage.GetProcessCPUUsage: Int64;
var
  CreationTime, ExitTime, KernelTime, UserTime: TFileTime;
begin
  try
    Result := 0;
    if GetProcessTimes(GetCurrentProcess, CreationTime, ExitTime, KernelTime, UserTime) then
    begin
      Result := Int64(KernelTime.dwLowDateTime or (KernelTime.dwHighDateTime shr 32)) + Int64(UserTime.dwLowDateTime or (UserTime.dwHighDateTime shr 32));
    end;
  except
    Result := 0;
  end;
end;

//取得进程CPU使用率
function TCPUUsage.ProcessCPUUsage: Int64;
var
  timespan, dtProcess: Int64;
begin
  try
    Result := 0;
    timespan := 0;
    if (FdtStartByProcess>0) and (FdtCPUPrevByProcess>0) then
    begin
      timespan := timeGetTime() - FdtStartByProcess;
      dtProcess := GetProcessCPUUsage - FdtCPUPrevByProcess;
      if (timespan>=bWaitTime) and (dtProcess>0) then
        Result := Round(((dtProcess / timespan) / 100) / 2)  //这里就是取CPU使用率了,不知为何总要除以2
      else
        Result := 0;
    end;
    if (timespan<=0) or (timespan>=bWaitTime) then
      FdtStartByProcess := timeGetTime();
    FdtCPUPrevByProcess := GetProcessCPUUsage;
  except
    Result := 0;
  end;
end;

initialization
  {initialization}
finalization
  {finalization}
end.
