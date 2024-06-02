#!/bin/bash
# Variables
INITHOST="$1"
INITSERVER="$2"
INITIP="$3"
HOST="$4"
IP="$5"
SERIES="$6"
TITLE="$7"

# Configuration Files
FORWARDZONE=""
REVERSEZONE=""

# Server Restart Commands
RESTARTDNS="/usr/bin/systemctl restart bind9"

# This script should be run as root or with sudo.
# Get User Input for Initial Host
# only if there are no supplied
# Initial HOST
if [ -z "$INITHOST" ]; then
	/usr/bin/echo "Please supply the info of the inital host or server."
	/usr/bin/echo "The new host will be placed underneath this host or server."
	/usr/bin/echo "HOST should be equal to the hostname of the host machine."
	/usr/bin/echo "Example HOST: $(uname -n)"
	/usr/bin/echo -n "Please enter the \"HOST\": "
	read INITHOST
fi

# Initial SEVER
if [ -z "$INITSERVER" ] && [ -z "$INITIP" ]; then
	/usr/bin/echo "SERVER should be equal to the name of the service being hosted."
	/usr/bin/echo "If setting up certificate for host only, leave SERVER blank."
	/usr/bin/echo "Example SERVER: shaarli"
	/usr/bin/echo -n "Please enter the \"SERVER\": "
	read INITSERVER
fi

# Initial IP
if [ -z "$INITIP" ]; then
	/usr/bin/echo "IP should be equal to ip of the host machine."
	/usr/bin/echo "Example IP: 192.168.1.140"
	/usr/bin/echo -n "Please enter the \"IP\": "
	read INITIP
fi

# Check for Null or incorrect values.

# Host Name - Checking for a single lower case word.
case $INITHOST in
"")
	/usr/bin/echo "You did not enter a hostname."
	exit 0
	;;
$(awk '/^[\-a-z0-9]*$/' <<<${INITHOST})) /usr/bin/echo "You set the hostname to:		$INITHOST" ;;
*)
	/usr/bin/echo "That is not a valid hostname."
	exit 0
	;;
esac

# Server Name - Checking for a single lower case word.
case $INITSERVER in
"")
	/usr/bin/echo "You did not enter a Server Name."
	/usr/bin/echo "Assuming This is a Host Entry..."
	;;
$(awk '/^[\-a-z0-9]*$/' <<<${INITSERVER})) /usr/bin/echo "You set the server name to:	$INITSERVER" ;;
*)
	/usr/bin/echo "That is not a valid server name."
	exit 0
	;;
esac

# IP Address - Checking for 3 sets of 1 to 3 numbers separated by periods.
case $INITIP in
"")
	/usr/bin/echo "You did not enter an ip address."
	exit 0
	;;
$(awk '/^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/' <<<${INITIP})) /usr/bin/echo "You set the IP address to:		$INITIP" ;;
*)
	/usr/bin/echo "You did not enter a valid ip address."
	exit 0
	;;
esac

# Get User Input for New Host

# HOST
if [ -z "$HOST" ]; then
	/usr/bin/echo "Please supply the info of the new host."
	/usr/bin/echo "This new host will be placed underneath the initial host."
	/usr/bin/echo "HOST should be equal to the hostname of the host machine."
	/usr/bin/echo "Example HOST: $(uname -n)"
	/usr/bin/echo -n "Please enter the \"HOST\": "
	read HOST
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

# IP Address - Checking for 3 sets of 1 to 3 numbers separated by periods.
case $IP in
"")
	/usr/bin/echo "You did not enter a ip address."
	exit 0
	;;
$(awk '/^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/' <<<${IP})) /usr/bin/echo "You set the IP address to:		$IP" ;;
*)
	/usr/bin/echo "You did not enter a valid ip address."
	exit 0
	;;
esac

# Update DNS Entries given Above Data
/usr/bin/echo "Adding DNS Entries for $HOST located at $IP"

