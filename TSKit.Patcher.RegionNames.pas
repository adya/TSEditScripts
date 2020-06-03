unit TSKitPatcherRegionNames;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('SkyfallEstateBuildable.esp', 'XLCN - Location');
  AddRecord('Oakwood.esp', 'XLCN - Location');
  AddRecord('Gavorstead.esp', 'XLCN - Location');
  AddRecord('Forgotten DungeonsSSE.esm', 'XLCN - Location');
  AddRecord('Improved Adoptions MERGED.esp', 'XLCN - Location');
  AddRecord('Alternate Start - Live Another Life.esp', 'XLCN - Location');
  AddRecord('Unofficial Skyrim Special Edition Patch', 'XLCN - Location');

  Patch('WRLD', 'Locations');
  Result := 0;
end;

end.
