unit GLService;

interface

uses
  WinSvc, WinSvcEx, Windows, SysUtils, Classes;

type
  TStartType = (stBoot, stSystem, stAuto, stManual, stDisabled);
  /// <remarks>
  /// ʹ��ʱ�̳�TGLService����дServiceStart��ʵ����, ΪServiceName��ServiceDisplayName��ֵ������ServiceApp.Run��ʼִ�У�
  ///  Ŀǰֻ֧��һ�����񣬾���ֻ����һ����TGLService�̳���������Ķ���
  /// </remarks>

  TGLService = class
  private
    FDescription: string;
    FStarted: Boolean;
    FOnContinue: TNotifyEvent;
    FOnPause: TNotifyEvent;
    FOnStart: TNotifyEvent;
    FOnStop: TNotifyEvent;
    FServiceDisplayName: string;
    FServiceName: string;
    FssStatus: TServiceStatus;
    FServiceStatusHandle: SERVICE_STATUS_HANDLE;
    FdwErr: DWORD;                             //������
    ServiceTableEntry: array[0..1] of TServiceTableEntry;              //һ������ֻ��һ���������
    FStartType: TStartType;
    procedure AddDescription(ServiceHandle: THandle);
    procedure Install;
    procedure UnInstall;
    procedure AddToMessageLog(sMsg: string);  //д��Ϣ��Windows������־

    procedure OutputDebugString(str: string);
    function GetLastErrorText: string;
    function ReportStatusToSCMgr(dwState, dwExitCode, dwWait: DWORD): BOOL;   //���·���״̬

    procedure ServiceRun;
    function GetNTStartType: integer;
  public
    constructor create;
    procedure ServiceStop; virtual;
    procedure ServiceStart; virtual;
    procedure ServicePause; virtual;
    procedure ServiceContinue; virtual;
    procedure GetAChar(AChar: AnsiString); virtual;
    procedure init;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
    property OnPause: TNotifyEvent read FOnPause write FOnPause;
    property OnContinue: TNotifyEvent read FOnContinue write FOnContinue;
    property Description: string read FDescription write FDescription;
    property ServiceDisplayName: string read FServiceDisplayName write FServiceDisplayName;
    property ServiceName: string read FServiceName write FServiceName;
    property StartType: TStartType read FStartType write FStartType;
    procedure Run;
    procedure DebugRun;
  end;

  /// <remarks>
  /// ����ʱ֧��һ������
  /// </remarks>
  TGLServiceAPP = class
  private
    ServiceS: TList;
    function GetService(Index: Integer): TGLService;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ServiceExecte(Sender: TObject); virtual;
    procedure Run;
    procedure DebugRun;
    procedure Add(Service: TGLService);
    property Service[Index: Integer]: TGLService read GetService;
  end;

var
  ServiceApp: TGLServiceAPP;

implementation

function RunAsConsole: Boolean;
var
  hStdOut: THandle;
begin
  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if hStdOut = INVALID_HANDLE_VALUE then
    RaiseLastOsError;
  Result := False;
  case GetFileType(hStdOut) of
    FILE_TYPE_CHAR:
      Result := True;
  end;
end;


{ TGLService }

procedure TGLService.AddDescription(ServiceHandle: THandle);
var
  sdBuf: SERVICE_DESCRIPTIONW;
begin
  sdBuf.lpDescription := PWideChar(FDescription);
  ChangeServiceConfig2W(ServiceHandle, SERVICE_CONFIG_DESCRIPTION, @sdBuf);
end;

procedure TGLService.AddToMessageLog(sMsg: string);
var
  sString: array[0..1] of string;
  hEventSource: THandle;
begin
  hEventSource := RegisterEventSource(nil, PWideChar(ServiceName));

  if hEventSource > 0 then
  begin
    sString[0] := ServiceName + ' error: ' + IntToStr(FdwErr);
    sString[1] := sMsg;
    ReportEvent(hEventSource, EVENTLOG_ERROR_TYPE, 0, 0, nil, 2, 0, @sString, nil);
    DeregisterEventSource(hEventSource);
  end;
