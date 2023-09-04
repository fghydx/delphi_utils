unit GLStringList;

interface

uses Classes;

Type

  IStringList = interface
    function GetStrings(Index: Integer): string; stdcall;
    procedure SetStrings(Index: Integer; const Value: string); stdcall;

    function Add(const S: string): Integer;
    function AddObject(const S: string; AObject: TObject): Integer;
    procedure Clear;
    procedure Delete(Index: Integer);
    function Find(const S: string; var Index: Integer): Boolean;
    function GetCaseSensitive: Boolean; stdcall;
    function GetDelimitedText: string; stdcall;
    function GetDelimiter: Char; stdcall;
    function GetNames(Index: Integer): string; stdcall;
    function GetObjects(Index: Integer): TObject; stdcall;
    function GetQuoteChar: Char; stdcall;
    function GetSorted: Boolean; stdcall;
    function GetText: string; stdcall;
    function GetValueFromIndex(Index: Integer): string; stdcall;
    function GetValues(Index:String): string; stdcall;
    function IndexOf(const S: string): Integer;
    procedure Insert(Index: Integer; const S: string);
    procedure InsertObject(Index: Integer; const S: string;AObject: TObject);
    procedure SetCaseSensitive(const Value: Boolean); stdcall;
    procedure SetSorted(const Value: Boolean); stdcall;
    procedure Sort;
    function IndexOfName(const Name: string): Integer;
    function IndexOfObject(AObject: TObject): Integer;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure SetDelimitedText(const Value: string); stdcall;
    procedure SetDelimiter(const Value: Char); stdcall;
    procedure SetObjects(Index: Integer; const Value: TObject); stdcall;
    procedure SetQuoteChar(const Value: Char); stdcall;
    procedure SetText(const Value: string); stdcall;
    procedure SetValueFromIndex(Index: Integer; const Value: string); stdcall;
    procedure SetValues(Index:String; const Value: string); stdcall;
    procedure AddStrings(Strings: TStrings);
    procedure Assign(Source: TPersistent);
    function Equals(Strings: TStrings): Boolean;


    property CaseSensitive: Boolean read GetCaseSensitive write SetCaseSensitive;
    property DelimitedText: string read GetDelimitedText write SetDelimitedText;
    property Delimiter: Char read GetDelimiter write SetDelimiter;
    property Names[Index: Integer]: string read GetNames;
    property Objects[Index: Integer]: TObject read GetObjects write SetObjects;
    property QuoteChar: Char read GetQuoteChar write SetQuoteChar;
    property Sorted: Boolean read GetSorted write SetSorted;
    property Strings[Index: Integer]: string read GetStrings write SetStrings;
        default;
    property Text: string read GetText write SetText;
    property ValueFromIndex[Index: Integer]: string read GetValueFromIndex write
        SetValueFromIndex;
    property Values[Index:String]: string read GetValues write SetValues;

  end;

  TGLStringList = class(TInterfacedObject,IStringList)
  private
    FStringList:TStringList;
    function GetStrings(Index: Integer): string; stdcall;
    procedure SetStrings(Index: Integer; const Value: string); stdcall;
    function GetCaseSensitive: Boolean; stdcall;
    function GetDelimitedText: string; stdcall;
    function GetDelimiter: Char; stdcall;
    function GetNames(Index: Integer): string; stdcall;
    function GetObjects(Index: Integer): TObject; stdcall;
    function GetQuoteChar: Char; stdcall;
    function GetSorted: Boolean; stdcall;
    function GetText: string; stdcall;
    function GetValueFromIndex(Index: Integer): string; stdcall;
    function GetValues(Index: String): string; stdcall;
    procedure SetCaseSensitive(const Value: Boolean); stdcall;
    procedure SetSorted(const Value: Boolean); stdcall;
    procedure SaveToFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure SetDelimitedText(const Value: string); stdcall;
    procedure SetDelimiter(const Value: Char); stdcall;
    procedure SetObjects(Index: Integer; const Value: TObject); stdcall;
    procedure SetQuoteChar(const Value: Char); stdcall;
    procedure SetText(const Value: string); stdcall;
    procedure SetValueFromIndex(Index: Integer; const Value: string); stdcall;
    procedure SetValues(Index: String; const Value: string); stdcall;
  public
    constructor Create;
    class function GetStringList:IStringList;
    destructor Destroy; override;
    function Add(const S: string): Integer;
    function AddObject(const S: string; AObject: TObject): Integer;
    procedure Clear;
    procedure AddStrings(Strings: TStrings);
    procedure Assign(Source: TPersistent);
    function Equals(Strings: TStrings): Boolean;
    procedure Delete(Index: Integer);
    procedure Sort;
    function IndexOfName(const Name: string): Integer;
    function IndexOfObject(AObject: TObject): Integer;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    function IndexOf(const S: string): Integer;
    procedure Insert(Index: Integer; const S: string);
    procedure InsertObject(Index: Integer; const S: string;AObject: TObject);
    function Find(const S: string; var Index: Integer): Boolean;
    property CaseSensitive: Boolean read GetCaseSensitive write SetCaseSensitive;
    property DelimitedText: string read GetDelimitedText write SetDelimitedText;
    property Delimiter: Char read GetDelimiter write SetDelimiter;
    property Names[Index: Integer]: string read GetNames;
    property Objects[Index: Integer]: TObject read GetObjects write SetObjects;
    property QuoteChar: Char read GetQuoteChar write SetQuoteChar;
    property Sorted: Boolean read GetSorted write SetSorted;
    property Strings[Index: Integer]: string read GetStrings write SetStrings;
        default;
    property Text: string read GetText write SetText;
    property ValueFromIndex[Index: Integer]: string read GetValueFromIndex write
        SetValueFromIndex;
    property Values[Index: String]: string read GetValues write SetValues;
  end;

  function GetStringList:IStringList;

