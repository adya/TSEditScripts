unit TSKitPrintWeaponStat;

uses TSKit;
uses mteFunctions;
uses mteTypes;
uses math;

const 
	formIDPath = 'Record Header\FormID';
	namePath = 'FULL - Name';
	editorIDPath = 'EDID - Editor ID';
	valuePath = 'DATA - Game Data\Value';
	weightPath = 'DATA - Game Data\Weight';
	damagePath = 'DATA - Game Data\Damage';
	speedPath = 'DNAM - Data\Speed';
	reachPath = 'DNAM - Data\Reach';
	staggerPath = 'DNAM - Data\Stagger';
	critDamagePath = 'CRDT - Critical Data\Damage';
	critMultPath = 'CRDT - Critical Data\% Mult';

function round2(const Number: Float; const Places: longint): Float;
var t: Float;
begin
   t := power(10, places);
   result := round(Number*t)/t;
end;

function GetMaterial(const editorId: String): String;
begin
	if Contains(editorId, 'Steel') then
		Result := 'Steel'
	else if Contains(editorId, 'Iron') then
		Result := 'Iron'
	else if Contains(editorId, 'Dwarven') then
		Result := 'Dwarven'
	else if Contains(editorId, 'Draugr') then
		Result := 'Draugr'
	else if Contains(editorId, 'Imperial') then
		Result := 'Imperial'
	else if Contains(editorId, 'Forsworn') then
		Result := 'Forsworn'
	else if Contains(editorId, 'Wood') then
		Result := 'Wood'
	else if Contains(editorId, 'Ebony') then
		Result := 'Ebony'
	else if Contains(editorId, 'Elven') then
		Result := 'Elven'
	else if Contains(editorId, 'Silver') then
		Result := 'Silver'
	else if Contains(editorId, 'Orcish') then
		Result := 'Orcish'
	else if Contains(editorId, 'Glass') then
		Result := 'Glass'
	else if Contains(editorId, 'Nordic') then
		Result := 'Nordic'
	else if Contains(editorId, 'Dragon_Bone') then
		Result := 'Dragon'
	else
		Result := '';
end;

function Initialize: Integer;
begin
AddMessage('Exporting WEAP data:');
AddMessage('FormID | name | material | weight | value | damage | reach | speed | stagger | crit mult | crit damage');
end;

function Process(e: IInterface): integer;
var damage, value, critDamage: Integer;
	weight, reach, stagger, speed, critMult: Float;
	s, form, name, material: String;
begin
  Result := 0;
  if Signature(e) = 'WEAP' then
  begin
  s := geev(e, formIDPath);
  form := Copy(s, LastPos('[', s) + 6, 8);
  name := genv(e, namePath);
  material := GetMaterial(geev(e, editorIDPath));
  value := genv(e, valuePath);
  weight := round2(genv(e, weightPath), 2);
  damage := genv(e, damagePath);
  speed := round2(genv(e, speedPath), 2);
  reach := round2(genv(e, reachPath), 2);
  stagger := round2(genv(e, staggerPath), 2);
  critDamage := genv(e, critDamagePath);
  critMult := round2(genv(e, critMultPath), 2);
  
  AddMessage(form  + ' | ' + name + ' | ' + material + ' | ' + FloatToStr(weight) + ' | ' + IntToStr(value) + ' | ' + IntToStr(damage) + ' | ' + FloatToStr(reach) + ' | ' + FloatToStr(speed) + ' | ' + FloatToStr(stagger) + ' | ' + FloatToStr(critMult) + ' | ' + IntToStr(critDamage));
  
  end;
end;

end.