end;

constructor TGLService.create;
begin
  FStarted := False;
  FStartType := stAuto;
  if Assigned(ServiceApp) then
  begin
    ServiceApp.Add(Self);
  end;
end;

procedure TGLService.DebugRun;
begin
  ServiceApp.DebugRun;
end;

procedure TGLService.GetAChar(AChar: AnsiString);
begin

end;

function TGLService.GetLastErrorText: string;
var
  dwSize: DWORD;
  lpszTemp: LPTSTR;
begin
  dwSize := 512;
  lpszTemp := nil;
  try
    GetMem(lpszTemp, dwSize);
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, GetLastError, LANG_NEUTRAL, lpszTemp, dwSize, nil);
  finally
    Result := StrPas(lpszTemp);
    FreeMem(lpszTemp);
  end;
end;

function TGLService.GetNTStartType: integer;
const
  NTStartType: array[TStartType] of Integer = (SERVICE_BOOT_START, SERVICE_SYSTEM_START, SERVICE_AUTO_START, SERVICE_DEMAND_START, SERVICE_DISABLED);
begin
  Result := NTStartType[FStartType];
  if (FStartType in [stBoot, stSystem]){ and (FServiceType <> stDevice) } then
    Result := SERVICE_AUTO_START;
end;

procedure DispachProc(dwCtrlCode: DWORD); stdcall;
begin
  ServiceApp.GetService(0).OutputDebugString('������ DispachProc��');
  case dwCtrlCode of
    SERVICE_CONTROL_STOP:                      //ֹͣ����
      begin
//      ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_STOP_PENDING, NO_ERROR, 0);
        ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_STOPPED, GetLastError, 0);
        ServiceApp.GetService(0).ServiceStop;
        exit;
      end;
    SERVICE_CONTROL_INTERROGATE:            //��ø�����Ϣ
      begin
      end;

    SERVICE_CONTROL_PAUSE:                  //��ͣ����
      begin
        ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_PAUSE_PENDING, NO_ERROR, 0);
        ServiceApp.GetService(0).ServicePause;
        ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_PAUSED, GetLastError, 0);
      end;

    SERVICE_CONTROL_CONTINUE:              //����
      begin
        ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_PAUSE_CONTINUE, NO_ERROR, 0);
        ServiceApp.GetService(0).ServiceContinue;
        ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_RUNNING, GetLastError, 0);
      end;

    SERVICE_CONTROL_SHUTDOWN:             //ϵͳ�ر�ʱ����
      begin
//      ServiceAPP.ReportStatusToSCMgr(SERVICE_START_PENDING);
      end;

    // invalid control code
  else

  end;

// update the service status.
  ServiceApp.GetService(0).ReportStatusToSCMgr(ServiceApp.GetService(0).FssStatus.dwCurrentState, NO_ERROR, 0);
end;

procedure ServiceMain;
var
  str: string;
begin
  str := ServiceApp.GetService(0).FServiceName;
  ServiceApp.GetService(0).OutputDebugString('���� ServiceMain+ Name��' + str);
  ServiceApp.GetService(0).FServiceStatusHandle := RegisterServiceCtrlHandler(PWideChar(str), ThandlerFunction(@DispachProc));
  ServiceApp.GetService(0).OutputDebugString('���� after RegisterServiceCtrlHandler  ' + inttostr(GetLastError){ServiceApp.GetService(0).GetLastErrorText});

  if ServiceApp.GetService(0).FServiceStatusHandle = 0 then
  begin
    ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_STOPPED, GetLastError, 0);
    exit;
  end;

  ServiceApp.GetService(0).FssStatus.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
  ServiceApp.GetService(0).FssStatus.dwServiceSpecificExitCode := 0;
  ServiceApp.GetService(0).FssStatus.dwCheckPoint := 1;

  // Report current status to SCM (Service Control Manager)
  if not ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_START_PENDING, NO_ERROR, 3000) then
  begin
    ServiceApp.GetService(0).ReportStatusToSCMgr(SERVICE_STOPPED, GetLastError, 0);
    exit;
  end;
  ServiceApp.GetService(0).ServiceRun;
