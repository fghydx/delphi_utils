unit GLUDPServer;

interface

uses
  Windows, Messages, Classes, SysUtils, GLWinSockX, contnrs;

type

//==============================================================================
// UDP 通讯类        服务端监听
//==============================================================================

{ TGLUDPSvr }

  TOnReceive = procedure(const Buffer; Len: Integer;
    FromIP: string; Port: Integer) of object;
  {* 接收到数据事件
   |<PRE>
     Sender     - TGLUDPSvr 对象
     Buffer     - 数据缓冲区
     Len        - 数据缓冲区长度
     FromIP     - 数据来源 IP
     Port       - 数据来源端口号
   |</PRE>}

  TGLUDPSvr = class
  {* 使用非阻塞方式进行 UDP 通讯的类。支持广播、数据队列等。}
  private
    FRemoteHost: string;
    FExitMsgProcess:boolean;
    FRemotePort: Integer;
    FLocalPort: Integer;
    FSocketWindow: HWND;
    FOnDataReceived: TOnReceive;
    FListening: Boolean;
    Wait_Flag: Boolean;
    RemoteHostS: PHostEnt;
    Succeed: Boolean;
    Procing: Boolean;
    MyWSAData: TWSAData;
    EventHandle: THandle;
    ThisSocket: TSocket;
    Queue: TQueue;
    FLastError: Integer;
    FRecvBufSize: Cardinal;
    FRecvBuf: Pointer;
    function ResolveRemoteHost(ARemoteHost: string; out RemoateAddr: TSockAddr):
        Boolean;
    procedure SetLocalPort(NewLocalPort: Integer);
    procedure ProcessIncomingdata;
    procedure ProcessQueue;
    procedure FreeQueueItem(P: Pointer);
    function GetQueueCount: Integer;
    procedure SetupLastError;
    function GetLocalHost: string;
    procedure UpdateBinding;
    procedure SetRecvBufSize(const Value: Cardinal);
    procedure ProcessMessage;
  protected
    procedure Wait;
  public
    constructor Create;
    destructor Destroy; override;

    function SendStream(DataStream: TStream; BroadCast: Boolean = False): Boolean;
    {* 发送一个数据流。如果 BroadCase 为真，执行 UDP 广播，否则发送数据到
       RomoteHost 的机器上的 RemotePort 端口}
    function SendBuffer(const Buff; Length: Integer; BroadCast: Boolean = False):
        Boolean;
    {* 发送一个数据块。如果 BroadCase 为真，执行 UDP 广播，否则发送数据到
       RomoteHost 的机器上的 RemotePort 端口}
    procedure ClearQueue;
    {* 清空数据队列。如果用户来不及处理接收到的数据，组件会把新数据包放到数据
       队列中，调用该方法可清空数据队列}

    procedure Start;
    procedure Stop;

    property LastError: Integer read FLastError;
    {* 最后一次错误的错误号，只读属性}
    property Listening: Boolean read FListening;
    {* 表示当前是否正在监听本地端口，只读属性}
    property QueueCount: Integer read GetQueueCount;
    {* 当前数据队列的长度，只读属性}
  published
    property RemoteHost: string read FRemoteHost write FRemoteHost;
    {* 要发送 UDP 数据的目标主机地址}
    property RemotePort: Integer read FRemotePort write FRemotePort;
    {* 要发送 UDP 数据的目标主机端口号}
    property LocalHost: string read GetLocalHost;
    {* 返回本机 IP 地址，只读属性}
    property LocalPort: Integer read FLocalPort write SetLocalPort;
    {* 本地监听的端口号}
    property RecvBufSize: Cardinal read FRecvBufSize write SetRecvBufSize default 1024;
    {* 接收的数据缓冲区大小，默认 2048}
    property OnDataReceived: TOnReceive read FOnDataReceived write
      FOnDataReceived;
    {* 接收到 UDP 数据包事件}
  end;


  TGLUDPServer = class(TThread)
  private
    FStoped:boolean;
    FListenPort: Integer;
    FOnRecvData: TOnReceive;
    FUDP: TGLUDPSvr;
    procedure SetListenPort(const Value: Integer);
    procedure SetOnRecvData(const Value: TOnReceive);
  public
    constructor Create;
    destructor Free;
    procedure Start;
    procedure Stop;

    procedure Execute;override;
    function SendBuffer(const Buff; const Length: Integer; ToAddr: string; ToPort:
        Integer): Boolean;
    function SendString(const str:string;Toaddr:string;ToPort:Integer):Boolean;
    property ListenPort: Integer read FListenPort write SetListenPort;
    property OnRecvData: TOnReceive read FOnRecvData write SetOnRecvData;
    property UDP: TGLUDPSvr read FUDP write FUDP;
  end;

