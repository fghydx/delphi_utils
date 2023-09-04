unit GLTimeWheel;

interface

{.$DEFINE WriteLog}

uses GLSyncObj,Classes,GLHashTableEx,SyncObjs,GLStreamPatch,Winapi.MMSystem
{$IFDEF DEBUG32}
       ,madExcept,madKernel
{$EndIF}
     ;

type
  //ʱ���������������
  PTimeWheelItem = ^TTimeWheelItem;
  TTimeWheelItem = record
    Scales:Word;                  //����ڵڼ���
    turns:Integer;                //ת��
    TimeOut:Cardinal;             //��ʱʱ��
    Data:Pointer;                 //����
    DataLen:integer;              //���ݳ���
    RefTimes:integer;             //���ü��������磬һ�����ݣ�find�����õ�ʱ��ʱ�䵽�ˣ�����ͷŵ�������ݣ���ٳɷǷ�����
    NextItem:PTimeWheelItem;
    PrveItem:PTimeWheelItem;
    case b:Boolean of
      true:(IntKey:Cardinal);
      false:(StrKey:Pchar);
  end;

  TOnTimeOut = function (Key:Pointer;Data:Pointer):Boolean of object;
  TOnDelItemData = Procedure (Data:Pointer) of object;
  /// <remarks>
  /// ʱ����
  /// </remarks>
  TGLTimeWheelCustom = class
  private
    Fcaption:string;
    TimeOutHashTBL:TGLIntHashTable;
    Fstarted:Boolean;                  //�����У���ֹ�ظ�Start����Ƶ�ʳ����ȴ���
    FTimer:MMRESULT;
    Fstoped:Boolean;
    FFreeEvent:TEvent;
    FAddCount: Integer;                 //ʣ�¶��ٸ�û��ʱ��
    FContentSize: cardinal;
    Locker:TGLCriticalSection;
    FCurScale:Word;                //��ָ�룬������һ��,��ǰָ��Ŀ̶�
    FOnDeleteItem: TOnDelItemData;
    FOnTimeOut: TOnTimeOut;        //��ʱʱ����
    FReTimingAfterProc: Boolean;
    FRollRate: Cardinal;           //ת��Ƶ�ʣ����ָ��ת��һ�Σ���λΪ���롣
    FScaleCount: Word;             //���̶�����
    FScales : array of PTimeWheelItem;         //ÿ���̶��Ϸŵ�����
    procedure InitATimeWheelItem(TimeWheelItem:PTimeWheelItem);
    function AddTimeWheelItem(TimeOut: Cardinal; TimeWheelItem: PTimeWheelItem):Boolean;
    procedure SetScaleCount(const Value: Word);
    function GetScale(Value:Word):Word;        //��ȡ����Ӧ���ĸ��̶���

    procedure clear;                          //ÿ�����ص�Data�������ⲿ���ݣ�����û���������ͷš�
    procedure CheckTimeOut;
    function DeleteItem(Key:string; var NextItem: PTimeWheelItem): Boolean;overload;     //����ɾ��Ԫ�ص���һ��Ԫ��
    function DeleteItem(Key:Cardinal ; var NextItem: PTimeWheelItem): Boolean;overload;   //����ɾ��Ԫ�ص���һ��Ԫ��
  protected
    function FindAWheelItem(Key:string):PTimeWheelItem;overload;virtual; abstract;
    function FindAWheelItem(Key:Cardinal):PTimeWheelItem;overload;virtual; abstract;
    procedure TBLDeleteKey(Key:string);overload;virtual;abstract;
    procedure TBLDeleteKey(Key:Cardinal);overload;virtual;abstract;
    function TBLAddData(Key:string;Data:Pointer):Boolean;overload;virtual;abstract;
    function TBLAddData(Key:Cardinal;Data:Pointer):Boolean;overload;virtual;abstract;
    procedure Tblclear;virtual;abstract;

    function DeleteWheelItem(AWheelItem: PTimeWheelItem; var NextItem: PTimeWheelItem): Boolean; //����ɾ��Ԫ�ص���һ��Ԫ��

    function Add(TimeOut: cardinal; Key1:string;Key2:Cardinal; Data: Pointer;
        DataLen:Integer):Boolean;
    procedure Update(TimeOut:Cardinal;Key1:string;Key2:Cardinal);
    /// <summary>TGLTimeWheelCustom.Find
    /// </summary>
    /// <returns> Pointer
    /// </returns>
    /// <param name="Key1"> (string) </param>
    /// <param name="Key2"> (Cardinal) </param>
    /// <param name="NeedGiveBack">True����ȡ���ݵ�һ����������Ҫ�����ͷ�</param>
    function Find(Key1: string; Key2: Cardinal; out DataLen: Integer; NeedGiveBack:
        Boolean = false): Pointer;
    function Delete(Key1: string; Key2: Cardinal):Boolean;
  public
    constructor Create;virtual;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    function Exist(Key:string):Boolean;overload;
    function Exist(Key:Cardinal):Boolean;overload;

    procedure SaveToFile(FileName: string);virtual;abstract;
    procedure LoadFromFile(FileName: string);virtual;abstract;

    function DoOnTimeOut(Key:Pointer;Data:Pointer): Boolean; virtual;
    procedure DoDeleteItem(Data:Pointer);virtual;

    procedure GiveBackData(Key1: string; Key2: Cardinal; Data: Pointer);
    procedure FreeData(P:Pointer);

    /// <remarks>
    /// ���볬ʱ��ʣ�¶��ٺ���
    /// </remarks>
    function GetLeaveTimeOutTimes(Key1:string;Key2:Cardinal):Int64;

    procedure Start;
    procedure Stop;
    property OnTimeOut: TOnTimeOut read FOnTimeOut write FOnTimeOut;
    property OnDeleteItem: TOnDelItemData read FOnDeleteItem write FOnDeleteItem;
    property AddCount: Integer read FAddCount;
    property ContentSize: cardinal read FContentSize write FContentSize;
    /// <remarks>
    /// ִ����ص����̺����¿�ʼ��ʱ����ֹ����ִ��ʱ����ڶ�ʱʱ�䣬ͬʱִ�ж�ι��̣� ���Ϊtrue���ճ����˳�ʱ���ܻ������⣬������
    /// </remarks>
    property ReTimingAfterProc: Boolean read FReTimingAfterProc write
        FReTimingAfterProc default False;
    property RollRate: Cardinal read FRollRate write FRollRate default 1000;
    property ScaleCount: Word read FScaleCount write SetScaleCount default 60;
    property Caption : string read Fcaption write Fcaption;
  end;

  TGLTimeWheelStr = class(TGLTimeWheelCustom)
  private
    FNeedTraversal: Boolean;
    HashTable:TGLStrHashTable;
    function GetCount: Integer;
    function GetItems(Index: Integer): Pointer;
    function GetKeys(Index: Integer): String;
    procedure SetNeedTraversal(const Value: Boolean);
    function GetTraversalCount: Integer;
    function GetTraversalItems(index: integer): Pointer;
  protected
    function FindAWheelItem(Key:string):PTimeWheelItem;overload;override;
    function FindAWheelItem(Key:Cardinal):PTimeWheelItem;overload;override;
    procedure TBLDeleteKey(Key:string);overload;override;
    procedure TBLDeleteKey(Key:Cardinal);overload;override;
    function TBLAddData(Key:string;Data:Pointer):Boolean;overload;override;
    function TBLAddData(Key:Cardinal;Data:Pointer):Boolean;overload;override;
    procedure Tblclear;override;
  public
    function Add(TimeOut: cardinal; Key: string; Data: Pointer; DataLen: Integer):Boolean;
    procedure Update(TimeOut:Cardinal;Key:string);
    function Find(Key: string; out DataLen: Integer; NeedGiveBack: Boolean =
        false): Pointer;
    function Delete(Key: string) : Boolean;
    procedure GiveBackData(Key1: string; Data: Pointer);

    /// <remarks>
    /// ���볬ʱ��ʣ�¶��ٺ���
    /// </remarks>
    function GetLeaveTimeOutTimes(Key1:string):Int64;

    constructor Create(size: cardinal);virtual;
    destructor Destroy; override;

    procedure SaveToFile(FileName: string);override;
    procedure LoadFromFile(FileName: string);override;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: Pointer read GetItems; default;
    property Keys[Index: Integer]: String read GetKeys;
    property NeedTraversal: Boolean read FNeedTraversal write SetNeedTraversal;
    property TraversalCount:Integer read GetTraversalCount;
    property TraversalItems[index:integer]:Pointer read GetTraversalItems;

    procedure BeginTraversal;
    procedure EndTraversal;
  end;

  TGLTimeWheelInt = class(TGLTimeWheelCustom)
  private
    FNeedTraversal: Boolean;
    HashTable:TGLIntHashTable;
    function GetCount: Integer;
    function GetItems(Index: Integer): Pointer;
    function GetKeys(Index: Integer): cardinal;
    procedure SetNeedTraversal(const Value: Boolean);
    function GetTraversalCount: Integer;
    function GetTraversalItems(index: integer): Pointer;
  protected
    function FindAWheelItem(Key:string):PTimeWheelItem;overload;override;
    function FindAWheelItem(Key:Cardinal):PTimeWheelItem;overload;override;
    procedure TBLDeleteKey(Key:string);overload;override;
    procedure TBLDeleteKey(Key:Cardinal);overload;override;
    function TBLAddData(Key:string;Data:Pointer):Boolean;overload;override;
    function TBLAddData(Key:Cardinal;Data:Pointer):Boolean;overload;override;
    procedure Tblclear;override;
  public
    function Add(TimeOut, Key: cardinal; Data: Pointer; DataLen: Integer):Boolean;
    procedure Update(TimeOut:Cardinal;Key:Cardinal);
    function Find(Key: Cardinal; out DataLen: Integer; NeedGiveBack: Boolean =
        false): Pointer;
    function Delete(Key: Cardinal):Boolean;
    procedure GiveBackData(Key2: Cardinal; Data: Pointer);

    /// <remarks>
    /// ���볬ʱ��ʣ�¶��ٺ���
    /// </remarks>
    function GetLeaveTimeOutTimes(Key2:Cardinal):Int64;

    constructor Create(size: cardinal);virtual;
    destructor Destroy; override;

    procedure SaveToFile(FileName: string);override;
    procedure LoadFromFile(FileName: string);override;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: Pointer read GetItems; default;
    property Keys[Index: Integer]: cardinal read GetKeys;
    property NeedTraversal: Boolean read FNeedTraversal write SetNeedTraversal;
    property TraversalCount:Integer read GetTraversalCount;
    property TraversalItems[index:integer]:Pointer read GetTraversalItems;

    procedure BeginTraversal;
    procedure EndTraversal;
  end;

