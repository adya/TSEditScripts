unit WeightOverhaulBooksPatcher;
uses TSPatcher;

//==============================================================================
function Initialize: integer;
begin
  AddRecord('WeightOV - Lightweight - MERGED - BCS.esp', 'DATA\Weight');
  AddRecord('WeightOV - Lightweight - CACO.esp', 'DATA\Weight');
  AddRecord('Book Covers Skyrim.esp', 'MODEL');
  AddRecord('Book Covers Skyrim.esp', 'INAM');
  Patch('BOOK');
  Result := 1;
end;

end.
