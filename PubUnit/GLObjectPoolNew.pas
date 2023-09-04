/// <remarks>
/// �����
/// </remarks>
unit GLObjectPoolNew;         

interface

uses Classes,SyncObjs,Windows,GLSyncObj;

type
  TObjectClass = class of Tobject;
  TObjectState = (OSIdle,OSBusy);

  TPutOption = (PONone,PONeedInit,POFree);     //�������ӽ���ʱ�Ĳ���,ʲô���������´�ʹ��Ҫ��ʼ����ֱ���ͷŵ�

  TOnReinit = function(var Aobj: Tobject): Boolean of object;

  TObjectItem = record
    ObjectState:TObjectState;                  //����״̬
    RefCount : Cardinal;                       //���ü���
    RunCount : Cardinal;                       //���񱻵��ô���
    RunTimes : Cardinal;                       //����ִ�к�ʱʱ��
     PopTime : Cardinal;                       //��������ȥʱ��ʱ�䣬���ڼ���ִ��ʱ��
    NeedInit : Boolean;                        //��Ҫ��ʼ������
    InitCount: integer;                        //��ʼʼ������
  LastRunTime:TDateTime;
       Status: String;
      CanUse : Boolean;                        //�Ƿ����
         obj : TObject;                        //����
  end;
  PObjectItem = ^TObjectItem;

  TGLObjectPoolNew = class(TComponent)
  private
    FLocker:TCriticalSection;
    Semaphore:TGLSemaphore;                    //�ź���
    FCanMultRun: Boolean;                    //�����Ƿ����ͬʱ�������
    FIdleCount: Integer;                     //���и���
    FInitWhenCreate: Boolean;                //����ʱ��ʼ��
    FobjCount: Integer;
    FCreateCount:Integer;                    //�������������
    FFreeCount:Integer;                      //���ͷŶ������ 
    FMax: cardinal;
    FMaxRef: Cardinal;                       //���������������ü���
    FMin: Cardinal;                          //�������ٶ������
    FObjects : TList;                        //�Ŷ���
    FObjClass:TObjectClass;                  //��������
    FOnCreateObj: TOnReinit;
    FOnReinit: TOnReinit;
    FWaitForIdleObj: Boolean;                //�Ƿ�ȴ�ֱ���п��ж���
    function GetItems(Index: Integer): TObject; //��ȡһ�����񣬲���״̬�����ܻ�ȡ
    procedure SetMin(const Value: Cardinal);

    function GetOneObj:TObject;
  public
    function GetInfo:string;
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function GetObj: TObject;overload;                 //�ӳ��л�ȡһ������
    function GetObj(Index:Integer): TObject;overload;  //��ȡָ����ŵĶ���
    procedure PutObj(AObj: TObject; PutType: TPutOption);

    function DoReInit(var Aobj: Tobject): Boolean; virtual;
    function DoCreateObj(var Aobj: Tobject): Boolean;virtual;

    property CanMultRun: Boolean read FCanMultRun write FCanMultRun;
    property objCount: Integer read FobjCount;
    property IdleCount: Integer read FIdleCount write FIdleCount;
    property InitWhenCreate: Boolean read FInitWhenCreate write FInitWhenCreate;
    property Items[Index: Integer]: TObject read GetItems;
    property Max: cardinal read FMax write FMax;
    property MaxRef: Cardinal read FMaxRef write FMaxRef;
    property Min: Cardinal read FMin write SetMin;
    property ObjClass: TObjectClass read FObjClass write FObjClass;
    property WaitForIdleObj: Boolean read FWaitForIdleObj write FWaitForIdleObj;
    property OnCreateObj: TOnReinit read FOnCreateObj write FOnCreateObj;
    property OnReinit: TOnReinit read FOnReinit write FOnReinit;
  end;

const
  ObjectStateStr : array[0..1] of string=('����','æµ');

implementation

uses GLPubFunc,SysUtils,ActiveX;

constructor TGLObjectPoolNew.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanMultRun := False;
  FMaxRef := 10;
  FInitWhenCreate := True;
  Fobjects := TList.Create;
  FLocker := TCriticalSection.Create;
  FWaitForIdleObj := true;
  Semaphore := TGLSemaphore.Create();
