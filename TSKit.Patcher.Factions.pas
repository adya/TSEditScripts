﻿unit TSKitPatcherLight;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Crime Overhaul Expanded.esp', 'DATA - Flags');
  AddRecord('Windhelm Bridge Overhaul.esp', 'DATA - Flags');
  AddRecord('Wild World.esp', 'Relations');
  AddRecord('Wild World.esp', 'DATA - Flags');
  AddRecord('OBIS SE.esp', 'Relations');
  Patch('FACT', 'Factions');
  Result := 0;
end;

end.
