unit TSKitReWeightBooks;

uses TSKitPatcher;

const
  pluginName = 'Scrolls';
  
  /// Scrolls
  scrollWeight = 0.1;

function Initialize: integer;
var
  patchPlugin: IInterface;
  group,
  overrideElement,
  element,
  patchedElement: IInterface;
  processed, skipped, i, j, k: Integer;

begin
  for i := 0 to Pred(FileCount) do
  begin
    group := GroupBySignature(FileByIndex(i), 'SCRL');
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
      
      SetElementNativeValues(patchedElement, 'DATA\Weight', scrollWeight);
    end;
  end;
  if Assigned(patchPlugin) then begin
    SortMasters(patchPlugin);
    CleanMasters(patchPlugin);
    AddMessage('Patch file created. Processed ' + IntToStr(processed) + ' scrolls. Skipped ' + IntToStr(skipped) + ' scrolls.');
  end;
  Result := 1;
end;

end.
