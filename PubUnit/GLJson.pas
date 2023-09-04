unit GLJson;

interface

uses superobject,Classes,SysUtils;

Type
  TGLJson = class;

  TGLJsonArr = class;
  IGLJsonArr = interface;

  IGLJson = interface
    procedure SetSuperJsonObj(Obj:ISuperObject);
    function GetSuperJsonObj:ISuperObject;
    function GetJsonString: String;
    procedure SetJsonString(const Value: String);
    procedure Add(const Key:string;Value:string);overload;
    procedure Add(const Key:string;Value:Int64);overload;
    procedure Add(const Key:string;Value:boolean);overload;
    procedure Add(const Key:string;value:Double);overload;
    procedure Add(const Key:string;Value:IGLJsonArr);overload;
    procedure Add(const Key:string;Value:IGLJson);overload;
    function AddObj(const Key:string):IGLJson;
    function AddArr(const Key:string):IGLJsonArr;

    function GetString(Key:string):string;
    function GetInteger(Key:string):Int64;
    function GetBoolean(Key:string):Boolean;
    function GetDouble(Key:string):Double;
    function GetArray(Key:string):IGLJsonArr;
    function GetObj(Key:string):IGLJson;
    function GetParseSucc: Boolean;
    procedure Clear;

    procedure SaveToFile(FileName: string; FormatForDisPlay: Boolean = false;
        EncodeUniCode: Boolean = false);
    procedure LoadFromFile(FileName:string);

    procedure SaveToStream(Stream:TStream;FormatForDisPlay: Boolean = false;
        EncodeUniCode: Boolean = false);
    procedure LoadFromStream(Stream:TStream);
    property JsonString: String read GetJsonString write SetJsonString;
    property ParseSucc: Boolean read GetParseSucc;
  end;

  IGLJsonArr = interface
    procedure SetSuperArr(Arr:TSuperArray);
    function AsSuperObj:ISuperObject;
    function GetBooleans(Index: Integer): Boolean;
    function GetCount: Integer;
    function GetDoubles(Index: Integer): Double;
    function GetIntegers(Index: Integer): Integer;
    function GetStrings(Index: Integer): string;
    function GetGLJsonS(Index: Integer): IGLJson;

    procedure Add(Value:string);overload;
    procedure Add(Value:Integer);overload;
    procedure Add(Value:boolean);overload;
    procedure Add(value:Double);overload;
    procedure Add(Value:IGLJson);overload;
    function AddObj:IGLJson;

    procedure Remove(Index:integer);

    property Booleans[Index: Integer]: Boolean read GetBooleans;
    property Count: Integer read GetCount;
    property Doubles[Index: Integer]: Double read GetDoubles;
    property Integers[Index: Integer]: Integer read GetIntegers;
    property Strings[Index: Integer]: string read GetStrings;
    property GLJsonS[Index: Integer]: IGLJson read GetGLJsonS;
  end;

  TGLJsonArr=class(TInterfacedObject,IGLJsonArr)
  private
    FSuperObj:ISuperObject;
    FSuperArr: TSuperArray;
    function AsSuperObj:ISuperObject;
    procedure SetSuperArr(Arr:TSuperArray);

    function ArrLen:integer;
    function GetBooleans(Index: Integer): Boolean;
    function GetCount: Integer;
    function GetDoubles(Index: Integer): Double;
    function GetIntegers(Index: Integer): Integer;
    function GetStrings(Index: Integer): string;
    function GetGLJsonS(Index: Integer): IGLJson;
  public
    constructor create;

    procedure Add(Value:string);overload;
    procedure Add(Value:Integer);overload;
    procedure Add(Value:boolean);overload;
    procedure Add(value:Double);overload;
    procedure Add(Value:IGLJson);overload;
    function AddObj:IGLJson;

    procedure Remove(Index:integer);

    property Booleans[Index: Integer]: Boolean read GetBooleans;
    property Count: Integer read GetCount;
    property Doubles[Index: Integer]: Double read GetDoubles;
    property Integers[Index: Integer]: Integer read GetIntegers;
    property Strings[Index: Integer]: string read GetStrings;
    property GLJsonS[Index: Integer]: IGLJson read GetGLJsonS;
  end;

  TGLJson = class(TInterfacedObject,IGLJson)
  private
    FParseSucc:Boolean;
    SuperJson:ISuperObject;
    function GetJsonString: String;
    function GetParseSucc: Boolean;
    procedure SetJsonString(const Value: String);
    procedure SetSuperJsonObj(Obj:ISuperObject);
    function GetSuperJsonObj:ISuperObject;
  public
    constructor create;
    procedure Add(const Key:string;Value:string);overload;
    procedure Add(const Key:string;Value:Int64); overload;
    procedure Add(const Key:string;Value:boolean);overload;
    procedure Add(const Key:string;value:Double);overload;
    procedure Add(const Key:string;Value:IGLJsonArr);overload;
    procedure Add(const Key:string;Value:IGLJson);overload;
    function AddObj(const Key:string):IGLJson;
    function AddArr(const Key:string):IGLJsonArr;

    function GetString(Key:string):string;
    function GetInteger(Key:string): Int64;
    function GetBoolean(Key:string):Boolean;
    function GetDouble(Key:string):Double;
    function GetArray(Key:string):IGLJsonArr;
    function GetObj(Key:string):IGLJson;
    procedure Clear;

    procedure SaveToFile(FileName: string; FormatForDisPlay: Boolean = false;
        EncodeUniCode: Boolean = false);
    procedure LoadFromFile(FileName:string);

    procedure SaveToStream(Stream:TStream;FormatForDisPlay: Boolean = false;
        EncodeUniCode: Boolean = false);
    procedure LoadFromStream(Stream:TStream);

    property JsonString: String read GetJsonString write SetJsonString;
    property ParseSucc: Boolean read GetParseSucc;
  end;

  function GetGLJsonObj:IGLJson;
  function GetGLJsonArr:IGLJsonArr;
