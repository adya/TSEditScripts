unit TSKitPatcherRegionNames;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Unique Region Names.esp', 'XCLR - Regions');
  Patch('WRLD', 'Unique Region Names');
  Result := 0;
end;

end.