// 取广播地址
procedure GetBroadCastAddress(sInt: TStrings);

// 取本机IP地址
procedure GetLocalIPAddress(sInt: TStrings);

implementation

{$R-}

//==============================================================================
// 辅助过程
//==============================================================================

//// 从Winsock 2.0导入函数WSAIOCtl
//function WSAIoctl(s: TSocket; cmd: DWORD; lpInBuffer: PCHAR; dwInBufferLen:
//  DWORD;
//  lpOutBuffer: PCHAR; dwOutBufferLen: DWORD;
//  lpdwOutBytesReturned: LPDWORD;
//  lpOverLapped: POINTER;
//  lpOverLappedRoutine: POINTER): Integer; stdcall; external 'WS2_32.DLL';

const
  SIO_GET_INTERFACE_LIST = $4004747F;
  IFF_UP = $00000001;
  IFF_BROADCAST = $00000002;
  IFF_LOOPBACK = $00000004;
  IFF_POINTTOPOINT = $00000008;
  IFF_MULTICAST = $00000010;

type
  sockaddr_gen = packed record
    AddressIn: sockaddr_in;
    filler: packed array[0..7] of AnsiChar;
  end;

  INTERFACE_INFO = packed record
    iiFlags: u_long;                    // Interface flags
    iiAddress: sockaddr_gen;            // Interface address
    iiBroadcastAddress: sockaddr_gen;   // Broadcast address
    iiNetmask: sockaddr_gen;            // Network mask
  end;

// 取广播地址
procedure DoGetIPAddress(sInt: TStrings; IsBroadCast: Boolean);
var
  s: TSocket;
  wsaD: WSADATA;
  NumInterfaces: Integer;
  BytesReturned, SetFlags: u_long;
  pAddr, pMask, pCast: TInAddr;
  pAddrStr: string;
  PtrA: pointer;
  Buffer: array[0..20] of INTERFACE_INFO;
  i: Integer;
begin
//GL2015-12-03  --
//  WSAStartup($0101, wsaD);              // Start WinSock
  s := Socket(AF_INET, SOCK_STREAM, 0); // Open a socket
  if (s = INVALID_SOCKET) then
    exit;

  try                                   // Call WSAIoCtl
    PtrA := @bytesReturned;
    if (WSAIoCtl(s, SIO_GET_INTERFACE_LIST, nil, 0, @Buffer, 1024, PtrA, nil,
      nil) <> SOCKET_ERROR) then
    begin                               // If ok, find out how
      // many interfaces exist
      NumInterfaces := BytesReturned div SizeOf(INTERFACE_INFO);
      sInt.Clear;
      for i := 0 to NumInterfaces - 1 do // For every interface
      begin
        SetFlags := Buffer[i].iiFlags;
        if (SetFlags and IFF_BROADCAST = IFF_BROADCAST) and not
          (SetFlags and IFF_LOOPBACK = IFF_LOOPBACK) then
        begin
          pAddr := Buffer[i].iiAddress.AddressIn.sin_addr;
          pMask := Buffer[i].iiNetmask.AddressIn.sin_addr;
          if IsBroadCast then
          begin
            pCast.S_addr := pAddr.S_addr or not pMask.S_addr;
            pAddrStr := string(inet_ntoa(pCast));
          end
          else
          begin
            pAddrStr := string(inet_ntoa(pAddr));
          end;
            
          if sInt.IndexOf(pAddrStr) < 0 then
            sInt.Add(pAddrStr);
        end;
      end;
    end;
  except
    ;
  end;
  CloseSocket(s);
