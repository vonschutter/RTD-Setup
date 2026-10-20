# RTD-Setup Repository Index

This generated catalog is the routing layer for repository work. Search it first, then open only the listed source files and symbols needed for the task.

Snapshot: commit `36658ae` with working-tree changes; 302 indexed paths; 1372 extracted code symbols. `docs/REPOSITORY_INDEX.md` excludes itself from counts.

Regenerate after structural or symbol changes:

```bash
python3 core/generate-repository-index.py
```

Fast, low-context lookups:

```bash
# Locate declarations without opening source files
rg -n -F '`symbol_name` —' docs/REPOSITORY_INDEX.md
# Find a module or tracked path
rg -n -F 'path_fragment' docs/REPOSITORY_INDEX.md
```

## Reuse Before Adding Code

1. Search the Symbol Index for an existing function before adding a helper.
2. Put cross-module Bash behavior in `core/_rtd_library`; keep UI and command orchestration in modules.
3. Put install/remove bundles in `core/_rtd_recipies.info` and command registration in `core/_locations.info`.
4. Reuse `_branding.info`, shared media, and existing GTK/TUI launch patterns instead of copying constants or assets.
5. Check sibling modules and their README before introducing another frontend or dependency wrapper.

## Repository Shape

| Area | Paths | Role |
| --- | ---: | --- |
| `.gitignore` | 1 | Git ignore policy. |
| `LICENSE` | 1 | Repository license text. |
| `LICENSE.md` | 1 | License documentation. |
| `README.md` | 1 | Primary user documentation and task routing. |
| `core` | 30 | Shared implementation, OEM flows, metadata, signatures, and core media. |
| `docs` | 3 | Getting-started, tool-reference, use-case, and generated repository documentation. |
| `media_files` | 26 | Repository-wide screenshots and branding assets. |
| `modules` | 236 | User-facing tools, compatibility commands, and module-local assets/docs. |
| `rtd-me.sh.cmd` | 1 | Cross-platform bootstrap/installation entry point. |
| `wallpaper` | 2 | Shared light/dark wallpaper assets. |

### File kinds

archive: 5, documentation: 50, file: 1, image: 155, metadata: 2, powershell: 4, python: 7, shell: 68, signature: 9, yml: 1

## Core Sources

| Source | Lines | Symbols | Purpose |
| --- | ---: | ---: | --- |
| [`core/_rtd_library`](../core/_rtd_library) | 36580 | 468 | Shared Bash API: platform, package, desktop, security, media, and VM functions. |
| [`core/_rtd_recipies.info`](../core/_rtd_recipies.info) | 1436 | 41 | Software bundle recipes consumed by the bundle managers. |
| [`core/_locations.info`](../core/_locations.info) | 392 | 0 | Tool registration and launcher metadata. |
| [`core/_branding.info`](../core/_branding.info) | 373 | 0 | Shared product names, paths, URLs, and presentation defaults. |
| [`core/rtd-oem-enable-config.sh`](../core/rtd-oem-enable-config.sh) | 367 | 7 | Register and configure RTD during automated Linux installs. |
| [`core/rtd-oem-linux-config.sh`](../core/rtd-oem-linux-config.sh) | 325 | 5 | Linux OEM workstation/server/VM configuration entry point. |
| [`core/rtd-vm-template-finalize-linux.sh`](../core/rtd-vm-template-finalize-linux.sh) | 263 | 12 | Install default bundles and reseal Linux VM templates. |
| [`core/rtd-bootstrap-progress-gtk.py`](../core/rtd-bootstrap-progress-gtk.py) | 358 | 3 | GTK progress UI for bootstrap and template finalization. |
| [`core/rtd-oem-macos-config.sh`](../core/rtd-oem-macos-config.sh) | 597 | 29 | macOS OEM configuration entry point. |
| [`core/rtd-oem-windows-setup.ps1`](../core/rtd-oem-windows-setup.ps1) | 2148 | 60 | Windows OEM setup and KVM guest integration. |
| [`core/rtd-oem-windows-setup-splash.ps1`](../core/rtd-oem-windows-setup-splash.ps1) | 1018 | 22 | Windows setup progress/splash UI. |

## Module Map

| Module | Entry points | Purpose |
| --- | --- | --- |
| [Security-tool.mod](../modules/Security-tool.mod/README.md) | `rtd-security-tool` | Interactive security auditing and hardening actions. |
| [gnome-shell-extension-installer.mod](../modules/gnome-shell-extension-installer.mod/README.md) | `rtd-gnome-shell-extension-installer` | Search for and install GNOME Shell extensions. |
| [light-weight-office-games.mod](../modules/light-weight-office-games.mod/README.md) | `rtd-light-weight-office-games` | Install a curated group of lightweight desktop games. |
| [macos-kvm.mod](../modules/macos-kvm.mod/README.md) | `macos-kvm-gtk.py`, `rtd-macos-kvm`, `rtd-macos-kvm-gui` | Prepare and define macOS recovery VMs on QEMU/KVM. |
| [minecraft-server-manager.mod](../modules/minecraft-server-manager.mod/README.md) | `rtd-minecraft-server` | Launch and monitor a dedicated Minecraft server. |
| [nordvpn-manager.mod](../modules/nordvpn-manager.mod/README.md) | `rtd-nordvpn` | Dialog wrapper for common NordVPN CLI operations. |
| [oem-app-runner.mod](../modules/oem-app-runner.mod/README.md) | `rtd-oem-app-runner` | Verify, unpack, and run packaged OEM support tools. |
| [oem-bundle-manager.mod](../modules/oem-bundle-manager.mod/README.md) | `rtd-oem-bundle-manager`, `rtd-oem-bundle-manager-legacy` | Install or remove role-oriented software bundles. |
| [oem-system-admin.mod](../modules/oem-system-admin.mod/README.md) | `rtd-7z-all-files-here`, `rtd-7z-encrypt-all-files-here`, `rtd-7z-encrypt-this`, `rtd-7z-this`, `rtd-add-ubuntu-to-landscape-onprem`, `rtd-burniso`, `rtd-clear-zombie`, `rtd-clear_iptables`, `rtd-configure-huion`, `rtd-deb-cleanup`, `rtd-dropbox-on-ecryptfs`, `rtd-get-Windows-product-key`, `rtd-internet-location`, `rtd-join-avi`, `rtd-make-bootable-cd`, `rtd-make-bootable-usb-drive`, `rtd-make-swap`, `rtd-malware-scan`, `rtd-malware-scan-HOME`, `rtd-mv`, `rtd-netuse`, `rtd-oem-old-kernel-remover`, `rtd-on-notify-wait`, `rtd-organize-everything`, `rtd-ppa-checker`, `rtd-restart-sound`, `rtd-script-menu`, `rtd-ssh-connection-list-local`, `rtd-tracker-force-update`, `rtd-unrar-all`, `rtd-xterm-sysconsole` | Small system-administration and support commands. |
| [oem-system-update.mod](../modules/oem-system-update.mod/README.md) | `rtd-self-update`, `rtd-update-system` | Update the OS and update/reinitialize RTD itself. |
| [oem-ventoy.mod](../modules/oem-ventoy.mod/README.md) | `rtd-ventoy-usb`, `ventoy-usb-gtk.py` | Build and maintain branded multi-ISO Ventoy media. |
| [rtd-ai-chat.mod](../modules/rtd-ai-chat.mod/README.md) | `rtd-ai-chat` | Launch local Ollama chat with an OpenAI-client fallback. |
| [rtd-check-sec.mod](../modules/rtd-check-sec.mod/README.md) | `rtd-check-sec` | Inspect exploit-mitigation properties of Linux binaries and processes. |
| [rtd-desktop-look-switcher.mod](../modules/rtd-desktop-look-switcher.mod/README.md) | `rtd-desktop-look-switcher` | Compatibility launcher for integrated desktop profiles. |
| [rtd-oem-tweaks.mod](../modules/rtd-oem-tweaks.mod/README.md) | `rtd-oem-tweaks`, `rtd-oem-tweaks-gtk.py` | GTK frontend for reusable GNOME/OEM tweaks. |
| [rtd-vpn-router.mod](../modules/rtd-vpn-router.mod/README.md) | `rtd-start-vpn-router` | Configure a fail-closed Linux VPN router. |
| [setup-whonix.mod](../modules/setup-whonix.mod/README.md) | `rtd-setup-whonix.sh` | Discover, verify, and define Whonix KVM guests. |
| [simple-support-tool.mod](../modules/simple-support-tool.mod/README.md) | `rtd-simple-support-tool` | Terminal menu for common local and remote support tasks. |
| [steam-world-of-tanks-utility.mod](../modules/steam-world-of-tanks-utility.mod/README.md) | `rtd-steam-world-of-tanks-utility` | Manage World of Tanks replays and GE-Proton. |
| [steam-world-of-warships-utility.mod](../modules/steam-world-of-warships-utility.mod/README.md) | `rtd-steam-world-of-warships-utility` | Manage World of Warships replays and GE-Proton. |
| [system-hardware-information.mod](../modules/system-hardware-information.mod/README.md) | `rtd-system-hardware-information` | Display hardware and sensor information in a YAD dashboard. |
| [system-user-backup.mod](../modules/system-user-backup.mod/README.md) | `rtd-oem-backup-linux-config`, `user-backup-gtk.py` | Create encrypted migration backups through GTK or CLI. |
| [theme-manager](../modules/theme-manager/README.md) | `rtd-theme-manager`, `theme-manager-gtk.py` | Apply GNOME themes, appearance elements, wallpapers, and desktop profiles. |
| [vm-tool.mod](../modules/vm-tool.mod/README.md) | `rtd-vm-tool`, `rtd-vm-tool-gtk` | Create and manage libvirt/KVM VMs through TUI and GTK frontends. |
| [windows.mod](../modules/windows.mod/README.md) | — | Payloads injected into unattended Windows VM installations. |

## Symbol Index

Format: `symbol` — `path:line`. Symbols are grouped by source so searches return a small, relevant slice.

### `core/_rtd_library`

