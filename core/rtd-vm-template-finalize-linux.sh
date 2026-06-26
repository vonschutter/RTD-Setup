#!/bin/bash

#
# RTD Linux VM template finalizer
#
# Installs the default OEM bundles non-interactively, then runs the distro
# reseal workflow so the next boot prompts the deployed user for first-run
# information where the distribution supports it.
#

set -o pipefail

: "${_SCRIPT_PATH:=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")}"
: "${_SCRIPT_DIR:=$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd)}"
: "${_OEM_DIR:=$(cd "${_SCRIPT_DIR}/.." && pwd)}"
: "${_TLA:=rtd}"
: "${_LOG_DIR:=/var/log/${_TLA}}"
: "${_LOGFILE:=${_LOG_DIR}/rtd-vm-template-finalize-linux-$(date +%Y-%m-%d).log}"
: "${RTD_TEMPLATE_STATUS_DIR:=/var/lib/${_TLA}/vm-template}"
: "${RTD_TEMPLATE_STATUS_FILE:=${RTD_TEMPLATE_STATUS_DIR}/status.json}"
: "${RTD_TEMPLATE_AUTOFINALIZE_MARKER:=/var/lib/${_TLA}/template-autofinalize}"
: "${RTD_POST_OOBE_BUNDLE_AUTOSTART:=/etc/skel/.config/autostart/rtd-oobe-bundle-manager.desktop}"
: "${RTD_POST_OOBE_BUNDLE_WRAPPER:=/usr/local/bin/rtd-oobe-bundle-manager-first-login}"

mkdir -p "${_LOG_DIR}" "${RTD_TEMPLATE_STATUS_DIR}"
touch "${_LOGFILE}"

# shellcheck source=/dev/null
source "${_SCRIPT_DIR}/_rtd_library" ""

rtd_template_finalize::json_escape() {
	local value="${1:-}"
	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	value="${value//$'\n'/\\n}"
	value="${value//$'\r'/\\r}"
	value="${value//$'\t'/\\t}"
	printf '%s' "$value"
}

rtd_template_finalize::supported() {
	local distro_type
	distro_type="$(system::distribution_type 2>/dev/null || printf 'unknown')"

	case "$distro_type" in
		ubuntu|fedora|redhat|suse)
			return 0
			;;
	esac
	return 1
}

rtd_template_finalize::manual_instruction() {
	local distro_type message
	distro_type="$(system::distribution_type 2>/dev/null || printf 'unknown')"
	message="RTD automated template finalization is not enabled for this distribution type (${distro_type}). Install desired default bundles manually, run any global configuration needed for future users, then run the appropriate distro reseal/OOBE preparation manually before cloning."

	rtd_template_finalize::write_status "unsupported" "manual-required" "$message"
	printf '%s\n' "$message" | tee -a "${_LOGFILE}" >&2
	if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
		zenity --warning --title="RTD Template Manual Setup Required" --width=720 --text="$message" 2>/dev/null || true
	elif command -v yad >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
		yad --warning --title="RTD Template Manual Setup Required" --width=720 --text="$message" 2>/dev/null || true
	fi
}

rtd_template_finalize::configure_post_oobe_bundle_manager() {
	mkdir -p "${RTD_POST_OOBE_BUNDLE_AUTOSTART%/*}"
	cat >"${RTD_POST_OOBE_BUNDLE_WRAPPER}" <<EOF
#!/bin/bash
rm -f "\${HOME}/.config/autostart/rtd-oobe-bundle-manager.desktop" >/dev/null 2>&1 || true
exec sudo -E bash "${_OEM_DIR}/core/rtd-oem-linux-config.sh" --first-login-bundle-manager
EOF
	chmod 755 "${RTD_POST_OOBE_BUNDLE_WRAPPER}" 2>/dev/null || true

	cat >"${RTD_POST_OOBE_BUNDLE_AUTOSTART}" <<EOF
[Desktop Entry]
Type=Application
Exec=/usr/bin/xterm -fa Monospace -fs 12 -e "${RTD_POST_OOBE_BUNDLE_WRAPPER}"
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
Name=RTD Bundle Manager
Comment=Select optional RTD software bundles on first login
EOF
	chmod 644 "${RTD_POST_OOBE_BUNDLE_AUTOSTART}" 2>/dev/null || true
}

rtd_template_finalize::disable_temporary_oem_autologin() {
	system::add_or_remove_login_script --remove /etc/xdg/autostart/oem-run.desktop || true
	system::toggle_oem_auto_login --disable || true
	system::toggle_oem_auto_elevated_privilege --disable || true
	system::set_oem_elevated_privilege_gui --disable || true
	rtd_template_finalize::scrub_oem_autologin
}

