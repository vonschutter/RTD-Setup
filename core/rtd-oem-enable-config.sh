#!/bin/bash
#
#::                             S Y S T E M    B U I L D     C O M P O N E N T
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::// OEM ENABLE CONFIG //::::::::::::::::::::::::::::::::::// Linux //::::::::
#::
#:: Author:   	SLS
#:: Version 	1.02
#::
#::
#::	Purpose: To enable configuration of a newly built linux install. This file will be referenced by
#::		 either Debian setup (Debian , ubuntu, etc.), SUSE auto yast, or Anaconda (red Hat, Fedora etc.).
#::		 This script configures the system to auto login, and run the system configuration choices menu.
#::
#::	Usage:	Simply execute this script to accomplish this task. No parameters required.
#::
#::
#::
#::
#::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
# This script is shared in the hopes that someone will find it useful.
# For convenience and supportability most actions (work) is stored in a common library used bu multiple scripts.
# To use these functions in the library, simply load the library using the "source" bash built in command. All
# functions will then be available for use. This script demonstrates the simplicity of using these functions.
#
# This script is intended to live in the ~/bin/ or /bin/ folder, alternatively in the $PATH.
# By default this script is placed in /opt/rtd/core/
#
# NOTE: this script is run by the power tools system setup and therefore the oem tools are assumed to be present.
#
# 1 - To see options to use the rtd library type: "bash _rtd_library --help"
# 2 - To see useful documentation on each function in this library: "bash _rtd_library --devhelp or --devhelp-gtk"

# --- Strict Mode & Early Exit on Error ---
# set -euo pipefail # Exit on error, unset variable, or pipe failure

# --- Essential Sanity Checks ---
if [[ $EUID -ne 0 ]]; then { echo "💥 This script must be run as root" ; exit 1; } ; fi


# --- Global Configuration Variables (Consider moving to a config file or env vars) ---
# Determine the Three Letter Acronym (TLA) for the organization/project
readonly SCRIPT_NAME=$(basename "$0")
readonly TLA_UPPERCASE="${SCRIPT_NAME:0:3}" # e.g., RTD
readonly TLA_LOWERCASE="${TLA_UPPERCASE,,}"  # e.g., rtd

readonly BASE_DIR="/opt/${TLA_LOWERCASE}"
readonly CORE_DIR="${BASE_DIR}/core"
readonly CONFIG_DIR="${BASE_DIR}/config"
readonly LOG_DIR_PATH="${BASE_DIR}/logs"

readonly LIBRARY_PATH="${CORE_DIR}/_rtd_library"
readonly FAILLOG_PATH="${BASE_DIR}/faillog.log"

# --- Load Core Library ---
if [ -z "${RTDFUNCTIONS:-}" ]; then
	if [[ ! -f "$LIBRARY_PATH" ]]; then
		echo "💥 CRITICAL ERROR: Required library not found at '${LIBRARY_PATH}'." >&2
		echo "💥 $(date '+%Y-%m-%d %H:%M:%S') CRITICAL ERROR: Library '${LIBRARY_PATH}' not found." >> "$FAILLOG_PATH" 2>/dev/null || true
		exit 1
	fi

	source "$LIBRARY_PATH" || {
		echo "💥 CRITICAL ERROR: Failed to source library '${LIBRARY_PATH}'." >&2
		echo "💥 $(date '+%Y-%m-%d %H:%M:%S') CRITICAL ERROR: Failed to source library '${LIBRARY_PATH}'." >> "$FAILLOG_PATH" 2>/dev/null || true
		exit 1
	}
else
	write_information "📚 _rtd_library is already loaded..."
fi


# --- Script Settings & Global Variables for Library ---
# These might be set by the library, but explicit declaration can be good.
# Re-evaluate if the library already handles these based on TLA.
export _TLA="${TLA_UPPERCASE}" # Library might expect this specific casing
export _LOG_DIR="${LOG_DIR_PATH}" # Ensure library uses this
export _CONFIG_DIR="${CONFIG_DIR}" # Ensure library uses this
export _LOGFILE="${_LOG_DIR}/$(basename "$0" .sh).log" # .sh extension removal
export _OEM_DIR="${BASE_DIR}" 

system::ensure_directory_exists "$_LOG_DIR" || exit 1 # Exit if log dir can't be made
system::ensure_directory_exists "$_CONFIG_DIR" || exit 1