- `dialog::clear_screen` — `core/_rtd_library:515`
- `dialog::ensure_menu_command` — `core/_rtd_library:555`
- `dialog` — `core/_rtd_library:591`
- `display_gui` — `core/_rtd_library:780`
- `dialog::check_menu_availability` — `core/_rtd_library:804`
- `rtd_ui::backend` — `core/_rtd_library:841`
- `rtd_ui::message` — `core/_rtd_library:890`
- `rtd_ui::text_file` — `core/_rtd_library:937`
- `rtd_ui::yes_no` — `core/_rtd_library:989`
- `rtd_ui::form` — `core/_rtd_library:1036`
- `rtd_ui::input` — `core/_rtd_library:1131`
- `rtd_ui::menu` — `core/_rtd_library:1183`
- `rtd_ui::checklist` — `core/_rtd_library:1263`
- `dialog::display_cmd_output` — `core/_rtd_library:1340`
- `dialog::copy_file_progress` — `core/_rtd_library:1368`
- `dialog::copy_with_progress` — `core/_rtd_library:1514`
- `dialog::display_notice` — `core/_rtd_library:1596`
- `dialog::display_error` — `core/_rtd_library:1630`
- `dialog::display_summary_message` — `core/_rtd_library:1664`
- `dialog::display_result` — `core/_rtd_library:1710`
- `dialog::prompt_yes_no` — `core/_rtd_library:1750`
- `yad::display_cmd_output` — `core/_rtd_library:1827`
- `yad::display_progressbar_pulsating` — `core/_rtd_library:1880`
- `zenity::display_info` — `core/_rtd_library:1923`
- `yad::display_info` — `core/_rtd_library:1957`
- `zenity::display_url` — `core/_rtd_library:1991`
- `yad::display_url` — `core/_rtd_library:2028`
- `zenity::display_file` — `core/_rtd_library:2066`
- `yad::display_file` — `core/_rtd_library:2102`
- `term::animate_while_command` — `core/_rtd_library:2137`
- `term::configure_tty_console_font` — `core/_rtd_library:2195`
- `term::configure_tty_console_font::usage` — `core/_rtd_library:2245`
- `term::configure_tty_console_font::find_font` — `core/_rtd_library:2319`
- `term::start_animation` — `core/_rtd_library:2473`
- `term::stop_animation` — `core/_rtd_library:2533`
- `term::task_exec_list_output` — `core/_rtd_library:2560`
- `term::err_no_menu_system_found` — `core/_rtd_library:2616`
- `network::check_inet_access` — `core/_rtd_library:2695`
- `network::get_oem_test_ips` — `core/_rtd_library:2764`
- `network::whats_my_ipinfo` — `core/_rtd_library:2780`
- `network::whats_my_external_ip` — `core/_rtd_library:2869`
- `network::rsync_upload` — `core/_rtd_library:2934`
- `network::rsync_download` — `core/_rtd_library:3060`
- `dependency::command_exists` — `core/_rtd_library:3234`
- `system::package_candidates_for_command` — `core/_rtd_library:3360`
- `dependency::current_desktop` — `core/_rtd_library:3390`
- `dependency::desktop` — `core/_rtd_library:3462`
- `desktop::apply_user_tweaks` — `core/_rtd_library:3548`
- `dependency::os_linux` — `core/_rtd_library:3651`
- `dependency::search_local` — `core/_rtd_library:3723`
- `dependency::file` — `core/_rtd_library:3797`
- `dialog::build_backtitle` — `core/_rtd_library:3871`
- `dependency::check_hardware_virtualization_support` — `core/_rtd_library:3895`
- `check_hardware_virtualization_support::_log_status` — `core/_rtd_library:3933`
- `check_hardware_virtualization_support::_log_error` — `core/_rtd_library:3941`
- `dependency::check_if_running_in_vm` — `core/_rtd_library:4009`
- `check_if_running_in_vm::_log_status` — `core/_rtd_library:4047`
- `check_if_running_in_vm::_log_error` — `core/_rtd_library:4055`
- `dependency::virtualization` — `core/_rtd_library:4094`
- `dependency::virtualization_log_status` — `core/_rtd_library:4134`
- `dependency::virtualization_log_error` — `core/_rtd_library:4142`
- `dependency::virtualization::_record_failure` — `core/_rtd_library:4155`
- `dependency::virtualization::_unit_exists` — `core/_rtd_library:4163`
- `dependency::virtualization::_enable_unit` — `core/_rtd_library:4167`
- `system::prepare_environment_for_iso_creation` — `core/_rtd_library:4411`
- `oem::task::iso::fetch_url` — `core/_rtd_library:4656`
- `oem::task::iso::sanitize_label` — `core/_rtd_library:4680`
- `oem::task::iso::sanitize_volume_id` — `core/_rtd_library:4700`
- `oem::task::iso::format_output_name` — `core/_rtd_library:4722`
- `oem::task::iso::find_cached_iso` — `core/_rtd_library:4748`
- `oem::task::iso::escape_ere` — `core/_rtd_library:4790`
- `oem::task::iso::prepare_keyring` — `core/_rtd_library:4806`
- `oem::task::iso::update_md5sum_entries` — `core/_rtd_library:4857`
- `oem::task::iso::collect_boot_cfg_paths` — `core/_rtd_library:4888`
- `oem::task::iso::inject_preseed_boot_params` — `core/_rtd_library:4935`
- `oem::task::iso::tweak_autoinstall_menu_labels` — `core/_rtd_library:5061`
- `oem::task::iso::inject_initrd` — `core/_rtd_library:5122`
- `oem::task::iso::rebuild_initrd_simple` — `core/_rtd_library:5854`
- `oem::task::iso::force_ubiquity_preseed` — `core/_rtd_library:6127`
- `oem::task::iso::download_url` — `core/_rtd_library:6196`
- `oem::task::iso::resolve_ubuntu_iso` — `core/_rtd_library:6256`
- `oem::task::iso::verify_ubuntu_iso` — `core/_rtd_library:6439`
- `oem::task::iso::resolve_debian_iso` — `core/_rtd_library:6511`
- `oem::task::iso::verify_debian_iso` — `core/_rtd_library:6699`
- `oem::task::iso::resolve_debian_netinst` — `core/_rtd_library:6771`
- `oem::task::iso::extract_iso` — `core/_rtd_library:6788`
- `oem::task::iso::extract_efi_boot_image` — `core/_rtd_library:6957`
- `oem::task::iso::detect_boot_args` — `core/_rtd_library:7046`
- `oem::task::iso::repack_iso` — `core/_rtd_library:7166`
- `oem::task::iso::post_build_menu` — `core/_rtd_library:7325`
- `oem::task::iso::ensure_grub_splash_fallback` — `core/_rtd_library:7403`
- `oem::task::debian::tweak_boot_cfg` — `core/_rtd_library:7436`
- `oem::task::debian::inject_initrd` — `core/_rtd_library:7474`
- `oem::task::ubuntu::inject_cloud_config` — `core/_rtd_library:7492`
- `oem::task::auto_install_iso_debian` — `core/_rtd_library:7583`
- `oem::task::auto_install_iso_ubuntu` — `core/_rtd_library:7682`
- `oem::task::auto_install_iso_zorin` — `core/_rtd_library:7890`
- `oem::task::auto_install_iso_windows` — `core/_rtd_library:8101`
- `system::download_and_manipulate_iso_debian` — `core/_rtd_library:8311`
- `system::create_iso_image_debian` — `core/_rtd_library:8316`
- `system::detect_session` — `core/_rtd_library:8443`
- `system::laptop_detect` — `core/_rtd_library:8481`
- `system::laptop_detect::_log` — `core/_rtd_library:8553`
- `system::preseed_to_ubuntu_ks_cfg` — `core/_rtd_library:8697`
- `system::make_preseed_cfg` — `core/_rtd_library:8729`
- `system::generate_cloudconfig` — `core/_rtd_library:8854`
- `system::generate_ks_cfg_file` — `core/_rtd_library:9034`
- `system::generate_autoyast_file` — `core/_rtd_library:9212`
- `system::install_missing_commands` — `core/_rtd_library:9318`
- `system::keyboard_set_layout` — `core/_rtd_library:9500`
- `system::check_file_limits` — `core/_rtd_library:9671`
- `system::check_file_limits::spinner` — `core/_rtd_library:9715`
- `system::distribution_type` — `core/_rtd_library:9773`
- `system::check_required_variables` — `core/_rtd_library:9934`
- `system::find_vm_bridge_gemini` — `core/_rtd_library:10000`
- `system::find_vm_bridge` — `core/_rtd_library:10131`
- `system::restart_sound` — `core/_rtd_library:10233`
- `system::remove_old_kernel` — `core/_rtd_library:10268`
- `system::oem_autounlock_disk` — `core/_rtd_library:10331`
- `system::get_Windows_Product_Key` — `core/_rtd_library:10396`
- `system::wait_for_internet_availability` — `core/_rtd_library:10414`
- `system::io_on_notify_wait` — `core/_rtd_library:10508`
- `system::display_spinner` — `core/_rtd_library:10552`
- `_spinner` — `core/_rtd_library:10564`
- `_start_spinner` — `core/_rtd_library:10617`
- `_stop_spinner` — `core/_rtd_library:10625`
- `system::add_or_remove_login_script` — `core/_rtd_library:10640`
- `_create_autostart_file` — `core/_rtd_library:10681`
- `_remove_autostart_file` — `core/_rtd_library:10727`
- `util::validate_heredoc_tabs_only` — `core/_rtd_library:10760`
- `system::update_config` — `core/_rtd_library:10820`
- `system::read_config` — `core/_rtd_library:10866`
- `system::generate_report_disk_space_used_by_directory` — `core/_rtd_library:10899`
- `system::toggle_oem_auto_login` — `core/_rtd_library:10939`
- `__toggle_dm_autologin` — `core/_rtd_library:10992`
- `system::set_oem_elevated_privilege_gui` — `core/_rtd_library:11108`
- `system::preserve_graphical_session_environment` — `core/_rtd_library:11230`
- `system::toggle_oem_auto_elevated_privilege` — `core/_rtd_library:11315`
- `system::make_system_recovery_partition` — `core/_rtd_library:11430`
- `system::run_command_in_gnome_user_session` — `core/_rtd_library:11496`
- `system::rtd_oem_reseal::_virtualization_context` — `core/_rtd_library:11516`
- `system::rtd_oem_reseal::_install_guest_additions` — `core/_rtd_library:11542`
- `system::rtd_oem_reseal::_prepare_ubuntu_like` — `core/_rtd_library:11618`
- `system::rtd_oem_reseal::_prepare_debian` — `core/_rtd_library:11641`
- `system::rtd_oem_reseal::_prepare_fedora` — `core/_rtd_library:11669`
- `system::rtd_oem_reseal::_prepare_suse` — `core/_rtd_library:11694`
- `system::rtd_oem_reseal::_finalize_shutdown` — `core/_rtd_library:11718`
- `system::rtd_oem_reseal` — `core/_rtd_library:11741`
- `system::create_swapfile` — `core/_rtd_library:11795`
- `system::create_swapfile::usage_mesage` — `core/_rtd_library:11832`
- `system::tune_system_power_profile` — `core/_rtd_library:11890`
- `system::rtd_oem_find_live_release` — `core/_rtd_library:11947`
- `system::validate_parameters` — `core/_rtd_library:12058`
- `system::optimize_harddrive` — `core/_rtd_library:12099`
- `_set_scheduler` — `core/_rtd_library:12113`
- `system::optimize_startup` — `core/_rtd_library:12181`
- `system::cleanup_and_finish` — `core/_rtd_library:12207`
- `github::clone_repo_user` — `core/_rtd_library:12257`
- `github::list_all_user_repositories` — `core/_rtd_library:12283`
- `oem::rtd_reset_default_environment_config` — `core/_rtd_library:12307`
- `oem::distro_release_upgrade` — `core/_rtd_library:12399`
- `oem::remove_non_western_latin_fonts` — `core/_rtd_library:12545`
- `oem::deploy_themes` — `core/_rtd_library:12576`
- `oem::register_all_tools` — `core/_rtd_library:12630`
- `oem::rtd_tools_make_launchers` — `core/_rtd_library:12771`
- `oem::create_single_launcher` — `core/_rtd_library:12785`
- `oem::rtd_tools_make_launchers_from_locations` — `core/_rtd_library:12862`
- `__oem_launcher_flush_entry` — `core/_rtd_library:12904`
- `oem::check_boot_splash_screen_enable` — `core/_rtd_library:12996`
- `oem::setup_brand_splash_screen` — `core/_rtd_library:13017`
- `gnome::set_tilix_ui_tweaks_for_user` — `core/_rtd_library:13199`
- `gnome::set_power_configuraton_for_user` — `core/_rtd_library:13355`
- `gnome::set_better_font_smoothing_for_user` — `core/_rtd_library:13385`
- `gnome::set_better_usability_for_user` — `core/_rtd_library:13405`
- `gnome::configure_dash_to_dock` — `core/_rtd_library:13426`
- `gnome::configure_dash_to_panel` — `core/_rtd_library:13462`
- `gnome::configure_nautilus` — `core/_rtd_library:13520`
- `gnome::organize_overlay_menu` — `core/_rtd_library:13540`
- `gnome::_apply_gtk4_theme` — `core/_rtd_library:13587`
- `gnome::_reset_ui_theme_settings` — `core/_rtd_library:13615`
- `gnome::ensure_window_buttons_visible` — `core/_rtd_library:13642`
- `gnome::_reload_shell_theme` — `core/_rtd_library:13659`
- `gnome::set_ui_common_tweaks_for_user` — `core/_rtd_library:13678`
- `gnome::_apply_terminal_preferences` — `core/_rtd_library:13693`
- `gnome::set_ui_tweaks_for_user` — `core/_rtd_library:13756`
- `gnome::set_basic_extensions_enabled` — `core/_rtd_library:13785`
- `gnome::set_startup_sound` — `core/_rtd_library:13895`
- `desktop::enable_firefox_pip_global` — `core/_rtd_library:14170`
- `gnome::set_ui_tweak_no_media_error` — `core/_rtd_library:14278`
- `gnome::set_ui_mac_tweaks_for_user` — `core/_rtd_library:14311`
- `gnome::set_ui_win10_tweaks_for_user` — `core/_rtd_library:14398`
- `gnome::set_ui_corporate_crisp_tweaks_for_user` — `core/_rtd_library:14484`
- `gnome::set_ui_moca_tweaks_for_user` — `core/_rtd_library:14574`
- `oem::register_wallpapers_for_gnome` — `core/_rtd_library:14641`
- `rtd_oem_turn_on_gui_network_management` — `core/_rtd_library:14690`
- `system::_enable_service` — `core/_rtd_library:14711`
- `system::ensure_directory_exists` — `core/_rtd_library:14763`
- `system::_disable_service` — `core/_rtd_library:14782`
- `system::_turn_on_gui_network_management` — `core/_rtd_library:14889`
- `add_gnome3_favorite_app` — `core/_rtd_library:15060`
- `kde::set_wallpaper` — `core/_rtd_library:15086`
- `kde::_kwriteconfig_cmd` — `core/_rtd_library:15149`
- `kde::_list_desktop_themes` — `core/_rtd_library:15165`
- `kde::_desktop_theme_exists` — `core/_rtd_library:15181`
- `kde::_default_desktop_theme` — `core/_rtd_library:15195`
- `kde::_plasma_version_major` — `core/_rtd_library:15218`
- `kde::_reload_shell` — `core/_rtd_library:15234`
- `kde::set_global_look_and_feel` — `core/_rtd_library:15275`
- `kde::set_color_scheme` — `core/_rtd_library:15342`
- `kde::set_icon_theme` — `core/_rtd_library:15392`
- `kde::set_cursor_theme` — `core/_rtd_library:15441`
- `kde::set_layout_panel` — `core/_rtd_library:15497`
- `kde::tune_fonts_antialias` — `core/_rtd_library:15543`
- `kde::apply_window_rules` — `core/_rtd_library:15581`
- `kde::set_startup_apps` — `core/_rtd_library:15647`
- `create_physical_media_from_iso` — `core/_rtd_library:15702`
- `util::add_iso_to_ventoy` — `core/_rtd_library:15851`
- `util::add_iso_to_ventoy::build_device_list` — `core/_rtd_library:15876`
- `oem::ventoy::resolve_latest_version` — `core/_rtd_library:15988`
- `oem::ventoy::download` — `core/_rtd_library:16044`
- `oem::ventoy::select_usb_device` — `core/_rtd_library:16146`
- `oem::ventoy::select_usb_device::build_list` — `core/_rtd_library:16180`
- `oem::ventoy::wipe_device` — `core/_rtd_library:16283`
- `oem::ventoy::unmount_device_partitions` — `core/_rtd_library:16329`
- `oem::ventoy::refresh_device_partitions` — `core/_rtd_library:16383`
- `oem::ventoy::create_usb` — `core/_rtd_library:16421`
- `oem::ventoy::detect_data_partition` — `core/_rtd_library:16603`
- `oem::ventoy::create_ext4_data_partition` — `core/_rtd_library:16687`
- `oem::ventoy::install_legacy_bios_fallback` — `core/_rtd_library:16731`
- `oem::ventoy::prepare_folders` — `core/_rtd_library:16786`
- `oem::ventoy::classify_iso` — `core/_rtd_library:16818`
- `oem::ventoy::copy_isos` — `core/_rtd_library:16849`
- `oem::ventoy::write_partition_title` — `core/_rtd_library:16992`
- `oem::ventoy::find_rtd_theme_background` — `core/_rtd_library:17031`
- `oem::ventoy::install_rtd_theme_assets` — `core/_rtd_library:17050`
- `oem::ventoy::write_menu_theme` — `core/_rtd_library:17087`
- `oem::ventoy::write_control_config` — `core/_rtd_library:17188`
- `oem::ventoy::brand_media` — `core/_rtd_library:17238`
- `oem::ventoy::setup_usb` — `core/_rtd_library:17265`
- `rtd_oem_ubuntu_auto_install_iso_builder` — `core/_rtd_library:17426`
- `system::process_vm_opt_args` — `core/_rtd_library:17435`
- `system::find_download_ubuntu_iso` — `core/_rtd_library:17501`
- `system::create_physical_media_from_ubuntu_iso` — `core/_rtd_library:17548`
- `cleanup` — `core/_rtd_library:17571`
- `log` — `core/_rtd_library:17579`
- `die` — `core/_rtd_library:17583`
- `usage` — `core/_rtd_library:17593`
- `tool::_compress_7z_items` — `core/_rtd_library:17782`
- `tool::_compress_7z_item_should_store` — `core/_rtd_library:17897`
- `tool::_format_elapsed_time` — `core/_rtd_library:17929`
- `tool::compress_all_items_here` — `core/_rtd_library:17958`
- `tool::compress_provided_items` — `core/_rtd_library:18093`
- `tool::recompress_all_items_in_folder` — `core/_rtd_library:18217`
- `tool::recompress_provided_items` — `core/_rtd_library:18296`
- `tool::up_2_date` — `core/_rtd_library:18362`
- `tool::test_iso_boot_media` — `core/_rtd_library:18403`
- `ssh::ensure_user_ssh_key` — `core/_rtd_library:18578`
- `ssh::ensure_key_installed_on_remote` — `core/_rtd_library:18647`
- `security::encrypt_disk_with_luks` — `core/_rtd_library:18731`
- `disk::reencrypt_device` — `core/_rtd_library:18859`
- `security::enable_firewall` — `core/_rtd_library:19007`
- `security::check_if_password_pOwned` — `core/_rtd_library:19138`
- `security::scan_for_malware` — `core/_rtd_library:19177`
- `security::change_disk_pass` — `core/_rtd_library:19261`
- `security::harden_ubuntu` — `core/_rtd_library:19286`
- `security::configure_clamav` — `core/_rtd_library:19366`
- `security::configure_fail2ban` — `core/_rtd_library:19454`
- `security::configure_rkhunter` — `core/_rtd_library:19563`
- `security::configure_auditd` — `core/_rtd_library:19644`
- `security::configure_auditd::ensure_audit_rules_dir` — `core/_rtd_library:19680`
- `security::sysctl_hardening` — `core/_rtd_library:19723`
- `security::secure_password_policy` — `core/_rtd_library:19815`
- `security::install_AIDE` — `core/_rtd_library:19869`
- `security::ensure_admin` — `core/_rtd_library:19914`
- `software::package_kit::add_package` — `core/_rtd_library:20152`
- `software::package_kit::remove_package` — `core/_rtd_library:20209`
- `software::list_bundles` — `core/_rtd_library:20236`
- `software::ensure_gnome_software_store_available` — `core/_rtd_library:20300`
- `software::refresh_flatpak_desktop_registration` — `core/_rtd_library:20359`
- `software::ensure_flatpak_package_managment` — `core/_rtd_library:20478`
- `software::enable_extra_repos` — `core/_rtd_library:20577`
- `software::offer_reboot_if_required` — `core/_rtd_library:20643`
- `software::updates_installed_today::native` — `core/_rtd_library:20751`
- `software::updates_installed_today::snap` — `core/_rtd_library:20804`
- `software::updates_installed_today::flatpak` — `core/_rtd_library:20821`
- `software::_flatpak_cmd` — `core/_rtd_library:20841`
- `software::_flatpak_filter_advisories` — `core/_rtd_library:20910`
- `software::update_flatpaks` — `core/_rtd_library:20967`
- `software::flatpak_list_eol_apps` — `core/_rtd_library:21067`
- `software::report_updates_installed_today` — `core/_rtd_library:21100`
- `software::show_updates_installed_today` — `core/_rtd_library:21129`
- `software::update_system_txt` — `core/_rtd_library:21156`
- `software::update_all_ui` — `core/_rtd_library:21242`
- `Native_Software_Packages` — `core/_rtd_library:21259`
- `Snap_Apps` — `core/_rtd_library:21295`
- `Flatpak_Apps` — `core/_rtd_library:21307`
- `software::from_flathub.org` — `core/_rtd_library:21352`
- `software::from_snapcraft.io` — `core/_rtd_library:21481`
- `software::from_snapcraft.io::_cleanup_tmp` — `core/_rtd_library:21532`
- `software::from_snapcraft.io::_install_snap` — `core/_rtd_library:21540`
- `software::add_software_task` — `core/_rtd_library:21642`
- `software::ensure_restricted_codecs` — `core/_rtd_library:21663`
- `software::vendor_download_and_install` — `core/_rtd_library:21698`
- `fetch_file` — `core/_rtd_library:21718`
- `software::is_native_package_available` — `core/_rtd_library:21789`
- `InstallSoftwareFromRepo` — `core/_rtd_library:21883`
- `display_message` — `core/_rtd_library:21901`
- `software::determine_package_name_from_dnf_command` — `core/_rtd_library:21926`
- `software::determine_package_name_from_cmd` — `core/_rtd_library:21949`
- `software::add_native_package` — `core/_rtd_library:22016`
- `software::native_management_availability_check` — `core/_rtd_library:22179`
- `software::ensure_snap_package_managment` — `core/_rtd_library:22255`
- `software::zypper_add_repo` — `core/_rtd_library:22421`
- `software::is_native_package_installed` — `core/_rtd_library:22481`
- `software::set_install_command` — `core/_rtd_library:22573`
- `software::add_gnome_extensions` — `core/_rtd_library:22640`
- `software::check_native_package_dependency` — `core/_rtd_library:22733`
- `software::rtd_ppa_checker` — `core/_rtd_library:22804`
- `software::remove_native_software_package` — `core/_rtd_library:22864`
- `system::determine_logfile` — `core/_rtd_library:22960`
- `system::log_item` — `core/_rtd_library:23085`
- `software::update_system` — `core/_rtd_library:23173`
- `display_software_installation_choices_gtk` — `core/_rtd_library:23251`
- `software::display_bundle_install_choices_gtk` — `core/_rtd_library:23283`
- `run_bundle_install` — `core/_rtd_library:23391`
- `software::display_bundle_removal_choices_gtk` — `core/_rtd_library:23449`
- `run_bundle_uninstall` — `core/_rtd_library:23524`
- `rtd_server_setup_choices_services` — `core/_rtd_library:23560`
- `rtd_server_setup_choices_productivity` — `core/_rtd_library:23625`
- `oem::setup_choices_server` — `core/_rtd_library:23692`
- `debian::download_iso` — `core/_rtd_library:23723`
- `oem::task::iso::resolve_fedora_iso` — `core/_rtd_library:23821`
- `oem::task::iso::verify_fedora_iso` — `core/_rtd_library:24058`
- `fedora::download_iso` — `core/_rtd_library:24126`
- `oem::task::iso::resolve_opensuse_iso` — `core/_rtd_library:24248`
- `oem::task::iso::verify_opensuse_iso` — `core/_rtd_library:24442`
- `opensuse::download_iso` — `core/_rtd_library:24521`
- `ubuntu::enable_plymouth_theme` — `core/_rtd_library:24620`
- `ubuntu::get_target_version` — `core/_rtd_library:24682`
- `ubuntu::get_latest_release_version` — `core/_rtd_library:24939`
- `ubuntu::download_iso` — `core/_rtd_library:25009`
- `macoskvm::normalize_installer_version` — `core/_rtd_library:25114`
- `macoskvm::normalize_modern_installer_version` — `core/_rtd_library:25146`
- `macoskvm::is_modern_installer_version` — `core/_rtd_library:25174`
- `macoskvm::version_label` — `core/_rtd_library:25188`
- `macoskvm::check_modern_host_requirements` — `core/_rtd_library:25213`
- `macoskvm::ensure_installer_dependencies` — `core/_rtd_library:25261`
- `macoskvm::ensure_vm_dependencies` — `core/_rtd_library:25303`
- `macoskvm::stage_boot_assets` — `core/_rtd_library:25392`
- `macoskvm::ensure_system_disk` — `core/_rtd_library:25583`
- `macoskvm::fetch_modern_installer_image` — `core/_rtd_library:25659`
- `macoskvm::fetch_installer_image` — `core/_rtd_library:25800`
- `macoskvm::define_vm` — `core/_rtd_library:25982`
- `macoskvm::prepare_host` — `core/_rtd_library:26341`
- `kvm::util::validate_vm_name` — `core/_rtd_library:26621`
- `kvm::util::set_vm_name` — `core/_rtd_library:26642`
- `kvm::util::config_label` — `core/_rtd_library:26772`
- `kvm::util::read_common_options` — `core/_rtd_library:26813`
- `kvm::util::read_distro_options` — `core/_rtd_library:26937`
- `kvm::util::read_distro_options::process_all_params` — `core/_rtd_library:27009`
- `kvm::get_vm_config_preferences` — `core/_rtd_library:27328`
- `kvm::get_vm_size_preferences` — `core/_rtd_library:27514`
- `kvm::get_kali_iso` — `core/_rtd_library:27690`
- `mint::get_mint_lmde_iso` — `core/_rtd_library:27789`
- `kvm::get_almalinux_boot_iso` — `core/_rtd_library:27848`
- `kvm::get_fedora_workstation_iso` — `core/_rtd_library:27936`
- `kvm::get_zorin_iso` — `core/_rtd_library:27989`
- `kvm__get_zorin_iso__get_latest_directory` — `core/_rtd_library:28030`
- `kvm__get_zorin_iso__get_highest_version_file` — `core/_rtd_library:28050`
- `kvm__get_zorin_iso__download_file` — `core/_rtd_library:28073`
- `kvm::mount_local_folder_to_guest` — `core/_rtd_library:28258`
- `kvm::create_expanding_vm_hardisk` — `core/_rtd_library:28403`
- `kvm::wait_for_domain_definition` — `core/_rtd_library:28482`
- `kvm::wait_for_domain_start` — `core/_rtd_library:28530`
- `kvm::cleanup_unused_qcow_images` — `core/_rtd_library:28606`
- `kvm::cleanup_virtual_floppy_images` — `core/_rtd_library:28707`
- `kvm::make_vm_now_from_fedora_org` — `core/_rtd_library:28778`
- `kvm::make_vm_now_from_redhat_com` — `core/_rtd_library:28974`
- `kvm::make_vm_now_from_opensuse_org` — `core/_rtd_library:29128`
- `kvm::make_vm_now_from_debian_org` — `core/_rtd_library:29268`
- `kvm::make_vm_now_from_kali_org` — `core/_rtd_library:29443`
- `kvm::make_vm_now_from_zorin` — `core/_rtd_library:29573`
- `kvm::make_vm_now_from_ubuntu_com` — `core/_rtd_library:29778`
- `kvm::make_vm_now_from_microsoft` — `core/_rtd_library:30267`
- `kvm::backup_all_running_vm` — `core/_rtd_library:30551`
- `kvm::backup_all_running_vm::do_vm_backup` — `core/_rtd_library:30576`
- `kvm::template_metadata_dir` — `core/_rtd_library:30668`
- `kvm::template_metadata_safe_name` — `core/_rtd_library:30672`
- `kvm::template_metadata_json_escape` — `core/_rtd_library:30680`
- `kvm::template_metadata_path` — `core/_rtd_library:30690`
- `kvm::template_metadata_write` — `core/_rtd_library:30695`
- `kvm::template_metadata_read_label` — `core/_rtd_library:30742`
- `kvm::clone_template_vm::_build_customize_args` — `core/_rtd_library:30773`
- `kvm::clone_template_vm::_format_name_component` — `core/_rtd_library:30836`
- `kvm::clone_template_vm::_display_template_label` — `core/_rtd_library:30865`
- `kvm::clone_template_vm::_detach_install_media` — `core/_rtd_library:30891`
- `kvm::clone_template_vm::_clone_from_category` — `core/_rtd_library:30959`
- `kvm::clone_server_template_vm` — `core/_rtd_library:31232`
- `kvm::clone_vdi_template_vm` — `core/_rtd_library:31262`
- `kvm::cicd::_render_extra_vars` — `core/_rtd_library:31292`
- `kvm::cicd::_render_user_data` — `core/_rtd_library:31332`
- `kvm::cicd::_render_meta_data` — `core/_rtd_library:31375`
- `kvm::cicd::_create_nocloud_iso` — `core/_rtd_library:31392`
- `kvm::cicd::configure_vm_with_ansible_pull` — `core/_rtd_library:31424`
- `whonix::init_context` — `core/_rtd_library:31581`
- `whonix::version_ge` — `core/_rtd_library:31628`
- `whonix::current_vm_version` — `core/_rtd_library:31647`
- `whonix::discover_bundle` — `core/_rtd_library:31671`
- `whonix::prepare_workdir` — `core/_rtd_library:31711`
- `whonix::download_with_verify` — `core/_rtd_library:31733`
- `whonix::download_bundle` — `core/_rtd_library:31768`
- `whonix::extract_archive` — `core/_rtd_library:31788`
- `whonix::detect_image_owner` — `core/_rtd_library:31833`
- `whonix::stage_images` — `core/_rtd_library:31858`
- `whonix::ensure_networks_defined` — `core/_rtd_library:31892`
- `whonix::ensure_networks_running` — `core/_rtd_library:31930`
- `whonix::add_extra_workstation` — `core/_rtd_library:31954`
- `whonix::define_vms` — `core/_rtd_library:31984`
- `whonix::maybe_skip_install` — `core/_rtd_library:32054`
- `template::preseed_cfg::early_command` — `core/_rtd_library:32145`
- `template::preseed_cfg::main` — `core/_rtd_library:32220`
- `template::preseed_cfg::auto_disk_layout` — `core/_rtd_library:32433`
- `template::preseed_cfg::expert_recipe` — `core/_rtd_library:32530`
- `template::preseed_cfg::late_command` — `core/_rtd_library:32595`
- `template::kickstart_cfg` — `core/_rtd_library:32749`
- `template::rtd_me_sh_cmd` — `core/_rtd_library:32982`
- `template::config_menu_cmd` — `core/_rtd_library:33179`
- `template::sysprep_unattend_xml` — `core/_rtd_library:33313`
- `template::autounattend_xml` — `core/_rtd_library:33378`
- `template::AutoYast_xml` — `core/_rtd_library:33755`
- `template::Agama_json` — `core/_rtd_library:33981`
- `template::cloud_config` — `core/_rtd_library:34243`
- `template::minecraft_server_launcher` — `core/_rtd_library:34719`
- `software::check_native_package_dependency` — `core/_rtd_library:34772`
- `install_software` — `core/_rtd_library:34793`
- `setup_minecraft_root` — `core/_rtd_library:34813`
- `run_minecraft_server_manager` — `core/_rtd_library:34831`
- `check_java` — `core/_rtd_library:34861`
- `find_active_network_interface` — `core/_rtd_library:34874`
- `minecraft_update` — `core/_rtd_library:34892`
- `announce.py` — `core/_rtd_library:34956`
- `start.sh` — `core/_rtd_library:35019`
- `server.properties` — `core/_rtd_library:35074`
- `eula.txt` — `core/_rtd_library:35137`
- `term::set_colors` — `core/_rtd_library:35258`
- `pause::for_input` — `core/_rtd_library:35449`
- `pause::a_given_time` — `core/_rtd_library:35485`
- `write_host` — `core/_rtd_library:35538`
- `write_error` — `core/_rtd_library:35614`
- `write_warning` — `core/_rtd_library:35643`
- `write_status` — `core/_rtd_library:35673`
- `write_information` — `core/_rtd_library:35703`
- `library::__cache_dir` — `core/_rtd_library:35733`
- `library::__desc_cache_file` — `core/_rtd_library:35749`
- `library::__load_desc_cache` — `core/_rtd_library:35764`
- `library::__save_desc_cache` — `core/_rtd_library:35803`
- `library::__build_header_desc_map` — `core/_rtd_library:35826`
- `library::__get_function_description` — `core/_rtd_library:35857`
- `library::__zformat_cache_file` — `core/_rtd_library:35911`
- `library::__load_zformat_cache` — `core/_rtd_library:35926`
- `library::__save_zformat_cache` — `core/_rtd_library:35944`
- `library::list_loaded_internal_functions` — `core/_rtd_library:35961`
- `library::check_status` — `core/_rtd_library:36084`
- `library::apply_rtd_defaults` — `core/_rtd_library:36138`
- `library::envcheck_report` — `core/_rtd_library:36219`
- `library::list_loaded_software_functions` — `core/_rtd_library:36254`
- `main` — `core/_rtd_library:36305`
- `display_documentation` — `core/_rtd_library:36410`

