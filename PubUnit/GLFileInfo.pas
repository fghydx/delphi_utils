unit GLFileInfo;

interface

uses
  SysUtils, Classes, Variants, Windows,GLTypeDef;

type
  TGLVersion = class(TPersistent)
  private
    fMinor: Integer;
    fRelease: Integer;
    fMajor: Integer;
    fBuild: Integer;
    function GetString: string;
  public
    function Compare(Other: TGLVersion): TCompareResult;
    property ToString: string read GetString;
  published
    property Major: Integer read fMajor write fMajor;
    property Minor: Integer read fMinor write fMinor;
    property Release: Integer read fRelease write fRelease;
    property Build: Integer read fBuild write fBuild;
  end;
  
  TGLFileVersionInfo = class
  private
    VersionBlock: Pointer;
    fProducTDzVersion: Variant;
    fBuildString: Variant;
    fCompanyName: Variant;
    fProductName: Variant;
    fFixedInfo: Variant;
    fVersion: TGLVersion;
    function GetCompanyName: string;
    function GetProductName: string;
    function GetProducTDzVersion: string;
  protected
    procedure GetFixedInfo;
    function GetStringInfo(const name: string): string;
  public
    constructor Create(const fileName: string);
    destructor Destroy; override;
    property ProducTDzVersion: string read GetProducTDzVersion;
    property CompanyName: string read GetCompanyName;
    property ProductName: string read GetProductName;
    property Version: TGLVersion read fVersion;
  end;

implementation

type
  TLanguageAndCodePage = packed record
    language: Word;
    codepage: Word;
  end;
  PLanguageAndCodePage = ^TLanguageAndCodePage;

procedure RaiseLastError;
var
  ErrorCode: Integer;
begin
  ErrorCode := GetLastError;
  raise Exception.Create(Format('Error %d: %s',
    [ErrorCode, SysErrorMessage(ErrorCode)]));
end;

{ TGLFileVersionInfo }

constructor TGLFileVersionInfo.Create(const fileName: string);
var
  cbSize, handle: DWORD;
begin
  fProducTDzVersion := Null;
  fBuildString := Null;
  fCompanyName := Null;
  fProductName := Null;
  fFixedInfo := Null;
  fVersion := TGLVersion.Create;
  cbSize := GetFileVersionInfoSize(PChar(fileName), handle);
  if cbSize <= 0 then RaiseLastError;
  VersionBlock := System.GetMemory(cbSize);
  if not GetFileVersionInfo(PChar(fileName), handle, cbSize,
    VersionBlock) then RaiseLastError;
  GetFixedInfo;
end;

destructor TGLFileVersionInfo.Destroy;
begin
  if Assigned(VersionBlock) then System.FreeMemory(VersionBlock);
  if Assigned(fVersion) then fVersion.Free;
  inherited;
end;

function TGLFileVersionInfo.GetCompanyName: string;
begin
  if VarIsNull(fCompanyName) then
    fCompanyName := GetStringInfo('CompanyName');
  Result := fCompanyName;
end;

procedure TGLFileVersionInfo.GetFixedInfo;
var
  fixedInfo: PVSFixedFileInfo;
  cbSize: DWORD;
begin
  if VarIsNull(fFixedInfo) then
  begin
    if VerQueryValue(VersionBlock, '\', Pointer(fixedInfo), cbSize) then
    begin
      fFixedInfo := Integer(fixedInfo);
      fVersion.Major := fixedInfo.dwFileVersionMS shr 16;
      fVersion.Minor := fixedInfo.dwFileVersionMS and $ffff;
      fVersion.Release := fixedInfo.dwFileVersionLS shr 16;
      fVersion.Build := fixedInfo.dwFileVersionLS and $ffff;
    end
    else fFixedInfo := Integer(nil);
  end;
end;

function TGLFileVersionInfo.GetProductName: string;
begin
  if VarIsNull(fProductName) then fProductName := GetStringInfo('ProductName');
  Result := fProductName;
end;

function TGLFileVersionInfo.GetProducTDzVersion: string;
begin
  if VarIsNull(fProducTDzVersion) then
  begin
    if fFixedInfo <> 0 then
    with PVSFixedFileInfo(Integer(fFixedInfo))^ do
    begin
      fProducTDzVersion := Format('%d.%d.%d.%d', [
        dwProductVersionMS shr 16, dwProductVersionMS and $ffff,
        dwProductVersionLS shr 16, dwProductVersionLS and $ffff]);
    end
    else fProducTDzVersion := '';
  end;
  Result := fProducTDzVersion;
end;

function TGLFileVersionInfo.GetStringInfo(const name: string): string;
var
  subblock: string;
  buffer: PChar;  
  cbSize: DWORD;
  i: Integer;
  transition: PLanguageAndCodePage;
begin
  Result := '';
  if not VerQueryValue(VersionBlock, '\VarFileInfo\Translation',
    Pointer(transition), cbSize) then Exit;
  for i := 0 to cbSize div SizeOf(TLanguageAndCodePage) - 1 do
  begin
    subblock := Format('StringFileInfo\%.4x%.4x\%s',
      [transition.language, transition.codepage, name]);
    if VerQueryValue(VersionBlock, PChar(subblock),
      Pointer(buffer), cbSize) then
    begin
      Result := StrPas(buffer);
      Break;
    end;
  end;
end;

{ TGLVersion }

function TGLVersion.Compare(Other: TGLVersion): TCompareResult;
begin
  if Self.Major > Other.Major then
  begin
    Result := crGreater; Exit;
  end;
  if Self.Major < Other.Major then
  begin
    Result := crLess; Exit;
  end;

  if Self.Minor > Other.Minor then
  begin
    Result := crGreater; Exit;
  end;
  if Self.Minor < Other.Minor then
  begin
    Result := crLess; Exit;
  end;
  
  if Self.Release > Other.Release then
  begin
    Result := crGreater; Exit;
  end;
  if Self.Release < Other.Release then
  begin
    Result := crLess; Exit;
  end;
  
  if Self.Build > Other.Build then
  begin
    Result := crGreater; Exit;
  end;
  if Self.Build < Other.Build then
  begin
    Result := crLess; Exit;
  end;

  Result := crEqual;
end;

function TGLVersion.GetString: string;
begin
  Result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

end.
