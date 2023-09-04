unit GLMemPool;

interface

/// <remarks>
/// 环形内存池，不支持自动扩容
/// </remarks>

Type
  Pmem = ^Tmem;
  Tmem = Record
  private
    Fmem:Pointer;
    FmemSize:Integer;
    FPosition: Integer;

    procedure SetPosition(const Value: Integer);
  public
    procedure WriteBuffer(const Buff;size:integer);
    procedure ReadBuffer(var Buff;Size:integer);

    property Position: Integer read FPosition write SetPosition;
    property Size : Integer read FmemSize;
    property mem : Pointer read Fmem;
  end;

  TGLMemPool = class
  private
    Fmem:Pointer;
    FPoolSize:Cardinal;
    FMemStart:Cardinal;
  public
    constructor Create(APoolSize:Cardinal);
    destructor Destroy; override;
    function GetMem(ASize:Cardinal): TMem;
  end;

implementation

{ MemPool }

constructor TGLMemPool.Create(APoolSize: Cardinal);
begin
  Fmem := GetMemory(APoolSize);
  FPoolSize := APoolSize;
  FMemStart := 0;
end;

destructor TGLMemPool.Destroy;
begin
  FreeMemory(Fmem);
  inherited;
end;

function TGLMemPool.GetMem(ASize:Cardinal): TMem;
begin
  if ASize+FMemStart>FPoolSize then FMemStart := 0;

  Result.Fmem := Pointer(Integer(Fmem)+FMemStart);
  Result.FmemSize := ASize;
  Result.Position := 0;

  FMemStart := FMemStart+ASize;
end;

{ Tmem }

procedure Tmem.ReadBuffer(var Buff; Size: integer);
var
  CurrPos : Cardinal;
begin
  CurrPos := Longint(Fmem) + FPosition;
  System.Move(Pointer(CurrPos)^, Buff,  Size);
  FPosition := FPosition + Size;
end;

procedure Tmem.SetPosition(const Value: Integer);
begin
  FPosition := Value;
end;

procedure Tmem.WriteBuffer(const Buff; size: integer);
var
  CurrPos : Cardinal;
begin
  CurrPos := Longint(Fmem) + FPosition;
  System.Move(Buff, Pointer(CurrPos)^, Size);
  FPosition := FPosition + size;
end;

end.