end;

destructor TGLObjectPoolNew.Destroy;
var
  I: Integer;
  ObjectItem : PObjectItem;
begin
  Semaphore.SetEvent(MaxInt);
  FLocker.Enter;
  try
    for I := FObjects.Count - 1 downto 0 do
    begin

      ObjectItem := FObjects.Items[I];
      if ObjectItem.RefCount<=0 then         //�п��ܳ��ͷ��ˣ��������ط�����������������Լ�����������ط������ͷŻ������õ��Ǹ�����
      begin
        ObjectItem.obj.Free;
      end;
      FObjects.Remove(ObjectItem);
      Dispose(ObjectItem);
      InterlockedIncrement(FFreeCount);
    end;
  finally
    FLocker.Leave;
  end;
  Fobjects.Free;
  FLocker.Free;
  Semaphore.Free;
  inherited;
end;

function TGLObjectPoolNew.DoReInit(var Aobj: Tobject): Boolean;
begin
  Result := true;
  if Assigned(FOnReinit) then
    Result := FOnReinit(Aobj);
end;

function TGLObjectPoolNew.GetInfo: string;
var
  I: Integer;
  ObjectItem : PObjectItem;
  AvgTime:integer;
begin
  FLocker.Enter;
  try
    Result := '����������Ϣ��'#13#10+
              '���ж��������'+inttostr(FObjects.Count)+#13#10+
              '��������ֵ��'+inttostr(Max)+#13#10+
              '�������Сֵ��'+inttostr(Min)+#13#10+
              '���ж��������'+inttostr(FIdleCount)+#13#10+
              '����ض����ࣺ'+FObjClass.ClassName+#13#10+
              '�����������: '+inttostr(FCreateCount)+#13#10+
              '�ͷŶ������: '+inttostr(FFreeCount)+#13#10+
              '���������Ƿ�ɶ�����ã�'+BoolToStr(FCanMultRun,True)+#13#10+
              '��������Ϣ��--------------'+#13#10;
    for I := 0 to FObjects.Count - 1 do
    begin
      ObjectItem := FObjects[I];
      if ObjectItem.RunCount>0 then
        AvgTime := Trunc(ObjectItem.RunTimes/ObjectItem.RunCount)
      else
        AvgTime := 0;
      Result := Result + '�����ַ��'+ IntToHex(Cardinal(ObjectItem.obj),8)+'   '+
                         '״̬��'+ ObjectStateStr[Integer(ObjectItem.ObjectState)]+'   '+
                         '����ʹ�ü�����'+inttostr(ObjectItem.RefCount)+'   '+
                         '���д�����'+inttostr(ObjectItem.RunCount)+'   '+
                         '�ܹ�����ʱ����'+inttostr(ObjectItem.RunTimes)+'   '+
                         '��ʼ������: '+inttostr(ObjectItem.InitCount)+'   '+
                         'ƽ������ʱ����'+inttostr(AvgTime)+'   '+
                         '���ִ��ʱ�䣺'+DateTimeToStr(ObjectItem.LastRunTime)+'  '+
                         '��ǰ����״̬��'+BoolToStr(ObjectItem.CanUse,True)+#13#10;
    end;
  finally
    FLocker.Leave;
  end;
end;

function TGLObjectPoolNew.GetObj: TObject;
begin
  Result := GetOneObj;
end;

function TGLObjectPoolNew.GetObj(Index: Integer): TObject;
var
  ObjectItem : PObjectItem;
