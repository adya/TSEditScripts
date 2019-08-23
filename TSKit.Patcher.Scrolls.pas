unit TSKitPatcherLight;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'KWDA - Keywords');
  Patch('SCRL', 'Scrolls');
  Result := 0;
end;

end.