### `core/_rtd_recipies.info`

- `recipe:_Internet_Browsing_Private` — `core/_rtd_recipies.info:233`
- `recipe:_Internet_Browsing_Corporate` — `core/_rtd_recipies.info:290`
- `recipe:_Virtualization:_Desktop_Software` — `core/_rtd_recipies.info:315`
- `recipe:_CLOUD:_Management_Options` — `core/_rtd_recipies.info:328`
- `recipe:_ADM:_Software_Stores` — `core/_rtd_recipies.info:354`
- `recipe:_Office:_3D_Printing` — `core/_rtd_recipies.info:379`
- `recipe:_Office:_CAD_Software_Options` — `core/_rtd_recipies.info:406`
- `recipe:_Office:_Standard_Apps` — `core/_rtd_recipies.info:436`
- `recipe:_Media:_Streaming_Apps` — `core/_rtd_recipies.info:465`
- `recipe:_Media:_Streaming_Servers` — `core/_rtd_recipies.info:504`
- `recipe:_Media:_Players` — `core/_rtd_recipies.info:515`
- `recipe:_Media:_Audio_Editing_Options` — `core/_rtd_recipies.info:540`
- `recipe:_Media:_Video_Editing` — `core/_rtd_recipies.info:570`
- `recipe:_Office:_Developer_Software` — `core/_rtd_recipies.info:621`
- `recipe:_ADM:_Compression_Tools` — `core/_rtd_recipies.info:654`
- `recipe:_Top_Curated_Games_for_Linux` — `core/_rtd_recipies.info:695`
- `recipe:_ADM:_System_Admin_Tools` — `core/_rtd_recipies.info:762`
- `recipe:_ADM:_Linux_Subsystem_for_Windows` — `core/_rtd_recipies.info:786`
- `recipe:_Media:_Digital_Art_and_Imaging` — `core/_rtd_recipies.info:818`
- `recipe:_OEM:_Restricted_Fonts` — `core/_rtd_recipies.info:845`
- `recipe:_SEC:_Secure_Communication_Options` — `core/_rtd_recipies.info:859`
- `recipe:_Office:_AI_Tools` — `core/_rtd_recipies.info:876`
- `recipe:_Office:_Collaboration_and_Communicaiton` — `core/_rtd_recipies.info:895`
- `recipe:_OEM:_Remove_non_western_latin_fonts` — `core/_rtd_recipies.info:918`
- `recipe:_SEC:_Password_Management` — `core/_rtd_recipies.info:926`
- `recipe:_SEC:_Secure_Storage` — `core/_rtd_recipies.info:936`
- `recipe:_SEC:_network_security` — `core/_rtd_recipies.info:944`
- `recipe:_SEC:_Proton_Suite_of_Ecrypted_Services` — `core/_rtd_recipies.info:956`
- `recipe:_SEC:_VPN_Software` — `core/_rtd_recipies.info:1006`
- `recipe:_ADM:_Advanced_Terminals` — `core/_rtd_recipies.info:1039`
- `recipe:_OEM:_Themes_and_Tweaks` — `core/_rtd_recipies.info:1047`
- `recipe:_RDP:_Team_Viewer_Remote_Desktop` — `core/_rtd_recipies.info:1168`
- `recipe:_RDP:_Remmina_Remote_Desktop` — `core/_rtd_recipies.info:1190`
- `recipe:_RDP:_Chrome_Remote_Desktop` — `core/_rtd_recipies.info:1205`
- `recipe:_RDP:_Anydesk_Remote_Desktop` — `core/_rtd_recipies.info:1214`
- `recipe:_RDP:_RustDesk_Remote_Desktop` — `core/_rtd_recipies.info:1224`
- `recipe:_CLOUD:_MEGA_Cloud_Storage` — `core/_rtd_recipies.info:1234`
- `fetch_mega_file` — `core/_rtd_recipies.info:1256`
- `recipe:_CLOUD:_Dropbox_Cloud_Storage` — `core/_rtd_recipies.info:1309`
- `recipe:_RDP:_Citrix_App` — `core/_rtd_recipies.info:1329`
- `recipe:_Virtualization:_VirtualBox` — `core/_rtd_recipies.info:1352`

### `core/generate-repository-index.py`

- `git` — `core/generate-repository-index.py:70`
- `repository_paths` — `core/generate-repository-index.py:74`
- `is_text` — `core/generate-repository-index.py:89`
- `read_text` — `core/generate-repository-index.py:96`
- `kind_for` — `core/generate-repository-index.py:103`
- `declarations_for` — `core/generate-repository-index.py:124`
- `entrypoints_for` — `core/generate-repository-index.py:145`
- `markdown_escape` — `core/generate-repository-index.py:159`
- `main` — `core/generate-repository-index.py:163`

### `core/rtd-bootstrap-progress-gtk.py`

- `sanitize_terminal_output` — `core/rtd-bootstrap-progress-gtk.py:91`
- `BootstrapProgressWindow` — `core/rtd-bootstrap-progress-gtk.py:96`
- `main` — `core/rtd-bootstrap-progress-gtk.py:340`

### `core/rtd-oem-enable-config.sh`

- `main` — `core/rtd-oem-enable-config.sh:79`
- `rtd_oem_enable::json_escape` — `core/rtd-oem-enable-config.sh:162`
- `rtd_oem_enable::template_workflow_supported` — `core/rtd-oem-enable-config.sh:172`
- `rtd_oem_enable::write_template_workflow_config` — `core/rtd-oem-enable-config.sh:184`
- `wisdom_quotes_setup` — `core/rtd-oem-enable-config.sh:207`
- `configure_motd` — `core/rtd-oem-enable-config.sh:235`
- `tty_login_banner` — `core/rtd-oem-enable-config.sh:332`

### `core/rtd-oem-linux-config.sh`

- `complete_setup` — `core/rtd-oem-linux-config.sh:109`
- `search_local` — `core/rtd-oem-linux-config.sh:158`
- `dependency_file` — `core/rtd-oem-linux-config.sh:187`
- `oem_linux_config` — `core/rtd-oem-linux-config.sh:220`
- `oem_first_login_bundle_manager` — `core/rtd-oem-linux-config.sh:277`

### `core/rtd-oem-macos-config.sh`

- `usage` — `core/rtd-oem-macos-config.sh:80`
- `write_log` — `core/rtd-oem-macos-config.sh:104`
- `write_status` — `core/rtd-oem-macos-config.sh:118`
- `write_ok` — `core/rtd-oem-macos-config.sh:120`
- `write_warning` — `core/rtd-oem-macos-config.sh:121`
- `write_error` — `core/rtd-oem-macos-config.sh:122`
- `run_cmd` — `core/rtd-oem-macos-config.sh:123`
- `run_shell` — `core/rtd-oem-macos-config.sh:133`
- `run_user_cmd` — `core/rtd-oem-macos-config.sh:143`
- `run_user_shell` — `core/rtd-oem-macos-config.sh:157`
- `run_privileged_cmd` — `core/rtd-oem-macos-config.sh:169`
- `command_exists` — `core/rtd-oem-macos-config.sh:181`
- `require_macos` — `core/rtd-oem-macos-config.sh:185`
- `detect_target_user` — `core/rtd-oem-macos-config.sh:194`
- `parse_args` — `core/rtd-oem-macos-config.sh:220`
- `initialize_log` — `core/rtd-oem-macos-config.sh:295`
- `ensure_command_line_tools` — `core/rtd-oem-macos-config.sh:307`
- `homebrew_bin` — `core/rtd-oem-macos-config.sh:321`
- `ensure_homebrew` — `core/rtd-oem-macos-config.sh:332`
- `install_homebrew_apps` — `core/rtd-oem-macos-config.sh:357`
- `apply_privacy_defaults` — `core/rtd-oem-macos-config.sh:389`
- `apply_ui_defaults` — `core/rtd-oem-macos-config.sh:409`
- `apply_firewall_defaults` — `core/rtd-oem-macos-config.sh:446`
- `find_rtd_wallpaper_dir` — `core/rtd-oem-macos-config.sh:463`
- `apply_rtd_wallpapers` — `core/rtd-oem-macos-config.sh:495`
- `cleanup_user_caches` — `core/rtd-oem-macos-config.sh:531`
- `restart_user_interface` — `core/rtd-oem-macos-config.sh:541`
- `complete_setup` — `core/rtd-oem-macos-config.sh:554`
- `main` — `core/rtd-oem-macos-config.sh:562`

