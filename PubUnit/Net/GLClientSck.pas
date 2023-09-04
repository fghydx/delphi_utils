unit GLClientSck;

interface
uses Classes,System.net.socket,
{$IFDEF MSWINDOWS}
  windows,
  GLWinsockX;
{$Else}
  Posix.String_,Posix.sysTime,Posix.StrOpts,Posix.Fcntl,
  Posix.Unistd,
  Posix.NetinetIn, Posix.ArpaInet, Posix.SysSocket, Posix.SysSelect;
{$ENDIF}

type
  /// <remarks>
  /// 客户端Socket组件，用的普通阻塞
  /// </remarks>
  TGLClientSck = class
  private
    FSock:TSocketHandle;
    Faddr:MarshaledAString;
    FPort:Word;
    FOpened:boolean;
    FTimeOut:integer;
    procedure SetTimeOut(value:integer);
    /// <remarks>
    /// 异步支持connect超时的connect
    /// </remarks>
    function syncConnect(const name: PSOCKADDR; const namelen: Integer;const TimeTout:integer):Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(ConnectTimeOut:Integer=2000): Boolean;
    procedure Close;

    function SendBuff(var Buff;Size:NativeInt): NativeInt;
    procedure SendStream(AData:Tstream);
    function RecvBuff(var ABuff;Size:NativeInt): NativeInt;

    property addr:MarshaledAString  read  Faddr write Faddr;
    property Port:Word read Fport write Fport;
    property Opened:Boolean read FOpened write FOpened;
    property TimeOut:integer read FTimeOut Write SetTimeOut default 40000;
  end;
implementation

{ TGLClientSck }

{$IFDEF POSIX}
function closesocket(Socket: TSocketHandle): Integer; inline;
begin
  Result := Posix.Unistd.__close(Socket);
end;

function SetSocketBlock(Socket: TSocketHandle;Blocked:Boolean): Integer; inline;
var
  flags:integer;
begin
  if Blocked then
  begin
     fcntl(Socket, F_SETFL, 0);
  end else
  begin
    flags := fcntl(Socket, F_GETFL, 0);
    if flags = -1 then
      flags := 0;
    fcntl(Socket, F_SETFL, flags or O_NONBLOCK);
  end;
end;
{$ENDIF}

procedure TGLClientSck.Close;
{$IFDEF MSWINDOWS}
const
  Linger:TLinger=(l_onoff:1;l_linger:0);
var
  I:integer;
begin
  if FSock = INVALID_SOCKET then Exit;

//  shutdown(FSock,SD_BOTH);
  setsockopt(FSock,SOL_SOCKET,SO_LINGER,PAnsiChar(@Linger),SizeOf(TLinger));
  I := closesocket(FSock);
  FSock := INVALID_SOCKET;
{$ENDIF}
{$IFDEF POSIX}
begin
  Posix.Unistd.__close(FSock);
{$ENDIF}
end;

constructor TGLClientSck.Create;
begin
  FTimeOut:=40000;
  Opened:=False;
  inherited;
end;

destructor TGLClientSck.Destroy;
begin
  Close;
  inherited;
end;

function TGLClientSck.Open(ConnectTimeOut:Integer=2000): Boolean;
var
{$IFDEF MSWINDOWS}
  sockAddr:PSockAddr;
{$ELSE}
  sockAddr:Psockaddr_in;
{$ENDIF}
  i:integer;
begin
  FSock:=socket(AF_INET,SOCK_STREAM,0);
//  setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
//  setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));

  result:=False;
  New(sockAddr);
  try
  sockAddr.sin_family:=AF_INET;
  sockAddr.sin_addr.S_addr:=inet_addr(MarshaledAString(Faddr));
  sockAddr.sin_port:=htons(FPort);

  if syncConnect(PSockAddr(sockAddr),SizeOf(sockAddr^),ConnectTimeOut) then
  begin
    Result := true;
    {$IFDEF MSWINDOWS}
      setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
      setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));
    {$ELSE}
      setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,FTimeOut,SizeOf(FTimeOut));
      setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,FTimeOut,SizeOf(FTimeOut));
    {$ENDIF};
  end;
  finally
  Dispose(sockAddr);
  end;

  FOpened:=Result;