implementation

{ TGLJson }

procedure TGLJson.Add(const Key: string; Value: string);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.S[Key] := Value;
end;

procedure TGLJson.Add(const Key:string;Value:Int64);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.i[Key] := Value;
end;

procedure TGLJson.Add(const Key: string; Value: boolean);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.B[Key] := Value;
end;

procedure TGLJson.Add(const Key: string; value: Double);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.D[Key] := value;
end;


constructor TGLJson.create;
begin
  SuperJson := nil;
end;

function TGLJson.GetArray(Key: string): IGLJsonArr;
var
  SuperArr:TSuperArray;
begin
  Result := nil;
  SuperArr := nil;
  if SuperJson<>nil then
    SuperArr := SuperJson.A[Key];
  if SuperArr<>nil then
  begin
    Result := TGLJsonArr.create;
    Result.SetSuperArr(SuperArr);
  end;
end;

function TGLJson.GetBoolean(Key: string): Boolean;
begin
  Result := False;
  if SuperJson<>nil then
    Result := SuperJson.B[Key];
end;

function TGLJson.GetDouble(Key: string): Double;
begin
  Result := 0;
  if SuperJson<>nil then
    Result := SuperJson.D[Key];
end;

function TGLJson.GetInteger(Key:string): Int64;
begin
  Result := 0;
  if SuperJson<>nil then
    Result := SuperJson.I[Key];
end;

function TGLJson.GetJsonString: String;
begin
  Result := '';
  if SuperJson<>nil then
    Result := SuperJson.AsString;
end;

function TGLJson.GetObj(Key: string): IGLJson;
var
  TemSuperObject:ISuperObject;
begin
  Result := nil;
  TemSuperObject := nil;
  if SuperJson<>nil then
    TemSuperObject := SuperJson.O[Key];
  if TemSuperObject<>nil then
  begin
    Result := TGLJson.create;
    Result.SetSuperJsonObj(TemSuperObject);
  end;
end;

function TGLJson.GetString(Key: string): string;
begin
  Result := '';
  if SuperJson<>nil then
    Result := SuperJson.S[Key];
end;

function TGLJson.GetSuperJsonObj: ISuperObject;
begin
  Result := SuperJson;
  if Result = nil then
  begin
    Result := SO();
    SuperJson := Result;
  end;
end;

procedure TGLJson.LoadFromFile(FileName: string);
var
  FileStream:TFileStream;
begin
  if FileExists(FileName) then
  begin
    FileStream := TFileStream.Create(FileName,fmOpenRead);
    try
      LoadFromStream(FileStream);
    finally
      FileStream.Free;
    end;
  end;
end;

procedure TGLJson.LoadFromStream(Stream: TStream);
var
  unicode:WideString;
  Ansic:AnsiString;
  Size:Integer;
  bom: array[0..1] of byte;
begin
  Stream.Position := 0;
  Stream.Read(bom[0],SizeOf(byte)*2);
  if (bom[0] = $FF) and (bom[1] = $FE) then
  begin
    Size := Stream.Size - Stream.Position;
    SetLength(unicode,size div SizeOf(WideChar));
    Stream.Read(unicode[1], Size);
    JsonString := unicode;
  end else
  begin
    Stream.Position := 0;
    Size := Stream.Size - Stream.Position;
    SetLength(Ansic,size);
    Stream.Read(Ansic[1], Size);
    JsonString := Ansic;
  end;
end;

procedure TGLJson.SaveToFile(FileName: string; FormatForDisPlay: Boolean =
    false; EncodeUniCode: Boolean = false);