implementation

uses Windows,DateUtils,SysUtils,GLLogger,GLPubFunc;

procedure WriteTimeWheelToStream(Stream:TStream;TimeWheelItem:PTimeWheelItem);
var
  KeyLen:integer;
begin
  with TimeWheelItem^ do
  begin
    if b then
    begin
      Stream.WriteCardinal(IntKey);
    end else
    begin
      KeyLen := Length(StrKey);
      Stream.writeInteger(KeyLen);
      Stream.WriteBuffer(StrKey^,KeyLen);
    end;
    Stream.WriteCardinal(Timeout);
    Stream.writeInteger(DataLen);
    Stream.WriteBuffer(Data^,DataLen);
  end;
end;

procedure TGLTimeWheelCustom.CheckTimeOut;
var
  TimeItem:PTimeWheelItem;
  I:integer;
  Key:string;
  tem,TimeItemAddr:string;
begin
  I:=0;
  if Locker.TryEnter then
  try
    if Fstoped then
    begin
      FFreeEvent.SetEvent;
      Exit;
    end;
    try
      tem := '1';
      FCurScale := GetScale(1);
      tem := '2';
      TimeItem := FScales[FCurScale];
      tem := '3';
      while TimeItem<>nil do
      begin
        TimeItemAddr := IntToStr(Integer(TimeItem));
        I := 0;
        Key := '';
        tem := '10';
        I:=TimeItem.turns;
        tem := '11';
        if TimeItem.b then
        begin
          Key := IntToStr(TimeItem.IntKey);
        end else
        begin
          Key := TimeItem.StrKey;
        end;
        tem := '20';
        Dec(TimeItem.turns);
        tem := '21';
        if (TimeItem.turns<0) then
        begin
{$IFDEF WriteLog}
          Logger.WriteLog(LTInfo,'��ʱɾ��һ��Ԫ�� '+IntToStr(Integer(TimeItem.PrveItem))+'->'+
                            IntToStr(Integer(TimeItem))+'->'+inttostr(Integer(TimeItem.NextItem))+' ����: '+inttostr(FCurScale));
{$ENDIF}
          tem := '22';
          if not DoOnTimeOut(TimeItem.StrKey,TimeItem.Data) then
          begin
{$IFDEF WriteLog}
            Logger.WriteLog(LTInfo,'ʱ�����У���ʱʱDoOnTimeOut����false,��ɾ��Ԫ��');
{$ENDIF}
            TimeItem := TimeItem.NextItem;
            Continue;
          end;
          tem := '23';
          if TimeItem.b then
          begin
            DeleteItem(TimeItem.IntKey,TimeItem);
          end else
          begin
            DeleteItem(TimeItem.StrKey,TimeItem);
          end;
        end else
        begin
{$IFDEF WriteLog}
          Logger.WriteLog(LTInfo,'Ԫ��ת��һȦ '+IntToStr(Integer(TimeItem.PrveItem))+'->'+
                  IntToStr(Integer(TimeItem))+'->'+inttostr(Integer(TimeItem.NextItem))+' ���� '+inttostr(TimeItem.turns)+'Ȧ  ����: '+inttostr(FCurScale));
{$ENDIF}
          tem := '30';
          TimeItem := TimeItem.NextItem;
          tem := '31';
        end;
      end;
    except
      Logger.WriteLog(LTError,'CheckTimeOut�з�������.'+Exception(ExceptObject).Message+
                      '  turns��ֵ��'+inttostr(I)+' Key: '+Key+' tem: '+tem+' Name: '+Fcaption+
                      ' TimeItemAddr:' + TimeItemAddr+' ����: '+inttostr(FCurScale)
                      {$IFDEF DEBUG32}+' ��ջ��Ϣ�� '+GetThreadStackTrace(GetCurrentThreadId){$ENDIF});
    end;
  finally
    Unlock;
  end;
