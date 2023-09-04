//非线程安全

unit GLObjectList;

interface

uses
  classes;

type
  TObjectData = class
  end;

  TCompare = function(A, B: TObjectData): Boolean of object;

  TObjectItem = class
    Data: TObjectData;
    Next: TObjectItem;
  end;

  TGLObjectList = class
  private
    FHead: TObjectItem;
    FLast: TObjectItem;
    FCount: UInt64;
    function GetItems(Index: UInt64): TObjectData;
  public
    procedure clear;
    procedure AddItem(AData: TObjectData);
    procedure InsertItem(AData: TObjectData; Index: UInt64);
    procedure DelIndex(Index: UInt64);
    procedure DelItem(AData: TObjectData; Compare: TCompare = nil);    //删除一项，如果Compare<>nil,删除比较通过的所有项
    destructor Destroy; override;

    property Count: UInt64 read FCount;
    property Items[Index: UInt64]: TObjectData read GetItems;
  end;

implementation

procedure TGLObjectList.AddItem(AData: TObjectData);
var
  temItem: TObjectItem;
begin
  temItem := TObjectItem.Create;
  temItem.Data := AData;
  temItem.Next := nil;

  if FLast = nil then
  begin
    FHead := temItem;
  end
  else
  begin
    FLast.Next := temItem;
  end;

  FLast := temItem;
  inc(FCount);
end;

procedure TGLObjectList.clear;
var
  tem : TObjectItem;
begin
  while FHead <> nil do
  begin
    tem := Fhead;
    FHead := FHead.Next;
    tem.Data.Free;
    tem.Free;
    Dec(FCount);
  end;
end;

procedure TGLObjectList.DelIndex(Index: UInt64);
var
  tem, PreItem, DelItem: TObjectItem;
  temIndex: UInt64;
begin
  if Index>Fcount-1 then exit;

  tem := FHead;
  PreItem := nil;
  temIndex := 0;
  while tem <> nil do
  begin
    if temIndex = Index then
    begin
      if PreItem = nil then                     //如果是头
      begin
        DelItem := FHead;
        FHead := Fhead.Next;
        if FHead = nil then
        begin
          FLast := nil;
        end;
        DelItem.Data.Free;
        delItem.Free;
      end
      else
      begin
        DelItem := tem.Next;
        if delItem <> nil then
        begin
          PreItem.Next := DelItem;
          tem.Data.Free;
          tem.Free;
        end
        else
        begin
          tem.Data.Free;
          tem.Free;
          FLast := PreItem;
          PreItem.Next := DelItem;
        end;
      end;
      Dec(Fcount);
      break;
    end;
    PreItem := tem;
    tem := tem.Next;
    inc(temIndex);
  end;
end;

procedure TGLObjectList.DelItem(AData: TObjectData; Compare: TCompare);
var
  tem, temDelItem, temPreItem: TObjectItem;

  procedure process;
  begin
    if tem = FHead then                  //如果是链表头，直接把第二个设置成头，然后把头释放掉
    begin
      FHead := FHead.Next;
      tem.Free;
      if FHead = nil then                 //如果只有一个元素，删掉后，把链表尾也值空
      begin
        FLast := nil;
      end;
    end
    else
    begin
      temDelItem := tem.Next;                     //链表中间的
      if temDelItem <> nil then
      begin
        temPreItem.Next := temDelItem;
        temDelItem.Free;
      end
      else                                     //链表末尾的。
      begin
        tem.Free;
        FLast := temPreItem;
        temPreItem.Next := temDelItem;
      end;
    end;
  end;

begin
  tem := FHead;
  temPreItem := FHead;
  while tem <> nil do
  begin
    if @Compare <> nil then
    begin
      if Compare(Adata, tem.Data) then
      begin
        process;
        Adata.Free;
        dec(Fcount);
      end;
    end
    else
    begin
      if Adata = tem.Data then
      begin
        process;
        Adata.Free;
        dec(Fcount);
        exit;
      end;
    end;
    temPreItem := tem;
    tem := tem.Next;
  end;
end;

destructor TGLObjectList.Destroy;
begin
  clear;
  inherited;
end;

function TGLObjectList.GetItems(Index: UInt64): TObjectData;
var
  tem: TObjectItem;
  temIndex: UInt64;
begin
  result := nil;
  tem := FHead;
  temIndex := 0;
  while tem <> nil do
  begin
    if temIndex = Index then
    begin
      Result := tem.Data;
      exit;
    end;
    tem := tem.Next;
    inc(temIndex);
  end;
end;

procedure TGLObjectList.InsertItem(AData: TObjectData; Index: UInt64);
var
  temItem, tem, PreItem: TObjectItem;
  temIndex: UInt64;
begin
  PreItem := nil;

  temItem := TObjectItem.Create;
  temItem.Data := AData;
  temItem.Next := nil;

  if FLast = nil then
  begin
    FHead := temItem;
    FLast := temItem;
    inc(FCount);
  end
  else
  begin
    tem := FHead;
    temIndex := 0;
    while tem <> nil do
    begin
      if temIndex = Index then
      begin
        if PreItem = nil then
        begin
          temItem.Next := FHead;
          FHead := temItem;
        end
        else
        begin
          PreItem.Next := temItem;
          temItem.Next := tem;
        end;
        inc(FCount);
        exit;
      end;
      PreItem := tem;
      tem := tem.Next;
      inc(temIndex);
    end;
    inc(FCount);
    FLast.Next := temItem;
    FLast := temItem;
  end;

end;

end.


