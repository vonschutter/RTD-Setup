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
	# These calls assume the library functions are robust and handle errors internally.
	# If they don't, add explicit error checking: if ! system::function; then ...; fi

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
	system::toggle_oem_auto_login --enable # Ensure this is idempotent and distro-aware
	system::set_oem_elevated_privilege_gui --enable # Ensure this is distro-aware

	# These are custom OEM functions, ensure they are defined and robust
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
	# Create a symlink for logs (ensure _OEM_DIR is defined, likely by library)
	if [[ -n "${_OEM_DIR:-}" && -d "$_OEM_DIR" ]]; then
	system::log_item "Creating symlink for logs: ${_LOG_DIR} -> ${_OEM_DIR}/log"
	# -T treats destination as a normal file (good for symlinking directories)
	# -f forces removal of existing destination if it's a file or symlink
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













# ******************* Deprecated  *******************
# if [[ $EUID -ne 0 ]]; then { echo "This script must be run as root" ; exit 1; } ; fi

# #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# #::::::::::::::                                          ::::::::::::::::::::::
# #::::::::::::::          Script Settings                 ::::::::::::::::::::::
# #::::::::::::::                                          ::::::::::::::::::::::
# #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# # Variables that govern the behavior or the script and location of files are

# # Base folder structure for optional administrative commandlets and scripts:
# # Put a convenient link to the logs where logs are normally found...
# # capture the 3 first letters as org TLA (Three Letter Acronym)

# # Figure the base TLA for the organization
# export _SCRIPTNAME=$(basename $0)
# export _TLA=${_SCRIPTNAME:0:3}
# _lib_path="/opt/${_TLA,,}/core/_rtd_library"
# _faillog="/opt/${_TLA,,}/faillog.log"

# # Load the RTD library (once loaded, all functions are available)
# if [ -f ${_lib_path} ]; then
# 	source ${_lib_path} || { echo "💥 CRITICAL ERROR: Required library ( ${_lib_path} ) not found." >> ${_faillog} ; exit 1; }
# else
# 	echo "💥 CRITICAL ERROR: Required library not found." >> ${_faillog}
# 	exit 1
# fi