### `core/rtd-oem-windows-setup-splash.ps1`

- `Test-SetupAdministrator` — `core/rtd-oem-windows-setup-splash.ps1:40`
- `Test-SetupVirtualMachine` — `core/rtd-oem-windows-setup-splash.ps1:46`
- `Start-SetupElevated` — `core/rtd-oem-windows-setup-splash.ps1:67`
- `New-SetupDefaultState` — `core/rtd-oem-windows-setup-splash.ps1:114`
- `ConvertTo-SetupStateHashtable` — `core/rtd-oem-windows-setup-splash.ps1:121`
- `Read-SetupState` — `core/rtd-oem-windows-setup-splash.ps1:142`
- `Test-SetupStateCompleted` — `core/rtd-oem-windows-setup-splash.ps1:162`
- `Save-SetupState` — `core/rtd-oem-windows-setup-splash.ps1:171`
- `Set-SetupStateCompleted` — `core/rtd-oem-windows-setup-splash.ps1:185`
- `Initialize-SetupTransportSecurity` — `core/rtd-oem-windows-setup-splash.ps1:199`
- `Assert-SetupPowerShellSyntax` — `core/rtd-oem-windows-setup-splash.ps1:204`
- `Resolve-SetupWorker` — `core/rtd-oem-windows-setup-splash.ps1:226`
- `Resolve-SetupBanner` — `core/rtd-oem-windows-setup-splash.ps1:288`
- `Update-PresetDescription` — `core/rtd-oem-windows-setup-splash.ps1:539`
- `Set-SetupStep` — `core/rtd-oem-windows-setup-splash.ps1:554`
- `Add-SetupOutput` — `core/rtd-oem-windows-setup-splash.ps1:595`
- `Invoke-ConfiguredLicenseActivation` — `core/rtd-oem-windows-setup-splash.ps1:611`
- `Invoke-SetupSysprep` — `core/rtd-oem-windows-setup-splash.ps1:635`
- `Read-SetupMarker` — `core/rtd-oem-windows-setup-splash.ps1:684`
- `Receive-SetupOutput` — `core/rtd-oem-windows-setup-splash.ps1:762`
- `Complete-SetupFrontend` — `core/rtd-oem-windows-setup-splash.ps1:776`
- `Start-SetupWorker` — `core/rtd-oem-windows-setup-splash.ps1:842`

### `core/rtd-oem-windows-setup.ps1`

- `New-RtdDefaultState` — `core/rtd-oem-windows-setup.ps1:106`
- `ConvertTo-RtdStateHashtable` — `core/rtd-oem-windows-setup.ps1:117`
- `Read-RtdSetupState` — `core/rtd-oem-windows-setup.ps1:138`
- `Save-RtdSetupState` — `core/rtd-oem-windows-setup.ps1:164`
- `Test-RtdStateCompleted` — `core/rtd-oem-windows-setup.ps1:175`
- `Set-RtdStateCompleted` — `core/rtd-oem-windows-setup.ps1:184`
- `Invoke-RtdDefaultOnce` — `core/rtd-oem-windows-setup.ps1:200`
- `Write-RtdLog` — `core/rtd-oem-windows-setup.ps1:238`
- `Write-RtdStep` — `core/rtd-oem-windows-setup.ps1:263`
- `Test-RtdAdmin` — `core/rtd-oem-windows-setup.ps1:279`
- `Start-RtdElevated` — `core/rtd-oem-windows-setup.ps1:287`
- `Get-RtdWindowsIdentity` — `core/rtd-oem-windows-setup.ps1:321`
- `Mount-RtdDefaultUserHive` — `core/rtd-oem-windows-setup.ps1:379`
- `Dismount-RtdDefaultUserHive` — `core/rtd-oem-windows-setup.ps1:405`
- `Initialize-RtdWindowsConfig` — `core/rtd-oem-windows-setup.ps1:426`
- `Set-RtdRegistryValue` — `core/rtd-oem-windows-setup.ps1:473`
- `Remove-RtdRegistryValue` — `core/rtd-oem-windows-setup.ps1:510`
- `Save-RtdWallpaper` — `core/rtd-oem-windows-setup.ps1:537`
- `Set-RtdCurrentUserWallpaper` — `core/rtd-oem-windows-setup.ps1:574`
- `Set-RtdDefaultUserWallpaper` — `core/rtd-oem-windows-setup.ps1:603`
- `Set-RtdWindowsWallpaper` — `core/rtd-oem-windows-setup.ps1:629`
- `Set-RtdServiceStartup` — `core/rtd-oem-windows-setup.ps1:640`
- `Disable-RtdScheduledTask` — `core/rtd-oem-windows-setup.ps1:667`
- `Disable-RtdWindowsTelemetry` — `core/rtd-oem-windows-setup.ps1:690`
- `Disable-RtdWindowsSuggestionsAndAds` — `core/rtd-oem-windows-setup.ps1:730`
- `Disable-RtdWindowsCopilotWidgetsChat` — `core/rtd-oem-windows-setup.ps1:783`
- `Disable-RtdWindowsBackgroundApps` — `core/rtd-oem-windows-setup.ps1:797`
- `Disable-RtdWindowsGaming` — `core/rtd-oem-windows-setup.ps1:811`
- `Disable-RtdWindowsOneDrive` — `core/rtd-oem-windows-setup.ps1:831`
- `Set-RtdWindowsPerformanceUi` — `core/rtd-oem-windows-setup.ps1:858`
- `Set-RtdWindowsCompatibilityBaseline` — `core/rtd-oem-windows-setup.ps1:876`
- `Set-RtdWindowsEdgePolicy` — `core/rtd-oem-windows-setup.ps1:948`
- `Optimize-RtdWindowsServices` — `core/rtd-oem-windows-setup.ps1:965`
- `Remove-RtdAppxPackagePattern` — `core/rtd-oem-windows-setup.ps1:1014`
- `Remove-RtdWindowsBloatApps` — `core/rtd-oem-windows-setup.ps1:1061`
- `Initialize-RtdChocolatey` — `core/rtd-oem-windows-setup.ps1:1120`
- `Install-RtdChocolateyPackage` — `core/rtd-oem-windows-setup.ps1:1163`
- `Get-RtdVirtualizationPlatform` — `core/rtd-oem-windows-setup.ps1:1210`
- `Resolve-RtdSecureDownloadUrl` — `core/rtd-oem-windows-setup.ps1:1246`
- `Get-RtdLatestVirtioGuestTools` — `core/rtd-oem-windows-setup.ps1:1277`
- `Assert-RtdInstallerFile` — `core/rtd-oem-windows-setup.ps1:1337`
- `Save-RtdInstallerDownload` — `core/rtd-oem-windows-setup.ps1:1383`
- `Invoke-RtdMsiInstall` — `core/rtd-oem-windows-setup.ps1:1464`
- `Get-RtdKvmGuestComponentStatus` — `core/rtd-oem-windows-setup.ps1:1492`
- `Start-RtdKvmGuestServices` — `core/rtd-oem-windows-setup.ps1:1503`
- `Install-RtdVirtioGuestTools` — `core/rtd-oem-windows-setup.ps1:1524`
- `Install-RtdVirtualizationGuestTools` — `core/rtd-oem-windows-setup.ps1:1593`
- `Install-RtdShutUp10` — `core/rtd-oem-windows-setup.ps1:1630`
- `Enable-RtdWindowsMediaPlayer` — `core/rtd-oem-windows-setup.ps1:1662`
- `Install-RtdWindowsSoftware` — `core/rtd-oem-windows-setup.ps1:1680`
- `Expand-RtdKmsArchive` — `core/rtd-oem-windows-setup.ps1:1725`
- `Test-RtdPowerShellScriptSyntax` — `core/rtd-oem-windows-setup.ps1:1785`
- `Resolve-RtdDodSecureDefaultsScript` — `core/rtd-oem-windows-setup.ps1:1823`
- `Invoke-RtdDodSecureDefaults` — `core/rtd-oem-windows-setup.ps1:1873`
- `Run-RtdWindowsMinimal` — `core/rtd-oem-windows-setup.ps1:1907`
- `Run-RtdWindowsAggressive` — `core/rtd-oem-windows-setup.ps1:1920`
- `Test-RtdPendingReboot` — `core/rtd-oem-windows-setup.ps1:1926`
- `Test-RtdSysprepRequirements` — `core/rtd-oem-windows-setup.ps1:1951`
- `Invoke-RtdSysprepReseal` — `core/rtd-oem-windows-setup.ps1:1992`
- `Complete-RtdWindowsConfig` — `core/rtd-oem-windows-setup.ps1:2036`

### `core/rtd-vm-template-finalize-linux.sh`

- `rtd_template_finalize::json_escape` — `core/rtd-vm-template-finalize-linux.sh:32`
- `rtd_template_finalize::supported` — `core/rtd-vm-template-finalize-linux.sh:42`
- `rtd_template_finalize::manual_instruction` — `core/rtd-vm-template-finalize-linux.sh:54`
- `rtd_template_finalize::full_software_update` — `core/rtd-vm-template-finalize-linux.sh:68`
- `rtd_template_finalize::run_with_progress_gui` — `core/rtd-vm-template-finalize-linux.sh:80`
- `rtd_template_finalize::run_finalization_tasks` — `core/rtd-vm-template-finalize-linux.sh:98`
- `rtd_template_finalize::configure_post_oobe_bundle_manager` — `core/rtd-vm-template-finalize-linux.sh:130`
- `rtd_template_finalize::configure_post_oobe_sudoers` — `core/rtd-vm-template-finalize-linux.sh:154`
- `rtd_template_finalize::disable_temporary_oem_autologin` — `core/rtd-vm-template-finalize-linux.sh:170`
- `rtd_template_finalize::scrub_oem_autologin` — `core/rtd-vm-template-finalize-linux.sh:178`
- `rtd_template_finalize::write_status` — `core/rtd-vm-template-finalize-linux.sh:225`
- `rtd_template_finalize::main` — `core/rtd-vm-template-finalize-linux.sh:246`

### `modules/Security-tool.mod/rtd-security-tool`

- `rtd::bootstrap_library` — `modules/Security-tool.mod/rtd-security-tool:77`
- `rtd::bootstrap_library::ok` — `modules/Security-tool.mod/rtd-security-tool:104`
- `security_menu` — `modules/Security-tool.mod/rtd-security-tool:159`
- `display_help` — `modules/Security-tool.mod/rtd-security-tool:229`
- `main` — `modules/Security-tool.mod/rtd-security-tool:239`

### `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer`

- `usage_guide` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:37`
- `enable_extension` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:62`
- `extract_extension` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:73`
- `install_version` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:82`
- `move_file` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:96`
- `download_version` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:103`
- `check_version_availability` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:129`
- `select_version` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:161`
- `get_other_version` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:181`
- `extract_info` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:193`
- `download_info` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:208`
- `extract_comments` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:236`
- `download_comments` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:260`
- `search_help` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:286`
- `load_content` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:305`
- `restart_shell` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:326`
- `interactive_search` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:334`
- `get_info_from_id` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:466`
- `get_extension` — `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer:475`

### `modules/light-weight-office-games.mod/rtd-light-weight-office-games`

- `write_information` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:153`
- `write_warning` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:154`
- `write_error` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:155`
- `system::log_item` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:156`
- `rtd::bootstrap_library` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:157`
- `rtd::bootstrap_library::ok` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:174`
- `usage` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:226`
- `parse_args` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:247`
- `ui_message` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:288`
- `office_games::cleanup` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:305`
- `office_games::handle_signal` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:315`
- `detect_ui_tool` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:321`
- `confirm_ui_tool_installation` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:354`
- `install_ui_dependency` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:379`
- `install_requested_ui_tool` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:392`
- `flatpak_capability_is_present` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:405`
- `confirm_flatpak_capability_setup` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:412`
- `show_flatpak_setup_progress` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:435`
- `setup_flatpak_capability_as_admin` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:453`
- `ensure_flatpak_capability_for_installer` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:461`
- `show_welcome` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:485`
- `choose_scope` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:505`
- `select_games` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:569`
- `install_games` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:608`
- `office_games::log_progress_output` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:653`
- `show_progress` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:661`
- `build_install_summary` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:682`
- `main` — `modules/light-weight-office-games.mod/rtd-light-weight-office-games:719`

### `modules/macos-kvm.mod/macos-kvm-gtk.py`

- `combo` — `modules/macos-kvm.mod/macos-kvm-gtk.py:94`
- `entry` — `modules/macos-kvm.mod/macos-kvm-gtk.py:102`
- `spin` — `modules/macos-kvm.mod/macos-kvm-gtk.py:108`
- `switch` — `modules/macos-kvm.mod/macos-kvm-gtk.py:115`
- `sanitize_terminal_output` — `modules/macos-kvm.mod/macos-kvm-gtk.py:122`
- `MacOSKvmWindow` — `modules/macos-kvm.mod/macos-kvm-gtk.py:127`
- `main` — `modules/macos-kvm.mod/macos-kvm-gtk.py:495`

### `modules/macos-kvm.mod/rtd-macos-kvm`

- `die` — `modules/macos-kvm.mod/rtd-macos-kvm:41`
- `rtd::bootstrap_library` — `modules/macos-kvm.mod/rtd-macos-kvm:50`
- `rtd::bootstrap_library::ok` — `modules/macos-kvm.mod/rtd-macos-kvm:74`
- `usage` — `modules/macos-kvm.mod/rtd-macos-kvm:126`
- `doctor` — `modules/macos-kvm.mod/rtd-macos-kvm:177`
- `main` — `modules/macos-kvm.mod/rtd-macos-kvm:236`

### `modules/macos-kvm.mod/rtd-macos-kvm-gui`

- `die` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:72`
- `warn` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:78`
- `info` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:83`
- `ensure_graphical_session` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:88`
- `rtd::bootstrap_library` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:106`
- `gtk_frontend_ready` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:140`
- `install_python_gtk_dependencies` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:147`
- `ensure_python_gtk_frontend` — `modules/macos-kvm.mod/rtd-macos-kvm-gui:170`

### `modules/minecraft-server-manager.mod/rtd-minecraft-server`

- `dialog::clear_screen` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:47`
- `dialog` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:62`
- `check_dependencies` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:82`
- `install_software` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:103`
- `setup_minecraft_root` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:123`
- `run_minecraft_server_manager` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:141`
- `check_java` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:171`
- `find_active_network_interface` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:184`
- `minecraft_update` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:192`
- `announce.py` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:231`
- `start.sh` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:283`
- `update_gamemode` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:310`
- `server.properties` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:375`
- `eula.txt` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:427`
- `filetowrite.txt` — `modules/minecraft-server-manager.mod/rtd-minecraft-server:438`

### `modules/nordvpn-manager.mod/rtd-nordvpn`

- `set_colors` — `modules/nordvpn-manager.mod/rtd-nordvpn:58`
- `dialog::clear_screen` — `modules/nordvpn-manager.mod/rtd-nordvpn:61`
- `dialog` — `modules/nordvpn-manager.mod/rtd-nordvpn:76`
- `check_menu_availability` — `modules/nordvpn-manager.mod/rtd-nordvpn:98`
- `err_no_menu_system_found` — `modules/nordvpn-manager.mod/rtd-nordvpn:112`
- `install_software` — `modules/nordvpn-manager.mod/rtd-nordvpn:126`
- `err_nordvpn_install` — `modules/nordvpn-manager.mod/rtd-nordvpn:147`
- `err_no_menu_system_available` — `modules/nordvpn-manager.mod/rtd-nordvpn:155`
- `check_if_first_run` — `modules/nordvpn-manager.mod/rtd-nordvpn:165`
- `watch_vpn_connection` — `modules/nordvpn-manager.mod/rtd-nordvpn:179`
- `status_cycle` — `modules/nordvpn-manager.mod/rtd-nordvpn:183`
- `_cleanup` — `modules/nordvpn-manager.mod/rtd-nordvpn:192`
- `select_country_to_tunnel_to` — `modules/nordvpn-manager.mod/rtd-nordvpn:197`
- `run_nordvpn` — `modules/nordvpn-manager.mod/rtd-nordvpn:238`

### `modules/oem-app-runner.mod/rtd-oem-app-runner`

- `rtd::bootstrap_library` — `modules/oem-app-runner.mod/rtd-oem-app-runner:72`
- `rtd::bootstrap_library::ok` — `modules/oem-app-runner.mod/rtd-oem-app-runner:100`
- `oem::refresh_apps` — `modules/oem-app-runner.mod/rtd-oem-app-runner:150`
- `oem::run_payload` — `modules/oem-app-runner.mod/rtd-oem-app-runner:167`
- `internal::chk_param_payload` — `modules/oem-app-runner.mod/rtd-oem-app-runner:250`
- `display::help` — `modules/oem-app-runner.mod/rtd-oem-app-runner:271`
- `display::oem_program_list` — `modules/oem-app-runner.mod/rtd-oem-app-runner:298`

### `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager`

