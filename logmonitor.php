<?php
	main();	

	function main()
	{

		/****************************************
		 * User-Defined Variables
		 ****************************************/
		$BLOCK_TRIES=3;			// Number of tries before blocking
		$BLOCK_TIL="5 minutes";		// Time limit for blocking
		$SERVICE="ssh";			// The service to be checked
		$PROTOCOL="tcp";		// The protocol of the service
		$LOG_LOC="/var/log/auth.log";	// The location of the log

		/****************************************
		 * Do not touch
		 ****************************************/

		// Regex for the log file
		$SSH = "sshd\[[0-9]+\]: Failed password";
		$SSH_IP=11;

		// Normal variables
		$output = "";
		$ips = array();

		$options = getopt("s:");

		if($options["s"] == "ssh") {
			$pattern = $SSH;
			$ip = $SSH_IP;
		}

		// Grab everything failed attempts from the log file
		exec("tac $LOG_LOC | grep -m 1000 -E \"$pattern\"", &$output);

		for($i = 0; $i < count($output); $i++) {
			$line = explode(" ", $output[$i]);
			if(!isset($ips[$line[$ip]])) {
				$ips[$line[$ip]] = 1;
			} else {
				$ips[$line[$ip]]++;
			}

			if($ips[$line[$ip]] == $BLOCK_TRIES) {
				$found = "";
				exec("iptables -L INPUT | grep -c \"$line[$ip]\"", &$found);
				if($found[0] == 0) { // Check if IP is already blocked				
					blockIP($line[$ip], $PROTOCOL, $SERVICE);
					unBlockIP($line[$ip], $PROTOCOL, $SERVICE, $BLOCK_TIL);
				}
			}
		}
	}

	/****************************************
	 * Function to Block the IP
	 ****************************************/
	function blockIP($ip, $protocol, $service)
	{
		exec("iptables -A INPUT -s \"$ip\" -j DROP");
	}

	/****************************************
	 * Function to set the delay before unblocking the IP
	 ****************************************/
	function unBlockIP($ip, $protocol, $service, $delay)
	{
		$date = "";

		exec("date --date=\"$delay\" +\"%M %H %d %m %u\"", &$date);

		exec("(crontab -l; echo \"$date[0] /rc.d/bin/iptables -D INPUT -s \"$ip\"\") | crontab -");
	}
?>
