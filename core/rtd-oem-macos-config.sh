#!/bin/bash
#
#::             	macOS software addon and configuration script
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::// OEM macOS Configuration Script //:::::::::::::::::::::// macOS //::::
#::
#:: Author(s):   	Vonschutter + 
#:: Version:      	1.00
#::
#:: Purpose: 	The purpose of the script is to:
#::		 - Configure a fresh macOS VM, VDI, or workstation for RTD use.
#::		 - Install a useful starter application bundle using Homebrew Cask.
#::		 - Reduce analytics, personalized ads, suggestions, animations, and background noise.
#::		 - Apply practical Finder, Dock, screenshot, and firewall defaults.
#::		 - Install the RTD light/dark wallpapers and set the active desktop picture.
#::		 - Clean safe user caches without touching protected system files.
#::
#::		NOTE: macOS protects most system apps and operating system components with SIP and the sealed
#::		      system volume. This script does not disable SIP, Gatekeeper, XProtect, MRT, FileVault,
#::		      software updates, or other security-critical platform services.
#::
#:: Usage: 	bash rtd-oem-macos-config.sh
#::		bash rtd-oem-macos-config.sh --preset minimal
#::		bash rtd-oem-macos-config.sh --preset workstation
#::		bash rtd-oem-macos-config.sh --dry-run
#::
#:: Presets:	minimal      Privacy, UI defaults, firewall, and cleanup. No application installs.
#::		workstation  Default. Minimal plus Firefox, Brave, VLC, Keka, LibreOffice, VS Code,
#::		             Rectangle, and The Unarchiver.
#::		apps         Install the application bundle only.
#::
#:: Background: This script is shared in the hopes that someone will find it useful. To encourage sharing changes
#:: 		 back to the source this script is released under the GPL v3. (see source location for details)
#::		 https://github.com/vonschutter/RTD-Setup/raw/master/LICENSE.md
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	NOTE:	This terminal program is written and documented to a high degree. The reason for doing this is that
#		these apps are seldom changed and when they are, it is useful to be able to understand why and how
#		things were built. As a general rule, we prefer using functions extensively because this makes it easier
#		to manage the script and facilitates several users working on the same scripts over time.
#
#	Taxonomy of this script: we prioritize the use of functions over monolithic script writing, and proper indentation
#	to make the script more readable. Each function shall also be documented to the point of the obvious.
#

set -u

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

RTD_MACOS_CONFIG_VERSION="1.00"
SCRIPT_NAME="$(basename "$0")"
PRESET="workstation"
DRY_RUN=0
INSTALL_APPS=1
APPLY_PRIVACY=1
APPLY_UI=1
APPLY_FIREWALL=1
APPLY_WALLPAPER=1
RUN_CLEANUP=1
RESTART_UI=1
LOG_DIR="${HOME}/Library/Logs/RTD"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
TARGET_USER="${RTD_MACOS_TARGET_USER:-}"
TARGET_HOME="${RTD_MACOS_TARGET_HOME:-}"

MINIMAL_CASKS="firefox brave-browser vlc keka"
WORKSTATION_CASKS="firefox brave-browser vlc keka libreoffice onlyoffice visual-studio-code gitkraken rectangle the-unarchiver joplin krita gimp rustdesk"

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Helper Functions                ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

usage() {
	cat <<EOF
Usage:
  ${SCRIPT_NAME} [options]

Options:
  --preset minimal|workstation|apps  Select the configuration bundle. Default: workstation.
  --no-apps                          Skip Homebrew and application installation.
  --no-privacy                       Skip privacy and suggestions settings.
  --no-ui                            Skip Finder, Dock, screenshot, and animation defaults.
  --no-firewall                      Skip firewall configuration.
  --no-wallpaper                     Skip RTD wallpaper installation and desktop picture setup.
  --no-cleanup                       Skip safe user cache cleanup.
  --no-restart-ui                    Do not restart Finder, Dock, or SystemUIServer.
  --dry-run                          Print actions without changing the system.
  --help, -h                         Show this help text.

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --preset minimal
  ${SCRIPT_NAME} --preset apps --dry-run
EOF
}

