unit TSKit;

const
  enableDebug = false;
  allowDuplicates = true;  
  patchPluginNamePrefix = 'Dynamic Patch';

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

procedure Debug(msg: String);
begin
  if enableDebug then
    AddMessage(msg);
end;

procedure PrintChildrenOrSelf(element: IwbContainer);
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
      PrintChildrenOrSelf(ElementByIndex(element, i));
    end;
  end;
end;

function CreatePatchFile(pluginName: string): IwbFile;
begin
  if pluginName = '' then
    Exit;
  
  pluginName := patchPluginNamePrefix + ' - ' + pluginName;
  if allowDuplicates then
    pluginName := pluginName + ' - ' + FormatDateTime('hhmmsszzz', Now);
  pluginName := pluginName + '.esp';
  Result := AddNewFileName(pluginName, True);
end;

end.