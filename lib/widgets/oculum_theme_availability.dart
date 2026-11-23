/// Retired themes remain resolvable for existing sheets and custom artwork.
/// This policy only controls new selections and acquisitions.
const oculumRetiredThemeIds = <String>{'whispering_reliquary'};

bool oculumIsThemeSelectable(String id) =>
    !oculumRetiredThemeIds.contains(id.trim().toLowerCase());
