unit TSKitPatcherLight;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCLL - Lighting');
  AddRecord('OCW_Settings.esp', 'XCLL\Inherits');
  AddRecord('OCW_Settings.esp', 'LTMP');
  AddRecord('Distinct Interiors.esp', 'DATA - Flags');
  AddRecord('Particle Patch for ENB SSE.esp', 'DATA - Flags');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCCM');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCIM');
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCCM');
  AddRecord('ENB Light.esp', 'FNAM - Fade value');
  AddRecord('Unique Display Room.esp', 'XEZN - Encounter Zone');
  Patch('CELL', 'Light');
  Result := 0;
end;

end.
