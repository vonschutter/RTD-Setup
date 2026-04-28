#!/usr/bin/env bash
#
#::                          Whonix KVM Installer (RTD)
#::                     S O F T W A R E    C O N F I G U R A T I O N
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::// Linux //::::::::
#:: Module:     setup-whonix.mod
#:: Script:     rtd-setup-whonix.sh
#:: Author(s):  RTD Team (vonschutter)
#:: Version:    1.0
#:: Purpose:    Whonix-KVM fully automatic installer with error handling and auto-discovery.
#:: Usage:      sudo bash rtd-setup-whonix.sh [--refresh] [--add]
#:: Requires:   RTD library > 2.04, admin privileges, and KVM/libvirt stack (qemu, libvirt, dnsmasq, virt-manager, xz-utils, wget).
#:: Notes:      Downloads the latest Whonix libvirt bundle, verifies, defines networks, and stages/defines the Gateway + Workstation VMs.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set -euo pipefail

##############  globals  ####################################################
# These will be initialized after the RTD defaults are applied so that values
# in _locations.info (or the environment) can override the sane fallbacks.
: "${WORK_DIR:=}"
: "${IMAGE_DIR:=}"
: "${WHONIX_BASE:=}"
REFRESH=0
ADD_WORKSTATION=0

##############  error helper  ###############################################
die(){
	if declare -F write_error &>/dev/null; then
		write_error "$*"
	else
		printf 'ERROR: %s\n' "$*" >&2
	fi
	exit 1
}

##############  apply defaults  #############################################
init_paths(){
	# Respect any caller/exported overrides first, then _locations.info, then hard defaults.
	: "${WORK_DIR:=${WHONIX_WORKDIR:-${_USER_HOME_DIR:-${HOME}}/.local/share/whonix-kvm}}"
	: "${IMAGE_DIR:=${WHONIX_IMAGE_DIR:-${VM_BUILD_TARGET:-/var/lib/libvirt/images}}}"
	: "${WHONIX_BASE:=${WHONIX_LIBVIRT_BASE_URL:-https://download.whonix.org/libvirt}}"
}

set_source_urls(){
	# _rtd_library sources .info files; apply fallbacks only if unset.
	local profile="${GIT_Profile:-${_GIT_PROFILE:-vonschutter}}"
	: "${RTD_SETUP_CLONE_URL:=${GIT_RTD_SRC_URL:-https://github.com/${profile}/RTD-Setup.git}}"
	: "${RTD_SETUP_RAW_BASE:=${GIT_RTD_SETUP_RAW_BASE:-https://raw.githubusercontent.com/${profile}/RTD-Setup/main}}"
}

##############  argument parsing  ###########################################
parse_args(){
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--refresh) REFRESH=1 ;;
			--add) ADD_WORKSTATION=1 ;;
			-h|--help)
				cat <<EOF
Usage: $0 [--refresh] [--add]
	--refresh   Force re-define VMs using the newly downloaded images (networks are kept)
	--add       If a workstation already exists and is up to date, add an extra workstation VM (gateway untouched)
EOF
				exit 0
				;;
			*) die "Unknown option: $1" ;;
		esac
		shift
	done
}

