// TXST \ DODT - Decal Data \ Flags \ Alpha - Testing
unit TSKitFixENBDecals;
uses TSKit;

var patchPlugin: IInterface;
const texturePath = 'DODT - Decal Data\Flags';
const alphaTestingFlag = 'Alpha - Testing';

function Process(e: IInterface): integer;
var texture: IElement;

var g: IInterface;
var i: integer;
begin
  
  if not Assigned(patchPlugin) then
    patchPlugin := CreatePatchFile('ENB Decals - ' + GetFileName(GetFile(e)));
    
  if Signature(e) = 'TXST' then
    ProcessTexture(e)
  else 
    begin
    g := GroupBySignature(e, 'TXST');
    if not Assigned(g) then
      exit;
    for i := 0 to Pred(ElementCount(group)) do
      ProcessTexture(ElementByIndex(g, i));
  end;
end;

function Finalize: integer;
begin
  if Assigned(patchPlugin) then begin
      CleanMasters(patchPlugin);
      SortMasters(patchPlugin);     
    end;
end;

procedure ProcessTexture(texture: IElement);
var patchedElement: IElement;
var flag: IElement;
begin
  if HasFlag(ElementByPath(texture, texturePath), alphaTestingFlag) then
    Exit;
  
  AddMastersSilently(texture, patchPlugin);
  patchedElement := wbCopyElementToFile(texture, patchPlugin, False, True);
  
  flag := ElementByPath(patchedElement, texturePath);
  SetFlag(flag, alphaTestingFlag, True);
end;

end.
