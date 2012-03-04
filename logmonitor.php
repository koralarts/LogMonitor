<?php
	main();	

	function main()
	{

		/****************************************
		 * User-Defined Variables
		 ****************************************/
		$BLOCK_TRIES=3;			// Number of tries before blocking
		$BLOCK_TIL="1 minute";		// Time limit for blocking
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

		foreach($output as $value) {
			$line = explode(" ", $value);
			if(!isset($ips[$line[$ip]])) {
				$ips[$line[$ip]] = 0;
			} else {
				$ips[$line[$ip]]++;
			}

			if($ips[$line[$ip]] == $BLOCK_TRIES) {
				blockIP($line[$ip], $PROTOCOL, $SERVICE);
				unBlockIP($line[$ip], $PROTOCOL, $SERVICE, $BLOCK_TIL);
			}
		}
	}

	function blockIP($ip, $protocol, $service)
	{
		exec("iptables -A INPUT -s \"$ip\" -p \"$protocol\" --dport \"$service\" -j DROP");
	}

	function unBlockIP($ip, $protocol, $service, $delay)
	{
		$date = "";

		exec("date --date=\"$delay\" +\"%M %H %d %m %u\"", &$date);

		exec("(crontab -l; echo \"$date[0] /rc.d/bin/iptables -D INPUT -s \"$ip\" -p \"$protocol\" --dport \"$service\"\") | crontab -");
	}
?>
