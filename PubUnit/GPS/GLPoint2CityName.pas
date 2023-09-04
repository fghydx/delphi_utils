unit GLPoint2CityName;

interface
uses Classes,GLStreamPatch;

Type
  TPointF = packed Record
    lng:Single;
    lat:Single;
  End;

  TPointFArr = array of TPointf;

  TTpointFarres = array of TPointFarr;

  TCityPointInfo = packed record
    CityName:String;
    TpointFarres:TTpointFarres;
    PolyGonMaxPoint:TPointF;
    PolyGonMinPoint:TPointF;
    procedure WriteToStream(Stream:TStream);
    procedure ReadFromStream(Stream:TStream);
  end;

  TCityPointInfoLst = array of TCityPointInfo;

  TGLPointTCityName = class
  private
    CityPointInfoLst : TCityPointInfoLst;
  public
    constructor create;overload;
    constructor create(ResourceFile:STring);overload;
    destructor Destroy; override;
    function GetPointCityName(lat,lng:Double):String;
    function GetALLCityName:String;
  end;

implementation
{$IFDEF UsePointRes}
{$R DataRes}
{$EndIF}

uses SysUtils;

function PointIsInPolygon(const Polygon : TPointFArr;const APoint:TPointF): Boolean;
var
  iSum, iCount, iIndex: Integer;
  dLon1, dLon2, dLat1, dLat2, dLon: double;
begin
  Result := False;
  if (Length(Polygon) < 3) then
  begin
    Result := False;
    Exit;
  end;
  iSum := 0;
  iCount := Length(Polygon);
  for iIndex :=0 to iCount - 1 do
  begin
    if (iIndex = iCount - 1) then
    begin
      dLon1 := Polygon[iIndex].lng;
      dLat1 := Polygon[iIndex].lat;
      dLon2 := Polygon[0].lng;
      dLat2 := Polygon[0].lat;
    end
    else
    begin
      dLon1 := Polygon[iIndex].lng;
      dLat1 := Polygon[iIndex].lat;
      dLon2 := Polygon[iIndex + 1].lng;
      dLat2 := Polygon[iIndex + 1].lat;
    end;

    if ((APoint.Lat >= dLat1) and (APoint.Lat < dLat2)) or ((APoint.Lat>=dLat2) and (APoint.Lat < dLat1)) then
    begin
      if (abs(dLat1 - dLat2) > 0) then
      begin
        dLon := dLon1 - ((dLon1 -dLon2) * (dLat1 -APoint.Lat)) / (dLat1 - dLat2);
        if (dLon < APoint.lng) then
          Inc(iSum);
      end;
    end;
  end;
  if (iSum mod 2 <> 0) then
    Result := True;
end;

{ TCityPointInfo }

procedure TCityPointInfo.ReadFromStream(Stream: TStream);
var
  Polygon:byte;
  I,PointCount:integer;
begin
  FillChar(self,sizeof(TCityPointInfo),0);
  CityName := stream.ReadAnsiString();
  stream.ReadBuffer(PolyGonMaxPoint,SizeOf(TPointF));
  stream.ReadBuffer(PolyGonMinPoint,SizeOf(TPointF));
  Polygon := stream.ReadByte();
  SetLength(TpointFarres,Polygon);
  for I := 0 to Polygon - 1 do
  begin
    PointCount := stream.ReadInteger();
    SetLength(TpointFarres[I],PointCount);
    stream.ReadBuffer(TpointFarres[I][0],sizeof(TPointF)*PointCount);
  end;   
end;

procedure TCityPointInfo.WriteToStream(Stream: TStream);
var
  I:integer;
  tem:TPointFArr;
begin
  stream.WriteAnsiString(CityName);
  Stream.WriteBuffer(PolyGonMaxPoint,SizeOf(TPointF));
  Stream.WriteBuffer(PolyGonMinPoint,SizeOf(TPointF));
  stream.WriteByte(length(TpointFarres));
  for I := 0 to length(TpointFarres) - 1 do
  begin
    tem := TpointFarres[I];
    if tem<>nil then
    begin
      stream.writeInteger(length(tem));
      Stream.WriteBuffer(tem[0],sizeof(TPointF)*length(tem));
    end;
  end;
end;

{ TPointTCityName }

constructor TGLPointTCityName.create;
var
  Res:TResourceStream;
  count,i:Integer;
begin
  try
    Res := TResourceStream.Create(HInstance,'CONVERTDATA','DATA');
    try
      count := Res.ReadInteger();
      if count>0 then
      begin
        setlength(CityPointInfoLst,count);
        for I := 0 to count - 1 do
        begin
          CityPointInfoLst[I].ReadFromStream(Res);
        end;
      end;
    finally
      Res.Free;
    end;
  except
    raise Exception.Create('读取资源文件失败,是否没添加{$R DataRes.Res}?');
  end;
end;

constructor TGLPointTCityName.create(ResourceFile: STring);
var
  memFileStream:TGLMapFileStream;
  count,i:Integer;
begin
  memFileStream := TGLMapFileStream.Create(ResourceFile);
  try
    count := memFileStream.ReadInteger();
    if count>0 then
    begin
      setlength(CityPointInfoLst,count);
      for I := 0 to count - 1 do
      begin
        CityPointInfoLst[I].ReadFromStream(memFileStream);
      end;
    end
  finally
    memFileStream.Free;
  end;
end;

destructor TGLPointTCityName.Destroy;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to Length(CityPointInfoLst) - 1 do
  begin
    for j := 0 to Length(CityPointInfoLst[I].TpointFarres) - 1 do
    begin
      SetLength(CityPointInfoLst[I].TpointFarres[J],0);
    end;
    SetLength(CityPointInfoLst[I].TpointFarres,0);
  end;
  SetLength(CityPointInfoLst,0);
  inherited;
end;

function TGLPointTCityName.GetALLCityName: String;
var
  I:Integer;
begin
  Result := '';
  for I := 0 to Length(CityPointInfoLst) - 1 do
  begin
    Result := Result + CityPointInfoLst[I].CityName+#13#10;
  end;  
end;

function TGLPointTCityName.GetPointCityName(lat, lng: Double): String;
  function outSideCurCity(CityPointInfo:TCityPointInfo):Boolean;
  begin
    Result := False;
    if (CityPointInfo.PolyGonMaxPoint.lat<lat) or (CityPointInfo.PolyGonMinPoint.lat>lat) then
    begin
      Result := true;
      Exit;
    end;
    if (CityPointInfo.PolyGonMaxPoint.lng<lng) or (CityPointInfo.PolyGonMinPoint.lng>lng) then
    begin
      Result := true;
      Exit;
    end;
  end;
var
  PointF : TPointF;
  I:Integer;
begin
  Result := '';
  PointF.lat := lat;
  PointF.lng := lng;
  for I := 0 to length(CityPointInfoLst) - 1 do
  begin
    if outSideCurCity(CityPointInfoLst[I]) then Continue;

    if PointIsInPolygon(CityPointInfoLst[I].TpointFarres[0],PointF) then
    begin
      Result := CityPointInfoLst[I].CityName;
      break;
    end;
  end;
end;

end.