end;

procedure TGLTimeWheelCustom.clear;
var
  I: Integer;
  TimeWheelItem:PTimeWheelItem;
begin
  Lock;
  try
    Tblclear;
    for I := 0 to FScaleCount - 1 do
    begin
      TimeWheelItem := FScales[I];
      while TimeWheelItem<>nil do
      begin
         DeleteWheelItem(TimeWheelItem,TimeWheelItem);
      end;
    end;
    for I := TimeOutHashTBL.ItemCount - 1 downto 0 do
    begin
      TimeWheelItem := TimeOutHashTBL.Items[I];
      if TimeWheelItem<>nil then
      begin
        if TimeWheelItem.Data<>nil then
          FreeMemory(TimeWheelItem.Data);
        Dispose(TimeWheelItem);
      end;
    end;
  finally
    Unlock;
  end;
end;

constructor TGLTimeWheelCustom.Create;
begin
  FFreeEvent := TEvent.Create();
  Fstoped := True;
  FCurScale := 0;
  FRollRate := 1000;
  ScaleCount := 60;
  Locker := TGLCriticalSection.Create;
  TimeOutHashTBL := TGLIntHashTable.Create(99997);
  TimeOutHashTBL.NeedTraversal := true;
  // TODO -cMM: TGLTimeWheelCustom.Create default body inserted
end;

function TGLTimeWheelCustom.Delete(Key1: string; Key2: Cardinal):Boolean;
var
  tem:PTimeWheelItem;
begin
  Result := False;
  tem := nil;
  Lock;
  try
    if Key1='' then
    begin
      Result := DeleteItem(Key2,tem);
    end else
    begin
      Result := DeleteItem(Key1,tem);
    end;
  finally
    Unlock;
  end;
end;

function TGLTimeWheelCustom.DeleteItem(Key: string; var NextItem: PTimeWheelItem): Boolean;
var
  TimeWheelItem:PTimeWheelItem;
begin
  NextItem := nil;
  Result := False;
  TimeWheelItem := FindAWheelItem(Key);
  if TimeWheelItem<>nil then
  begin
     Result := DeleteWheelItem(TimeWheelItem,NextItem);
  end;
  TBLDeleteKey(Key);
end;

function TGLTimeWheelCustom.DeleteItem(Key: Cardinal; var NextItem: PTimeWheelItem): Boolean;
var
  TimeWheelItem:PTimeWheelItem;
begin
  NextItem := nil;
  Result := False;
  TimeWheelItem := FindAWheelItem(Key);
  if TimeWheelItem<>nil then
  begin
    Result := DeleteWheelItem(TimeWheelItem,NextItem);
  end;
  TBLDeleteKey(Key);
end;

function TGLTimeWheelCustom.DeleteWheelItem(AWheelItem: PTimeWheelItem; var NextItem: PTimeWheelItem): Boolean;
var
  tem:PTimeWheelItem;
