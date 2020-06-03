unit TSKit.NoiseCancellation;

uses TSKit;
uses 'TSKit.Patcher';

const

  pluginName = 'NoiseCancellation';

/// Cancels "noise" (e.g. conflicts of meaningless records) in records with specified signature.
//procedure Denoise(signature, noise: string);
function Initialize: integer;
begin
var
  patchPlugin: IInterface;
  baseFiles: TStringList;
  group,
  overrideElement,
  element,
  patchedElement,
  currentPlugin: IInterface;
  processed, skipped, i, j, k: Integer;
begin
  
  baseFiles := BethesdaMasters();
  baseFiles.Add('Unofficial Skyrim Special Edition Patch.esp');
  try
  
  for i := 0 to Pred(baseFiles.Count) do
  begin
    currentPlugin := FileByName(baseFiles[i]);
    group := GroupBySignature(currentPlugin, 'WRLD');
    if Assigned(group) then
      Denoise(group, 'MHDT');
    group := GroupBySignature(currentPlugin, 'CELL');
    if Assigned(group) then
      Denoise(group, 'XCLW');
  Result := 0;
  finally
    baseFiles.Free; 
  end;
end;

procedure Denoise(group: IInterface, path: string);
var
 patchPlugin: IInterface;
  baseFiles: TStringList;
  group,
  overrideElement,
  element,
  patchedElement,
  currentPlugin: IInterface;
j, k: Integer;
begin
  for j := 0 to Pred(ElementCount(group)) do
    begin
      overrideElement := ElementByIndex(group, j);
      
      element := ElementByIndex(group, j);
      debug('Looking for override of ' + Stringify(element));
      overrideElement := WinningOverride(element);
      
      if Equals(GetFile(overrideElement), patchPlugin) then begin
        debug('Skipping ' + Stringify(overrideElement));
        Inc(skipped);
        continue;
      end;
      
      debug('Processing ' + Stringify(overrideElement));
      Inc(processed);
      
      if not Assigned(patchPlugin) then
        patchPlugin := CreatePatchFile(pluginName);

      if not Assigned(patchPlugin) then
        Exit;
      
      AddMastersSilently(overrideElement, patchPlugin);
      debug('Copying ' + Stringify(overrideElement));
      
      patchedElement := wbCopyElementToFile(overrideElement, patchPlugin, False, True);
      
      modelName := GetElementEditValues(patchedElement, 'Model\MODL - Model FileName');
      debug('Model: ' + modelName);
      
      
      if modelName = '' then begin
        AddMessage('Failed to read book''s model');
        continue;
      end;
      
      if Pos('Note', modelName) <> 0 then begin
        debug(Name(patchedElement) + ' is note');
        Inc(notes);
        weight := noteWeight;
      end
      else if  Pos('Journal', modelName) <> 0 then begin
        debug(Name(patchedElement) + ' is journal');
        Inc(journals);
        weight := journalWeight;
      end
      else begin
        debug(Name(patchedElement) + ' is book');
        Inc(books);
        weight := bookWeight;
      end;
      SetElementNativeValues(patchedElement, 'DATA\Weight', weight);
    end;
  end;
  if Assigned(patchPlugin) then begin
    SortMasters(patchPlugin);
    CleanMasters(patchPlugin);
    AddMessage('Patch file created. Processed ' + IntToStr(processed) + ' records: ' + IntToStr(books) + ' books, ' + IntToStr(journals) + ' journals, ' + IntToStr(notes) + ' notes. Skipped ' + IntToStr(skipped) + ' records.');
  end;
 end;

end.
