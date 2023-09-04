unit GLADOQueryPatch;

interface

uses ADODB,Classes,ADOInt,Variants,Windows,SysUtils;

type
  TGLADOQueryHelper = class helper for TADOQuery
  public
    function LoadFromStream(Stream: TStream): Boolean;
    function SaveToStream(Stream: TStream): Boolean;
  end;
  
  Recordset25 = interface(_Recordset)
    ['{00000556-0000-0010-8000-00AA006D2EA4}']
    procedure Save(Destination: OleVariant; PersistFormat: PersistFormatEnum); safecall;
  end;

implementation

{ TGLADOQueryHelper }

function TGLADOQueryHelper.LoadFromStream(Stream: TStream): Boolean;
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
    mRecordset.Open(TStreamAdapter.Create(Stream) as IUnknown, EmptyParam, adOpenStatic, adLockBatchOptimistic, adAsyncExecute);
    Stream.Position := 0;
    if not mRecordSet.BOF then mRecordset.MoveFirst;
    RecordSet := mRecordSet;
    OpenCursor(False);
    Resync([]);
    Result := True;
  except
    OutputDebugString(PChar('GLADOQuery.LoadFromStream ´íÎó £º'+Exception(ExceptObject).Message));
  end;
end;

function TGLADOQueryHelper.SaveToStream(Stream: TStream): Boolean;
var
  mRecordSet: Recordset25;
begin
  Result := False;
  if Recordset = nil then Exit;
  if Recordset.QueryInterface(Recordset25, mRecordSet) = 0 then
  try
    Stream.Position := 0;
    mRecordSet.Save(TStreamAdapter.Create(Stream) as IUnknown, adPersistXML);
    Stream.Position := 0;
    Result := True;
  except
    OutputDebugString(PChar('GLADOQuery.SaveToStream ´íÎó £º'+Exception(ExceptObject).Message));
  end;
end;

end.
