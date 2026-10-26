# Theme Studio research and implementation mapping

Public sources reviewed on 2026-10-22. This is an independent RTD implementation, not an upstream LinuxTex release or an affiliation claim.

## Product and application references

- [LinuxTex ThemeStudio on Payhip](https://payhip.com/LinuxTex): primary feature/design brief. Describes 30 looks, 15 GTK families, 17 icon families, 1,057 installable variants, original wallpapers, GTK4/Libadwaita GUI, terminal UI, component selection, local installation, removal, and Ubuntu reset. The listing does not publish the application source, paid asset collection, or full variant manifest.
- [hhanzla/Theme-Studio](https://github.com/hhanzla/Theme-Studio): an independently named GNOME customization manager whose README says development has stopped. Describes themes, cursors, extensions, app-grid organization and GDM styling. No evidence found linking it to LinuxTex. Its privileged GDM work is deliberately excluded from this user-local implementation.
- [GNOME Layout Manager](https://github.com/vmavromatis/gnome-layout-manager): an older preset/layout reference covering coordinated themes and extension dependencies. Its alpha status and old GNOME assumptions make its scripts unsuitable as a new backend.
- [Orchis](https://github.com/vinceliuice/Orchis-theme): documented theme/color/density options, optional GTK4 links, GTK rendering dependencies, and version-specific Shell styling.
- [Tela](https://github.com/vinceliuice/Tela-icon-theme): documented user-local installation destination and selectable folder-color variants.
- [WhiteSur](https://github.com/vinceliuice/WhiteSur-gtk-theme), [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme), [Graphite](https://github.com/vinceliuice/Graphite-gtk-theme), [Fluent](https://github.com/vinceliuice/Fluent-gtk-theme), and [Qogir](https://github.com/vinceliuice/Qogir-theme): profile options are based on upstream documentation, not a generic unvalidated shell argument field.
- [Everforest](https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme), [Gruvbox](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme), [Rose Pine](https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme), and [Tokyo Night](https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme): source compilation, GTK4 assets, and appearance/size/accent controls.

## Feature mapping

| Reference capability | RTD implementation |
| --- | --- |
| Coordinated looks | 30 independently composed presets; automatic installation of missing community families |
| Original high-resolution wallpapers | 30 deterministic original vector compositions, 3840×2160, generated locally |
| Theme/icon catalog | 16 GTK and 17 icon families with immutable source commits in [catalog.json](catalog.json) |
| More than 1,000 variants | Supported family-specific build profiles and real installed-variant enumeration; the paid catalog's exact count is not reproduced or claimed |
| Light/dark, colors, compact, solid, scaling | Installed variants plus allowlisted upstream build profiles; WhiteSur high-definition assets and scalable icon families |
| Shell themes | Installed Shell discovery and explicit User Themes extension checks |
| GTK4/Libadwaita | Opt-in CSS imports with original-file preservation, transactional rollback and reset |
| Visual discovery | Wallpaper/palette cards, family search, upstream preview links, installed-variant selectors |
| Local and reversible | User directories only, isolated source builds, settings preflight, snapshot/undo/recovery |
| Removal | Managed-family ownership manifest and active-use protection |
| Ubuntu reset | Yaru selection and default appearance keys, without resetting unrelated GNOME state |
| Graphical and terminal access | GTK4/Libadwaita GUI, interactive terminal menu, scriptable CLI using one backend |
| App-grid entry | Per-user desktop file, no system installation |
| Licenses and sources | Repository/revision/digest in manifest; upstream README/license/notice files retained locally |

## Asset provenance and source adaptations

The module vendors no third-party theme assets. Sources are fetched from HTTPS codeload URLs at the commits recorded in the catalog. Their licenses remain the responsibility and property of their upstream authors; installed copies retain the available notices. SHA-256 digests are recorded for auditability, not described as prepublished signature verification.

The built-in wallpaper generator and UI are original repository code. No paid LinuxTex assets or third-party application source were copied.

Fausto-Korpsvart repositories build from their `themes` directory; unrelated bundled icon trees are omitted during GTK-source extraction. BeautyLine's pinned archive contains absolute links to its author's `/home/kde` directory. An explicit catalog mapping rewrites only that known prefix to the corresponding files inside the downloaded BeautyLine tree. Unknown external symlinks remain rejected. Dangling upstream links are omitted rather than copied as broken user assets.

Previews are labeled palettes, not promises of exact rendering. Theme artwork and Shell/Libadwaita behavior vary across GNOME and application versions. Native GNOME accent changes do not recolor every third-party GTK stylesheet; select an appropriate installed color variant when needed.
