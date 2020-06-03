unit TSKit.Sandboxing;
uses TSKit;
uses mteFunctions;
uses mteElements;

function Process(e: IInterface): integer;
var k: IInterface;
var i: integer;
begin
k := ElementByPath(e, 'KWDA');
i := ElementCount(k);

AddMessage('Count: ' + IntToStr(i));
AddMessage(etToString(ElementType(k)));
end;

end.