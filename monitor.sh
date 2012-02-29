#############################################
# LOG MONITORING
#
# Authors:
#	Karl Castillo
#	Daniel Khatkar
##############################################

##############################################
# USER VARIABLES
##############################################
BLOCK_TRIES="3"
BLOCK_DELAY="10s"
BLOCK_TIL="1d"
OS="ubuntu"
SERVICE="ssh"
LOG_LOC="/var/log/auth.log"

##############################################
# DO NOT TOUCH
##############################################

# SERVICE LOG REGEXP
SSH="sshd\[[0-9]+\]: Failed password"

#NORMAL VARIABLES
COUNTER=0
TRY_COUNTER=0

if [[ $SERVICE="ssh" ]]
then
	PATTERN=$SSH
	sshMonitor
fi

function sshMonitor()
{
	for line in `grep -E "$PATTERN" $LOG_LOC`
	do
		echo 'line ='${line}
		echo 'counter = '${COUNTER}

		case ${COUNTER} in
			2)	if [[ "$BLOCK_DELAY" =~ ^[0-9]+s$ ]]
				then
					echo "seconds"
				fi

				if [[ "$BLOCK_DELAY" =~ ^[0-9]+m$ ]]
				then
					echo "minutes"
				fi

				if [[ "$BLOCK_DELAY" =~ ^[0-9]+h$ ]]
				then
					echo "hours"
				fi

				COUNTER=`expr $COUNTER + 1`
			;;
			10) 	IP_ADDRESS=$line
				COUNTER=`expr $COUNTER + 1`
			;;
			13) 	IP_ADDRESS=""
				COUNTER=0
			;;
			*)	COUNTER=`expr $COUNTER + 1`
		esac
	done
}