begin
  Result := False;
  NextItem := nil;
  try
    if AWheelItem<>nil then
    begin
  {$IFDEF WriteLog}
      Logger.WriteLog(LTDebug,'ɾ��һ��Ԫ�أ�ɾ��ǰ���Ӧǰһ�����һ����ַΪ '+IntToStr(Integer(AWheelItem.PrveItem))+'->'+
                              IntToStr(Integer(AWheelItem))+'->'+inttostr(Integer(AWheelItem.NextItem))+'  ���ӣ� '+inttostr(FCurScale));
  {$ENDIF}
      if AWheelItem.PrveItem=nil then                        //�ȴ���֮ǰ��ʱ����
      begin
        Tem := AWheelItem.NextItem;
        if Tem<>nil then
          Tem.PrveItem := nil;
        FScales[AWheelItem.Scales] := Tem;
        NextItem := Tem;
      end else
      begin
        Tem := AWheelItem.PrveItem;
        Tem.NextItem := AWheelItem.NextItem;
        if AWheelItem.NextItem<>nil then
           AWheelItem.NextItem.PrveItem := tem;
        NextItem := AWheelItem.NextItem;
      end;
      if not AWheelItem.b then
        FreeMemory(AWheelItem.StrKey);

      if AWheelItem.DataLen>0 then
      begin
        if AWheelItem.RefTimes<=0 then           //������ô���С�ڵ���0���ͷ����ݡ�
          FreeMemory(AWheelItem.Data);
        Dec(FContentSize,AWheelItem.DataLen);
      end else
      begin
        DoDeleteItem(AWheelItem.Data);
      end;

  {$IFDEF WriteLog}
      Logger.WriteLog(LTDebug,'ɾ��һ��Ԫ�أ�ɾ�������Ӧǰһ�����һ����ַΪ '+IntToStr(Integer(AWheelItem.PrveItem))+'->'+
                              IntToStr(Integer(AWheelItem))+'->'+inttostr(Integer(AWheelItem.NextItem))+' ��ǰ����ֵ: '+inttostr(Integer(FScales[AWheelItem.Scales])));
  {$ENDIF}
      Result := True;
      if AWheelItem.RefTimes<=0 then                      //���û�����ã�ֱ�����٣�����У��Ž���ʱ�ұ����ñ���
      begin
        Dispose(AWheelItem);
      end else
      begin
        TimeOutHashTBL.Add(Cardinal(AWheelItem.Data),AWheelItem,0);
      end;
      Dec(FAddCount);
    end;
  except
    Logger.WriteLog(LTError,'DeleteWheelItem: '+LastErrMsg);
  end;
end;

destructor TGLTimeWheelCustom.Destroy;
begin
  Stop;
  clear;
  Locker.Free;
  FFreeEvent.Free;
  TimeOutHashTBL.Free;
  inherited;
  // TODO -cMM: TGLTimeWheelCustom.Destroy default body inserted
end;

procedure TGLTimeWheelCustom.DoDeleteItem(Data: Pointer);
begin
  if Assigned(FOnDeleteItem) then
    FOnDeleteItem(Data);
end;

function TGLTimeWheelCustom.DoOnTimeOut(Key:Pointer;Data:Pointer): Boolean;
begin
  Result := true;
  if Assigned(FOnTimeOut) then
    Result := FOnTimeOut(Key,Data);
end;

function TGLTimeWheelCustom.Exist(Key: Cardinal): Boolean;
begin
  Result := FindAWheelItem(Key)<>nil;
end;

function TGLTimeWheelCustom.Exist(Key: string): Boolean;
begin
  Result := FindAWheelItem(Key)<>nil;
end;

function TGLTimeWheelCustom.Find(Key1: string; Key2: Cardinal; out DataLen:
    Integer; NeedGiveBack: Boolean = false): Pointer;
var
  TimeWheelItem:PTimeWheelItem;
begin
  Result := nil;
  Lock;
  try
    if Key1='' then
    begin
      TimeWheelItem := FindAWheelItem(Key2)
    end else
    begin
      TimeWheelItem := FindAWheelItem(Key1)
    end;
    if TimeWheelItem<>nil then
    begin
      if TimeWheelItem.DataLen>0 then
      begin
        DataLen := TimeWheelItem.DataLen;
        if not NeedGiveBack then                           //����Ҫ����GiveBack���������ø�������һ��,��������Ҫ�ͷ�
        begin
          Result := GetMemory(TimeWheelItem.DataLen);
          CopyMemory(Result,TimeWheelItem.Data,TimeWheelItem.DataLen);
        end else
        begin
          Inc(TimeWheelItem.RefTimes);
          Result := TimeWheelItem.Data;
        end;
      end  else
      begin
        Result := TimeWheelItem.Data;
      end;
    end;
  finally
    Unlock;
  end;
end;

procedure TGLTimeWheelCustom.FreeData(P: Pointer);
begin
  FreeMemory(P);
end;

function TGLTimeWheelCustom.GetLeaveTimeOutTimes(Key1: string;
  Key2: Cardinal): Int64;
var
  TimeWheelItem:PTimeWheelItem;
begin
  Lock;
  try
    if Key1<>'' then
    begin
      TimeWheelItem := FindAWheelItem(Key1);
    end else
    begin
      TimeWheelItem := FindAWheelItem(Key2);
    end;
    if TimeWheelItem<>nil then
    begin
      Result := TimeWheelItem^.turns*FRollRate*FScaleCount;
      if FCurScale>TimeWheelItem^.Scales then
        Result := Result + FScaleCount-(FCurScale-TimeWheelItem^.Scales)
      else
        Result := Result + TimeWheelItem^.Scales - FCurScale;
    end;
  finally
    Unlock;
  end;
end;

function TGLTimeWheelCustom.GetScale(Value: Word): Word;
begin
  if Value+FCurScale>=ScaleCount then
    Result := Value+FCurScale-ScaleCount
  else
    Result := Value+FCurScale;
end;

procedure TGLTimeWheelCustom.GiveBackData(Key1: string; Key2: Cardinal; Data:
    Pointer);
var
  TimeWheelItem:PTimeWheelItem;
  ADataLen:Cardinal;
