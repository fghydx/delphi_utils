unit RBTreeBase;

interface

uses
  Classes, sysutils;

type
  /// <summary>比较函数，我还是决定加上 of object了，如果你觉得是个错误的决定，去掉它好了</summary>
  /// <param name='P1'>第一个要比较的参数</param>
  /// <param name='P2'>第二个要比较的参数</param>
  /// <returns>如果P1<P2，返回小于0的值，如果P1>P2返回大于0的值，如果相等，返回0</returns>
  TQRBCompare = function(P1, P2: Pointer): Integer of object;

  TQRBNode = class;
  PQRBNode = ^TQRBNode;
  TQRBTree = class;
  PQRBTree = ^TQRBTree;
  /// <summary>
  /// 删除结点通知事件，在删除一个树结点时触发
  /// </summary>
  /// <param name="ASender">触发事件的红黑树对象</param>
  /// <param name="ANode">要删除的结点</param>
  TQRBDeleteNotify = procedure(ASender: TQRBTree; ANode: TQRBNode) of object;
  // 下面三个事件我真没想到啥时需要，原Linux代码中触发了，我也就保留了
  TQRBRotateNotify = procedure(ASender: TQRBTree; AOld, ANew: TQRBNode)
    of object;
  TQRBCopyNotify = TQRBRotateNotify;
  TQRBPropagateNotify = procedure(ASender: TQRBTree; ANode, AStop: TQRBNode)
    of object;

  /// <summary>TQRBNode是一个红黑树结点记录，与Linux代码相比，增加了一个Data成员
  /// 来直接保存外部数据指针，原打算象VirtualTreeView一样设置一个DataSize，后来
  /// 觉得反正要分配两次内存，没多大区别就放弃了，当然，如果改成record的话，应该
  /// 能少一次内存分配，暂时先不做此优化，将来再说(record+record helper)。
  /// </summary>
  TQRBNode = class
  private
    FParent_Color: IntPtr;
    FLeft, FRight: TQRBNode;
    FData: Pointer;
    function GetNext: TQRBNode; inline;
    function GetParent: TQRBNode; inline;
    function GetPrior: TQRBNode; inline;
    function GetIsEmpty: Boolean; inline;
    procedure SetBlack; inline;
    function RedParent: TQRBNode; inline;
    procedure SetParentColor(AParent: TQRBNode; AColor: Integer); inline;
    function GetIsBlack: Boolean; inline;
    function GetIsRed: Boolean; inline;
    procedure SetParent(const Value: TQRBNode); inline;
    function GetLeftDeepest: TQRBNode; inline;
  public
    constructor Create; overload;
    destructor Destroy; override;
    /// <summary>
    /// 拷贝函数，复制相应的数据成员
    /// </summary>
    /// <param name="src">源结点</param>
    procedure Assign(src: TQRBNode);
    /// <summary>下一后根次序结点，我反正用不上，对应于rb_next_postorder函数</summary>
    function NextPostOrder: TQRBNode;
    /// <summary>重置为空结点，调用后IsEmpty将返回true</summary>
    procedure Clear;
    /// 下一结点
    property Next: TQRBNode read GetNext; // rb_next
    /// 前一结点
    property Prior: TQRBNode read GetPrior; // rb_prev
    /// 父结点
    property Parent: TQRBNode read GetParent write SetParent; // rb_parent
    /// 是否是空结点
    property IsEmpty: Boolean read GetIsEmpty; // RB_NODE_EMPTY
    /// 是否是黑结点
    property IsBlack: Boolean read GetIsBlack; // rb_is_black
    /// 是否为红结点
    property IsRed: Boolean read GetIsRed; // rb_is_red
    /// 右结点
    property Right: TQRBNode read FRight write FRight; // rb_right
    /// 左结点
    property Left: TQRBNode read FLeft write FLeft; // rb_left
    /// 附加数据成员
    property Data: Pointer read FData write FData; // 附加数据成员
    /// 最深的最左结点
    property LeftDeepest: TQRBNode read GetLeftDeepest;
  end;

  /// <summary>红黑树Delphi对象封装</summary>
  TQRBTree = class
  protected
    FRoot: TQRBNode;
    FCount: Integer;
    FOnCompare: TQRBCompare;
    FOnDelete: TQRBDeleteNotify;
    FOnRotate: TQRBRotateNotify;
    FOnCopy: TQRBCopyNotify;
    FOnPropagate: TQRBPropagateNotify;
    function GetIsEmpty: Boolean; inline;
    procedure RotateSetParents(AOld, ANew: TQRBNode; color: Integer); inline;
    procedure InsertNode(node: TQRBNode); inline;
    procedure EraseColor(AParent: TQRBNode); inline;
    procedure ChangeChild(AOld, ANew, Parent: TQRBNode); inline;
    function EraseAugmented(node: TQRBNode): TQRBNode; inline;
    procedure DoCopy(node1, node2: TQRBNode); inline;
    procedure DoPropagate(node1, node2: TQRBNode); inline;
    procedure InsertColor(AChild: TQRBNode); inline;
    procedure DoRotate(AOld, ANew: TQRBNode); inline;
    procedure LinkNode(node, Parent: TQRBNode; var rb_link: TQRBNode); inline;
  public
    /// <summary>构造函数，传递一个大小比较函数进去，以便在插入和查找时能够正确的区分</summary>
    constructor Create(AOnCompare: TQRBCompare); overload;
    destructor Destroy; override;
    /// <summary>删除一个结点</summary>
    /// <param name="AChild">要删除的结点</param>
    /// <returns>成功，返回被删除结点的Data数据成员地址，失败或不存在，返回nil</returns>
    /// <remarks>如果你指定的OnDelete事件响应并释放了Data成员，就不要尝试访问返回的地址</remarks>
    function Delete(AChild: TQRBNode): Pointer; // rb_erase
    /// <summary>首个结点</summary>
    function First: TQRBNode; // rb_first
    /// <summary>首个结点</summary>
    function Last: TQRBNode; // rb_last
    /// <summary>首个后根次序结点</summary>
    function FirstPostOrder: TQRBNode; // rb_first_postorder
    /// <summary>插入一个数据，比较由构造时传入的事件回调函数处理</summary>
    /// <param name="AData">数据成员</param>
    /// <returns>成功，返回true，失败，返回false</returns>
    /// <remarks>如果指定的数据相同内容已经存在，就会返回false</remarks>
    function Insert(AData: Pointer): Boolean;
    /// <summary>查找与指定的数据内容相同的结点</summary>
    /// <param name="AData">要用于搜索的数据内容</param>
    /// <returns>返回找到的结点</returns>
    function Find(AData: Pointer): TQRBNode;
    /// <summary>清除所有的结点</summary>
    procedure Clear;
    /// <summary>替换结点</summary>
    /// <param name="victim">牺牲品，要被替换的结点</param>
    /// <param name="ANew">新结点</param>
    /// <remarks>替换要自己保证内容和牺牲品一致，否则可能造成树错乱，如果不能保证,
    /// 尝试删除+添加来完成替换
    /// </remarks>
    procedure Replace(victim, ANew: TQRBNode);
    /// 判断树是否为空树
    property IsEmpty: Boolean read GetIsEmpty;
    /// 比较函数，注意不要在树插入后更改比较算法
    property OnCompare: TQRBCompare read FOnCompare write FOnCompare;
    /// 删除事件响应函数
    property OnDelete: TQRBDeleteNotify read FOnDelete write FOnDelete;
    /// 旋转事件
    property OnRotate: TQRBRotateNotify read FOnRotate write FOnRotate;
    /// 复制事件
    property OnCopy: TQRBCopyNotify read FOnCopy write FOnCopy;
    /// 扩散事件
    property OnPropagate: TQRBPropagateNotify read FOnPropagate
      write FOnPropagate;
    // 结点数量
    property Count: Integer read FCount;
  end;

  TQRBComparor = class
  private
  public
    function IntComp(P1, P2: Pointer): Integer;
    function SingleComp(P1, P2: Pointer): Integer;
    function FloatComp(P1, P2: Pointer): Integer;
    function Int64Comp(P1, P2: Pointer): Integer;
    function QStringWComp(P1, P2: Pointer): Integer;
    function QStringWCompI(P1, P2: Pointer): Integer;
    function Int2Pointer(const V: Integer): Pointer; inline;
    function Pointer2Int(const V: Pointer): Integer; inline;
  end;