write_log() {
	# Keep a timestamped record because macOS setup runs often happen inside VMs
	# where terminal scrollback may be lost after a reboot or reseal.
	local level="$1"
	local message="$2"
	local line
	line="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
	printf '%s\n' "$line"
	mkdir -p "$LOG_DIR" 2>/dev/null || true
	if [ -n "${LOG_FILE:-}" ] && { : >>"$LOG_FILE"; } 2>/dev/null; then
		{ printf '%s\n' "$line" >>"$LOG_FILE"; } 2>/dev/null || true
	fi
}

write_status() { write_log "INFO" "$*"; }
write_ok() { write_log "OK" "$*"; }
write_warning() { write_log "WARN" "$*"; }
write_error() { write_log "ERROR" "$*"; }

run_cmd() {
	# Commands go through this wrapper so --dry-run is reliable and so the log
	# shows exactly what would have been executed.
	write_status "RUN: $*"
	if [ "$DRY_RUN" -eq 1 ]; then
		return 0
	fi
	"$@"
}

run_shell() {
	# Use a shell wrapper only where macOS commands require redirects, pipelines,
	# or compound commands. Normal commands should use run_cmd.
	write_status "RUN: $*"
	if [ "$DRY_RUN" -eq 1 ]; then
		return 0
	fi
	/bin/bash -c "$*"
}

run_user_cmd() {
	# Homebrew and per-user macOS defaults must run as the console user. Running
	# them as root either fails outright or writes preferences into the wrong home.
	write_status "RUN as ${TARGET_USER}: $*"
	if [ "$DRY_RUN" -eq 1 ]; then
		return 0
	fi
	if [ "$(id -u)" -eq 0 ]; then
		sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" "$@"
	else
		HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" "$@"
	fi
}

run_user_shell() {
	write_status "RUN as ${TARGET_USER}: $*"
	if [ "$DRY_RUN" -eq 1 ]; then
		return 0
	fi
	if [ "$(id -u)" -eq 0 ]; then
		sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" /bin/bash -c "$*"
	else
		HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" /bin/bash -c "$*"
	fi
}

run_privileged_cmd() {
	write_status "RUN privileged: $*"
	if [ "$DRY_RUN" -eq 1 ]; then
		return 0
	fi
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

require_macos() {
	# This script uses macOS-specific tools such as defaults, scutil, and
	# socketfilterfw. Refuse to run elsewhere to avoid accidental Linux changes.
	if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
		write_error "This script must be run on macOS."
		exit 1
	fi
}

detect_target_user() {
	if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
		TARGET_USER="${SUDO_USER:-}"
	fi
	if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
		TARGET_USER="$(stat -f '%Su' /dev/console 2>/dev/null || true)"
	fi
	if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
		TARGET_USER="$(id -un)"
	fi
	if [ "$TARGET_USER" = "root" ]; then
		write_error "Could not determine a non-root macOS user for Homebrew and user defaults."
		exit 1
	fi

	if [ -z "$TARGET_HOME" ]; then
		TARGET_HOME="$(dscl . -read "/Users/${TARGET_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
	fi
	if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
		TARGET_HOME="/Users/${TARGET_USER}"
	fi

	LOG_DIR="${TARGET_HOME}/Library/Logs/RTD"
	LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
}

parse_args() {
	while [ $# -gt 0 ]; do
		case "$1" in
			--preset)
				[ $# -ge 2 ] || { write_error "--preset requires a value."; exit 1; }
				PRESET="$2"
				shift 2
				;;
			--no-apps)
				INSTALL_APPS=0
				shift
				;;
			--no-privacy)
				APPLY_PRIVACY=0
				shift
				;;
			--no-ui)
				APPLY_UI=0
				shift
				;;
			--no-firewall)
				APPLY_FIREWALL=0
				shift
				;;
			--no-wallpaper)
				APPLY_WALLPAPER=0
				shift
				;;
			--no-cleanup)
				RUN_CLEANUP=0
				shift
				;;
			--no-restart-ui)
				RESTART_UI=0
				shift
				;;
			--dry-run)
				DRY_RUN=1
				shift
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				write_error "Unknown option: $1"
				usage
				exit 1
				;;
		esac
	done

	case "$PRESET" in
		minimal)
			INSTALL_APPS=0
			;;
		workstation)
			:
			;;
		apps)
			INSTALL_APPS=1
			APPLY_PRIVACY=0
			APPLY_UI=0
			APPLY_FIREWALL=0
			APPLY_WALLPAPER=0
			RUN_CLEANUP=0
			RESTART_UI=0
			;;
		*)
			write_error "Unsupported preset: ${PRESET}. Use minimal, workstation, or apps."
			exit 1
			;;
	esac
}

