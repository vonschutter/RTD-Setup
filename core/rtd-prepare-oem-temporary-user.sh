#!/bin/bash
#
# Prepare RTD's temporary Ubuntu build account for Ubiquity OEM first boot.
# This runs as a systemd oneshot before oem-config.service, when the temporary
# graphical login is no longer active and the account can safely be renamed.

set -euo pipefail

readonly STATE_FILE="${RTD_OEM_USER_STATE_FILE:-/var/lib/rtd/oem-temporary-user}"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	printf 'Usage: %s\n' "$(basename "$0")"
	printf 'Rename the RTD temporary build account to the Ubiquity OEM account.\n'
	exit 0
fi

[[ $# -eq 0 ]] || {
	printf 'Unexpected argument: %s\n' "$1" >&2
	exit 2
}
[[ -r "${STATE_FILE}" ]] || exit 0

temporary_user="$(head -n 1 "${STATE_FILE}")"
[[ "${temporary_user}" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || {
	printf 'Invalid temporary OEM username in %s.\n' "${STATE_FILE}" >&2
	exit 1
}
[[ "${temporary_user}" != "root" ]] || {
	printf 'Refusing to rename root for OEM setup.\n' >&2
	exit 1
}
[[ "${temporary_user}" != "oem" ]] || exit 0
getent passwd "${temporary_user}" >/dev/null
if getent passwd oem >/dev/null; then
	printf 'RTD OEM handoff refused: both %s and oem exist.\n' "${temporary_user}" >&2
	exit 1
fi

old_home="$(getent passwd "${temporary_user}" | cut -d: -f6)"
old_group="$(id -gn "${temporary_user}")"
old_uid="$(id -u "${temporary_user}")"
old_gid="$(id -g "${temporary_user}")"
[[ "${old_group}" == "${temporary_user}" ]] || {
	printf 'RTD OEM handoff requires a private primary group for %s.\n' "${temporary_user}" >&2
	exit 1
}
if getent group oem >/dev/null; then
	printf 'RTD OEM handoff refused: group oem already exists.\n' >&2
	exit 1
fi
if [[ "${old_uid}" != 29999 ]] && getent passwd 29999 >/dev/null; then
	printf 'RTD OEM handoff refused: UID 29999 is already occupied.\n' >&2
	exit 1
fi
if [[ "${old_gid}" != 29999 ]] && getent group 29999 >/dev/null; then
	printf 'RTD OEM handoff refused: GID 29999 is already occupied.\n' >&2
	exit 1
fi

groupmod --new-name oem "${old_group}"
[[ "${old_gid}" == 29999 ]] || groupmod --gid 29999 oem
usermod --login oem "${temporary_user}"
[[ "${old_uid}" == 29999 ]] || usermod --uid 29999 oem
if [[ "${old_home}" != "/home/oem" ]]; then
	usermod --home /home/oem --move-home oem
fi
usermod --gid oem oem
chown -R oem:oem /home/oem

for account_file in "/var/lib/AccountsService/users/${temporary_user}" "/var/lib/AccountsService/icons/${temporary_user}"; do
	[[ -e "${account_file}" ]] || continue
	mv "${account_file}" "${account_file%/*}/oem"
done
printf '%s\n' oem >"${STATE_FILE}"
