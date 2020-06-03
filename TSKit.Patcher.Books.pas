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
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'OBND - Object Bounds');
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'MODEL');
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'INAM - Inventory Art');
  AddRecord('MysticismMagic.esp', 'DATA\Value');
  AddRecord('MysticismMagic.esp', 'FULL - Name');
  AddRecord('MysticismMagic.esp', 'OBND - Object Bounds');
  
  Patch('BOOK', 'Books');
  
  Result := 0;
end;

end.