initialize_log() {
	mkdir -p "$LOG_DIR" 2>/dev/null || true
	if ! { : >>"$LOG_FILE"; } 2>/dev/null; then
		LOG_DIR="${TMPDIR:-/tmp}/RTD"
		LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
		mkdir -p "$LOG_DIR" 2>/dev/null || true
	fi
	write_status "RTD macOS OEM configuration ${RTD_MACOS_CONFIG_VERSION} started."
	write_status "Preset: ${PRESET}; dry-run: ${DRY_RUN}"
	write_status "Target user: ${TARGET_USER}; home: ${TARGET_HOME}"
}

ensure_command_line_tools() {
	# Homebrew and many casks expect Apple's command line tools. macOS may show a
	# GUI installer prompt here; that is intentional because Apple controls this flow.
	if xcode-select -p >/dev/null 2>&1; then
		write_ok "Apple Command Line Tools are available."
		return 0
	fi

	write_warning "Apple Command Line Tools are missing. Requesting installation."
	run_user_cmd xcode-select --install || true
	write_warning "If a Command Line Tools installer opened, complete it and rerun this script."
	return 1
}

homebrew_bin() {
	# Homebrew installs to different prefixes on Apple Silicon and Intel Macs.
	if [ -x /opt/homebrew/bin/brew ]; then
		printf '%s\n' /opt/homebrew/bin/brew
	elif [ -x /usr/local/bin/brew ]; then
		printf '%s\n' /usr/local/bin/brew
	else
		return 1
	fi
}

ensure_homebrew() {
	# Homebrew is the safest normal-user mechanism for installing desktop apps on
	# macOS without bypassing platform protections or hand-maintaining DMG URLs.
	local brew
	if brew="$(homebrew_bin)"; then
		write_ok "Homebrew is available."
		return 0
	fi

	write_warning "Homebrew is not installed. Installing Homebrew for ${TARGET_USER}."
	if [ "$DRY_RUN" -eq 1 ]; then
		write_status "DRY-RUN: would install Homebrew from https://brew.sh/"
		return 0
	fi

	run_user_shell 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' || {
		write_error "Homebrew installation failed."
		return 1
	}
	homebrew_bin >/dev/null || {
		write_error "Homebrew installed, but brew is still not available in PATH."
		return 1
	}
}

install_homebrew_apps() {
	# Casks are intentionally mainstream, cross-architecture applications useful
	# on a fresh workstation/VDI. This avoids force-removing Apple apps and instead
	# adds better default tools for browsers, media, archives, office, and editing.
	local casks="$WORKSTATION_CASKS"
	local app brew
	local clt_ready=1
	if [ "$PRESET" = "minimal" ]; then
		casks="$MINIMAL_CASKS"
	fi

	ensure_homebrew || return 1
	brew="$(homebrew_bin)" || return 1
	if ! ensure_command_line_tools; then
		clt_ready=0
		write_warning "Continuing with Homebrew cask installation; if macOS is still installing Command Line Tools, rerun this script after that finishes."
	fi

	run_user_cmd "$brew" update || write_warning "Homebrew update failed; continuing with available metadata."

	for app in $casks; do
		if run_user_cmd "$brew" list --cask "$app" >/dev/null 2>&1; then
			write_ok "Application already installed: ${app}"
			continue
		fi
		run_user_cmd "$brew" install --cask "$app" || write_warning "Failed to install cask: ${app}"
	done
	if [ "$clt_ready" -eq 0 ]; then
		write_warning "Application installation may be incomplete because Apple Command Line Tools were not ready at the start of this run."
	fi
}

