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
#::		 This script configures the system to auto login, and run the systen configuration choices menu.
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
# NOTE: this script is run by the power tools system setup and therefore the oem tools are asumed to be present.
#
# 1 - To see options to use the rtd library type: "bash _rtd_library --help"
# 2 - To see usefull documentation on each function in this library: "bash _rtd_library --devhelp or --devhelp-gtk"

if [[ $EUID -ne 0 ]]; then { echo "This script must be run as root" ; exit 1; } ; fi

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Script Settings                 ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Variables that govern the behavior or the script and location of files are

# Base folder structure for optional administrative commandlets and scripts:
# Put a convenient link to the logs where logs are normally found...
# capture the 3 first letters as org TLA (Three Letter Acronym)

# Figure the base TLA for the organization
export _SCRIPTNAME=$(basename $0)
export _TLA=${_SCRIPTNAME:0:3}
_lib_path="/opt/${_TLA,,}/core/_rtd_library"
_faillog="/opt/${_TLA,,}/faillog.log"

# Load the RTD library (once loaded, all functions are available)
if [ -f ${_lib_path} ]; then
	source ${_lib_path} || { echo "💥 CRITICAL ERROR: Required library ( ${_lib_path} ) not found." >> ${_faillog} ; exit 1; }
else
	echo "💥 CRITICAL ERROR: Required library not found." >> ${_faillog}
	exit 1
fi

kens_quotes="
- Do not argue with an idiot. He will drag you down to his level and beat you with experience.
- Going to church doesn't make you a Christian any more than standing in a garage makes you a car.
- The last thing I want to do is hurt you. But it's still on the list.
- If I agreed with you we'd both be wrong.
- We never really grow up, we only learn how to act in public.
- War does not determine who is right - only who is left.
- Knowledge is knowing a tomato is a fruit; Wisdom is not putting it in a fruit salad.
- Evening news is where they begin with 'Good evening', and then proceed to tell you why it isn't.
- A bus station is where a bus stops. A train station is where a train stops. On my desk, I have a work station.
- How is it one careless match can start a forest fire, but it takes a whole box to start a campfire?
- Dolphins are so smart that within a few weeks of captivity, they can train people to stand on the very edge of the pool and throw them fish.
- I thought I wanted a career, turns out I just wanted pay checks.
- Whenever I fill out an application, in the part that says "If an emergency, notify:" I put "DOCTOR".
- I didn't say it was your fault, I said I was blaming you.
- Behind every successful man is his woman. Behind the fall of a successful man is usually another woman.
- You do not need a parachute to skydive. You only need a parachute to skydive twice.
- The voices in my head may not be real, but they have some good ideas!
- Hospitality: making your guests feel like they're at home, even if you wish they were.
- I discovered I scream the same way whether I'm about to be devoured by a great white shark or if a piece of seaweed touches my foot.
- There's a fine line between cuddling and holding someone down so they can't get away.
- I always take life with a grain of salt, plus a slice of lemon, and a shot of tequila.
- When tempted to fight fire with fire, remember that the Fire Department usually uses water.
- You're never too old to learn something stupid.
- To be sure of hitting the target, shoot first and call whatever you hit the target.
- If you are supposed to learn from your mistakes, why do some people have more than one child?
- Light travels faster then sound... which is why most people appear brilliant until you hear them.
- There is a light at the end of every tunnel, just pray it's not a train.
- He who feels that he is too small to make a difference has never been bitten by a mosquito.
- A computer once beat me at chess, but it was no match for me at kick boxing.
- Expecting the world to treat you fairly because you are good is like expecting the bull not to charge because you are a vegetarian.
- A successful man makes more money than his woman can spend. A successful woman is one who can find such a man.
- Laughter is a smile with the volume turned up.
- You can't expect people to look eye to eye with you if you are looking down on them.
- Better a diamond with a flaw than a pebble without.
- People laugh because I'm different, I laugh because they're all the same.
- A calm sea does not make a skilled sailor.
- A diplomat is a man who always remembers a woman's birthday but never remembers her age.
- A fine is a tax for doing wrong. A tax is a fine for doing well.
- Did Noah include termites on the ark?
- Doesn't expecting the unexpected make the unexpected become the expected?
- If pro is the opposite of con, is progress the opposite of congress?
- If you learn from your mistakes, then why ain't I a genius?
- What is a "free" gift? Aren't all gifts free?
- There are two rules for success: 1.) Don't tell all you know.
- All I ask is a chance to prove money can't make me happy.
- A diplomat is someone who can tell you to go to hell in such a way that you will look forward to the trip.
- Before you criticize someone, you should walk a mile in their shoes. That way, when you criticize them, you're a mile away and you have their shoes.
- Don't be irreplaceable; if you can't be replaced, you can't be promoted.
- Get a new car for your spouse; it'll be a great trade!
- He who laughs last thinks slowest.
- I don't suffer from insanity. I enjoy every minute of it.
- I need someone really bad. Are you really bad?
- I just got lost in thought. It was unfamiliar territory.
- I used to be indecisive. Now I'm not sure.
- I'm as confused as a baby in a topless bar.
- If you tell the truth you don't have to remember anything.
- Jack Kevorkian for White House Physician.
- Never ask a barber if he thinks you need a haircut.
- Remember half the people you know are below average.
- Support bacteria, they're the only culture some people have.
- The early bird may get the worm, but the second mouse gets the cheese.
- There are 3 kinds of people: those who can count & those who can't.
- Time is the best teacher; unfortunately it kills all of its students.
- When every thing's coming your way, you're in the wrong lane and going the wrong way.
- When there's a will, I want to be in it.
- I'm as confused as a baby in a topless bar.
- Women who seek to be equal to men lack ambition.
- You can do more with a kind word and a gun than with just a kind word.
- Doing nothing is very hard to do. You never know when you're finished.
- Always drink upstream from the herd.
- Life is ten percent what you make it and ninety percent how you take it!
- I have kleptomania, but when it gets bad, I take something for it.
- I may be schizophrenic, but at least I have each other.
"