begin
  Lock;                                                       //��Data�ڳ�ʱ�ұ���������TimeWheelItem������Key1��2��TimeWheel�����������
  try
    if Key1='' then
    begin
      TimeWheelItem := FindAWheelItem(Key2)
    end else
    begin
      TimeWheelItem := FindAWheelItem(Key1);
    end;
    if TimeWheelItem<>nil then
    begin
      Dec(TimeWheelItem.RefTimes);
    end else
    begin
      TimeWheelItem := TimeOutHashTBL.Find(Cardinal(data),ADataLen);
      if TimeWheelItem<>nil then
      begin
        Dec(TimeWheelItem.RefTimes);
        if TimeWheelItem.RefTimes<=0 then
        begin
          TimeOutHashTBL.Remove(Cardinal(Data));
          if TimeWheelItem.Data<>nil then
          begin
            FreeMemory(TimeWheelItem.Data);
            TimeWheelItem.Data := nil;
          end;
          Dispose(TimeWheelItem);
        end;
      end;
    end;
  finally
    Unlock;
  end;
end;

procedure TGLTimeWheelCustom.InitATimeWheelItem(TimeWheelItem: PTimeWheelItem);
begin

end;

function TGLTimeWheelCustom.Add(TimeOut: cardinal; Key1:string;Key2:Cardinal;
    Data: Pointer;DataLen:Integer):Boolean;
var
  TimeWheelItem:PTimeWheelItem;
  StrKeyLen:Integer;
begin
  Result := False;
  if TimeOut<=0 then Exit;
  try
    New(TimeWheelItem);
    FillChar(TimeWheelItem^,SizeOf(TTimeWheelItem),0);
    TimeWheelItem.turns := Trunc(TimeOut /(FRollRate*FScaleCount));
    if Key1='' then
    begin
      TimeWheelItem.b := True;
      TimeWheelItem.IntKey := Key2;
    end else
    begin
      TimeWheelItem.b := False;
      StrKeyLen := ByteLength(Key1);
      TimeWheelItem.StrKey := GetMemory(StrKeyLen+sizeof(Char));
      FillChar(TimeWheelItem.StrKey^,StrKeyLen+sizeof(Char),0);
      CopyMemory(TimeWheelItem.StrKey,@Key1[1],StrKeyLen);
    end;

    if DataLen>0 then
    begin
      TimeWheelItem.Data := GetMemory(DataLen);
      CopyMemory(TimeWheelItem.Data,Data,DataLen);
    end else
    begin
      TimeWheelItem.Data := Data;
    end;
    TimeWheelItem.DataLen := DataLen;
    TimeWheelItem.TimeOut := TimeOut;
    TimeWheelItem.RefTimes := 0;
    Result := AddTimeWheelItem(TimeOut,TimeWheelItem);
  except
    Logger.WriteLog(LTError,'TimeWheelCustom.Add�г��ִ���.'+Exception(ExceptObject).Message);
  end;
  // TODO -cMM: TGLTimeWheelCustom.Add default body inserted
end;

procedure TGLTimeWheelCustom.SetScaleCount(const Value: Word);
begin
  FScaleCount := Value;
  SetLength(FScales,FScaleCount);
  FillChar(FScales[0],SizeOf(PTimeWheelItem)*FScaleCount,0);        //����зǷ��ڴ����
end;

procedure CallBack(uTimerID, uMessage: UINT;
    dwUser, dw1, dw2: NativeUInt) stdcall;
var
  TimeWheel:TGLTimeWheelCustom;
begin
  try
    TimeWheel := TGLTimeWheelCustom(dwUser);
    if TimeWheel<>nil then
    begin
      if TimeWheel.ReTimingAfterProc then
      begin
        try
          timeKillEvent(TimeWheel.FTimer);
          TimeWheel.FTimer := 0;
          TimeWheel.CheckTimeOut();
        finally
          TimeWheel.FTimer := timeSetEvent(TimeWheel.FRollRate,0,CallBack,NativeUInt(TimeWheel),TIME_ONESHOT);
        end;
      end else
      begin
        TimeWheel.CheckTimeOut();
      end;
    end;
  except
    Logger.WriteLog(LTError,' ��ʱ���ص������г��ִ���: ' + LastErrMsg);
  end;
end;

procedure TGLTimeWheelCustom.Start;
begin
  Fstoped := False;
  if Fstarted then  Exit;
  
  Fstarted := True;
  if ReTimingAfterProc then
    FTimer := timeSetEvent(FRollRate,0,CallBack,
    NativeUInt(Self),TIME_ONESHOT)
  else
    FTimer := timeSetEvent(FRollRate,0,CallBack,NativeUInt(Self),TIME_PERIODIC);
end;

procedure TGLTimeWheelCustom.Stop;
begin
  Fstoped := True;
  WaitForSingleObject(FFreeEvent.Handle,FRollRate+1000);
  if FTimer<>0 then  
    timeKillEvent(FTimer);
  Fstarted := False;
end;


procedure TGLTimeWheelCustom.Update(TimeOut:Cardinal;Key1:string;Key2:Cardinal);
var
  TimeWheelItem,Tem:PTimeWheelItem;
  SetScale:Word;