# Local DNS
# Check if the Initial Entry was a Server
if [ -z "$INITSERVER" ]; then
	# Check if the host is the first of a series
	if [ -z "$SERIES" ]; then
		echo "Is this the first of a series of hosts?"
		echo "[Y]es/[N]o?"
		read SERIES
	fi
	case $SERIES in
	"y" | "Y" | "yes" | "Yes")
		if [ -z "$TITLE" ]; then
			echo "Please supply series title"
			read TITLE
		fi
		case $TITLE in
		"")
			echo "You have not entered a title"
			exit 0
			;;

		$(awk '/^[A-Z].*$/' <<<${TITLE}))
			echo "This will be the series title:"
			echo "$TITLE"
			;;

		*)
			echo "This is not a valid title"
			exit 0
			;;

		esac
		#;;

		/usr/bin/sed -e "/$INITHOST\t*IN\tA\t$INITIP/a\ \n; $TITLE" -i "$FORWARDZONE"
		/usr/bin/sed -e "/$TITLE/a $HOST\t\t\tIN\tA\t$IP" -i "$FORWARDZONE"
		/usr/bin/sed -e "/${INITIP#*.1.}\tIN\tPTR\t$INITHOST.lab./a\ \n; $TITLE" -i "$REVERSEZONE"
		/usr/bin/sed -e "/$TITLE/a ${IP#*.1.}\tIN\tPTR\t$HOST.lab." -i "$REVERSEZONE"
		/usr/bin/sed -e "/$INITIP\t*$INITHOST.lab\t*$INITHOST/a\ \n# $TITLE" -i /etc/hosts
		/usr/bin/sed -e "/$TITLE/a $IP\t\t$HOST.lab\t\t\t$HOST" -i /etc/hosts
		;;

	"n" | "N" | "no" | "No")
		/usr/bin/sed -e "/$INITHOST\t*IN\tA\t$INITIP/a\ \n$HOST\t\t\tIN\tA\t$IP" -i "$FORWARDZONE"
		/usr/bin/sed -e "/${INITIP#*.1.}\tIN\tPTR\t$INITHOST.lab./a\ \n${IP#*.1.}\tIN\tPTR\t$HOST.lab." -i "$REVERSEZONE"
		/usr/bin/sed -e "/$INITIP\t\t$INITHOST.lab\t\t\t$INITHOST/a\ \n$IP\t\t$HOST.lab\t\t\t$HOST" -i /etc/hosts
		;;
	esac
else
	# Check if the host if the first of a series
	if [ -z "$SERIES" ]; then
		echo "Is this the first of a series of hosts?"
		echo "[Y]es/[N]o?"
		read SERIES
	fi
	case $SERIES in
	"y" | "Y" | "yes" | "Yes")
		if [ -z "$TITLE" ]; then
			echo "Please supply series title"
			read TITLE
		fi
		case $TITLE in
		"")
			echo "You have not entered a title"
			exit 0
			;;

		$(awk '/^[A-Z].*$/' <<<${TITLE}))
			echo "This will be the series title:"
			echo "$TITLE"
			;;

		*)
			echo "This is not a valid title"
			exit 0
			;;

		esac
		#;;

		/usr/bin/sed -e "/$INITSERVER.$INITHOST\t*IN\tA\t$INITIP/a\ \n; $TITLE" -i "$FORWARDZONE"
		/usr/bin/sed -e "/$TITLE/a $HOST\t\t\tIN\tA\t$IP" -i "$FORWARDZONE"
		/usr/bin/sed -e "/${INITIP#*.1.}\tIN\tPTR\t$INITSERVER.$INITHOST.lab/a\ \n; $TITLE" -i "$REVERSEZONE"
		/usr/bin/sed -e "/$TITLE/a ${IP#*.1.}\tIN\tPTR\t$HOST.lab." -i "$REVERSEZONE"
		/usr/bin/sed -e "/$INITIP\t*$INITSERVER.$INITHOST.lab\t*$INITSERVER.$INITHOST/a\ \n# $TITLE" -i /etc/hosts
		/usr/bin/sed -e "/$TITLE/a $IP\t\t$HOST.lab\t\t\t$HOST" -i /etc/hosts
		;;

	"n" | "N" | "no" | "No")
		/usr/bin/sed -e "/$INITSERVER.$INITHOST\t*IN\tA\t$INITIP/a\ \n$HOST\t\t\tIN\tA\t$IP" -i "$FORWARDZONE"
		/usr/bin/sed -e "/${INITIP#*.1.}\tIN\tPTR\t$INITSERVER.$INITHOST.lab/a\ \n${IP#*.1.}\tIN\tPTR\t$HOST.lab." -i "$REVERSEZONE"
		/usr/bin/sed -e "/$INITIP\t*$INITSERVER.$INITHOST.lab\t*$INITSERVER.$INITHOST/a\ \n$IP\t\t$HOST.lab\t\t\t$HOST" -i /etc/hosts
		;;
	esac
fi

# Restart Services
/usr/bin/bash -c "$RESTARTDNS"

#Finish
/usr/bin/echo "DNS Entries have been updated on $(uname -n)."

exit 0