main() {
	# --- OEM Auto-Configuration Tasks (Relying on Library Functions) ---

	write_status "🚀 Preparing system for automated OEM post-build tasks..."

	wisdom_quotes_setup || {
		system::log_item "⛔ ERROR: Failed to set up wisdom quotes. MOTD may not function as expected."
	}

	configure_motd || {
		system::log_item "⛔ ERROR: Failed to configure MOTD. Login messages will not be shown..."
	}

	tty_login_banner || {
		system::log_item "⛔ ERROR: Failed to set TTY login banner. Check permissions or file system."
	}

	system::add_or_remove_login_script --add "${CORE_DIR}/rtd-oem-linux-config.sh"
	system::toggle_oem_auto_elevated_privilege --enable
	system::toggle_oem_auto_login --enable
	system::set_oem_elevated_privilege_gui --enable

	# --- OEM Tool Integration ---
	if command -v oem::rtd_tools_make_launchers &>/dev/null; then
		oem::rtd_tools_make_launchers
	else
		system::log_item "WARNING: Function oem::rtd_tools_make_launchers not found."
	fi

	if command -v oem::register_all_tools &>/dev/null; then
		oem::register_all_tools
	else
		system::log_item "WARNING: Function oem::register_all_tools not found."
	fi

	# --- Final Touches ---
	if [[ -n "${_OEM_DIR:-}" && -d "$_OEM_DIR" ]]; then
		system::log_item "Creating symlink for logs: ${_LOG_DIR} -> ${_OEM_DIR}/log"

		if ! ln -sfn "$_LOG_DIR" "${_OEM_DIR}/log"; then
			system::log_item "ERROR: Failed to create symlink from ${_LOG_DIR} to ${_OEM_DIR}/log."
		fi
	else
		system::log_item "WARNING: _OEM_DIR not set or not a directory. Skipping log symlink creation."
	fi

	system::log_item "✅ OEM Enable Configuration script completed."
	exit 0
}


wisdom_quotes_setup() {
	if [[ -z "${KENS_QUOTES:-}" ]]; then
		write_error "⛔ KENS_QUOTES variable is not set. Please define it before running the script."
	fi
	readonly RTD_WISDOM_QUOTES_PATH="${_CONFIG_DIR}/kens_quotes.txt" # Use consistent naming

	write_status "🦉 Preparing wisdom quotes file: ${RTD_WISDOM_QUOTES_PATH}"
	if ! touch "$RTD_WISDOM_QUOTES_PATH"; then
		system::log_item "ERROR: Failed to create wisdom quotes file: ${RTD_WISDOM_QUOTES_PATH}"
		exit 1 # Critical if MOTD depends on it
	fi
	# Populate if empty or only with placeholder (idempotency)
	if ! grep -q "Do not argue with an idiot" "$RTD_WISDOM_QUOTES_PATH"; then
		system::log_item "Populating Ken's wisdom in '${RTD_WISDOM_QUOTES_PATH}'..."
		# Use printf for better control over newlines than cat >> EOF
		# Overwrite to ensure consistency if the file was only touched or had old content
		printf '%s\n' "$KENS_QUOTES" > "$RTD_WISDOM_QUOTES_PATH" || {
			system::log_item "⛔ ERROR: Failed to write quotes to ${RTD_WISDOM_QUOTES_PATH}";
		}
	else
		system::log_item "Wisdom quotes file already populated."
	fi
}


