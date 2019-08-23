unit TSKitPatcherBooks;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Book Covers Skyrim.esp', 'OBND - Object Bounds');
  AddRecord('Book Covers Skyrim.esp', 'MODEL');
  AddRecord('Book Covers Skyrim.esp', 'INAM');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'OBND - Object Bounds');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'MODEL');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'INAM');
  AddRecord('Dynamic Patch - ReWeight.Books.esp', 'DATA\Weight');
  AddRecord('Wintersun - Faiths of Skyrim.esp', 'VMAD - Virtual Machine Adapter');
  
  Patch('BOOK', 'Books');
  Result := 0;
end;

end.