begin
  Lock;
  try
    if Key1='' then
    begin
      TimeWheelItem := FindAWheelItem(Key2);
    end else
    begin
      TimeWheelItem := FindAWheelItem(Key1);
    end;
    if TimeWheelItem<>nil then
    begin
{$IFDEF WriteLog}
      Logger.WriteLog(LTDebug,'����һ��Ԫ�أ�����ǰ���Ӧǰһ�����һ����ַΪ '+IntToStr(Integer(TimeWheelItem.PrveItem))+'->'+
                              IntToStr(Integer(TimeWheelItem))+'->'+inttostr(Integer(TimeWheelItem.NextItem))+'  ���ӣ�'+inttostr(TimeWheelItem.Scales));
{$ENDIF}
      if TimeWheelItem.PrveItem=nil then                        //�ȴ���֮ǰ��ʱ����
      begin
        Tem := TimeWheelItem.NextItem;
        if Tem<>nil then
          Tem.PrveItem := nil;
        FScales[TimeWheelItem.Scales] := Tem;
      end else
      begin
        TimeWheelItem.PrveItem.NextItem := TimeWheelItem.NextItem;
        if TimeWheelItem.NextItem<>nil then
          TimeWheelItem.NextItem.PrveItem := TimeWheelItem.PrveItem;
      end;

      TimeWheelItem.PrveItem := nil;
      TimeWheelItem.turns := Trunc(TimeOut /(FRollRate*FScaleCount));
      SetScale := GetScale(Trunc((TimeOut-FRollRate*FScaleCount*TimeWheelItem.turns) / Integer(FRollRate)));
      if SetScale = FCurScale then
        TimeWheelItem.turns := TimeWheelItem.turns-1;
      TimeWheelItem.NextItem := FScales[SetScale];
      if FScales[SetScale]<>nil then
        FScales[SetScale].PrveItem := TimeWheelItem;
      TimeWheelItem.Scales := SetScale;
      FScales[SetScale] := TimeWheelItem;
{$IFDEF WriteLog}
      Logger.WriteLog(LTDebug,'����һ��Ԫ�أ����º����Ӧǰһ�����һ����ַΪ '+IntToStr(Integer(TimeWheelItem.PrveItem))+'->'+
                              IntToStr(Integer(TimeWheelItem))+'->'+inttostr(Integer(TimeWheelItem.NextItem))+'  ���ӣ�'+inttostr(TimeWheelItem.Scales)+
                              ' Ȧ��:'+IntToStr(TimeWheelItem.turns)+'  ��ǰ����: '+inttostr(FCurScale)+'  ��ʱʱ����'+inttostr(TimeOut));
{$ENDIF}
    end;
  finally
    Unlock;
  end;
end;

{ TTimeWheelItem }


function TGLTimeWheelCustom.AddTimeWheelItem(TimeOut: Cardinal; TimeWheelItem:
    PTimeWheelItem):Boolean;
var
  SetScale: Word;
  Key:string;
begin
  Result := false;
  Lock;
  try
    SetScale := GetScale(Trunc((TimeOut - FRollRate * FScaleCount * TimeWheelItem.turns) / FRollRate));
    if SetScale = FCurScale then
      TimeWheelItem.turns := TimeWheelItem.turns - 1;

    if TimeWheelItem.b then
    begin
      Key := IntToStr(TimeWheelItem.IntKey);
      Result := TBLAddData(TimeWheelItem.IntKey,TimeWheelItem);
    end
    else
    begin
      Key := TimeWheelItem.StrKey;
      Result := TBLAddData(TimeWheelItem.StrKey,TimeWheelItem);
    end;
    if not Result then
    begin
      Logger.WriteLog(LTDebug,'AddTimeWheelItem�� ����һ��Ԫ��ʧ��.'+IntToStr(Integer(TimeWheelItem.PrveItem))+'->'+
                        IntToStr(Integer(TimeWheelItem))+'->'+inttostr(Integer(TimeWheelItem.NextItem))+'  Key:'+Key+
                        '   ���ӣ�'+inttostr(SetScale)+'  ת����'+inttostr(TimeWheelItem.turns)+'  ��ʱʱ����'+inttostr(TimeOut)+'  ��С:'+SizeConvert(TimeWheelItem.DataLen));
      if not TimeWheelItem.b then
        FreeMemory(TimeWheelItem.StrKey);
      if TimeWheelItem.DataLen>0 then
      begin
        FreeMemory(TimeWheelItem.Data);
//        Logger.WriteLog(LTDebug,'�ͷ�TimeWheelItem.Data ��С:'+SizeConvert(TimeWheelItem.DataLen));
      end;
      Dispose(TimeWheelItem);
      Exit;
    end;

    TimeWheelItem.NextItem := FScales[SetScale];
    TimeWheelItem.Scales := SetScale;
    if FScales[SetScale] <> nil then
      FScales[SetScale].PrveItem := TimeWheelItem;
    FScales[SetScale] := TimeWheelItem;
    if TimeWheelItem.NextItem=TimeWheelItem then
    begin
      Logger.WriteLog(LTDebug,'AddTimeWheelItem�� ���ѵ���һ����������!');
      TimeWheelItem.NextItem := nil;
    end;
    if TimeWheelItem.PrveItem=TimeWheelItem then
    begin
      Logger.WriteLog(LTDebug,'AddTimeWheelItem�� ���ѵ���һ����������!');
      TimeWheelItem.PrveItem := nil;
    end;

    Inc(FAddCount);
    Inc(FContentSize,TimeWheelItem.DataLen);
{$IFDEF WriteLog}
    Logger.WriteLog(LTDebug,'����һ��Ԫ�أ����Ӧǰһ�����һ����ַΪ '+IntToStr(Integer(TimeWheelItem.PrveItem))+'->'+
                        IntToStr(Integer(TimeWheelItem))+'->'+inttostr(Integer(TimeWheelItem.NextItem))+'  Key:'+Key+
                        '   ���ӣ�'+inttostr(SetScale)+'  ת����'+inttostr(TimeWheelItem.turns)+'  ��ʱʱ����'+inttostr(TimeOut));
{$ENDIF}
  finally
    Unlock;
  end;
end;

procedure TGLTimeWheelCustom.Lock;
begin
  Locker.Enter;
  // TODO -cMM: TGLTimeWheelCustom.Lock default body inserted
end;

procedure TGLTimeWheelCustom.Unlock;
begin
  Locker.Leave;
  // TODO -cMM: TGLTimeWheelCustom.Unlock default body inserted
end;

function TGLTimeWheelStr.Add(TimeOut: cardinal; Key: string; Data: Pointer;
    DataLen: Integer):Boolean;
begin
  Result := false;
  if Key<>'' then
    Result := inherited Add(TimeOut,Key,0,Data,DataLen);
end;

procedure TGLTimeWheelStr.BeginTraversal;
begin
  Lock;
  HashTable.BeginTraversal;
end;

constructor TGLTimeWheelStr.Create(size: cardinal);
begin
  HashTable := TGLStrHashTable.Create(size);
  HashTable.NeedSync := False;
  NeedTraversal := True;
  inherited Create;
  // TODO -cMM: TGLTimeWheelStr.Create default body inserted