# kens_quotes="
# - Do not argue with an idiot. He will drag you down to his level and beat you with experience.
# - Going to church doesn't make you a Christian any more than standing in a garage makes you a car.
# - The last thing I want to do is hurt you. But it's still on the list.
# - If I agreed with you we'd both be wrong.
# - We never really grow up, we only learn how to act in public.
# - War does not determine who is right - only who is left.
# - Knowledge is knowing a tomato is a fruit; Wisdom is not putting it in a fruit salad.
# - Evening news is where they begin with 'Good evening', and then proceed to tell you why it isn't.
# - A bus station is where a bus stops. A train station is where a train stops. On my desk, I have a work station.
# - How is it one careless match can start a forest fire, but it takes a whole box to start a campfire?
# - Dolphins are so smart that within a few weeks of captivity, they can train people to stand on the very edge of the pool and throw them fish.
# - I thought I wanted a career, turns out I just wanted pay checks.
# - Whenever I fill out an application, in the part that says "If an emergency, notify:" I put "DOCTOR".
# - I didn't say it was your fault, I said I was blaming you.
# - Behind every successful man is his woman. Behind the fall of a successful man is usually another woman.
# - You do not need a parachute to skydive. You only need a parachute to skydive twice.
# - The voices in my head may not be real, but they have some good ideas!
# - Hospitality: making your guests feel like they're at home, even if you wish they were.
# - I discovered I scream the same way whether I'm about to be devoured by a great white shark or if a piece of seaweed touches my foot.
# - There's a fine line between cuddling and holding someone down so they can't get away.
# - I always take life with a grain of salt, plus a slice of lemon, and a shot of tequila.
# - When tempted to fight fire with fire, remember that the Fire Department usually uses water.
# - You're never too old to learn something stupid.
# - To be sure of hitting the target, shoot first and call whatever you hit the target.
# - If you are supposed to learn from your mistakes, why do some people have more than one child?
# - Light travels faster then sound... which is why most people appear brilliant until you hear them.
# - There is a light at the end of every tunnel, just pray it's not a train.
# - He who feels that he is too small to make a difference has never been bitten by a mosquito.
# - A computer once beat me at chess, but it was no match for me at kick boxing.
# - Expecting the world to treat you fairly because you are good is like expecting the bull not to charge because you are a vegetarian.
# - A successful man makes more money than his woman can spend. A successful woman is one who can find such a man.
# - Laughter is a smile with the volume turned up.
# - You can't expect people to look eye to eye with you if you are looking down on them.
# - Better a diamond with a flaw than a pebble without.
# - People laugh because I'm different, I laugh because they're all the same.
# - A calm sea does not make a skilled sailor.
# - A diplomat is a man who always remembers a woman's birthday but never remembers her age.
# - A fine is a tax for doing wrong. A tax is a fine for doing well.
# - Did Noah include termites on the ark?
# - Doesn't expecting the unexpected make the unexpected become the expected?
# - If pro is the opposite of con, is progress the opposite of congress?
# - If you learn from your mistakes, then why ain't I a genius?
# - What is a "free" gift? Aren't all gifts free?
# - There are two rules for success: 1.) Don't tell all you know.
# - All I ask is a chance to prove money can't make me happy.
# - A diplomat is someone who can tell you to go to hell in such a way that you will look forward to the trip.
# - Before you criticize someone, you should walk a mile in their shoes. That way, when you criticize them, you're a mile away and you have their shoes.
# - Don't be irreplaceable; if you can't be replaced, you can't be promoted.
# - Get a new car for your spouse; it'll be a great trade!
# - He who laughs last thinks slowest.
# - I don't suffer from insanity. I enjoy every minute of it.
# - I need someone really bad. Are you really bad?
# - I just got lost in thought. It was unfamiliar territory.
# - I used to be indecisive. Now I'm not sure.
# - I'm as confused as a baby in a topless bar.
# - If you tell the truth you don't have to remember anything.
# - Jack Kevorkian for White House Physician.
# - Never ask a barber if he thinks you need a haircut.
# - Remember half the people you know are below average.
# - Support bacteria, they're the only culture some people have.
# - The early bird may get the worm, but the second mouse gets the cheese.
# - There are 3 kinds of people: those who can count & those who can't.
# - Time is the best teacher; unfortunately it kills all of its students.
# - When every thing's coming your way, you're in the wrong lane and going the wrong way.
# - When there's a will, I want to be in it.
# - I'm as confused as a baby in a topless bar.
# - Women who seek to be equal to men lack ambition.
# - You can do more with a kind word and a gun than with just a kind word.
# - Doing nothing is very hard to do. You never know when you're finished.
# - Always drink upstream from the herd.
# - Life is ten percent what you make it and ninety percent how you take it!
# - I have kleptomania, but when it gets bad, I take something for it.
# - I may be schizophrenic, but at least I have each other.
# "

# # Esure used directories exist
# mkdir -p ${_LOG_DIR}
# mkdir -p ${_CONFIG_DIR}

# # Determine log file directory
# _LOGFILE=${_LOG_DIR}/$( basename $0 ).log

# if [[ -d /etc/update-motd.d ]]; then
# 	motd_wisdom_file="/etc/update-motd.d/55-wisdom"
# 	neofetch_file="/etc/update-motd.d/50-neofetch"
# elif [[ -d /etc/motd.d ]]; then
# 	motd_wisdom_file="/etc/motd.d/55-wisdom"
# 	neofetch_file="/etc/motd.d/50-neofetch"
# else
# 	system::log_item "No MOTD directory found, NOT installing wisdom."
# fi

# # Set the key locations for the system
# ISSUE_FILE="/etc/issue"

# write_status "🦉 Creating wisdom quotes file: ${RTD_WISDOM_QUOTES}"
# RTD_WISDOM_QUOTES="${_CONFIG_DIR}/kens_quotes.txt"
# touch ${RTD_WISDOM_QUOTES} && system::log_item "✅ Wisdom quotes file created: ${RTD_WISDOM_QUOTES}" || system::log_item "⛔ Failed to create wisdom quotes file: ${RTD_WISDOM_QUOTES}"



