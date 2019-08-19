{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  if Signature(e) = 'BOOK' then
  begin
    if GetElementEditValues(e, 'DATA\Weight') = 0.1 then
      SetElementEditValues(e, 'DATA\Weight', 0.01)
    else
    if GetElementEditValues(e, 'DATA\Weight') = 0.5 then
      SetElementEditValues(e, 'DATA\Weight', 0.2)
  end
  else if Signature(e) = 'SCRL' then
    SetElementEditValues(e, 'DATA\Weight', 0.01)
end;


end.
