##############################################
# LOG MONITORING
#
# Authors:
#	Karl Castillo
#	Daniel Khatkar
##############################################

##############################################
# USER VARIABLES
##############################################
BLOCK_TRIES="3"			# How many tries before blocking
BLOCK_DELAY="10"		# The delay in seconds to determine blocking
BLOCK_TIL="10"			# The amount of time to block the IP
SERVICE="ssh"			# Port/Service to be checked
PROTOCOL="tcp"			# Protocol the service will be on
LOG_LOC="/var/log/auth.log"	# The location of the log file

##############################################
# DO NOT TOUCH
##############################################

# SERVICE LOG REGEXP
SSH="sshd\[[0-9]+\]: Failed password"
	
# NORMAL VARIABLES
TRIES=0
IFS=$'\n'

#############################################
# HELPER FUNCTIONS
#############################################

# ADDS A RULE TO THE IP TABLE
function blockIP()
{
	iptables -A INPUT -s $@ -p $PROTOCOL --dport $SERVICE -j DROP
}

# REMOVES THE RULE FROM THE IP TABLE AFTER 10 DAYS
function unblockIP()
{
	DATE=`date +"%M %k %d %m %u" --date="+$BLOCK_TIL days"`

	(crontab -l; echo "$DATE /unblock.sh $SERVICE $IP_ADDRESS") | crontab -
}

# PARSE THE SSH LOG FILE
function sshMonitor()
{	
	for LINE in `grep -E "$@" $LOG_LOC`
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
		hwrite ipblock $IP_ADDRESS $TIMESTAMP TRIES 0 
	done
}

function main()
{
	# Check if file exists
	if [ ! -f $LOG_LOC ]
	then
		echo "$LOG_LOC: does not exist"
		return 1
	fi

	# Check if file can be read
	if [ ! -r $LOG_LOG ]
	then
		echo "$LOGLOC: cannot read file"
		return 2
	fi

	# Determine type of service
	if [ "$SERVICE" == "ssh" ]
	then
		sshMonitor $SSH
	fi
}

function hinit() {
    rm -f hashmap.$1
}

function hwrite() {
    echo "$2 $3 $4 $5" >> hashmap.$1
}

function hread() {
    grep "^$2 " hashmap.$1 | awk '{ print $2 };'
}

#hinit ipblock
#hread ipblock IP
#############################################
# Start Main
#############################################
main
