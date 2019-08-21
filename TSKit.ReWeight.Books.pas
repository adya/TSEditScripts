unit TSKitReWeightBooks;

uses TSKit;
uses 'TSKit.Patcher';

const

  pluginName = 'ReWeight.Books';
  
  /// Books and diaries
  bookWeight = 0.5;
  
  /// Journals
  journalWeight = 0.3;
  
  /// Notes, Recipes, Letters
  noteWeight = 0.1;

function Initialize: integer;
var
  patchPlugin: IInterface;
  group,
  overrideElement,
  element,
  patchedElement,
  currentPlugin: IInterface;
  modelName: string;
  weight: Float;
  processed, skipped, books, notes, journals, i, j, k: Integer;
begin
  for i := 0 to Pred(FileCount) do
  begin
    currentPlugin := FileByIndex(i);
    group := GroupBySignature(currentPlugin, 'BOOK');
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
      
      AddRequiredElementMasters(overrideElement, patchPlugin, False);
      debug('Copying ' + Stringify(overrideElement));
      
      patchedElement := wbCopyElementToFile(overrideElement, patchPlugin, False, True);
      
      modelName :=  GetElementEditValues(patchedElement, 'Model\MODL - Model FileName');
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
  Result := 0;
end;

end.
