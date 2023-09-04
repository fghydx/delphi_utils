/// <remarks>
/// 对像池
/// </remarks>
unit GLObjectPoolNew;         

interface

uses Classes,SyncObjs,Windows,GLSyncObj;

type
  TObjectClass = class of Tobject;
  TObjectState = (OSIdle,OSBusy);

  TPutOption = (PONone,PONeedInit,POFree);     //将对像扔进池时的参数,什么都不做、下次使用要初始化，直接释放掉

  TOnReinit = function(var Aobj: Tobject): Boolean of object;

  TObjectItem = record
    ObjectState:TObjectState;                  //对像状态
    RefCount : Cardinal;                       //引用计数
    RunCount : Cardinal;                       //对像被调用次数
    RunTimes : Cardinal;                       //对像执行耗时时长
     PopTime : Cardinal;                       //对像拉出去时的时间，用于计算执行时长
    NeedInit : Boolean;                        //需要初始化对像
    InitCount: integer;                        //初始始化次数
  LastRunTime:TDateTime;
       Status: String;
      CanUse : Boolean;                        //是否可用
         obj : TObject;                        //对像
  end;
  PObjectItem = ^TObjectItem;

  TGLObjectPoolNew = class(TComponent)
  private
    FLocker:TCriticalSection;
    Semaphore:TGLSemaphore;                    //信号量
    FCanMultRun: Boolean;                    //对像是否可以同时多次引用
    FIdleCount: Integer;                     //空闲个数
    FInitWhenCreate: Boolean;                //创建时初始化
    FobjCount: Integer;
    FCreateCount:Integer;                    //共创建对像个数
    FFreeCount:Integer;                      //共释放对像个数 
    FMax: cardinal;
    FMaxRef: Cardinal;                       //单个对像的最大引用计数
    FMin: Cardinal;                          //池中最少对像个数
    FObjects : TList;                        //放对像
    FObjClass:TObjectClass;                  //对像类型
    FOnCreateObj: TOnReinit;
    FOnReinit: TOnReinit;
    FWaitForIdleObj: Boolean;                //是否等待直到有空闲对像
    function GetItems(Index: Integer): TObject; //获取一个对像，不论状态，都能获取
    procedure SetMin(const Value: Cardinal);

    function GetOneObj:TObject;
  public
    function GetInfo:string;
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function GetObj: TObject;overload;                 //从池中获取一个对像
    function GetObj(Index:Integer): TObject;overload;  //获取指定序号的对像
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
  ObjectStateStr : array[0..1] of string=('空闲','忙碌');

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
      if ObjectItem.RefCount<=0 then         //有可能池释放了，但其它地方还在用这个对像，所以加这个，其它地方自已释放还在引用的那个对像
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
    Result := '任务对像池信息：'#13#10+
              '池中对像个数：'+inttostr(FObjects.Count)+#13#10+
              '对像池最大值：'+inttostr(Max)+#13#10+
              '对像池最小值：'+inttostr(Min)+#13#10+
              '空闲对像个数：'+inttostr(FIdleCount)+#13#10+
              '对像池对像类：'+FObjClass.ClassName+#13#10+
              '创建对像个数: '+inttostr(FCreateCount)+#13#10+
              '释放对像个数: '+inttostr(FFreeCount)+#13#10+
              '单个对像是否可多次引用：'+BoolToStr(FCanMultRun,True)+#13#10+
              '各对像信息：--------------'+#13#10;
    for I := 0 to FObjects.Count - 1 do
    begin
      ObjectItem := FObjects[I];
      if ObjectItem.RunCount>0 then
        AvgTime := Trunc(ObjectItem.RunTimes/ObjectItem.RunCount)
      else
        AvgTime := 0;
      Result := Result + '对像地址：'+ IntToHex(Cardinal(ObjectItem.obj),8)+'   '+
                         '状态：'+ ObjectStateStr[Integer(ObjectItem.ObjectState)]+'   '+
                         '正在使用计数：'+inttostr(ObjectItem.RefCount)+'   '+
                         '运行次数：'+inttostr(ObjectItem.RunCount)+'   '+
                         '总共运行时长：'+inttostr(ObjectItem.RunTimes)+'   '+
                         '初始化次数: '+inttostr(ObjectItem.InitCount)+'   '+
                         '平均单次时长：'+inttostr(AvgTime)+'   '+
                         '最后执行时间：'+DateTimeToStr(ObjectItem.LastRunTime)+'  '+
                         '当前可用状态：'+BoolToStr(ObjectItem.CanUse,True)+#13#10;
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
          end else       //如果初始化失败,释放掉
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
    if not Geted then      //如果池中没有获取到
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
          end else       //如果初始化失败,释放掉
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
        ObjectItem.Status := ObjectItem.Status + 'PutObj在池中';
        if PutType = POFree then
        begin
          ObjectItem.Status := ObjectItem.Status + ' POFree释放';
          ObjectItem.obj.Free;
          FObjects.Remove(ObjectItem);
          Dispose(ObjectItem);
          Dec(FobjCount);
          InterlockedIncrement(FFreeCount);
          Exit;
        end else
        begin
          ObjectItem.Status := ObjectItem.Status + ' 放回池中';
          ProcessObjItem(ObjectItem);
          ObjectItem.Status := ObjectItem.Status + ' O';
        end;
        InPool := True;
        break;
      end;
    end;

    if not InPool then
    begin
      ObjectItem.Status := ObjectItem.Status + 'PutObj不在池中';
      if (PutType = POFree) or (FObjects.Count>=Max) then
      begin
        ObjectItem.Status := ObjectItem.Status + ' POFree释放';
        AObj.Free;
        AObj := nil;
        Exit;
      end else
      begin
        ObjectItem.Status := ObjectItem.Status + ' 添加进池中';
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
    ObjectItem.Status := ObjectItem.Status + ' 状态改为可用';
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
