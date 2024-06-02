#!/bin/bash
# Variables
HOST="$1"
SERVER="$2"
IP="$3"
SERIES="$4"
ISOLATED="$5"

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

# Check for Null or incorrect values.

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
	/usr/bin/echo "Assuming This is a Host Entry..."
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
if [ -z "${SERVER}" ]; then
	/usr/bin/echo "Removing DNS Entries for $HOST located at $IP."
else
	/usr/bin/echo "Removing DNS Entries for $SERVER on $HOST located at $IP."
fi

# Local DNS

if [ -z "${SERVER}" ]; then
	/usr/bin/echo "Removing Local DNS Entries for $HOST."
else
	/usr/bin/echo "Removing Local DNS Entries for $SERVER."
fi

# If Server is not null remove a server.host entry.
# If Server is not not null remove a host entry.
if [ -z "${SERVER}" ]; then
	if [ -z "$SERIES" ]; then
		echo "You are about to delete a host entry."
		echo "Is this the first of a series of hosts?"
		echo "[Y]es/[N]o?"
		read SERIES
	fi
	case $SERIES in
	"y" | "Y" | "yes" | "Yes")
		echo "Removing Host entry and Section title..."
		/usr/bin/sed -e:b -e "$!{N;2,1bb" -e\} -e "/\n$HOST\t*IN\tA\t$IP/!P;D" -i "$FORWARDZONE"
		/usr/bin/sed -e "/$HOST\t*IN\tA\t$IP/d" -i "$FORWARDZONE"
		/usr/bin/sed -e:b -e "$!{N;2,1bb" -e\} -e "/\n${IP#*.1.}\tIN\tPTR\t$HOST.lab/!P;D" -i "$REVERSEZONE"
		/usr/bin/sed -e "/${IP#*.1.}\tIN\tPTR\t$HOST.lab/d" -i "$REVERSEZONE"
		/usr/bin/sed -e:b -e "$!{N;2,1bb" -e\} -e "/\n$IP\t*$HOST.lab\t*$HOST/!P;D" -i /etc/hosts
		/usr/bin/sed -e "/$IP\t*$HOST.lab\t*$HOST/d" -i /etc/hosts
		;;

	"n" | "N" | "no" | "No")
		if [ -z "$ISOLATED" ]; then
			echo "Is this an isolated host?"
			echo "[Y]es/[N]o?"
			read ISOLATED
		fi
		case $ISOLATED in
		"y" | "Y" | "yes" | "Yes")
			echo "Removing Host entry..."
			/usr/bin/sed -e "/$HOST\t*IN\tA\t$IP/,+1d" -i "$FORWARDZONE"
			/usr/bin/sed -e "/${IP#*.1.}\tIN\tPTR\t$HOST.lab/,+1d" -i "$REVERSEZONE"
			/usr/bin/sed -e "/$IP\t*$HOST.lab\t*$HOST/,+1d" -i /etc/hosts
			;;

		"n" | "N" | "no" | "No")
			echo "Removing Host entry..."
			/usr/bin/sed -e "/$HOST\t*IN\tA\t$IP/d" -i "$FORWARDZONE"
			/usr/bin/sed -e "/${IP#*.1.}\tIN\tPTR\t$HOST.lab/d" -i "$REVERSEZONE"
			/usr/bin/sed -e "/$IP\t*$HOST.lab\t*$HOST/d" -i /etc/hosts
			;;

		*)
			echo "That is not a valid answer."
			echo "Quitting operation..."
			exit 0
			;;

		esac
		;;

	*)
		echo "That is not a valid answer."
		echo "Quitting operation..."
		exit 0
		;;

	esac
else
	/usr/bin/sed -e "/$SERVER.$HOST\t\tIN\tA\t$IP/d" -i "$FORWARDZONE"
	/usr/bin/sed -e "/${IP#*.1.}\tIN\tPTR\t$SERVER.$HOST.lab/d" -i "$REVERSEZONE"
	/usr/bin/sed -e "/$IP\t\t$SERVER.$HOST.lab\t\t$SERVER.$HOST/d" -i /etc/hosts
fi

# Restart Services
/usr/bin/bash -c "$RESTARTDNS"

/usr/bin/echo "DNS Entries have been Removed on $(uname -n)."

exit 0
