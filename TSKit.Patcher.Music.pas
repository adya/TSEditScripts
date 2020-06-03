unit TSKitPatcherMusic;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Soulmancer Soundtrack - NoVindDun.esp', 'XCMO');
  Patch('CELL', 'Music');
  Result := 0;
end;

end.