end;

function TGLTimeWheelStr.Delete(Key: string):Boolean;
begin
  Result := False;
  if Key<>'' then
    Result := inherited Delete(Key,0);
end;

destructor TGLTimeWheelStr.Destroy;
begin
  inherited;
  HashTable.Free;
  // TODO -cMM: TGLTimeWheelStr.Destroy default body inserted
end;

procedure TGLTimeWheelStr.EndTraversal;
begin
  HashTable.EndTraversal;
  Unlock;
end;

{ TGLTimeWheelStr }

function TGLTimeWheelStr.Find(Key: string; out DataLen: Integer; NeedGiveBack:
    Boolean = false): Pointer;
begin
  Result := nil;
  if Key<>'' then
    Result := inherited Find(Key,0,DataLen,NeedGiveBack);
end;

function TGLTimeWheelStr.FindAWheelItem(Key: Cardinal): PTimeWheelItem;
begin
  Result := nil;
end;

function TGLTimeWheelStr.FindAWheelItem(Key: string): PTimeWheelItem;
var
  ADataLen:Cardinal;
begin
  Result := PTimeWheelItem(HashTable.Find(Key,ADataLen));
end;

function TGLTimeWheelStr.GetCount: Integer;
begin
  // TODO -cMM: TGLTimeWheelStr.GetCount default body inserted
  Result := HashTable.ItemCount;
end;

function TGLTimeWheelStr.GetItems(Index: Integer): Pointer;
begin
  // TODO -cMM: TGLTimeWheelStr.GetItems default body inserted
  Result := PTimeWheelItem(HashTable.Items[Index]).Data;
end;

function TGLTimeWheelStr.GetKeys(Index: Integer): String;
begin
  // TODO -cMM: TGLTimeWheelStr.GetKeys default body inserted
  Result := StrPas(PTimeWheelItem(HashTable.Items[Index]).StrKey);
end;

function TGLTimeWheelStr.GetLeaveTimeOutTimes(Key1: string): Int64;
begin
  Result := inherited GetLeaveTimeOutTimes(Key1,0);
end;

function TGLTimeWheelStr.GetTraversalCount: Integer;
begin
  Result := HashTable.TraversalList.Count;
end;

function TGLTimeWheelStr.GetTraversalItems(index: integer): Pointer;
var
  TimeWheelItem:PTimeWheelItem;
begin
  Result := nil;
  TimeWheelItem := HashTable.TraversalList.Items[index];
  if TimeWheelItem<>nil then
    Result := TimeWheelItem.Data;
end;

procedure TGLTimeWheelStr.GiveBackData(Key1: string; Data: Pointer);
begin
  inherited GiveBackData(Key1,0,Data);
end;

procedure TGLTimeWheelStr.LoadFromFile(FileName: string);
var
  FileStream:TFileStream;
  TimeWheelItem:PTimeWheelItem;
  TimeOut:Cardinal;
  Key:string;
  DataLen:integer;
  Data:Pointer;
