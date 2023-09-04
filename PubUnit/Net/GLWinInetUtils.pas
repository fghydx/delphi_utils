unit GLWinInetUtils;

interface

uses
  SysUtils, Classes, Windows, WinInet, GLWinsockX;

const
  INET_NULL_HANDLE: HINTERNET = nil;
  INTERNET_STATUS_DETECTING_PROXY  =  80;
  INTERNET_STATUS_USER_INPUT_REQUIRED = 140;
  INTERNET_STATUS_COOKIE_SENT = 320;
  INTERNET_STATUS_COOKIE_RECEIVED = 321;
  INTERNET_STATUS_PRIVACY_IMPACTED = 324;
  INTERNET_STATUS_P3P_HEADER = 325;
  INTERNET_STATUS_P3P_POLICYREF = 326;
  INTERNET_STATUS_COOKIE_HISTORY = 327;

  BUFFER_SIZE = 50 * 1024;

  PORT_HTTP = 80;
  PORT_HTTPS = 443;
  PORT_FTP = 21;
  PORT_GOPHER = 70;

type
  TInternetCookieHistory = packed record
    Accepted, Leashed, Downgraded, Rejected: BOOL;
  end;
  PInternetCookieHistory = ^TInternetCookieHistory;

  TXInetContextAccess = (caPreconfig, caDirect, caGateway,
    caCustom, caPreconfigNoScript);
    
  TXInetContextFlag = (cfAsync, cfCache, cfOffline);
  TXInetContextFlags = set of TXInetContextFlag;

TUrlScheme = (usPartial, usUnknow, usDefault, usFtp{1}, usGopher{2}, usHttp{3},
    usHttps, usFile, usNews, usMailto);

TUrlPart = (upUnknown, upSchema, upUserName, upHost, upPort, upPath, upParam);

TUrlColon = record
    case Part: TUrlPart of
      upUserName: (
        UserNamePtr: PAnsiChar;
        UserNameLen: Integer;
        PasswordPtr: PAnsiChar;
        PasswordLen: Integer);
      upPort: (Port: Integer; PortPtr: PAnsiChar; PortLen: Integer)
  end;

const
DefaultInternetPorts: array [TUrlScheme] of Integer =
  (0, 0, 0, PORT_FTP, PORT_GOPHER, PORT_HTTP, PORT_HTTPS, 0, 0, 0);

type
  TXUrlComponents = object
  public
    Scheme: TUrlScheme;
    HostPtr: PAnsiChar;
    HostLen: Integer;
    Port: Integer;
    UserNamePtr: PAnsiChar;
    UserNameLen: Integer;
    PasswordPtr: PAnsiChar;
    PasswordLen: Integer;
    PathPtr: PAnsiChar;
    PathLen: Integer;
    ParamsPtr: PAnsiChar;
    ParamsLen: Integer;
  public
    function Host: AnsiString;
    function Path: AnsiString;
    function Params: AnsiString;
    function PathWithParams: AnsiString;
    function UserName: AnsiString;
    function Password: AnsiString;
  end;