//GL2015-12-03  --
//  WSACleanUp;
end;

// 取本机IP地址
procedure GetLocalIPAddress(sInt: TStrings);
begin
  DoGetIPAddress(sInt, False);
end;  

// 取广播地址
procedure GetBroadCastAddress(sInt: TStrings);
begin
  DoGetIPAddress(sInt, True);
end;

//==============================================================================
// UDP 通讯类
//==============================================================================

{ TGLUDPSvr }

const
  WM_ASYNCHRONOUSPROCESS = WM_USER + 101;
  WM_ExitMsgProcess = WM_USER + 102;
  Const_cmd_true = 'TRUE';

type
  PRecvDataRec = ^TRecvDataRec;
  TRecvDataRec = record
    FromIP: string[128];
    FromPort: u_short;
    Buff: Pointer;
    BuffSize: Integer;
  end;

constructor TGLUDPSvr.Create;
begin
  inherited Create;
  Queue := TQueue.Create;
  FListening := False;
  Procing := False;
  FRecvBufSize := 1024;
  FExitMsgProcess := true;
  GetMem(RemoteHostS, MAXGETHOSTSTRUCT);
  FSocketWindow := INVALID_HANDLE_VALUE;
  EventHandle := CreateEvent(nil, True, False, '');
  if WSAStartup($0101, MyWSADATA) = 0 then
  begin
    ThisSocket := Socket(AF_INET, SOCK_DGRAM, 0);
    if ThisSocket = TSocket(INVALID_SOCKET) then
    begin
      SetupLastError;
      WSACleanup;
      Exit;
    end;
    setsockopt(ThisSocket, SOL_SOCKET, SO_DONTLINGER, Const_cmd_true, 4);
    setsockopt(ThisSocket, SOL_SOCKET, SO_BROADCAST, Const_cmd_true, 4);
    FListening := True;
  end;
end;

destructor TGLUDPSvr.Destroy;
begin
  if FRecvBuf <> nil then
  begin
    FreeMem(FRecvBuf);
    FRecvBuf := nil;
  end;

  ClearQueue;
  Queue.Free;
  FreeMem(RemoteHostS, MAXGETHOSTSTRUCT);
  if FSocketWindow<>INVALID_HANDLE_VALUE then
     DeallocateHWND(FSocketWindow);

  CloseHandle(EventHandle);
  if ThisSocket <> 0 then
    closesocket(ThisSocket);
  if FListening then
    WSACleanup;
  inherited Destroy;
end;

procedure TGLUDPSvr.UpdateBinding;
var
  Data: DWORD;
  LocalAddr: TSockAddr;
begin
  FListening := False;
  LocalAddr.sin_addr.S_addr := Inet_Addr('0.0.0.0');
  LocalAddr.sin_family := AF_INET;
  LocalAddr.sin_port := htons(FLocalPort);
  Wait_Flag := False;
  if Bind(ThisSocket, @LocalAddr, SizeOf(LocalAddr)) =
    SOCKET_ERROR then
  begin
    SetupLastError;
    WSACleanup;
    Exit;
  end;
  // Allow to send to 255.255.255.255
  Data := 1;
  setsockopt(ThisSocket, SOL_SOCKET, SO_BROADCAST,
    PAnsiChar(@Data), SizeOf(Data));
  Data := 256 * 1024;
  setsockopt(ThisSocket, SOL_SOCKET, SO_SNDBUF,
    PAnsiChar(@Data), SizeOf(Data));
  setsockopt(ThisSocket, SOL_SOCKET, SO_RCVBUF,
    PAnsiChar(@Data), SizeOf(Data));
  if FSocketWindow=INVALID_HANDLE_VALUE then
    FSocketWindow := AllocateHWND(nil);
  WSAAsyncSelect(ThisSocket, FSocketWindow, WM_ASYNCHRONOUSPROCESS, FD_READ);
  FListening := True;
  ProcessMessage;
