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
  if not Assigned(patchRecords) then begin
    Reset();
  end;
  patchRecords.Add(Format('%s%s%s', [sourcePluginName, recordsDelimiter, recordPath]));
  AddMessage('Registered ' + recordPath + ' from ' + sourcePluginName);
end;

/// Creates a patch for all loaded plugins using configured patchers.
/// Resets itself afterwards.
procedure Patch(signature, pluginName: String);
var
  group,
  world,
  block,
  subBlock,
  cell,
  cellChildren: IInterface;
  processed, skipped, patched, copied, i, j, k, z, x: Integer;
  patcherList: TStringList;
begin
  processed := 0;
  skipped := 0;
  patched := 0;
  copied := 0;
  
  if signature = '' then begin
    AddMessage('Signature required');
    exit;
  end;
  patchSignature := signature;
  patchPluginName := pluginName;
  patcherList := PatcherPlugins;
  try
    for i := 0 to Pred(patcherList.Count) do
    begin
      currentPlugin := FileByName(patcherList[i]);
      
      group := GroupBySignature(currentPlugin, signature);
      if signature = 'CELL' then begin
        for j := 0 to Pred(ElementCount(group)) do
        begin
          block := ElementByIndex(group, j);
          for k := 0 to Pred(ElementCount(block)) do
          begin
            subBlock := ElementByIndex(block, k);
            ProcessGroup(subBlock, processed, skipped, copied, patched);    
          end;
        end;
      end
      else if signature = 'WRLD' then begin
        for x := 0 to Pred(ElementCount(group)) do
        begin
          world := ElementByIndex(group, x);
          ProcessCell(ChildGroup(world), processed, skipped, copied, patched);
        end;
      end
      else begin
        ProcessGroup(group, processed, skipped, copied, patched);
      end;  
    end;
    
    if Assigned(patchPlugin) then begin
      CleanMasters(patchPlugin);
      SortMasters(patchPlugin);     
      AddMessage(patchPluginName + ' file created. Processed ' + IntToStr(processed) + ' records. Skipped ' + IntToStr(skipped) + ' records. Copied ' + IntToStr(copied) + ' records. Patched ' + IntToStr(patched) + ' records');
    end;
  finally
    Reset();
  end;
  
end;

procedure Reset();
begin
  patchPlugin := nil;
  
  if Assigned(patchRecords) then begin
    patchRecords.Free;
  end;
  patchSignature := '';
  patchPluginName := '';
  patchRecords := TStringList.create;
end;


// ================== Patcher Privates ==================

var
  currentPlugin,
  patchPlugin: IInterface;
  patchSignature,
  patchPluginName: string;

/// Traverses cell element recursively to find all nested cells that needs patching.
procedure ProcessCell(e: IInterface; var processed, skipped, copied, patched: Integer);
var
  i: integer;
begin
  if ElementType(e) = etMainRecord then begin
    if Signature(e) = 'CELL' then
      ProcessElement(e, processed, skipped, copied, patched);   
  end
  else begin
    // don't step into Cell Children, no CELLs there
    if GroupType(e) = 6 then
      Exit;
    
    for i := 0 to Pred(ElementCount(e)) do
      ProcessCell(ElementByIndex(e, i), processed, skipped, copied, patched);
  end;
end;

/// Traverses group element to find any nested elements that needs patching.
procedure ProcessGroup(group: IInterface; var processed, skipped, copied, patched: Integer);
var
  j: Integer;
begin
  Debug('Got ' + IntToStr(ElementCount(group)) + ' records to process in ' + GetFileName(currentPlugin));
  for j := 0 to Pred(ElementCount(group)) do
    ProcessElement(ElementByIndex(group, j), processed, skipped, copied, patched);
end;

/// Examines given element to determine whether it needs patching.
procedure ProcessElement(overrideElement: IInterface; var processed, skipped, copied, patched: Integer);
var
  patcherElement,
  patchedElement: IInterface;
  wasPatched: Boolean;
  j, k: Integer;
  pluginName, pluginPath: String;
begin
  Debug('Looking for override of ' + Stringify(overrideElement));
  overrideElement := GetPatchableWinningOverride(overrideElement);
  if not Assigned(overrideElement) or Equals(GetFile(overrideElement), GetFile(currentPlugin)) then begin
    Inc(skipped);
    Debug('Skipping ' + Stringify(overrideElement) + ' - no conflicts');
    Exit;
  end;
  
  Debug('Processing ' + Stringify(overrideElement));
  Inc(processed);
  
  if IsPatchedElement(overrideElement) then begin
    Debug('Skipping ' + Stringify(overrideElement));
    Inc(skipped);
    Exit;
  end;
  
  if not Assigned(patchPlugin) then
  begin
    patchPlugin := FileByName(PatchFileName(patchPluginName));
    if not Assigned(patchPlugin) then
      patchPlugin := CreatePatchFile(patchPluginName);
  end;
  if not Assigned(patchPlugin) then
    Exit;
  
  AddMastersSilently(overrideElement, patchPlugin);
  patchedElement := wbCopyElementToFile(overrideElement, patchPlugin, False, True);
  Debug('Copying ' + Stringify(overrideElement));
  Inc(copied);
  wasPatched := false;
  for k := 0 to Pred(patchRecords.Count) do
  begin
    pluginPath := PatcherPluginPathByIndex(k);
    pluginName := PatcherPluginNameByIndex(k);      
    patcherElement := GetPatcherElement(pluginName, overrideElement);
    Debug('Patching ' + Stringify(patcherElement));
    if not Assigned(patcherElement) then continue;
    if not wasPatched then
      Inc(patched);
    
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

/// Gets WinningOverride of the element if its not a patcher plugin nor a patch plugin.
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
    if not hasPatcher and not Equals(GetFile(overrideMaster), GetFile(currentPlugin)) then begin
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
var
  patchRecords: TStringList;

/// Checks whether given file is registered as patcher plugin.
function IsPatcherPlugin(f: IwbFile): Boolean;
var
  i: Integer;
  patchPluginName: String;
begin
  for i := 0 to Pred(patchRecords.Count) do
  begin
    patchPluginName := PatcherPluginNameByIndex(i);
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
    names.Add(PatcherPluginNameByIndex(i));
  end;
  Result := names;
end;

function PatcherPluginPathByIndex(index: Integer): String;
var
  s: TStrings;
begin
  s := Split(patchRecords[index], recordsDelimiter, true);
  if s.Count > 1 then
    Result := s[1];
  s.Free;
end;

function PatcherPluginNameByIndex(index: Integer): String;
var
  s: TStrings;
begin
  s := Split(patchRecords[index], recordsDelimiter, true);
  if s.Count > 0 then
    Result := s[0];
  s.Free;
end;


end.
