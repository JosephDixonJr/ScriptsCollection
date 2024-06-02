#!/bin/bash
# Variables
HOST="$1"
SERVER="$2"
IP="$3"

# Configuration Files
FORWARDZONE=""
REVERSEZONE=""

# Server Restart Commands
RESTARTDNS="/usr/bin/systemctl restart bind9"

# This script should be run as root or with sudo.
# Get User Input
# HOST
if [ -z "$HOST" ]; then
	/usr/bin/echo "Please supply the info of the new host."
	/usr/bin/echo "This new host will be placed underneath the initial host."
	/usr/bin/echo "HOST should be equal to the hostname of the host machine."
	/usr/bin/echo "Example HOST: $(uname -n)"
	/usr/bin/echo -n "Please enter the \"HOST\": "
	read HOST
fi

# SERVER
if [ -z "$SERVER" ] && [ -z "$IP" ]; then
	/usr/bin/echo "SERVER should be equal to the name of the service being hosted."
	/usr/bin/echo "If setting up certificate for host only, leave SERVER blank."
	/usr/bin/echo "Example SERVER: shaarli"
	/usr/bin/echo -n "Please enter the \"SERVER\": "
	read SERVER
fi

# IP
if [ -z "$IP" ]; then
	/usr/bin/echo "IP should be equal to ip of the host machine."
	/usr/bin/echo "Example IP: 192.168.1.140"
	/usr/bin/echo -n "Please enter the \"IP\": "
	read IP
fi

# Check for Null Values

# Host Name - Checking for a single lower case word.
case $HOST in
"")
	/usr/bin/echo "You did not enter a hostname."
	exit 0
	;;
$(awk '/^[\-a-z0-9]*$/' <<<${HOST})) /usr/bin/echo "You set the hostname to:		$HOST" ;;
*)
	/usr/bin/echo "That is not a valid hostname."
	exit 0
	;;
esac

# Server Name - Checking for a single lower case word.
case $SERVER in
"")
	/usr/bin/echo "You did not enter a Server Name."
	exit 0
	;;
$(awk '/^[\-a-z0-9]*$/' <<<${SERVER})) /usr/bin/echo "You set the server name to:		$SERVER" ;;
*)
	/usr/bin/echo "That is not a valid server name."
	exit 0
	;;
esac

# IP Address - Checking for 3 sets of 1 to 3 numbers separated by periods.
case $IP in
"")
	/usr/bin/echo "You did not enter an ip address."
	exit 0
	;;
$(awk '/^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/' <<<${IP})) /usr/bin/echo "You set the IP address to:		$IP" ;;
*)
	/usr/bin/echo "You did not enter a valid ip address."
	exit 0
	;;
esac

# Update DNS Entries given Above Data
/usr/bin/echo "Adding DNS Entries for $SERVER on $HOST located at $IP"

# Local DNS
/usr/bin/echo "Adding DNS Entries for $SERVER."
/usr/bin/sed -e "/^$HOST\t*IN\tA\t$IP/a $SERVER.$HOST\t\tIN\tA\t$IP" -i "$FORWARDZONE"
/usr/bin/sed -e "/${IP#*.1.}\tIN\tPTR\t$HOST.lab./a ${IP#*.1.}\tIN\tPTR\t$SERVER.$HOST.lab" -i "$REVERSEZONE"
/usr/bin/sed -e "/$IP\t*$HOST.lab\t*$HOST/a $IP\t\t$SERVER.$HOST.lab\t\t$SERVER.$HOST" -i /etc/hosts

# Restart Services
/usr/bin/bash -c "$RESTARTDNS"

/usr/bin/echo "DNS Entries have been updated on $(uname -n)."

exit 0