- `rtd::bootstrap_library` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:99`
- `rtd::bootstrap_library::ok` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:126`
- `bm2::log` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:179`
- `bm2::trim` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:187`
- `bm2::ensure_yad` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:194`
- `bm2::ensure_admin` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:203`
- `bm2::completed_file` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:212`
- `bm2::category_for_bundle` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:218`
- `bm2::display_name_for_bundle` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:229`
- `bm2::source_summary_for_bundle` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:240`
- `bm2::count_zformat_records` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:259`
- `bm2::build_list_args` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:268`
- `bm2::build_installed_list_args` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:304`
- `bm2::show_about` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:335`
- `bm2::dashboard` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:343`
- `bm2::select_bundles` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:371`
- `bm2::show_installed` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:410`
- `bm2::progress_dialog` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:436`
- `bm2::install_bundles` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:450`
- `bm2::default_installable_bundles` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:488`
- `bm2::install_default_bundles_noninteractive` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:511`
- `bm2::remove_bundles` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:557`
- `bm2::summary` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:593`
- `bm2::help` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:613`
- `bm2::main` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager:635`

### `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy`

- `rtd::bootstrap_library` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:149`
- `rtd::bootstrap_library::ok` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:177`
- `system::ExecStart` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:227`
- `system::ExecStart::help` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:361`
- `system::open_url_in_browser` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:391`
- `main` — `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy:460`

### `modules/oem-system-admin.mod/rtd-7z-all-files-here`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-7z-all-files-here:52`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-7z-all-files-here:78`
- `local_help` — `modules/oem-system-admin.mod/rtd-7z-all-files-here:128`

### `modules/oem-system-admin.mod/rtd-7z-encrypt-all-files-here`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-7z-encrypt-all-files-here:52`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-7z-encrypt-all-files-here:78`
- `local_help` — `modules/oem-system-admin.mod/rtd-7z-encrypt-all-files-here:128`

### `modules/oem-system-admin.mod/rtd-7z-encrypt-this`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-7z-encrypt-this:53`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-7z-encrypt-this:79`
- `local_help` — `modules/oem-system-admin.mod/rtd-7z-encrypt-this:129`

### `modules/oem-system-admin.mod/rtd-7z-this`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-7z-this:56`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-7z-this:82`
- `local_help` — `modules/oem-system-admin.mod/rtd-7z-this:132`

### `modules/oem-system-admin.mod/rtd-add-ubuntu-to-landscape-onprem`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-add-ubuntu-to-landscape-onprem:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-add-ubuntu-to-landscape-onprem:76`

### `modules/oem-system-admin.mod/rtd-burniso`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-burniso:48`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-burniso:74`

### `modules/oem-system-admin.mod/rtd-clear-zombie`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-clear-zombie:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-clear-zombie:76`
- `local_help` — `modules/oem-system-admin.mod/rtd-clear-zombie:126`

### `modules/oem-system-admin.mod/rtd-clear_iptables`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-clear_iptables:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-clear_iptables:76`

### `modules/oem-system-admin.mod/rtd-configure-huion`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-configure-huion:49`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-configure-huion:75`
- `local_help` — `modules/oem-system-admin.mod/rtd-configure-huion:125`

### `modules/oem-system-admin.mod/rtd-deb-cleanup`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-deb-cleanup:60`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-deb-cleanup:86`
- `rtd_oem_clean_deb` — `modules/oem-system-admin.mod/rtd-deb-cleanup:136`
- `local_help` — `modules/oem-system-admin.mod/rtd-deb-cleanup:164`
- `conditional_run` — `modules/oem-system-admin.mod/rtd-deb-cleanup:189`

### `modules/oem-system-admin.mod/rtd-dropbox-on-ecryptfs`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-dropbox-on-ecryptfs:49`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-dropbox-on-ecryptfs:75`
- `local_help` — `modules/oem-system-admin.mod/rtd-dropbox-on-ecryptfs:125`

### `modules/oem-system-admin.mod/rtd-get-Windows-product-key`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-get-Windows-product-key:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-get-Windows-product-key:76`

### `modules/oem-system-admin.mod/rtd-internet-location`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-internet-location:49`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-internet-location:75`
- `local_help` — `modules/oem-system-admin.mod/rtd-internet-location:125`

### `modules/oem-system-admin.mod/rtd-join-avi`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-join-avi:51`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-join-avi:77`
- `local_help` — `modules/oem-system-admin.mod/rtd-join-avi:127`
- `rtd_join_avis` — `modules/oem-system-admin.mod/rtd-join-avi:167`

### `modules/oem-system-admin.mod/rtd-make-bootable-cd`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:69`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:95`
- `cancelled` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:145`
- `exit_on_error` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:150`
- `expand_user_path` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:155`
- `prompt_yes_no_or_exit` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:171`
- `prompt_input` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:182`
- `directory_has_entries` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:195`
- `require_file` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:201`
- `check_environment` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:207`
- `get_task_information` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:266`
- `warn_deprecated` — `modules/oem-system-admin.mod/rtd-make-bootable-cd:293`

### `modules/oem-system-admin.mod/rtd-make-bootable-usb-drive`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-make-bootable-usb-drive:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-make-bootable-usb-drive:76`

### `modules/oem-system-admin.mod/rtd-make-swap`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-make-swap:49`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-make-swap:75`

### `modules/oem-system-admin.mod/rtd-malware-scan`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-malware-scan:52`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-malware-scan:78`
- `local_help` — `modules/oem-system-admin.mod/rtd-malware-scan:128`

### `modules/oem-system-admin.mod/rtd-malware-scan-HOME`

- `log_info` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:67`
- `log_warn` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:75`
- `log_error` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:83`
- `usage` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:91`
- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:118`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:144`
- `prompt_text` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:194`
- `resolve_invoking_user` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:210`
- `parse_args` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:229`
- `ensure_clamav` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:270`
- `run_freshclam` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:282`
- `validate_inputs` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:296`
- `build_scan_opts` — `modules/oem-system-admin.mod/rtd-malware-scan-HOME:331`

### `modules/oem-system-admin.mod/rtd-mv`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-mv:56`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-mv:82`
- `file_mover` — `modules/oem-system-admin.mod/rtd-mv:181`
- `build_file_list` — `modules/oem-system-admin.mod/rtd-mv:201`
- `move_file_list` — `modules/oem-system-admin.mod/rtd-mv:213`
- `display_help` — `modules/oem-system-admin.mod/rtd-mv:230`

### `modules/oem-system-admin.mod/rtd-netuse`

- `sanitize_args_for_log` — `modules/oem-system-admin.mod/rtd-netuse:75`
- `require_option_value` — `modules/oem-system-admin.mod/rtd-netuse:103`
- `clear_screen` — `modules/oem-system-admin.mod/rtd-netuse:113`
- `usage` — `modules/oem-system-admin.mod/rtd-netuse:121`
- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-netuse:148`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-netuse:174`
- `prompt_text` — `modules/oem-system-admin.mod/rtd-netuse:224`
- `prompt_password` — `modules/oem-system-admin.mod/rtd-netuse:240`
- `parse_yes_no` — `modules/oem-system-admin.mod/rtd-netuse:262`
- `prompt_netuse_form` — `modules/oem-system-admin.mod/rtd-netuse:273`
- `parse_args` — `modules/oem-system-admin.mod/rtd-netuse:336`
- `resolve_defaults` — `modules/oem-system-admin.mod/rtd-netuse:377`
- `create_credential_file` — `modules/oem-system-admin.mod/rtd-netuse:401`
- `cleanup_credential_file` — `modules/oem-system-admin.mod/rtd-netuse:416`
- `require_sudo_credentials` — `modules/oem-system-admin.mod/rtd-netuse:421`
- `run_admin_command` — `modules/oem-system-admin.mod/rtd-netuse:439`
- `ensure_mount_dir` — `modules/oem-system-admin.mod/rtd-netuse:447`
- `list_shares` — `modules/oem-system-admin.mod/rtd-netuse:461`
- `mount_share` — `modules/oem-system-admin.mod/rtd-netuse:487`

### `modules/oem-system-admin.mod/rtd-oem-old-kernel-remover`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-oem-old-kernel-remover:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-oem-old-kernel-remover:80`
- `main_sh` — `modules/oem-system-admin.mod/rtd-oem-old-kernel-remover:150`

### `modules/oem-system-admin.mod/rtd-on-notify-wait`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-on-notify-wait:66`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-on-notify-wait:92`

### `modules/oem-system-admin.mod/rtd-organize-everything`

- `dialog::clear_screen` — `modules/oem-system-admin.mod/rtd-organize-everything:71`
- `dialog` — `modules/oem-system-admin.mod/rtd-organize-everything:86`

### `modules/oem-system-admin.mod/rtd-ppa-checker`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-ppa-checker:50`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-ppa-checker:76`

### `modules/oem-system-admin.mod/rtd-restart-sound`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-restart-sound:51`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-restart-sound:77`

### `modules/oem-system-admin.mod/rtd-ssh-connection-list-local`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:52`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:78`
- `scan_local_net_ssh` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:128`
- `show_local_ssh_list` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:137`
- `get_remote_user` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:167`
- `configure_remote_user` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:180`
- `display_help` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:203`
- `parameter_check` — `modules/oem-system-admin.mod/rtd-ssh-connection-list-local:220`

### `modules/oem-system-admin.mod/rtd-unrar-all`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-unrar-all:51`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-unrar-all:76`
- `local_help` — `modules/oem-system-admin.mod/rtd-unrar-all:126`

### `modules/oem-system-admin.mod/rtd-xterm-sysconsole`

- `rtd::bootstrap_library` — `modules/oem-system-admin.mod/rtd-xterm-sysconsole:59`
- `rtd::bootstrap_library::ok` — `modules/oem-system-admin.mod/rtd-xterm-sysconsole:85`

### `modules/oem-system-update.mod/rtd-self-update`

- `rtd::bootstrap_library` — `modules/oem-system-update.mod/rtd-self-update:112`
- `rtd::bootstrap_library::ok` — `modules/oem-system-update.mod/rtd-self-update:138`
- `rtd::stage_powertools_update` — `modules/oem-system-update.mod/rtd-self-update:188`
- `rtd::cleanup_powertools_stage` — `modules/oem-system-update.mod/rtd-self-update:205`
- `rtd::register_updated_powertools` — `modules/oem-system-update.mod/rtd-self-update:211`
- `rtd::update_powertools_in_place` — `modules/oem-system-update.mod/rtd-self-update:222`
- `rtd::reinitialize_powertools` — `modules/oem-system-update.mod/rtd-self-update:261`
- `rtd::stage_themes_update` — `modules/oem-system-update.mod/rtd-self-update:313`
- `rtd::cleanup_themes_stage` — `modules/oem-system-update.mod/rtd-self-update:330`
- `rtd::update_themes_in_place` — `modules/oem-system-update.mod/rtd-self-update:336`
- `system::perform_powertools_update_linux` — `modules/oem-system-update.mod/rtd-self-update:370`
- `task_setup_rtd_basics` — `modules/oem-system-update.mod/rtd-self-update:416`
- `rtd_wait_for_internet_availability` — `modules/oem-system-update.mod/rtd-self-update:435`
- `do_update` — `modules/oem-system-update.mod/rtd-self-update:447`
- `oem_launch_me` — `modules/oem-system-update.mod/rtd-self-update:488`

### `modules/oem-system-update.mod/rtd-update-system`

- `script::help` — `modules/oem-system-update.mod/rtd-update-system:62`
- `script::config_notice` — `modules/oem-system-update.mod/rtd-update-system:118`
- `script::initialize_runtime` — `modules/oem-system-update.mod/rtd-update-system:123`
- `script::show_banner` — `modules/oem-system-update.mod/rtd-update-system:140`
- `main` — `modules/oem-system-update.mod/rtd-update-system:155`
- `rtd::bootstrap_library` — `modules/oem-system-update.mod/rtd-update-system:237`
- `rtd::bootstrap_library::ok` — `modules/oem-system-update.mod/rtd-update-system:263`
- `log_item` — `modules/oem-system-update.mod/rtd-update-system:313`
- `script::offer_remove_abandoned_flatpaks` — `modules/oem-system-update.mod/rtd-update-system:319`
- `update_me` — `modules/oem-system-update.mod/rtd-update-system:421`
- `config_me` — `modules/oem-system-update.mod/rtd-update-system:518`
- `setup_me` — `modules/oem-system-update.mod/rtd-update-system:529`

### `modules/oem-ventoy.mod/rtd-ventoy-usb`

- `rtd::bootstrap_library` — `modules/oem-ventoy.mod/rtd-ventoy-usb:59`
- `rtd::bootstrap_library::ok` — `modules/oem-ventoy.mod/rtd-ventoy-usb:85`
- `usage` — `modules/oem-ventoy.mod/rtd-ventoy-usb:135`
- `trace` — `modules/oem-ventoy.mod/rtd-ventoy-usb:179`
- `require_value` — `modules/oem-ventoy.mod/rtd-ventoy-usb:183`
- `set_default_dest` — `modules/oem-ventoy.mod/rtd-ventoy-usb:194`
- `require_dialog` — `modules/oem-ventoy.mod/rtd-ventoy-usb:206`
- `ui_notice` — `modules/oem-ventoy.mod/rtd-ventoy-usb:218`
- `ui_confirm` — `modules/oem-ventoy.mod/rtd-ventoy-usb:228`
- `normalize_device` — `modules/oem-ventoy.mod/rtd-ventoy-usb:242`
- `device_summary` — `modules/oem-ventoy.mod/rtd-ventoy-usb:255`
- `init_logging` — `modules/oem-ventoy.mod/rtd-ventoy-usb:289`
- `parse_args` — `modules/oem-ventoy.mod/rtd-ventoy-usb:298`
- `graphical_ventoy_frontend` — `modules/oem-ventoy.mod/rtd-ventoy-usb:382`
- `gtk_frontend_ready` — `modules/oem-ventoy.mod/rtd-ventoy-usb:396`
- `install_python_gtk_dependencies` — `modules/oem-ventoy.mod/rtd-ventoy-usb:401`
- `should_launch_gui` — `modules/oem-ventoy.mod/rtd-ventoy-usb:422`
- `launch_gui` — `modules/oem-ventoy.mod/rtd-ventoy-usb:449`
- `ui_select_action` — `modules/oem-ventoy.mod/rtd-ventoy-usb:464`
- `resolve_target_device` — `modules/oem-ventoy.mod/rtd-ventoy-usb:519`
- `build_setup_args` — `modules/oem-ventoy.mod/rtd-ventoy-usb:541`
- `build_confirm_message` — `modules/oem-ventoy.mod/rtd-ventoy-usb:556`
- `run_setup` — `modules/oem-ventoy.mod/rtd-ventoy-usb:590`
- `main` — `modules/oem-ventoy.mod/rtd-ventoy-usb:613`

### `modules/oem-ventoy.mod/ventoy-usb-gtk.py`

- `sanitize` — `modules/oem-ventoy.mod/ventoy-usb-gtk.py:59`
- `human_size` — `modules/oem-ventoy.mod/ventoy-usb-gtk.py:63`
- `removable_devices` — `modules/oem-ventoy.mod/ventoy-usb-gtk.py:76`
- `VentoyWindow` — `modules/oem-ventoy.mod/ventoy-usb-gtk.py:116`
- `main` — `modules/oem-ventoy.mod/ventoy-usb-gtk.py:578`

### `modules/rtd-ai-chat.mod/chatgpt.sh`

- `usage` — `modules/rtd-ai-chat.mod/chatgpt.sh:44`
- `handle_error` — `modules/rtd-ai-chat.mod/chatgpt.sh:97`
- `list_models` — `modules/rtd-ai-chat.mod/chatgpt.sh:107`
- `request_to_completions` — `modules/rtd-ai-chat.mod/chatgpt.sh:118`
- `request_to_image` — `modules/rtd-ai-chat.mod/chatgpt.sh:135`
- `request_to_chat` — `modules/rtd-ai-chat.mod/chatgpt.sh:150`
- `build_chat_context` — `modules/rtd-ai-chat.mod/chatgpt.sh:173`
- `escape` — `modules/rtd-ai-chat.mod/chatgpt.sh:181`
- `maintain_chat_context` — `modules/rtd-ai-chat.mod/chatgpt.sh:192`
- `build_user_chat_message` — `modules/rtd-ai-chat.mod/chatgpt.sh:210`
- `add_assistant_response_to_chat_message` — `modules/rtd-ai-chat.mod/chatgpt.sh:224`

### `modules/rtd-ai-chat.mod/rtd-ai-chat`

- `rtd::bootstrap_library` — `modules/rtd-ai-chat.mod/rtd-ai-chat:67`
- `rtd::bootstrap_library::ok` — `modules/rtd-ai-chat.mod/rtd-ai-chat:95`
- `rtd_ai_chat::usage` — `modules/rtd-ai-chat.mod/rtd-ai-chat:145`
- `rtd_ai_chat::parse_args` — `modules/rtd-ai-chat.mod/rtd-ai-chat:178`
- `rtd_ai_chat::load_configured_model` — `modules/rtd-ai-chat.mod/rtd-ai-chat:215`
- `rtd_ai_chat::save_default_model` — `modules/rtd-ai-chat.mod/rtd-ai-chat:226`
- `rtd_ai_chat::has_ollama` — `modules/rtd-ai-chat.mod/rtd-ai-chat:233`
- `rtd_ai_chat::ollama_responds` — `modules/rtd-ai-chat.mod/rtd-ai-chat:237`
- `rtd_ai_chat::install_ollama` — `modules/rtd-ai-chat.mod/rtd-ai-chat:242`
- `rtd_ai_chat::model_is_installed` — `modules/rtd-ai-chat.mod/rtd-ai-chat:268`
- `rtd_ai_chat::ensure_model` — `modules/rtd-ai-chat.mod/rtd-ai-chat:277`
- `rtd_ai_chat::resolve_chatgpt_fallback` — `modules/rtd-ai-chat.mod/rtd-ai-chat:284`
- `rtd_ai_chat::run_remote_fallback` — `modules/rtd-ai-chat.mod/rtd-ai-chat:295`
- `rtd_ai_chat::capture_stdin_prompt` — `modules/rtd-ai-chat.mod/rtd-ai-chat:315`
- `rtd_ai_chat::run_local` — `modules/rtd-ai-chat.mod/rtd-ai-chat:323`
- `rtd_ai_chat::main` — `modules/rtd-ai-chat.mod/rtd-ai-chat:352`

### `modules/rtd-check-sec.mod/rtd-check-sec`

- `version` — `modules/rtd-check-sec.mod/rtd-check-sec:110`
- `help` — `modules/rtd-check-sec.mod/rtd-check-sec:116`
- `command_exists` — `modules/rtd-check-sec.mod/rtd-check-sec:138`
- `root_privs` — `modules/rtd-check-sec.mod/rtd-check-sec:143`
- `isNumeric` — `modules/rtd-check-sec.mod/rtd-check-sec:152`
- `isString` — `modules/rtd-check-sec.mod/rtd-check-sec:157`
- `filecheck` — `modules/rtd-check-sec.mod/rtd-check-sec:162`
- `proccheck` — `modules/rtd-check-sec.mod/rtd-check-sec:216`
- `libcheck` — `modules/rtd-check-sec.mod/rtd-check-sec:289`
- `aslrcheck` — `modules/rtd-check-sec.mod/rtd-check-sec:304`
- `nxcheck` — `modules/rtd-check-sec.mod/rtd-check-sec:343`
- `kernelcheck` — `modules/rtd-check-sec.mod/rtd-check-sec:352`
- `FS_libc_check` — `modules/rtd-check-sec.mod/rtd-check-sec:503`
- `FS_binary_check` — `modules/rtd-check-sec.mod/rtd-check-sec:515`
- `FS_comparison` — `modules/rtd-check-sec.mod/rtd-check-sec:528`
- `FS_summary` — `modules/rtd-check-sec.mod/rtd-check-sec:555`

### `modules/rtd-desktop-look-switcher.mod/rtd-desktop-look-switcher`

- `find_theme_manager` — `modules/rtd-desktop-look-switcher.mod/rtd-desktop-look-switcher:17`
- `show_help` — `modules/rtd-desktop-look-switcher.mod/rtd-desktop-look-switcher:27`

### `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks`

- `rtd::bootstrap_library` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:194`
- `rtd::bootstrap_library::ok` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:220`
- `checkbox_state` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:277`
- `gtk4_settings_file` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:285`
- `startup_sound_autostart_file` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:289`
- `show_gnome_session_required_notice` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:293`
- `gsettings_value_is` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:313`
- `compact_gvariant` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:323`
- `gsettings_compact_value_is` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:327`
- `gsettings_value_contains` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:337`
- `gtk4_setting_is` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:347`
- `gtk4_custom_theme_present` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:359`
- `dconf_key_unset` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:369`
- `terminal_profiles` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:376`
- `default_terminal_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:380`
- `terminal_profile_schema` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:393`
- `tilix_expected_terminal_font` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:399`
- `terminal_profile_matches_defaults` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:407`
- `tilix_terminal_defaults_applied` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:421`
- `terminal_preferences_applied` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:439`
- `expected_extensions_list` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:453`
- `startup_sound_enabled` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:486`
- `overlay_folder_matches` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:494`
- `set_last_tweak_label` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:503`
- `tweak_is_applied` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:507`
- `initialize_menu_state` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:696`
- `capture_menu_selection` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:712`
- `sync_menu_state_from_selection` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:730`
- `show_gtk_menu` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:734`
- `profile_safe_name` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:775`
- `profile_path` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:782`
- `profile_exists` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:789`
- `valid_tweak_key` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:793`
- `reset_menu_selection` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:803`
- `prompt_profile_name` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:812`
- `show_profile_builder` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:828`
- `save_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:861`
- `choose_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:894`
- `load_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:921`
- `delete_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:943`
- `prompt_custom_gtk4_theme` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:957`
- `prompt_window_buttons_layout` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:985`
- `prompt_startup_sound_file` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1002`
- `run_function_checked` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1018`
- `apply_gsetting` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1030`
- `reset_gsetting` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1038`
- `reset_terminal_profile` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1045`
- `reset_tweak` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1062`
- `execute_tweak` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1205`
- `run_selected_tweaks` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1380`
- `print_status` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1476`
- `print_tweak_catalog` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1486`
- `print_profile_list` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1501`
- `apply_tweaks_cli` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1512`
- `set_tweak_state_cli` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1537`
- `apply_profile_cli` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1565`
- `gtk_frontend_ready` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1588`
- `launch_gtk_frontend` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1593`
- `main` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks:1606`

### `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py`

- `first_existing_path` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:51`
- `Tweak` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:67`
- `run_backend` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:76`
- `safe_profile_name` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:86`
- `TweakWindow` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:90`
- `main` — `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py:638`

