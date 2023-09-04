unit GLConfig;

interface

uses IniFiles,TypInfo,System.Classes;

const
  csSupportTypes: TTypeKinds = [tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat,
    tkString, tkSet, tkClass, tkMethod, tkWChar, tkLString, tkWString,
    tkVariant, tkArray, tkRecord, tkInterface, tkInt64, tkDynArray, tkUString,
    tkClassRef, tkPointer, tkProcedure {, tkMRecord}];

Type
{$m+}
/// <remarks>
/// 配置文件父类，继承此类，添加属性，会自动读取属性值和保存值到Ini文件
/// </remarks>
  TGLConfig = class
  private
    FIni:TIniFile;
    FPropCount: Integer;
    FPropList: PPropList;
    FReadOnly: Boolean;
    FStringListDelimiter: Char;
    procedure InitPropLists;
  public
    procedure LoadProPValue;
    procedure SaveProPValue;

    constructor Create(IniFile:string);
    destructor Destroy; override;

    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property StringListDelimiter: Char read FStringListDelimiter write
        FStringListDelimiter;
  end;
{$M-}
implementation
uses  SysUtils;
{ TGLConfig }

constructor TGLConfig.Create(IniFile:string);
begin
  FReadOnly := false;
  FStringListDelimiter := ',';
  FIni := TIniFile.Create(IniFile);
  InitPropLists;
  LoadProPValue;
end;

destructor TGLConfig.Destroy;
begin
  SaveProPValue;
  FIni.Free;
  FreeMemory(FPropList);
  inherited;
end;

procedure TGLConfig.InitPropLists;
begin
  FPropCount := GetPropList(ClassInfo, csSupportTypes, nil);
  if FPropCount > 0 then
    FPropList := GetMemory(FPropCount * SizeOf(PPropInfo));
  GetPropList(ClassInfo, csSupportTypes, FPropList);
end;

procedure TGLConfig.LoadProPValue;
var
  I: Integer;
  PropName,str:string;
  value:Variant;
  Value1:TStringList;
begin
  if FPropList <> nil then
  begin
    for i := 0 to FPropCount - 1 do
    begin
      PropName := FPropList[i].NameFld.ToString;
      case (FPropList[i].PropType^).Kind of
        tkInteger,tkChar,tkInt64:
          begin
            value := FIni.ReadInteger(Self.ClassName,PropName,0);
          end;
        tkFloat:
          begin
            value := FIni.ReadFloat(Self.ClassName,PropName,0);
          end;
        tkString,tkLString,tkUString:
          begin
             value := FIni.ReadString(Self.ClassName,PropName,'');
          end;
        tkEnumeration:
          begin
            str := FIni.ReadString(Self.ClassName,PropName,'False');
            value := StrToBool(str);
          end;
        tkClass:
          begin
            if GetTypeData(FPropList[i].PropType^).ClassType = TStringList then
            begin
              Value1 := TStringList(GetObjectProp(Self, PropName));
              if value1=nil then
                value1 := TStringList.Create;
              value1.StrictDelimiter := true;
              value1.Delimiter := FStringListDelimiter;
              str := FIni.ReadString(Self.ClassName, PropName, '');
              Value1.DelimitedText := str;
              SetObjectProp(self, PropName, Value1);
              continue;
            end;
          end;
      end;
      SetPropValue(Self,PropName,value);
    end;
  end;
end;

procedure TGLConfig.SaveProPValue;
var
  I:integer;
  PropName,str:string;
  value:Variant;
  value1: TStringList;
begin
  if FPropList <> nil then
  begin
    for i := 0 to FPropCount - 1 do
    begin
      PropName := FPropList[i].NameFld.ToString;
      case (FPropList[i].PropType^).Kind of
        tkInteger, tkChar, tkInt64, tkFloat, tkString, tkLString,tkUString, tkEnumeration:
          Value := GetPropValue(Self, PropName);
        tkClass:
          begin
            if GetTypeData(FPropList[i].PropType^).ClassType = TStringList then
            begin
              Value1 := TStringList(GetObjectProp(Self, PropName));
              if Value1 <> nil then
              begin
                value1.Delimiter := FStringListDelimiter;
                str := value1.DelimitedText;
                Value1.Free;
              end;
              if not FReadOnly then
                Fini.WriteString(Self.ClassName, PropName, str);
              Continue;
            end;
          end;
      end;

      if FReadOnly then continue;

      try
        case (FPropList[i].PropType^).Kind of
          tkInteger,tkChar,tkInt64:
            begin
              Fini.WriteInteger(Self.ClassName,PropName,value);
            end;
          tkFloat:
            begin
              Fini.WriteFloat(Self.ClassName,PropName,value);
            end;
          tkString,tkLString,tkUString:
            begin
               Fini.WriteString(Self.ClassName,PropName,value);
            end;
          tkEnumeration:
            begin
              str := BoolToStr(value,true);
              FIni.WriteString(Self.ClassName,PropName,value);
            end;
        end;
      finally
        VarClear(Value);
      end;
    end;
  end;
end;

end.
