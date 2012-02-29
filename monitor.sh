#############################################
# LOG MONITORING
#
# Authors:
#	Karl Castillo
#	Daniel Khatkar
#####################################
#########

##############################################
# USER VARIABLES
##############################################
BLOCK_TRIES="3"			# How many tries before blocking
BLOCK_DELAY="10"		# The delay in seconds
BLOCK_TIL="1d"			# The amount of time to block the IP
OS="ubuntu"			# The current OS
SERVICE="ssh"			# Service to be checked
LOG_LOC="/var/log/auth.log"	# The location of the log file

##############################################
# DO NOT TOUCH
##############################################

# SERVICE LOG REGEXP
SSH="sshd\[[0-9]+\]: Failed password"
	
#NORMAL VARIABLES
TRIES=0
IFS=$'\n'

#############################################
# HELPER FUNCTIONS
#############################################
function sshMonitor()
{	
	for LINE in `grep -E "$PATTERN" $LOG_LOC`
	do
		eval `echo $LINE | awk '
				BEGIN {
					IP_ADDRESS=""
					TIMESTAMP=""
				} 
				{ IP_ADDRESS=$11 }
				{ TIMESTAMP=$3 }
				END {
					printf "IP_ADDRESS=\"%s\"\n", IP_ADDRESS
					printf "TIMESTAMP=\"%s\"\n", TIMESTAMP
				}
				'`
		echo "============================"
		echo "IP_ADDRESS = $IP_ADDRESS"
		echo "TIMESTAMP = $TIMESTAMP"
		echo "============================"
	done
}

# Check if file exists
if [ ! -f $LOG_LOC ]
then
	echo "$LOG_LOC: does not exist"
	return 1
fi

# Check if file can be read
if [ ! -r $LOG_LOG]
then
	echo "$LOGLOC: cannot read file"
	return 2
fi

# Determine type of service
if [[ $SERVICE="ssh" ]]
then
	PATTERN=$SSH
	sshMonitor
fi
