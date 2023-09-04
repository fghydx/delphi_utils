unit GLClientSocketStream;

interface

uses GLClientSocket,Classes,SyncObjs,GLLogger;

Type
  /// <remarks>
  /// 支持客户端Tcp连接的流操作。
  /// </remarks>
  TGLClientSocketStream = class(TStream)
  private
    FSocket: TClientWinSocket;
    FClientSocket:TClientSocket;
    FReadTimeout: Longint;
    FEvent: TSimpleEvent;
    FUntilOverRead: Boolean;
    function GetActive: Boolean;
    function GetHost: string;
    function GetPort: Integer;
    procedure SetActive(const Value: Boolean);
    procedure SetHost(const Value: string);
    procedure SetPort(const Value: Integer);
    function WaitForData(Timeout: Longint): Boolean;
  public

    constructor Create(AReadTimeOut: Longint=45000;ConnectTimeOut:Integer = 5000);
    destructor Destroy; override;
    /// <summary>TGLClientSocketStream.Read
    /// </summary>
    /// <returns> 实际读取长度</returns>
    /// <param name="Buffer">缓冲区</param>
    /// <param name="Count">缓冲区长度，要接收多长</param>
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;

    function Open: Boolean;
    procedure Close;

    property Active: Boolean read GetActive write SetActive;
    property Host: string read GetHost write SetHost;
    property Port: Integer read GetPort write SetPort;
    property ReadTimeout: Longint read FReadTimeout write FReadTimeout;

    /// <remarks>
    /// 读取数据进是否必须读取到指定大小才返回
    /// </remarks>
    property UntilOverRead: Boolean read FUntilOverRead write FUntilOverRead
        default True;
  end;

implementation

uses Windows,GLWinSockX,RTLConsts,SysUtils,StrUtils;

{ TGLClientSocketStream }

procedure TGLClientSocketStream.Close;
begin
  FClientSocket.Close;
end;

constructor TGLClientSocketStream.Create(AReadTimeOut:
    Longint=45000;ConnectTimeOut:Integer = 5000);
begin
  FClientSocket := TClientSocket.Create(nil);
  FSocket := FClientSocket.Socket;
  FSocket.ClientType := ctBlocking;
  FSocket.ASyncStyles := [];
  FReadTimeout := AReadTimeOut;
  FClientSocket.timeout := FReadTimeout;
  FClientSocket.ConnectTimeOut := ConnectTimeOut;
  FEvent := TSimpleEvent.Create;
  inherited Create;
end;

destructor TGLClientSocketStream.Destroy;
begin
  FEvent.Free;
  FClientSocket.Free;
  inherited Destroy;
end;

function TGLClientSocketStream.GetActive: Boolean;
begin
  // TODO -cMM: TGLClientSocketStream.GetActive default body inserted
  Result := FClientSocket.Active;
end;

function TGLClientSocketStream.GetHost: string;
begin
  // TODO -cMM: TGLClientSocketStream.GetHost default body inserted
  Result := FClientSocket.Host;
end;

function TGLClientSocketStream.GetPort: Integer;
begin
  // TODO -cMM: TGLClientSocketStream.GetPort default body inserted
  Result := FClientSocket.Port;
end;

function TGLClientSocketStream.Open: Boolean;
begin
  Result := False;
  FClientSocket.Open;
  Result := FClientSocket.Active;
end;

function TGLClientSocketStream.WaitForData(Timeout: Longint): Boolean;
var
  FDSet: TFDSet;
  TimeVal: TTimeVal;
begin
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := (Timeout mod 1000) * 1000;
  FD_ZERO(FDSet);
  FD_SET(FSocket.SocketHandle, FDSet);
  Result := select(0, @FDSet, nil, nil, @TimeVal) > 0;
end;

function TGLClientSocketStream.Read(var Buffer; Count: Longint): Longint;
var
  Overlapped: TOverlapped;
  ErrorCode: Integer;
  P:Pointer;
  temCount:LongInt;
  WaitedData,OverlappedResult:Boolean;
begin
  Result := 0;
  P:=@buffer;
  temCount := Count;
  FSocket.Lock;
  try
    WaitedData := WaitForData(FReadTimeout);
    if WaitedData then
    begin
//    Result := recv(FSocket.SocketHandle,Buffer, Count,0);
//    Exit;

      FillChar(OVerlapped, SizeOf(Overlapped), 0);
      Overlapped.hEvent := FEvent.Handle;

      if not ReadFile(FSocket.SocketHandle, P^, temCount, DWORD(Result),
        @Overlapped) and (GetLastError <> ERROR_IO_PENDING) then
      begin
        ErrorCode := GetLastError;
        raise ESocketError.CreateResFmt(@sSocketIOError, [sSocketRead, ErrorCode,
          SysErrorMessage(ErrorCode)]);
      end;

      OverlappedResult := GetOverlappedResult(FSocket.SocketHandle, Overlapped, DWORD(Result), True);
      FEvent.ResetEvent;
      if not OverlappedResult then
      begin
        ErrorCode := GetLastError;
        raise ESocketError.Create('接收数据时出错！ ErrorCode:'+inttostr(ErrorCode)+'IP:'+rightstr(Host,6)+' Port:'+inttostr(Port));
        Exit;
      end;
      if Result<=0 then
      begin
        ErrorCode := GetLastError;
        raise ESocketError.Create('对端主动关闭了此连接！ErrorCode:'+inttostr(ErrorCode)+'IP:'+rightstr(Host,6)+' Port:'+inttostr(Port));
        Exit;
      end;
      if UntilOverRead and (temCount>Result) then
      begin
        P:=Pointer(Integer(P)+result);
        temCount := temCount-Result;
        Result := Result + Read(P^,temCount);
      end else
      begin
        Exit;
      end;
    end else
    begin
      ErrorCode := GetLastError;
      raise ESocketError.Create('读取数据超时！ErrorCode:'+inttostr(ErrorCode)+'IP:'+rightstr(Host,6)+' Port:'+inttostr(Port));
    end;
  finally
    FSocket.Unlock;
  end;
end;

function TGLClientSocketStream.Write(const Buffer; Count: Longint): Longint;
var
  Overlapped: TOverlapped;
  ErrorCode: Integer;
begin
  FSocket.Lock;
  try
    FillChar(OVerlapped, SizeOf(Overlapped), 0);
    Overlapped.hEvent := FEvent.Handle;
    if not WriteFile(FSocket.SocketHandle, Buffer, Count, DWORD(Result),
      @Overlapped) and (GetLastError <> ERROR_IO_PENDING) then
    begin
      ErrorCode := GetLastError;
      raise ESocketError.CreateResFmt(@sSocketIOError, [sSocketWrite, ErrorCode,
        SysErrorMessage(ErrorCode)]);
    end;
    if FEvent.WaitFor(FReadTimeout) <> wrSignaled then
      Result := 0
    else GetOverlappedResult(FSocket.SocketHandle, Overlapped, DWORD(Result), False);
  finally
    FSocket.Unlock;
  end;
end;

function TGLClientSocketStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := 0;
end;

procedure TGLClientSocketStream.SetActive(const Value: Boolean);
begin
  FClientSocket.Active := Value;
end;

procedure TGLClientSocketStream.SetHost(const Value: string);
begin
  FClientSocket.Host := Value;
end;

procedure TGLClientSocketStream.SetPort(const Value: Integer);
begin
  FClientSocket.Port := Value;
end;


end.