apply_privacy_defaults() {
	# These settings reduce Apple's analytics and ad personalization. They do not
	# disable security services such as Gatekeeper, XProtect, MRT, or updates.
	write_status "Applying macOS privacy and suggestion defaults."

	run_user_cmd defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
	run_user_cmd defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
	run_user_cmd defaults write com.apple.assistant.support "Assistant Enabled" -bool false
	run_user_cmd defaults write com.apple.Siri StatusMenuVisible -bool false
	run_user_cmd defaults write com.apple.Siri UserHasDeclinedEnable -bool true
	run_user_cmd defaults write com.apple.spotlight SuggestionsEnabled -bool false
	run_user_cmd defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

	# System-wide diagnostic submission settings need sudo. Failures are warnings
	# because some MDM-managed or newer macOS builds may reject local writes.
	run_privileged_cmd defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory AutoSubmit -bool false || true
	run_privileged_cmd defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory ThirdPartyDataSubmit -bool false || true
	run_privileged_cmd defaults write /Library/Preferences/com.apple.SubmitDiagInfo AutoSubmit -bool false || true
}

apply_ui_defaults() {
	# These are support-oriented UI defaults: make files inspectable, reduce
	# animation overhead, keep screenshots organized, and remove noisy Dock items.
	local screenshot_dir="${TARGET_HOME}/Pictures/Screenshots"
	write_status "Applying Finder, Dock, screenshot, and animation defaults."

	run_user_cmd mkdir -p "$screenshot_dir"

	run_user_cmd defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	run_user_cmd defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
	run_user_cmd defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
	run_user_cmd defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	run_user_cmd defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

	run_user_cmd defaults write com.apple.finder AppleShowAllFiles -bool true
	run_user_cmd defaults write com.apple.finder FXDefaultSearchScope -string SCcf
	run_user_cmd defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	run_user_cmd defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
	run_user_cmd defaults write com.apple.finder ShowPathbar -bool true
	run_user_cmd defaults write com.apple.finder ShowStatusBar -bool true
	run_user_cmd defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

	run_user_cmd defaults write com.apple.dock autohide -bool false
	run_user_cmd defaults write com.apple.dock expose-animation-duration -float 0.1
	run_user_cmd defaults write com.apple.dock launchanim -bool false
	run_user_cmd defaults write com.apple.dock mru-spaces -bool false
	run_user_cmd defaults write com.apple.dock show-recents -bool false
	run_user_cmd defaults write com.apple.dock tilesize -int 48

	run_user_cmd defaults write com.apple.screencapture disable-shadow -bool true
	run_user_cmd defaults write com.apple.screencapture location -string "$screenshot_dir"
	run_user_cmd defaults write com.apple.screencapture type -string png

	run_user_cmd defaults write com.apple.universalaccess reduceMotion -bool true
	run_user_cmd defaults write com.apple.universalaccess reduceTransparency -bool true
}

apply_firewall_defaults() {
	# Keep macOS security controls enabled. Stealth mode is useful for VMs and
	# laptops because it reduces unsolicited network response noise.
	local firewall="/usr/libexec/ApplicationFirewall/socketfilterfw"
	write_status "Applying macOS firewall defaults."

	if [ ! -x "$firewall" ]; then
		write_warning "socketfilterfw not found; skipping firewall settings."
		return 0
	fi

	run_privileged_cmd "$firewall" --setglobalstate on || true
	run_privileged_cmd "$firewall" --setstealthmode on || true
	run_privileged_cmd "$firewall" --setallowsigned on || true
	run_privileged_cmd "$firewall" --setallowsignedapp on || true
}

find_rtd_wallpaper_dir() {
	local script_path script_dir fallback_dir raw_base
	script_path="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")"
	script_dir="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd)"
	for candidate in \
		"${RTD_MACOS_WALLPAPER_SOURCE:-}" \
		"${script_dir}/../wallpaper" \
		"${script_dir}/../../wallpaper" \
		"/opt/rtd/wallpaper" \
		"/usr/local/rtd/wallpaper"; do
		if [ -n "$candidate" ] && [ -r "${candidate}/Wayland.jpg" ] && [ -r "${candidate}/Wayland-dark.jpg" ]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done

	raw_base="${RTD_MACOS_SETUP_RAW_URL:-https://raw.githubusercontent.com/vonschutter/RTD-Setup/main}"
	fallback_dir="${TMPDIR:-/tmp}/rtd-macos-wallpaper"
	mkdir -p "$fallback_dir" 2>/dev/null || return 1
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "${raw_base}/wallpaper/Wayland.jpg" -o "${fallback_dir}/Wayland.jpg" || return 1
		curl -fsSL "${raw_base}/wallpaper/Wayland-dark.jpg" -o "${fallback_dir}/Wayland-dark.jpg" || return 1
	elif command -v wget >/dev/null 2>&1; then
		wget -qO "${fallback_dir}/Wayland.jpg" "${raw_base}/wallpaper/Wayland.jpg" || return 1
		wget -qO "${fallback_dir}/Wayland-dark.jpg" "${raw_base}/wallpaper/Wayland-dark.jpg" || return 1
	else
		return 1
	fi
	printf '%s\n' "$fallback_dir"
	return 0
}

