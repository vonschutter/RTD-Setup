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
	rm -f "${RTD_TEMPLATE_AUTOFINALIZE_MARKER}" 2>/dev/null || true
	system::rtd_oem_reseal
}

rtd_template_finalize::main "$@"
