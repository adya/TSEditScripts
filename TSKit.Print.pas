unit TSKitPrint;

uses TSKit;

function Process(e: IInterface): integer;
begin
  Result := 0;
  PrintChildrenOrSelf(e);
end;

end.