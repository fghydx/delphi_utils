unit GLCacheTimeWheel;

interface

uses GLTimeWheel,Windows;

type
  TGLCacheTimeWheel = class(TGLTimeWheelStr)
  public
    constructor Create(size: cardinal);
    procedure AddString(AKey, value: string; Timeout: Cardinal = 30000);overload;
    procedure AddString(AKey:string ; value: AnsiString; Timeout: Cardinal = 30000);overload;
    function GetString(AKey:string):string;
    function GetAnsiString(AKey:string):AnsiString;
    procedure AddInteger(AKey: string; value: Integer; Timeout: Cardinal = 30000);
    function GetInteger(AKey:string):integer;
    procedure AddFloat(AKey:string;value:Extended;Timeout:Cardinal = 30000);
    function GetFloat(AKey:string):Extended;
    procedure AddInt64(Akey:string;Value:Int64;Timeout: Cardinal = 30000);
    function GetInt64(Akey:string):Int64;
    function AddPointer(AKey:string;Value:Pointer;DataLen:Integer;TimeOut:Cardinal
        = 30000): Boolean;
    function GetPointer(AKey: string; out DataLen: Integer; NeedGiveBack: Boolean):
        Pointer;
    function AddDynArr(AKey:string;Value:Pointer;DataLen:Integer;TimeOut:Cardinal =
        30000): Boolean;
    function GetDynArr(AKey:string;out DynArrAddr:Pointer;NeedGiveBack:Boolean):Pointer;

    procedure UpdateTime(AKey:string;NewTimeOut:Cardinal);
  end;

implementation
uses System.SysUtils;

constructor TGLCacheTimeWheel.Create(size: cardinal);
begin
  inherited Create(size);
  // TODO -cMM: TGLCacheTimeWheel.Create default body inserted
end;

{ TGLCacheTimeWheel }

function TGLCacheTimeWheel.AddDynArr(AKey:string;Value:Pointer;DataLen:Integer;
    TimeOut:Cardinal = 30000): Boolean;
begin
  Result := AddPointer(AKey,Pointer(Integer(Value)-8),DataLen+8,TimeOut);
end;

procedure TGLCacheTimeWheel.AddFloat(AKey: string; value: Extended;
  Timeout: Cardinal);
begin
  inherited Add(Timeout,AKey,@Value,SizeOf(Extended));
end;

procedure TGLCacheTimeWheel.AddInt64(Akey: string; Value: Int64;
  Timeout: Cardinal);
begin
  inherited Add(Timeout,AKey,@Value,SizeOf(Int64));
end;

procedure TGLCacheTimeWheel.AddInteger(AKey: string; value: Integer; Timeout:
    Cardinal = 30000);
begin
  inherited Add(Timeout,AKey,@Value,SizeOf(Integer));
end;

function TGLCacheTimeWheel.AddPointer(AKey:string;Value:Pointer;
    DataLen:Integer;TimeOut:Cardinal = 30000): Boolean;
begin
  Result := inherited Add(TimeOut,AKey,Value,DataLen);
end;

procedure TGLCacheTimeWheel.AddString(AKey:string; value: AnsiString;
  Timeout: Cardinal);
begin
  inherited Add(Timeout,AKey,@Value[1],Length(Value));
end;

procedure TGLCacheTimeWheel.AddString(AKey, value: string; Timeout: Cardinal =
    30000);
begin
  inherited Add(Timeout,AKey,@Value[1],ByteLength(Value));
end;

function TGLCacheTimeWheel.GetAnsiString(AKey: string): AnsiString;
var
  P:Pointer;
  DataLen:integer;
begin
  Result := '';
  P := Find(AKey,DataLen);
  if P<>nil then
  begin
    SetLength(Result,DataLen);
    CopyMemory(@result[1],P,DataLen);
    FreeData(P);
  end;
end;

function TGLCacheTimeWheel.GetDynArr(AKey: string; out DynArrAddr: Pointer;
  NeedGiveBack: Boolean): Pointer;
var
  DataLen:integer;
begin
  Result := GetPointer(AKey,DataLen,NeedGiveBack);
  if Result<>nil then
  begin
    DynArrAddr := Pointer(integer(Result)+8);
  end;
end;

function TGLCacheTimeWheel.GetFloat(AKey: string): Extended;
var
  P:PExtended;
  DataLen:Integer;
begin
  Result := 0;
  P := Find(AKey,DataLen);
  if P<>nil then
  begin
    Result := P^;
    FreeData(P);
  end;
end;

function TGLCacheTimeWheel.GetInt64(Akey: string): Int64;
var
  P:PInt64;
  DataLen:integer;
begin
  Result := 0;
  P := Find(AKey,DataLen);
  if P<>nil then
  begin
    Result := P^;
    FreeData(P);
  end;
end;

function TGLCacheTimeWheel.GetInteger(AKey: string): integer;
var
  P:Pinteger;
  DataLen:Integer;
begin
  Result := 0;
  P := Find(AKey,DataLen);
  if P<>nil then
  begin
    result := P^;
    FreeData(P);
  end;
end;

function TGLCacheTimeWheel.GetPointer(AKey: string; out DataLen: Integer;
    NeedGiveBack: Boolean): Pointer;
begin
  Result := Find(AKey,DataLen,NeedGiveBack);
end;

function TGLCacheTimeWheel.GetString(AKey: string): string;
var
  P:Pointer;
  DataLen:integer;
begin
  Result := '';
  P := Find(AKey,DataLen);
  if P<>nil then
  begin
    SetLength(Result,DataLen div SizeOf(Char));
    CopyMemory(@result[1],P,DataLen);
    FreeData(P);
  end;
end;

procedure TGLCacheTimeWheel.UpdateTime(AKey: string; NewTimeOut: Cardinal);
begin
  inherited Update(NewTimeOut,AKey);
end;

end.