implementation


function GetStringList:IStringList;
begin
  Result := TGLStringList.Create;
end;

constructor TGLStringList.Create;
begin
  inherited;
  FStringList := TStringList.Create;
  // TODO -cMM: TGLStringList.Create default body inserted
end;

procedure TGLStringList.Delete(Index: Integer);
begin
  FStringList.Delete(Index);
end;

destructor TGLStringList.Destroy;
begin
  FStringList.Free;
  inherited;
  // TODO -cMM: TGLStringList.Destroy default body inserted
end;

function TGLStringList.Equals(Strings: TStrings): Boolean;
begin
  Result := FStringList.Equals(Strings);
end;

function TGLStringList.Find(const S: string; var Index: Integer): Boolean;
begin
  Result := FStringList.Find(s,Index);
end;

function TGLStringList.GetCaseSensitive: Boolean;
begin
  Result := FStringList.CaseSensitive;
end;

function TGLStringList.GetDelimitedText: string;
begin
  Result := FStringList.DelimitedText;
end;

function TGLStringList.GetDelimiter: Char;
begin
  Result := FStringList.Delimiter;
end;

function TGLStringList.GetNames(Index: Integer): string;
begin
  Result := FStringList.Names[index];
end;

function TGLStringList.GetObjects(Index: Integer): TObject;
begin
  Result := FStringList.Objects[index];
end;

function TGLStringList.GetQuoteChar: Char;
begin
  Result := FStringList.QuoteChar;
end;

function TGLStringList.GetSorted: Boolean;
begin
  Result := FStringList.Sorted;
end;

class function TGLStringList.GetStringList: IStringList;
begin
  Result := Create;
end;

function TGLStringList.GetStrings(Index: Integer): string;
begin
  Result := FStringList.Strings[index];
end;

function TGLStringList.GetText: string;
begin
  Result := FStringList.Text;
end;

function TGLStringList.GetValueFromIndex(Index: Integer): string;
begin
  Result := FStringList.ValueFromIndex[index];
end;

function TGLStringList.GetValues(Index: String): string;
begin
  Result := FStringList.Values[index];
end;

function TGLStringList.IndexOf(const S: string): Integer;
begin
  result := FStringList.IndexOf(s);
end;

function TGLStringList.IndexOfName(const Name: string): Integer;
begin
  Result := FStringList.IndexOfName(name);
end;

function TGLStringList.IndexOfObject(AObject: TObject): Integer;
begin
  Result := FStringList.IndexOfObject(AObject);
end;

procedure TGLStringList.Insert(Index: Integer; const S: string);
begin
  FStringList.Insert(Index,S);
end;

procedure TGLStringList.InsertObject(Index: Integer; const S: string;
  AObject: TObject);
begin
  FStringList.InsertObject(Index,s,AObject);
end;

procedure TGLStringList.LoadFromFile(const FileName: string);
begin
  FStringList.LoadFromFile(FileName);
end;

procedure TGLStringList.LoadFromStream(Stream: TStream);
begin
  FStringList.LoadFromStream(Stream);
end;

procedure TGLStringList.SaveToFile(const FileName: string);
begin
  FStringList.SaveToFile(FileName);
end;

procedure TGLStringList.SaveToStream(Stream: TStream);
begin
  FStringList.SaveToStream(Stream);
end;

procedure TGLStringList.SetCaseSensitive(const Value: Boolean);
begin
  FStringList.CaseSensitive := Value;
end;

procedure TGLStringList.SetDelimitedText(const Value: string);
begin
  FStringList.DelimitedText := Value;
end;

procedure TGLStringList.SetDelimiter(const Value: Char);
begin
  FStringList.Delimiter := Value;
end;

procedure TGLStringList.SetObjects(Index: Integer; const Value: TObject);
begin
  FStringList.Objects[Index] := Value;
end;

procedure TGLStringList.SetQuoteChar(const Value: Char);
begin
  FStringList.QuoteChar := Value;
end;

procedure TGLStringList.SetSorted(const Value: Boolean);
begin
  FStringList.Sorted := Value;
end;

procedure TGLStringList.SetStrings(Index: Integer; const Value: string);
begin
  FStringList.Strings[Index] := Value;
end;


function TGLStringList.Add(const S: string): Integer;
begin
  Result := FStringList.Add(S);
end;

function TGLStringList.AddObject(const S: string; AObject: TObject): Integer;
begin
  Result := FStringList.AddObject(s,AObject);
end;

procedure TGLStringList.AddStrings(Strings: TStrings);
begin
  FStringList.AddStrings(Strings);
end;

procedure TGLStringList.Assign(Source: TPersistent);
begin
  FStringList.Assign(Source);
end;

procedure TGLStringList.Clear;
begin
  FStringList.Clear;
end;

procedure TGLStringList.SetText(const Value: string);
begin
  FStringList.Text := Value;
end;

procedure TGLStringList.SetValueFromIndex(Index: Integer; const Value: string);
begin
  FStringList.ValueFromIndex[Index] := Value;
end;

procedure TGLStringList.SetValues(Index: String; const Value: string);
begin
  FStringList.Values[Index] := Value;
end;

procedure TGLStringList.Sort;
begin
  FStringList.Sort;
end;

end.
