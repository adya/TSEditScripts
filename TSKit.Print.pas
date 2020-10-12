unit TSKitPrint;

uses TSKit;

function Process(e: IInterface): integer;
begin
  Result := 0;
  AddMessage('Printing ' + GetFileName(GetFile(e)));
  PrintChildrenOrSelf(e);
end;

end.