# #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# #::::::::::::::                                          ::::::::::::::::::::::
# #::::::::::::::          Execute tasks                   ::::::::::::::::::::::
# #::::::::::::::                                          ::::::::::::::::::::::
# #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# # Set login banner:
# system::distribution_type
# if [[ $dtype == "redhat" ]]; then
# write_status "setup MOTD manually for redhat"

# # Step 1: Create the MOTD update script
# MOTD_SCRIPT_PATH="/usr/local/sbin/update-motd.sh"
# cat << EOF > "$MOTD_SCRIPT_PATH"
# #!/bin/bash
# MOTD_FILE="/etc/motd"
# {
#     ${motd_wisdom_file}
# } > "$MOTD_FILE"
# EOF

# chmod +x "$MOTD_SCRIPT_PATH"

# # Step 2: Create a systemd service file
# SERVICE_PATH="/etc/systemd/system/update-motd.service"
# cat << EOF > "$SERVICE_PATH"
# [Unit]
# Description=Update MOTD

# [Service]
# Type=oneshot
# ExecStart=$MOTD_SCRIPT_PATH
# EOF

# # Step 3: Create a systemd timer file
# TIMER_PATH="/etc/systemd/system/update-motd.timer"
# cat << EOF > "$TIMER_PATH"
# [Unit]
# Description=Runs update-motd every day

# [Timer]
# OnBootSec=5min
# OnUnitActiveSec=24h
# Unit=update-motd.service

# [Install]
# WantedBy=timers.target
# EOF

# # Step 4: Enable and start the timer
# systemctl enable update-motd.timer
# systemctl start update-motd.timer

# system::log_item "Dynamic MOTD setup completed."

# fi




# # Enable the login banner:
# test -L "${ISSUE_FILE}" && rm "${ISSUE_FILE}"
# echo "${_OEM_TTY_LOGIN_BANNER}" > ${ISSUE_FILE}

# # Create Ken's MOTD file with some wisdom:
# system::log_item "Populating Ken's ${RTD_WISDOM_QUOTES} file with some wisdom... "

# cat >> ${RTD_WISDOM_QUOTES} << WEOF
# ${kens_quotes}
# WEOF

# # Set the MOTD to display a random quote from the file:
# if [[ -n "${motd_wisdom_file}" && -n "${RTD_WISDOM_QUOTES}" ]]; then
#     cat > "${motd_wisdom_file}" <<-"EOF"
# 	#!/bin/bash
# 	QuoteFile=RTD_WISDOM_QUOTES
# 	num_lines=$(wc -l < "$QuoteFile")
# 	random_line=$((RANDOM % num_lines + 1))
# 	sed -n "${random_line}p" "$QuoteFile"
# 	EOF

# 	chmod +x "${motd_wisdom_file}"
# 	# Correctly escape the path to handle spaces and special characters
# 	sed -i "s|QuoteFile=RTD_WISDOM_QUOTES|QuoteFile=\"${RTD_WISDOM_QUOTES}\"|" "${motd_wisdom_file}"
# fi

# if [[ -n "${neofetch_file}" ]]; then
#     cat > "${neofetch_file}" <<-"EOF"
# 	#!/bin/bash
# 	neofetch
# 	EOF
# 	chmod +x "${neofetch_file}"
# fi


# # Prepare the system for auto task sequence post build
# system::add_or_remove_login_script --add "/opt/rtd/core/rtd-oem-linux-config.sh"
# system::toggle_oem_auto_elevated_privilege --enable
# system::toggle_oem_auto_login --enable
# system::set_oem_elevated_privilege_gui --enable
# oem::rtd_tools_make_launchers
# oem::register_all_tools

# system::log_item "Create a link to the log directory in the OEM directory: ${_LOG_DIR} to ${_OEM_DIR}/log"
# ln -s -f ${_LOG_DIR} -T ${_OEM_DIR}/log