# Esure used directories exist
mkdir -p ${_LOG_DIR}
mkdir -p ${_CONFIG_DIR}

# Determine log file directory
_LOGFILE=${_LOG_DIR}/$( basename $0 ).log

if [[ -d /etc/update-motd.d ]]; then
	motd_wisdom_file="/etc/update-motd.d/55-wisdom"
	neofetch_file="/etc/update-motd.d/50-neofetch"
elif [[ -d /etc/motd.d ]]; then
	motd_wisdom_file="/etc/motd.d/55-wisdom"
	neofetch_file="/etc/motd.d/50-neofetch"
else
	system::log_item "No MOTD directory found, NOT installing wisdom."
fi

# Set the key locations for the system
ISSUE_FILE="/etc/issue"

write_status "🦉 Creating wisdom quotes file: ${RTD_WISDOM_QUOTES}"
RTD_WISDOM_QUOTES="${_CONFIG_DIR}/kens_quotes.txt"
touch ${RTD_WISDOM_QUOTES} && system::log_item "✅ Wisdom quotes file created: ${RTD_WISDOM_QUOTES}" || system::log_item "⛔ Failed to create wisdom quotes file: ${RTD_WISDOM_QUOTES}"



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::          Execute tasks                   ::::::::::::::::::::::
#::::::::::::::                                          ::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Set login banner:
system::distribution_type
if [[ $dtype == "redhat" ]]; then
write_status "setup MOTD manually for redhat"

# Step 1: Create the MOTD update script
MOTD_SCRIPT_PATH="/usr/local/sbin/update-motd.sh"
cat << EOF > "$MOTD_SCRIPT_PATH"
#!/bin/bash
MOTD_FILE="/etc/motd"
{
    ${motd_wisdom_file}
} > "$MOTD_FILE"
EOF

chmod +x "$MOTD_SCRIPT_PATH"

# Step 2: Create a systemd service file
SERVICE_PATH="/etc/systemd/system/update-motd.service"
cat << EOF > "$SERVICE_PATH"
[Unit]
Description=Update MOTD

[Service]
Type=oneshot
ExecStart=$MOTD_SCRIPT_PATH
EOF

# Step 3: Create a systemd timer file
TIMER_PATH="/etc/systemd/system/update-motd.timer"
cat << EOF > "$TIMER_PATH"
[Unit]
Description=Runs update-motd every day

[Timer]
OnBootSec=5min
OnUnitActiveSec=24h
Unit=update-motd.service

[Install]
WantedBy=timers.target
EOF

# Step 4: Enable and start the timer
systemctl enable update-motd.timer
systemctl start update-motd.timer

system::log_item "Dynamic MOTD setup completed."

fi




# Enable the login banner:
test -L "${ISSUE_FILE}" && rm "${ISSUE_FILE}"
echo "${_OEM_TTY_LOGIN_BANNER}" > ${ISSUE_FILE}

# Create Ken's MOTD file with some wisdom:
system::log_item "Populating Ken's ${RTD_WISDOM_QUOTES} file with some wisdom... "

cat >> ${RTD_WISDOM_QUOTES} << WEOF
${kens_quotes}
WEOF

# Set the MOTD to display a random quote from the file:
if [[ -n "${motd_wisdom_file}" && -n "${RTD_WISDOM_QUOTES}" ]]; then
    cat > "${motd_wisdom_file}" <<-"EOF"
	#!/bin/bash
	QuoteFile=RTD_WISDOM_QUOTES
	num_lines=$(wc -l < "$QuoteFile")
	random_line=$((RANDOM % num_lines + 1))
	sed -n "${random_line}p" "$QuoteFile"
	EOF

	chmod +x "${motd_wisdom_file}"
	# Correctly escape the path to handle spaces and special characters
	sed -i "s|QuoteFile=RTD_WISDOM_QUOTES|QuoteFile=\"${RTD_WISDOM_QUOTES}\"|" "${motd_wisdom_file}"
fi

if [[ -n "${neofetch_file}" ]]; then
    cat > "${neofetch_file}" <<-"EOF"
	#!/bin/bash
	neofetch
	EOF
	chmod +x "${neofetch_file}"
fi


# Prepare the system for auto task sequnce post build
system::add_or_remove_login_script --add "/opt/rtd/core/rtd-oem-linux-config.sh"
system::toggle_oem_auto_elevated_privilege --enable
system::toggle_oem_auto_login --enable
system::set_oem_elevated_privilege_gui --enable
oem::rtd_tools_make_launchers
oem::register_all_tools

system::log_item "Create a link to the log directory in the OEM directory: ${_LOG_DIR} to ${_OEM_DIR}/log"
ln -s -f ${_LOG_DIR} -T ${_OEM_DIR}/log

