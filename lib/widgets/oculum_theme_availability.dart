/// Retired themes remain resolvable for existing sheets and custom artwork.
/// This policy only controls new selections and acquisitions.
const oculumRetiredThemeIds = <String>{
  'whispering_reliquary',
  'element_laser',
  'element_pack_laser',
};

bool oculumIsThemeSelectable(String id) =>
    !oculumRetiredThemeIds.contains(id.trim().toLowerCase());