##############  locate and source RTD library  ##############################
rtd::bootstrap_library() {
	local library_name="${1:-_rtd_library}"
	local minimum_version="${2:-}"
	local loaded_version="${RTD_VERSION:-${RTDFUNCTIONS:-}}"
	local script_dir path src_url tmp

	if [[ "$library_name" == "_rtd_library" && -n "$loaded_version" ]]; then
		if { [[ -z "$minimum_version" ]] || [[ "$(printf '%s\n%s\n' "$minimum_version" "$loaded_version" | sort -V | tail -n 1)" == "$loaded_version" ]]; } &&
			declare -F system::log_item >/dev/null 2>&1 &&
			declare -F library::apply_rtd_defaults >/dev/null 2>&1; then
			return 0
		fi
	fi

	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	for path in \
		"${script_dir}/${library_name}" \
		"${script_dir}/../core/${library_name}" \
		"${script_dir}/../../core/${library_name}" \
		"/opt/${_TLA:-${_tla:-rtd}}/core/${library_name}" \
		"/opt/rtd/core/${library_name}" \
		"${HOME:-}/GIT/RTD-Setup/core/${library_name}" \
		"${HOME:-}/RTD-Setup/core/${library_name}"; do
		if [[ -r "$path" ]]; then
			# shellcheck source=/dev/null
			source "$path" ""
			return $?
		fi
	done

	src_url="https://github.com/${_GIT_PROFILE:-${GIT_Profile:-vonschutter}}/RTD-Setup/raw/main/core/${library_name}"
	tmp="$(mktemp "/tmp/${library_name}.XXXXXX" 2>/dev/null || echo "/tmp/${library_name}.$$")"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$src_url" -o "$tmp" || return 1
	elif command -v wget >/dev/null 2>&1; then
		wget -qO "$tmp" "$src_url" || return 1
	else
		return 1
	fi

	# shellcheck source=/dev/null
	source "$tmp" ""
	local rc=$?
	rm -f "$tmp"
	return $rc
}

check_rtd_version(){
	local min="2.04"
	if [ -z "${RTD_VERSION:-}" ]; then
		die "_rtd_library not loaded correctly (RTD_VERSION missing)"
	fi
	local max
	max=$(printf '%s\n%s\n' "$RTD_VERSION" "$min" | sort -V | tail -1)
	if [[ $max != "$RTD_VERSION" || $RTD_VERSION == "$min" ]]; then
		die "_rtd_library version $RTD_VERSION is unsupported; require > $min"
	fi
}

##############  install distro packages  ####################################
ensure_deps(){
	write_status "Checking QEMU/KVM dependencies"
	local deps=(
		qemu-system-x86 libvirt-daemon-system libvirt-clients virt-manager
		dnsmasq-base qemu-utils iptables xz-utils wget gir1.2-spiceclientgtk-3.0
	)
	declare -F software::check_native_package_dependency &>/dev/null \
		|| die "RTD library not loaded: software::check_native_package_dependency missing"
	for pkg in "${deps[@]}"; do
		software::check_native_package_dependency "$pkg" 
	done
}

##############  add user to libvirt groups  #################################
add_user_groups(){
	write_status "Ensuring $USER is in libvirt/kvm groups"
	local groups_needed=(libvirt kvm)
	for grp in "${groups_needed[@]}"; do
		if id -nG "$USER" 2>/dev/null | grep -qw "$grp"; then
			write_status "User $USER already in $grp"
		else
			usermod -aG "$grp" "$USER" || write_warning "Could not add $USER to group $grp"
		fi
	done
}

##############  start default network  ######################################
start_default_net(){
	write_status "Ensuring libvirt default network is active"
	virsh -c qemu:///system net-start default 2>/dev/null || true
	virsh -c qemu:///system net-autostart default 2>/dev/null || true
}

##############  final sanity check  #########################################
sanity_check(){
	write_status "Installed VMs:"
	virsh -c qemu:///system list --all | grep -Ei whonix || die "no Whonix VMs visible"
}

##############  main  #######################################################
main(){
	parse_args "$@"
	rtd::bootstrap_library "_rtd_library" || die "Unable to locate or download _rtd_library"
	check_rtd_version
	set_source_urls
	init_paths
	security::ensure_admin || die "Failed to obtain admin privileges"
	ensure_deps
	add_user_groups
	start_default_net

	whonix::discover_bundle || die "failed to discover Whonix bundle"
	whonix::maybe_skip_install
	whonix::prepare_workdir
	whonix::download_bundle || die "failed to download bundle"
	whonix::extract_archive || die "failed to extract bundle"
	whonix::ensure_networks_defined
	whonix::ensure_networks_running
	whonix::stage_images
	whonix::define_vms
	sanity_check
	write_status "SUCCESS! Start the VMs with:
		virsh -c qemu:///system start Whonix-Gateway
		virsh -c qemu:///system start Whonix-Workstation"
}

main "$@"