# --- MOTD (Message Of The Day) Configuration ---
configure_motd() {
	system::log_item "Configuring MOTD..."
	local motd_scripts_dir=""
	local motd_wisdom_script_path=""
	local neofetch_script_path=""

	# Determine standard MOTD scripts directory
	if [[ -d /etc/update-motd.d ]]; then
		motd_scripts_dir="/etc/update-motd.d"
	elif [[ -d /etc/motd.d ]]; then # Older systems or different configurations
		motd_scripts_dir="/etc/motd.d"
	fi

	if [[ -z "$motd_scripts_dir" ]]; then
		system::log_item "⛔ WARNING: No standard MOTD script directory (/etc/update-motd.d or /etc/motd.d) found."
		system::log_item "⛔ Attempting Red Hat/Fedora specific dynamic MOTD setup if applicable."
		# Fall through to distro-specific logic which might handle this
	else
		motd_wisdom_script_path="${motd_scripts_dir}/55-rtd-wisdom" # Use consistent naming
		neofetch_script_path="${motd_scripts_dir}/50-rtd-neofetch" # Use consistent naming
	fi

	# Set the MOTD to display a random quote from the file
	if [[ -n "$motd_wisdom_script_path" ]]; then
		system::log_item "Creating wisdom MOTD script: ${motd_wisdom_script_path}"
		# Use printf for the script content to handle special characters and ensure newlines
		printf '#!/bin/bash\n' > "$motd_wisdom_script_path"
		printf '# Displays a random quote from the specified file.\n\n' >> "$motd_wisdom_script_path"
		# Use a more robust way to get a random line (shuf if available, otherwise awk)
		# Ensure the variable is correctly quoted within the generated script
		printf 'readonly QuoteFile="%s"\n' "$RTD_WISDOM_QUOTES_PATH" >> "$motd_wisdom_script_path"
		printf 'if [[ -f "$QuoteFile" && -s "$QuoteFile" ]]; then\n' >> "$motd_wisdom_script_path"
		# Use shuf if available, otherwise fallback to awk for random line
		printf '  if command -v shuf > /dev/null; then\n' >> "$motd_wisdom_script_path"
		printf '    shuf -n 1 "$QuoteFile"\n' >> "$motd_wisdom_script_path"
		printf '  else\n' >> "$motd_wisdom_script_path"
		printf '    awk -v "max=\$(wc -l < \"\$QuoteFile\")" \'\''BEGIN{srand(); l=int(rand()*max)+1} NR==l{print; exit}'\'' "$QuoteFile"\n' >> "$motd_wisdom_script_path"
		printf '  fi\n' >> "$motd_wisdom_script_path"
		printf 'fi\n' >> "$motd_wisdom_script_path"

		if ! chmod +x "$motd_wisdom_script_path"; then
			system::log_item "⛔ ERROR: Failed to make ${motd_wisdom_script_path} executable."
		fi
	fi

	# Neofetch MOTD script
	if [[ -n "$neofetch_script_path" ]] && command -v neofetch &>/dev/null; then
		system::log_item "Creating neofetch MOTD script: ${neofetch_script_path}"
		printf '#!/bin/bash\nneofetch\n' > "$neofetch_script_path"
		if ! chmod +x "$neofetch_script_path"; then
			system::log_item "⛔ ERROR: Failed to make ${neofetch_script_path} executable."
		fi
	elif [[ -n "$neofetch_script_path" ]]; then
		system::log_item "⛔ INFO: neofetch command not found, skipping neofetch MOTD script."
	fi

	# Distribution-specific MOTD handling (e.g., for systems without /etc/update-motd.d)
	local dtype="unknown"
	dtype=$(system::distribution_type) 

	if [[ "$dtype" == "fedora" || "$dtype" == "rhel" || "$dtype" == "centos" ]]; then
		if [[ -z "$motd_scripts_dir" ]]; then # Only if standard dirs weren't found
		system::log_item "Setting up systemd timer for dynamic MOTD on Fedora/RHEL-like system..."
		local motd_update_script_path="/usr/local/sbin/rtd-update-motd.sh"
		local motd_service_path="/etc/systemd/system/rtd-update-motd.service"
		local motd_timer_path="/etc/systemd/system/rtd-update-motd.timer"

		# Create the script that generates /etc/motd
		printf '#!/bin/bash\n' > "$motd_update_script_path"
		printf '# Aggregates MOTD content for /etc/motd.\n\n' >> "$motd_update_script_path"
		printf 'readonly MOTD_FILE="/etc/motd"\n' >> "$motd_update_script_path"
		printf '(\n' >> "$motd_update_script_path"
		# Execute the wisdom script if it was intended (even if not in standard dir)
		if [[ -f "/usr/local/sbin/rtd-wisdom-motd.sh" ]]; then # Assuming we'd place it here
			printf '  /usr/local/sbin/rtd-wisdom-motd.sh\n' >> "$motd_update_script_path"
		fi
		if command -v neofetch &>/dev/null; then
			printf '  neofetch\n' >> "$motd_update_script_path"
		fi
		printf ') > "$MOTD_FILE"\n' >> "$motd_update_script_path"
		chmod +x "$motd_update_script_path"

		# Create systemd service
		printf '[Unit]\nDescription=Update RTD MOTD\n\n' > "$motd_service_path"
		printf '[Service]\nType=oneshot\nExecStart=%s\n' "$motd_update_script_path" >> "$motd_service_path"

		# Create systemd timer
		printf '[Unit]\nDescription=Run RTD MOTD update daily and on boot\n\n' > "$motd_timer_path"
		printf '[Timer]\nOnBootSec=2min\nOnUnitActiveSec=24h\nUnit=%s\n\n' "$(basename "$motd_service_path")" >> "$motd_timer_path"
		printf '[Install]\nWantedBy=timers.target\n' >> "$motd_timer_path"

		systemctl daemon-reload || system::log_item "WARNING: Failed to reload systemd daemon."
		systemctl enable --now "$(basename "$motd_timer_path")" || system::log_item "WARNING: Failed to enable/start MOTD timer."
		system::log_item "Dynamic MOTD setup via systemd timer completed for Fedora/RHEL-like system."
		fi		
	fi
}



tty_login_banner() {
	# --- TTY Login Banner (/etc/issue) ---
	readonly ISSUE_FILE="/etc/issue"
	: ${_OEM_TTY_LOGIN_BANNER:="$_TLA_UPPERCASE Enable Configuration Script"}
	if [[ -n "${_OEM_TTY_LOGIN_BANNER}" ]]; then
	system::log_item "Setting TTY login banner in ${ISSUE_FILE}..."
	# If /etc/issue is a symlink (common on some systems to point to a dynamic issue file),
	# removing and replacing it might be necessary if we want a static banner.
	# However, if it's dynamic for a reason, overwriting might break things.
	if [[ -L "$ISSUE_FILE" ]]; then
		system::log_item "INFO: ${ISSUE_FILE} is a symlink. Removing it to set a static banner."
		rm -f "$ISSUE_FILE" || { system::log_item "ERROR: Failed to remove symlink ${ISSUE_FILE}"; }
	fi
	# Use printf for safer writing
	printf '%s\n' "${_OEM_TTY_LOGIN_BANNER}" > "$ISSUE_FILE" || {
		system::log_item "⛔ ERROR: Failed to write to ${ISSUE_FILE}";
	}
	else
	system::log_item "WARNING: _OEM_TTY_LOGIN_BANNER is not set. Skipping /etc/issue update."
	fi
}


main "$@"





# End of Script