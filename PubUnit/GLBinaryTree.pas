unit GLBinaryTree;

interface

uses
  RTLConsts, Classes,GLTypeDef,Windows;

{
  红黑树五大性质：
    1. 每个节点要么是红色，要么黑色
    2. 根节点是黑色的
    3. 每个叶节点是黑色的
    4. 如果一个节点是红色的，那么它的2个子节点都是黑色的
    5. 对每个节点，从该节点到其子孙节点的所有路径上包含相同数目的黑节点
}

type
  TGLBinaryTree = class;
  TGLAnsiStrRBTree = class;
  TGLWideStrRBTree = class;
  TGLIntegerRBTree = class;
  TGLCardinalRBTree = class;

  TGLBinaryTreeNode = class
  protected
    fParent: TGLBinaryTreeNode;
    fLeftChild: TGLBinaryTreeNode;
    fRightChild: TGLBinaryTreeNode;
  protected
    procedure CopyFrom(Other: TGLBinaryTreeNode); virtual;
    function CompareValue(Tree: TGLBinaryTree; Other: Pointer): Integer; virtual;
    function Compare(Tree: TGLBinaryTree;
      Other: TGLBinaryTreeNode): Integer; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property Parent: TGLBinaryTreeNode read fParent;
    property LeftChild: TGLBinaryTreeNode read fLeftChild;
    property RightChild: TGLBinaryTreeNode read fRightChild;
  end;

  TGLBinaryTreeNodeProc = function(Node: TGLBinaryTreeNode; Param: Pointer):
      Boolean;
  TGLBinaryTree = class
  private
    FCount: Integer;
    procedure CheckIndex(Index: Integer);
    function GetList(Index: Integer): TGLBinaryTreeNode;
    function Iterate(Node: TGLBinaryTreeNode; Param: Pointer;
      Callback: TGLBinaryTreeNodeProc): Boolean; overload;
    procedure SetCount(const Value: Integer);
  protected
    fRoot: TGLBinaryTreeNode;
    fSentinel: TGLBinaryTreeNode;
    procedure Replace(Node, Rep: TGLBinaryTreeNode);
    procedure LeftRotate(Node: TGLBinaryTreeNode);
    procedure RightRotate(Node: TGLBinaryTreeNode);
    function GetHeight(Node: TGLBinaryTreeNode): Integer;
    procedure Insert(Node: TGLBinaryTreeNode);
    procedure Delete(Node: TGLBinaryTreeNode);
    function Extract(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
    function Find(Key: Pointer): TGLBinaryTreeNode;
    function Predecessor(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
    function Successor(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
    function Minimum(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
    function Maximum(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
    procedure ReplaceEx(Node, Rep: TGLBinaryTreeNode); virtual;
    function DoDeletionFixup(Node: TGLBinaryTreeNode): Boolean; virtual;
    procedure InsertionFixup(Node: TGLBinaryTreeNode); virtual;
    procedure DeletionFixup(x: TGLBinaryTreeNode); virtual;
    function CreateSentinel: TGLBinaryTreeNode; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    function Iterate(Param: Pointer;
      Callback: TGLBinaryTreeNodeProc): Boolean; overload;
    property Count: Integer read FCount write SetCount;
    property Root: TGLBinaryTreeNode read fRoot;
    property Sentinel: TGLBinaryTreeNode read fSentinel;
    property List[Index: Integer]: TGLBinaryTreeNode read GetList;
  end;

  TGLRBTreeNodeColor = (tncRed, tncBlack);
  TGLRBTreeNode = class(TGLBinaryTreeNode)
  protected
    fColor: TGLRBTreeNodeColor;
  public
    property Color: TGLRBTreeNodeColor read fColor;
  end;

  TGLRedBlackTree = class(TGLBinaryTree)
  protected
    procedure ReplaceEx(Node, Rep: TGLBinaryTreeNode); override;
    function DoDeletionFixup(Node: TGLBinaryTreeNode): Boolean; override;
    procedure InsertionFixup(Node: TGLBinaryTreeNode); override;
    procedure DeletionFixup(x: TGLBinaryTreeNode); override;
    function CreateSentinel: TGLBinaryTreeNode; override;
  end;

  TGLAnsiStrRBTNode = class(TGLRBTreeNode)
  protected
    function CompareValue(Tree: TGLBinaryTree; Other: Pointer): Integer; override;
    function Compare(Tree: TGLBinaryTree;
      Other: TGLBinaryTreeNode): Integer; override;
  public
    Key: AnsiString;
    Value: TObject;
  end;

  TGLAnsiStrRBTreeIterator = class
  private
    fTree: TGLAnsiStrRBTree;
    fNode: TGLAnsiStrRBTNode;
    function GetKey: AnsiString;
    function GetValue: TObject;
    procedure SetValue(const Value: TObject);
    function IsEof: Boolean;
  public
    constructor Create(Tree: TGLAnsiStrRBTree); overload;
    constructor Create(Tree: TGLAnsiStrRBTree; Key: AnsiString); overload;
    function First: TGLAnsiStrRBTreeIterator;
    function Last: TGLAnsiStrRBTreeIterator;
    function Prev: TGLAnsiStrRBTreeIterator;
    function Next: TGLAnsiStrRBTreeIterator;
    function Erase: TGLAnsiStrRBTreeIterator;
    property Eof: Boolean read IsEof;
    property Key: AnsiString read GetKey;
    property Value: TObject read GetValue write SetValue;
  end;

  TGLAnsiStrRBTree = class(TGLRedBlackTree)
  private
    fLocale: TLocale;
    fOptions: TStringCompareOptions;
    function GetItems(const Key: AnsiString): TObject;
    procedure SetItems(const Key: AnsiString; const Value: TObject);
    function GetHeights(const Key: AnsiString): Integer;
    function GetList(Index: Integer): TObject;
  public
    constructor Create; override;
    function Add(const Key: AnsiString; Value: TObject;
      Replace: Boolean = False): Boolean;
    function Delete(const Key: AnsiString): Boolean;
    function Exists(const Key: AnsiString): Boolean;
    function Predecessor(const Key: AnsiString): TGLAnsiStrRBTNode;
    function Successor(const Key: AnsiString): TGLAnsiStrRBTNode;
    property Items[const Key: AnsiString]: TObject
      read GetItems write SetItems; default;
    property List[Index: Integer]: TObject read GetList;
    property Heights[const Key: AnsiString]: Integer read GetHeights;
    property Options: TStringCompareOptions read fOptions write fOptions;
    property Locale: TLocale read fLocale write fLocale;
  end;

  TGLWideStrRBTNode = class(TGLRBTreeNode)
  protected
    function CompareValue(Tree: TGLBinaryTree; Other: Pointer): Integer; override;
    function Compare(Tree: TGLBinaryTree;
      Other: TGLBinaryTreeNode): Integer; override;
  public
    Key: WideString;
    Value: TObject;
  end;

  TGLWideStrRBTreeIterator = class
  private
    fTree: TGLWideStrRBTree;
    fNode: TGLWideStrRBTNode;
    function GetKey: WideString;
    function GetValue: TObject;
    procedure SetValue(const Value: TObject);
    function IsEof: Boolean;
  public
    constructor Create(Tree: TGLWideStrRBTree); overload;
    constructor Create(Tree: TGLWideStrRBTree; Key: WideString); overload;
    function First: TGLWideStrRBTreeIterator;
    function Last: TGLWideStrRBTreeIterator;
    function Prev: TGLWideStrRBTreeIterator;
    function Next: TGLWideStrRBTreeIterator;
    function Erase: TGLWideStrRBTreeIterator;
    property Eof: Boolean read IsEof;
    property Key: WideString read GetKey;
    property Value: TObject read GetValue write SetValue;
  end;

  TGLWideStrRBTree = class(TGLRedBlackTree)
  private
    fLocale: TLocale;
    fOptions: TStringCompareOptions;
    function GetItems(const Key: WideString): TObject;
    procedure SetItems(const Key: WideString; const Value: TObject);
    function GetHeights(const Key: WideString): Integer;
    function GetList(Index: Integer): TObject;
  public
    constructor Create; override;
    function Add(const Key: WideString; Value: TObject;
      Replace: Boolean = False): Boolean;
    function Delete(const Key: WideString): Boolean;
    function Exists(const Key: WideString): Boolean;
    function Predecessor(const Key: WideString): TGLWideStrRBTNode;
    function Successor(const Key: WideString): TGLWideStrRBTNode;
    property Items[const Key: WideString]: TObject
      read GetItems write SetItems; default;
    property List[Index: Integer]: TObject read GetList;
    property Heights[const Key: WideString]: Integer read GetHeights;
    property Options: TStringCompareOptions read fOptions write fOptions;
    property Locale: TLocale read fLocale write fLocale;
  end;

{$IFDEF UNICODE}
  TGLStringRBTree = TGLWideStrRBTree;
  TGLStringRBTreeIterator = TGLWideStrRBTreeIterator;
{$ELSE}
  TGLStringRBTree = TGLAnsiStrRBTree;
  TGLStringRBTreeIterator = TGLAnsiStrRBTreeIterator;
{$ENDIF}

  TGLIntegerRBTNode = class(TGLRBTreeNode)
  protected
    function CompareValue(Tree: TGLBinaryTree; Other: Pointer): Integer; override;
    function Compare(Tree: TGLBinaryTree;
      Other: TGLBinaryTreeNode): Integer; override;
  public
    Key: Integer;
    Value: TObject;
  end;

  TGLIntegerRBTreeIterator = class
  private
    fTree: TGLIntegerRBTree;
    fNode: TGLIntegerRBTNode;
    function GetKey: Integer;
    function GetValue: TObject;
    procedure SetValue(const Value: TObject);
    function IsEof: Boolean;
  public
    constructor Create(Tree: TGLIntegerRBTree); overload;
    constructor Create(Tree: TGLIntegerRBTree; Key: Integer); overload;
    function First: TGLIntegerRBTreeIterator;
    function Last: TGLIntegerRBTreeIterator;
    function Prev: TGLIntegerRBTreeIterator;
    function Next: TGLIntegerRBTreeIterator;
    function Erase: TGLIntegerRBTreeIterator;
    property Eof: Boolean read IsEof;
    property Key: Integer read GetKey;
    property Value: TObject read GetValue write SetValue;
  end;

  TGLIntegerRBTree = class(TGLRedBlackTree)
  private
    function GetItems(Key: Integer): TObject;
    procedure SetItems(Key: Integer; const Value: TObject);
    function GetHeights(Key: Integer): Integer;
    function GetList(Index: Integer): TObject;
  public
    function Add(Key: Integer; Value: TObject;
      Replace: Boolean = False): Boolean;
    function Delete(Key: Integer): Boolean;
    function Predecessor(Key: Integer): TGLIntegerRBTNode;
    function Successor(Key: Integer): TGLIntegerRBTNode;
    function Exists(Key: Integer): Boolean;
    function Find(Key: Integer; Value: PObject): Boolean;
    property Items[Key: Integer]: TObject read GetItems write SetItems; default;
    property List[Index: Integer]: TObject read GetList;
    property Heights[Key: Integer]: Integer read GetHeights;
  end;

  TGLCardinalRBTNode = class(TGLRBTreeNode)
  protected
    function CompareValue(Tree: TGLBinaryTree; Other: Pointer): Integer; override;
    function Compare(Tree: TGLBinaryTree;
      Other: TGLBinaryTreeNode): Integer; override;
  public
    Key: Cardinal;
    Value: TObject;
  end;

  TGLCardinalRBTreeIterator = class
  private
    fTree: TGLCardinalRBTree;
    fNode: TGLCardinalRBTNode;
    function GetKey: Cardinal;
    function GetValue: TObject;
    procedure SetValue(const Value: TObject);
    function IsEof: Boolean;
  public
    constructor Create(Tree: TGLCardinalRBTree); overload;
    constructor Create(Tree: TGLCardinalRBTree; Key: Cardinal); overload;
    function First: TGLCardinalRBTreeIterator;
    function Last: TGLCardinalRBTreeIterator;
    function Prev: TGLCardinalRBTreeIterator;
    function Next: TGLCardinalRBTreeIterator;
    function Erase: TGLCardinalRBTreeIterator;
    property Eof: Boolean read IsEof;
    property Key: Cardinal read GetKey;
    property Value: TObject read GetValue write SetValue;
  end;

  TGLCardinalRBTree = class(TGLRedBlackTree)
  private
    function GetItems(Key: Cardinal): TObject;
    procedure SetItems(Key: Cardinal; const Value: TObject);
    function GetHeights(Key: Cardinal): Integer;
    function GetList(Index: Cardinal): TObject;
  public
    function Add(Key: Cardinal; Value: TObject;
      Replace: Boolean = False): Boolean;
    function Delete(Key: Cardinal): Boolean;
    function Predecessor(Key: Cardinal): TGLCardinalRBTNode;
    function Successor(Key: Cardinal): TGLCardinalRBTNode;
    function Exists(Key: Cardinal): Boolean;
    property Items[Key: Cardinal]: TObject read GetItems write SetItems; default;
    property List[Index: Cardinal]: TObject read GetList;
    property Heights[Key: Cardinal]: Integer read GetHeights;
  end;

implementation

{ TGLAnsiStrRBTNode }
function TranslateCompareStringFlags(Options: TStringCompareOptions): LongWord;
var
  opt: TStringCompareOption;
begin
  Result := 0;
  for opt := Low(TStringCompareOption) to High(TStringCompareOption) do
  begin
    if (opt in Options) then Result := Result or COMPARE_StrING_FLAGS[opt];
  end;
end;

function ParseWinAPICompareStringReturnValue(
  RetValue: Integer): TCompareResult;
begin
  if (RetValue - 2 > 0) then Result := crGreater
  else if (RetValue - 2 = 0) then Result := crEqual
  else Result := crLess;
end;

function AnsiCompareString(const Str1, Str2: AnsiString;
  Options: TStringCompareOptions = [];
  Locale: TLocale = loUserDefault): TCompareResult;
begin
  if (Pointer(Str1) = Pointer(Str2)) then
  begin
    Result := crEqual;
    Exit;
  end;
  Result := ParseWinAPICompareStringReturnValue(CompareStringA(
    Locale_IDS[Locale],
    TranslateCompareStringFlags(Options),
    PAnsiChar(Str1),
    Length(Str1),
    PAnsiChar(Str2),
    Length(Str2)));
end;

function WideCompareString(const Str1, Str2: WideString; Options: TStringCompareOptions;
  Locale: TLocale): TCompareResult;
begin
  if (Pointer(Str1) = Pointer(Str2)) then
  begin
    Result := crEqual;
    Exit;
  end;
  Result := ParseWinAPICompareStringReturnValue(CompareStringW(Locale_IDS[Locale],
    TranslateCompareStringFlags(Options),
    PWideChar(Str1), Length(Str1), PWideChar(Str2), Length(Str2)))
end;

function TGLAnsiStrRBTNode.Compare(Tree: TGLBinaryTree;
  Other: TGLBinaryTreeNode): Integer;
begin
  with TGLAnsiStrRBTree(Tree) do
    Result := Ord(AnsiCompareString(Key, TGLAnsiStrRBTNode(Other).Key,
      Options, Locale)) - 1;
end;

function TGLAnsiStrRBTNode.CompareValue(Tree: TGLBinaryTree;
  Other: Pointer): Integer;
begin
  with TGLAnsiStrRBTree(Tree) do
    Result := Ord(AnsiCompareString(Key, AnsiString(Other),
      Options, Locale)) - 1;
end;

{ TGLWideStrRBTNode }

function TGLWideStrRBTNode.Compare(Tree: TGLBinaryTree;
  Other: TGLBinaryTreeNode): Integer;
begin
  with TGLWideStrRBTree(Tree) do
    Result := Ord(WideCompareString(Key, TGLWideStrRBTNode(Other).Key,
      Options, Locale)) - 1;
end;

function TGLWideStrRBTNode.CompareValue(Tree: TGLBinaryTree;
  Other: Pointer): Integer;
begin
  with TGLWideStrRBTree(Tree) do
    Result := Ord(WideCompareString(Key, WideString(Other),
      Options, Locale)) - 1;
end;

{ TGLIntegerRBTNode }

function TGLIntegerRBTNode.Compare(Tree: TGLBinaryTree;
  Other: TGLBinaryTreeNode): Integer;
begin
  Result := Self.Key - TGLIntegerRBTNode(Other).Key;
end;

function TGLIntegerRBTNode.CompareValue(Tree: TGLBinaryTree;
  Other: Pointer): Integer;
begin
  Result := Self.Key - Integer(Other);
end;

{ TGLCardinalRBTNode }

function TGLCardinalRBTNode.Compare(Tree: TGLBinaryTree;
  Other: TGLBinaryTreeNode): Integer;
begin
  if Self.Key > TGLCardinalRBTNode(Other).Key then Result := 1
  else if Self.Key = TGLCardinalRBTNode(Other).Key then Result := 0
  else Result := - 1
end;

function TGLCardinalRBTNode.CompareValue(Tree: TGLBinaryTree;
  Other: Pointer): Integer;
begin
  if Self.Key > Cardinal(Other) then Result := 1
  else if Self.Key = Cardinal(Other) then Result := 0
  else Result := - 1
end;

{ TGLBinaryTreeNode }

function TGLBinaryTreeNode.Compare(Tree: TGLBinaryTree;
  Other: TGLBinaryTreeNode): Integer;
begin
  Result := 0;
end;

function TGLBinaryTreeNode.CompareValue(
  Tree: TGLBinaryTree; Other: Pointer): Integer;
begin
  Result := 0;
end;

procedure TGLBinaryTreeNode.CopyFrom(Other: TGLBinaryTreeNode);
begin

end;

constructor TGLBinaryTreeNode.Create;
begin

end;

destructor TGLBinaryTreeNode.Destroy;
begin

  inherited;
end;

{ TGLBinaryTree }

procedure TGLBinaryTree.CheckIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= Self.Count) then
    TList.Error(@SListIndexError, Index);
end;

procedure TGLBinaryTree.Clear;
var
  Node, Temp: TGLBinaryTreeNode;
begin
  Node := fRoot;
  while Node <> fSentinel do
  begin
    if Node.LeftChild <> fSentinel then Node := Node.LeftChild
    else if Node.RightChild <> fSentinel then Node := Node.RightChild
    else begin
      Temp := Node;
      Node := Node.Parent;
      if Temp = Node.LeftChild then Node.fLeftChild := fSentinel
      else Node.fRightChild := fSentinel;
      Temp.Free;
    end;
  end;
  fRoot := fSentinel;
  fCount := 0;
end;

constructor TGLBinaryTree.Create;
begin
  fSentinel := CreateSentinel;
  fSentinel.fLeftChild := fSentinel;
  fSentinel.fRightChild := fSentinel;
  fRoot := fSentinel;
end;

function TGLBinaryTree.CreateSentinel: TGLBinaryTreeNode;
begin
  Result := TGLBinaryTreeNode.Create;
end;

procedure TGLBinaryTree.Delete(Node: TGLBinaryTreeNode);
begin
  Self.Extract(Node).Free;
end;

procedure TGLBinaryTree.DeletionFixup(x: TGLBinaryTreeNode);
begin

end;

destructor TGLBinaryTree.Destroy;
begin
  Clear;
  fSentinel.Free;
  inherited;
end;

function TGLBinaryTree.DoDeletionFixup(Node: TGLBinaryTreeNode): Boolean;
begin
  Result := False;
end;

function TGLBinaryTree.Extract(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
var
  x, y: TGLBinaryTreeNode;
  DoFixup: Boolean;
begin
  if (Node.LeftChild = fSentinel) or (Node.RightChild = fSentinel) then
    y := Node
  else y := Self.Successor(Node);
  x := y.LeftChild;
  if x = fSentinel then x := y.RightChild;
  x.fParent := y.Parent;
  if y.Parent = fSentinel then fRoot := x
  else if y.Parent.LeftChild = y then y.Parent.fLeftChild := x
  else y.Parent.fRightChild := x;
  DoFixup := DoDeletionFixup(y);
  if y <> node then
  begin
    Replace(Node, y);
    ReplaceEx(Node, y);
  end;
  if DoFixup then Self.DeletionFixup(x);
  Dec(fCount);
  Result := node;
end;

function TGLBinaryTree.Find(Key: Pointer): TGLBinaryTreeNode;
var
  r: Integer;
begin
  Result := Root;
  while Result <> fSentinel do
  begin
    r := Result.CompareValue(Self, Key);
    if r < 0 then Result := Result.RightChild
    else if r = 0 then Exit
    else Result := Result.LeftChild;
  end;
  if Result = fSentinel then Result := nil;  
end;

function TGLBinaryTree.GetHeight(Node: TGLBinaryTreeNode): Integer;
begin
  Result := 0;
  while Node <> fSentinel do
  begin
    Inc(Result);
    Node := Node.Parent;
  end;
end;

function TGLBinaryTree.GetList(Index: Integer): TGLBinaryTreeNode;
var
  i: Integer;
begin
  CheckIndex(Index);
  if Index < Count div 2 then
  begin
    Result := Self.Minimum(fRoot);
    for i := 0 to Index - 1 do Result := Self.Successor(Result);
  end
  else begin
    Result := Self.Maximum(fRoot);
    for i := Count - 1 downto Index + 1 do Result := Self.Predecessor(Result);
  end;
end;

{$WARNINGS OFF}
procedure TGLBinaryTree.Insert(Node: TGLBinaryTreeNode);
var
  p, c: TGLBinaryTreeNode;
  r: Integer;
begin
  Node.fLeftChild := fSentinel;
  Node.fRightChild := fSentinel;
  c := fSentinel;
  p := Self.Root;
  while p <> fSentinel do
  begin
    c := p;
    r := p.Compare(Self, Node);
    if r > 0 then p := p.LeftChild
    else if r = 0 then Exit
    else p := p.RightChild;
  end;
  Node.fParent := c;
  if c <> fSentinel then
  begin
    if r > 0 then c.fLeftChild := Node
    else c.fRightChild := Node;
  end
  else fRoot := Node;
  Self.InsertionFixup(Node);
  Inc(fCount);
end;

procedure TGLBinaryTree.InsertionFixup(Node: TGLBinaryTreeNode);
begin

end;

function TGLBinaryTree.Iterate(Node: TGLBinaryTreeNode; Param: Pointer;
  Callback: TGLBinaryTreeNodeProc): Boolean;
begin
  Result := False;
  if (Node.LeftChild <> fSentinel) and not
    Iterate(Node.LeftChild, Param, Callback) then Exit;
  if not Callback(Node, Param) then Exit;
  Result := (Node.RightChild = fSentinel) or
    Iterate(Node.RightChild, Param, Callback);
end;

function TGLBinaryTree.Iterate(Param: Pointer;
  Callback: TGLBinaryTreeNodeProc): Boolean;
begin
  Result := (fRoot = fSentinel) or Iterate(fRoot, Param, Callback);
end;

{$WARNINGS ON}

procedure TGLBinaryTree.LeftRotate(Node: TGLBinaryTreeNode);
var
  r: TGLBinaryTreeNode;
begin
  r := Node.RightChild;
  Node.fRightChild := r.LeftChild;
  r.LeftChild.fParent := Node;
  r.fParent := Node.Parent;
  if r.Parent <> fSentinel then
  begin
    if r.Parent.LeftChild = Node then r.Parent.fLeftChild := r
    else r.Parent.fRightChild := r;
  end
  else fRoot := r;
  r.fLeftChild := Node;
  Node.fParent := r;
end;

function TGLBinaryTree.Maximum(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
begin
  Result := nil;
  while Node <> fSentinel do
  begin
    Result := Node;
    Node := Node.RightChild;
  end;
end;

function TGLBinaryTree.Minimum(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
begin
  Result := nil;
  while Node <> fSentinel do
  begin
    Result := Node;
    Node := Node.LeftChild;
  end;
end;

function TGLBinaryTree.Predecessor(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
begin
  if Node.LeftChild <> fSentinel then Result := Maximum(Node.LeftChild)
  else begin
    Result := Node.Parent;
    while (Result <> fSentinel) and (Result.LeftChild = Node) do
    begin
      Node := Result;
      Result := Result.Parent;
    end;
  end;
  if Result = fSentinel then Result := nil;
end;

procedure TGLBinaryTree.Replace(Node, Rep: TGLBinaryTreeNode);
begin
  Rep.fParent := Node.Parent;
  if Node.Parent = fSentinel then fRoot := Rep
  else if Node.Parent.LeftChild = Node then Node.Parent.fLeftChild := Rep
  else Node.Parent.fRightChild := Rep;
  Rep.fLeftChild := Node.LeftChild;
  Rep.fRightChild := Node.fRightChild;
  Node.LeftChild.fParent := Rep;
  Node.RightChild.fParent := Rep;
end;

procedure TGLBinaryTree.ReplaceEx(Node, Rep: TGLBinaryTreeNode);
begin
  
end;

procedure TGLBinaryTree.RightRotate(Node: TGLBinaryTreeNode);
var
  L: TGLBinaryTreeNode;
begin
  L := Node.LeftChild;
  Node.fLeftChild := L.RightChild;
  L.RightChild.fParent := Node;
  L.fParent := Node.Parent;
  if L.Parent <> fSentinel then
  begin
    if L.Parent.LeftChild = Node then L.Parent.fLeftChild := L
    else L.Parent.fRightChild := L;
  end
  else fRoot := L;
  L.fRightChild := Node;
  Node.fParent := L;
end;

procedure TGLBinaryTree.SetCount(const Value: Integer);
begin
  FCount := Value;
end;

function TGLBinaryTree.Successor(Node: TGLBinaryTreeNode): TGLBinaryTreeNode;
begin
  if Node.RightChild <> fSentinel then Result := Minimum(Node.RightChild)
  else begin
    Result := Node.Parent;
    while (Result <> fSentinel) and (Node = Result.RightChild) do
    begin
      Node := Result;
      Result := Result.Parent;
    end;
  end;
  if Result = fSentinel then Result := nil;
end;

{ TGLRedBlackTree }

function TGLRedBlackTree.CreateSentinel: TGLBinaryTreeNode;
begin
  Result := TGLRBTreeNode.Create;
  TGLRBTreeNode(Result).fColor := tncBlack;
end;

procedure TGLRedBlackTree.DeletionFixup(x: TGLBinaryTreeNode);
var
  w: TGLRBTreeNode;
begin
  while (x <> fRoot) and (TGLRBTreeNode(x).Color = tncBlack) do
  begin
    if x = x.Parent.LeftChild then
    begin
      w := TGLRBTreeNode(x.Parent.RightChild);
      if w.Color = tncRed then
      begin
        w.fColor := tncBlack;
        TGLRBTreeNode(x.Parent).fColor := tncRed;
        LeftRotate(x.Parent);
        w := TGLRBTreeNode(x.Parent.RightChild);
      end;
      if (TGLRBTreeNode(w.RightChild).Color = tncBlack) and
        (TGLRBTreeNode(w.LeftChild).Color = tncBlack) then
      begin
        w.fColor := tncRed;
        x := x.Parent;
      end
      else begin
        if TGLRBTreeNode(w.RightChild).Color = tncBlack then
        begin
          TGLRBTreeNode(w.LeftChild).fColor := tncBlack;
          w.fColor := tncRed;
          RightRotate(w);
          w := TGLRBTreeNode(w.Parent);
        end;
        w.fColor := TGLRBTreeNode(w.Parent).Color;
        TGLRBTreeNode(w.Parent).fColor := tncBlack;
        TGLRBTreeNode(w.RightChild).fColor := tncBLACK;
        LeftRotate(w.Parent);
        x := fRoot;
      end;
    end
    else begin
      w := TGLRBTreeNode(x.Parent.LeftChild);
      if w.Color = tncRed then
      begin
        w.fColor := tncBlack;
        TGLRBTreeNode(x.Parent).fColor := tncRed;
        RightRotate(x.Parent);
        w := TGLRBTreeNode(x.Parent.LeftChild);
      end;
      if (TGLRBTreeNode(w.LeftChild).Color = tncBlack) and
        (TGLRBTreeNode(w.RightChild).Color = tncBlack) then
      begin
        w.fColor := tncRed;
        x := x.Parent;
      end
      else begin
        if TGLRBTreeNode(w.LeftChild).Color = tncBlack then
        begin
          TGLRBTreeNode(w.RightChild).fColor := tncBlack;
          w.fColor := tncRed;
          LeftRotate(w);
          w := TGLRBTreeNode(w.Parent);
        end;
        w.fColor := TGLRBTreeNode(w.Parent).Color;
        TGLRBTreeNode(w.Parent).fColor := tncBlack;
        TGLRBTreeNode(w.LeftChild).fColor := tncBLACK;
        RightRotate(w.Parent);
        x := fRoot;
      end;
    end;
  end;
  TGLRBTreeNode(x).fColor := tncBlack;
end;

function TGLRedBlackTree.DoDeletionFixup(Node: TGLBinaryTreeNode): Boolean;
begin
  Result := TGLRBTreeNode(Node).Color = tncBlack;
end;

procedure TGLRedBlackTree.InsertionFixup(Node: TGLBinaryTreeNode);
var
  grand, uncle: TGLRBTreeNode;
begin
  TGLRBTreeNode(Node).fColor := tncRed;
  while TGLRBTreeNode(Node.Parent).Color = tncRed do
  begin
    grand := TGLRBTreeNode(Node.Parent.Parent);
    if Node.Parent = grand.LeftChild then
    begin
      uncle := TGLRBTreeNode(grand.RightChild);
      if uncle.Color = tncRed then
      begin
        uncle.fColor := tncBlack;
        TGLRBTreeNode(Node.Parent).fColor := tncBlack;
        grand.fColor := tncRed;
        Node := grand;
      end
      else begin
        if Node = Node.Parent.RightChild then
        begin
          Node := TGLRBTreeNode(Node.Parent);
          Self.LeftRotate(Node);
        end;
        TGLRBTreeNode(Node.Parent).fColor := tncBlack;
        grand.fColor := tncRed;
        Self.RightRotate(grand);
      end;
    end
    else begin
      uncle := TGLRBTreeNode(grand.LeftChild);
      if uncle.Color = tncRed then
      begin
        uncle.fColor := tncBlack;
        TGLRBTreeNode(Node.Parent).fColor := tncBlack;
        grand.fColor := tncRed;
        Node := grand;
      end
      else begin
        if Node = Node.Parent.LeftChild then
        begin
          Node := TGLRBTreeNode(Node.Parent);
          Self.RightRotate(Node);
        end;
        TGLRBTreeNode(Node.Parent).fColor := tncBlack;
        grand.fColor := tncRed;
        Self.LeftRotate(grand);
      end;
    end;
  end;
  TGLRBTreeNode(fRoot).fColor := tncBlack;
end;

procedure TGLRedBlackTree.ReplaceEx(Node, Rep: TGLBinaryTreeNode);
begin
  inherited;
  TGLRBTreeNode(Rep).fColor := TGLRBTreeNode(Node).Color;
end;

{$WARNINGS ON}

{ TGLAnsiStrRBTree }

function TGLAnsiStrRBTree.Add(const Key: AnsiString; Value: TObject;
  Replace: Boolean): Boolean;
var
  Node: TGLAnsiStrRBTNode;
begin
  Node := TGLAnsiStrRBTNode(Find(Pointer(Key)));
  if Node = nil then
  begin
    Node := TGLAnsiStrRBTNode.Create;
    Node.Key := Key;
    Node.Value := Value;
    Insert(Node);
    Result := True;
  end
  else begin
    if Replace then Node.Value := Value;
    Result := False;
  end;
end;

constructor TGLAnsiStrRBTree.Create;
begin
  inherited;
  fOptions := [];
  fLocale := loUserDefault;
end;

function TGLAnsiStrRBTree.Delete(const Key: AnsiString): Boolean;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  Result := Assigned(Node);
  if Result then inherited Delete(Node);
end;

function TGLAnsiStrRBTree.Exists(const Key: AnsiString): Boolean;
begin
  Result := Find(Pointer(Key)) <> nil;
end;

function TGLAnsiStrRBTree.GetHeights(const Key: AnsiString): Integer;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if (Node = nil) or (Node.LeftChild <> Sentinel) or
    (Node.RightChild <> Sentinel) then Result := -1
  else Result := GetHeight(Node);
end;

function TGLAnsiStrRBTree.GetItems(const Key: AnsiString): TObject;
var
  Node: TGLAnsiStrRBTNode;
begin
  Node := TGLAnsiStrRBTNode(Find(Pointer(Key)));
  if Node = nil then Result := nil
  else Result := Node.Value; 
end;

function TGLAnsiStrRBTree.GetList(Index: Integer): TObject;
begin
  Result := TGLAnsiStrRBTNode(inherited List[Index]).Value;
end;

function TGLAnsiStrRBTree.Predecessor(const Key: AnsiString): TGLAnsiStrRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLAnsiStrRBTNode(inherited Predecessor(Node));
end;

procedure TGLAnsiStrRBTree.SetItems(const Key: AnsiString;
  const Value: TObject);
begin
  Add(Key, Value, True);
end;

function TGLAnsiStrRBTree.Successor(const Key: AnsiString): TGLAnsiStrRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLAnsiStrRBTNode(inherited Successor(Node));
end;

{ TGLWideStrRBTree }

function TGLWideStrRBTree.Add(const Key: WideString; Value: TObject;
  Replace: Boolean): Boolean;
var
  Node: TGLWideStrRBTNode;
begin
  Node := TGLWideStrRBTNode(Find(Pointer(Key)));
  if Node = nil then
  begin
    Node := TGLWideStrRBTNode.Create;
    Node.Key := Key;
    Node.Value := Value;
    Insert(Node);
    Result := True;
  end
  else begin
    if Replace then Node.Value := Value;
    Result := False;
  end;
end;

constructor TGLWideStrRBTree.Create;
begin
  inherited;
  fOptions := [];
  fLocale := loUserDefault;
end;

function TGLWideStrRBTree.Delete(const Key: WideString): Boolean;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  Result := Assigned(Node);
  if Result then inherited Delete(Node);
end;

function TGLWideStrRBTree.Exists(const Key: WideString): Boolean;
begin
  Result := Find(Pointer(Key)) <> nil;
end;

function TGLWideStrRBTree.GetHeights(const Key: WideString): Integer;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if (Node = nil) or (Node.LeftChild <> Sentinel) or
    (Node.RightChild <> Sentinel) then Result := -1
  else Result := GetHeight(Node);
end;

function TGLWideStrRBTree.GetItems(const Key: WideString): TObject;
var
  Node: TGLWideStrRBTNode;
begin
  Node := TGLWideStrRBTNode(Find(Pointer(Key)));
  if Node = nil then Result := nil
  else Result := Node.Value; 
end;

function TGLWideStrRBTree.GetList(Index: Integer): TObject;
begin
  Result := TGLWideStrRBTNode(inherited List[Index]).Value;
end;

function TGLWideStrRBTree.Predecessor(const Key: WideString): TGLWideStrRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLWideStrRBTNode(inherited Predecessor(Node));
end;

procedure TGLWideStrRBTree.SetItems(const Key: WideString;
  const Value: TObject);
begin
  Add(Key, Value, True);
end;

function TGLWideStrRBTree.Successor(const Key: WideString): TGLWideStrRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLWideStrRBTNode(inherited Successor(Node));
end;

{ TGLIntegerRBTree }

function TGLIntegerRBTree.Add(Key: Integer; Value: TObject;
  Replace: Boolean): Boolean;
var
  Node: TGLIntegerRBTNode;
begin
  Node := TGLIntegerRBTNode(inherited Find(Pointer(Key)));
  if Node = nil then
  begin
    Node := TGLIntegerRBTNode.Create;
    Node.Key := Key;
    Node.Value := Value;
    Insert(Node);
    Result := True;
  end
  else begin
    if Replace then Node.Value := Value;
    Result := False;
  end;
end;

function TGLIntegerRBTree.Delete(Key: Integer): Boolean;
var
  Node: TGLBinaryTreeNode;
begin
  Node := inherited Find(Pointer(Key));
  Result := Assigned(Node);
  if Result then inherited Delete(Node);
end;

function TGLIntegerRBTree.Exists(Key: Integer): Boolean;
begin
  Result := Assigned(inherited Find(Pointer(Key)));
end;

function TGLIntegerRBTree.Find(Key: Integer; Value: PObject): Boolean;
var
  Node: TGLWideStrRBTNode;
begin
  Node := TGLWideStrRBTNode(inherited Find(Pointer(Key)));
  Result := Assigned(Node);
  if Result and Assigned(Value) then Value^ := Node.Value;
end;

function TGLIntegerRBTree.GetHeights(Key: Integer): Integer;
var
  Node: TGLBinaryTreeNode;
begin
  Node := inherited Find(Pointer(Key));
  if (Node = nil) or (Node.LeftChild <> Sentinel) or
    (Node.RightChild <> Sentinel) then Result := -1
  else Result := GetHeight(Node);
end;

function TGLIntegerRBTree.GetItems(Key: Integer): TObject;
var
  Node: TGLWideStrRBTNode;
begin
  Node := TGLWideStrRBTNode(inherited Find(Pointer(Key)));
  if Node = nil then Result := nil
  else Result := Node.Value;
end;

function TGLIntegerRBTree.GetList(Index: Integer): TObject;
begin
  Result := TGLIntegerRBTNode(inherited List[Index]).Value;
end;

function TGLIntegerRBTree.Predecessor(Key: Integer): TGLIntegerRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := inherited Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLIntegerRBTNode(inherited Predecessor(Node));
end;

procedure TGLIntegerRBTree.SetItems(Key: Integer; const Value: TObject);
begin
  Add(Key, Value, True);
end;

function TGLIntegerRBTree.Successor(Key: Integer): TGLIntegerRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := inherited Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLIntegerRBTNode(inherited Successor(Node));
end;

{ TGLCardinalRBTree }

function TGLCardinalRBTree.Add(Key: Cardinal; Value: TObject;
  Replace: Boolean): Boolean;
var
  Node: TGLCardinalRBTNode;
begin
  Node := TGLCardinalRBTNode(Find(Pointer(Key)));
  if Node = nil then
  begin
    Node := TGLCardinalRBTNode.Create;
    Node.Key := Key;
    Node.Value := Value;
    Insert(Node);
    Result := True;
  end
  else begin
    if Replace then Node.Value := Value;
    Result := False;
  end;
end;

function TGLCardinalRBTree.Delete(Key: Cardinal): Boolean;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  Result := Assigned(Node);
  if Result then inherited Delete(Node);
end;

function TGLCardinalRBTree.Exists(Key: Cardinal): Boolean;
begin
  Result := Find(Pointer(Key)) <> nil;
end;

function TGLCardinalRBTree.GetHeights(Key: Cardinal): Integer;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if (Node = nil) or (Node.LeftChild <> Sentinel) or
    (Node.RightChild <> Sentinel) then Result := -1
  else Result := GetHeight(Node);
end;

function TGLCardinalRBTree.GetItems(Key: Cardinal): TObject;
var
  Node: TGLWideStrRBTNode;
begin
  Node := TGLWideStrRBTNode(Find(Pointer(Key)));
  if Node = nil then Result := nil
  else Result := Node.Value;
end;

function TGLCardinalRBTree.GetList(Index: Cardinal): TObject;
begin
  Result := TGLCardinalRBTNode(inherited List[Index]).Value;
end;

function TGLCardinalRBTree.Predecessor(Key: Cardinal): TGLCardinalRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLCardinalRBTNode(inherited Predecessor(Node));
end;

procedure TGLCardinalRBTree.SetItems(Key: Cardinal; const Value: TObject);
begin
  Add(Key, Value, True);
end;

function TGLCardinalRBTree.Successor(Key: Cardinal): TGLCardinalRBTNode;
var
  Node: TGLBinaryTreeNode;
begin
  Node := Find(Pointer(Key));
  if Node = nil then Result := nil
  else Result := TGLCardinalRBTNode(inherited Successor(Node));
end;

{ TGLAnsiStrRBTreeIterator }

constructor TGLAnsiStrRBTreeIterator.Create(Tree: TGLAnsiStrRBTree);
begin
  fTree := Tree;
  First;
end;

constructor TGLAnsiStrRBTreeIterator.Create(Tree: TGLAnsiStrRBTree;
  Key: AnsiString);
begin
  fTree := Tree;
  fNode := TGLAnsiStrRBTNode(Tree.Find(Pointer(Key)));
end;

function TGLAnsiStrRBTreeIterator.IsEof: Boolean;
begin
  Result := fNode = nil;
end;

function TGLAnsiStrRBTreeIterator.Erase: TGLAnsiStrRBTreeIterator;
var
  n: TGLAnsiStrRBTNode;
begin
  n := TGLAnsiStrRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  TGLBinaryTree(fTree).Delete(fNode);
  fNode := n;
  Result := Self;  
end;

function TGLAnsiStrRBTreeIterator.First: TGLAnsiStrRBTreeIterator;
begin
  fNode := TGLAnsiStrRBTNode(TGLBinaryTree(fTree).Minimum(fTree.Root));
  Result := Self;
end;

function TGLAnsiStrRBTreeIterator.GetKey: AnsiString;
begin
  Result := fNode.Key;
end;

function TGLAnsiStrRBTreeIterator.GetValue: TObject;
begin
  Result := fNode.Value;
end;

function TGLAnsiStrRBTreeIterator.Last: TGLAnsiStrRBTreeIterator;
begin
  fNode := TGLAnsiStrRBTNode(TGLBinaryTree(fTree).Maximum(fTree.Root));
  Result := Self;
end;

function TGLAnsiStrRBTreeIterator.Next: TGLAnsiStrRBTreeIterator;
begin
  fNode := TGLAnsiStrRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  Result := Self;
end;

function TGLAnsiStrRBTreeIterator.Prev: TGLAnsiStrRBTreeIterator;
begin
  fNode := TGLAnsiStrRBTNode(TGLBinaryTree(fTree).Predecessor(fNode));
  Result := Self;
end;

procedure TGLAnsiStrRBTreeIterator.SetValue(const Value: TObject);
begin
  fNode.Value := Value;
end;

{ TGLWideStrRBTreeIterator }

constructor TGLWideStrRBTreeIterator.Create(Tree: TGLWideStrRBTree);
begin
  fTree := Tree;
  First;
end;

constructor TGLWideStrRBTreeIterator.Create(Tree: TGLWideStrRBTree;
  Key: WideString);
begin
  fTree := Tree;
  fNode := TGLWideStrRBTNode(Tree.Find(Pointer(Key)));
end;

function TGLWideStrRBTreeIterator.IsEof: Boolean;
begin
  Result := fNode = nil;
end;

function TGLWideStrRBTreeIterator.Erase: TGLWideStrRBTreeIterator;
var
  n: TGLWideStrRBTNode;
begin
  n := TGLWideStrRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  TGLBinaryTree(fTree).Delete(fNode);
  fNode := n;
  Result := Self; 
end;

function TGLWideStrRBTreeIterator.First: TGLWideStrRBTreeIterator;
begin
  fNode := TGLWideStrRBTNode(TGLBinaryTree(fTree).Minimum(fTree.Root));
  Result := Self;
end;

function TGLWideStrRBTreeIterator.GetKey: WideString;
begin
  Result := fNode.Key;
end;

function TGLWideStrRBTreeIterator.GetValue: TObject;
begin
  Result := fNode.Value;
end;

function TGLWideStrRBTreeIterator.Last: TGLWideStrRBTreeIterator;
begin
  fNode := TGLWideStrRBTNode(TGLBinaryTree(fTree).Maximum(fTree.Root));
  Result := Self;
end;

function TGLWideStrRBTreeIterator.Next: TGLWideStrRBTreeIterator;
begin
  fNode := TGLWideStrRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  Result := Self;
end;

function TGLWideStrRBTreeIterator.Prev: TGLWideStrRBTreeIterator;
begin
  fNode := TGLWideStrRBTNode(TGLBinaryTree(fTree).Predecessor(fNode));
  Result := Self;
end;

procedure TGLWideStrRBTreeIterator.SetValue(const Value: TObject);
begin
  fNode.Value := Value;
end;

{ TGLIntegerRBTreeIterator }

constructor TGLIntegerRBTreeIterator.Create(Tree: TGLIntegerRBTree);
begin
  fTree := Tree;
  First;
end;

constructor TGLIntegerRBTreeIterator.Create(Tree: TGLIntegerRBTree;
  Key: Integer);
begin
  fTree := Tree;
  fNode := TGLIntegerRBTNode(Tree.Find(Key, nil));
end;

function TGLIntegerRBTreeIterator.Erase: TGLIntegerRBTreeIterator;
var
  n: TGLIntegerRBTNode;
begin
  n := TGLIntegerRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  TGLBinaryTree(fTree).Delete(fNode);
  fNode := n;
  Result := Self; 
end;

function TGLIntegerRBTreeIterator.First: TGLIntegerRBTreeIterator;
begin
  fNode := TGLIntegerRBTNode(TGLBinaryTree(fTree).Minimum(fTree.Root));
  Result := Self;
end;

function TGLIntegerRBTreeIterator.GetKey: Integer;
begin
  Result := fNode.Key;
end;

function TGLIntegerRBTreeIterator.GetValue: TObject;
begin
  Result := fNode.Value;
end;

function TGLIntegerRBTreeIterator.IsEof: Boolean;
begin
  Result := fNode = nil;
end;

function TGLIntegerRBTreeIterator.Last: TGLIntegerRBTreeIterator;
begin
  fNode := TGLIntegerRBTNode(TGLBinaryTree(fTree).Maximum(fTree.Root));
  Result := Self;
end;

function TGLIntegerRBTreeIterator.Next: TGLIntegerRBTreeIterator;
begin
  fNode := TGLIntegerRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  Result := Self;
end;

function TGLIntegerRBTreeIterator.Prev: TGLIntegerRBTreeIterator;
begin
  fNode := TGLIntegerRBTNode(TGLBinaryTree(fTree).Predecessor(fNode));
  Result := Self;
end;

procedure TGLIntegerRBTreeIterator.SetValue(const Value: TObject);
begin
  fNode.Value := Value;
end;

{ TGLCardinalRBTreeIterator }

constructor TGLCardinalRBTreeIterator.Create(Tree: TGLCardinalRBTree);
begin
  fTree := Tree;
  First;
end;

constructor TGLCardinalRBTreeIterator.Create(Tree: TGLCardinalRBTree;
  Key: Cardinal);
begin
  fTree := Tree;
  fNode := TGLCardinalRBTNode(Tree.Find(Pointer(Key)));
end;

function TGLCardinalRBTreeIterator.Erase: TGLCardinalRBTreeIterator;
var
  n: TGLCardinalRBTNode;
begin
  n := TGLCardinalRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  TGLBinaryTree(fTree).Delete(fNode);
  fNode := n;
  Result := Self; 
end;

function TGLCardinalRBTreeIterator.First: TGLCardinalRBTreeIterator;
begin
  fNode := TGLCardinalRBTNode(TGLBinaryTree(fTree).Minimum(fTree.Root));
  Result := Self;
end;

function TGLCardinalRBTreeIterator.GetKey: Cardinal;
begin
  Result := fNode.Key;
end;

function TGLCardinalRBTreeIterator.GetValue: TObject;
begin
  Result := fNode.Value;
end;

function TGLCardinalRBTreeIterator.IsEof: Boolean;
begin
  Result := fNode = nil;
end;

function TGLCardinalRBTreeIterator.Last: TGLCardinalRBTreeIterator;
begin
  fNode := TGLCardinalRBTNode(TGLBinaryTree(fTree).Maximum(fTree.Root));
  Result := Self;
end;

function TGLCardinalRBTreeIterator.Next: TGLCardinalRBTreeIterator;
begin
  fNode := TGLCardinalRBTNode(TGLBinaryTree(fTree).Successor(fNode));
  Result := Self;
end;

function TGLCardinalRBTreeIterator.Prev: TGLCardinalRBTreeIterator;
begin
  fNode := TGLCardinalRBTNode(TGLBinaryTree(fTree).Predecessor(fNode));
  Result := Self;
end;

procedure TGLCardinalRBTreeIterator.SetValue(const Value: TObject);
begin
  fNode.Value := Value;
end;

end.
