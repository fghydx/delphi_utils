/// <remarks>
/// 几种算法应用
/// </remarks>
unit GLAlgorithm;

interface

uses
  Classes;

type
  TPtrCmpFunc = function(first, second: Pointer): Integer;         //比较函数
  TPtrFunc = procedure(first, second: Pointer);                    //互换函数
/// <remarks>
/// 堆排序
/// </remarks>
procedure HeapSort(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);
/// <remarks>
/// 快速排序
/// </remarks>
procedure QuickSort(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);

/// <remarks>
/// 查找，针对已经排好序的数据
/// </remarks>
function BinarySearch(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;

function BinarySearchInsertPos(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;


/// <remarks>
/// 普通顺序遍历
/// </remarks>
function Search(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;

implementation

procedure HeapAdjust(pArray: Pointer; nItemSize, nItemCount: LongWord;
  iRoot: LongWord; pCompare: TPtrCmpFunc; pSwap: TPtrFunc); forward;

procedure HeapSort(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);
var
  i: LongWord;
begin
  for i := nItemCount shr 1 - 1 downto 0 do
  begin
    HeapAdjust(pArray, nItemSize, nItemCount, i, pCompare, pSwap);
  end;
  for i := nItemCount - 1 downto 1 do
  begin
    pSwap(pArray, Pointer(LongWord(pArray) + nItemSize * i));
    HeapAdjust(pArray, nItemSize, i, 0, pCompare, pSwap);
  end;
end;

procedure QuickSort(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);
var
  i, j, pidx: LongWord;
  LItem, RItem, Pivot: Pointer;
  LIndex, RIndex: LongWord;
begin
  LIndex := 0;
  RIndex := nItemCount - 1;
  while LIndex < RIndex do
  begin
    i := LIndex;
    j := RIndex;
    pidx := (i + j) shr 1;
    Pivot := Pointer(LongWord(pArray) + nItemSize * pidx);
    repeat
      while pCompare(Pointer(LongWord(pArray) + nItemSize * i), Pivot) < 0 do Inc(i);
      while pCompare(Pointer(LongWord(pArray) + nItemSize * j), Pivot) > 0 do Dec(j);
      if i < j then
      begin
        LItem := Pointer(LongWord(pArray) + nItemSize * i);
        RItem := Pointer(LongWord(pArray) + nItemSize * j);
        pSwap(LItem, RItem);
        if i = pidx then
        begin
          pidx := j;
          Pivot := RItem;
        end
        else if j = pidx then
        begin
          pidx := i;
          Pivot := LItem;
        end;
        Inc(i);
        Dec(j);
      end
      else if i = j then Inc(i);
    until i >= j;
    if LIndex < j then
      QuickSort(Pointer(LongWord(pArray) + nItemSize * LIndex),
        nItemSize, j - LIndex + 1, pCompare, pSwap);
    LIndex := i;
  end;
end;

function BinarySearch(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;
var
  L, R, M, CR: Integer;
  ItemAddr: Pointer;
begin
  L := 0;
  R := nItemCount - 1;
  while L <= R do
  begin
    M := (L + R) shr 1;
    ItemAddr := Pointer(LongWord(pArray) + nItemSize * LongWord(M));
    CR := pCompare(ItemAddr, @Value);
    if CR = 0 then
    begin
      Result := M;
      Exit;
    end;
    if CR > 0 then R := M - 1
    else L := M + 1;
  end;
  Result := -1;
end;

function BinarySearchInsertPos(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;
var
  L, R, M, CR: Integer;
  ItemAddr: Pointer;
begin
  L := 0;
  R := nItemCount - 1;
  while L <= R do
  begin
    M := (L + R) shr 1;
    ItemAddr := Pointer(LongWord(pArray) + nItemSize * LongWord(M));
    CR := pCompare(ItemAddr, @Value);
    if CR = 0 then
    begin
      Result := M;
      Exit;
    end;
    
    if CR > 0 then
    begin
      if (M = L) or (pCompare(Pointer(LongWord(ItemAddr) - nItemSize), @Value) <= 0) then 
      begin
        Result := M;
        Exit;
      end;
      R := M - 1;
      Continue;
    end;

    if (M = R) or (pCompare(Pointer(LongWord(ItemAddr) + nItemSize), @Value) >= 0) then
    begin
      Result := M + 1;
      Exit;
    end;
    L := M + 1;
  end;
  Result := 0;
end;

function Search(pArray: Pointer; nItemSize, nItemCount: LongWord;
  pCompare: TPtrCmpFunc; const Value): Integer;
var
  i: LongWord;
begin
  Result := -1;
  if nItemCount = 0 then Exit;
  for i := 0 to nItemCount - 1 do
  begin
    if pCompare(Pointer(LongWord(pArray) + nItemSize * i), @Value) = 0 then
    begin
      Result := i;
      Exit;
    end;
  end;    
end;

procedure HeapAdjust(pArray: Pointer; nItemSize, nItemCount, iRoot: LongWord;
  pCompare: TPtrCmpFunc; pSwap: TPtrFunc);
var
  iChild: LongWord;
  Parent, Child1, Child2: Pointer;
begin
  iChild := 2 * iRoot + 1;  
  while iChild < nItemCount do
  begin
    Parent := Pointer(LongWord(pArray) + nItemSize * iRoot);
    Child1 := Pointer(LongWord(pArray) + nItemSize * iChild);
    if iChild < nItemCount - 1 then
    begin
      Child2 := Pointer(LongWord(Child1) + nItemSize);
      if pCompare(Child1, Child2) < 0 then
      begin
        Child1 := Child2;
        Inc(iChild);
      end;
    end;
    if pCompare(Parent, Child1) < 0 then
    begin
      pSwap(Parent, Child1);
      iRoot := iChild;
      iChild := iRoot * 2 + 1;
    end
    else Break;
  end;
end;

end.
