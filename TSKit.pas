unit TSKit;

const
  enableDebug = false;
  allowDuplicates = false;
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
  Result := Name(element) + ' | at ' + FullPath(element) + ' | from ' + GetFileName(GetFile(element));
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

procedure AddMastersSilently(originalElement: IwbElement; destination: IwbFile);
var
  i: integer;
  originalFile: IwbFile;
begin
  originalFile := GetFile(originalElement);
  Debug('Adding master ' + GetFileName(originalFile) + ' to ' + GetFileName(destination));
  AddMasterIfMissing(destination, GetFileName(originalFile));
  for i := 0 to Pred(MasterCount(originalFile)) do
  begin
    Debug('Adding master ' + GetFileName(originalFile) + ' to ' + GetFileName(destination));
    AddMasterIfMissing(destination, GetFileName(MasterByIndex(originalFile, i)));
  end;
end;

procedure SetFlag(eFlags: IInterface; flagName: string; flagValue: boolean);
var
  tstrlistFlags: TStringList;
  iCounter: Integer;
  iRawFlags, f2: Cardinal;
begin
 
  tstrlistFlags := TStringList.Create;
  tstrlistFlags.Text := FlagValues(eFlags); //Give each flag their own line. Value is the flag's name as a string
  iRawFlags := GetNativeValue(eFlags); //Get the binary result of the flags as an integer
   
  for iCounter := 0 to Pred(tstrlistFlags.Count) do //Iterate through each individual flag
    if SameText(tstrlistFlags[iCounter], flagName) then begin //If current line in the TStringList has the specified flag
           
      if flagValue then //If we want to set the flag to true
        f2 := iRawFlags or (1 shl iCounter)
      else //If we want to set the flag to false
        f2 := iRawFlags and not (1 shl iCounter);
           
      if iRawFlags <> f2 then SetNativeValue(eFlags, f2);
      Break;
           
    end;
       
  tstrlistFlags.Free;
   
end;

function HasFlag(flags: IElement; flagName: String): boolean;
begin
  Result := Assigned(ElementByPath(flags, flagName));
end;

end.
