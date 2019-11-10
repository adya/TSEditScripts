unit TSKitPatcherBlacksmithWaterFix;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin  
  AddRecord('Blacksmith Forge Water Fix SE USSEP.esp', 'DATA - Flags');
  Patch('CELL', 'BFWF');
  Result := 0;
end;

end.