begin
  if Length(FileName)=0 then raise  Exception.Create('TGLTimeWheelStr.SaveToFile--�������ļ�����');

  if Pos('\',FileName)<=0 then
    FileName := GetCurrentPath+FileName+'.dat';
    
  FileStream := TFileStream.Create(FileName,fmCreate or fmOpenRead);
  FileStream.Position := 0;
  Lock;
  try
    while not FileStream.Eof do
    begin
      try
        Key := FileStream.ReadAnsiString;
        TimeOut := FileStream.ReadCardinal;
        DataLen := FileStream.ReadInteger;
        Data := GetMemory(Datalen);
        try
          FileStream.Read(Data^,DataLen);
          Add(TimeOut,Key,Data,DataLen);
        finally
          FreeMemory(Data);
        end;
      except
        Logger.WriteLog(LTError,'TimeWheeStr.LoadFromFile����.'+Exception(ExceptObject).Message);
      end;
    end;
  finally
    Unlock;
    FileStream.Free;
  end;
end;

procedure TGLTimeWheelStr.SaveToFile(FileName: string);
var
  FileStream:TFileStream;
  I: Integer;
  TimeWheelItem:PTimeWheelItem;
begin
  if Length(FileName)=0 then raise  Exception.Create('TGLTimeWheelStr.SaveToFile--�������ļ�����');

  if Pos('\',FileName)<=0 then
    FileName := GetCurrentPath+FileName+'.dat';
  FileStream := TFileStream.Create(FileName,fmCreate or fmOpenWrite);
  FileStream.Position := 0;
  Lock;
  try
    for I := 0 to HashTable.ItemCount - 1 do
    begin
      TimeWheelItem := HashTable.Items[I];
      WriteTimeWheelToStream(FileStream,TimeWheelItem);
    end;
  finally
    Unlock;
    FileStream.Free;
  end;
end;

procedure TGLTimeWheelStr.SetNeedTraversal(const Value: Boolean);
begin
  FNeedTraversal := Value;
  HashTable.NeedTraversal := Value;
end;

function TGLTimeWheelStr.TBLAddData(Key: string; Data: Pointer):Boolean;
begin
  Result := HashTable.Add(Key,Data,0);
end;

function TGLTimeWheelStr.TBLAddData(Key: Cardinal; Data: Pointer):Boolean;
begin

end;

procedure TGLTimeWheelStr.Tblclear;
begin
  HashTable.Clear;
end;

procedure TGLTimeWheelStr.TBLDeleteKey(Key: Cardinal);
begin

end;

procedure TGLTimeWheelStr.Update(TimeOut: Cardinal; Key: string);
begin
  if Key<>'' then
    inherited Update(TimeOut,Key,0);
end;

procedure TGLTimeWheelStr.TBLDeleteKey(Key: string);
begin
  HashTable.Remove(Key);
end;

{ TGLTimeWheelInt }

function TGLTimeWheelInt.Add(TimeOut, Key: cardinal; Data: Pointer; DataLen:
    Integer):Boolean;
begin
  Result := inherited Add(TimeOut,'',Key,Data,DataLen);
end;

procedure TGLTimeWheelInt.BeginTraversal;
begin
  Lock;
  HashTable.BeginTraversal;
end;

constructor TGLTimeWheelInt.Create(size: cardinal);
begin
  HashTable := TGLIntHashTable.Create(size);
  HashTable.NeedSync := False;
  NeedTraversal := True;
  inherited Create;
end;

function TGLTimeWheelInt.Delete(Key: Cardinal):Boolean;
begin
  Result := False;
  if Key>0 then
    Result := inherited Delete('',Key);
end;

destructor TGLTimeWheelInt.Destroy;
begin
  inherited;
  HashTable.Free;
end;

procedure TGLTimeWheelInt.EndTraversal;
begin
  HashTable.EndTraversal;
  Unlock;
end;

function TGLTimeWheelInt.Find(Key: Cardinal; out DataLen: Integer;
    NeedGiveBack: Boolean = false): Pointer;
begin
  Result := inherited Find('',Key,DataLen,NeedGiveBack);
end;

function TGLTimeWheelInt.FindAWheelItem(Key: Cardinal): PTimeWheelItem;
var
  ADataLen:Cardinal;
begin
  Result := PTimeWheelItem(HashTable.Find(Key,ADataLen));
end;

function TGLTimeWheelInt.FindAWheelItem(Key: string): PTimeWheelItem;
begin
  Result := nil;
end;

function TGLTimeWheelInt.GetCount: Integer;
begin
  // TODO -cMM: TGLTimeWheelInt.GetCount default body inserted
  Result := HashTable.ItemCount;
end;

function TGLTimeWheelInt.GetItems(Index: Integer): Pointer;
begin
  // TODO -cMM: TGLTimeWheelInt.GetItems default body inserted
  Result := PTimeWheelItem(HashTable.Items[Index]).Data;
end;

function TGLTimeWheelInt.GetKeys(Index: Integer): cardinal;
begin
  // TODO -cMM: TGLTimeWheelInt.GetKeys default body inserted
  Result := PTimeWheelItem(HashTable.Items[Index]).IntKey;
end;

function TGLTimeWheelInt.GetLeaveTimeOutTimes(Key2: Cardinal): Int64;
begin
  Result := inherited GetLeaveTimeOutTimes('',Key2);
end;

function TGLTimeWheelInt.GetTraversalCount: Integer;
begin
  Result := HashTable.TraversalList.Count;
end;

function TGLTimeWheelInt.GetTraversalItems(index: integer): Pointer;
var
  TimeWheelItem:PTimeWheelItem;
begin
  Result := nil;
  TimeWheelItem := HashTable.TraversalList.Items[index];
  if TimeWheelItem<>nil then
    Result := TimeWheelItem.Data;
end;

procedure TGLTimeWheelInt.GiveBackData(Key2: Cardinal; Data: Pointer);
begin
  inherited GiveBackData('',Key2,Data);
end;

procedure TGLTimeWheelInt.LoadFromFile(FileName: string);
var
  FileStream:TFileStream;
  TimeWheelItem:PTimeWheelItem;
  Key,TimeOut:Cardinal;
  DataLen:integer;
  Data:Pointer;
begin
  if Length(FileName)=0 then raise  Exception.Create('TGLTimeWheelInt.SaveToFile--�������ļ�����');

  if Pos('\',FileName)<=0 then
    FileName := GetCurrentPath+FileName+'.dat';
    
  FileStream := TFileStream.Create(FileName,fmCreate or fmOpenRead);
  FileStream.Position := 0;
  Lock;
  try
    while not FileStream.Eof do
    begin
      try
        Key := FileStream.ReadCardinal;
        TimeOut := FileStream.ReadCardinal;
        DataLen := FileStream.ReadInteger;
        Data := GetMemory(Datalen);
        try
          FileStream.Read(Data^,DataLen);
          Add(TimeOut,Key,Data,DataLen);
        finally
          FreeMemory(Data);
        end;
      except
        Logger.WriteLog(LTError,'TimeWheelInt.LoadFromFile����.'+Exception(ExceptObject).Message);
      end;
    end;
  finally
    Unlock;
    FileStream.Free;
  end;
end;

procedure TGLTimeWheelInt.SaveToFile(FileName: string);
var
  FileStream:TFileStream;
  I: Integer;
  TimeWheelItem:PTimeWheelItem;
begin
  if Length(FileName)=0 then raise  Exception.Create('TGLTimeWheelInt.SaveToFile--�������ļ�����');

  if Pos('\',FileName)<=0 then
    FileName := GetCurrentPath+FileName+'.dat';
    
  FileStream := TFileStream.Create(FileName,fmCreate or fmOpenWrite);
  FileStream.Position := 0;
  Lock;
  try
    for I := 0 to HashTable.ItemCount - 1 do
    begin
      TimeWheelItem := HashTable.Items[I];
      WriteTimeWheelToStream(FileStream,TimeWheelItem);
    end;
  finally
    Unlock;
    FileStream.Free;
  end;
end;

procedure TGLTimeWheelInt.SetNeedTraversal(const Value: Boolean);
begin
  FNeedTraversal := Value;
  HashTable.NeedTraversal := Value;
end;

function TGLTimeWheelInt.TBLAddData(Key: Cardinal; Data: Pointer):Boolean;
begin
  Result := HashTable.Add(Key,Data,0);
end;

function TGLTimeWheelInt.TBLAddData(Key: string; Data: Pointer):Boolean;
begin

end;

procedure TGLTimeWheelInt.Tblclear;
begin
  HashTable.Clear;
end;

procedure TGLTimeWheelInt.TBLDeleteKey(Key: Cardinal);
begin
  HashTable.Remove(Key);
end;

procedure TGLTimeWheelInt.TBLDeleteKey(Key: string);
begin

end;

procedure TGLTimeWheelInt.Update(TimeOut, Key: Cardinal);
begin
  inherited Update(TimeOut,'',Key);
end;

end.

