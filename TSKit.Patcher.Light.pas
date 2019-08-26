unit TSKitPatcherLight;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Luminosity Lighting Overhaul.esp', 'XCLL');
  AddRecord('OCW_Obscure''s_CollegeofWinterhold.esp', 'XCLL\Inherits');
  AddRecord('OCW_Obscure''s_CollegeofWinterhold.esp', 'LTMP');
  AddRecord('Distinct Interiors.esp', 'DATA - Flags');
  AddRecord('Particle Patch for ENB SSE.esp', 'DATA - Flags');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCCM');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCIM');
  AddRecord('Soulmancer Soundtrack - NoVindDun.esp', 'XCMO');
  AddRecord('Blacksmith Forge Water Fix SE USSEP.esp', 'DATA - Flags');
  AddRecord('Unique Display Room.esp', 'XEZN - Encounter Zone');
  Patch('CELL', 'Light');
  Result := 0;
end;

end.