end;

procedure TGLUDPSvr.SetLocalPort(NewLocalPort: Integer);
begin
  if NewLocalPort <> FLocalPort then
  begin
    FListening := False;
    if ThisSocket <> 0 then
      closesocket(ThisSocket);
    WSACleanup;
    if WSAStartup($0101, MyWSADATA) = 0 then
    begin
      ThisSocket := Socket(AF_INET, SOCK_DGRAM, 0);
      if ThisSocket = TSocket(INVALID_SOCKET) then
      begin
        WSACleanup;
        SetupLastError;
        Exit;
      end;
    end;
    FLocalPort := NewLocalPort;
  end;
end;

function TGLUDPSvr.ResolveRemoteHost(ARemoteHost: string; out RemoateAddr: TSockAddr):
    Boolean;
var
  Buf: array[0..127] of AnsiChar;
begin
  Result := False;
  if not FListening then Exit;
  try
    RemoateAddr.sin_addr.S_addr := Inet_Addr(PAnsiChar(StrPCopy(Buf, AnsiString(ARemoteHost))));
    if RemoateAddr.sin_addr.S_addr = SOCKET_ERROR then
    begin
      Wait_Flag := False;
      WSAAsyncGetHostByName(FSocketWindow, WM_ASYNCHRONOUSPROCESS, Buf,
        PAnsiChar(RemoteHostS), MAXGETHOSTSTRUCT);
      repeat
        Wait;
      until Wait_Flag;
      if Succeed then
      begin
        with RemoateAddr.sin_addr.S_un_b do
        begin
          s_b1 := Ord(remotehostS.h_address_list^[0]);
          s_b2 := Ord(remotehostS.h_address_list^[1]);
          s_b3 := Ord(remotehostS.h_address_list^[2]);
          s_b4 := Ord(remotehostS.h_address_list^[3]);
        end;
      end;
    end;
  except
    ;
  end;
  if RemoateAddr.sin_addr.S_addr <> 0 then
    Result := True;
  if not Result then
    SetupLastError;
end;

function TGLUDPSvr.SendStream(DataStream: TStream; BroadCast: Boolean): Boolean;
var
  Buff: Pointer;
begin
  GetMem(Buff, DataStream.Size);
  try
    DataStream.Position := 0;
    DataStream.Read(Buff^, DataStream.Size);
    Result := SendBuffer(Buff, DataStream.Size, BroadCast);
  finally
    FreeMem(Buff);
  end;
end;

function TGLUDPSvr.SendBuffer(const Buff; Length: Integer; BroadCast: Boolean =
    False): Boolean;
var
  Hosts: TStrings;
  i: Integer;
  
  function DoSendBuffer(const Buff; Length: Integer; Host: string): Boolean;
  var
    i: Integer;
    RemoateAddr:TSockAddr;
  begin
    Result := False;
    try
      if not ResolveRemoteHost(Host,RemoateAddr) then
        Exit;
      RemoateAddr.sin_family := AF_INET;
      RemoateAddr.sin_port := htons(FRemotePort);
      i := SizeOf(RemoateAddr);
      if sendto(ThisSocket, Buff, Length, 0, @RemoateAddr, i)
        <> SOCKET_ERROR then
        Result := True
      else
        SetupLastError;
    except
      SetupLastError;
    end;
  end;
begin
  if BroadCast then
  begin
    Result := False;
    Hosts := TStringList.Create;
    try
      GetBroadCastAddress(Hosts);
      for i := 0 to Hosts.Count - 1 do
        if DoSendBuffer(Buff, Length, Hosts[i]) then
          Result := True;
    finally
      Hosts.Free;
    end;
  end
  else
    Result := DoSendBuffer(Buff, Length, FRemoteHost);
