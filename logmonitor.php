<?php
	main();	

	function main()
	{

		/****************************************
		 * User-Defined Variables
		 ****************************************/
		$BLOCK_TRIES=3;			// Number of tries before blocking
		$BLOCK_TIL="1 minute";		// Time limit for blockinig
		$BLOCK_DELAY="50";		// Minutes
		$SERVICE="ssh";			// The service to be checked
		$PROTOCOL="tcp";		// The protocol of the service
		$LOG_LOC="/var/log/secure";	// The location of the log

		/****************************************
		 * Do not touch
		 ****************************************/

		// Regex for the log file
		$SSH = "sshd\[[0-9]+\]: Failed password";
		$SSH_IP=11;
		$SSH_TIME=3;

		// Normal variables
		$output = "";
		$ips = array();

		$options = getopt("s:");

		if($options["s"] == "ssh") {
			$pattern = $SSH;
			$ip = $SSH_IP;
			$time = $SSH_TIME;
		}

		// Grab everything failed attempts from the log file
		exec("grep -E \"$pattern\" $LOG_LOC", &$output);
		date_default_timezone_set('America/Vancouver');

		for($i = 0; $i < count($output); $i++) {
			$line = explode(" ", $output[$i]);
			$time_1 = strtotime("now");
			$time_2 = strtotime("$line[$time]");
			$delay = date("s", $time_1 - $time_2);

			if($delay <= $BLOCK_DELAY) {
				if(!isset($ips[$line[$ip]])) {
					$ips[$line[$ip]] = 1;
				} else {
					$ips[$line[$ip]]++;
				}

				if($ips[$line[$ip]] == $BLOCK_TRIES) {				
					blockIP($line[$ip]);
					unBlockIP($line[$ip], $BLOCK_TIL);
				}
			}
		}
	}

	/****************************************
	 * Function to Block the IP
	 ****************************************/
	function blockIP($ip)
	{
		exec("/sbin/iptables -A INPUT -s \"$ip\" -j DROP");
	}

	/****************************************
	 * Function to set the delay before unblocking the IP
	 ****************************************/
	function unBlockIP($ip, $delay)
	{
		$date = "";

		exec("date --date=\"$delay\" +\"%M %H %d %m %u\"", &$date);

		exec("(crontab -l; echo \"$date[0] sh /root/LogMonitor/unblock.sh $ip\") | crontab -");
	}
?>