type
  TGLInetContext = object
  private
    fHandle: HINTERNET;
    fAgent: AnsiString;
    fAccess: TXInetContextAccess;
    fFlags: TXInetContextFlags;
    procedure SetFlags(const Value: TXInetContextFlags);
    procedure SetAccess(const Value: TXInetContextAccess);
    procedure SetAgent(const Value: AnsiString);
  public
    procedure Initial;
    procedure Cleanup;
    procedure Open;
    property Handle: HINTERNET read fHandle;
    property Agent: AnsiString read fAgent write SetAgent;
    property Access: TXInetContextAccess read fAccess write SetAccess;
    property Flags: TXInetContextFlags read fFlags write SetFlags;
  end;
  PGLInetContext = ^TGLInetContext;

  TGLInetConnection = class
  private
    fContext: PGLInetContext;
    fOwnedContext: Boolean;
    fConnection: HINTERNET;
    procedure AccquireContext;
    procedure SetContext(const Value: PGLInetContext);
    function GetContext: PGLInetContext;
  protected
    procedure AsyncCallback(Status, InfoLen: DWORD; Info: Pointer);
    function Connect(Host: PChar; Port: Word = INTERNET_DEFAULT_HTTP_PORT;
      Service: DWORD = INTERNET_SERVICE_HTTP; Username: PAnsiChar = nil;
      Password: PAnsiChar = nil; Flags: DWORD = 0;
      pError: PInteger = nil): Boolean;
    procedure OnConnectionCreated(ErrorCode: Integer); virtual; abstract;
    procedure OnResolvingName(Domain: PAnsiChar); dynamic;
    procedure OnNameResolved(Domain: PAnsiChar); dynamic;
    procedure OnConnecting(EndPoint: PSockAddr); dynamic;
    procedure OnConnected(EndPoint: PSockAddr); dynamic;
    procedure OnSendingRequest; dynamic;
    procedure OnRequestSent(BytesSent: Integer); dynamic;
    procedure OnRecvingResponse; dynamic;
    procedure OnResponseRecved(BytesRecved: Integer); dynamic;
    procedure OnCtlRespRecved; dynamic;
    procedure OnPrefetch; dynamic;
    procedure OnDisconnecting; dynamic;
    procedure OnDisconneted; dynamic;
    procedure OnHandleCreated(Error: Integer; Handle: HINTERNET); dynamic;
    procedure OnHandleClosing; dynamic;
    procedure OnDetectingProxy; dynamic;
    procedure OnCallComplete(ReturnValue: Boolean; Error: Integer); dynamic;
    procedure OnRedirect(Url: PAnsiChar); dynamic;
    procedure OnIntermediateResponse; dynamic;
    procedure OnUserInputRequired; dynamic;
    procedure OnStateChange; dynamic;
    procedure OnCookieSent; dynamic;
    procedure OnCookieRecved; dynamic;
    procedure OnPrivacyImpacted; dynamic;
    procedure OnP3PHeader; dynamic;
    procedure OnP3pPolicyRef; dynamic;
    procedure OnCookieHistory(CookieHistory: PInternetCookieHistory); dynamic;
  public
    destructor Destroy; override;
    property Context: PGLInetContext read GetContext write SetContext;
    property Connection: HINTERNET read fConnection;
  end; 

  THttpRequestState = (rsConnect, rsOpenRequest, rsSendHeader, rsSendParam,
    rsRecvHeader, rsRecvContent);

  TProgressEvent = procedure(Sender: TObject; Done, Total: Int64) of object;
  
  TGLWinInetHttp = class(TGLInetConnection)
  private
    fRequest: HINTERNET;
    fPostContentType: AnsiString;
    fReferrer: AnsiString;
    fReadBufSize: Integer;
    fWriteBufSize: Integer;
    fMethod: string;
    fPathAndParam: AnsiString;
    fUpStream: TStream;
    fDownStream: TStream;
    ContentLength: DWORD;
    fOnProgress: TProgressEvent;
  private
    CustomHeader: AnsiString;
    InetBuf: TInternetBuffersA;
    fState: THttpRequestState;
    Buf: array [0..BUFFER_SIZE - 1] of AnsiChar;
  private
    function GetCustomHeader(PostParamSize: DWORD): AnsiString;
    function PostParam(pError: PInteger = nil): Boolean;
    function ReadContent(pError: PInteger = nil): Boolean;
    procedure GetContentLength;
  protected
    function OpenRequest(pError: PInteger = nil): Boolean;
    function SendRequest(pError: PInteger = nil): Boolean;
    function EndRequest(pError: PInteger = nil): Boolean;
    procedure OnConnectionCreated(ErrorCode: Integer); override;
    procedure OnRequestSent(BytesSent: Integer); override;
    procedure OnResponseRecved(BytesRecved: Integer); override;
    procedure OnHandleCreated(Error: Integer; Handle: HINTERNET); override;
    procedure OnCallComplete(ReturnValue: Boolean; Error: Integer); override;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure DoRequest(Method, Host: PAnsiChar; Path: AnsiString;
      Request, Response: TStream;
      Port: Word = INTERNET_DEFAULT_HTTP_PORT;
      Service: DWORD = INTERNET_SERVICE_HTTP;
      Username: PAnsiChar = nil;
      Password: PAnsiChar = nil); overload;

    procedure DoRequest(Method: PAnsichar; Url: AnsiString;
      Request, Response: TStream); overload;

    procedure Close;
    procedure Get(const Url: AnsiString; Data: TStream);
    procedure Post(const Url: AnsiString; Param, Data: TStream);
    procedure Abort;
    property ReadBufSize: Integer read fReadBufSize write fReadBufSize;
    property WriteBufSize: Integer read fWriteBufSize write fWriteBufSize;
    property Method: AnsiString read fMethod;
    property PathAndParam: AnsiString read fPathAndParam;
    property Referrer: AnsiString read fReferrer write fReferrer;
    property PostContentType: AnsiString read fPostContentType write fPostContentType;
    property OnProgress: TProgressEvent read fOnProgress write fOnProgress;
  end; 

function HttpGet(client: TGLWinInetHttp; const Url: AnsiString): AnsiString; overload;
function HttpGet(const Url: AnsiString): AnsiString; overload;
procedure HttpGet(const Url:AnsiString;var OutStream:TStream); overload;

implementation

uses InZLibEx;

function UrlParseColon(BeginChar, Colon, EndChar: PAnsiChar;
  out Output: TUrlColon): Boolean;
var
  Ptr: PAnsiChar;
  Flag: Boolean;
  Port: Integer;
begin
  Result := True;
  Ptr := Colon + 1;
  Flag := True;
  Port := 0;
  while Ptr < EndChar do
  begin
    case Ptr^ of
      '/': Break;
      '@':
        begin
          Output.Part := upUserName;
          Output.UserNamePtr := BeginChar;
          Output.UserNameLen := Colon - BeginChar;
          Output.PasswordPtr := Colon + 1;
          Output.PasswordLen := Ptr - Colon - 1;
          Exit;
        end;
      '0'..'9':
        begin
          if Flag then
          begin
            Port := Port * 10 + Byte(Ptr^) and $0f;
          end;
        end;
      else begin
        Flag := False;
      end;
    end;
    Inc(Ptr);
  end;
  if not Flag then
  begin
    Result := False;
    Exit;
  end;
  Output.Part := upPort;
  Output.Port := Port;
  Output.PortPtr := Colon + 1;
  Output.PortLen := Ptr - Colon - 1;
end;

