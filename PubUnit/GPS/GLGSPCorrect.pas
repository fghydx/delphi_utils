/// <remarks>
/// 谷哥,高德,腾讯,百度地图纠偏与逆转算法
/// 网上翻译 
/// 机器猫（5909386@qq.com）
/// </remarks>

unit GLGSPCorrect;

interface

const
  PI = 3.14159265358979324;
  x_pi = 3.14159265358979324 * 3000.0 / 180.0;

type
  TGLGPSCorrect = class
  private
    class procedure delta(var lat,lng:Double);
    class function transformLon(lat,lng:Double):Double;
    class function transformlat(lat,lng:Double):Double;

    /// <remarks>
    /// GPS坐标转到 Google Map、高德、腾讯
    /// </remarks>
    class procedure WGS84_to_GCJ02(var lat,lng:Double);
    /// <remarks>
    /// 从Google Map、高德、腾讯转到GPS坐标
    /// </remarks>
    class procedure GCJ02_to_WGS84(var lat,lng:Double);    //粗略
    class procedure GCJ02_to_WGS84Ex(var lat,lng:Double);  //精确

    /// <remarks>
    /// 从Google Map、高德、腾讯转到百度坐标
    /// </remarks>
    class procedure GCJ02_to_BD09(var lat,lng:Double);
    /// <remarks>
    /// 从百度转到 Google Map、高德、腾讯坐标
    /// </remarks>
    class procedure BD09_to_GCJ02(var lat,lng:Double);

  public
    class function OutOfChina(lat,lng:Double):Boolean;
    class function Distance(latA,lngA,latB,lngB:Double):Double;

    class procedure GPS_to_Google(var lat,lng:Double);
    class procedure Google_to_GPS(var lat,lng:Double);
    class procedure Gps_to_Baidu(var lat,lng:Double);
    class procedure Baidu_to_Gps(var lat,lng:Double);
    class procedure Google_to_Baidu(var lat,lng:double);
    class procedure Baidu_to_Google(var lat,lng:Double);
  end;

implementation
  uses Math;

class procedure TGLGPSCorrect.Baidu_to_Google(var lat, lng: Double);
begin
  BD09_to_GCJ02(lat,lng);
end;

class procedure TGLGPSCorrect.Baidu_to_Gps(var lat, lng: Double);
begin
  BD09_to_GCJ02(lat,lng);
  GCJ02_to_WGS84Ex(lat,lng);
end;

class procedure TGLGPSCorrect.BD09_to_GCJ02(var lat, lng: Double);
var
  x,y,z,theta:Double;
begin
  x := lng - 0.0065;
  y := lat - 0.006;
  z := sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
  theta := ArcTan2(y, x) - 0.000003 * cos(x * x_pi);
  lng := z * cos(theta);
  lat := z * sin(theta);
end;

class procedure TGLGPSCorrect.delta(var lat, lng: Double);
const
   a = 6378245.0; //  a: 卫星椭球坐标投影到平面地图坐标系的投影因子。
   ee = 0.00669342162296594323; //  ee: 椭球的偏心率。
var
  dLat,dLng,radLat,magic,sqrtMagic:Double;
begin
  dLat := transformLat(lng - 105.0, lat - 35.0);
  dlng := transformLon(lng - 105.0, lat - 35.0);
  radLat := lat / 180.0 * PI;
  magic := sin(radLat);
  magic := 1 - ee * magic * magic;
  sqrtMagic := sqrt(magic);
  dLat := (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * PI);
  dlng := (dlng * 180.0) / (a / sqrtMagic * cos(radLat) * PI);

  lat := dLat;
  lng := dLng;
end;

class function TGLGPSCorrect.Distance(latA, lngA, latB, lngB: Double): Double;
const
  earthR = 6371000.0;
var
  x,y,s,alpha:Double;
begin
  x := cos(latA * PI / 180.0) * cos(latB * PI / 180.0) * cos((lngA - lngB) * PI / 180);
  y := sin(latA * PI / 180.0) * sin(latB * PI / 180.0);
  s := x + y;
  if (s > 1) then s := 1;
  if (s < -1) then s := -1;
  alpha := ArcCos(s);
  result := alpha * earthR;
end;

class procedure TGLGPSCorrect.GCJ02_to_BD09(var lat, lng: Double);
var
  x,y,z,theta:Double;