### `modules/rtd-vpn-router.mod/rtd-start-vpn-router`

- `usage` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:96`
- `rtd::bootstrap_library` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:135`
- `rtd::bootstrap_library::ok` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:157`
- `initialize_runtime_user` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:207`
- `initialize_script` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:215`
- `cleanup` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:246`
- `require_command` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:250`
- `install_software` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:256`
- `ensure_optional_package` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:260`
- `vendor_download_and_install` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:267`
- `install_systemd_service` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:273`
- `find_active_newtork_interface` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:324`
- `derive_local_network` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:335`
- `find_active_bridge_interface` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:350`
- `wait_for_vpn_interface` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:375`
- `setup_routing_for_vpn` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:390`
- `get_codename` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:446`
- `install_nordvpn_client` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:458`
- `ensure_mullvad_repo` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:474`
- `ensure_protonvpn_repo` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:490`
- `install_vpn_client` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:499`
- `detect_vpn_client` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:519`
- `protonvpn_command` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:540`
- `prompt_vpn_country` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:548`
- `connect_vpn_client` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:575`
- `check_menu_availability` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:614`
- `choose_vpn_to_install` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:624`
- `run_vpn` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:642`
- `ensure_monitor_tool` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:667`
- `write_monitor_readme` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:691`
- `append_monitor_log` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:711`
- `bandwidth_monitor_command` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:723`
- `process_monitor_command` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:733`
- `start_byobu_monitoring` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:741`
- `start_monitoring` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:761`
- `vpn_router_service_is_active` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:784`
- `monitor_existing_service_only` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:789`
- `start_existing_service_monitor` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:796`
- `err_vpn_install` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:805`
- `err_no_menu_system_available` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:815`
- `err_no_menu_system_found` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:823`
- `main` — `modules/rtd-vpn-router.mod/rtd-start-vpn-router:848`

### `modules/setup-whonix.mod/rtd-setup-whonix.sh`

- `die` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:42`
- `init_paths` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:52`
- `set_source_urls` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:58`
- `parse_args` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:67`
- `rtd::bootstrap_library` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:87`
- `rtd::bootstrap_library::ok` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:112`
- `ensure_deps` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:164`
- `add_user_groups` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:178`
- `start_default_net` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:191`
- `sanity_check` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:198`
- `main` — `modules/setup-whonix.mod/rtd-setup-whonix.sh:204`

### `modules/simple-support-tool.mod/rtd-simple-support-tool`

- `rtd::bootstrap_library` — `modules/simple-support-tool.mod/rtd-simple-support-tool:148`
- `rtd::bootstrap_library::ok` — `modules/simple-support-tool.mod/rtd-simple-support-tool:174`
- `rtd_oem_check_inet_access` — `modules/simple-support-tool.mod/rtd-simple-support-tool:224`
- `check_menu_availability` — `modules/simple-support-tool.mod/rtd-simple-support-tool:242`
- `display_notice` — `modules/simple-support-tool.mod/rtd-simple-support-tool:288`
- `show_notice_on_fist_run` — `modules/simple-support-tool.mod/rtd-simple-support-tool:316`
- `rtd_setup_choices_cli_workstation` — `modules/simple-support-tool.mod/rtd-simple-support-tool:335`
- `show_make_media_gui_server` — `modules/simple-support-tool.mod/rtd-simple-support-tool:390`
- `show_make_media_gui_desktop` — `modules/simple-support-tool.mod/rtd-simple-support-tool:440`
- `rtd::find_vm_tool` — `modules/simple-support-tool.mod/rtd-simple-support-tool:498`
- `show_manage_vm_gui` — `modules/simple-support-tool.mod/rtd-simple-support-tool:530`
- `show_view_informaion_about_this_system` — `modules/simple-support-tool.mod/rtd-simple-support-tool:555`
- `show_monitor_informaion_about_this_system` — `modules/simple-support-tool.mod/rtd-simple-support-tool:655`
- `show_manage_software_gui` — `modules/simple-support-tool.mod/rtd-simple-support-tool:740`
- `show_main_menu` — `modules/simple-support-tool.mod/rtd-simple-support-tool:817`
- `show_manage_crypt_sec` — `modules/simple-support-tool.mod/rtd-simple-support-tool:899`
- `rtd::refresh_branding` — `modules/simple-support-tool.mod/rtd-simple-support-tool:962`

### `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility`

- `software::vendor_download_and_install` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:112`
- `fetch_file` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:123`
- `steam::get_proton_ge_versions` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:147`
- `steam::install_proton_ge` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:162`
- `get_ge_proton` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:204`
- `steam::find_replays` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:307`
- `steam::load_replays` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:346`
- `steam::wot_manager_ui` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:384`
- `steam::install_steam` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:449`
- `steam::system::log_item` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:470`
- `rtd_say` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:519`
- `write_error` — `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility:542`

### `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility`

- `software::vendor_download_and_install` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:104`
- `fetch_file` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:115`
- `steam::get_proton_ge_versions` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:139`
- `steam::install_proton_ge` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:154`
- `get_ge_proton` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:196`
- `steam::find_replays` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:245`
- `steam::load_replays` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:269`
- `steam::wow_manager_ui` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:307`
- `steam::install_steam` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:372`
- `steam::system::log_item` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:393`
- `rtd_say` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:442`
- `write_error` — `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility:465`

### `modules/system-hardware-information.mod/rtd-system-hardware-information`

- `rtd::bootstrap_library` — `modules/system-hardware-information.mod/rtd-system-hardware-information:84`
- `rtd::bootstrap_library::ok` — `modules/system-hardware-information.mod/rtd-system-hardware-information:110`
- `show_mod_info` — `modules/system-hardware-information.mod/rtd-system-hardware-information:160`
- `run::show_UI` — `modules/system-hardware-information.mod/rtd-system-hardware-information:171`

### `modules/system-user-backup.mod/rtd-oem-backup-linux-config`

- `rtd::bootstrap_library` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:83`
- `log_info` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:119`
- `log_status` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:121`
- `log_warn` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:122`
- `log_error` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:123`
- `ensure_rtd_library` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:128`
- `ensure_commands` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:132`
- `ensure_backup_dependencies` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:148`
- `ensure_estimate_dependencies` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:152`
- `ensure_profile_dependency` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:156`
- `install_gui_dependencies` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:166`
- `fetch_remote_file` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:178`
- `resolve_gtk_frontend` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:194`
- `resolve_gui_backend` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:214`
- `usage` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:237`
- `profile_rows` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:262`
- `list_profiles` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:283`
- `expand_path` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:291`
- `add_existing_source` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:300`
- `add_common_excludes` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:311`
- `prepare_profile_sources` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:325`
- `csv_to_profiles` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:398`
- `estimate_bytes` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:411`
- `json_escape` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:429`
- `write_manifest` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:437`
- `create_backup` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:473`
- `gtk_frontend_ready` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:524`
- `launch_gui` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:529`
- `parse_args` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:543`
- `main` — `modules/system-user-backup.mod/rtd-oem-backup-linux-config:567`

### `modules/system-user-backup.mod/user-backup-gtk.py`

- `human_size` — `modules/system-user-backup.mod/user-backup-gtk.py:61`
- `run_text` — `modules/system-user-backup.mod/user-backup-gtk.py:71`
- `BackupWindow` — `modules/system-user-backup.mod/user-backup-gtk.py:80`
- `main` — `modules/system-user-backup.mod/user-backup-gtk.py:437`

### `modules/theme-manager/rtd-theme-manager`

- `die` — `modules/theme-manager/rtd-theme-manager:68`
- `warn` — `modules/theme-manager/rtd-theme-manager:70`
- `info` — `modules/theme-manager/rtd-theme-manager:71`
- `require` — `modules/theme-manager/rtd-theme-manager:72`
- `desktop_matches` — `modules/theme-manager/rtd-theme-manager:76`
- `is_kde_desktop` — `modules/theme-manager/rtd-theme-manager:82`
- `is_gnome_desktop` — `modules/theme-manager/rtd-theme-manager:86`
- `launch_native_kde_look_settings` — `modules/theme-manager/rtd-theme-manager:90`
- `apply_kde_look_and_feel` — `modules/theme-manager/rtd-theme-manager:101`
- `rtd::bootstrap_library` — `modules/theme-manager/rtd-theme-manager:105`
- `gtk_frontend_ready` — `modules/theme-manager/rtd-theme-manager:143`
- `install_python_gtk_dependencies` — `modules/theme-manager/rtd-theme-manager:148`
- `ensure_python_gtk_frontend` — `modules/theme-manager/rtd-theme-manager:170`
- `ensure_dialog_backend` — `modules/theme-manager/rtd-theme-manager:186`
- `setting_is_writable` — `modules/theme-manager/rtd-theme-manager:220`
- `enable_extension_uuid` — `modules/theme-manager/rtd-theme-manager:224`
- `find_extension_installer` — `modules/theme-manager/rtd-theme-manager:236`
- `ensure_user_theme_extension` — `modules/theme-manager/rtd-theme-manager:246`
- `find_component_names` — `modules/theme-manager/rtd-theme-manager:271`
- `component_value_or_keep` — `modules/theme-manager/rtd-theme-manager:291`
- `dialog_info` — `modules/theme-manager/rtd-theme-manager:298`
- `dialog_list` — `modules/theme-manager/rtd-theme-manager:311`
- `pick_component` — `modules/theme-manager/rtd-theme-manager:323`
- `run_dialog_fallback` — `modules/theme-manager/rtd-theme-manager:332`
- `set_setting` — `modules/theme-manager/rtd-theme-manager:393`
- `apply_theme` — `modules/theme-manager/rtd-theme-manager:404`
- `require_profile_functions` — `modules/theme-manager/rtd-theme-manager:434`
- `apply_desktop_profile` — `modules/theme-manager/rtd-theme-manager:440`
- `show_help` — `modules/theme-manager/rtd-theme-manager:493`
- `main` — `modules/theme-manager/rtd-theme-manager:555`

### `modules/theme-manager/theme-manager-gtk.py`

- `directories` — `modules/theme-manager/theme-manager-gtk.py:115`
- `theme_names` — `modules/theme-manager/theme-manager-gtk.py:126`
- `theme_path` — `modules/theme-manager/theme-manager-gtk.py:130`
- `wallpapers` — `modules/theme-manager/theme-manager-gtk.py:138`
- `get_setting` — `modules/theme-manager/theme-manager-gtk.py:151`
- `combo` — `modules/theme-manager/theme-manager-gtk.py:166`
- `combo_value` — `modules/theme-manager/theme-manager-gtk.py:177`
- `scaled_image` — `modules/theme-manager/theme-manager-gtk.py:181`
- `ThemeManager` — `modules/theme-manager/theme-manager-gtk.py:188`

### `modules/vm-tool.mod/rtd-vm-tool`

