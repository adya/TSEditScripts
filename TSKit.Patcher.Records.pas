unit TSKitPatcherRecords;
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
function PatcherPlugins: TStrings;
var names: TStrings;
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
var signatures: TStrings;
	  components: TStrings;
	  i: Integer;
begin
	signatures := TStringList.Create;
	signatures.Duplicates := dupIgnore;
	for i := 0 to Pred(patchRecords.Count) do begin
		components := DeserializeComponentsAtIndex(i);
		if not Assigned(components) then begin
      AddMessage('Failed to get components from string "' + patchRecords[i] + '"');
    end;
    if not Assigned(signatures) then begin
      AddMessage('FATAL: Signature is null');
    end;
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
	records.Duplicates := dupIgnore;
	for i := 0 to Pred(patchRecords.Count) do begin
		components := DeserializeComponentsAtIndex(i);
		try 
			if (components[compositionSourcePluginIndex] = pluginName) and (components[compositionSignatureIndex] = signature) then begin
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
  Result := DeserializeComponentAtIndex(index, compositionSourcePluginIndex);
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
end;

function DeserializeComponentsAtIndex(patchIndex: Integer): TStrings;
begin
	Result := Split(patchRecords[patchIndex], recordsDelimiter, true);
end;

end.