function ParseScheme(Str: PAnsiChar; Len: Integer): TUrlScheme;
begin
  Result := usUnknow;
  if Len = 3 then
  begin
    if (Str[0] in ['F', 'f']) and (Str[1] in ['T', 't']) and (Str[2] in ['P', 'p']) then
      Result := usFtp;
    Exit;
  end;

  if Len = 4 then
  begin
    case Str[0] of
      'H', 'h': if (Str[1] in ['T', 't']) and (Str[2] in ['T', 't']) and
        (Str[3] in ['P', 'p']) then Result := usHttp;
      'F', 'f': if (Str[1] in ['I', 'i']) and (Str[2] in ['F', 'f']) and
        (Str[3] in ['L', 'l']) then Result := usFile;
      'N', 'n': if (Str[1] in ['E', 'e']) and (Str[2] in ['W', 'w']) and
        (Str[3] in ['S', 's']) then Result := usNews;
    end;
    Exit;
  end;

  if Len = 5 then
  begin
    if (Str[0] in ['H', 'h']) and (Str[1] in ['T', 't']) and (Str[2] in ['T', 't']) and
      (Str[3] in ['P', 'p']) and (Str[4] in ['S', 's']) then Result := usHttps;
    Exit;
  end;

  if Len = 6 then
  begin
    case Str[0] of
      'G', 'g': if (Str[1] in ['O', 'o']) and (Str[2] in ['P', 'p']) and
        (Str[3] in ['H', 'h']) and (Str[4] in ['E', 'e']) and
        (Str[5] in ['R', 'r']) then Result := usGopher;
      'M', 'm': if (Str[1] in ['A', 'a']) and (Str[2] in ['I', 'i']) and
        (Str[3] in ['L', 'l']) and (Str[4] in ['T', 't']) and
        (Str[5] in ['O', 'o']) then Result := usMailto;
    end;
  end;
end;

function ParseUrl(const Url: AnsiString; out Components: TXUrlComponents): Boolean;
var
  pUrl, CharPtr, UrlEnd: PAnsiChar;
  UrlColon: TUrlColon;
  State: TUrlPart;
