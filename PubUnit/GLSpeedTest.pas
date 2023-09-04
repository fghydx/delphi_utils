//���ٵ�Ԫ
unit GLSpeedTest;

interface

uses GLClientSck,GLUDPClient,GLHTTPClient,SyncObjs,Classes,Windows,SysUtils;

type
  /// <author>�������������ͽṹ</author>
  TServerAddr= packed record
    AddrName:AnsiString;
    AddrIP:AnsiString;
    Port:Word;
    Tag:integer;
    NeedTime:Cardinal;
  end;
  TGLSpeedTest = class;
  /// <remarks>
  /// ������HTTP��ȡ�����ķ������б�
  /// </remarks>  
  TProcSvrListFromHttpGet = procedure (Sender:TGLSpeedTest;Str:string) of object;

  /// <remarks>
  /// ���ٵ�Ԫ,��TCP��UDP����
  /// </remarks>
  TGLSpeedTest = class
  private
    FProcSvrListFromHttpGet:TProcSvrListFromHttpGet;
    FTcpTest : Boolean;
    FTestedCount:integer;
    Fevent:TEvent;
    FLocker:TCriticalSection;
    FSvrList:array of TServerAddr;
    FUseUdpRecvStr: string;
    FUseUDPSendStr: string;
    function GetCount: Integer;
    function GetSvrItems(Index: Integer): TServerAddr;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReSort(Addr:TServerAddr);
    procedure GetSvrListFromURL(URL:String);    //��һ��URL��ַ���ȡ�������б�
    procedure Add(SvrAddr:TServerAddr);

    procedure ConnectTest;                 //���Ӳ���
    procedure WaitForTest;                 //�ȵ����Ӳ������(��������᷵��)
    function GetSpeedInfo:string;
    
    property TcpTest:Boolean read FTcpTest write FTcpTest;
    property Count: Integer read GetCount;
    property SvrItems[Index: Integer]: TServerAddr read GetSvrItems;
    property UseUdpRecvStr: string read FUseUdpRecvStr write FUseUdpRecvStr;    //UDP���ٷ��͵Ĵ�
    property UseUDPSendStr: string read FUseUDPSendStr write FUseUDPSendStr;    //���UDP���ٽ��յĴ��������ͬ,˵���˴β��ٳɹ�
    property OnProcSvrListFromHttpGet:TProcSvrListFromHttpGet  read FProcSvrListFromHttpGet write FProcSvrListFromHttpGet;
  end;

  /// <remarks>
  /// ���Ӳ����߳�,���Ƿ���������ָ��������
  /// </remarks>
  TConnectTestThread = class(TThread)
  private
    FOwner:TGLSpeedTest;
    SvrAddr:TServerAddr;
  public
    constructor Create(Addr:TServerAddr;Owner:TGLSpeedTest);
    procedure Execute;override;
  end;

implementation

{ TGLSpeedTest }

procedure TGLSpeedTest.Add(SvrAddr: TServerAddr);
var
  I:Integer;
begin
  FLocker.Enter;
  try
    for I := 0 to Length(FSvrList) - 1 do
    begin
      if FSvrList[I].AddrIP = SvrAddr.AddrIP then
      begin
        Exit;
      end;
    end;  
    SetLength(FSvrList,length(FSvrList)+1);
    FSvrList[High(FSvrList)] := SvrAddr;
  finally
    FLocker.Leave;
  end;
end;

procedure TGLSpeedTest.ConnectTest;
var
  I:integer;
begin
  FLocker.Enter;
  try
    FTestedCount := 0;
    for I := 0 to Length(FSvrList) - 1 do
    begin
      FSvrList[I].Tag := 0;
      TConnectTestThread.Create(FSvrList[I],Self);
    end;
  finally
    FLocker.Leave;
  end;
end;

constructor TGLSpeedTest.Create;
begin
  inherited;
  FTcpTest := True;
  FLocker := TCriticalSection.Create;
  Fevent := TEvent.Create();
end;

destructor TGLSpeedTest.Destroy;
begin
  FLocker.Free;
  Fevent.Free;
  inherited;
end;

function TGLSpeedTest.GetCount: Integer;
begin
  FLocker.Enter;
  try
    Result := Length(FSvrList);
  finally
    FLocker.Leave;
  end;
