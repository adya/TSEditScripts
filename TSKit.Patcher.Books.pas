unit TSKitPatcherBooks;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Book Covers Skyrim.esp', 'BOOK \ OBND - Object Bounds');
  AddRecord('Book Covers Skyrim.esp', 'MODEL');
  AddRecord('Book Covers Skyrim.esp', 'INAM');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'BOOK \ OBND - Object Bounds');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'MODEL');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'INAM');
  AddRecord('Dynamic Patch - ReWeight.Books.esp', 'DATA\Weight');
  Patch('BOOK', 'Books');
  Result := 0;
end;

end.
