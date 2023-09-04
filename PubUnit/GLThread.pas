unit GLThread;

interface

/// <remarks>
/// 线程补丁单元，使线程可支持CreateAnonymousThread
/// </remarks>

uses Classes;

type
  TThreadTem=class;

  TThdMethod=procedure(AParam:Pointer;Thread:TThreadTem) of object;
  TCallBack = procedure(AData:Pointer;DataLen:integer) of object;


  TThreadTem = class(TThread)
  Private
    FMethod: TThdMethod;
    FcallBack:TCallBack;
    Fparams:Pointer;
    FCallBackData: Pointer;
    FCallBackDataLen:Integer;
    procedure syncproc;
  public
    procedure Execute;override;
    constructor Create(Amethod:TThdMethod;Params:Pointer;Callback:TCallBack);

    property CallBackData: Pointer read FCallBackData write FCallBackData;
    property CallBackDataLen : integer write FCallBackDataLen;
  end;

  TThreadPack=class helper for TThread
  public
    class function CreateAnonymousThread(Amethod:TThdMethod;Params:Pointer;Callback:TCallBack):TThread; static;
  end;

var
  testInt,ThreadCount:integer;

implementation

uses Windows,SysUtils;

{ TThreadTem }

constructor TThreadTem.Create(Amethod: TThdMethod;Params:Pointer;Callback:TCallBack);
begin
  FMethod := Amethod;
  FcallBack := Callback;
  Fparams:=Params;
  FreeOnTerminate := true;
  FCallBackData := nil;
  inherited Create(False);
end;

procedure TThreadTem.Execute;
begin
  inherited;
  FMethod(Fparams,Self);
  if @FcallBack<>nil then
  begin
    Synchronize(syncproc);
    if FCallBackData<>nil then
      FreeMemory(FCallBackData);
  end;
end;

procedure TThreadTem.syncproc;
begin
  FcallBack(FCallBackData,FCallBackDataLen);
end;

{ TMyThread }

class function TThreadPack.CreateAnonymousThread(Amethod: TThdMethod;Params:Pointer;Callback:TCallBack): TThread;
var
  i:integer;
begin
  i:=InterlockedIncrement(testInt);
  Result:=TThreadTem.Create(Amethod,Params,Callback);
end;

end.
