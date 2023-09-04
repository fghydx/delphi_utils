unit GLADOQuery;

interface

uses ADODB,Classes,ADOInt,Variants,Windows,SysUtils,GLStreamPatch;

type
/// <remarks>
/// 支持将ADOQuery的数据集写入流，或从流中读取
/// </remarks>
  TGLADOQuery = class(TADOquery)
  private
//    FKeys: AnsiString;                                 //这个数据集的主键信息
  public
    function LoadFromStream(Stream: TStream): Boolean;
    function SaveToStream(Stream: TStream): Boolean;
//    property Keys: AnsiString read FKeys write FKeys;
  end;

type
  Recordset25 = interface(_Recordset)
    ['{00000556-0000-0010-8000-00AA006D2EA4}']
    procedure Save(Destination: OleVariant; PersistFormat: PersistFormatEnum); safecall;
  end;

implementation

{ TGLADOQuery }

function TGLADOQuery.LoadFromStream(Stream: TStream): Boolean;
var
  mRecordSet: _Recordset;
begin
  Result := False;
  Close;
  DestroyFields;
  mRecordSet := CoRecordset.Create;
  try
    if mRecordSet.State = adStateOpen then mRecordset.Close;
    Stream.Position := 0;
//    FKeys := Stream.ReadAnsiString;
    mRecordset.Open(TStreamAdapter.Create(Stream) as IUnknown, EmptyParam, adOpenStatic, adLockBatchOptimistic, adAsyncExecute);
    Stream.Position := 0;
    if not mRecordSet.BOF then mRecordset.MoveFirst;
    RecordSet := mRecordSet;
    inherited OpenCursor(False);
    Resync([]);
    Result := True;
  except
    OutputDebugString(PChar('GLADOQuery.LoadFromStream 错误 ：'+Exception(ExceptObject).Message));
  end;
end;

function TGLADOQuery.SaveToStream(Stream: TStream): Boolean;
var
  mRecordSet: Recordset25;
begin
  Result := False;
  if Recordset = nil then Exit;
  if Recordset.QueryInterface(Recordset25, mRecordSet) = 0 then
  try
    Stream.Position := 0;
//    Stream.WriteAnsiString(FKeys);
    mRecordSet.Save(TStreamAdapter.Create(Stream) as IUnknown, adPersistXML);
    Stream.Position := 0;
    Result := True;
  except
    OutputDebugString(PChar('GLADOQuery.SaveToStream 错误 ：'+Exception(ExceptObject).Message));
  end;
end;

end.