- `rtd::bootstrap_library` — `modules/vm-tool.mod/rtd-vm-tool:138`
- `rtd::bootstrap_library::ok` — `modules/vm-tool.mod/rtd-vm-tool:164`
- `main` — `modules/vm-tool.mod/rtd-vm-tool:226`
- `vmtool::has_graphical_session` — `modules/vm-tool.mod/rtd-vm-tool:313`
- `vmtool::has_graphical_backend` — `modules/vm-tool.mod/rtd-vm-tool:319`
- `vmtool::configure_ui_mode` — `modules/vm-tool.mod/rtd-vm-tool:324`
- `vmtool::launch_gui` — `modules/vm-tool.mod/rtd-vm-tool:370`
- `launch_byobu` — `modules/vm-tool.mod/rtd-vm-tool:390`
- `vmtool::refresh_backtitle` — `modules/vm-tool.mod/rtd-vm-tool:444`
- `vmtool::settings_file` — `modules/vm-tool.mod/rtd-vm-tool:454`
- `vmtool::load_tool_settings` — `modules/vm-tool.mod/rtd-vm-tool:472`
- `vmtool::ubuntu_version_prompt_enabled` — `modules/vm-tool.mod/rtd-vm-tool:488`
- `vmtool::configure_ubuntu_version_prompt` — `modules/vm-tool.mod/rtd-vm-tool:494`
- `display_notice` — `modules/vm-tool.mod/rtd-vm-tool:537`
- `show_notice_on_fist_run` — `modules/vm-tool.mod/rtd-vm-tool:560`
- `vmtool::cleanup_after_action` — `modules/vm-tool.mod/rtd-vm-tool:605`
- `vmtool::run_server_template_action` — `modules/vm-tool.mod/rtd-vm-tool:616`
- `vmtool::run_vdi_template_action` — `modules/vm-tool.mod/rtd-vm-tool:686`
- `vmtool::run_settings_action` — `modules/vm-tool.mod/rtd-vm-tool:837`
- `vmtool::run_maintenance_action` — `modules/vm-tool.mod/rtd-vm-tool:858`
- `vmtool::run_main_action` — `modules/vm-tool.mod/rtd-vm-tool:872`
- `manage_server_vm_templates` — `modules/vm-tool.mod/rtd-vm-tool:919`
- `manage_vdi_vm_templates` — `modules/vm-tool.mod/rtd-vm-tool:953`
- `show_settings_menu` — `modules/vm-tool.mod/rtd-vm-tool:1002`
- `show_maintenance_menu` — `modules/vm-tool.mod/rtd-vm-tool:1032`
- `vmtool::gnome_boxes_target_user` — `modules/vm-tool.mod/rtd-vm-tool:1062`
- `vmtool::gnome_boxes_target_home` — `modules/vm-tool.mod/rtd-vm-tool:1072`
- `vmtool::gnome_boxes_integration_enabled` — `modules/vm-tool.mod/rtd-vm-tool:1085`
- `vmtool::toggle_gnome_boxes_integration` — `modules/vm-tool.mod/rtd-vm-tool:1095`
- `vmtool::install_gnome_boxes_integration` — `modules/vm-tool.mod/rtd-vm-tool:1104`
- `vmtool::remove_gnome_boxes_integration` — `modules/vm-tool.mod/rtd-vm-tool:1198`
- `vmtool::run_cleanup_task` — `modules/vm-tool.mod/rtd-vm-tool:1253`
- `vmtool::run_qcow_cleanup` — `modules/vm-tool.mod/rtd-vm-tool:1321`
- `vmtool::run_floppy_cleanup` — `modules/vm-tool.mod/rtd-vm-tool:1332`
- `show_manage_VM_template_menu` — `modules/vm-tool.mod/rtd-vm-tool:1343`
- `vmtool::map_role_to_server_task` — `modules/vm-tool.mod/rtd-vm-tool:1377`
- `vmtool::ensure_ansible_repo` — `modules/vm-tool.mod/rtd-vm-tool:1395`
- `vmtool::build_server_role_menu` — `modules/vm-tool.mod/rtd-vm-tool:1421`
- `vmtool::prompt_cicd_options` — `modules/vm-tool.mod/rtd-vm-tool:1455`
- `vmtool::post_clone_ansible_pull` — `modules/vm-tool.mod/rtd-vm-tool:1525`
- `vmtool::wait_for_vm_stop` — `modules/vm-tool.mod/rtd-vm-tool:1547`
- `vmtool::start_stop_vm_menu` — `modules/vm-tool.mod/rtd-vm-tool:1567`
- `vmtool::show_main_menu` — `modules/vm-tool.mod/rtd-vm-tool:1662`

### `modules/vm-tool.mod/rtd-vm-tool-gtk`

- `vmtoolgtk::gui_tool` — `modules/vm-tool.mod/rtd-vm-tool-gtk:29`
- `vmtoolgtk::find_tui_script` — `modules/vm-tool.mod/rtd-vm-tool-gtk:43`
- `vmtoolgtk::show_error` — `modules/vm-tool.mod/rtd-vm-tool-gtk:62`
- `vmtoolgtk::show_info` — `modules/vm-tool.mod/rtd-vm-tool-gtk:72`
- `vmtoolgtk::log` — `modules/vm-tool.mod/rtd-vm-tool-gtk:82`
- `vmtoolgtk::with_legacy_nounset` — `modules/vm-tool.mod/rtd-vm-tool-gtk:89`
- `vmtoolgtk::prompt_yes_no` — `modules/vm-tool.mod/rtd-vm-tool-gtk:104`
- `vmtoolgtk::entry` — `modules/vm-tool.mod/rtd-vm-tool-gtk:128`
- `vmtoolgtk::show_about` — `modules/vm-tool.mod/rtd-vm-tool-gtk:150`
- `vmtoolgtk::show_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:167`
- `vmtoolgtk::find_terminal_emulator` — `modules/vm-tool.mod/rtd-vm-tool-gtk:227`
- `vmtoolgtk::terminal_candidates` — `modules/vm-tool.mod/rtd-vm-tool-gtk:238`
- `vmtoolgtk::terminal_is_usable` — `modules/vm-tool.mod/rtd-vm-tool-gtk:255`
- `vmtoolgtk::find_terminal_font` — `modules/vm-tool.mod/rtd-vm-tool-gtk:275`
- `vmtoolgtk::parse_args` — `modules/vm-tool.mod/rtd-vm-tool-gtk:301`
- `vmtoolgtk::launch_terminal_payload` — `modules/vm-tool.mod/rtd-vm-tool-gtk:329`
- `vmtoolgtk::launch_tui_action` — `modules/vm-tool.mod/rtd-vm-tool-gtk:407`
- `vmtoolgtk::start_stop_vm_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:441`
- `vmtoolgtk::select_clone_template` — `modules/vm-tool.mod/rtd-vm-tool-gtk:529`
- `vmtoolgtk::prompt_cicd_options` — `modules/vm-tool.mod/rtd-vm-tool-gtk:590`
- `vmtoolgtk::run_clone_with_progress` — `modules/vm-tool.mod/rtd-vm-tool-gtk:696`
- `vmtoolgtk::clone_server_template_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:779`
- `vmtoolgtk::clone_vdi_template_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:792`
- `vmtoolgtk::show_template_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:804`
- `vmtoolgtk::show_server_template_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:821`
- `vmtoolgtk::show_vdi_template_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:849`
- `vmtoolgtk::show_settings_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:891`
- `vmtoolgtk::show_maintenance_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:916`
- `vmtoolgtk::show_main_menu` — `modules/vm-tool.mod/rtd-vm-tool-gtk:944`
- `vmtoolgtk::main` — `modules/vm-tool.mod/rtd-vm-tool-gtk:985`

### `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1`

