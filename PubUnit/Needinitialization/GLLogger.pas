/// <remarks>
/// 有点内存泄漏，待测
/// </remarks>
unit GLLogger;

interface

uses GLQueue,Classes,SysUtils,GLStreamPatch{$ifdef MSWINDOWS},Winapi.Windows{$Endif};

const
  LogStr : array[0..3] of string = ('错误','警告','调试','信息');
type
  TLogType = (LTError,LTWarning,LTDebug,LTInfo);
  TWriteType = (WTFile,WTOutputDebugString,WTConsole,WTNone);      //写文件，OutputDebugString输出，控制台输出

  TCanLog = set of TLogType;
  TCanWriteType = set of TWriteType;

  PLogRec = ^TLogRec;
  TLogRec = record
    MSG:string;
    ThreadID:THandle;
    LogTime:TDateTime;
    LogType:TLogType;
  end;

  TLogWriteThread = class;

  /// <remarks>
  /// 写日志
  /// </remarks>
  TGLLog=class
  private
    LogWriteThread:TLogWriteThread;
    LogQueue:TGLQueue;
    AuToCreateLogFile:Boolean;
    LastWriteDay:Integer;
    FFileName:string;
    FileStream:TFileStream;
    FLogTypes: TcanLog;
    FWriteType: TWriteType;
    procedure CreateFile;
    procedure SetWriteType(const Value: TWriteType);
    procedure WriteToFile(str:string);
  public
    constructor Create(FileName: string = '');
    destructor Destroy; override;

    procedure ReWriteFile;

    procedure WriteLog(LogType: TLogType; Msg: string);
    property LogTypes: TcanLog read FLogTypes write FLogTypes;
    property WriteType: TWriteType read FWriteType write SetWriteType default
        WTOutputDebugString;
  end;

  TLogWriteThread = class(TThread)
  private
    Owner:TGLLog;
  protected
    procedure Execute;override;
  public
    constructor Create(AOwner: TGLLog);
  end;

var
  Logger:TGLLog;

implementation
  uses System.IOUtils;
{ TGLLog }

constructor TGLLog.Create(FileName: string = '');
begin
  WriteType := WTNone;
  AuToCreateLogFile := False;
  FFileName := FileName;
  LogQueue := TGLQueue.Create();
  LogWriteThread := TLogWriteThread.Create(Self);
  FLogTypes := [LTError,LTWarning,LTDebug,LTInfo];
end;

function GetExeFileName: string;
begin
  Result := ExtractFileName(ParamStr(0));
  Delete(Result, Length(Result) - 3, 4);
end;

function GetFileName: string;
var
  Path: string;
begin
{$ifdef MSWINDOWS}
  Path := ExtractFilePath(ParamStr(0)) + GetExeFileName + 'Log\';
{$ELSE}
  Path := TPath.GetTempPath;
{$ENDIF}
  if not DirectoryExists(Path) then
    ForceDirectories(Path);
  Result := Path + FormatDateTime('yyyymmdd', Now) + '.log';
end;

procedure TGLLog.CreateFile;
begin
  if Assigned(FileStream) then
    FreeAndNil(Filestream);
  if FFileName<>'' then
  begin
    if not FileExists(FFileName) then
    begin
      FileStream := TFileStream.Create(FFileName,fmCreate);
      FreeAndNil(Filestream);
    end;
    FileStream := TFileStream.Create(FFileName,fmOpenReadWrite or fmShareDenyNone);
    FileStream.Position := FileStream.Size;
    FileStream.Write(#$FF#$FE, 2);
  end else
  begin
    FFileName := GetFileName;
    AuToCreateLogFile := True;
    LastWriteDay := Trunc(Now);
    CreateFile;
  end;
end;

destructor TGLLog.Destroy;
var
  Log:PLogRec;
  Handle:Thandle;
begin
  LogWriteThread.Terminate;
  LogQueue.Blocked := False;
  LogQueue.SetEvent;
  LogWriteThread.WaitFor;
  LogWriteThread.Free;
  Log := LogQueue.Pop;
  while Log<>nil do
  begin
    Dispose(Log);
    Log := LogQueue.Pop;
  end;
  LogQueue.Free;
  if Assigned(FileStream) then
    FreeAndNil(FileStream);
  inherited;
end;

procedure TGLLog.ReWriteFile;
begin
  FileStream.Size := 0;
  FileStream.Position := 0;
end;

procedure TGLLog.SetWriteType(const Value: TWriteType);
begin
  if Value<>FWriteType then
  begin
    FWriteType := Value;
    if FWriteType=WTFile then
      CreateFile;
  end;
end;

procedure TGLLog.WriteLog(LogType: TLogType; Msg: string);
var
  Log:PLogRec;
begin
  if FWriteType = WTNone then Exit;

  if not (LogType in FLogTypes) then Exit;
  

  New(Log);
  Log.MSG := Msg;             //这个地方的String晓不得要不要特殊处理
//  SetLength(Log.MSG,Length(Msg));
//  CopyMemory(@(Log.MSG[1]),@Msg[1],Length(Msg));
  Log.LogType := LogType;
  Log.ThreadID := TThread.CurrentThread.ThreadID;
  Log.LogTime := now;
  LogQueue.Push(Log);
end;

procedure TGLLog.WriteToFile(str:string);
var
  CanWriteType:TCanWriteType;
begin
{$IFDEF MSWINDOWS}
  if FWriteType in CanWriteType then
    FWriteType := WTFile;
{$ENDIF}
  case FWriteType of
    WTFile:
      begin
        if AuToCreateLogFile and  (LastWriteDay<>Trunc(Now)) then
        begin
          FFileName := GetFileName;
          CreateFile;
        end;
        FileStream.WriteString(str,False);
      end;
{$IFDEF MSWINDOWS}
    WTOutputDebugString:
      begin
        OutputDebugString(PWideChar(str));
      end;
    WTConsole:
      begin
        try
          Writeln(str);
        except
          OutputDebugString(PWideChar(Exception(ExceptObject).Message));
        end;
      end;
{$ENDIF}
  end;

end;

{ TLogWriteThread }

constructor TLogWriteThread.Create(AOwner: TGLLog);
begin
  Owner := AOwner;
//  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TLogWriteThread.Execute;
const
  FMT = '%s【%s】: %s -(%s)';
var
  Log:PLogRec;
  str:string;
  a:string;
begin
  inherited;
  while not Terminated do
  begin
    try
      Log := Owner.LogQueue.Pop;
      if Log<>nil then
      begin
        str := format(FMT,[FormatDateTime('YY-MM-DD hh:nn:ss zzz',Log.LogTime),LogStr[Integer(Log.LogType)],Log.MSG,IntToStr(Log.ThreadID)])+#13#10;
        Owner.WriteToFile(str);
        Log.MSG := '';
        Dispose(Log);
      end;
    except
      Owner.WriteLog(LTError,'TLogWriteThread.Execute: '+Exception(ExceptObject).Message+'  '+a);
    end;
  end;
end;
{$ifdef MSWINDOWS}
initialization
  Logger := TGLLog.Create();
  logger.WriteType := WTFile;
  logger.LogTypes := [LTError,LTWarning,LTDebug,LTInfo];
finalization
  Logger.Free;
{$ENDIF}
end.