end;

function TGLSpeedTest.GetSpeedInfo: string;
var
  I: Integer;
begin
  Result := '';
  FLocker.Enter;
  try
    for I := 0 to Length(FSvrList) - 1 do
    begin
      Result := Result + 'IP:'+FSvrList[I].AddrIP +' Port:'+inttostr(FSvrList[I].Port)+' Speed:'+inttostr(FSvrList[I].NeedTime)+#13#10;
    end;
  finally
    FLocker.Leave;
  end;
end;

function TGLSpeedTest.GetSvrItems(Index: Integer): TServerAddr;
begin
  FillChar(result,SizeOf(TServerAddr),0);
  FLocker.Enter;
  try
    if (Index<0) or (index>High(FSvrList)) then  Exit;
    
    Result := FSvrList[index];
  finally
    FLocker.Leave;
  end;
end;

procedure TGLSpeedTest.GetSvrListFromURL(URL: String);
var
  str:string;
begin
  str := HttpGet(URL);
  if Assigned(FProcSvrListFromHttpGet) then
    FProcSvrListFromHttpGet(self,str);
end;

procedure TGLSpeedTest.ReSort(Addr: TServerAddr);
  procedure Sort;
  var
    i,j:integer;
    tem:TServerAddr;
  begin
    for I := 0 to Length(FSvrList) - 1 do
    begin
      for j := i to Length(FSvrList) - 1 do
      begin
        if FSvrList[I].Tag<FSvrList[J].Tag then
        begin
           tem := FSvrList[I];
           FSvrList[I] := FSvrList[j];
           FSvrList[J] := tem;
        end;
      end;
    end;  
  end;

var
  svr:TServerAddr;
  I:Integer;
begin
  FLocker.Enter;
  try
    Inc(FTestedCount);
    for I := 0 to Length(FSvrList) - 1 do
    begin
      if FSvrList[I].Tag=0 then
      begin
        FSvrList[I] := Addr;
        Sort;
        Break;
      end;
    end;
    if FTestedCount>=3 then            //����ͨ��3���Ͳ��õ���.
    begin
      Fevent.SetEvent;
    end;
  finally
    FLocker.Leave;
  end;
end;

procedure TGLSpeedTest.WaitForTest;
begin
  Fevent.WaitFor(3000);
end;

{ TConnectTestThread }

constructor TConnectTestThread.Create(Addr: TServerAddr; Owner: TGLSpeedTest);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  SvrAddr := Addr;
  FOwner := Owner;
  Resume;
end;

procedure TConnectTestThread.Execute;

  procedure UseTcpTest;
  var
    Sck:TGLClientSck;
    i:integer;
  begin
      for I := 0 to 2 do
      begin
        Sck := TGLClientSck.Create;
        try
          Sck.addr := SvrAddr.AddrIP;
          Sck.Port := SvrAddr.Port;
          try
            if Sck.Open(1500) then
            begin
              Inc(SvrAddr.Tag);
            end;
          except
            Continue;
          end;
        finally
          Sck.Free;
        end;
      end;
  end;

  procedure UseUdpTest;
  var
    UdpCnt:TGLUDPClient;
    i:integer;
  begin
    for I := 0 to 2 do
    begin
      UdpCnt := TGLUDPClient.Create;
      try
        UdpCnt.RemoteHost := SvrAddr.AddrIP;
        UdpCnt.RemotePort := SvrAddr.Port;
        UdpCnt.RecvTimeOut := 1500;
        UdpCnt.SendString(FOwner.UseUDPSendStr);
        if UdpCnt.RecvString=FOwner.UseUdpRecvStr then
        begin
          Inc(SvrAddr.Tag);
        end;
      finally
        UdpCnt.Free;
      end;
    end;
  end;
var
  T:Cardinal;
begin
  inherited;
  T := GetTickCount;
  try
    if FOwner.TcpTest then
    begin
      UseTcpTest;
    end else
    begin
      UseUdpTest;
    end;
  finally
    Inc(SvrAddr.Tag);
    SvrAddr.NeedTime := GetTickCount - T;
    FOwner.ReSort(SvrAddr);
  end;
end;

end.
