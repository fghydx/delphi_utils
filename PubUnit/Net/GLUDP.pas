
unit GLUDP;


interface

uses
  Windows, Messages, Classes, SysUtils, GLWinSockX, contnrs;

type

//==============================================================================
// UDP ͨѶ��        ��CnVCL���졣
//==============================================================================

{ TGLUDP }

  TOnReceive = procedure(Sender: TComponent; Buffer: Pointer; Len: Integer;
    FromIP: string; Port: Integer) of object;
  {* ���յ������¼�
   |<PRE>
     Sender     - TGLUDP ����
     Buffer     - ���ݻ�����
     Len        - ���ݻ���������
     FromIP     - ������Դ IP
     Port       - ������Դ�˿ں�
   |</PRE>}

  TGLUDP = class(TComponent)
  {* ʹ�÷�������ʽ���� UDP ͨѶ���ࡣ֧�ֹ㲥�����ݶ��еȡ�}
  private
    FRemoteHost: string;
    FRemotePort: Integer;
    FLocalPort: Integer;
    FSocketWindow: HWND;
    FOnDataReceived: TOnReceive;
    FListening: Boolean;
    Wait_Flag: Boolean;
    RemoteAddress, RemoteAddress2: TSockAddr;
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
    function ResolveRemoteHost(ARemoteHost: string): Boolean;
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
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SendStream(DataStream: TStream; BroadCast: Boolean = False): Boolean;
    {* ����һ������������� BroadCase Ϊ�棬ִ�� UDP �㲥�����������ݵ�
       RomoteHost �Ļ����ϵ� RemotePort �˿�}
    function SendBuffer(Buff: Pointer; Length: Integer; BroadCast:
      Boolean = False): Boolean;
    {* ����һ�����ݿ顣��� BroadCase Ϊ�棬ִ�� UDP �㲥�����������ݵ�
       RomoteHost �Ļ����ϵ� RemotePort �˿�}
    procedure ClearQueue;
    {* ������ݶ��С�����û�������������յ������ݣ������������ݰ��ŵ�����
       �����У����ø÷�����������ݶ���}

    procedure Start;
    procedure Stop;

    property LastError: Integer read FLastError;
    {* ���һ�δ���Ĵ���ţ�ֻ������}
    property Listening: Boolean read FListening;
    {* ��ʾ��ǰ�Ƿ����ڼ������ض˿ڣ�ֻ������}
    property QueueCount: Integer read GetQueueCount;
    {* ��ǰ���ݶ��еĳ��ȣ�ֻ������}
  published
    property RemoteHost: string read FRemoteHost write FRemoteHost;
    {* Ҫ���� UDP ���ݵ�Ŀ��������ַ}
    property RemotePort: Integer read FRemotePort write FRemotePort;
    {* Ҫ���� UDP ���ݵ�Ŀ�������˿ں�}
    property LocalHost: string read GetLocalHost;
    {* ���ر��� IP ��ַ��ֻ������}
    property LocalPort: Integer read FLocalPort write SetLocalPort;
    {* ���ؼ����Ķ˿ں�}
    property RecvBufSize: Cardinal read FRecvBufSize write SetRecvBufSize default 2048;
    {* ���յ����ݻ�������С��Ĭ�� 2048}
    property OnDataReceived: TOnReceive read FOnDataReceived write
      FOnDataReceived;
    {* ���յ� UDP ���ݰ��¼�}
  end;

// ȡ�㲥��ַ
procedure GetBroadCastAddress(sInt: TStrings);

// ȡ����IP��ַ
procedure GetLocalIPAddress(sInt: TStrings);

implementation

{$R-}

//==============================================================================
// ��������
//==============================================================================

//// ��Winsock 2.0���뺯��WSAIOCtl
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

// ȡ�㲥��ַ
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

// ȡ����IP��ַ
procedure GetLocalIPAddress(sInt: TStrings);
begin
  DoGetIPAddress(sInt, False);
end;  

// ȡ�㲥��ַ
procedure GetBroadCastAddress(sInt: TStrings);
begin
  DoGetIPAddress(sInt, True);
end;

//==============================================================================
// UDP ͨѶ��
//==============================================================================

{ TGLUDP }

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

constructor TGLUDP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Queue := TQueue.Create;
  FListening := False;
  Procing := False;
  FRecvBufSize := 2048;

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

destructor TGLUDP.Destroy;
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

procedure TGLUDP.UpdateBinding;
var
  Data: DWORD;
begin
  if not (csDesigning in ComponentState) then
  begin
    FListening := False;
    RemoteAddress2.sin_addr.S_addr := Inet_Addr('0.0.0.0');
    RemoteAddress2.sin_family := AF_INET;
    RemoteAddress2.sin_port := htons(FLocalPort);
    Wait_Flag := False;
    if Bind(ThisSocket, @RemoteAddress2, SizeOf(RemoteAddress2)) =
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
end;

