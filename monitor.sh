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
BLOCK_TIL="1"			# The amount of time to block the IP
SERVICE="ssh"			# Port/Service to be checked
PROTOCOL="tcp"			# Protocol the service will be on
LOG_LOC="/var/log/auth.log"	# The location of the log file
HASH_FILE="hash.map"		# The location of the hash map file
OS="ubuntu"

##############################################
# DO NOT TOUCH
##############################################

# SERVICE LOG REGEXP
SSH="sshd\[[0-9]+\]: Failed password"
	
# NORMAL VARIABLES
IFS=$'\n'

#############################################
# HELPER FUNCTIONS
#############################################

# ADDS A RULE TO THE IP TABLE
function blockIP()
{
	iptables -A INPUT -s $1 -p $PROTOCOL --dport $SERVICE -j DROP
}

# REMOVES THE RULE FROM THE IP TABLE AFTER n DAYS
function unblockIP()
{
	DATE=`date --date="$BLOCK_TIL days" +"%M %k %d %m %u"`

	(crontab -l; echo "$DATE /unblock.sh $HASH_FILE $PROTOCOL $SERVICE $IP_ADDRESS") | crontab -
}

function hinit() 
{
	rm -f hashmap.map
}

# WRITE NEW ELEMENT INTO THE HASH FILE
function hwrite() 
{
	echo "$1 $2 $3 $4" >> $HASH_FILE
}

function hoverwrite()
{
	sed "$(printf ""$LINE_NUM"i%c\n$1 $2 $3 $4\n" '\')" $HASH_FILE > $HASH_FILE
}

# READ THE SPECIFIC LINE IN THE HASH FILE
function hread() 
{
	for LINE in `grep "^$1" $HASH_FILE`
	do
	eval `echo $LINE | awk -F "|" '
			BEGIN {
				HASH_LINE=""
			}				
			{ HASH_LINE=$1 }
			END {
				printf "HASH_LINE=\"%s\"\n", HASH_LINE
			}				
			'`
	done
}

# PARSE THE LINE READ
function hparse()
{
	eval `echo $1 | awk '
			BEGIN {
				H_IP_ADDRESS=""
				H_TIMESTAMP=""
				H_TRIES=""
				H_BLOCKED=""
			}
			{ H_IP_ADDRESS=$1 }
			{ H_TIMESTAMP=$2 }
			{ H_TRIES=$3 }
			{ H_BLOCKED=$4 }
			END {
				printf "H_IP_ADDRESS=\"%s\"\n", H_IP_ADDRESS
				printf "H_TIMESTAMP=\"%s\"\n", H_TIMESTAMP
				printf "H_TRIES=\"%s\"\n", H_TRIES
				printf "H_BLOCKED=\"%s\"\n", H_BLOCKED			
			}'`

}

# PEEK IF THE ELEMENT EXISTS
function hpeek()
{
	LINE_NUM=`grep -n "^$1" $HASH_FILE | sed -n 's/^\([0-9]*\)[:].*/\1/p'`

	if [ -z $LINE_NUM ]
	then 
		return 0
	fi

	return 1
}

# PARSE THE SSH LOG FILE
function sshMonitor()
{	
	date=`date --date="1 minute ago" +"%a %b %d %H:%M"`

	grep -E "$date:[0-9]{2} $OS $@" $LOG_LOC

	for LINE in `grep -E "$date:[0-9]{2} $OS $@" $LOG_LOC`
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
		hpeek $IP_ADDRESS
		PEEK=$?

		if [ $PEEK == 0 ]
		then
			hwrite $IP_ADDRESS $TIMESTAMP $TRIES
			continue
		fi

		echo 

		if [ $PEEK == 1 ]
		then
			hread $IP_ADDRESS
		fi

		hparse $HASH_LINE
		
		H_TRIES=$((H_TRIES + 1))

		S_TIME=`date -d "$TIMESTAMP" +%s`
		E_TIME=`date -d "$H_TIMESTAMP" +%s`

		# Caclculate Delay
		if [ $S_TIME > $E_TIME ]
		then
			DELAY="$(($((S_TIME - E_TIME)) / 10000))"
		fi

		if [ $S_TIME < $E_TIME ]
		then
			DELAY="$(($((E_TIME - S_TIME)) / 10000))"
		fi

		# Check if the ip needs to be blocked and update
		if [[ $DELAY < $BLOCK_DELAY ]]
		then
			if [[ $H_TRIES == $BLOCK_TRIES ]]
			then 
				if [[ $H_BLOCKED == 0 ]]
				then
					TRIES=0
					blockIP $IP_ADDRESS
					hoverwrite $IP_ADDRESS $TIMESTAMP $TRIES
					#unblockIP
				fi
			fi
		fi

		# Update hash line
		if [[ $DELAY > $BLOCK_DELAY ]]
		then
			if [[ $H_TRIES == $BLOCK_TRIES ]]
			then
				hoverwrite $IP_ADDRESS $TIMESTAMP $TRIES
			fi
		fi
	done
}

function main()
{
	if [ ! -f $HASH_FILE ]
	then
		echo "Creating $HASH_FILE"
		touch $HASH_FILE
	fi

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
#############################################
# Start Main
#############################################
main