var
  RBDefaultComparor: TQRBComparor;

implementation

const
  RB_RED = 0;
  RB_BLACK = 1;

  { TQRBTree }

procedure FreeObject(v:TObject);
begin
  FreeAndNil(v);
end;
procedure TQRBTree.DoCopy(node1, node2: TQRBNode);
begin
  if Assigned(FOnCopy) then
    FOnCopy(Self, node1, node2);
end;

procedure TQRBTree.DoPropagate(node1, node2: TQRBNode);
begin
  if Assigned(FOnPropagate) then
    FOnPropagate(Self, node1, node2);
end;

procedure TQRBTree.ChangeChild(AOld, ANew, Parent: TQRBNode);
begin
  if Parent <> nil then
  begin
    if Parent.Left = AOld then
      Parent.Left := ANew
    else
      Parent.Right := ANew;
  end
  else
    FRoot := ANew;
end;

procedure TQRBTree.Clear;
var
  ANode: TQRBNode;
begin
  if Assigned(OnDelete) then
  begin
    ANode := First;
    while ANode <> nil do
    begin
      OnDelete(Self, ANode);
      ANode := ANode.Next;
    end;
  end;
  FreeAndNil(FRoot);
  FCount := 0;
end;

constructor TQRBTree.Create(AOnCompare: TQRBCompare);
begin
  inherited Create;
  FOnCompare := AOnCompare;
