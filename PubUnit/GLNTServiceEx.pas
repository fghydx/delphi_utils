
unit GLNTServiceEx;

interface

uses
  SysUtils, Classes, Windows, WinSvc, Forms, GLMethodHook;

type
	TServiceBootType = (btSystemLoader, btIoInitSystem, btAuto, btManual,
    btDisable);

/// <remarks>
/// Nt服务对像，从Dz组件中弄过来的。
/// </remarks>  
  TGLNTService = object
  private
    Status: SERVICE_STATUS;
    Handle: SERVICE_STATUS_HANDLE;
    CheckPoint: DWORD;
    fTerminated: Boolean;
    MainDirector, HandlerDirector: TMethodDirector;
  protected
    ExecuteProc: procedure of object;
    StopProc: procedure of object;
    procedure Stop;
  public
    procedure Main(argc: Integer; argv: PPChar);
	  procedure CtrlHandler(ctrl: DWORD);
  protected
    procedure ReportState(state, exit_code, wait_hint: DWORD);
  public
    Name: string;
    Desc: string;
    procedure Initialize;
    procedure Finalize;
    function Exists: Boolean;
	  function Install(BootType: TServiceBootType; Err: PInteger = nil): Boolean;
    procedure Start;
	  function Run: Boolean;
    procedure InstallAndRun;
    property Terminated: Boolean read fTerminated;
  end;

implementation

{$IFDEF UNICODE}
function StartService(hService: SC_HANDLE; dwNumServiceArgs: DWORD;
  lpServiceArgVectors: PPWideChar): BOOL; stdcall;
  external 'advapi32' name 'StartServiceW';
{$ELSE}
function StartService(hService: SC_HANDLE; dwNumServiceArgs: DWORD;
  lpServiceArgVectors: PPAnsiChar): BOOL; stdcall;
  external 'advapi32' name 'StartServiceA';
{$ENDIF}

{ TGLNTService }

function TGLNTService.Exists: Boolean;
var
  scm: SC_HANDLE;
  svc: SC_HANDLE;
  error: Integer;
begin
  Result := False;
	scm := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
	if scm = 0 then Exit;

	svc := OpenService(scm, PChar(Name), SERVICE_ALL_ACCESS);
	if svc = 0 then
  begin
    error := GetLastError;
		CloseServiceHandle(scm);
    if error <> ERROR_SERVICE_DOES_NOT_EXIST then
      RaiseLastOSError(error);
    Exit;
  end;
	CloseServiceHandle(scm);
	CloseServiceHandle(svc);
  Result := True;
end;

procedure TGLNTService.Finalize;
begin
  Name := '';
  Desc := '';
end;

procedure TGLNTService.InstallAndRun;
const
  ERROR_FAILED_SERVICE_CONTROLLER_CONNECT = 1063;
begin
  if Exists then
  begin
    if not Run and (GetLastError = ERROR_FAILED_SERVICE_CONTROLLER_CONNECT) then
      Start;
  end
  else if Install(btManual) then Start;
end;

procedure TGLNTService.Initialize;
begin
  StopProc := Stop;
  SetMethodDirector(MainDirector, TObject(@Self), @TGLNTService.Main,
    @TwoParamStdCall);
  SetMethodDirector(HandlerDirector, TObject(@Self),
    @TGLNTService.CtrlHandler, @OneParamStdCall);
end;

procedure TGLNTService.CtrlHandler(ctrl: DWORD);
begin
  case ctrl of
    SERVICE_CONTROL_STOP:
      begin
        ReportState(SERVICE_STOP_PENDING, NO_ERROR, 0);
        StopProc;
        Exit;
      end;
    else ReportState(Status.dwCurrentState, NO_ERROR, 0);
  end;
end;

function TGLNTService.Install(BootType: TServiceBootType;
  Err: PInteger): Boolean;
var
  scm, svc: SC_HANDLE;
begin
  Result := False;
	scm := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);
	if scm = 0 then
  begin
    if Err <> nil then Err^ := GetLastError;
    Exit;
  end;

	svc := CreateService(scm, PChar(Name), PChar(Desc), 0,
		SERVICE_WIN32_OWN_PROCESS, Ord(BootType), SERVICE_ERROR_NORMAL,
    PChar(ParamStr(0)), nil, nil, nil, nil, nil);

  if svc = 0 then
  begin
    if (Err <> nil) then Err^ := GetLastError;
  end
  else begin
    CloseServiceHandle(svc);
    Result := True;
  end;
  CloseServiceHandle(scm);
end;

procedure TGLNTService.Main(argc: Integer; argv: PPChar);
begin
  Handle := RegisterServiceCtrlHandler(PChar(Name), @HandlerDirector.Call);
	if  Handle = 0 then Exit;
	Status.dwServiceType := SERVICE_WIN32_OWN_PROCESS;
	Status.dwServiceSpecificExitCode := NO_ERROR;
	ReportState(SERVICE_RUNNING, NO_ERROR, 3000);
  ExecuteProc;
  ReportState(SERVICE_STOPPED, NO_ERROR, 0);
end;

procedure TGLNTService.ReportState(state, exit_code, wait_hint: DWORD);
begin
	Status.dwCurrentState := state;
	Status.dwWin32ExitCode := exit_code;
	Status.dwWaitHint := wait_hint;

	case state of
	  SERVICE_RUNNING:
		  Status.dwControlsAccepted := SERVICE_ACCEPT_STOP;
	  SERVICE_START_PENDING, SERVICE_STOP_PENDING:
      Status.dwControlsAccepted := 0;
    else
      Status.dwControlsAccepted := 0;
  end;

	if state in [SERVICE_RUNNING, SERVICE_STOPPED] then 
		Status.dwCheckPoint := 0
	else begin
    Inc(CheckPoint);
    Status.dwCheckPoint := CheckPoint;
  end;

	SetServiceStatus(Handle, Status);
end;

function TGLNTService.Run: Boolean;
var
  svc_table: array [0..1] of TServiceTableEntry;
begin
	svc_table[0].lpServiceName := PChar(Name);
  svc_table[0].lpServiceProc := @MainDirector.Call;
	svc_table[1].lpServiceName := nil;
  svc_table[1].lpServiceProc := nil;

	Result := StartServiceCtrlDispatcher(svc_table[0]);
end;

procedure TGLNTService.Start;
var
  scm, svc: SC_HANDLE;
  args: array of string;
  i: Integer;
begin
  scm := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if scm = 0 then Exit;
  svc := OpenService(scm, PChar(Name), SERVICE_ALL_ACCESS);
  if svc = 0 then
  begin
    CloseServiceHandle(scm);
    Exit;
  end;

  if ParamCount = 0 then StartService(svc, 0, nil)
  else begin
    SetLength(args, ParamCount + 1);
    for i := 0 to ParamCount do
      args[i] := ParamStr(i);
    StartService(svc, ParamCount + 1, @args);
  end;
  CloseServiceHandle(svc);
  CloseServiceHandle(scm);
end;

procedure TGLNTService.Stop;
begin
  fTerminated := True;
end;

end.
