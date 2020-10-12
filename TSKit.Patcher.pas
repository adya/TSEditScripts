unit TSKitPatcher;

uses TSKit;
uses 'TSKit.Patcher.Privates';
uses mteElements;
uses mteFiles;
// ================== Glossary ==================
// * PatchPlugin - plugin into which all results are written
// * PatcherPlugin - plugin records of which should be retained in patch plugin

// ================== Patcher ==================

/// Adds an element of specified plugin at given path as a reference value
/// that patcher will use in resulting patch.
/// Patcher uses the same order as records are added, 
/// so when multiple records exist in different patcher plugins the last one will take priority.
procedure AddRecord(sourcePluginName: String; recordPath: String);
begin
  Debug('Adding "' + recordPath + '" from "' + sourcePluginName + '"');
  if currentPatcherSignature = '' then begin
    AddMessage('Signature was not set. Call StartPatching(signature) before adding records.');
    exit;  
  end;
  
  if not Assigned(patchRecords) then begin
    if Assigned(patchRecords)then begin
  		patchRecords.Free;
  	end;
	  patchRecords := TStringList.create;
  end;
  SerializeRecord(sourcePluginName, currentPatcherSignature, recordPath);
  AddMessage('Registered ' + recordPath + ' from ' + sourcePluginName);
end;

/// Initializes patching records for given signature.
/// Following calls to AddRecord procedure
/// will register provided records under that signature.
procedure StartPatching(signature: String);
begin
  currentPatcherSignature := signature;
end;

/// Creates a patch for all loaded plugins using configured patchers.
/// Resets itself afterwards.
procedure BuildPatch(pluginName: String);
var i: Integer;
begin
	counterProcessed := 0;
	counterSkipped := 0;
	counterPatched := 0;
	counterCopied := 0;
  
	patchPluginName := pluginName;
	currentPatcherList := PatcherPlugins;
	try	
		if not Assigned(currentPatcherList) then
      AddMessage('No configured patchers were added');
		
		if not Assigned(patchPlugin) then begin
			// Look for patch file with given name
			patchPlugin := FileByName(PatchFileName(patchPluginName));
			// Or create one if not found
			if not Assigned(patchPlugin) then
				patchPlugin := CreatePatchFile(patchPluginName);
		end;

		if not Assigned(patchPlugin) then begin
			AddMessage('Couldn''t read or create path plugin "' + patchPluginName + '"');
			Exit;
		end;
	
		for i := 0 to Pred(currentPatcherList.Count) do begin
			ProcessPlugin(currentPatcherList[i]);
		end;
		
		if Assigned(patchPlugin) then begin
			CleanMasters(patchPlugin);
			SortMasters(patchPlugin);     
			AddMessage(patchPluginName + ' file created. Processed ' + IntToStr(counterProcessed) + ' records. Skipped ' + IntToStr(counterSkipped) + ' records. Copied ' + IntToStr(counterCopied) + ' records. Patched ' + IntToStr(counterPatched) + ' records');
		end;
	finally
		currentPatcherList.Free;
		Reset();
	end;
end;

procedure Reset();
begin
	patchPlugin := nil;
	currentPatcherSignature := '';
	patchPluginName := '';
end;
end.