unit GLClientSck;

interface
uses Windows,Classes,
{$IFDEF MSWINDOWS}
  GLWinsockX;
{$ENDIF}
{$IFDEF POSIX}
  Posix.NetinetIn, Posix.ArpaInet, Posix.SysSocket, Posix.SysSelect;
{$ENDIF}

type
  /// <remarks>
  /// 客户端Socket组件，用的普通阻塞
  /// </remarks>
  TGLClientSck = class
  private
    FSock:THandle;
    Faddr:AnsiString;
    FPort:Word;
    FOpened:boolean;
    FTimeOut:integer;
    procedure SetTimeOut(value:integer);
    /// <remarks>
    /// 异步支持connect超时的connect
    /// </remarks>
    function syncConnect(const s: TSocket; const name: PSOCKADDR; const namelen: Integer;const TimeTout:integer):Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(ConnectTimeOut:Integer=2000): Boolean;
    procedure Close;

    function SendBuff(var Buff;Size:integer): Integer;
    procedure SendStream(AData:Tstream);
    function RecvBuff(var ABuff;Size:integer): Integer;

    property addr:AnsiString  read  Faddr write Faddr;
    property Port:Word read Fport write Fport;
    property Opened:Boolean read FOpened write FOpened;
    property TimeOut:integer read FTimeOut Write SetTimeOut default 40000;
  end;
implementation

{ TGLClientSck }

procedure TGLClientSck.Close;
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
  sockAddr:TSOCKADDR;
  i:integer;
begin
  FSock:=socket(AF_INET,SOCK_STREAM,0);
//  setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
//  setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));

  result:=False;
  sockAddr.sin_family:=AF_INET;
  sockAddr.sin_addr.S_addr:=inet_addr(PAnsiChar(Faddr));
  sockAddr.sin_port:=htons(FPort);

  if syncConnect(FSock,@sockAddr,SizeOf(TSockAddr),ConnectTimeOut) then
  begin
    Result := true;
    setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
    setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));
  end;

//  i:=Connect(FSock,@sockAddr,SizeOf(TSockAddr));
//  if i>=0 then
//  begin
//    Result := true;
//  end;

  FOpened:=Result;
end;


function TGLClientSck.RecvBuff(var ABuff;Size:integer): Integer;
var
  buff:array[0..8191] of AnsiChar;
begin
  Result := 0;
  FillChar(buff,Length(buff),0);


  if Size<=Length(buff) then
    Result := recv(FSock,buff,Size,0)
  else
    Result := recv(FSock,buff,Length(buff),0);
  
  if Result>0 then
    CopyMemory(@Abuff,@Buff[0],Result)
  else
    FOpened := False;
end;

function TGLClientSck.SendBuff(var Buff;Size:integer): Integer;
begin
  Result:=send(FSock,Buff,Size,0);
  if Result <= 0  then
  begin
     FOpened := False;
  end;
end;

procedure TGLClientSck.SendStream(AData:Tstream);
var
  buff:array[0..8191] of AnsiChar;
  Sended:integer;
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
  setsockopt(FSock,SOL_SOCKET,SO_RCVTIMEO,@FTimeOut,SizeOf(FTimeOut));
  setsockopt(FSock,SOL_SOCKET,SO_SNDTIMEO,@FTimeOut,SizeOf(FTimeOut));
end;

function TGLClientSck.syncConnect(const s: TSocket; const name: PSOCKADDR;
  const namelen, TimeTout: integer): Boolean;
var
  ul:Cardinal;
  tm:TTimeVal;
  fdset:TFDSet;
  err,len:Integer;
begin
  len := SizeOf(integer);
  Result := false;
  ul := 1;
  ioctlsocket(s, FIONBIO, ul); //设置为非阻塞模式
  if connect(s,name,namelen)=-1 then
  begin
    tm.tv_sec  := TimeTout div 1000;;                       //秒
    tm.tv_usec := (TimeTout mod 1000) * 1000;;                       //0微秒
    FD_ZERO(fdset);
    FD_SET(s, fdset);
    if select(s+1,nil,@fdset,nil,@tm)>0 then
    begin
      getsockopt(s, SOL_SOCKET, SO_ERROR,PAnsiChar(@err), len);
      if (error = 0) then
          Result := true
      else
          Result := false;

    end else
      Result := False;
  end else
    result := true;

  ul := 0;
  ioctlsocket(s, FIONBIO, ul); //设置为阻塞模式
  if not Result then
    closesocket(s);
end;

end.
