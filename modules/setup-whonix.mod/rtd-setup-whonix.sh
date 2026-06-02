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
#:: Requires:   RTD library >= 2.05, admin privileges, and KVM/libvirt stack (qemu, libvirt, dnsmasq, virt-manager, xz-utils, wget).
#:: Notes:      Downloads the latest Whonix libvirt bundle, verifies, defines networks, and stages/defines the Gateway + Workstation VMs.
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Safety Check             ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
	echo "ERROR: RTD _rtd_library requires Bash 4.4 or newer. Current shell: Bash ${BASH_VERSION}." >&2
	return 1 2>/dev/null || exit 1
fi

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
	if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
		echo "ERROR: RTD _rtd_library requires Bash 4.4 or newer. Current shell: Bash ${BASH_VERSION}." >&2
		return 1
	fi
	local library_name="${1:-_rtd_library}" minimum_version="" loaded_version path script_dir src_url tmp rc check
	local -a checks=()

	[[ $# -gt 0 && "${1:-}" != --* ]] && { library_name="$1"; shift; }
	[[ $# -gt 0 && "${1:-}" != --* ]] && { minimum_version="$1"; shift; }
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--version|--check)
				[[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
				[[ "$1" == "--version" ]] && minimum_version="$2" || checks+=("$2")
				shift 2
			;;
			*)
				echo "Unknown rtd::bootstrap_library option: $1" >&2
				return 1
			;;
		esac
	done

	[[ "$library_name" == "_rtd_library" && ${#checks[@]} -eq 0 ]] && checks=(system::log_item library::apply_rtd_defaults)

	rtd::bootstrap_library::ok() {
		loaded_version="${RTD_VERSION:-${RTDFUNCTIONS:-}}"
		if [[ "$library_name" == "_rtd_library" && -n "$minimum_version" ]]; then
			[[ -n "$loaded_version" ]] || return 1
			[[ "$(printf '%s\n%s\n' "$minimum_version" "$loaded_version" | sort -V | tail -n 1)" == "$loaded_version" ]] || return 1
		fi
		for check in "${checks[@]}"; do declare -F "$check" >/dev/null 2>&1 || return 1; done
	}

	[[ "$library_name" == "_rtd_library" && -n "$loaded_version" ]] && rtd::bootstrap_library::ok && return 0

	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	for path in \
		"${script_dir}/${library_name}" \
		"${script_dir}/../core/${library_name}" \
		"${script_dir}/../../core/${library_name}" \
		"/opt/${_TLA:-${_tla:-rtd}}/core/${library_name}" \
		"/opt/rtd/core/${library_name}" \
		"${HOME:-}/GIT/RTD-Setup/core/${library_name}" \
		"${HOME:-}/RTD-Setup/core/${library_name}"; do
		[[ -r "$path" ]] || continue
		# shellcheck source=/dev/null
		source "$path" ""
		rc=$?
		[[ $rc -eq 0 ]] && rtd::bootstrap_library::ok && return 0
	done

	src_url="https://github.com/${_GIT_PROFILE:-${GIT_Profile:-vonschutter}}/RTD-Setup/raw/main/core/${library_name}"
	tmp="$(mktemp "/tmp/${library_name}.XXXXXX" 2>/dev/null || echo "/tmp/${library_name}.$$")"
	rc=0
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$src_url" -o "$tmp" || rc=$?
	elif command -v wget >/dev/null 2>&1; then
		wget -qO "$tmp" "$src_url" || rc=$?
	else
		rc=1
	fi
	[[ ${rc:-0} -eq 0 ]] || { rm -f "$tmp"; return "$rc"; }

	# shellcheck source=/dev/null
	source "$tmp" ""
	rc=$?
	rm -f "$tmp"
	[[ $rc -eq 0 ]] || return "$rc"
	rtd::bootstrap_library::ok && return 0

	echo "Loaded $library_name, but the requested version/functions are not available." >&2
	return 1
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
	rtd::bootstrap_library "_rtd_library" --version 2.05 --check software::check_native_package_dependency || die "Unable to locate or download a compatible _rtd_library"
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
