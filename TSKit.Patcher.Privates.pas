unit TSKitPatcherPrivates;

uses TSKit;
uses 'TSKit.Patcher.Records';

// ================== Patcher Privates ==================

var
  
	/// The patch's Plugin to which all records are being copied.
	patchPlugin: IInterface;
	
	/// Plugin that is currently being processed.
	currentPatcherPlugin: IInterface;

	/// Before BuildPatch is called: Signature for which patcher records are being added to.
	/// During building the patch: Signature that is currently being processed.
	currentPatcherSignature: String;

	/// Name of the patch plugin.
	patchPluginName: String;

	/// List of all patcher files that needs to be processed.
	currentPatcherList: TStringList;
	
	/// List of all patcher signatures that needs to be processed in currentPatcherPlugin;
	currentPatcherSignatures: TStringList;
	
	/// List of all patcher records that needs to be patched in currentPatcherPlugin under currentPatcherSignature;
	currentPatcherRecords: TStringList;
	
	/// Name of the current patcher plugin;
	currentPatcherPluginName: String;

	/// Total number of processed records;
	counterProcessed: Integer;

	/// Total number of skipped records;
	counterSkipped: Integer;

	/// Total number of patched records;
	counterPatched: Integer;

	/// Total number of copied records;
	counterCopied: Integer;

procedure ProcessPlugin(plugin: String);
var i: Integer;
begin
	if plugin = patchPluginName then begin
		Exit; // skip patcher file itself.
	end;
	
  currentPatcherPlugin := FileByName(plugin);
	if not Assigned(currentPatcherPlugin) then begin
		AddMessage('Plugin "' + plugin + '" was not found');
		exit;
	end;
	
	AddMessage('Processing ' + plugin);
	currentPatcherPluginName := plugin;
	currentPatcherSignatures := PatcherSignaturesInPlugin(plugin);
	
	try 	
		if currentPatcherSignatures.Count = 0 then begin
			AddMessage('No registered signatures were found for plugin "' + plugin + '"');
			exit;
		end;
		
		for i := 0 to Pred(currentPatcherSignatures.Count) do begin
			currentPatcherSignature := currentPatcherSignatures[i];
			currentPatcherRecords := PatcherRecordsForSignatureInPlugin(currentPatcherSignature, plugin);
			ProcessSignature(currentPatcherSignature);
			currentPatcherRecords.Free;
		end;
	finally
		currentPatcherSignatures.Free;
	end;
end;

procedure ProcessSignature(signature: String);
var
	group,
	world,
	block,
	subBlock,
	cell: IInterface;
	i, j, k: Integer;
begin

	if signature = '' then begin
		AddMessage('Empty signature skipped');
		exit;
	end;
	
	group := GroupBySignature(currentPatcherPlugin, signature);
	Debug('Processing ' + IntToStr(ElementCount(group)) + ' elements in group ' + signature + ' ' + Stringify(group));
	if signature = 'CELL' then begin
		for j := 0 to Pred(ElementCount(group)) do begin
			block := ElementByIndex(group, j);
			for k := 0 to Pred(ElementCount(block)) do begin
				subBlock := ElementByIndex(block, k);
				ProcessGroup(subBlock);    
			end;
		end;
	end
	else if signature = 'WRLD' then begin
		for j := 0 to Pred(ElementCount(group)) do begin
			world := ElementByIndex(group, j);
			ProcessCell(ChildGroup(world));
		end;
	end
	else begin
		ProcessGroup(group);
	end;  
end;

/// Traverses cell element recursively to find all nested cells that needs patching.
procedure ProcessCell(e: IInterface);
var i: integer;
begin
	if ElementType(e) = etMainRecord then begin
		if Signature(e) = 'CELL' then
			ProcessElement(e);   
	end
	else begin
		// don't step into Cell Children, no CELLs there
		if GroupType(e) = 6 then
			Exit;
    
		for i := 0 to Pred(ElementCount(e)) do
			ProcessCell(ElementByIndex(e, i));
	end;
end;

/// Traverses group element to find any nested elements that needs patching.
procedure ProcessGroup(group: IInterface);
var
  j: Integer;
begin
  Debug('Got ' + IntToStr(ElementCount(group)) + ' records to process in ' + GetFileName(currentPatcherPlugin));
  for j := 0 to Pred(ElementCount(group)) do
    ProcessElement(ElementByIndex(group, j));
end;

/// Examines given element to determine whether it needs patching.
procedure ProcessElement(currentElement: IInterface);
var
	/// Element that will be used as a base for patching. E.g. all patches will be applied on top of this record.
	targetElement: IInterface;
	
	/// The same element as targetElement, but from the patcher plugin.
	patcherElement: IInterface;
	
	/// Resulting element containing all patches.
	patchedElement: IInterface;
	wasPatched: Boolean;
	j, k: Integer;
	pluginPath: String;