begin
  pUrl := PAnsiChar(Url);
  UrlEnd := pUrl + Length(Url);
  CharPtr := pUrl;
  State := upPath;
  FillChar(Components, SizeOf(Components), 0);
  Result := True;
  while (CharPtr < UrlEnd) and not (CharPtr^ in [':', '.', '/', '@']) do Inc(CharPtr);
  if CharPtr = UrlEnd then
  begin
    Components.Scheme := usHttp;
    Components.HostPtr := pUrl;
    Components.HostLen := CharPtr - pUrl;
    Components.Port := PORT_HTTP;
    Components.PathPtr := '/';
    Components.PathLen := 1;
    Exit;
  end;
  case CharPtr^ of
    ':':
      begin
        if CharPtr = UrlEnd - 1 then
        begin
          Result := False;
          Exit;
        end;
        if CharPtr[1] = '/' then
        begin
          //scheme
          if (CharPtr = UrlEnd - 2) or (CharPtr[2] <> '/') then
          begin
            Result := False;
            Exit;
          end;
          Components.Scheme := ParseScheme(pUrl, CharPtr - pUrl);
          if Components.Scheme = usUnknow then Exit;
          Inc(CharPtr, 3);
          State := upUserName;  //scheme get, username&password expected
        end
        else begin
          //host&port or username&password
          Components.Scheme := usHttp;
          if not UrlParseColon(pUrl, CharPtr, UrlEnd, UrlColon) then
          begin
            Result := False;
            Exit;
          end;
          if UrlColon.Part = upUserName then
          begin
            Components.UserNamePtr := UrlColon.UserNamePtr;
            Components.UserNameLen := UrlColon.UserNameLen;
            Components.PasswordPtr := UrlColon.PasswordPtr;
            Components.PasswordLen := UrlColon.PasswordLen;
            State := upHost; //username&password get, host expected
            CharPtr := UrlColon.PasswordPtr + UrlColon.PasswordLen + 1;
          end
          else begin
            Components.HostPtr := pUrl;
            Components.HostLen := CharPtr - pUrl;
            Components.Port := UrlColon.Port;
            CharPtr := UrlColon.PortPtr + UrlColon.PortLen;
            //State := 2; //host&port get, path expected
          end;
        end;
      end;
    '.':
      begin
        Components.Scheme := usHttp;
        while (CharPtr < UrlEnd) and not (CharPtr^ in [':', '/']) do Inc(CharPtr);
        if (CharPtr = UrlEnd) or (CharPtr^ = '/') then
        begin
          Components.Port := PORT_HTTP;
          Components.HostPtr := pUrl;
          Components.HostLen := CharPtr - pUrl;
          if CharPtr = UrlEnd then
          begin
            Components.PathPtr := '/';
            Components.PathLen := 1;
            Exit;
          end;
        end;
        if CharPtr^ = ':' then
        begin
          if not UrlParseColon(pUrl, CharPtr, UrlEnd, UrlColon) then
          begin
            Result := False;
            Exit;
          end;
          if UrlColon.Part = upUserName then
          begin
            Components.UserNamePtr := UrlColon.UserNamePtr;
            Components.UserNameLen := UrlColon.UserNameLen;
            Components.PasswordPtr := UrlColon.PasswordPtr;
            Components.PasswordLen := UrlColon.PasswordLen;
            State := upHost; //username&password get, host expected
            CharPtr := UrlColon.PasswordPtr + UrlColon.PasswordLen + 1;
          end
          else begin
            Components.HostPtr := pUrl;
            Components.HostLen := CharPtr - pUrl;
            Components.Port := UrlColon.Port;
            CharPtr := UrlColon.PortPtr + UrlColon.PortLen;
            //State := 2; //host&port get, path expected
          end;
        end;
      end;
    '/':
      begin
        Components.Scheme := usHttp;
        Components.Port := PORT_HTTP;
        Components.HostPtr := pUrl;
        Components.HostLen := CharPtr - pUrl; 
      end;
    '@':
      begin
        Components.Scheme := usHttp;
        Components.UserNamePtr := pUrl;
        Components.UserNameLen := CharPtr - pUrl;
        Inc(CharPtr);
        State := upHost;
      end;
  end;

  pUrl := CharPtr;
  if State = upUserName then
  begin
    while (CharPtr < UrlEnd) and not (CharPtr^ in [':', '/', '@']) do Inc(CharPtr);
    if CharPtr = UrlEnd then
    begin
      Components.HostPtr := pUrl;
      Components.HostLen := CharPtr - pUrl;
      Components.Port := DefaultInternetPorts[Components.Scheme];
      Components.PathPtr := '/';
      Components.PathLen := 1;
      Exit;
    end;

    case CharPtr^ of
      ':':
        begin
          if not UrlParseColon(pUrl, CharPtr, UrlEnd, UrlColon) then
          begin
            Result := False;
            Exit;
          end;
          if UrlColon.Part = upUserName then
          begin
            Components.UserNamePtr := UrlColon.UserNamePtr;
            Components.UserNameLen := UrlColon.UserNameLen;
            Components.PasswordPtr := UrlColon.PasswordPtr;
            Components.PasswordLen := UrlColon.PasswordLen;
            State := upHost; //username&password get, host expected
            CharPtr := UrlColon.PasswordPtr + UrlColon.PasswordLen + 1;
          end
          else begin
            Components.HostPtr := pUrl;
            Components.HostLen := CharPtr - pUrl;
            Components.Port := UrlColon.Port;
            CharPtr := UrlColon.PortPtr + UrlColon.PortLen;
            State := upPath; //host&port get, path expected
          end;
        end;
      '@':
        begin
          Components.UserNamePtr := pUrl;
          Components.UserNameLen := CharPtr - pUrl;
          Inc(CharPtr);
          State := upHost;
        end;
      else begin
        Components.HostPtr := pUrl;
        Components.HostLen := CharPtr - pUrl;
        Components.Port := DefaultInternetPorts[Components.Scheme];
        State := upPath;
      end;
    end;
  end;

  pUrl := CharPtr;
  if State = upHost then
  begin
    while (CharPtr < UrlEnd) and not (CharPtr^ in [':', '/']) do Inc(CharPtr);
    Components.HostPtr := pUrl;
    Components.HostLen := CharPtr - pUrl;
    if CharPtr = UrlEnd then
    begin
      Components.Port := DefaultInternetPorts[Components.Scheme];
      Components.PathPtr := '/';
      Components.PathLen := 1;
      Exit;
    end;
    if CharPtr^ = ':' then
    begin
      Inc(CharPtr);
      while CharPtr < UrlEnd do
      begin
        if CharPtr^ = '/' then
        begin
          if Components.Port = 0 then
          begin
            Result := False; Exit;
          end;
          Break;
        end;
        if not (CharPtr^ in ['0'..'9']) then
        begin
          Result := False;
          Exit;
        end;
        Components.Port := Components.Port * 10 + Byte(CharPtr^) and $0f;
        Inc(CharPtr);
      end;
    end
    else begin
      Components.Port := DefaultInternetPorts[Components.Scheme];
    end;
  end;

  pUrl := CharPtr;
  while (CharPtr < UrlEnd)  and (CharPtr^ <> '?') do Inc(CharPtr);
  Components.PathPtr := pUrl;
  Components.PathLen := CharPtr - pUrl;
  if CharPtr < UrlEnd then
  begin
    Components.ParamsPtr := CharPtr;
    Components.ParamsLen := UrlEnd - CharPtr;
  end;
end;

procedure InetCallback(hInternet: HINTERNET; dwContext: TGLInetConnection;
  dwInternetStatus: DWORD; lpStatusInfo: Pointer; dwStatusInfoLen: DWORD); stdcall;
begin
  dwContext.AsyncCallback(dwInternetStatus, dwStatusInfoLen, lpStatusInfo);
end;

procedure DecompressGZip(AInStream, AOutStream: TStream);
var
   pb1, pb2: Byte;
begin
  AInStream.Seek(1, 0);
  AInStream.Read(pb1, 1);
  AInStream.Seek(2, 0);
  AInStream.Read(pb2, 1);
  AInStream.Position := 0;
  AOutStream.Position := 0;
  if (pb1 = $8B) and (pb2 = $8) then
    ZDecompressStream2(AInStream, AOutStream, 47)
  else
    AOutStream.CopyFrom(AInStream, AInStream.Size);
end;

function HttpGet(client: TGLWinInetHttp; const Url: AnsiString): AnsiString;
var
  ss: TStringStream;