end;

destructor TQRBTree.Destroy;
begin
  Clear;
  inherited;
end;

procedure TQRBTree.DoRotate(AOld, ANew: TQRBNode);
begin
  if Assigned(FOnRotate) then
    FOnRotate(Self, AOld, ANew);
end;

function TQRBTree.Delete(AChild: TQRBNode): Pointer;
var
  rebalance: TQRBNode;
begin
  Result := AChild.Data;
  rebalance := EraseAugmented(AChild);
  if rebalance <> nil then
    EraseColor(rebalance);
  AChild.FLeft := nil;
  AChild.FRight := nil;
  Dec(FCount);
  if Assigned(FOnDelete) then
    FOnDelete(Self, AChild);
  FreeObject(AChild);
end;

function TQRBTree.EraseAugmented(node: TQRBNode): TQRBNode;
var
  child, tmp, AParent, rebalance: TQRBNode;
  pc, pc2: IntPtr;
  successor, child2: TQRBNode;
begin
  child := node.Right;
  tmp := node.Left;
  if tmp = nil then
  begin
    pc := node.FParent_Color;
    AParent := node.Parent;
    ChangeChild(node, child, AParent);
    if Assigned(child) then
    begin
      child.FParent_Color := pc;
      rebalance := nil;
    end
    else if (pc and RB_BLACK) <> 0 then
      rebalance := AParent
    else
      rebalance := nil;
    tmp := AParent;
  end
  else if not Assigned(child) then
  begin
    tmp.FParent_Color := node.FParent_Color;
    AParent := node.Parent;
    ChangeChild(node, tmp, AParent);
    rebalance := nil;
    tmp := AParent;
  end
  else
  begin
    successor := child;
    tmp := child.Left;
    if not Assigned(tmp) then
    begin
      AParent := successor;
      child2 := successor.Right;
      DoCopy(node, successor);
    end
    else
    begin
      repeat
        AParent := successor;
        successor := tmp;
        tmp := tmp.Left;
      until tmp = nil;
      AParent.Left := successor.Right;
      child2 := successor.Right;
      successor.Right := child;
      child.Parent := successor;
      DoCopy(node, successor);
      DoPropagate(AParent, successor);
    end;
    successor.Left := node.Left;
    tmp := node.Left;
    tmp.Parent := successor;
    pc := node.FParent_Color;
    tmp := node.Parent;
    ChangeChild(node, successor, tmp);
    if Assigned(child2) then
    begin
      successor.FParent_Color := pc;
      child2.SetParentColor(AParent, RB_BLACK);
      rebalance := nil;
    end
    else
    begin
      pc2 := successor.FParent_Color;
      successor.FParent_Color := pc;
      if (pc2 and RB_BLACK) <> 0 then
        rebalance := AParent
      else
        rebalance := nil;
    end;
    tmp := successor;
  end;
  DoPropagate(tmp, nil);
  Result := rebalance;
