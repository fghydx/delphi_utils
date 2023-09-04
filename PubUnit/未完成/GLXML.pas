//有莫名奇妙的错误，多线程中
unit GLXML;

interface

uses xmldom,XMLIntf,GLXMLDoc,oxmldom,StrUtils,SysUtils;

type
  TXMLAnalyType = (MSXML,OpenXML);              //解析类型

  TGLXML = class
  private
    FXMLAnalyType:TXMLAnalyType;
    FXMLIntf:IXMLDocument;
    function GetRoot: IXMLNodeAccess;
    function GetXML: WideString;
    function NewDiffXmlDocument(DOMVender: string;Version: DOMString = '1.0'): IXMLDocument;
    procedure SetXML(const Value: WideString);
  public
    constructor Create({AnalyType: TXMLanalyType});
    destructor Destroy; override;

  public
    property Root: IXMLNodeAccess read GetRoot;
    property XML: WideString read GetXML write SetXML;
  end;

implementation
uses ActiveX;

function TGLXML.NewDiffXmlDocument(DOMVender: string;Version: DOMString): IXMLDocument;
var
  XMLDoc : TXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.DOMVendor := GetDOMVendor(DOMVender);
  Result := XMLDoc;
  Result.Active := true;
  Result.AddChild('Root');
  if Version <> '' then
    Result.Version := Version;
end;

constructor TGLXML.Create({AnalyType: TXMLAnalyType});
begin
  CoInitialize(nil);
  inherited create;
//  FXMLAnalyType := MSXML;
//  if FXMLAnalyType = MSXML then

  FXMLIntf := NewDiffXmlDocument(XMLanalyTypeStr[Integer(FXMLAnalyType)]);
end;

destructor TGLXML.Destroy;
begin
  inherited;
//  if FXMLAnalyType = MSXML then
  CoUninitialize;
  // TODO -cMM: TGLXML.Destroy default body inserted
end;

function TGLXML.GetRoot: IXMLNodeAccess;
begin
  case FXMLAnalyType of
    MSXML:Result := (FXMLIntf.Node as IXMLNodeAccess).Nodes[1];
    OpenXML:Result := FXMLIntf.ChildNodes[0] as IXMLNodeAccess;
  end;

end;

function TGLXML.GetXML: WideString;
begin
  Result := FXMLIntf.XML.Text;
end;

procedure TGLXML.SetXML(const Value: WideString);
var
  str:WideString;
begin
  if Trim(LeftStr(Value,2))<>'<?' then
  begin
    str := '<?xml version="1.0" ?>'+Value;
  end else
  begin
    str := Value;
  end;
  FXMLIntf.loadFromXML(str);
end;

end.