begin
	Debug('Processing ' + Stringify(currentElement));
	Inc(counterProcessed);
	Debug('Looking for override of ' + Stringify(currentElement));
	targetElement := GetPatchableWinningOverride(currentElement);
	if not Assigned(targetElement) then begin
		Inc(counterSkipped);
		Debug('Skipping ' + Stringify(currentElement) + ' - no conflicts');
		Exit;
	end;
  
	AddMastersSilently(targetElement, patchPlugin);
	if not Equals(targetElement, currentElement) then
		patchedElement := wbCopyElementToFile(targetElement, patchPlugin, False, True)
	else
		patchedElement := targetElement;

	Debug('Copying ' + Stringify(targetElement));
	Inc(counterCopied);
	
	wasPatched := false;

	for k := 0 to Pred(currentPatcherRecords.Count) do begin
		pluginPath := currentPatcherRecords[k];
		patcherElement := GetPatcherElement(currentPatcherPluginName, targetElement);
		Debug('Patching ' + Stringify(patcherElement));
		if not Assigned(patcherElement) then 
			continue;
		if not wasPatched then
			Inc(counterPatched);

		PatchElement(patchedElement, patcherElement, patchPlugin, pluginPath);
		wasPatched := true;
	end;
end;

/// Performs patching of 'patchedElement' using 'patcherElement'.
procedure PatchElement(patchedElement, patcherElement, patchPlugin: IInterface; path: String);
var
  elementAtPath: IInterface;
  fromVal, toVal: Integer;
  i: Integer;
begin
  elementAtPath := ElementByPath(patcherElement, path);
  if FlagValues(elementAtPath) <> '' then begin
    fromVal := GetNativeValue(elementAtPath);
    toVal := GetNativeValue(ElementByPath(patchedElement, path));
    Debug('From ' + IntToStr(fromVal));
    Debug('To ' + IntToStr(toVal));
    Debug('Res ' + IntToStr(fromVal or toVal));
    SetNativeValue(ElementByPath(patchedElement, path), fromVal or toVal);
  end
  else begin
	AddMastersSilently(patcherElement, patchPlugin);
    wbCopyElementToRecord(elementAtPath, patchedElement, false, true);
  end;
end;

/// Gets WinningOverride of the element.
function GetPatchableWinningOverride(element: IwbElement): IwbElement;
var
  candidate: IwbElement;
begin
  Result := WinningOverride(element);  
end;

/// Gets Element of the Patcher plugin if any for specified element.
function GetPatcherElement(patcherPluginName: String; element: IwbElement): IwbElement;
var
  i: integer;
  baseMaster, overrideMaster: IInterface;
begin
  baseMaster := MasterOrSelf(element);
  for i := 0 to Pred(OverrideCount(baseMaster)) do
  begin
    overrideMaster := OverrideByIndex(baseMaster, i);
    if GetFileName(GetFile(overrideMaster)) = patcherPluginName then begin
      Result := overrideMaster;
      Exit;
    end;
  end;
end;

/// Determines whether given element has master overrides from Patcher records.
/// Should be patched if:
/// 1) Has overriden record in one of the patcher plugins.
/// 2) Has overriden record from other plugins which are not official masters.
/// 3) Such overriden record is not ITM.
function ShouldBePatched(element: IwbElement): Boolean;
var
  i, j: Integer;
  
  // 1
  hasPatcher,
  // 2/3
  hasPatchable: boolean;
  fileName: String;
  baseMaster, overrideMaster: IwbElement;
begin
  // 1
  baseMaster := MasterOrSelf(element);
  debug('Searching for patchers of ' + Stringify(element) + '...');
  debug('Analyzing ' + IntToStr(OverrideCount(baseMaster)) + ' overrides');
  for i := 0 to Pred(OverrideCount(baseMaster)) do
  begin
    overrideMaster := OverrideByIndex(baseMaster, i);
    debug('Analyzing ' + Stringify(overrideMaster) + ' record');
    if not hasPatcher and not Equals(GetFile(overrideMaster), GetFile(currentPatcherPlugin)) then begin
      Debug(Stringify(element) + ' has patcher: ' + Stringify(overrideMaster));
      hasPatcher := true;
    end;
    
    // 2
    //    if not hasPatchable and true then begin
    //      hasPatchable := true;
    //    end;
  end;
  hasPatchable := true; // not supported yet.
  Result := hasPatchable and hasPatcher;
  
end;

/// Checks whether or not given element is from the patch plugin.
function IsPatchedElement(element: IwbElement): Boolean;
var f: IInterface;
begin
    f := GetFile(element);
    Result := Equals(f, patchPlugin);
end;

end.