end;

procedure TQRBTree.EraseColor(AParent: TQRBNode);
var
  node, sibling, tmp1, tmp2: TQRBNode;
begin
  node := nil;
  while (true) do
  begin
    sibling := AParent.Right;
    if node <> sibling then
    begin
{$REGION 'node<>sibling'}
      if sibling.IsRed then
{$REGION 'slbling.IsRed'}
      begin
        AParent.Right := sibling.Left;
        tmp1 := sibling.Left;
        sibling.Left := AParent;
        tmp1.SetParentColor(AParent, RB_BLACK);
        RotateSetParents(AParent, sibling, RB_RED);
        DoRotate(AParent, sibling);
        sibling := tmp1;
      end;
{$ENDREGION 'slbling.IsRed'}
      tmp1 := sibling.Right;
      if (not Assigned(tmp1)) or tmp1.IsBlack then
      begin
{$REGION 'tmp1.IsBlack'}
        tmp2 := sibling.Left;
        if (not Assigned(tmp2)) or tmp2.IsBlack then
        begin
{$REGION 'tmp2.IsBlack'}
          sibling.SetParentColor(AParent, RB_RED);
          if AParent.IsRed then
            AParent.SetBlack
          else
          begin
            node := AParent;
            AParent := node.Parent;
            if Assigned(AParent) then
              Continue;
          end;
          Break;
{$ENDREGION 'tmp2.IsBlack'}
        end;
        sibling.Left := tmp2.Right;
        tmp1 := tmp2.Right;
        tmp2.Right := sibling;
        AParent.Right := tmp2;
        if Assigned(tmp1) then
          tmp1.SetParentColor(sibling, RB_BLACK);
        DoRotate(sibling, tmp2);
        tmp1 := sibling;
        sibling := tmp2;
{$ENDREGION 'tmp1.IsBlack'}
      end;
      AParent.Right := sibling.Left;
      tmp2 := sibling.Left;
      sibling.Left := AParent;
      tmp1.SetParentColor(sibling, RB_BLACK);
      if Assigned(tmp2) then
        tmp2.Parent := AParent;
      RotateSetParents(AParent, sibling, RB_BLACK);
      DoRotate(AParent, sibling);
      Break;
{$ENDREGION 'node<>sibling'}
    end
    else
    begin
{$REGION 'RootElse'}
      sibling := AParent.Left;
      if (sibling.IsRed) then
      begin
{$REGION 'Case 1 - right rotate at AParent'}
        AParent.Left := sibling.Right;
        tmp1 := sibling.Right;
        tmp1.SetParentColor(AParent, RB_BLACK);
        RotateSetParents(AParent, sibling, RB_RED);
        DoRotate(AParent, sibling);
        sibling := tmp1;
{$ENDREGION 'Case 1 - right rotate at AParent'}
      end;
      tmp1 := sibling.Left;
      if (tmp1 = nil) or tmp1.IsBlack then
      begin
{$REGION 'tmp1.IsBlack'}
        tmp2 := sibling.Right;
        if (tmp2 = nil) or tmp2.IsBlack then
        begin
{$REGION 'tmp2.IsBlack'}
          sibling.SetParentColor(AParent, RB_RED);
          if AParent.IsRed then
            AParent.SetBlack
          else
          begin
            node := AParent;
            AParent := node.Parent;
            if Assigned(AParent) then
              Continue;
          end;
          Break;
{$ENDREGION 'tmp2.IsBlack'}
        end;
        sibling.Right := tmp2.Left;
        tmp1 := tmp2.Left;
        tmp2.Left := sibling;
        AParent.Left := tmp2;
        if Assigned(tmp1) then
          tmp1.SetParentColor(sibling, RB_BLACK);
        DoRotate(sibling, tmp2);
        tmp1 := sibling;
        sibling := tmp2;
{$ENDREGION ''tmp1.IsBlack'}
      end;
      AParent.Left := sibling.Right;
      tmp2 := sibling.Right;
      sibling.Right := AParent;
      tmp1.SetParentColor(sibling, RB_BLACK);
      if Assigned(tmp2) then
        tmp2.Parent := AParent;
      RotateSetParents(AParent, sibling, RB_BLACK);
      DoRotate(AParent, sibling);
      Break;
{$ENDREGION 'RootElse'}
    end;
  end;
end;

function TQRBTree.Find(AData: Pointer): TQRBNode;
var
  rc: Integer;
begin
  Result := FRoot;
  while Assigned(Result) do
  begin
    rc := OnCompare(AData, Result.Data);
    if rc < 0 then
      Result := Result.Left
    else if rc > 0 then
      Result := Result.Right
    else
      Break;
  end
end;

function TQRBTree.First: TQRBNode;
begin
  Result := FRoot;
  if Result <> nil then
  begin
    while Assigned(Result.Left) do
      Result := Result.Left;
  end;
end;

function TQRBTree.FirstPostOrder: TQRBNode;
begin
  if Assigned(FRoot) then
    Result := FRoot.LeftDeepest
  else
    Result := nil;
end;

function TQRBTree.GetIsEmpty: Boolean;
begin
  Result := (FRoot = nil);
end;

procedure TQRBTree.InsertColor(AChild: TQRBNode);
begin
  InsertNode(AChild);
end;

// static __always_inline void
// __rb_insert(struct rb_node *node, struct rb_root *root,
/// void (*augment_rotate)(struct rb_node *old, struct rb_node *new))
function TQRBTree.Insert(AData: Pointer): Boolean;
var
  new: PQRBNode;
  Parent, AChild: TQRBNode;
  rc: Integer;
begin
  new := @FRoot;
  Parent := nil;
  while new^ <> nil do
  begin
    rc := OnCompare(AData, new.Data);
    Parent := new^;
    if rc < 0 then
      new := @new^.FLeft
    else if rc > 0 then
      new := @new^.FRight
    else // 已存在
    begin
      Result := False;
      Exit;
    end;
  end;
  AChild := TQRBNode.Create;
  AChild.Data := AData;
  LinkNode(AChild, Parent, new^);       //把新的结点加入树
  InsertColor(AChild);                  //修正结点颜色，以满足红黑树条件
  Inc(FCount);
  Result := true;
end;

procedure TQRBTree.InsertNode(node: TQRBNode);
var
  AParent, GParent, tmp: TQRBNode;
begin
  AParent := node.RedParent;
  while true do
  begin
    if AParent = nil then                           //说明是根结点，直接设置为黑
    begin
      node.SetParentColor(nil, RB_BLACK);
      Break;
    end
    else if AParent.IsBlack then                   //如果父结点是黑色，直接插入既满足红黑树条件
      Break;
    GParent := AParent.RedParent;
    tmp := GParent.Right;
    if AParent <> tmp then
    begin
      if Assigned(tmp) and tmp.IsRed then
      begin
        tmp.SetParentColor(GParent, RB_BLACK);
        AParent.SetParentColor(GParent, RB_BLACK);
        node := GParent;
        AParent := node.Parent;
        node.SetParentColor(AParent, RB_RED);
        Continue;
      end;
      tmp := AParent.Right;
      if node = tmp then
      begin
        AParent.Right := node.Left;
        tmp := node.Left;
        node.Left := AParent;
        if Assigned(tmp) then
          tmp.SetParentColor(AParent, RB_BLACK);
        AParent.SetParentColor(node, RB_RED);
        DoRotate(AParent, node); // augment_rotate(parent,node)
        AParent := node;
        tmp := node.Right;
      end;
      GParent.Left := tmp;
      AParent.Right := GParent;
      if tmp <> nil then
        tmp.SetParentColor(GParent, RB_BLACK);
      RotateSetParents(GParent, AParent, RB_RED);
      DoRotate(GParent, AParent);
      Break;
    end
    else
    begin
      tmp := GParent.Left;
      if Assigned(tmp) and tmp.IsRed then
      begin
        tmp.SetParentColor(GParent, RB_BLACK);
        AParent.SetParentColor(GParent, RB_BLACK);
        node := GParent;
        AParent := node.Parent;
        node.SetParentColor(AParent, RB_RED);
        Continue;
      end;
      tmp := AParent.Left;
      if node = tmp then
      begin
        AParent.Left := node.Right;
        tmp := node.Right;
        node.Right := AParent;
        if tmp <> nil then
          tmp.SetParentColor(AParent, RB_BLACK);
        AParent.SetParentColor(node, RB_RED);
        DoRotate(AParent, node);
        AParent := node;
        tmp := node.Left;
      end;
      GParent.Right := tmp;
      AParent.Left := GParent;
      if tmp <> nil then
        tmp.SetParentColor(GParent, RB_BLACK);
      RotateSetParents(GParent, AParent, RB_RED);
      DoRotate(GParent, AParent);
      Break;
    end;
  end;
end;

function TQRBTree.Last: TQRBNode;
begin
  Result := FRoot;
  if Result <> nil then
  begin
    while Assigned(Result.Right) do
      Result := Result.Right;
  end;
end;

procedure TQRBTree.LinkNode(node, Parent: TQRBNode; var rb_link: TQRBNode);
begin
  node.FParent_Color := IntPtr(Parent);
  node.FLeft := nil;
  node.FRight := nil;
  rb_link := node;
end;

procedure TQRBTree.Replace(victim, ANew: TQRBNode);
var
  Parent: TQRBNode;
begin
  Parent := victim.Parent;
  ChangeChild(victim, ANew, Parent);
  if Assigned(victim.Left) then
    victim.Left.SetParent(ANew)
  else
    victim.Right.SetParent(ANew);
  ANew.Assign(victim);
end;

// __rb_rotate_set_parents(struct rb_node *old, struct rb_node *new,struct rb_root *root, int color)
{
  struct rb_node *parent = rb_parent(old);
  new->__rb_parent_color = old->__rb_parent_color;
  rb_set_parent_color(old, new, color);
  __rb_change_child(old, new, parent, root);
}
procedure TQRBTree.RotateSetParents(AOld, ANew: TQRBNode; color: Integer);
var
  AParent: TQRBNode;
begin
  AParent := AOld.Parent;
  ANew.FParent_Color := AOld.FParent_Color;
  AOld.SetParentColor(ANew, color);
  ChangeChild(AOld, ANew, AParent);
end;

{ TQRBNode }

procedure TQRBNode.Assign(src: TQRBNode);
begin
  FParent_Color := src.FParent_Color;
  FLeft := src.FLeft;
  FRight := src.FRight;
  FData := src.FData;
end;

procedure TQRBNode.Clear;
begin
  FParent_Color := IntPtr(Self);
end;

constructor TQRBNode.Create;
begin
  inherited;
end;

destructor TQRBNode.Destroy;
begin
  if Assigned(FLeft) then
    FreeObject(FLeft);
  if Assigned(FRight) then
    FreeObject(FRight);
  inherited;
end;

function TQRBNode.GetIsBlack: Boolean;
begin
  Result := (IntPtr(FParent_Color) and $1) <> 0;
end;

function TQRBNode.GetIsEmpty: Boolean;
begin
  Result := (FParent_Color = IntPtr(Self));
end;

function TQRBNode.GetIsRed: Boolean;
begin
  Result := ((IntPtr(FParent_Color) and $1) = 0);
end;

function TQRBNode.GetLeftDeepest: TQRBNode;
begin
  Result := Self;
  while true do
  begin
    if Assigned(Result.Left) then
      Result := Result.Left
    else if Assigned(Result.Right) then
      Result := Result.Right
    else
      Break;
  end;
end;

function TQRBNode.GetNext: TQRBNode;
var
  node, AParent: TQRBNode;
begin
  if IsEmpty then
    Result := nil
  else
  begin
    if Assigned(FRight) then
    begin
      Result := FRight;
      while Assigned(Result.Left) do
        Result := Result.Left;
      Exit;
    end;
    node := Self;
    repeat
      AParent := node.Parent;
      if Assigned(AParent) and (node = AParent.Right) then
        node := AParent
      else
        Break;
    until AParent = nil;
    Result := AParent;
  end;
end;

function TQRBNode.GetParent: TQRBNode;
begin
  Result := TQRBNode(IntPtr(FParent_Color) and (not $3));
end;

function TQRBNode.GetPrior: TQRBNode;
var
  node, AParent: TQRBNode;
begin
  if IsEmpty then
    Result := nil
  else
  begin
    if Assigned(FLeft) then
    begin
      Result := FLeft;
      while Assigned(Result.Right) do
        Result := Result.Right;
      Exit;
    end;
    node := Self;
    repeat
      AParent := node.Parent;
      if Assigned(Parent) and (node = AParent.Left) then
        node := AParent
      else
        Break;
    until AParent = nil;
    Result := AParent;
  end;
end;

function TQRBNode.NextPostOrder: TQRBNode;
begin
  Result := Parent;
  if Assigned(Result) and (Self = Result.Left) and Assigned(Result.Right) then
    Result := Result.Right.LeftDeepest;
end;
// struct rb_node *rb_red_parent(struct rb_node *red)

function TQRBNode.RedParent: TQRBNode;
begin
  Result := TQRBNode(FParent_Color);
end;

// rbtree.c rb_set_black(struct rb_node *rb)
procedure TQRBNode.SetBlack;
begin
  FParent_Color := FParent_Color or RB_BLACK;
end;

procedure TQRBNode.SetParent(const Value: TQRBNode);
begin
  FParent_Color := IntPtr(Value) or (IntPtr(FParent_Color) and $1);
end;

procedure TQRBNode.SetParentColor(AParent: TQRBNode; AColor: Integer);
begin
  FParent_Color := IntPtr(AParent) or AColor;
end;

{ TQHashTable }
{ TQHashTableIterator }
{ TQRBComparor }

function TQRBComparor.IntComp(P1, P2: Pointer): Integer;
var
  R: IntPtr;
begin
  R := IntPtr(P1) - IntPtr(P2);
  if R < 0 then
    Result := -1
  else if R > 0 then
    Result := 1
  else
    Result := 0;
end;

function TQRBComparor.Pointer2Int(const V: Pointer): Integer;
begin
  Result := IntPtr(V);
end;

function TQRBComparor.FloatComp(P1, P2: Pointer): Integer;
begin
  if PDouble(P1)^ < PDouble(P2)^ then
    Result := -1
  else if PDouble(P1)^ > PDouble(P2)^ then
    Result := 1
  else
    Result := 0;
end;

function TQRBComparor.Int2Pointer(const V: Integer): Pointer;
begin
  Result := Pointer(V);
end;

function TQRBComparor.Int64Comp(P1, P2: Pointer): Integer;
begin
  Result := PInt64(P1)^ - PInt64(P2)^;
end;

function TQRBComparor.QStringWComp(P1, P2: Pointer): Integer;
begin
//  Result := StrCmpW(PQCharW(PQStringW(P1)^), PQCharW(PQStringW(P2)^), False);

  Result := CompareStr((PString(P1)^),(PString(P2)^));
end;

function TQRBComparor.QStringWCompI(P1, P2: Pointer): Integer;
begin
//  Result := StrCmpW(PQCharW(PQStringW(P1)^), PQCharW(PQStringW(P2)^), true);
  Result := CompareText((PString(P1)^),(PString(P2)^));
end;

function TQRBComparor.SingleComp(P1, P2: Pointer): Integer;
begin
  if PSingle(P1)^ < PSingle(P2)^ then
    Result := -1
  else if PSingle(P1)^ > PSingle(P2)^ then
    Result := 1
  else
    Result := 0;
end;

initialization

RBDefaultComparor := TQRBComparor.Create;

finalization

FreeAndNil(RBDefaultComparor);

end.
