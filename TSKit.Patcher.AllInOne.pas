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
  AddRecord('Dynamic Patch - ReWeight.Books.esp', 'DATA\Weight');
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'OBND - Object Bounds');
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'MODEL');
  AddRecord('Qw_BookCoversSkyrim_USSEP Patch.esp', 'INAM - Inventory Art');
  AddRecord('MysticismMagic.esp', 'DATA\Value');
  AddRecord('MysticismMagic.esp', 'FULL - Name');
  AddRecord('MysticismMagic.esp', 'OBND - Object Bounds');
  
  StartPatching('WEAP');
  // Sounds
  AddRecord('Audio Overhaul Skyrim.esp', 'INAM - Impact Data Set');
  
  StartPatching('FACT');
  AddRecord('Crime Overhaul Expanded.esp', 'DATA - Flags');
  AddRecord('Wild World.esp', 'Relations');
  AddRecord('Wild World.esp', 'DATA - Flags');
  AddRecord('Settlements Expanded SE.esp', 'Relations');
  
  StartPatching('CELL');
  // Light
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCLL - Lighting');
  AddRecord('OCW_Settings.esp', 'XCLL\Inherits');
  AddRecord('OCW_Settings.esp', 'LTMP');
  AddRecord('Particle Patch for ENB SSE.esp', 'DATA - Flags');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCCM');
  AddRecord('Particle Patch for ENB SSE.esp', 'XCIM');
  AddRecord('Luminosity - Skyrim is Lit Edition.esp', 'XCCM');
  AddRecord('ENB Light.esp', 'FNAM - Fade value');
  AddRecord('Unique Display Room.esp', 'XEZN - Encounter Zone');
 
  // Music
  AddRecord('Soulmancer Soundtrack - NoVindDun.esp', 'XCMO');
  
  // Locations
  AddRecord('SkyfallEstateBuildable.esp', 'XLCN - Location');
  AddRecord('Oakwood.esp', 'XLCN - Location');
  AddRecord('Gavorstead.esp', 'XLCN - Location');
  AddRecord('Forgotten DungeonsSSE.esm', 'XLCN - Location');
  AddRecord('Improved Adoptions MERGED.esp', 'XLCN - Location');
  AddRecord('Alternate Start - Live Another Life.esp', 'XLCN - Location');
  AddRecord('Unofficial Skyrim Special Edition Patch', 'XLCN - Location'); 
  
  StartPatching('SCRL');
  AddRecord('Unofficial Skyrim Special Edition Patch.esp', 'KWDA - Keywords');
  
  BuildPatch('SmartPatch');
  Result := 0;
end;

end.
