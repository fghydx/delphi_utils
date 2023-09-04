/// <remarks>
/// 利用RTTI序列化的对像基类
/// </remarks>
unit GLRTTIObjBase;

interface

uses
  TypInfo, GLStreamPatch, Classes;

const
  csSupportTypes: TTypeKinds = [tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat, tkString, tkSet, tkClass, tkMethod, tkWChar, tkLString, tkWString, tkVariant, tkArray, tkRecord, tkInterface, tkInt64, tkDynArray, tkUString, tkClassRef, tkPointer, tkProcedure {, tkMRecord}];

type
  TGLRTTIObjBaseClass = class of TGLRTTIObjBase;

  /// <remarks>
  /// 支持RTTI序列化的基类     只支持简单类型
  /// </remarks>
  TGLRTTIObjBase = class(TPersistent)
  protected
    FPropCount: Integer;
    FPropList: PPropList;
    procedure InitPropLists;
  public
    constructor Create(); virtual;
    destructor Destroy; override;
    procedure SaveToStream(AStream: TStream); virtual;
    procedure LoadFromStream(AStream: TStream); virtual;
  end;

implementation

uses
  system.SysUtils;
{ TGLRTTIObjBase }

constructor TGLRTTIObjBase.Create;
begin
  InitPropLists;
end;

destructor TGLRTTIObjBase.Destroy;
begin
  FreeMemory(FPropList);
  inherited;
end;

procedure TGLRTTIObjBase.InitPropLists;
begin
  FPropCount := GetPropList(ClassInfo, csSupportTypes, nil);
  if FPropCount > 0 then
    FPropList := GetMemory(FPropCount * SizeOf(PPropInfo));
  GetPropList(ClassInfo, csSupportTypes, FPropList);
end;

procedure TGLRTTIObjBase.LoadFromStream(AStream: TStream);
var
  I, j: Integer;
  PropName: string;
  Value: Variant;
  PropInfo: PPropInfo;
begin
  I := FPropCount;
  j := 0;
  while j < I do
  begin
    PropName := FPropList[j].NameFld.ToString;
    PropInfo := GetPropInfo(Self, PropName);
    case (PropInfo.PropType^).Kind of
      tkInteger, tkChar, tkWChar:
        begin
          if LowerCase((PropInfo.PropType^).Name) = 'byte' then
            Value := AStream.ReadByte()
          else
            Value := AStream.ReadInteger;
          SetPropValue(Self, PropName, Value);
        end;
      tkInt64:
        begin
          Value := AStream.ReadInt64;
          SetPropValue(Self, PropName, Value);
        end;
      tkFloat:
        begin
          Value := AStream.ReadExtended;
          SetPropValue(Self, PropName, Value);
        end;
      tkLString, tkString:
        begin
          Value := AStream.ReadAnsiString;
          SetRawByteStrProp(Self, PropName, Value);
        end;
      tkWString, tkUString:
        begin
          Value := AStream.ReadString;
          SetPropValue(Self, PropName, Value);
        end;
      tkRecord:
        begin

        end;
      tkEnumeration:
        begin
          Value := AStream.ReadByte;
          SetPropValue(Self, PropName, Value);
        end;
    end;
    Inc(j);
  end;
end;

procedure TGLRTTIObjBase.SaveToStream(AStream: TStream);
var
  I: integer;
  PropName: string;
  Value: Variant;
begin
  if FPropList <> nil then
  begin
    for I := 0 to FPropCount - 1 do
    begin
      PropName := FPropList[I].NameFld.ToString;

      Value := GetPropValue(Self, PropName);
      case (FPropList[I].PropType^).Kind of
        tkInteger, tkChar, tkWChar:
          begin
            if LowerCase((FPropList[I].PropType^).Name) = 'byte' then
              AStream.WriteByte(Value)
            else
              AStream.writeInteger(Value);
          end;
        tkInt64:
          begin
            AStream.WriteInt64(Value);
          end;
        tkFloat:
          begin
            AStream.WriteExtended(Value);
          end;
        tkLString, tkString:
          begin
            AStream.WriteAnsiString(Value);
          end;
        tkWString, tkUString:
          begin
            AStream.WriteString(Value);
          end;
        tkRecord:
          begin
            GetTypeData(FPropList[I].PropType^);
          end;
        tkEnumeration:
          begin
            AStream.WriteByte(Value);
          end;
      end;
    end;
  end;
end;

end.