begin
  Result := nil;
  FLocker.Enter;
  try
    if Index>FObjects.Count-1 then Exit;

    ObjectItem := FObjects.Items[Index];
    if ObjectItem.CanUse then
    begin
      Inc(ObjectItem.RefCount);
      if FCanMultRun then
      begin
        if ObjectItem.RefCount>MaxRef then
        begin
          ObjectItem.CanUse := False;
        end;
      end else
      begin
        ObjectItem.CanUse := False;
      end;
      ObjectItem.PopTime := GetTickCount;

      Result := ObjectItem.obj;

      Dec(FIdleCount);

      if Result<>nil then
      begin
        if ObjectItem.NeedInit then
        begin
          if DoReInit(Result) then
          begin
            Inc(ObjectItem.InitCount);
            ObjectItem.NeedInit := False;
          end else       //�����ʼ��ʧ��,�ͷŵ�
          begin
            FObjects.Delete(Index);
            Result.Free;
            Dispose(ObjectItem);
            InterlockedIncrement(FFreeCount);
            Exit;
          end;
        end;
      end else
      begin
        FObjects.Delete(Index);
        Dispose(ObjectItem);
        InterlockedIncrement(FFreeCount);
        Exit;
      end;
      ObjectItem.ObjectState := OSBusy;
      ObjectItem.LastRunTime := Now;
      ObjectItem.Status := 'GetObj('+inttostr(Index)+')->';
    end;
  finally
    FLocker.Leave;
  end;
end;

function TGLObjectPoolNew.GetOneObj: TObject;

  procedure ProcessObjitem(ObjectItem:PObjectItem);
  begin
    Inc(ObjectItem.RefCount);
    if FCanMultRun then
    begin
      if ObjectItem.RefCount>MaxRef then
      begin
        ObjectItem.CanUse := False;
      end;
    end else
    begin
      ObjectItem.CanUse := False;
    end;
    ObjectItem.PopTime := GetTickCount;
  end;

var
  I: Integer;
  ObjectItem : PObjectItem;
  Geted:Boolean;
begin
  Result := nil;
  ObjectItem := nil;
  Geted := false;

  if FWaitForIdleObj and (objCount>=Max) then
    Semaphore.WaitForSign();

  FLocker.Enter;
  try
    for I := 0 to FObjects.Count - 1 do
    begin
      ObjectItem := PObjectItem(FObjects.Items[I]);
      if ObjectItem.CanUse then
      begin
        Geted := True;
        Break;
      end;
      ObjectItem :=nil;
    end;
    if not Geted then      //�������û�л�ȡ��
    begin
      if FObjects.Count<Max then
      begin
        New(ObjectItem);
        ZeroMemory(ObjectItem,SizeOf(TObjectItem));
        InterlockedIncrement(FCreateCount);
        if DoCreateObj(ObjectItem.obj) then
        begin
          ObjectItem.NeedInit := True;
          FObjects.Add(ObjectItem);
        end else
        begin
          if ObjectItem.obj<>nil then
            ObjectItem.obj.Free;
          Dispose(ObjectItem);
          ObjectItem := nil;
          InterlockedIncrement(FFreeCount);
        end;
      end;
    end;

    if ObjectItem<>nil then
    begin
      Dec(FIdleCount);

      Result := ObjectItem.obj;
      if Result<>nil then
      begin
        if ObjectItem.NeedInit then
        begin
          if DoReInit(Result) then
          begin
            Inc(ObjectItem.InitCount);
            ObjectItem.NeedInit := False;
          end else       //�����ʼ��ʧ��,�ͷŵ�
          begin
            FObjects.Remove(ObjectItem);
            Result.Free;
            Dispose(ObjectItem);
            InterlockedIncrement(FFreeCount);
            Exit;
          end;
        end;
      end else
      begin
        FObjects.Remove(ObjectItem);
        Dispose(ObjectItem);
        InterlockedIncrement(FFreeCount);
        Exit;
      end;
      ProcessObjitem(ObjectItem);
      ObjectItem.ObjectState := OSBusy;
      ObjectItem.LastRunTime := Now;
      ObjectItem.Status := 'GetOneObj->';
    end;
  finally
    FLocker.Leave;
  end;
end;

function TGLObjectPoolNew.DoCreateObj(var Aobj: Tobject): Boolean;
begin
  Result := True;
  if Assigned(FOnCreateObj) then
    Result := FOnCreateObj(Aobj);
  Inc(FIdleCount);
  Inc(FobjCount);
  if FWaitForIdleObj then
    Semaphore.SetEvent();
end;

