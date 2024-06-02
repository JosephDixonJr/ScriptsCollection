#!/usr/bin/bash
# Created on May, 22 2024
# Author: Joseph Dixon, Jr.
#
# This script simplifies sending
# a message via ntfy. It takes 2
# parameters: message topic
#
# Example:
#
# notify done maintenence
#
# The above command would send a
# message of "done" to a topic of
# "maintenance" on the ntfy server
# hosted on tecnet.lab
#
# To send messages with spaces,
# enclose the message with quotes:
#
# "This message has multiple spaces"
#

MESSAGE="$1"
TOPIC="$2"

curl -d "$MESSAGE" https://ntfy.tecnet.lab/"$TOPIC"
