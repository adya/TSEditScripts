unit TSKitPatcherRegionNames;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Unique Region Names.esp', 'XCLR - Regions');
  AddRecord('Unofficial Skyrim Special Edition Patch', 'XLCN - Location');
  AddRecord('HammetDungeons.esm', 'XLCN - Location');
  AddRecord('Unique Region Names.esp', 'XLCN - Location');
  Patch('WRLD', 'Locations');
  Result := 0;
end;

end.