end;


function TGLClientSck.RecvBuff(var ABuff;Size:NativeInt): NativeInt;
var
  buff:array[0..8191] of Byte;
begin
  Result := 0;
  FillChar(buff,Length(buff),0);


  if Size<=Length(buff) then
    Result := recv(FSock,buff,Size,0)
  else
    Result := recv(FSock,buff,Length(buff),0);

  if Result>0 then
 {$IFDEF MSWINDOWS}
    CopyMemory(@Abuff,@Buff[0],Result)
 {$ELSE}
    MemCpy(Abuff,Buff[0],Result)
 {$ENDIF}
  else
    FOpened := False;
end;

function TGLClientSck.SendBuff(var Buff;Size:NativeInt): NativeInt;
begin
  Result:=send(FSock,Buff,Size,0);
  if Result <= 0  then
  begin
     FOpened := False;
  end;
end;

procedure TGLClientSck.SendStream(AData:Tstream);
var
  buff:array[0..8191] of Byte;
  Sended:NativeInt;
  remain:Int64;
begin
  AData.Position:=0;
  while AData.Position<AData.Size do
  begin
    remain:=AData.Size-AData.Position;
    if remain-Length(buff)>=0 then
    begin
      AData.Read(buff,Length(buff));
      Sended:=SendBuff(buff,Length(buff));
      if Sended<=0 then
      begin
        Break;
      end;
      AData.Position:=AData.Position-(Length(buff)-Sended);
    end else
    begin
      Adata.Read(buff,remain);
      Sended:=SendBuff(buff,remain);
      if Sended<=0 then
      begin
        Break;
      end;
      AData.Position:=AData.Position-(remain-Sended);
    end;
  end;
end;

procedure TGLClientSck.SetTimeOut(value: integer);
begin
  FTimeOut := value;
{$IFDEF MSWINDOWS}
  setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
  setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));
{$ELSE}
  setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,FTimeOut,SizeOf(FTimeOut));
  setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,FTimeOut,SizeOf(FTimeOut));
{$ENDIF}
end;

function TGLClientSck.syncConnect(const name: PSOCKADDR;
  const namelen, TimeTout: integer): Boolean;
var
  ul:Cardinal;
  tm:PTimeVal;
{$IFDEF MSWINDOWS}
  fdset:TFDSet;
  len:integer;
{$ELSE}
  fdset:fd_set;
  len:Cardinal;
{$ENDIF}
  err:Integer;
begin
  len := SizeOf(integer);
  Result := false;
  ul := 1;
{$IFDEF MSWINDOWS}
  ioctlsocket(FSock, FIONBIO, ul); //设置为非阻塞模式
{$ELSE}
  SetSocketBlock(FSock,false);
{$ENDIF}
{$IFDEF MSWINDOWS}
  if connect(FSock,name,namelen)=-1 then
{$ELSE}
  if connect(FSock,name^,namelen)=-1 then
{$ENDIF}
  begin
    New(tm);
    try
    tm.tv_sec  := TimeTout div 1000;;                       //秒
    tm.tv_usec := (TimeTout mod 1000) * 1000;;                       //0微秒
    FD_ZERO(fdset);
{$IFDEF MSWINDOWS}
    FD_SET(FSock, fdset);
{$ELSE}
    __FD_SET(FSock, fdset);
{$ENDIF}
    if select(FSock+1,nil,@fdset,nil,tm)>0 then
    begin
{$IFDEF MSWINDOWS}
      getsockopt(FSock, SOL_SOCKET, SO_ERROR,PAnsiChar(@err), len);
{$ELSE}
      getsockopt(FSock, SOL_SOCKET, SO_ERROR,err, len);
{$ENDIF}
      if (err = 0) then
          Result := true
      else
          Result := false;

    end else
      Result := False;
    finally
     Dispose(tm);
    end;

  end else
    result := true;

  ul := 0;
{$IFDEF MSWINDOWS}
  ioctlsocket(FSock, FIONBIO, ul); //设置为阻塞模式
{$ELSE}
  SetSocketBlock(FSock,true);
{$ENDIF}
  if not Result then
    close;
end;

end.
