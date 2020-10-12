unit TSKitPatcherUnified;
uses 'TSKit.Patcher';

//==============================================================================
function Initialize: integer;
begin
  StartPatching('BOOK');
  AddRecord('Book Covers Skyrim.esp', 'OBND - Object Bounds');
  AddRecord('Book Covers Skyrim.esp', 'MODEL');
  AddRecord('Book Covers Skyrim.esp', 'INAM');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'OBND - Object Bounds');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'MODEL');
  AddRecord('Book Covers Skyrim - Lost Library.esp', 'INAM');
  AddRecord('ReWeight.Books.esp', 'DATA - Item\Weight');
  AddRecord('ReWeight.Scrolls.esp', 'DATA - Item\Weight');
  AddRecord('MysticismMagic.esp', 'DATA\Value');
  AddRecord('MysticismMagic.esp', 'FULL - Name');
  AddRecord('MysticismMagic.esp', 'OBND - Object Bounds');
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'DESC - Book Text'); 
  AddRecord('Complete Alchemy & Cooking Overhaul.esp', 'DESC - Book Text'); 
  AddRecord('MysticismMagic.esp', 'DESC - Book Text');
  
  AddRecord('MysticismMagic.esp', 'EDID - Editor ID');
  
  StartPatching('WEAP');
  //// Sounds
  AddRecord('Audio Overhaul Skyrim.esp', 'BIDS - Block Bash Impact Data Set');
  AddRecord('Audio Overhaul Skyrim.esp', 'INAM - Impact Data Set');
  //
  StartPatching('FACT');
  AddRecord('Wild World.esp', 'Relations');
  AddRecord('Wild World - Crime Overhaul.esp', 'DATA - Flags');
  AddRecord('Settlements Expanded SE.esp', 'Relations');
  
  StartPatching('WRLD');
  
  // XCLL
  AddRecord('OCW_CellSettings.esp', 'XCLL\Inherits');
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCLL - Lighting');
  
  // LTMP
  AddRecord('OCW_CellSettings.esp', 'LTMP');
  
  // XCCM
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCCM');
  
  // XCIM
  AddRecord('OCW_CellSettings.esp', 'XCIM');
  
  // XCWT
  AddRecord('Water for ENB.esp', 'XCWT - Water');
  
   XCAS
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'XCAS - Acoustic Space');
  AddRecord('OCW_CellSettings.esp', 'XCAS - Acoustic Space');
  
  // XLCN
  AddRecord('Oakwood.esp', 'XLCN - Location');
  AddRecord('Forgotten DungeonsSSE.esm', 'XLCN - Location');
  AddRecord('Improved Adoptions MERGED.esp', 'XLCN - Location');
  AddRecord('Alternate Start - Live Another Life.esp', 'XLCN - Location');
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'XLCN - Location'); 
  
  StartPatching('LIGH');
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'DATA - DATA');
  AddRecord('Shadows.esp', 'DATA - DATA \ Near Clip');
  AddRecord('Shadows.esp', 'DATA - DATA \ Flicker Effect');
  
  StartPatching('SCRL');
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'KWDA - Keywords');
  
  StartPatching('REFR');
  AddRecord('Soljund''s Sinkhole.esp', 'Map Marker');
  AddRecord('Soljund''s Sinkhole.esp', 'XRDS - Radius');
  AddRecord('Soljund''s Sinkhole.esp', 'DATA - Position');
  
  BuildPatch('SmartPatch');
  Result := 0;
end;

end.
