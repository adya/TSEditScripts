unit TSKitPatcher;

uses TSKit;
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
  if currentPatcherSignature = '' then begin
    AddMessage('Signature was not set. Call StartPatching(signature) before adding records.');
    exit;  
  end;
  
  if not Assigned(patchRecords) then begin
    Reset();
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
  
	try
		patchPluginName := pluginName;
		currentPatcherList := PatcherPlugins;
		
		if not Assigned(patchPlugin) then begin
			// Look for patch file with given name
			patchPlugin := FileByName(PatchFileName(patchPluginName));
			// Or create one if not found
			if not Assigned(patchPlugin) then
				patchPlugin := CreatePatchFile(patchPluginName);
		end;

		if not Assigned(patchPlugin) then begin
			AddMessage('Couldn''t read or create path plugin ''' + patchPluginName + '''');
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
	if Assigned(patchRecords) then begin
		patchRecords.Free;
	end;
	currentPatcherSignature := '';
	patchPluginName := '';
	patchRecords.Free;
	patchRecords := TStringList.create;
	
end;


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
	try 
		currentPatcherPlugin := FileByName(plugin);
		
		if not Assigned(currentPatcherPlugin) then begin
			AddMessage('Plugin "' + plugin + '" was not found');
			exit;
		end;
		
		currentPatcherSignatures := PatcherSignaturesInPlugin(plugin);
		
		if currentPatcherSignatures.Count = 0 then begin
			AddMessage('No registered signatures were found for plugin "' + plugin + '"');
			exit;
		end;
		
		for i := 0 to Pred(currentPatcherSignatures.Count) do begin
			currentPatcherSignature := currentPatcherSignatures[i];
			ProcessSignature(currentPatcherSignature);
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
		AddMessage('Signature required');
		exit;
	end;
	
	group := GroupBySignature(currentPatcherPlugin, signature);
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
	/// Element that will be used as a base to for patching. E.g. all patches will be applied on top of this record.
	targetElement: IInterface;
	
	/// The same element as targetElement, but from the patcher plugin.
	patcherElement: IInterface;
	
	/// Resulting element containing all patches.
	patchedElement: IInterface;
	wasPatched: Boolean;
	j, k: Integer;
	pluginName, pluginPath: String;
begin
	Debug('Processing ' + Stringify(targetElement));
	Inc(counterProcessed);
	Debug('Looking for override of ' + Stringify(currentElement));
	targetElement := GetPatchableWinningOverride(currentElement);
	if not Assigned(targetElement) then begin
		Inc(counterSkipped);
		Debug('Skipping ' + Stringify(currentElement) + ' - no conflicts');
		Exit;
	end;
  
	AddMastersSilently(targetElement, patchPlugin);
	patchedElement := wbCopyElementToFile(targetElement, patchPlugin, False, True);
	Debug('Copying ' + Stringify(targetElement));
	Inc(counterCopied);
	
	wasPatched := false;
	currentPatcherRecords := PatcherRecordsForSignatureInPlugin(currentPatcherSignature, currentPatcherPlugin);
	
	// TODO: Continue here to patch element.
	for k := 0 to Pred(patchRecords.Count) do begin
		pluginPath := PatcherRecordPathAtIndex(k);
		pluginName := PatcherPluginNameAtIndex(k);      
		patcherElement := GetPatcherElement(pluginName, targetElement);
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


// ================== Patcher Records ==================

const
  recordsDelimiter = '@';
  compositionFormat= '%s%s%s%s%s';
  compositionSourcePluginIndex = 0;
  compositionSignatureIndex = 1;
  compositionRecordPathIndex = 2;
var
  patchRecords: TStringList;

/// Stores information about patcher record.
/// - Parameter sourcePluginName: Name of the plugin which provides winning override records.
/// - Parameter signature: Signature of the winning override records.
/// - Parameter recordPath: Path to the records being patched.
procedure SerializeRecord(sourcePluginName, signature, recordPath: String);
begin
	patchRecords.Add(Format(compositionFormat, [sourcePluginName, recordsDelimiter, currentPatcherSignature, recordsDelimiter, recordPath]));
end;

/// Checks whether given file is registered as patcher plugin.
function IsPatcherPlugin(f: IwbFile): Boolean;
var
  i: Integer;
  patchPluginName: String;
begin
  for i := 0 to Pred(patchRecords.Count) do
  begin
    patchPluginName := PatcherPluginNameAtIndex(i);
    if GetFileName(f) = patchPluginName then begin
      Result := true;
      Exit;
    end;
  end;
  Result := false;
end;

/// Returns unique patcher plugin names that has been configured.
function PatcherPlugins: TStringList;
var names: TStringList;
i: integer;
begin
  names := TStringList.Create;
  names.Duplicates := dupIgnore;
  for i:=0 to Pred(patchRecords.Count) do begin
    names.Add(PatcherPluginNameAtIndex(i));
  end;
  Result := names;
end;

/// Returns unique patcher signatures in given plugin.
function PatcherSignaturesInPlugin(pluginName: String): TStringList;
var signatures: TStringList;
	components: TStrings;
	i: Integer;
begin
	signatures := TStringList.Create;
	signatures := dupIgnore;
	for i := 0 to Pred(patchRecords.Count) do begin
		components := DeserializeComponentsAtIndex(i);
		try 
			if components[compositionSourcePluginIndex] = pluginName then begin
				signatures.Add(components[compositionSignatureIndex]);
			end;
		finally
			components.Free;
		end;
		
	end;
	Result := signatures;
end;

function PatcherRecordsForSignatureInPlugin(signature, pluginName: String): TStringList;
var records: TStringList;
	components: TStrings;
	i: Integer;
begin
	records := TStringList.Create;
	records := dupIgnore;
	for i := 0 to Pred(patchRecords.Count) do begin
		components := DeserializeComponentsAtIndex(i);
		try 
			if components[compositionSourcePluginIndex] = pluginName and components[compositionSignatureIndex] then begin
				records.Add(components[compositionRecordPathIndex]);
			end;
		finally
			components.Free;
		end;
		
	end;
	Result := records;
end;

function PatcherRecordPathAtIndex(index: Integer): String;
begin
  Result := DeserializeComponentAtIndex(index, compositionRecordPathIndex);
end;

function PatcherPluginNameAtIndex(index: Integer): String;
begin
  Result := DeserializeComponentAtIndex(index, compositionRecordPathIndex);
end;

function PatcherSignatureAtIndex(index: Integer): String;
begin
  Result := DeserializeComponentAtIndex(index, compositionSignatureIndex);
end;

function DeserializeComponentAtIndex(patchIndex, componentIndex: Integer): String;
var s: TStrings;
begin
	s := DeserializeComponentsAtIndex(patchIndex);
	try
		if s.Count > componentIndex then
			Result := s[componentIndex];
	finally
		s.Free;
	end;
end.

function DeserializeComponentsAtIndex(patchIndex: Integer): TStrings;
begin
	Restuls := Split(patchRecords[patchIndex], recordsDelimiter, true);
end;