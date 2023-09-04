unit GLServiceControl;

interface

uses
  Windows, WinSvc;

type
  TServiceCurrentState = (ssNotInstalled, ssUnknown, ssStopped, ssStartPending,
    ssStopPending, ssRunning, ssContinuePending, ssPausePending, ssPause);

  TGLServiceControl = class(TObject)
  private
    FComputerName: string;
    FLastErrorCode: DWORD;
    FLastErrorMsg: string;
    FServiceName: string;
    FSCHandle: Integer;
    FServiceHandle: Integer;
    function OpenSCHandle: Boolean;
    procedure CloseSCHandle;
    function OpenSvcHandle: Boolean;
    procedure CloseSvcHandle;
    function GetIsInstalled: Boolean;
    function GetCanStart: Boolean;
    function GetCanStop: Boolean;
    function GetCurrentState: TServiceCurrentState;
  protected
    procedure LogError(const ErrorMsg: string);
    property SCHandle: Integer read FSCHandle;
    property ServiceHandle: Integer read FServiceHandle;
  public
    constructor Create(const AServiceName: string; const AComputerName:
      string = '');
    destructor Destroy; override;
    /// <param name="ServiceFileName">服务程序路径</param>
    /// <param name="DisplayName">服务显示名</param>
    function Install(const ServiceFileName: string; const DisplayName: string =
        ''): Boolean;
    function Uninstall: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    function GetStatus(var Value: TServiceStatus): Boolean;
    function SetStatus(var Value: TServiceStatus): Boolean;
    property ComputerName: string read FComputerName;
    property ServiceName: string read FServiceName;
    property LastErrorCode: DWORD read FLastErrorCode;
    property LastErrorMsg: string read FLastErrorMsg;
    property IsInstalled: Boolean read GetIsInstalled;
    property CanStart: Boolean read GetCanStart;
    property CanStop: Boolean read GetCanStop;
    property CurrentState: TServiceCurrentState read GetCurrentState;
  end;

implementation

{ TGLServiceControl }

procedure TGLServiceControl.CloseSCHandle;
begin
  CloseServiceHandle(FSCHandle);
end;

procedure TGLServiceControl.CloseSvcHandle;
begin
  CloseServiceHandle(FServiceHandle);
end;

constructor TGLServiceControl.Create(const AServiceName: string; const AComputerName: string);
begin
  inherited Create;
  FServiceName := AServiceName;
  FComputerName := AComputerName;
end;

destructor TGLServiceControl.Destroy;
begin

  inherited;
end;

function TGLServiceControl.GetCanStart: Boolean;
var
  Status: TServiceStatus;
begin
  if GetStatus(Status) then
    Result := Status.dwCurrentState = SERVICE_STOPPED
  else
    Result := False;
end;

function TGLServiceControl.GetCanStop: Boolean;
var
  Status: TServiceStatus;
begin
  if GetStatus(Status) then
    Result := Status.dwControlsAccepted and SERVICE_ACCEPT_STOP > 0
  else
    Result := False;
end;

function TGLServiceControl.GetCurrentState: TServiceCurrentState;
var
  Status: TServiceStatus;
begin
  if not IsInstalled then
    Result := ssNotInstalled
  else if not GetStatus(Status) then
    Result := ssUnknown
  else
  begin
    case Status.dwCurrentState of
      SERVICE_STOPPED: Result := ssStopped;
      SERVICE_START_PENDING: Result := ssStartPending;
      SERVICE_STOP_PENDING: Result := ssStopPending;
      SERVICE_RUNNING: Result := ssRunning;
      SERVICE_CONTINUE_PENDING: Result := ssContinuePending;
      SERVICE_PAUSE_PENDING: Result := ssPausePending;
      SERVICE_PAUSED: Result := ssPause;
    else
      Result := ssUnknown;
    end;
  end;
end;

function TGLServiceControl.GetIsInstalled: Boolean;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;

    Result := True;
    
    CloseSvcHandle;
  finally
    CloseSCHandle;
  end;
end;

function TGLServiceControl.GetStatus(var Value: TServiceStatus): Boolean;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;
    try
      if not QueryServiceStatus(ServiceHandle, Value) then
        LogError('GetStatus fail')
      else
        Result := True;
    finally
      CloseSvcHandle;
    end;
  finally
    CloseSCHandle;
  end;
end;

function TGLServiceControl.Install(const ServiceFileName: string; const
    DisplayName: string = ''): Boolean;
var
  SvcHandle: Integer;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    SvcHandle := CreateService(SCHandle, PChar(ServiceName), PChar(DisplayName),
      GENERIC_EXECUTE, SERVICE_WIN32_OWN_PROCESS or SERVICE_INTERACTIVE_PROCESS,
      SERVICE_AUTO_START, SERVICE_ERROR_IGNORE, PChar(ServiceFileName),
      nil, nil, nil, nil, nil);

    if (SvcHandle = 0) and (GetLastError <> ERROR_SERVICE_EXISTS) then
      LogError('CreateService fail.')
    else
      Result := True;

    CloseServiceHandle(SvcHandle);
  finally
    CloseSCHandle;
  end;
end;

procedure TGLServiceControl.LogError(const ErrorMsg: string);
begin
  FLastErrorCode := GetLastError;
  FLastErrorMsg := ErrorMsg;
end;

function TGLServiceControl.OpenSCHandle: Boolean;
begin
  FSCHandle := OpenSCManager(PChar(ComputerName), nil, SC_MANAGER_ALL_ACCESS or
    GENERIC_WRITE or GENERIC_EXECUTE);

  if SCHandle = 0 then
  begin
    LogError('OpenSCManager fail.');
    Result := False;
  end
  else
    Result := True;
end;

function TGLServiceControl.OpenSvcHandle: Boolean;
begin
  FServiceHandle := OpenService(SCHandle, PChar(ServiceName),
    SERVICE_ALL_ACCESS);

  if ServiceHandle = 0 then
  begin
    LogError('OpenService fail');
    Result := False;
  end
  else
    Result := True;
end;

function TGLServiceControl.SetStatus(var Value: TServiceStatus): Boolean;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;
    try
      if not SetServiceStatus(ServiceHandle, Value) then
        LogError('SetStatus fail')
      else
        Result := True;
    finally
      CloseSvcHandle;
    end;
  finally
    CloseSCHandle;
  end;
end;

function TGLServiceControl.Start: Boolean;
var
  P: PChar;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;
    try
      if (not StartService(ServiceHandle, 0, P))
        and (GetLastError <> ERROR_SERVICE_ALREADY_RUNNING) then
        LogError('StartService fail')
      else
        Result := True;
    finally
      CloseSvcHandle;
    end;
  finally
    CloseSCHandle;
  end;
end;

function TGLServiceControl.Stop: Boolean;
var
  SvStatus: TServiceStatus;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;
    try
      if not ControlService(Servicehandle, SERVICE_CONTROL_STOP, svStatus) then
        LogError('StopService fail')
      else
        Result := True;
    finally
      CloseSvcHandle;
    end;
  finally
    CloseSCHandle;
  end;
end;

function TGLServiceControl.Uninstall: Boolean;
begin
  Result := False;
  if not OpenSCHandle then Exit;
  try
    if not OpenSvcHandle then Exit;
    try
      if not DeleteService(ServiceHandle) then
        LogError('DeleteService fail')
      else
        Result := True;
    finally
      CloseSvcHandle;
    end;
  finally
    CloseSCHandle;
  end;
end;

end.