function TGLObjectPoolNew.GetItems(Index: Integer): TObject;
begin
  Result := PObjectItem(FObjects.Items[Index]).obj;
end;

procedure TGLObjectPoolNew.PutObj(AObj: TObject; PutType: TPutOption);

  procedure ProcessObjItem(ObjectItem:PObjectItem);
  begin
    Dec(ObjectItem.RefCount);
    inc(ObjectItem.RunCount);
    ObjectItem.RunTimes := ObjectItem.RunTimes + GetTickCountDiff(ObjectItem.PopTime,GetTickCount);
    ObjectItem.NeedInit := PutType = PONeedInit;
    ObjectItem.CanUse := True;
  end;

var
  ObjectItem : PObjectItem;
  I: Integer;
  InPool:Boolean;
begin
  InPool := false;
  FLocker.Enter;
  try
    for I := 0 to FObjects.Count - 1 do
    begin
      ObjectItem := FObjects.Items[I];
      if ObjectItem.obj = AObj then
      begin
        ObjectItem.Status := ObjectItem.Status + 'PutObj�ڳ���';
        if PutType = POFree then
        begin
          ObjectItem.Status := ObjectItem.Status + ' POFree�ͷ�';
          ObjectItem.obj.Free;
          FObjects.Remove(ObjectItem);
          Dispose(ObjectItem);
          Dec(FobjCount);
          InterlockedIncrement(FFreeCount);
          Exit;
        end else
        begin
          ObjectItem.Status := ObjectItem.Status + ' �Żس���';
          ProcessObjItem(ObjectItem);
          ObjectItem.Status := ObjectItem.Status + ' O';
        end;
        InPool := True;
        break;
      end;
    end;

    if not InPool then
    begin
      ObjectItem.Status := ObjectItem.Status + 'PutObj���ڳ���';
      if (PutType = POFree) or (FObjects.Count>=Max) then
      begin
        ObjectItem.Status := ObjectItem.Status + ' POFree�ͷ�';
        AObj.Free;
        AObj := nil;
        Exit;
      end else
      begin
        ObjectItem.Status := ObjectItem.Status + ' ��ӽ�����';
        New(ObjectItem);
        ZeroMemory(ObjectItem,SizeOf(TObjectItem));
        ObjectItem.obj := AObj;
        ObjectItem.RefCount := 0;
        ObjectItem.RunCount := 1;
        ObjectItem.RunTimes := 0 ;
        ObjectItem.NeedInit := PutType = PONeedInit;
        ObjectItem.CanUse := True;
        FObjects.Add(ObjectItem);
        inc(FobjCount);
      end;
    end;
    ObjectItem.Status := ObjectItem.Status + ' ״̬��Ϊ����';
    ObjectItem.ObjectState := OSIdle;
    Inc(FIdleCount);
    if FWaitForIdleObj then
      Semaphore.SetEvent();
  finally
    FLocker.Leave;
  end;
end;

procedure TGLObjectPoolNew.SetMin(const Value: Cardinal);
var
  I: Integer;
  ObjectItem : PObjectItem;
begin
  FMin := Value;
  if FObjects.Count<FMin then
  begin
    for I := 0 to FMin - FObjects.Count - 1 do
    begin
      New(ObjectItem);
      ZeroMemory(ObjectItem,SizeOf(TObjectItem));
      InterlockedIncrement(FCreateCount);
      
      if DoCreateObj(ObjectItem.Obj) then
      begin
        ObjectItem.RefCount := 0;
        ObjectItem.RunCount := 0;
        ObjectItem.RunTimes := 0 ;
        if InitWhenCreate then
        begin
          ObjectItem.InitCount := 1;
          ObjectItem.NeedInit := False;
        end
        else
          ObjectItem.NeedInit := True;
        ObjectItem.CanUse := True;
        FObjects.Add(ObjectItem);
      end else
      begin
        if ObjectItem.Obj<>nil then
          ObjectItem.Obj.Free;
        Dispose(ObjectItem);
        InterlockedIncrement(FFreeCount);
      end;
    end;
  end;
end;

end.
