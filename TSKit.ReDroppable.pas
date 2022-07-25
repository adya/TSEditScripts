unit TSKitReDrop;
// This script removes Can't Drop flag from WEAP records of a selected Plugin. (Creates a new plugin with overwrites)


uses TSKit;
uses mteFunctions;
uses mteElements;

const
  pluginName = 'ArteFake';
  patchName = 'ReDroppable.ArteFake';
  flagPath = 'DNAM - Data\Flags';
  flagIndex = 3; // Index of 'Can't Drop' flag. Didn't work by name.


var sourcePlugin: IInterface;
	patchPlugin: IInterface;
	
	processed, skipped, patched: Integer;

function Initialize: integer;
var
  weapon,
  element,
  group,
  patchedElement: IInterface;
  i: Integer;
begin
	Result := 0;
	patchPlugin := FileByName(patchName + '.esp');
	if not Assigned(patchPlugin) then
		patchPlugin := CreatePatchFile(patchName);
	if not Assigned(patchPlugin) then
		Result := 1;
		
	sourcePlugin := FileByName(pluginName + '.esp');
	
	if not Assigned(sourcePlugin) then
	begin
		AddMessage('ArteFake.esp not found in load order');
		exit;
	end;
	
	group := GroupBySignature(sourcePlugin, 'WEAP');
	processed := ElementCount(group);	
	for i := 0 to Pred(ElementCount(group)) do
	begin

		weapon := ElementByIndex(group, i);
		
		Debug('Looking for ' + flagPath + ' in ' + Stringify(weapon));
		element := ElementByPath(weapon, flagPath);
		Debug(Stringify(element));

		if not GetFlag(element, flagIndex) then 
		begin
			AddMessage('Skipping ' + Stringify(weapon) + ' - flag is absent');
			Inc(skipped);
			continue;
		end;

		Debug('Patching ' + Stringify(weapon));
		Inc(patched);

		patchedElement := WinningOverride(weapon);
		if GetFileName(GetFile(patchedElement)) <> GetFileName(patchPlugin) then
		begin
			AddMastersSilently(weapon, patchPlugin);
			Debug('Copying ' + Stringify(weapon));
			patchedElement := wbCopyElementToFile(weapon, patchPlugin, False, True);
		end;
		Debug('Reseting flag in ' + Stringify(patchedElement));
		element := ElementByPath(patchedElement, flagPath);
		SetFlag(element, flagIndex, false);
	end;
end;

function Finalize: integer;
begin
	Result := 0;
	if Assigned(patchPlugin) then 
	begin
		SortMasters(patchPlugin);
		CleanMasters(patchPlugin);
		AddMessage('Patch file created. Patched ' + IntToStr(patched) + ' of ' + IntToStr(processed) + ' weapons. Skipped ' + IntToStr(skipped) + ' weapons.');
	end;
end;
end.