procedure TGLUDP.SetLocalPort(NewLocalPort: Integer);
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

function TGLUDP.ResolveRemoteHost(ARemoteHost: string): Boolean;
var
  Buf: array[0..127] of AnsiChar;
begin
  Result := False;
  if not FListening then Exit;
  try
    RemoteAddress.sin_addr.S_addr := Inet_Addr(PAnsiChar(StrPCopy(Buf, AnsiString(ARemoteHost))));
    if RemoteAddress.sin_addr.S_addr = SOCKET_ERROR then
    begin
      Wait_Flag := False;
      WSAAsyncGetHostByName(FSocketWindow, WM_ASYNCHRONOUSPROCESS, Buf,
        PAnsiChar(RemoteHostS), MAXGETHOSTSTRUCT);
      repeat
        Wait;
      until Wait_Flag;
      if Succeed then
      begin
        with RemoteAddress.sin_addr.S_un_b do
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
  if RemoteAddress.sin_addr.S_addr <> 0 then
    Result := True;
  if not Result then
    SetupLastError;
end;

function TGLUDP.SendStream(DataStream: TStream; BroadCast: Boolean): Boolean;
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

function TGLUDP.SendBuffer(Buff: Pointer; Length: Integer;
  BroadCast: Boolean): Boolean;
var
  Hosts: TStrings;
  i: Integer;
  
  function DoSendBuffer(Buff: Pointer; Length: Integer; Host: string): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    try
      if not ResolveRemoteHost(Host) then
        Exit;
      RemoteAddress.sin_family := AF_INET;
      RemoteAddress.sin_port := htons(FRemotePort);
      i := SizeOf(RemoteAddress);
      if sendto(ThisSocket, Buff^, Length, 0, @RemoteAddress, i)
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

function TGLUDP.GetQueueCount: Integer;
begin
  Result := Queue.Count;
end;

procedure TGLUDP.FreeQueueItem(P: Pointer);
var
  Rec: PRecvDataRec;
begin
  Rec := PRecvDataRec(P);
  Rec.FromIP := '';
  FreeMem(Rec.Buff);
  FreeMem(Rec);
end;

procedure TGLUDP.ClearQueue;
var
  Rec: PRecvDataRec;
begin
  while Queue.Count > 0 do
  begin
    Rec := Queue.Pop;
    FreeQueueItem(Rec);
  end;
end;

procedure TGLUDP.ProcessQueue;
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
        FOnDataReceived(Self, Rec.Buff, Rec.BuffSize, string(Rec.FromIP), Rec.FromPort);
      FreeQueueItem(Rec);
    end;
  finally
    Procing := False;
  end;
end;

procedure TGLUDP.ProcessIncomingdata;
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
  Tlongint = record
    LparamLo:Word;
    LparamHi:Word;
  end;
procedure TGLUDP.ProcessMessage;
var
  msg:TMsg;
  Loparam:Tlongint;
  Unicode: Boolean;
  MsgExists: Boolean;
begin
  while GetMessage(Msg, FSocketWindow, 0, 0) do
  begin
    if Msg.message = WM_ASYNCHRONOUSPROCESS then
    begin
      Loparam := Tlongint(msg.lParam);
      if Loparam.LparamLo = FD_READ then
      begin
        ProcessIncomingdata;
        if not Procing then
          ProcessQueue;
      end
      else
      begin
        Wait_Flag := True;
        if Loparam.LparamHi > 0 then
          Succeed := False
        else
          Succeed := True;
      end;
      SetEvent(EventHandle);
    end else if msg.message = WM_QUIT then
    begin
      Break;
    end else
    begin
      TranslateMessage(Msg);
      DispatchMessageW(Msg);
    end;
  end;
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

procedure TGLUDP.Wait;
begin
  WaitforSync(EventHandle);
  ResetEvent(EventHandle);
end;

procedure TGLUDP.SetupLastError;
begin
  FLastError := WSAGetLastError;
end;

function TGLUDP.GetLocalHost: string;
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

procedure TGLUDP.Start;
begin
  if FLocalPort>0 then
    UpdateBinding;
  // TODO -cMM: TGLUDP.Start default body inserted
end;

procedure TGLUDP.SetRecvBufSize(const Value: Cardinal);
begin
  if FRecvBufSize <> Value then
  begin
    FRecvBufSize := Value;
    if FRecvBuf <> nil then
    begin
      // �ͷţ��ȴ��´���Ҫʱ���·���
      FreeMem(FRecvBuf);
      FRecvBuf := nil;
    end;  
  end;
end;

procedure TGLUDP.Stop;
begin
  SendMessage(FSocketWindow,WM_QUIT,0,0);
end;

end.

