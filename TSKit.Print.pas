unit TSKitPrint;

uses TSKit;
uses mteElements;
uses mteFunctions;

function Process(e: IInterface): integer;
begin
  Result := 0;
  AddMessage('Printing ' + GetFileName(GetFile(e)));
  PrintChildrenOrSelf(e);
end;

end.