begin
  x := lng;
  y := lat;
  z := sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
  theta := ArcTan2(y, x) + 0.000003 * cos(x * x_pi);
  lng := z * cos(theta) + 0.0065;
  lat := z * sin(theta) + 0.006;
end;

class procedure TGLGPSCorrect.GCJ02_to_WGS84(var lat, lng: Double);
var
  deltalat,delatlng:Double;
begin
  if outOfChina(lat, lng) then exit;

  deltalat := lat;
  delatlng := lng;
  delta(deltalat, delatlng);

  lat := lat - deltalat;
  lng := lng - delatlng;
end;

class procedure TGLGPSCorrect.GCJ02_to_WGS84Ex(var lat, lng: Double);
const
  initDelta = 0.01;
  threshold = 0.000000001;
var
  dLat,dLon,mLat,mLon,pLat,pLon,wgsLat,wgsLon:Double;
  i:integer;
begin
  dLat := initDelta;
  dLon := initDelta;
  mLat := Lat - dLat;
  mLon := lng - dLon;
  pLat := Lat + dLat;
  pLon := lng + dLon;
  i := 0;
  while true do
  begin
      wgsLat := (mLat + pLat) / 2;
      wgsLon := (mLon + pLon) / 2;
      WGS84_to_GCJ02(wgsLat, wgsLon);
      dLat := wgsLat - Lat;
      dLon := wgsLon - lng;
      if ((abs(dLat) < threshold) and (abs(dLon) < threshold)) then
          break;

      if (dLat > 0) then pLat := wgsLat else mLat := wgsLat;
      if (dLon > 0) then pLon := wgsLon else mLon := wgsLon;
      Inc(i);
      if i > 10000 then break;
  end;
  lat := wgsLat;
  lng := wgsLon;
end;

class procedure TGLGPSCorrect.Google_to_Baidu(var lat, lng: double);
begin
  GCJ02_to_BD09(lat,lng);
end;

class procedure TGLGPSCorrect.Google_to_GPS(var lat, lng: Double);
begin
  GCJ02_to_WGS84Ex(lat,lng);
end;

class procedure TGLGPSCorrect.Gps_to_Baidu(var lat, lng: Double);
begin
  WGS84_to_GCJ02(lat,lng);
  GCJ02_to_BD09(lat,lng);
end;

class procedure TGLGPSCorrect.GPS_to_Google(var lat, lng: Double);
begin
  WGS84_to_GCJ02(lat,lng);
end;

class function TGLGPSCorrect.OutOfChina(lat, lng: Double): Boolean;
begin
  Result := False;
  if (lng < 72.004) or (lng > 137.8347) then
      Result := true;
  if (lat < 0.8293) or (lat > 55.8271) then
      Result := true;
end;

class function TGLGPSCorrect.transformlat(lat, lng: Double): Double;
begin
  Result := -100.0 + 2.0 * lat + 3.0 * lng + 0.2 * lng * lng + 0.1 * lat * lng + 0.2 * sqrt(abs(lat));
  Result := Result + (20.0 * sin(6.0 * lat * PI) + 20.0 * sin(2.0 * lat * PI)) * 2.0 / 3.0;
  Result := Result + (20.0 * sin(lng * PI) + 40.0 * sin(lng / 3.0 * PI)) * 2.0 / 3.0;
  Result := Result + (160.0 * sin(lng / 12.0 * PI) + 320 * sin(lng * PI / 30.0)) * 2.0 / 3.0;
end;

class function TGLGPSCorrect.transformLon(lat, lng: Double): Double;
begin
  Result := 300.0 + lat + 2.0 * lng + 0.1 * lat * lat + 0.1 * lat * lng + 0.1 * sqrt(abs(lat));
  Result := Result + (20.0 * sin(6.0 * lat * PI) + 20.0 * sin(2.0 * lat * PI)) * 2.0 / 3.0;
  Result := Result + (20.0 * sin(lat * PI) + 40.0 * sin(lat / 3.0 * PI)) * 2.0 / 3.0;
  Result := Result + (150.0 * sin(lat / 12.0 * PI) + 300.0 * sin(lat / 30.0 * PI)) * 2.0 / 3.0;
end;


class procedure TGLGPSCorrect.WGS84_to_GCJ02(var lat, lng: Double);
var
  deltalat,delatlng:Double;
begin
  if (outOfChina(lat, lng)) then
    Exit;

  deltalat := lat;
  delatlng := lng;
  delta(deltalat, delatlng);
  lat := lat + deltalat;
  lng := lng + delatlng;
end;

end.
