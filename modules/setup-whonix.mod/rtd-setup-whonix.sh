#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Whonix-KVM fully automatic installer (with error handling and auto-discovery)
# ---------------------------------------------------------------------------
set -euo pipefail

##############  globals  ####################################################
WORK_DIR="${HOME}/.local/share/whonix-kvm"
IMAGE_DIR="/var/lib/libvirt/images"
WHONIX_BASE="https://download.whonix.org/libvirt"

WHONIX_URL=""
WHONIX_SHA=""
WHONIX_VERSION=""
BUNDLE_NAME=""
BUNDLE_PATH=""
IMAGE_OWNER=""
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
load_rtd_library(){
  local -a saved_args=("$@")
  local script_dir candidates tmp
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  candidates=(
    "/opt/rtd/core/_rtd_library"
    "${PWD}/_rtd_library"
    "${script_dir}/_rtd_library"
    "${script_dir}/../core/_rtd_library"
    "${HOME}/RTD-Setup/core/_rtd_library"
    "${HOME}/GIT/RTD-Setup/core/_rtd_library"
  )
  for path in "${candidates[@]}"; do
    if [[ -f $path ]]; then
      set --
      source "$path"
      set -- "${saved_args[@]}"
      return
    fi
  done

  tmp=$(mktemp -d)
  if command -v git &>/dev/null; then
    if git clone --depth 1 https://github.com/vonschutter/RTD-Setup "$tmp/RTD-Setup" &>/dev/null; then
      if [[ -f $tmp/RTD-Setup/core/_rtd_library ]]; then
        set --
        source "$tmp/RTD-Setup/core/_rtd_library"
        set -- "${saved_args[@]}"
        return
      fi
    fi
  fi
  if wget -qO "$tmp/_rtd_library" "https://raw.githubusercontent.com/vonschutter/RTD-Setup/main/core/_rtd_library"; then
    set --
    source "$tmp/_rtd_library"
    set -- "${saved_args[@]}"
    return
  fi
  set -- "${saved_args[@]}"
  die "Unable to locate or download _rtd_library"
}

check_rtd_version(){
  local min="2.04"
  [[ -z ${RTD_VERSION:-} ]] && die "_rtd_library not loaded correctly (RTD_VERSION missing)"
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
  load_rtd_library "$@"
  check_rtd_version
  security::ensure_admin >/dev/null 2>&1 || die "Failed to obtain admin privileges"
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
