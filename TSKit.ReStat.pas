unit TSKitReStat;

uses TSKit;
uses mteFunctions;

const
  pluginName = 'ReStat';
  healthPath = 'ACBS\Health Offset';
  staminaPath = 'ACBS\Stamina Offset';
  magickaPath = 'ACBS\Magicka Offset';
  
  /// Values
  healthOffset = 0;
  staminaOffset = 0;
  magickaOffset = 0;
   
  function IgnoreFormID(formId: integer): boolean;
  begin
  
	case formId of
	$00000007: result: = true; // Player
	
	// The Mind of Madness NPCs. Reseting this will break the quest as all NPCs will be dead.
	$0009F851: result := true; // Anger 
	$0009F844: result := true; // Confidence
	$0009F82D: result := true; // Pelagius the Tormented
	$0009B287: result := true; // Pelagius the Suspicious
	else result := false;
	end;
  end;

function Initialize: integer;
var
  patchPlugin: IInterface;
  group,
  element,
  skyrimFile,
  patchedElement: IInterface;
  currentHealth, currentStamina, currentMagicka: Integer;
  processed, skipped, i, j, k: Integer;

begin
	patchPlugin := FileByName(pluginName + '.esp');
	if not Assigned(patchPlugin) then
		patchPlugin := CreatePatchFile(pluginName);
	if not Assigned(patchPlugin) then
		Exit;
		
	for i := 0 to Pred(FileCount) do
	begin
		group := GroupBySignature(FileByIndex(i), 'NPC_');
		for j := 0 to Pred(ElementCount(group)) do
		begin 
			element := ElementByIndex(group, j);
			debug('Looking for override of ' + Stringify(element));
			element := WinningOverride(element);
	  
			if Equals(GetFile(element), patchPlugin) then begin
				debug('Skipping ' + Stringify(element));
				Inc(skipped);
				continue;
			end;
			
			if IgnoreFormID(FormID(element)) then begin
				debug('Skipping ' + Stringify(element));
				Inc(skipped);
				continue;
			end;
	  
			debug('Processing ' + Stringify(element));
			Inc(processed);
		  
		  
			currentHealth := Integer(GetElementNativeValues(element, healthPath));
			currentStamina := Integer(GetElementNativeValues(element, staminaPath));
			currentMagicka := Integer(GetElementNativeValues(element, magickaPath));
			debug('Current stats for ' + geev(element, 'EDID') + ': ' + IntToStr(currentHealth) + ', ' + IntToStr(currentStamina) + ', ' + IntToStr(currentMagicka));
			if (currentHealth <= healthOffset) and
			   (currentStamina <= staminaOffset) and
			   (currentMagicka <= magickaOffset) then begin
				debug('Skipping identical stats');
				Inc(skipped);
				continue;
			end;
		  
			AddMastersSilently(element, patchPlugin);
			debug('Copying ' + Stringify(element));
		  
			patchedElement := wbCopyElementToFile(element, patchPlugin, False, True);
		  
		  
			if currentHealth > healthOffset then
				SetElementNativeValues(patchedElement, healthPath, healthOffset);
			if currentStamina > staminaOffset then
				SetElementNativeValues(patchedElement, staminaPath, staminaOffset);
			if currentMagicka > magickaOffset then
				SetElementNativeValues(patchedElement, magickaPath, magickaOffset);
		end;
	end;
	
	// Remove Health Level bonus
	skyrimFile := FileByName('Skyrim.esm');
	group := GroupBySignature(skyrimFile, 'GMST');
	for i := 0 to Pred(ElementCount(group)) do
	begin
		element := ElementByIndex(group, i);
		
		if geev(element, 'EDID - Editor ID') = 'fNPCHealthLevelBonus' then
		begin
			patchedElement := wbCopyElementToFile(element, patchPlugin, False, True);
			senv(patchedElement, 'DATA - Value\Float', 0);
			break;
		end;
	end;
	
	if Assigned(patchPlugin) then begin
		SortMasters(patchPlugin);
		CleanMasters(patchPlugin);
		AddMessage('Patch file created. Processed ' + IntToStr(processed) + ' NPCs. Skipped ' + IntToStr(skipped) + ' NPCs.');
	end;
	Result := 0;
end;

end.