begin
  if SuperJson<>nil then
    SuperJson.SaveTo(FileName,FormatForDisPlay,not EncodeUniCode);
end;

procedure TGLJson.SaveToStream(Stream: TStream; FormatForDisPlay,
  EncodeUniCode: Boolean);
begin
  if SuperJson<>nil then
    SuperJson.SaveTo(Stream,FormatForDisPlay,not EncodeUniCode);
end;

procedure TGLJson.SetJsonString(const Value: String);
begin
  SuperJson := nil;
  if (length(Value)>1) and ((Value[1]='{') or (value[1]='[')) then
  SuperJson := SO(Value);
    FParseSucc := SuperJson<>nil;
end;

procedure TGLJson.SetSuperJsonObj(Obj: ISuperObject);
begin
  SuperJson := Obj;
end;

procedure TGLJson.Add(const Key: string; Value: IGLJsonArr);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.O[Key] := Value.AsSuperObj;
end;

procedure TGLJson.Add(const Key: string; Value: IGLJson);
begin
  if SuperJson=nil then
    SuperJson := SO();
  SuperJson.O[Key] := Value.GetSuperJsonObj;
end;

function TGLJson.AddArr(const Key: string): IGLJsonArr;
begin
  if SuperJson=nil then
    SuperJson := SO();
  Result := TGLJsonArr.create;
  SuperJson.O[Key] := Result.AsSuperObj;
end;

function TGLJson.AddObj(const Key: string): IGLJson;
begin
  if SuperJson=nil then
    SuperJson := SO();

  Result := TGLJson.create;
  SuperJson.O[Key] := Result.GetSuperJsonObj;
end;

procedure TGLJson.Clear;
begin
  if SuperJson<>nil then
    SuperJson.Clear(True);
end;

function TGLJson.GetParseSucc: Boolean;
begin
  // TODO -cMM: TGLJson.GetParseSucc default body inserted
  Result := FParseSucc;
end;

procedure TGLJsonArr.Add(Value: boolean);
begin
  FSuperArr.B[ArrLen]:=Value;
end;

procedure TGLJsonArr.Add(Value: Integer);
begin
  FSuperArr.I[ArrLen]:=Value;
end;

procedure TGLJsonArr.Add(Value: string);
begin
  FSuperArr.S[ArrLen]:=Value;
end;

procedure TGLJsonArr.Add(Value: IGLJson);
begin
  FSuperArr.O[ArrLen]:=Value.GetSuperJsonObj;
end;

function TGLJsonArr.AddObj: IGLJson;
begin
  Result := TGLJson.create;
  FSuperArr.O[ArrLen]:=Result.GetSuperJsonObj;
end;

function TGLJsonArr.ArrLen: integer;
begin
  Result := FSuperArr.Length;
end;

procedure TGLJsonArr.Add(value: Double);
begin
  FSuperArr.D[ArrLen]:=Value;
end;

function TGLJsonArr.AsSuperObj: ISuperObject;
begin
  Result := FSuperObj;
end;

constructor TGLJsonArr.create;
begin
  FSuperObj := SA([]);
  FSuperArr := FSuperObj.AsArray;
end;

function TGLJsonArr.GetBooleans(Index: Integer): Boolean;
begin
  Result := False;
  if FSuperArr<>nil then
    Result := FSuperArr.B[index];
end;

function TGLJsonArr.GetCount: Integer;
begin
  Result := FSuperArr.Length;
end;

function TGLJsonArr.GetDoubles(Index: Integer): Double;
begin
  Result := 0;
  if FSuperArr<>nil then
    Result := FSuperArr.D[index];
end;

function TGLJsonArr.GetIntegers(Index: Integer): Integer;
begin
  Result := 0;
  if FSuperArr<>nil then
    Result := FSuperArr.I[index];
end;

function TGLJsonArr.GetStrings(Index: Integer): string;
begin
  Result := '';
  if FSuperArr<>nil then
    Result := FSuperArr.S[index];
end;

function TGLJsonArr.GetGLJsonS(Index: Integer): IGLJson;
var
  IObj:ISuperObject;
begin
  Result := nil;
  if FSuperArr<>nil then
    IObj := FSuperArr.O[index];
  if IObj<>nil then
  begin
    Result := TGLJson.create;
    Result.SetSuperJsonObj(IObj);
  end;
end;

procedure TGLJsonArr.Remove(Index: integer);
begin
  FSuperArr.Delete(Index);
end;

procedure TGLJsonArr.SetSuperArr(Arr: TSuperArray);
begin
  FSuperArr := Arr;
end;


function GetGLJsonObj:IGLJson;
begin
  Result := TGLJson.create;
end;
function GetGLJsonArr:IGLJsonArr;
begin
  Result := TGLJsonArr.create;
end;
end.
