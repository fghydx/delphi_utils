unit GLADOConPool;

interface

uses
  Windows, Messages, SysUtils, Classes, GLObjectPool, ADODB;

type
  TGLADOConWrapper = class(TGLObjectWrapper)
  private
    function GetConnection: TADOConnection;
  public
    property Connection: TADOConnection read GetConnection;
  end;

  /// <remarks>
  /// ADOÁ¬½Ó³Ø
  /// </remarks>
  TGLADOConPool = class(TGLCustomObjectPool)
  private
    FConnectionString: WideString;
    procedure SetConnectionString(const Value: WideString);
  protected
    function DoCreateOne(Wrapper: TGLObjectWrapper;
      var Obj: TObject): Boolean; override;
    function DoFreeOne(Wrapper: TGLObjectWrapper;
      var Obj: TObject): Boolean; override;
    function DoGetOne(Wrapper: TGLObjectWrapper;
      var Obj: TObject): Boolean; override;
    function DoReleaseOne(Wrapper: TGLObjectWrapper;
      var Obj: TObject): Boolean; override;
    function DoReInitOne(Wrapper: TGLObjectWrapper;
      var Obj: TObject): Boolean; override;

  public
    function GetConnection(var con: TADOConnection;
      const go: TGLObjectPoolGetOption = goNone): TGLObjectPoolGetResult;
    procedure ReleaseConnection(var con: TADOConnection;
      const ro: TGLObjectPoolReleaseOption = roNone);
  published
    property ConnectionString: WideString
      read FConnectionString
      write SetConnectionString;
    property MinSize;
    property MaxSize;
    property LowLoadCount;
    property PeakCount;
    property PolicyOnBusy;
    property PolicyOnPeak;
    property PolicyOnGet;
    property WaitTimeOut;

    property OnGetOne;
    property OnReleaseOne;
    property OnReInitOne;
  end;

implementation

uses
  ActiveX,
  ComObj;

{ TGLADOConWrapper }

function TGLADOConWrapper.GetConnection: TADOConnection;
begin
  Result := nil;
  if Assigned(ObjectWrapped) then
    Result := TADOConnection(ObjectWrapped);
end;

{ TGLADOConPool }

function TGLADOConPool.DoCreateOne(Wrapper: TGLObjectWrapper;
  var Obj: TObject): Boolean;
begin
  csObjectMgr.Enter;
  try
    CoInitialize(nil);
    try
      Obj := TADOConnection.Create(Self);
      with TADOConnection(Obj) do
      begin
        KeepConnection := True;
        LoginPrompt := False;
        ConnectionString := Self.ConnectionString;
      end;

      Result := inherited DoCreateOne(Wrapper, Obj);

      if Assigned(Wrapper) then
        TGLADOConWrapper(Wrapper).NeedReInit := True;
    finally
      CoUninitialize;
    end;
  finally
    csObjectMgr.Leave;
  end;
end;

function TGLADOConPool.DoFreeOne(Wrapper: TGLObjectWrapper;
  var Obj: TObject): Boolean;
begin
  csObjectMgr.Enter;
  try
    Result := inherited DoFreeOne(Wrapper, Obj);
  finally
    csObjectMgr.Leave;
  end;
end;

function TGLADOConPool.DoGetOne(Wrapper: TGLObjectWrapper;
  var Obj: TObject): Boolean;
begin
  csObjectMgr.Enter;
  try
    Result := inherited DoGetOne(Wrapper, Obj);
  finally
    csObjectMgr.Leave;
  end;
end;

function TGLADOConPool.DoReInitOne(Wrapper: TGLObjectWrapper;
  var Obj: TObject): Boolean;
begin
  Result := True;
  
  csObjectMgr.Enter;
  try
    CoInitialize(nil);
    try
      with TADOConnection(Obj) do
      begin
        Connected := False;
        KeepConnection := True;
        LoginPrompt := False;
        ConnectionString := Self.ConnectionString;
        try
          Connected := True;
        except
          Result := False;
        end;
      end;

      Result := (inherited DoReInitOne(Wrapper, Obj)) and Result;

      if not Result then
        TGLADOConWrapper(Wrapper).NeedReInit := True;

    finally
      CoUninitialize;
    end;
  finally
    csObjectMgr.Leave;
  end;
end;

function TGLADOConPool.DoReleaseOne(Wrapper: TGLObjectWrapper;
  var Obj: TObject): Boolean;
begin
  csObjectMgr.Enter;
  try
    Result := inherited DoReleaseOne(Wrapper, Obj);
  finally
    csObjectMgr.Leave;
  end;
end;

function TGLADOConPool.GetConnection(var con: TADOConnection;
  const go: TGLObjectPoolGetOption): TGLObjectPoolGetResult;
var
  Obj: TObject;
begin
  Result := GetOne(Obj, go);
  if Obj is TADOConnection then
    con := TADOConnection(Obj)
  else
  begin
    if Obj <> nil then
      ReleaseOne(Obj, roFree);
    con := nil;
    Result := grGetError;
  end;
end;

procedure TGLADOConPool.ReleaseConnection(var con: TADOConnection;
  const ro: TGLObjectPoolReleaseOption);
begin
  ReleaseOne(con, ro);
end;

procedure TGLADOConPool.SetConnectionString(const Value: WideString);
begin
  csObjectMgr.Enter;
  try
    FConnectionString := Value;
    ReInitAll;
  finally
    csObjectMgr.Leave;
  end;
end;

end.