apply_rtd_wallpapers() {
	local source_dir target_dir light_wallpaper dark_wallpaper active_wallpaper active_style
	write_status "Installing RTD wallpapers and setting the desktop picture."

	if ! source_dir="$(find_rtd_wallpaper_dir)"; then
		write_warning "RTD wallpapers were not found. Expected Wayland.jpg and Wayland-dark.jpg near the RTD setup files or in /opt/rtd/wallpaper."
		return 0
	fi

	target_dir="${TARGET_HOME}/Pictures/RTD-Wallpapers"
	light_wallpaper="${target_dir}/Wayland.jpg"
	dark_wallpaper="${target_dir}/Wayland-dark.jpg"

	run_user_cmd mkdir -p "$target_dir"
	run_user_cmd cp -f "${source_dir}/Wayland.jpg" "$light_wallpaper"
	run_user_cmd cp -f "${source_dir}/Wayland-dark.jpg" "$dark_wallpaper"

	active_wallpaper="$light_wallpaper"
	if [ "$DRY_RUN" -ne 1 ]; then
		if [ "$(id -u)" -eq 0 ]; then
			active_style="$(sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true)"
		else
			active_style="$(HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true)"
		fi
		if [ "$active_style" = "Dark" ]; then
			active_wallpaper="$dark_wallpaper"
		fi
	fi

	run_user_shell "osascript -e 'tell application \"System Events\" to tell every desktop to set picture to POSIX file \"${active_wallpaper}\"'" || {
		write_warning "Unable to set the macOS desktop picture automatically."
		return 0
	}
	write_ok "RTD desktop picture set to ${active_wallpaper}."
}

cleanup_user_caches() {
	# This intentionally cleans only disposable user-owned cache/log locations.
	# It avoids /System, /Library, and protected app payloads.
	write_status "Cleaning safe user cache and log files."

	run_user_shell "rm -rf \"${TARGET_HOME}/Library/Caches\"/* 2>/dev/null || true"
	run_user_shell "rm -rf \"${TARGET_HOME}/Library/Logs\"/*.log 2>/dev/null || true"
	run_user_shell "rm -rf \"${TARGET_HOME}/Library/Saved Application State\"/* 2>/dev/null || true"
}

restart_user_interface() {
	# Finder, Dock, and SystemUIServer cache many defaults. Restarting them makes
	# most UI changes visible without rebooting the whole machine.
	if [ "$RESTART_UI" -ne 1 ]; then
		return 0
	fi

	write_status "Restarting Finder, Dock, and SystemUIServer to apply UI defaults."
	run_user_cmd killall Finder || true
	run_user_cmd killall Dock || true
	run_user_cmd killall SystemUIServer || true
}

complete_setup() {
	write_ok "RTD macOS OEM configuration complete."
	write_status "Log file: ${LOG_FILE}"
	if [ "$APPLY_PRIVACY" -eq 1 ] || [ "$APPLY_UI" -eq 1 ] || [ "$APPLY_FIREWALL" -eq 1 ]; then
		write_warning "A restart is recommended before final testing or resealing the image."
	fi
}

main() {
	parse_args "$@"
	require_macos
	detect_target_user
	initialize_log

	if [ "$INSTALL_APPS" -eq 1 ]; then
		install_homebrew_apps
	fi

	if [ "$APPLY_PRIVACY" -eq 1 ]; then
		apply_privacy_defaults
	fi

	if [ "$APPLY_UI" -eq 1 ]; then
		apply_ui_defaults
	fi

	if [ "$APPLY_FIREWALL" -eq 1 ]; then
		apply_firewall_defaults
	fi

	if [ "$APPLY_WALLPAPER" -eq 1 ]; then
		apply_rtd_wallpapers
	fi

	if [ "$RUN_CLEANUP" -eq 1 ]; then
		cleanup_user_caches
	fi

	restart_user_interface
	complete_setup
}

main "$@"
