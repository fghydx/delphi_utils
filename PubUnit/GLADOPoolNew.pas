unit GLADOPoolNew;

interface

uses GLObjectPoolNew,ADODB, Classes;

type
  TGLADOPoolNew = class(TGLObjectPoolNew)
  private
    FConnectString: WideString;
    procedure SetConnectString(const Value: WideString);
  public
    constructor Create(AOwner: TComponent);
    function DoReInit(var Aobj: Tobject):Boolean; override;
    function DoCreateObj(var Aobj: Tobject):Boolean; override;
    function GetObj: TADOConnection;                 //从池中获取一个对像
    procedure PutObj(AObj: TADOConnection; PutType: TPutOption);
    property ConnectString: WideString read FConnectString write SetConnectString;
  end;

implementation

uses ActiveX,GLLogger,GLPubFunc,SysUtils;

constructor TGLADOPoolNew.Create(AOwner: TComponent);
begin
  inherited;
  ObjClass := TADOConnection;
  // TODO -cMM: TGLADOPoolNew.Create default body inserted
end;

{ TGLADOPoolNew }

function TGLADOPoolNew.DoCreateObj(var Aobj: Tobject): Boolean;
begin
  Result := False;
  CoInitialize(nil);
  try
    Aobj := TADOConnection.Create(Self);
    TADOConnection(Aobj).ConnectionTimeout := 180;
    if InitWhenCreate then
    begin
      Result := DoReInit(Aobj);
    end;
    if not Result then
    begin
      Exit;
    end;
  finally
    CoUninitialize;
  end;
  Result := inherited DoCreateObj(Aobj);
end;

function TGLADOPoolNew.DoReInit(var Aobj: Tobject):Boolean;
begin
  Result := false;
  if Aobj=nil then
  begin
    exit;
  end;

  CoInitialize(nil);
  try
    try
      with TADOConnection(Aobj) do
      begin
        Close;
        KeepConnection := True;
        LoginPrompt := False;
        ConnectionString := FConnectString;
        Connected := True;
      end;
    except
      Result := False;
      Logger.WriteLog(LTError,Exception(ExceptObject).Message);
      Exit;
    end;
  finally
    CoUninitialize;
  end;
  Result := inherited DoReInit(Aobj);
end;

function TGLADOPoolNew.GetObj: TADOConnection;
var
  tem:TObject;
begin
  Result := nil;
  tem := inherited GetObj;
  if tem<>nil then
    Result := Tem as TADOConnection;
end;

procedure TGLADOPoolNew.PutObj(AObj: TADOConnection; PutType: TPutOption);
begin
  inherited PutObj(AObj,PutType);
end;

procedure TGLADOPoolNew.SetConnectString(const Value: WideString);
begin
  FConnectString := Value;
end;

end.