- `Get-WinUtilCheckBoxes` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:42`
- `is` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:47`
- `Get-WinUtilDarkMode` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:94`
- `Get-WinUtilInstallerProcess` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:110`
- `Install-WinUtilChoco` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:128`
- `is` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:133`
- `Install-WinUtilProgramWinget` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:158`
- `Install-WinUtilWinget` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:186`
- `is` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:191`
- `Invoke-WinUtilScript` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:254`
- `Invoke-WinUtilTweaks` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:280`
- `Remove-WinUtilAPPX` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:337`
- `Set-WinUtilDNS` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:371`
- `Set-WinUtilRegistry` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:403`
- `Set-WinUtilScheduledTask` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:443`
- `Set-WinUtilService` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:483`
- `Test-WinUtilPackageManager` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:526`
- `Update-WinUtilProgramWinget` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:553`
- `Invoke-WPFButton` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:575`
- `Invoke-WPFControlPanel` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:624`
- `Invoke-WPFDarkMode` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:642`
- `Invoke-WPFFeatureInstall` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:675`
- `Invoke-WPFFixesUpdate` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:731`
- `Invoke-WPFFormVariables` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:842`
- `Invoke-WPFImpex` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:879`
- `Invoke-WPFInstall` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:916`
- `Invoke-WPFInstallUpgrade` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:968`
- `Invoke-WPFPanelAutologin` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:995`
- `Invoke-WPFPanelDISM` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1005`
- `Invoke-WPFPresets` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1018`
- `Invoke-WPFRunspace` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1049`
- `Invoke-WPFTab` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1122`
- `Invoke-WPFtweaksbutton` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1146`
- `Invoke-WPFUltimatePerformance` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1186`
- `Invoke-WPFundoall` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1216`
- `Invoke-WPFUpdatesdefault` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1406`
- `Invoke-WPFUpdatesdisable` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1451`
- `Invoke-WPFUpdatessecurity` — `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1:1483`

### `modules/windows.mod/_secure_windows.ps1`

- `Import-GPOs` — `modules/windows.mod/_secure_windows.ps1:161`
- `Set-SecureConfig` — `modules/windows.mod/_secure_windows.ps1:360`

### `rtd-me.sh.cmd`

- `fetch_to_stdout` — `rtd-me.sh.cmd:153`
- `ensure_linux_bootstrap_packages` — `rtd-me.sh.cmd:165`
- `gtk_bootstrap_ready` — `rtd-me.sh.cmd:187`
- `try_bootstrap_gui` — `rtd-me.sh.cmd:193`

## Complete Path Catalog

Format: `path` — kind, lines for text files, bytes. This covers every tracked or unignored repository path except this generated index itself.

### `.gitignore`

- `.gitignore` — metadata, 4 lines, 17 bytes

### `LICENSE`

- `LICENSE` — metadata, 674 lines, 35149 bytes

### `LICENSE.md`

- `LICENSE.md` — documentation, 166 lines, 7652 bytes

### `README.md`

- `README.md` — documentation, 87 lines, 4577 bytes

### `core`

- `core/Media_files/rtd-bootstrap-gui-banner.png` — image, 709083 bytes
- `core/README.md` — documentation, 102 lines, 4880 bytes
- `core/_branding.info` — shell, 373 lines, 18376 bytes
- `core/_locations.info` — shell, 392 lines, 20923 bytes
- `core/_rtd_library` — shell, 36580 lines, 1350628 bytes
- `core/_rtd_recipies.info` — shell, 1436 lines, 70498 bytes
- `core/generate-repository-index.py` — python, 322 lines, 13229 bytes
- `core/image/README/1683618476060.png` — image, 80526 bytes
- `core/image/README/1683618508270.png` — image, 63582 bytes
- `core/image/README/1683622846033.png` — image, 166051 bytes
- `core/image/README/1683623896061.png` — image, 134725 bytes
- `core/image/README/1683625615788.png` — image, 110799 bytes
- `core/image/README/term-lib-help.png` — image, 83984 bytes
- `core/image/terminal.ico` — image, 71 lines, 7872 bytes
- `core/rtd-bootstrap-progress-gtk.py` — python, 358 lines, 13738 bytes
- `core/rtd-oem-enable-config.sh` — shell, 367 lines, 15111 bytes
- `core/rtd-oem-linux-config.sh` — shell, 325 lines, 13728 bytes
- `core/rtd-oem-macos-config.sh` — shell, 597 lines, 21831 bytes
- `core/rtd-oem-windows-setup-splash.ps1` — powershell, 1018 lines, 41628 bytes
- `core/rtd-oem-windows-setup.ps1` — powershell, 2148 lines, 93936 bytes
- `core/rtd-vm-template-finalize-linux.sh` — shell, 263 lines, 10260 bytes
- `core/sigs/AudioBookConverter.sig` — signature, 1 lines, 56 bytes
- `core/sigs/RustDesk.sig` — signature, 1 lines, 46 bytes
- `core/sigs/Teamviewer.sig` — signature, 1 lines, 48 bytes
- `core/sigs/Ventoy.sig` — signature, 1 lines, 44 bytes
- `core/sigs/YUMI-2.0.9.4.exe.sig` — signature, 1 lines, 54 bytes
- `core/sigs/YUMI-UEFI-0.0.4.6.exe.sig` — signature, 1 lines, 59 bytes
- `core/sigs/YUMI-exFAT-1.0.1.5.exe.sig` — signature, 1 lines, 60 bytes
- `core/sigs/unetbootin.sig` — signature, 1 lines, 48 bytes
- `core/sigs/winimage.exe.sig` — signature, 1 lines, 50 bytes

### `docs`

- `docs/GETTING_STARTED.md` — documentation, 90 lines, 3646 bytes
- `docs/TOOLS.md` — documentation, 93 lines, 7922 bytes
- `docs/USE_CASES.md` — documentation, 126 lines, 4791 bytes

### `media_files`

- `media_files/1682710892026.png` — image, 1274684 bytes
- `media_files/20230508_145523_image.png` — image, 365592 bytes
- `media_files/DebianLogo.png` — image, 38128 bytes
- `media_files/LinuxLogo.png` — image, 132977 bytes
- `media_files/README.md` — documentation, 3 lines, 119 bytes
- `media_files/RedHatLogo.png` — image, 41038 bytes
- `media_files/Scr-13-43-45.png` — image, 75276 bytes
- `media_files/Scr11.png` — image, 106127 bytes
- `media_files/ScrLindesk01.png` — image, 222307 bytes
- `media_files/ScrLindesk02.png` — image, 239549 bytes
- `media_files/ScrRTDTerm.png` — image, 64557 bytes
- `media_files/ScrTermOEMSetup.png` — image, 69286 bytes
- `media_files/ScrTnGCombo.png` — image, 107352 bytes
- `media_files/ScrWinWSL.png` — image, 1245301 bytes
- `media_files/SuseLogo.png` — image, 61599 bytes
- `media_files/UbuntuLogo.png` — image, 58989 bytes
- `media_files/WindowsLogo.png` — image, 155935 bytes
- `media_files/header-time.jpg` — image, 132397 bytes
- `media_files/sys.ico` — image, 2104 bytes
- `media_files/sys0.ico` — image, 199251 bytes
- `media_files/sys1.ico` — image, 34731 bytes
- `media_files/sys2.ico` — image, 122960 bytes
- `media_files/sys3.ico` — image, 83096 bytes
- `media_files/sys4.ico` — image, 20070 bytes
- `media_files/sys5.ico` — image, 129854 bytes
- `media_files/sys7.ico` — image, 87729 bytes

### `modules`

- `modules/README.md` — documentation, 38 lines, 2834 bytes
- `modules/Security-tool.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/Security-tool.mod/Media_files/Screenshot.png` — image, 61455 bytes
- `modules/Security-tool.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/Security-tool.mod/README.md` — documentation, 61 lines, 2264 bytes
- `modules/Security-tool.mod/rtd-security-tool` — shell, 253 lines, 8321 bytes
- `modules/gnome-shell-extension-installer.mod/LICENSE` — file, 297 lines, 16054 bytes
- `modules/gnome-shell-extension-installer.mod/README.md` — documentation, 32 lines, 1350 bytes
- `modules/gnome-shell-extension-installer.mod/rtd-gnome-shell-extension-installer` — shell, 650 lines, 22784 bytes
- `modules/light-weight-office-games.mod/Media_files/light-weight-office-games-icon.png` — image, 32447 bytes
- `modules/light-weight-office-games.mod/Media_files/light-weight-office-games-sidebar.png` — image, 282132 bytes
- `modules/light-weight-office-games.mod/Media_files/screenshot-game-selection.png` — image, 153052 bytes
- `modules/light-weight-office-games.mod/Media_files/screenshot-install-scope.png` — image, 168668 bytes
- `modules/light-weight-office-games.mod/Media_files/screenshot-welcome.png` — image, 379886 bytes
- `modules/light-weight-office-games.mod/README.md` — documentation, 75 lines, 4013 bytes
- `modules/light-weight-office-games.mod/rtd-light-weight-office-games` — shell, 816 lines, 28923 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-boot.png` — image, 30502 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-desktop.png` — image, 1615140 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-gui-banner.png` — image, 718598 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-homebrew-app-install.png` — image, 2167341 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-install-progress.png` — image, 581266 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-main-window.png` — image, 402677 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-recovery-utilities.png` — image, 541701 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-sonoma-fetch.png` — image, 199407 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-sonoma-install-progress.png` — image, 303951 bytes
- `modules/macos-kvm.mod/Media_files/macos-kvm-welcome.png` — image, 307474 bytes
- `modules/macos-kvm.mod/Media_files/terminal-rtd-mac-os.png` — image, 154801 bytes
- `modules/macos-kvm.mod/README.md` — documentation, 356 lines, 17412 bytes
- `modules/macos-kvm.mod/THIRD_PARTY.md` — documentation, 36 lines, 1205 bytes
- `modules/macos-kvm.mod/macos-kvm-gtk.py` — python, 504 lines, 20735 bytes
- `modules/macos-kvm.mod/rtd-macos-kvm` — shell, 315 lines, 11393 bytes
- `modules/macos-kvm.mod/rtd-macos-kvm-gui` — shell, 206 lines, 8126 bytes
- `modules/minecraft-server-manager.mod/LICENSE.md` — documentation, 166 lines, 7652 bytes
- `modules/minecraft-server-manager.mod/Media_files/Scr1.png` — image, 273241 bytes
- `modules/minecraft-server-manager.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/minecraft-server-manager.mod/Media_files/header.png` — image, 486099 bytes
- `modules/minecraft-server-manager.mod/Media_files/sys5.ico` — image, 129854 bytes
- `modules/minecraft-server-manager.mod/README.md` — documentation, 29 lines, 1461 bytes
- `modules/minecraft-server-manager.mod/_config.yml` — yml, 1 lines, 29 bytes
- `modules/minecraft-server-manager.mod/rtd-minecraft-server` — shell, 492 lines, 16778 bytes
- `modules/nordvpn-manager.mod/LICENSE.md` — documentation, 662 lines, 34521 bytes
- `modules/nordvpn-manager.mod/Media_files/CMD.png` — image, 87578 bytes
- `modules/nordvpn-manager.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/nordvpn-manager.mod/Media_files/sys3.ico` — image, 83096 bytes
- `modules/nordvpn-manager.mod/README.md` — documentation, 27 lines, 1466 bytes
- `modules/nordvpn-manager.mod/index.md` — documentation, 20 lines, 718 bytes
- `modules/nordvpn-manager.mod/rtd-nordvpn` — shell, 291 lines, 10458 bytes
- `modules/oem-app-runner.mod/README.md` — documentation, 39 lines, 1572 bytes
- `modules/oem-app-runner.mod/apps/RustDesk.7z` — archive, 63667339 bytes
- `modules/oem-app-runner.mod/apps/Teamviewer.7z` — archive, 18932290 bytes
- `modules/oem-app-runner.mod/apps/Ventoy.7z` — archive, 18684055 bytes
- `modules/oem-app-runner.mod/apps/winimage.exe.7z` — archive, 507651 bytes
- `modules/oem-app-runner.mod/image/App-launcher.jpg` — image, 8561 bytes
- `modules/oem-app-runner.mod/image/README/1681677853031.png` — image, 51150 bytes
- `modules/oem-app-runner.mod/image/README/1681678071052.png` — image, 67537 bytes
- `modules/oem-app-runner.mod/rtd-oem-app-runner` — shell, 350 lines, 12477 bytes
- `modules/oem-bundle-manager.mod/README.md` — documentation, 66 lines, 3617 bytes
- `modules/oem-bundle-manager.mod/image/README/1679592243988.png` — image, 22623 bytes
- `modules/oem-bundle-manager.mod/image/README/install.png` — image, 184171 bytes
- `modules/oem-bundle-manager.mod/image/README/main.png` — image, 209322 bytes
- `modules/oem-bundle-manager.mod/image/README/remove.png` — image, 85736 bytes
- `modules/oem-bundle-manager.mod/image/banner.png` — image, 406373 bytes
- `modules/oem-bundle-manager.mod/image/sideimage.png` — image, 161263 bytes
- `modules/oem-bundle-manager.mod/image/software.ico` — image, 94697 bytes
- `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager` — shell, 679 lines, 23441 bytes
- `modules/oem-bundle-manager.mod/rtd-oem-bundle-manager-legacy` — shell, 546 lines, 18640 bytes
- `modules/oem-system-admin.mod/LICENSE.md` — documentation, 166 lines, 7652 bytes
- `modules/oem-system-admin.mod/README.md` — documentation, 45 lines, 2718 bytes
- `modules/oem-system-admin.mod/rtd-7z-all-files-here` — shell, 170 lines, 7139 bytes
- `modules/oem-system-admin.mod/rtd-7z-encrypt-all-files-here` — shell, 171 lines, 7186 bytes
- `modules/oem-system-admin.mod/rtd-7z-encrypt-this` — shell, 173 lines, 7222 bytes
- `modules/oem-system-admin.mod/rtd-7z-this` — shell, 192 lines, 7142 bytes
- `modules/oem-system-admin.mod/rtd-add-ubuntu-to-landscape-onprem` — shell, 192 lines, 8432 bytes
- `modules/oem-system-admin.mod/rtd-burniso` — shell, 175 lines, 6837 bytes
- `modules/oem-system-admin.mod/rtd-clear-zombie` — shell, 162 lines, 6454 bytes
- `modules/oem-system-admin.mod/rtd-clear_iptables` — shell, 165 lines, 6449 bytes
- `modules/oem-system-admin.mod/rtd-configure-huion` — shell, 163 lines, 6229 bytes
- `modules/oem-system-admin.mod/rtd-deb-cleanup` — shell, 249 lines, 8890 bytes
- `modules/oem-system-admin.mod/rtd-dropbox-on-ecryptfs` — shell, 164 lines, 6424 bytes
- `modules/oem-system-admin.mod/rtd-get-Windows-product-key` — shell, 142 lines, 5639 bytes
- `modules/oem-system-admin.mod/rtd-internet-location` — shell, 161 lines, 6576 bytes
- `modules/oem-system-admin.mod/rtd-join-avi` — shell, 175 lines, 6763 bytes
- `modules/oem-system-admin.mod/rtd-make-bootable-cd` — shell, 332 lines, 12223 bytes
- `modules/oem-system-admin.mod/rtd-make-bootable-usb-drive` — shell, 149 lines, 6251 bytes
- `modules/oem-system-admin.mod/rtd-make-swap` — shell, 151 lines, 6248 bytes
- `modules/oem-system-admin.mod/rtd-malware-scan` — shell, 157 lines, 6195 bytes
- `modules/oem-system-admin.mod/rtd-malware-scan-HOME` — shell, 392 lines, 11778 bytes
- `modules/oem-system-admin.mod/rtd-mv` — shell, 256 lines, 9297 bytes
- `modules/oem-system-admin.mod/rtd-netuse` — shell, 622 lines, 19130 bytes
- `modules/oem-system-admin.mod/rtd-oem-old-kernel-remover` — shell, 177 lines, 7066 bytes
- `modules/oem-system-admin.mod/rtd-on-notify-wait` — shell, 174 lines, 7542 bytes
- `modules/oem-system-admin.mod/rtd-organize-everything` — shell, 155 lines, 6340 bytes
- `modules/oem-system-admin.mod/rtd-ppa-checker` — shell, 151 lines, 6085 bytes
- `modules/oem-system-admin.mod/rtd-restart-sound` — shell, 148 lines, 6149 bytes
- `modules/oem-system-admin.mod/rtd-script-menu` — shell, 78 lines, 3660 bytes
- `modules/oem-system-admin.mod/rtd-ssh-connection-list-local` — shell, 249 lines, 9273 bytes
- `modules/oem-system-admin.mod/rtd-tracker-force-update` — shell, 58 lines, 2484 bytes
- `modules/oem-system-admin.mod/rtd-unrar-all` — shell, 159 lines, 6264 bytes
- `modules/oem-system-admin.mod/rtd-xterm-sysconsole` — shell, 159 lines, 6731 bytes
- `modules/oem-system-update.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/oem-system-update.mod/Media_files/Screenshot0.png` — image, 34722 bytes
- `modules/oem-system-update.mod/Media_files/Screenshot1.png` — image, 140870 bytes
- `modules/oem-system-update.mod/Media_files/Screenshot2.png` — image, 80243 bytes
- `modules/oem-system-update.mod/README.md` — documentation, 49 lines, 2283 bytes
- `modules/oem-system-update.mod/rtd-self-update` — shell, 530 lines, 18898 bytes
- `modules/oem-system-update.mod/rtd-update-system` — shell, 581 lines, 19698 bytes
- `modules/oem-ventoy.mod/Media_files/ScrRTDVtGui.png` — image, 86550 bytes
- `modules/oem-ventoy.mod/Media_files/Screenshot-Ventoy-boot-commercial.png` — image, 94671 bytes
- `modules/oem-ventoy.mod/Media_files/Screenshot-Ventoy-boot-oem.png` — image, 102002 bytes
- `modules/oem-ventoy.mod/Media_files/Screenshot-Ventoy-boot-oss.png` — image, 99409 bytes
- `modules/oem-ventoy.mod/Media_files/Screenshot-Ventoy-boot-tools.png` — image, 95197 bytes
- `modules/oem-ventoy.mod/Media_files/Screenshot-Ventoy-boot.png` — image, 91725 bytes
- `modules/oem-ventoy.mod/Media_files/rtd-ventoy-background-1024x768.png` — image, 82532 bytes
- `modules/oem-ventoy.mod/README.md` — documentation, 84 lines, 3704 bytes
- `modules/oem-ventoy.mod/USAGE.md` — documentation, 120 lines, 4848 bytes
- `modules/oem-ventoy.mod/rtd-ventoy-usb` — shell, 675 lines, 22130 bytes
- `modules/oem-ventoy.mod/ventoy-usb-gtk.py` — python, 588 lines, 24364 bytes
- `modules/rtd-ai-chat.mod/README.md` — documentation, 54 lines, 1986 bytes
- `modules/rtd-ai-chat.mod/chatgpt.sh` — shell, 484 lines, 16995 bytes
- `modules/rtd-ai-chat.mod/rtd-ai-chat` — shell, 394 lines, 14031 bytes
- `modules/rtd-check-sec.mod/README.md` — documentation, 45 lines, 1267 bytes
- `modules/rtd-check-sec.mod/rtd-check-sec` — shell, 900 lines, 32353 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/SCREENSHOTS.md` — documentation, 19 lines, 699 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrMacDk.jpg` — image, 195446 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrMacLi.jpg` — image, 203757 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrMocca.jpg` — image, 163192 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrProDk.jpg` — image, 446434 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrProLi.jpg` — image, 261758 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrReset.jpg` — image, 170473 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrWinDk.jpg` — image, 171059 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/ScrWinLi.jpg` — image, 175148 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/rtd-desktop-look-switcher.mod/Media_files/sys7.ico` — image, 87729 bytes
- `modules/rtd-desktop-look-switcher.mod/README.md` — documentation, 49 lines, 2482 bytes
- `modules/rtd-desktop-look-switcher.mod/rtd-desktop-look-switcher` — shell, 54 lines, 1439 bytes
- `modules/rtd-oem-tweaks.mod/Media_files/Screenshot.png` — image, 1039540 bytes
- `modules/rtd-oem-tweaks.mod/Media_files/rtd-oem-tweaks-banner.svg` — image, 55 lines, 3493 bytes
- `modules/rtd-oem-tweaks.mod/README.md` — documentation, 77 lines, 3118 bytes
- `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks` — shell, 1745 lines, 57522 bytes
- `modules/rtd-oem-tweaks.mod/rtd-oem-tweaks-gtk.py` — python, 648 lines, 23720 bytes
- `modules/rtd-vpn-router.mod/LICENSE.md` — documentation, 675 lines, 35142 bytes
- `modules/rtd-vpn-router.mod/Media_files/Scr1.png` — image, 271556 bytes
- `modules/rtd-vpn-router.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/rtd-vpn-router.mod/README.md` — documentation, 69 lines, 4045 bytes
- `modules/rtd-vpn-router.mod/rtd-start-vpn-router` — shell, 868 lines, 28136 bytes
- `modules/setup-whonix.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/setup-whonix.mod/Media_files/Screenshot.png` — image, 163443 bytes
- `modules/setup-whonix.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/setup-whonix.mod/README.md` — documentation, 83 lines, 4057 bytes
- `modules/setup-whonix.mod/rtd-setup-whonix.sh` — shell, 229 lines, 8928 bytes
- `modules/simple-support-tool.mod/LICENSE.md` — documentation, 166 lines, 7652 bytes
- `modules/simple-support-tool.mod/Media_files/0-amalgam.png` — image, 199126 bytes
- `modules/simple-support-tool.mod/Media_files/0-startup.png` — image, 45570 bytes
- `modules/simple-support-tool.mod/Media_files/1-main_menu.png` — image, 48860 bytes
- `modules/simple-support-tool.mod/Media_files/10.png` — image, 11517 bytes
- `modules/simple-support-tool.mod/Media_files/11.png` — image, 62934 bytes
- `modules/simple-support-tool.mod/Media_files/2-notice.png` — image, 62344 bytes
- `modules/simple-support-tool.mod/Media_files/3-info.png` — image, 61683 bytes
- `modules/simple-support-tool.mod/Media_files/4-softw.png` — image, 47366 bytes
- `modules/simple-support-tool.mod/Media_files/5-vm.png` — image, 42647 bytes
- `modules/simple-support-tool.mod/Media_files/5-vm2.png` — image, 38184 bytes
- `modules/simple-support-tool.mod/Media_files/5-vm3.png` — image, 46084 bytes
- `modules/simple-support-tool.mod/Media_files/5-vm4.png` — image, 60047 bytes
- `modules/simple-support-tool.mod/Media_files/6-pass.png` — image, 39516 bytes
- `modules/simple-support-tool.mod/Media_files/7-pass.png` — image, 29476 bytes
- `modules/simple-support-tool.mod/Media_files/8-pass.png` — image, 39804 bytes
- `modules/simple-support-tool.mod/Media_files/9-iso.png` — image, 60747 bytes
- `modules/simple-support-tool.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/simple-support-tool.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/simple-support-tool.mod/Media_files/sys2.ico` — image, 122960 bytes
- `modules/simple-support-tool.mod/README.md` — documentation, 62 lines, 2234 bytes
- `modules/simple-support-tool.mod/rtd-simple-support-tool` — shell, 1011 lines, 34290 bytes
- `modules/steam-world-of-tanks-utility.mod/LICENSE.md` — documentation, 166 lines, 7652 bytes
- `modules/steam-world-of-tanks-utility.mod/README.md` — documentation, 66 lines, 2709 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/Screenshot.png` — image, 316720 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/Screenshot2.png` — image, 321092 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/Screenshot3.png` — image, 276154 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/Screenshot4.png` — image, 257192 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/swot-header-sm.png` — image, 228557 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/swot-header-sm2.png` — image, 228557 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/swot-header.png` — image, 494572 bytes
- `modules/steam-world-of-tanks-utility.mod/media_files/swot-sideimg.png` — image, 204721 bytes
- `modules/steam-world-of-tanks-utility.mod/rtd-steam-world-of-tanks-utility` — shell, 653 lines, 20978 bytes
- `modules/steam-world-of-warships-utility.mod/LICENSE.md` — documentation, 166 lines, 7652 bytes
- `modules/steam-world-of-warships-utility.mod/README.md` — documentation, 37 lines, 1825 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/Screenshot2.png` — image, 243263 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/Screenshot3.png` — image, 158924 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/Screenshot4.png` — image, 154280 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/screenshot.png` — image, 269444 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/swow-header-sm.png` — image, 225690 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/swow-header.png` — image, 473891 bytes
- `modules/steam-world-of-warships-utility.mod/media_files/swow-sideimg.png` — image, 111893 bytes
- `modules/steam-world-of-warships-utility.mod/rtd-steam-world-of-warships-utility` — shell, 576 lines, 18272 bytes
- `modules/system-hardware-information.mod/README.md` — documentation, 26 lines, 1282 bytes
- `modules/system-hardware-information.mod/image/README/1680304786891.png` — image, 72880 bytes
- `modules/system-hardware-information.mod/image/README/1680304828450.png` — image, 84156 bytes
- `modules/system-hardware-information.mod/image/system-information-icon-3.png` — image, 48870 bytes
- `modules/system-hardware-information.mod/rtd-system-hardware-information` — shell, 277 lines, 10450 bytes
- `modules/system-user-backup.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/system-user-backup.mod/Media_files/Screenshot-main.png` — image, 102056 bytes
- `modules/system-user-backup.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/system-user-backup.mod/Media_files/sys0.ico` — image, 199251 bytes
- `modules/system-user-backup.mod/README.md` — documentation, 168 lines, 5143 bytes
- `modules/system-user-backup.mod/rtd-oem-backup-linux-config` — shell, 588 lines, 21872 bytes
- `modules/system-user-backup.mod/user-backup-gtk.py` — python, 444 lines, 18356 bytes
- `modules/theme-manager/Media_files/main-window.png` — image, 474001 bytes
- `modules/theme-manager/Media_files/profile-crisp-day.jpg` — image, 261758 bytes
- `modules/theme-manager/Media_files/profile-crisp-evening.jpg` — image, 446434 bytes
- `modules/theme-manager/Media_files/profile-distro-reset.jpg` — image, 170473 bytes
- `modules/theme-manager/Media_files/profile-mac-bright.jpg` — image, 203757 bytes
- `modules/theme-manager/Media_files/profile-mac-dusk.jpg` — image, 195446 bytes
- `modules/theme-manager/Media_files/profile-moca-smooth.jpg` — image, 163192 bytes
- `modules/theme-manager/Media_files/profile-win10-dark.jpg` — image, 171059 bytes
- `modules/theme-manager/Media_files/profile-win10-light.jpg` — image, 175148 bytes
- `modules/theme-manager/Media_files/theme-manager-banner.png` — image, 1017812 bytes
- `modules/theme-manager/README.md` — documentation, 108 lines, 4481 bytes
- `modules/theme-manager/rtd-theme-manager` — shell, 598 lines, 21461 bytes
- `modules/theme-manager/theme-manager-gtk.py` — python, 543 lines, 22693 bytes
- `modules/vm-tool.mod/Media_files/README.md` — documentation, 3 lines, 119 bytes
- `modules/vm-tool.mod/Media_files/Screenshot From 2026-05-22 23-02-54.png` — image, 44563 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_Fedora_VDI.png` — image, 1794178 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_Fedora_VDI_KDE.png` — image, 1395051 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_Ubuntu_VDI.png` — image, 1007668 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_Windows11_VDI.png` — image, 905506 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_rtd-vm-tool-gtk.png` — image, 65647 bytes
- `modules/vm-tool.mod/Media_files/Screenshot_rtd-vm-tool.png` — image, 52288 bytes
- `modules/vm-tool.mod/Media_files/header-time.jpg` — image, 132397 bytes
- `modules/vm-tool.mod/README.md` — documentation, 85 lines, 3465 bytes
- `modules/vm-tool.mod/rtd-vm-tool` — shell, 1720 lines, 58701 bytes
- `modules/vm-tool.mod/rtd-vm-tool-gtk` — shell, 1060 lines, 34183 bytes
- `modules/windows.mod/Media_files/Screenshot-Initial-install.png` — image, 106127 bytes
- `modules/windows.mod/Media_files/Screenshot-tweaks.png` — image, 225307 bytes
- `modules/windows.mod/README.md` — documentation, 80 lines, 3766 bytes
- `modules/windows.mod/_Chris-Titus-Post-Windows-Install-App.ps1` — powershell, 3934 lines, 158719 bytes
- `modules/windows.mod/_KMS.zip` — archive, 49411 bytes
- `modules/windows.mod/_secure_windows.ps1` — powershell, 3046 lines, 249472 bytes

### `rtd-me.sh.cmd`

- `rtd-me.sh.cmd` — shell, 532 lines, 23918 bytes

### `wallpaper`

- `wallpaper/Wayland-dark.jpg` — image, 919436 bytes
- `wallpaper/Wayland.jpg` — image, 1124200 bytes
