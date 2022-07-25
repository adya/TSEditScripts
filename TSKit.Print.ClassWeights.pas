unit TSKitPrintWeaponStat;

uses TSKit;
uses mteElements;
uses mteFunctions;
uses mteTypes;
uses math;

const 
    formIDPath = 'Record Header\FormID';
    namePath = 'FULL - Name';
    skillsPath = 'DATA\Skill Weights\';

function Initialize: Integer;
begin
AddMessage('Exporting CLAS data:');
AddMessage('FormID|name|One Handed|Two Handed|Archery|Block|Smithing|Heavy Armor|Light Armor|Pickpocket|Lockpicking|Sneak|Alchemy|Speech|Alteration|Conjuration|Destruction|Illusion|Restoration|Enchanting');
end;

function Process(e: IInterface): integer;
var s, form, name, summary: String;
    i: Integer;
begin
    Result := 0;
    if Signature(e) = 'CLAS' then
    begin
        s := geev(e, formIDPath);
        form := Copy(s, LastPos('[', s) + 6, 8);
        name := genv(e, namePath);
        summary := form  + '|' + name;

        for i := 0 to 17 do begin
            summary := summary + '|' + geevx(e, skillsPath + '[' + IntToStr(i) + ']')
        end; 
        AddMessage(summary);
    end;
end;

end.