end;

function TGLUDPSvr.GetQueueCount: Integer;
begin
  Result := Queue.Count;
end;

procedure TGLUDPSvr.FreeQueueItem(P: Pointer);
var
  Rec: PRecvDataRec;
begin
  Rec := PRecvDataRec(P);
  Rec.FromIP := '';
  FreeMem(Rec.Buff);
  FreeMem(Rec);
end;

procedure TGLUDPSvr.ClearQueue;
var
  Rec: PRecvDataRec;
begin
  while Queue.Count > 0 do
  begin
    Rec := Queue.Pop;
    FreeQueueItem(Rec);
  end;
end;

procedure TGLUDPSvr.ProcessQueue;
var
  Rec: PRecvDataRec;
begin
  if Procing then Exit;
  Procing := True;
  try
    while Queue.Count > 0 do
    begin
      Rec := Queue.Pop;
      if Assigned(FOnDataReceived) then
        FOnDataReceived((Rec.Buff)^, Rec.BuffSize, string(Rec.FromIP), Rec.FromPort);
      FreeQueueItem(Rec);
    end;
  finally
    Procing := False;
  end;
end;

procedure TGLUDPSvr.ProcessIncomingdata;
var
  from: TSockAddr;
  i: Integer;
  Rec: PRecvDataRec;
  IBuffSize: Integer;
begin
  i := SizeOf(from);
  if FRecvBuf = nil then
    GetMem(FRecvBuf, FRecvBufSize);

  IBuffSize := recvfrom(ThisSocket, FRecvBuf^, FRecvBufSize, 0, @from, @i);
  if (IBuffSize > 0) and Assigned(FOnDataReceived) then
  begin
    GetMem(Rec, SizeOf(TRecvDataRec));
    ZeroMemory(Rec, SizeOf(TRecvDataRec));
    Rec.FromIP := ShortString(Format('%d.%d.%d.%d', [Ord(from.sin_addr.S_un_b.S_b1),
      Ord(from.sin_addr.S_un_b.S_b2), Ord(from.sin_addr.S_un_b.S_b3),
        Ord(from.sin_addr.S_un_b.S_b4)]));
    Rec.FromPort := ntohs(from.sin_port);
    GetMem(Rec.Buff, IBuffSize);
    Rec.BuffSize := IBuffSize;
    CopyMemory(Rec.Buff, FRecvBuf, IBuffSize);
    Queue.Push(Rec);
  end;
end;

type
  TInt = record
    LparamLo:word;
    LparamHi:word;
  end;
  TInt64 = record
    LparamLo:TInt;
    LparamHi:TInt;
  end;
procedure TGLUDPSvr.ProcessMessage;
var
  msg:TMsg;
  Loparam:TInt64;
begin
  FExitMsgProcess := False;
  while GetMessage(Msg, 0, 0,0) do
  begin
    if Msg.message = WM_ASYNCHRONOUSPROCESS then
    begin
      Loparam := TInt64(msg.lParam);
      if Loparam.LparamLo.LparamLo = FD_READ then
      begin
        ProcessIncomingdata;
        if not Procing then
          ProcessQueue;
      end
      else
      begin
        Wait_Flag := True;
        if Loparam.LparamHi.LparamHi > 0 then
          Succeed := False
        else
          Succeed := True;
      end;
      SetEvent(EventHandle);
    end else if msg.message = WM_ExitMsgProcess then
    begin
      Loparam := TInt64(msg.lParam);
      Break;
    end else
    begin
      TranslateMessage(Msg);
      DispatchMessageW(Msg);
    end;
  end;
  FExitMsgProcess := true;
end;

procedure WaitforSync(Handle: THandle);
var
  Msg:TMsg;
  Unicode : Boolean;
  msgExists : Boolean;
