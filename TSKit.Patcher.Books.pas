unit TSKitPatcherBooks;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Dynamic Patch - Books Weight.esp', 'DATA\Weight');
  AddRecord('Book Covers Skyrim.esp', 'MODEL');
  AddRecord('Book Covers Skyrim.esp', 'INAM');
  Patch('BOOK');
  Result := 1;
end;

end.