end;

procedure TGLService.init;
begin
//  ServiceMain;
  OutputDebugString('�����ʼ��1��');
  if ParamCount > 0 then
  begin
    if LowerCase(ParamStr(1)) = '-install' then
    begin
      Install;
      Halt;
    end;
    if LowerCase(ParamStr(1)) = '-uninstall' then
    begin
      UnInstall;
      Halt;
    end;
  end;
  with ServiceTableEntry[0] do
  begin
    lpServiceName := PWideChar(FServiceName);
    lpServiceProc := @ServiceMain;
  end;

  with ServiceTableEntry[1] do
  begin
    lpServiceName := nil;
    lpServiceProc := nil;
  end;

  if not StartServiceCtrlDispatcher(ServiceTableEntry[0]) then
  begin
    AddToMessageLog('StartServiceCtrlDispatcher Error!');
    OutputDebugString('����ʧ�ܣ�' + inttostr(GetLastError));
    Halt;
  end;
end;

procedure TGLService.Install;
var
  schService: SC_HANDLE;
  schSCManager: SC_HANDLE;
  lpszPath: LPTSTR;
  dwSize: DWORD;
begin
  dwSize := 512;
  GetMem(lpszPath, dwSize);
  if GetModuleFileName(0, lpszPath, dwSize) = 0 then
  begin
    FreeMem(lpszPath);
    OutputDebugString('���� Unable to install ' + FServiceName + ',GetModuleFileName Fail.');
    exit;
  end;
  FreeMem(lpszPath);
  schSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (schSCManager > 0) then
  begin
    schService := createService(schSCManager, PWideChar(FServiceName), PWideChar(FServiceDisplayName), SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS, {SERVICE_DEMAND_START}GetNTStartType, SERVICE_ERROR_NORMAL, pchar(ParamStr(0)), nil, nil, nil, nil, nil);
    if (schService > 0) then
    begin
      OutputDebugString('���� Install Ok.');
      if FDescription <> '' then
        AddDescription(schService);
      CloseServiceHandle(schService);
    end
    else
      OutputDebugString('���� Unable to install ' + FServiceName + ',createService Fail.');
  end
  else
    OutputDebugString('���� Unable to install ' + FServiceName + ',OpenSCManager Fail.');
end;

procedure TGLService.OutputDebugString(str: string);
begin
  OutputDebugStringA(PAnsiChar(str));
end;

function TGLService.ReportStatusToSCMgr(dwState, dwExitCode, dwWait: DWORD): BOOL;
begin
  Result := True;
  with FssStatus do
  begin
    if (dwState = SERVICE_START_PENDING) then
      dwControlsAccepted := 0
    else
      dwControlsAccepted := SERVICE_ACCEPT_STOP;

    dwCurrentState := dwState;
    dwWin32ExitCode := dwExitCode;
    dwWaitHint := dwWait;

    if (dwState = SERVICE_RUNNING) or (dwState = SERVICE_STOPPED) then
      dwCheckPoint := 0
    else
      inc(dwCheckPoint);
  end;

  Result := SetServiceStatus(FServiceStatusHandle, FssStatus);
  if not Result then
    AddToMessageLog('SetServiceStauts');
end;

procedure TGLService.Run;
begin
  ServiceApp.Run;
end;

procedure TGLService.ServiceContinue;
begin
  OutputDebugString('�������');
  if Assigned(FOnContinue) then
    FOnContinue(Self);
end;

procedure TGLService.ServicePause;
begin
  OutputDebugString('������ͣ');
  if Assigned(FOnPause) then
    FOnPause(Self);
end;

procedure TGLService.ServiceRun;
var
  Runing: Boolean;
  getChar: AnsiString;
  AChar: AnsiChar;
