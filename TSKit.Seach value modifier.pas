unit TSKit_Sandboxing;

uses TSKit;
uses mteFunctions;

/// Script that runs on MGEF group and searches for specified modifier in effect's data.

const modifier = 'Light Armor Modifier';
// const modifier = 'Light Armor Power Modifier';
// const modifier = 'Heavy Armor Modifier';
// const modifier = 'Heavy Armor Power Modifier';

function Process(e: IInterface): integer;
var element: IInterafce;
	j: integer;
begin
  Result := 0;
  for j := 0 to Pred(ElementCount(e)) do
		begin 
			element := ElementByIndex(e, j);
			if Contains(gav(element), modifier) then
				AddMessage(Stringify(element));
		end;
end;

end.
