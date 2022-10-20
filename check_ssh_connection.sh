#!/bin/bash

#This script checks the provided client if successfull SSH connection can be established

#Author: Roman Spiak <roman.spiak@merckgroup.com>
#Last Update: 2022-06-20
#GIT-remote: https://dfwpgitlab.sial.com/M302628/monitoring-scripts/

#Initialize vars
USER=monitor
PRIV_KEY=/etc/icinga2/secrets/icinga
EXIT_CODE=0
SCRIPTNAME=$0
SERVER=$2
TIMEOUT=90

#Check private key file existence
if [ ! -f $PRIV_KEY ];then
  echo "ERROR: accessing $PRIV_KEY file"
  EXIT_CODE=2
  exit $EXIT_CODE
fi

#Check SSH open port
if ! timeout $TIMEOUT nc -vz $SERVER 22 &>/dev/null; then
  echo "ERROR: port 22 is not open or listening for $SERVER"
  EXIT_CODE=2
  exit $EXIT_CODE
fi

#Check if SSH connection can be established
if ! timeout $TIMEOUT ssh $USER@$SERVER -i $PRIV_KEY -o 'LogLevel QUIET' '-o' 'StrictHostKeyChecking NO' 'true'; then
  echo "ERROR: unable to SSH to $SERVER"
  EXIT_CODE=2
  exit $EXIT_CODE
else
  echo "INFO: SSH to $SERVER is working OK"
  EXIT_CODE=0
  exit $EXIT_CODE
fi