begin
  OutputDebugString('����ServiceRun');
  FStarted := true;
  Runing := False;
  if RunAsConsole then
  begin
    writeln('����Exit�س��˳���');
    ServiceStart;
    while True do
    begin
      read(AChar);
      getChar := getChar + AChar;
      if AChar = #10 then
      begin
        if Trim(getChar) = 'Exit' then
        begin
          writeln('�����˳���');
          ServiceStop;
          Break;
        end
        else
        begin
          getAChar(Trim(getChar));
          getChar := '';
        end;
      end;
    end;
    Self.Free;
    Exit;
  end;

  while True do
  begin
    if not FStarted then
      Break;
    if not Runing then
    begin
      ServiceStart;
      Runing := true;
    end
    else
      Sleep(10000);
  end;
end;

procedure TGLService.ServiceStart;
begin
  if not ReportStatusToSCMgr(SERVICE_START_PENDING, NO_ERROR, 3000) then
    exit;
  if not ReportStatusToSCMgr(SERVICE_RUNNING, NO_ERROR, 0) then
  begin
    exit;
  end;
  OutputDebugString('��������');
  if Assigned(FOnStart) then
    FOnStart(Self);
end;

procedure TGLService.ServiceStop;
begin
  FStarted := False;
  OutputDebugString('����ֹͣ');
  if Assigned(FOnStop) then
    FOnStop(Self);
  // TODO -cMM: TGLService.ServiceStop default body inserted
end;

procedure TGLService.UnInstall;
var
  schService: SC_HANDLE;
  schSCManager: SC_HANDLE;
begin
  schSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (schSCManager > 0) then
  begin
    schService := OpenService(schSCManager, PWideChar(ServiceName), SERVICE_ALL_ACCESS);
    if (schService > 0) then
    begin
      // Try to stop service at first
      if ControlService(schService, SERVICE_CONTROL_STOP, FssStatus) then
      begin
        OutputDebugString('���� Stopping Service ');
        Sleep(1000);
        while (QueryServiceStatus(schService, FssStatus)) do
        begin
          if FssStatus.dwCurrentState = SERVICE_STOP_PENDING then
          begin
            OutputDebugString('.');
            Sleep(1000);
          end
          else
            break;
        end;

        if FssStatus.dwCurrentState = SERVICE_STOPPED then
          OutputDebugString('���� Service Stop Now')
        else
        begin
          CloseServiceHandle(schService);
          CloseServiceHandle(schSCManager);
          OutputDebugString('���� Service Stop Fail');
          exit;
        end;
      end;

        // Remove the service
      if (deleteService(schService)) then
        OutputDebugString('���� Service Uninstall Ok.')
      else
        OutputDebugString('���� deleteService fail (' + GetLastErrorText + ').');

      CloseServiceHandle(schService);
    end
    else
      OutputDebugString('���� OpenService fail (' + GetLastErrorText + ').');

    CloseServiceHandle(schSCManager);
  end
  else
    OutputDebugString('���� OpenSCManager fail (' + GetLastErrorText + ').');
end;

procedure TGLServiceAPP.Add(Service: TGLService);
begin
  ServiceS.Add(Service);
end;

constructor TGLServiceAPP.Create;
var
  GLService: TGLService;
begin
  ServiceS := TList.Create;
//  GLService := TGLService.create;
//  GLService.OnStart := ServiceExecte;
//  Add(GLService);
end;

procedure TGLServiceAPP.DebugRun;
begin
  GetService(0).ServiceRun;
end;

destructor TGLServiceAPP.Destroy;
begin
  ServiceS.Free;
  inherited;
end;

function TGLServiceAPP.GetService(Index: Integer): TGLService;
begin
  // TODO -cMM: TGLServiceAPP.GetService default body inserted
  Result := TGLService(ServiceS.Items[Index]);
end;

{ TGLServiceAPP }

procedure TGLServiceAPP.Run;
begin
  GetService(0).init;
end;

procedure TGLServiceAPP.ServiceExecte(Sender: TObject);
begin

end;

initialization
  ServiceApp := TGLServiceAPP.Create;

finalization
  ServiceApp.Free;

end.