begin
  Result := '';
  ss := TStringStream.Create('');
  try
    client.Get(Url, ss);
    Result := ss.DataString;
  finally
    ss.Free;
  end;
end;

function HttpGet(const Url: AnsiString): AnsiString; overload;
var
  Client: TGLWinInetHttp;
begin
  Client := TGLWinInetHttp.Create;
  try
    Result := HttpGet(Client, Url);
  finally
    Client.Free;
  end;
end;

procedure HttpGet(const Url:AnsiString;var OutStream:TStream);
var
  Client: TGLWinInetHttp;
begin
  if OutStream=nil then  Exit;
  Client := TGLWinInetHttp.Create;
  try
    Client.Get(Url,OutStream);
  finally
    Client.Free;
  end;
end;

procedure ResetInetHandle(var handle: HINTERNET);
var
  temp: HINTERNET;
begin
  temp := HINTERNET(InterlockedExchange(Integer(handle), 0));
  if temp <> INET_NULL_HANDLE then InternetCloseHandle(temp);
end;

{ TGLWinInetHttp }

procedure TGLWinInetHttp.Abort;
begin

end;

procedure TGLWinInetHttp.Close;
begin
  ResetInetHandle(fRequest);
  ResetInetHandle(fConnection);
end;

constructor TGLWinInetHttp.Create;
begin
  fReadBufSize := BUFFER_SIZE;
  fWriteBufSize := BUFFER_SIZE;
end;

destructor TGLWinInetHttp.Destroy;
begin
  Close;
  inherited;
end;

procedure TGLWinInetHttp.DoRequest(Method, Host: PAnsiChar;
  Path: AnsiString; Request, Response: TStream; Port: Word;
  Service: DWORD; Username, Password: PAnsiChar);
var
  LastError: Integer;
