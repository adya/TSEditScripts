﻿unit TSKitPatcherTrees;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'PFIG - Ingredient');
  AddRecord('IHarvestVanillaFixes.esp', 'PFIG - Ingredient');
  AddRecord('SkyrimIsWindy.esp', 'CNAM - Tree Data');
  Patch('TREE', 'Trees');
  Result := 0;
end;

end.
