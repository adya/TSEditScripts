unit TSKitPatcher;

uses mteElements;

// ================== Configurations ==================
const
  enableDebug = false;


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
procedure Patch(signature: String);
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
      SortMasters(patchPlugin);
      CleanMasters(patchPlugin);
      AddMessage('Patch file created. Processed ' + IntToStr(processed) + ' records. Skipped ' + IntToStr(skipped) + ' records. Copied ' + IntToStr(copied) + ' records. Patched ' + IntToStr(patched) + ' records');
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
  patchRecords := TStringList.create;
end;

// ================== Utilities ==================

function Split(Input: string; const Delimiter: Char; strict: boolean): TStringList;
var
  Strings: TStrings;
begin
  Strings := TStringList.create;
  Strings.StrictDelimiter := true;
  Strings.Delimiter := Delimiter;
  Strings.DelimitedText := Input;
  Result := Strings;
end;

function Stringify(element: IInterface): String;
begin
  Result := Name(element) + ' from ' + GetFileName(GetFile(element));
end;

procedure debug(msg: String);
begin
  if enableDebug then
    AddMessage(msg);
end;

procedure printChildren(element: IwbContainer);
var
  child: IInterface;
  i: integer;
begin
  if ElementCount(element) < 2 then
    AddMessage(Path(element))
  else
  begin
    AddMessage(Path(element));
    for i := 0 to Pred(ElementCount(element)) do
    begin
      printChildren(ElementByIndex(element, i));
    end;
  end;
end;

// ================== Patcher Privates ==================

const
  recordsDelimiter = '@';
  
var
  patchRecords: TStringList;
  patchPlugin: IInterface;

procedure PatchGroup(group, currentPlugin: IInterface; var processed, skipped, copied, patched: Integer);
var
  overrideElement,
  patcherElement,
  patchedElement: IInterface;
  wasPatched: Boolean;
  j, k: Integer;
  pluginName, pluginPath: String;
begin
  debug('Got ' + IntToStr(ElementCount(group)) + ' records to process in ' + GetFileName(currentPlugin));
  for j := 0 to Pred(ElementCount(group)) do
  begin
    overrideElement := ElementByIndex(group, j);
    debug('Looking for override of ' + Stringify(overrideElement));
    overrideElement := WinningOverride(overrideElement);
    debug('Processing ' + Stringify(overrideElement));
    Inc(processed);
    //    if IsPatcherElement(overrideElement) then begin
    //      debug('Skipping ' + Stringify(overrideElement));
    //      Inc(skipped);
    //      continue;
    //    end;
    if not ShouldBePatched(overrideElement) then begin
      debug('Skipping ' + Stringify(overrideElement));
      Inc(skipped);
      continue;
    end;
    
    if not Assigned(patchPlugin) then
      patchPlugin := AddNewFile;
    
    if not Assigned(patchPlugin) then
      Exit;
    
    AddRequiredElementMasters(overrideElement, patchPlugin, False);
    patchedElement := wbCopyElementToFile(overrideElement, patchPlugin, False, True);
    debug('Copying ' + Stringify(overrideElement));
    Inc(copied);
    wasPatched := false;
    for k := 0 to Pred(patchRecords.Count) do
    begin
      pluginPath := PatcherPluginPathByIndex(k);
      pluginName := PatcherPluginNameByIndex(k);      
      patcherElement := GetPatcherElement(pluginName, overrideElement);
      debug('Patching ' + Stringify(patcherElement));
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
    debug('From ' + IntToStr(fromVal));
    debug('To ' + IntToStr(toVal));
    debug('Res ' + IntToStr(fromVal or toVal));
    SetNativeValue(ElementByPath(patchedElement, path), fromVal or toVal);
  end
  else begin
    AddRequiredElementMasters(patcherElement, patchPlugin, False);
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

/// Gets Element of the Patcher plugin if any for specified element.
function GetPatcherElement(patcherPluginName: String; element: IInterface): IInterface;
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
function ShouldBePatched(element: IInterface): Boolean;
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

function IsPatcherPlugin(f: IInterface): Boolean;
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

/// Checks whether or not given element is from one of the patcher plugins.
function IsPatcherElement(element: IInterface): Boolean;
var
  i: integer;
  patchPluginName: String;
  f: IInterface;
begin
  for i := 0 to Pred(patchRecords.Count) do
  begin
    patchPluginName := PatcherPluginNameByIndex(i);
    f := GetFile(element);
    if GetFileName(f) = patchPluginName then begin
      Result := true;
      Exit;
    end;
  end;
  Result := false;
end;

end.
