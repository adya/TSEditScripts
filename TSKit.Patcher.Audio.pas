unit TSKitPatcherSmartPatch;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  AddRecord(' Audio Overhaul Skyrim.esp', 'INAM - Impact Data Set');
  
  Patch('WEAP', 'WeaponImpact');
  
  Result := 0;
end;

end.
