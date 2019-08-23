unit TSKitPatcher;

uses TSKit;
uses mteElements;

// ================== Configurations ==================


// ================== Patcher ==================

/// Adds an element of specified plugin at given path as a reference value
/// that patcher will use in resulting patch.
procedure AddRecord(sourcePluginName: String; recordPath: String);
begin
  if not Assigned(patchRecords) then begin
    Reset();
  end;
  patchRecords.Add(Format('%s%s%s', [sourcePluginName, recordsDelimiter, recordPath]));
  AddMessage('Registered ' + recordPath + ' from ' + sourcePluginName);
end;

/// Creates a patch for all loaded plugins using
procedure Patch(signature, pluginName: String);
var
  group,
  block,
  subBlock,
  currentPlugin: IInterface;
  processed, skipped, patched, copied, i, j, k: Integer;
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
  try
    for i := 0 to Pred(FileCount) do
    begin
      currentPlugin := FileByIndex(i);
      
      if IsPatcherPlugin(currentPlugin) then continue;
      
      group := GroupBySignature(currentPlugin, signature);
      
      if signature = 'CELL' then begin
        for j := 0 to ElementCount(group) do
        begin
          block := ElementByIndex(group, j);
          for k := 0 to ElementCount(block) do
          begin
            subBlock := ElementByIndex(block, k);
            PatchGroup(subBlock, currentPlugin, processed, skipped, copied, patched);    
          end;
        end;
      end
      else begin
        PatchGroup(group, currentPlugin, processed, skipped, copied, patched);
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

const
  recordsDelimiter = '@';

var
  patchRecords: TStringList;
  patchPlugin: IInterface;
  patchSignature,
  patchPluginName: string;

procedure PatchGroup(group, currentPlugin: IInterface; var processed, skipped, copied, patched: Integer);
var
  overrideElement,
  patcherElement,
  patchedElement: IInterface;
  wasPatched: Boolean;
  j, k: Integer;
  pluginName, pluginPath: String;
begin
  Debug('Got ' + IntToStr(ElementCount(group)) + ' records to process in ' + GetFileName(currentPlugin));
  for j := 0 to Pred(ElementCount(group)) do
  begin
    overrideElement := ElementByIndex(group, j);
    Debug('Looking for override of ' + Stringify(overrideElement));
    overrideElement := GetPatchableWinningOverride(overrideElement);
    Debug('Processing ' + Stringify(overrideElement));
    Inc(processed);
    
    if IsPatchedElement(overrideElement) or (not ShouldBePatched(overrideElement)) then begin
      Debug('Skipping ' + Stringify(overrideElement));
      Inc(skipped);
      continue;
    end;
    
    if not Assigned(patchPlugin) then
      patchPlugin := CreatePatchFile(patchPluginName);
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
end;

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

/// Gets WinningOverride of the element or the first one that is not a patcher plugin.
function GetPatchableWinningOverride(element: IwbElement): IwbElement;
var
  master,
  overriden,
  candidate: IwbElement;
  i: integer;
begin
  overriden := WinningOverride(element);  
  if not IsPatcherPlugin(candidate) then begin
    Result := candidate;
    exit;
  end;
  
  master := MasterOrSelf(candidate);
  for i := Pred(OverrideCount(master)) downto 0 do
  begin
    candidate := OverrideByIndex(master, i);
    if not IsPatcherPlugin(candidate) and not IsBethesdaMaster(candidate) then begin
      Result := candidate;
      exit;
    end;
  end;
  
  Result := overriden;
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
function ShouldBePatched(element: IwbElement): Boolean;
var
  i, j: Integer;
  fileName: String;
  baseMaster, overrideMaster: IInterface;
begin
  
  baseMaster := MasterOrSelf(element);
  for i := 0 to Pred(OverrideCount(baseMaster)) do
  begin
    overrideMaster := OverrideByIndex(baseMaster, i);
    for j := 0 to Pred(patchRecords.Count) do
    begin
      if GetFileName(GetFile(overrideMaster)) = PatcherPluginNameByIndex(j) then begin
        Result := true;
        Exit;
      end;
    end;	
  end;
end;

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

/// Checks whether given file is one of official Bethesda master plugins.
function IsBethesdaMaster(f: IwbFile): Boolean;
var
  i: Integer;
  bethesdaMasterName: string;
  bethesdaMasters: TStringList;
begin
  
  bethesdaMasters := Split('Skyrim.esm,Update.esm,Dawnguard.esm,Dragonborn.esm,HearthFires.esm', ',', true);
  try
    for i := 0 to Pred(bethesdaMasters.Count) do
    begin
      bethesdaMasterName := bethesdaMasters[i];
      if GetFileName(f) = bethesdaMasterName then begin
        Result := true;
        Exit;
      end;
    end;
    Result := false;
  finally
    bethesdaMasters.Free;
  end;
end;

/// Checks whether or not given element is from the patch plugin.
function IsPatchedElement(element: IwbElement): Boolean;
var
  i: integer;
  f: IInterface;
begin
  for i := 0 to Pred(patchRecords.Count) do
  begin
    f := GetFile(element);
    if Equals(f, patchPlugin) then begin
      Result := true;
      Exit;
    end;
  end;
  Result := false;
end;

end.