begin
  repeat
    if MsgWaitForMultipleObjects(1, Handle, False, INFINITE, QS_ALLINPUT)
      = WAIT_OBJECT_0 + 1 then
    begin
      if PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE) then
      begin
        Unicode := (Msg.hwnd <> 0) and IsWindowUnicode(Msg.hwnd);
        if Unicode then
          MsgExists := PeekMessageW(Msg, 0, 0, 0, PM_REMOVE)
        else
          MsgExists := PeekMessage(Msg, 0, 0, 0, PM_REMOVE);
        if not MsgExists then Exit;
        if Msg.Message <> WM_QUIT then
        begin
          TranslateMessage(Msg);
          if Unicode then
            DispatchMessageW(Msg)
          else
            DispatchMessage(Msg);
        end;
      end;
    end
    else
      Break;
  until False;
end;

procedure TGLUDPSvr.Wait;
begin
  WaitforSync(EventHandle);
  ResetEvent(EventHandle);
end;

procedure TGLUDPSvr.SetupLastError;
begin
  FLastError := WSAGetLastError;
end;

function TGLUDPSvr.GetLocalHost: string;
var
  wVersionRequested: WORD;
  wsaData: TWSAData;
  p: PHostEnt;
  s: array[0..256] of AnsiChar;
begin
  wVersionRequested := MAKEWORD(1, 1);
  WSAStartup(wVersionRequested, wsaData);
  try
    GetHostName(@s, 256);
    p := GetHostByName(@s);
    Result := string(inet_ntoa(PInAddr(p^.h_address_list^)^));
  finally
    WSACleanup;
  end;
end;

procedure TGLUDPSvr.Start;
begin
  if FLocalPort>0  then
    UpdateBinding
  // TODO -cMM: TGLUDPSvr.Start default body inserted
end;

procedure TGLUDPSvr.SetRecvBufSize(const Value: Cardinal);
begin
  if FRecvBufSize <> Value then
  begin
    FRecvBufSize := Value;
    if FRecvBuf <> nil then
    begin
      // 释放，等待下次需要时重新分配
      FreeMem(FRecvBuf);
      FRecvBuf := nil;
    end;  
  end;
end;

procedure TGLUDPSvr.Stop;                 //同一线程中才有作用
begin
  SendMessage(FSocketWindow,WM_ExitMsgProcess,0,0);
end;

constructor TGLUDPServer.Create;
begin
  FreeOnTerminate := True;
  inherited Create(True);
  FUDP := TGLUDPSvr.Create;
end;

destructor TGLUDPServer.Free;
begin
  if Assigned(FUDP) then
  begin
    FUDP.Stop;
    FUDP.Free;
  end;
  Terminate;
end;

procedure TGLUDPServer.Execute;
begin
  inherited;
  FUDP.Start;
end;

function TGLUDPServer.SendBuffer(const Buff; const Length: Integer; ToAddr:
    string; ToPort: Integer): Boolean;
var
  TemUDP:TGLUDPSvr;
begin
  try
    TemUDP := TGLUDPSvr.Create;
    TemUDP.RemoteHost := ToAddr;
    TemUDP.RemotePort := ToPort;
    Result := TemUDP.SendBuffer(Buff,Length);
  finally
    TemUDP.Free;
  end;
end;

function TGLUDPServer.SendString(const str: string; Toaddr: string;
  ToPort: Integer): Boolean;
begin
  SendBuffer(str[1],Length(str),Toaddr,ToPort);
end;

procedure TGLUDPServer.SetListenPort(const Value: Integer);
begin
  FListenPort := Value;
  FUDP.LocalPort := FListenPort;
end;

procedure TGLUDPServer.SetOnRecvData(const Value: TOnReceive);
begin
  FOnRecvData := Value;
  FUDP.OnDataReceived := FOnRecvData;
end;

procedure TGLUDPServer.Start;
begin
  Resume;
end;

procedure TGLUDPServer.Stop;
begin
  if Assigned(FUDP) then
  begin
    FUDP.Stop;
    FreeAndNil(FUDP);
  end;
  Suspend;
end;

end.
