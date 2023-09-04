unit GLUDPClient;

interface

uses
  Windows, Messages, Classes, SysUtils, GLWinSockX, contnrs;

type

//==============================================================================
// UDP 通讯类        客户端
//==============================================================================

{ TGLUDPClient }

  TGLUDPClient = class
  private
    FListening:Boolean;
    FRemoteHost: string;
    FRemotePort: Integer;
    FSocketWindow: HWND;
    Wait_Flag: Boolean;
    RemoteHostS: PHostEnt;
    Succeed: Boolean;
    Procing: Boolean;
    MyWSAData: TWSAData;
    EventHandle: THandle;
    ThisSocket: TSocket;
    FLastError: Integer;
    FRecvBufSize: Cardinal;
    FRecvBuf: Pointer;
    FRecvTimeOut: Integer;
    function ResolveRemoteHost(ARemoteHost: string; out RemoateAddr: TSockAddr):
        Boolean;
    procedure FreeQueueItem(P: Pointer);
    procedure SetupLastError;
    procedure SetRecvBufSize(const Value: Cardinal);
    procedure SetRecvTimeOut(const Value: Integer);
  protected
    procedure Wait;
  public
    constructor Create;
    destructor Destroy; override;

    ///<param name="DataStream"> 要发送的流数据 </param>
    ///<param name="BroadCast"> 执行UDP广播,True执行,False发送到 RomoteHost 的机器上的
    ///RemotePort 端口</param>
    ///<remarks>
    ///发送一个数据流。
    ///</remarks>
    function SendStream(DataStream: TStream; BroadCast: Boolean = False): Boolean;

    function SendBuffer(const Buff; Length: Integer; BroadCast: Boolean = False):
        Boolean;
    function SendString(str:string;BroadCast:Boolean = False):Boolean;


    function RecvBuffer(out Buff: Pointer; var DataLen: integer): boolean;
    function RecvString: string;

    property LastError: Integer read FLastError;
    {* 当前数据队列的长度，只读属性}
  published
    property RemoteHost: string read FRemoteHost write FRemoteHost;
    {* 要发送 UDP 数据的目标主机地址}
    property RemotePort: Integer read FRemotePort write FRemotePort;
    {* 本地监听的端口号}
    property RecvBufSize: Cardinal read FRecvBufSize write SetRecvBufSize default 1024;
    {* 接收的数据缓冲区大小，默认 1024}
    property RecvTimeOut: Integer read FRecvTimeOut write SetRecvTimeOut;
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

{ TGLUDPClient }

const
  WM_ASYNCHRONOUSPROCESS = WM_USER + 101;
  Const_cmd_true = 'TRUE';

type
  PRecvDataRec = ^TRecvDataRec;
  TRecvDataRec = record
    FromIP: string[128];
    FromPort: u_short;
    Buff: Pointer;
    BuffSize: Integer;
  end;

constructor TGLUDPClient.Create;
begin
  inherited Create;
  Procing := False;
  FRecvBufSize := 1024;
  FListening := False;
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
    FListening := true;
  end;
end;

destructor TGLUDPClient.Destroy;
begin
  if FRecvBuf <> nil then
  begin
    FreeMem(FRecvBuf);
    FRecvBuf := nil;
  end;

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

function TGLUDPClient.RecvBuffer(out Buff: Pointer; var DataLen: integer):
    boolean;
var
  Sockaddr:TSockAddr;
  I:integer;
  RecvLen,Recved:integer;
begin
  if FRecvBuf = nil then
    GetMem(FRecvBuf, FRecvBufSize);

  Result := False;
  i:=SizeOf(TSockAddr);
  DataLen := recvfrom(ThisSocket,FRecvBuf^,FRecvBufSize,0,@Sockaddr,@i);
  if DataLen>0 then
  begin
    Buff := GetMemory(DataLen);
    CopyMemory(Buff,FRecvBuf,DataLen);
    Result := true;
  end;
//  Recved := RecvLen;
//  if Recved<0 then
//  begin
//    Result := False;
//  end else
//  begin
//    if Recved>=DataLen then
//    begin
//      CopyMemory(@Buff,@Bufftem[0],DataLen);
//      Result := true;
//    end else
//    begin
//      CopyMemory(@Buff,@Bufftem[0],Recved);
//      while Recved<DataLen do
//      begin
//        RecvLen := recvfrom(ThisSocket,BuffTem,SizeOf(BuffTem),0,@Sockaddr,@i);
//        if RecvLen<0 then
//        begin
//          Result := False;
//          Break;
//        end;
//        CopyMemory(Pointer(Integer(@Buff)+recved),@Bufftem[0],RecvLen);
//        Recved := Recved+RecvLen;
//      end;
//    end;
//  end;
end;

function TGLUDPClient.RecvString: string;
var
  len:integer;
  P:Pointer;
begin
  Result := '';
  P:=nil;
  if RecvBuffer(P,Len) then
  begin
    SetLength(Result,len);
    CopyMemory(@Result[1],P,len);
    FreeMemory(P);
  end;
end;

function TGLUDPClient.ResolveRemoteHost(ARemoteHost: string; out RemoateAddr: TSockAddr):
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

function TGLUDPClient.SendStream(DataStream: TStream; BroadCast: Boolean =
    False): Boolean;
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

function TGLUDPClient.SendString(str: string; BroadCast: Boolean): Boolean;
begin
  Result := SendBuffer(str[1],Length(str),BroadCast);
end;

function TGLUDPClient.SendBuffer(const Buff; Length: Integer; BroadCast:
    Boolean = False): Boolean;
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

procedure TGLUDPClient.FreeQueueItem(P: Pointer);
var
  Rec: PRecvDataRec;
begin
  Rec := PRecvDataRec(P);
  Rec.FromIP := '';
  FreeMem(Rec.Buff);
  FreeMem(Rec);
end;

type
  Tlongint = record
    LparamLo:Word;
    LparamHi:Word;
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

procedure TGLUDPClient.Wait;
begin
  WaitforSync(EventHandle);
  ResetEvent(EventHandle);
end;

procedure TGLUDPClient.SetupLastError;
begin
  FLastError := WSAGetLastError;
end;

procedure TGLUDPClient.SetRecvBufSize(const Value: Cardinal);
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

procedure TGLUDPClient.SetRecvTimeOut(const Value: Integer);
var
  ToRec:timeval;
begin
  FRecvTimeOut := Value;
  ToRec.tv_sec := Value;
  ToRec.tv_usec := 0;
  setsockopt(ThisSocket,SOL_SOCKET,SO_RCVTIMEO,@ToRec, sizeof(timeval))
end;

end.