begin
  fUpStream := Request;
  fDownStream := Response;
  ContentLength := DWORD(-1);
  fState := rsConnect;
  fMethod := Method;
  fPathAndParam := Path;
  if not Connect(PAnsiChar(Host), Port, Service, PAnsiChar(Username),
    PAnsiChar(Password), 0, @LastError) then
  begin
    if LastError = ERROR_IO_PENDING then Exit
    else RaiseLastOSError(LastError);
  end;
  fState := rsOpenRequest;
  if not OpenRequest(@LastError) then
  begin
    if LastError = ERROR_IO_PENDING then Exit
    else RaiseLastOSError(LastError);
  end;
  fState := rsSendHeader;
  try
    if not SendRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsSendParam;
    if Assigned(Request) and not PostParam(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsRecvHeader;
    if not EndRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    GetContentLength;
    fState := rsRecvContent;
    if ReadContent(@LastError) then ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;
  end;
end;

procedure TGLWinInetHttp.DoRequest(Method: PAnsiChar; Url: AnsiString;
  Request, Response: TStream);
var
  UrlComp: TXURLComponents;
begin
  if not ParseUrl(Url, UrlComp) then
    raise Exception.CreateFmt('"%s" is not a invalid url', [string(Url)]);
  with UrlComp do
  begin
    DoRequest(Method, PAnsiChar(Host), PathWithParams, Request, Response,
      Port, Ord(Scheme) - 2, PAnsiChar(Username), PAnsiChar(Password));
  end;
end;

function TGLWinInetHttp.EndRequest(pError: PInteger): Boolean;
begin
  
  Result := HttpEndRequestA(fRequest, nil, 0, DWORD(Self));
  if Result then GetContentLength
  else begin
    if Assigned(pError) then pError^ := GetLastError
    else RaiseLastOSError(GetLastError);
  end;
end;

procedure TGLWinInetHttp.Get(const Url: AnsiString; Data: TStream);
var
  mem:TMemoryStream;
begin
  mem := TMemoryStream.Create;
  try
    DoRequest('GET', Url, nil, mem);
    DecompressGZip(Mem,Data);
  finally
    mem.Free;
  end;
end;

procedure TGLWinInetHttp.GetContentLength;
var
  TotalRead, BytesRead: DWORD;
begin
  BytesRead := SizeOf(ContentLength);
  ContentLength:=0;
  TotalRead:=0;
  if not HttpQueryInfoA(fRequest, HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,
    @ContentLength, BytesRead, TotalRead) then
  begin
    if GetLastError = ERROR_HTTP_HEADER_NOT_FOUND then
      ContentLength := 0
    else SysUtils.RaiseLastOSError;
  end
  else begin
    //Writeln('Content-Length: ', ContentLength);
  end;
end;

function TGLWinInetHttp.GetCustomHeader(PostParamSize: DWORD): AnsiString;
begin
  if PostParamSize <> 0 then
  begin
    Result := Format('content-type: %s'#13#10'content-length: %d'#13#10#13#10,
      [PostContentType, PostParamSize]);
  end
  else Result := '';
end;

procedure TGLWinInetHttp.OnConnectionCreated(ErrorCode: Integer);
var
  LastError: Integer;
begin
  if not Assigned(Connection) then
  begin
    Exit;
  end;
  fState := rsOpenRequest;
  if not OpenRequest(@LastError) then
  begin
    if LastError = ERROR_IO_PENDING then Exit
    else RaiseLastOSError(LastError);
  end;
  fState := rsSendHeader;
  try
    if not SendRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsSendParam;
    if Assigned(fUpStream) and not PostParam(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsRecvHeader;
    if not EndRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsRecvContent;
    if ReadContent(@LastError) then
      ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then
        RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;  
  end;
end;

procedure TGLWinInetHttp.OnHandleCreated(Error: Integer; Handle: HINTERNET);
var
  LastError: Integer;
begin
  if Handle = INET_NULL_HANDLE then
  begin
    Exit;
  end;
  fRequest := Handle;
  fState := rsSendHeader;
  try
    if not SendRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsSendParam;
    if Assigned(fUpStream) and not PostParam(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsRecvHeader;
    if not EndRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    fState := rsRecvContent;
    if ReadContent(@LastError) then
      ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then
        RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;  
  end;
end;

procedure TGLWinInetHttp.OnCallComplete(ReturnValue: Boolean; Error: Integer);
var
  LastError: Integer;
begin
  if not ReturnValue then
  begin
    ResetInetHandle(fRequest);
    Exit;
  end;
  try
    if fState = rsSendHeader then
    begin
      fState := rsSendParam;
      if Assigned(fUpStream) and not PostParam(@LastError) then
      begin
        if LastError = ERROR_IO_PENDING then Exit
        else RaiseLastOSError(LastError);
      end;
      fState := rsRecvHeader;
      if not EndRequest(@LastError) then
      begin
        if LastError = ERROR_IO_PENDING then Exit
        else RaiseLastOSError(LastError);
      end;
      fState := rsRecvContent;
    end
    else begin
      GetContentLength;
      fState := rsRecvContent;
    end;
    if ReadContent(@LastError) then
      ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then
        RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;  
  end;
end;

procedure TGLWinInetHttp.OnRequestSent(BytesSent: Integer);
var
  LastError: Integer;
begin
  if fState = rsSendHeader then Exit;
  try
    if fUpStream.Position <> fUpStream.Size then
    begin
      if not PostParam(@LastError) then
      begin
        if LastError = ERROR_IO_PENDING then Exit
        else RaiseLastOSError(LastError);
      end;
    end;
    if not EndRequest(@LastError) then
    begin
      if LastError = ERROR_IO_PENDING then Exit
      else RaiseLastOSError(LastError);
    end;
    if ReadContent(@LastError) then
      ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then
        RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;  
  end;
end;

procedure TGLWinInetHttp.OnResponseRecved(BytesRecved: Integer);
var
  LastError: Integer;
begin
  if fState = rsRecvHeader then Exit;
  //SetEvent(hReadEvent);
  try
    if ReadContent(@LastError) then
      ResetInetHandle(fRequest)
    else begin
      if LastError <> ERROR_IO_PENDING then
        RaiseLastOSError(LastError);
    end;
  except
    ResetInetHandle(fRequest);
    raise;  
  end;
end;

function TGLWinInetHttp.OpenRequest(pError: PInteger): Boolean;
var
  AcceptTypes: array [0..1] of PAnsiChar;
begin
  AcceptTypes[0] := '*/*';
  AcceptTypes[1] := nil;
  
  fRequest := HttpOpenRequestA(Connection, PAnsiChar(fMethod),
    PAnsiChar(fPathAndParam), nil, PAnsiChar(fReferrer), @AcceptTypes,
    INTERNET_FLAG_NO_CACHE_WRITE, DWORD(Self));
  Result := fRequest <> INET_NULL_HANDLE;
  if not Result then 
  begin
    if Assigned(pError) then pError^ := GetLastError
    else SysUtils.RaiseLastOSError;
  end
end;

function TGLWinInetHttp.SendRequest(pError: PInteger): Boolean;
begin
  if Assigned(fUpStream) then
    CustomHeader := GetCustomHeader(fUpStream.Size - fUpStream.Position)
  else CustomHeader := GetCustomHeader(0);

  FillChar(InetBuf, SizeOf(InetBuf), 0);
  InetBuf.dwStructSize := SizeOf(InetBuf);
  InetBuf.lpcszHeader := PAnsiChar(CustomHeader);
  InetBuf.dwHeadersLength := Length(CustomHeader);
  if Assigned(fUpStream) then
    InetBuf.dwBufferTotal := fUpStream.Size - fUpStream.Position
  else InetBuf.dwBufferTotal := 0;

  Result := HttpSendRequestEx(fRequest, @InetBuf, nil, 0, DWORD(Self));
  if not Result then
  begin
    if Assigned(pError) then pError^ := GetLastError
    else RaiseLastOSError(GetLastError);
  end
end;

procedure TGLWinInetHttp.Post(const Url: AnsiString; Param, Data: TStream);
begin
  DoRequest('POST', Url, Param, Data);
end;

function TGLWinInetHttp.PostParam(pError: PInteger): Boolean;
var
  pBuf: PAnsiChar;
  BufSize, BytesWrite: DWORD;
begin  
  pBuf := Buf;
  if fWriteBufSize > SizeOf(Buf) then pBuf := GetMemory(fWriteBufSize);
  try
    BufSize := fUpStream.Read(pBuf^, fWriteBufSize);
    while BufSize > 0 do
    begin
      if not InternetWriteFile(fRequest, pBuf, BufSize, BytesWrite) then
      begin
        Result := False;
        if Assigned(pError) then pError^ := GetLastError
        else RaiseLastOSError(GetLastError);
        Exit;
      end;
      BufSize := fUpStream.Read(pBuf^, fWriteBufSize);
    end;
    Result := True;
  finally
    if Pointer(pBuf) <> Pointer(@Buf[0]) then FreeMemory(pBuf);
  end;
end;

function TGLWinInetHttp.ReadContent(pError: PInteger): Boolean;
var
  pBuf: PAnsiChar;
  TotalRead, BytesRead: DWORD;
begin
  pBuf := Buf;
  TotalRead := 0;
  if fReadBufSize > SizeOf(Buf) then pBuf := GetMemory(fReadBufSize);
  try
    while (ContentLength = 0) or (TotalRead < ContentLength) do
    begin
      if not InternetReadFile(fRequest, pBuf, fReadBufSize, BytesRead) then
      begin
        if Assigned(pError) then pError^ := GetLastError
        else SysUtils.RaiseLastOSError;
        Result := False;
        Exit;
      end;
    
      if BytesRead = 0 then Break;
      fDownStream.WriteBuffer(pBuf^, BytesRead);
      Inc(TotalRead, BytesRead);
      if Assigned(fOnProgress) then fOnProgress(Self, TotalRead, ContentLength);
    end;
    Result := True;
  finally
    if Pointer(pBuf) <> Pointer(@Buf[0]) then FreeMemory(pBuf);
  end;
end;

{ TGLInetContext }

procedure TGLInetContext.Cleanup;
begin
  ResetInetHandle(fHandle);
end;

procedure TGLInetContext.Initial;
begin
  fHandle := nil;
  fAccess := caPreconfig;
  fFlags := [];
  fAgent := 'DZWinInet';
end;

procedure TGLInetContext.Open;
  function ContextFlag_SetToInt(const Flags: TXInetContextFlags): DWORD;
  begin
    if cfAsync in Flags then Result := INTERNET_FLAG_ASYNC
    else Result := 0;
    if cfCache in Flags then Result := INTERNET_FLAG_FROM_CACHE;
    if cfOffline in Flags then Result := INTERNET_FLAG_OFFLINE;
  end;
begin
  if fHandle = INET_NULL_HANDLE then
  begin
    fHandle := InternetOpenA(PAnsiChar(fAgent), DWORD(fAccess), nil, nil,
      ContextFlag_SetToInt(fFlags));
    if fHandle = INET_NULL_HANDLE then SysUtils.RaiseLastOSError
    else if cfAsync in fFlags then
      InternetSetStatusCallback(fHandle, @InetCallback);
  end;
end;

procedure TGLInetContext.SetAccess(const Value: TXInetContextAccess);
begin
  fAccess := Value;
end;

procedure TGLInetContext.SetAgent(const Value: AnsiString);
begin
  fAgent := Value;
end;

procedure TGLInetContext.SetFlags(const Value: TXInetContextFlags);
begin
  fFlags := Value;
end;

{ TGLInetConnection }

procedure TGLInetConnection.AccquireContext;
begin
  if not Assigned(fContext) then 
  begin
    New(fContext);
    fContext.Initial;
    fOwnedContext := True;
  end;
end;

procedure TGLInetConnection.AsyncCallback(Status, InfoLen: DWORD; Info: Pointer);
var
  AsyncResult: PInternetAsyncResult;
begin
  AsyncResult := PInternetAsyncResult(Info);
  case Status of
    INTERNET_STATUS_RESOLVING_NAME: OnResolvingName(PAnsiChar(Info));
    INTERNET_STATUS_NAME_RESOLVED: OnNameResolved(PAnsiChar(Info));
    INTERNET_STATUS_CONNECTING_TO_SERVER: OnConnecting(PSockAddr(Info));
    INTERNET_STATUS_CONNECTED_TO_SERVER: OnConnected(PSockAddr(Info));
    INTERNET_STATUS_SENDING_REQUEST: OnSendingRequest;
    INTERNET_STATUS_REQUEST_SENT: OnRequestSent(PInteger(Info)^);
    INTERNET_STATUS_RECEIVING_RESPONSE: OnRecvingResponse;
    INTERNET_STATUS_RESPONSE_RECEIVED: OnResponseRecved(PInteger(Info)^);
    INTERNET_STATUS_CTL_RESPONSE_RECEIVED: OnCtlRespRecved;
    INTERNET_STATUS_PREFETCH: OnPrefetch;
    INTERNET_STATUS_CLOSING_CONNECTION: OnDisconnecting;
    INTERNET_STATUS_CONNECTION_CLOSED: OnDisconneted;
    INTERNET_STATUS_HANDLE_CREATED:
      begin
        if fConnection = INET_NULL_HANDLE then
        begin
          fConnection := HINTERNET(AsyncResult^.dwResult);
          OnConnectionCreated(AsyncResult^.dwError);
        end
        else OnHandleCreated(AsyncResult^.dwError, HINTERNET(AsyncResult^.dwResult));
      end;
    INTERNET_STATUS_HANDLE_CLOSING: OnHandleClosing;
    INTERNET_STATUS_DETECTING_PROXY: OnDetectingProxy;
    INTERNET_STATUS_REQUEST_COMPLETE:
      OnCallComplete(AsyncResult^.dwResult <> 0, AsyncResult^.dwError);
    INTERNET_STATUS_REDIRECT: OnRedirect(PAnsiChar(Info));
    INTERNET_STATUS_INTERMEDIATE_RESPONSE: OnIntermediateResponse;
    INTERNET_STATUS_USER_INPUT_REQUIRED: OnUserInputRequired;
    INTERNET_STATUS_STATE_CHANGE: OnStateChange;
    INTERNET_STATUS_COOKIE_SENT: OnCookieSent;
    INTERNET_STATUS_COOKIE_RECEIVED: OnCookieRecved;
    INTERNET_STATUS_PRIVACY_IMPACTED: OnPrivacyImpacted;
    INTERNET_STATUS_P3P_HEADER: OnP3PHeader;
    INTERNET_STATUS_P3P_POLICYREF: OnP3pPolicyRef;
    INTERNET_STATUS_COOKIE_HISTORY: OnCookieHistory(PInternetCookieHistory(Info));
  end;
end;

function TGLInetConnection.Connect(Host: PChar; Port: Word; Service: DWORD;
  Username, Password: PAnsiChar; Flags: DWORD; pError: PInteger): Boolean;
begin
  if Assigned(fConnection) then
  begin
    Result := True;
    Exit;
  end;
  Context.Open;
  fConnection := InternetConnectA(fContext.Handle, Host, Port,
    Username, Password, Service, Flags, DWORD(Self));
  Result := fConnection <> INET_NULL_HANDLE;
  if not Result then
  begin
    if Assigned(pError) then pError^ := GetLastError
    else SysUtils.RaiseLastOSError;
  end;
end;

destructor TGLInetConnection.Destroy;
begin
  if Assigned(fContext) and fOwnedContext then
  begin
    fContext.Cleanup;
    Dispose(fContext);
  end;  
  inherited;
end;

function TGLInetConnection.GetContext: PGLInetContext;
begin
  AccquireContext;
  Result := fContext;
end;

procedure TGLInetConnection.OnConnected(EndPoint: PSockAddr);
begin

end;

procedure TGLInetConnection.OnConnecting(EndPoint: PSockAddr);
begin

end;

procedure TGLInetConnection.OnCookieHistory(CookieHistory: PInternetCookieHistory);
begin

end;

procedure TGLInetConnection.OnCookieRecved;
begin

end;

procedure TGLInetConnection.OnCookieSent;
begin

end;

procedure TGLInetConnection.OnCtlRespRecved;
begin

end;

procedure TGLInetConnection.OnDetectingProxy;
begin

end;

procedure TGLInetConnection.OnDisconnecting;
begin

end;

procedure TGLInetConnection.OnDisconneted;
begin

end;

procedure TGLInetConnection.OnHandleClosing;
begin

end;

procedure TGLInetConnection.OnHandleCreated(Error: Integer; Handle: HINTERNET);
begin

end;

procedure TGLInetConnection.OnIntermediateResponse;
begin

end;

procedure TGLInetConnection.OnNameResolved;
begin

end;

procedure TGLInetConnection.OnP3PHeader;
begin

end;

procedure TGLInetConnection.OnP3pPolicyRef;
begin

end;

procedure TGLInetConnection.OnPrefetch;
begin

end;

procedure TGLInetConnection.OnPrivacyImpacted;
begin

end;

procedure TGLInetConnection.OnRecvingResponse;
begin

end;

procedure TGLInetConnection.OnRedirect(Url: PAnsiChar);
begin

end;

procedure TGLInetConnection.OnCallComplete(ReturnValue: Boolean; Error: Integer);
begin

end;

procedure TGLInetConnection.OnRequestSent(BytesSent: Integer);
begin

end;

procedure TGLInetConnection.OnResolvingName;
begin

end;

procedure TGLInetConnection.OnResponseRecved(BytesRecved: Integer);
begin

end;

procedure TGLInetConnection.OnSendingRequest;
begin

end;

procedure TGLInetConnection.OnStateChange;
begin

end;

procedure TGLInetConnection.OnUserInputRequired;
begin

end;

procedure TGLInetConnection.SetContext(const Value: PGLInetContext);
begin
  if (Value = nil) or (fContext = Value) then Exit;
  if Assigned(fContext) and fOwnedContext then
  begin
    fContext.Cleanup;
    Dispose(fContext);
  end;
  fContext := Value;
  fOwnedContext := False;
end;

{ TXUrlComponents }

function AnsiStrFromBuf(Buf: Pointer; BufLen: Integer): AnsiString;
begin
  SetLength(Result, BufLen);
  if BufLen = 0 then Exit;
  Move(Buf^, Pointer(Result)^, BufLen);
end;

function TXUrlComponents.Host: AnsiString;
begin
  Result := AnsiStrFromBuf(HostPtr, HostLen);
end;

function TXUrlComponents.Params: AnsiString;
begin
  Result := AnsiStrFromBuf(ParamsPtr, ParamsLen);
end;

function TXUrlComponents.Password: AnsiString;
begin
  Result := AnsiStrFromBuf(PasswordPtr, PasswordLen);
end;

function TXUrlComponents.Path: AnsiString;
begin
  Result := AnsiStrFromBuf(PathPtr, PathLen);
end;

function TXUrlComponents.PathWithParams: AnsiString;
begin
  Result := AnsiStrFromBuf(PathPtr, PathLen + ParamsLen);
end;

function TXUrlComponents.UserName: AnsiString;
begin
  Result := AnsiStrFromBuf(UserNamePtr, UserNameLen);
end;

end.