rtd_template_finalize::scrub_oem_autologin() {
	local file
	local -a autologin_files=(
		/etc/xdg/autostart/oem-run.desktop
		/etc/sddm.conf.d/10-rtd-autologin.conf
		/etc/lightdm/lightdm.conf.d/10-rtd-autologin.conf
		/etc/systemd/system/getty@tty1.service.d/override.conf
	)

	for file in "${autologin_files[@]}"; do
		rm -f "$file" 2>/dev/null || true
	done

	for file in /etc/gdm3/custom.conf /etc/gdm3/daemon.conf /etc/gdm/custom.conf; do
		[[ -f "$file" ]] || continue
		sed -i \
			-e 's/^[[:space:]]*AutomaticLoginEnable[[:space:]]*=.*/AutomaticLoginEnable=False/' \
			-e '/^[[:space:]]*AutomaticLogin[[:space:]]*=/d' \
			"$file" 2>/dev/null || true
	done

	for file in /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf; do
		[[ -f "$file" ]] || continue
		sed -i \
			-e '/^[[:space:]]*autologin-user[[:space:]]*=/d' \
			-e '/^[[:space:]]*autologin-user-timeout[[:space:]]*=/d' \
			"$file" 2>/dev/null || true
	done

	for file in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
		[[ -f "$file" ]] || continue
		sed -i \
			-e '/^[[:space:]]*User[[:space:]]*=[[:space:]]*tangarora[[:space:]]*$/d' \
			-e '/^[[:space:]]*Session[[:space:]]*=.*$/d' \
			"$file" 2>/dev/null || true
	done

	if [[ -f /etc/sysconfig/displaymanager ]]; then
		sed -i \
			-e 's/^DISPLAYMANAGER_AUTOLOGIN=.*/DISPLAYMANAGER_AUTOLOGIN=""/' \
			-e 's/^DISPLAYMANAGER_PASSWORD_LESS_LOGIN=.*/DISPLAYMANAGER_PASSWORD_LESS_LOGIN="no"/' \
			/etc/sysconfig/displaymanager 2>/dev/null || true
	fi

	systemctl daemon-reload >/dev/null 2>&1 || true
}

rtd_template_finalize::write_status() {
	local phase="${1:-unknown}" result="${2:-running}" detail="${3:-}"
	local pretty_name distro_family timestamp

	pretty_name="$(system::os_pretty_name 2>/dev/null || printf 'Linux')"
	distro_family="$(system::distribution_type 2>/dev/null || printf 'unknown')"
	timestamp="$(date --iso-8601=seconds 2>/dev/null || date)"

	cat >"${RTD_TEMPLATE_STATUS_FILE}" <<EOF
{
  "schema": "rtd.vm-template.guest-status.v1",
  "phase": "$(rtd_template_finalize::json_escape "$phase")",
  "result": "$(rtd_template_finalize::json_escape "$result")",
  "detail": "$(rtd_template_finalize::json_escape "$detail")",
  "os": "$(rtd_template_finalize::json_escape "$pretty_name")",
  "distribution_family": "$(rtd_template_finalize::json_escape "$distro_family")",
  "updated_at": "$(rtd_template_finalize::json_escape "$timestamp")"
}
EOF
}

rtd_template_finalize::main() {
	local bundle_manager="${_OEM_DIR}/modules/oem-bundle-manager.mod/rtd-oem-bundle-manager"

	if [[ ${EUID} -ne 0 ]]; then
		exec sudo -E bash "$0" "$@"
	fi

	if ! rtd_template_finalize::supported; then
		rtd_template_finalize::manual_instruction
		rm -f "${RTD_TEMPLATE_AUTOFINALIZE_MARKER}" 2>/dev/null || true
		return 1
	fi

	rtd_template_finalize::write_status "bundle-install" "running" "Installing default RTD bundles"
	if [[ ! -x "$bundle_manager" ]]; then
		chmod 755 "$bundle_manager" 2>/dev/null || true
	fi
	if [[ ! -f "$bundle_manager" ]]; then
		rtd_template_finalize::write_status "bundle-install" "failed" "Bundle manager not found at ${bundle_manager}"
		printf 'Bundle manager not found at %s\n' "$bundle_manager" >&2
		return 1
	fi
	if ! bash "$bundle_manager" --noninteractive >>"${_LOGFILE}" 2>&1; then
		rtd_template_finalize::write_status "bundle-install" "failed" "Default bundle installation failed; see ${_LOGFILE}"
		printf 'Default bundle installation failed; see %s\n' "${_LOGFILE}" >&2
		return 1
	fi

	rtd_template_finalize::write_status "reseal" "running" "Running RTD OEM reseal"
	rtd_template_finalize::configure_post_oobe_bundle_manager
	rtd_template_finalize::disable_temporary_oem_autologin
	rm -f "${RTD_TEMPLATE_AUTOFINALIZE_MARKER}" 2>/dev/null || true
	system::rtd_oem_reseal
}

rtd_template_finalize::main "$@"
