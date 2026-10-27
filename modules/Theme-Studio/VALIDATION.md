# Theme Studio validation

Validation performed through 2026-10-27. All appearance tests used temporary homes and fake or in-memory settings. The user's GNOME appearance was not changed.

## Automated and UI checks

- **46 unit/regression tests** pass: snapshots, undo, rollback on injected failure, pending-change recovery, locking, GTK4 original-file and symlink preservation, saved GTK4 components, ownership and active-theme protection, User Themes schema/permission repair, activation and next-login fallback, catalog/preset consistency, archive traversal/link handling, import rollback, source notices, and relocated/cross-family icon links.
- **Native GTK4/Libadwaita smoke test** passes: opens the real window, checks 63 look/family cards, verifies the multi-column gallery, visits all five pages, searches, runs an asynchronous action, refreshes selectors and closes cleanly.
- Inspected an actual [rendered application preview](Media_files/preview.png); fixed SVG intrinsic sizing that initially prevented the gallery from forming columns.
- Real **Gio.Settings** validation/write/read roundtrip passes with `GSETTINGS_BACKEND=memory`.
- Launcher passes `bash -n` and ShellCheck. Launching through a temporary symlink successfully locates the sibling Python backend.
- Generated desktop entry passes `desktop-file-validate`.
- Python compilation, CLI help/JSON catalog listing and whitespace checks pass.

## Online source/build checks

Each family was downloaded at its catalog commit, extracted and installed under a disposable home. Source installers ran inside the production Bubblewrap sandbox. No tests installed packages or changed system directories. After fixing importer and sandbox-environment issues, **33 of 33 families installed successfully**. WhiteSur GTK was retested with its build tools mounted from extracted distribution packages; the build produced 12 variants without changing the host system.

The table reports the upstream **default profile**, not every possible build combination. Counts exclude system-installed themes. Default-profile installation success does not establish visual correctness on every GNOME release.

| Family | Kind | Result | Installed variants |
| --- | --- | --- | ---: |
| Orchis | theme | Pass | 6 |
| WhiteSur | theme | Pass | 12 |
| Colloid | theme | Pass | 3 |
| Graphite | theme | Pass | 3 |
| Fluent | theme | Pass | 6 |
| Layan | theme | Pass | 6 |
| Qogir | theme | Pass | 3 |
| Matcha | theme | Pass | 12 |
| Mojave | theme | Pass | 8 |
| Nordic | theme | Pass | 1 |
| Dracula | theme | Pass | 1 |
| Everforest | theme | Pass | 2 |
| Gruvbox | theme | Pass | 2 |
| Rose Pine | theme | Pass | 2 |
| Tokyo Night | theme | Pass | 2 |
| Catppuccin | theme | Pass | 2 |
| Tela | icons | Pass | 3 |
| Tela Circle | icons | Pass | 3 |
| WhiteSur Icons | icons | Pass | 3 |
| Colloid Icons | icons | Pass | 3 |
| Fluent Icons | icons | Pass | 3 |
| Qogir Icons | icons | Pass | 9 |
| Vimix | icons | Pass | 2 |
| McMojave Circle | icons | Pass | 3 |
| Reversal | icons | Pass | 2 |
| La Capitaine | icons | Pass | 1 |
| Papirus | icons | Pass | 3 |
| Numix | icons | Pass | 2 |
| Numix Circle | icons | Pass | 2 |
| Candy | icons | Pass | 1 |
| BeautyLine | icons | Pass | 5 |
| Zafiro | icons | Pass | 2 |
| Win11 | icons | Pass | 2 |

An additional real build of **Orchis `compact-all-colors` produced 27 variants**, with installed links checked after extraction/build. Reversal, Win11 and Papirus were retested after their link-handling fixes. Catppuccin was retested after enabling its upstream batch mode. Not every family/profile combination was built.

The regression fixes include theme sources nested under `themes/`, explicit BeautyLine author-path repair, omission of dangling upstream links, preservation of safe shared icon links, remapping sandbox `/output/` links, and refusal to overwrite unmanaged themes. Large concurrent catalog tests briefly exhausted temporary filesystem inodes; the checked-in smoke runner uses sequential builds to avoid that test-only resource pressure.

## Reproduce

```bash
python3 -m unittest discover -s modules/Theme_Studio/tests -v
python3 modules/Theme_Studio/tests/smoke_gtk.py
python3 modules/Theme_Studio/tests/smoke_catalog.py --family orchis --profile compact-all-colors
python3 modules/Theme_Studio/tests/smoke_catalog.py --output /tmp/theme-studio-catalog-results.json
shellcheck modules/Theme_Studio/rtd-theme-studio
bash -n modules/Theme_Studio/rtd-theme-studio
```

The catalog smoke test downloads large archives and needs build prerequisites, disk space and inodes. Its temporary homes are cleaned on normal completion; it reports nonzero status for any failing family. The GUI test needs a display. Set `RTD_STUDIO_SMOKE_SCREENSHOT` to an output PNG path to capture its initial window.

## Remaining limits

- WhiteSur GTK requires a defined `TERM` even for a noninteractive build. The sandbox supplies the safe `dumb` terminal type while continuing to clear the rest of the caller environment.
- Actual GNOME Shell/GTK application rendering and logout/login behavior were not tested by changing a live desktop. Compatibility remains dependent on GNOME version and upstream theme quality.
- Native accent behavior on pre-GNOME-47 systems is covered through simulated schema absence, not a second installed GNOME version.
- The paid product's exact 1,057-variant inventory and original assets are not public and are not reproduced. The module exposes independently sourced families and supported build profiles; it does not claim exact paid-product parity.
