/// <remarks>
/// 导出一些WIndowsAPI
/// </remarks>
unit GLWindowsAPI;

interface

uses Windows;

const
  WT_EXECUTEDEFAULT       = ULONG($00000000);
  {$EXTERNALSYM WT_EXECUTEDEFAULT }
  WT_EXECUTEINIOTHREAD    = ULONG($00000001);
  {$EXTERNALSYM WT_EXECUTEINIOTHREAD}
  WT_EXECUTEINUITHREAD    = ULONG($00000002);
  {$EXTERNALSYM WT_EXECUTEINUITHREAD}
  WT_EXECUTEINWAITTHREAD  = ULONG($00000004);
  {$EXTERNALSYM WT_EXECUTEINWAITTHREAD}
  WT_EXECUTEONLYONCE      = ULONG($00000008);
  {$EXTERNALSYM WT_EXECUTEONLYONCE}
  WT_EXECUTEINTIMERTHREAD = ULONG($00000020);
  {$EXTERNALSYM WT_EXECUTEINTIMERTHREAD}
  WT_EXECUTELONGFUNCTION  = ULONG($00000010);
  {$EXTERNALSYM WT_EXECUTELONGFUNCTION}
  WT_EXECUTEINPERSISTENTIOTHREAD  = ULONG($00000040);
  {$EXTERNALSYM WT_EXECUTEINPERSISTENTIOTHREAD}
  WT_EXECUTEINPERSISTENTTHREAD = ULONG($00000080);
  {$EXTERNALSYM WT_EXECUTEINPERSISTENTTHREAD}
  WT_TRANSFER_IMPERSONATION = ULONG($00000100);
  {$EXTERNALSYM WT_TRANSFER_IMPERSONATION}
type
  TWaitOrTimerCallback = procedure (Context: Pointer; Success: Boolean) stdcall;
 {$REGION '定时器队列相关函数'}
  function CreateTimerQueue: THandle; stdcall;
  function CreateTimerQueueTimer(out phNewTimer: THandle;             //回调函数须stdcall
    TimerQueue: THandle; CallBack: TWaitOrTimerCallback;
    Parameter: Pointer; DueTime: DWORD; Period: DWORD; Flags: ULONG): BOOL; stdcall;
  function DeleteTimerQueueEx(TimerQueue: THandle;
    CompletionEvent: THandle): BOOL; stdcall;
  function DeleteTimerQueueTimer(TimerQueue: THandle;
    Timer: THandle; CompletionEvent: THandle): BOOL; stdcall;
  function ChangeTimerQueueTimer(TimerQueue: THandle;
  Timer: THandle; DueTime: ULONG; Period: ULONG): BOOL; stdcall;
{$ENDREGION}
{$IFNDEF WIN64}
  function InterlockedCompareExchange64(var AValue:Int64;NewValue:Int64;Exchange:Int64):Int64; stdcall; external kernel32 name 'InterlockedCompareExchange64';
{$ENDIF}

function InterlockedIncrement64(var Value:Int64;IncValue:int64=1):Int64;inline;

implementation

  function CreateTimerQueueTimer; external kernel32 name 'CreateTimerQueueTimer';
  function CreateTimerQueue; external kernel32 name 'CreateTimerQueue';
  function DeleteTimerQueueEx; external kernel32 name 'DeleteTimerQueueEx';
  function DeleteTimerQueueTimer; external kernel32 name 'DeleteTimerQueueTimer';
  function ChangeTimerQueueTimer; external kernel32 name 'ChangeTimerQueueTimer';


  function InterlockedIncrement64(var Value:Int64;IncValue:int64=1):Int64;inline;
  var
    temValue:Int64;
  begin
    repeat
      temValue := Value;
    until (InterlockedCompareExchange64(Value,temValue+IncValue,temValue) = temValue);
    Result := temValue+IncValue;
  end;
end.
