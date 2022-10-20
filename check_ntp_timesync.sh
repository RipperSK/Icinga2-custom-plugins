#!/usr/bin/env bash
#
# roman.spiak@merckgroup.com
# Date: 2021-10-22
# Checks time synchronization offset of ntpd or chronyd service
# Tested on RHEL & SUSE

# For debugging
#set -x

EXIT_OK=0
EXIT_WARNING=1
EXIT_CRITICAL=2
EXIT_UNKNOWN=3
# define how many seconds are acceptable as time drift from NTP server
THRESHOLD_CRITICAL=1

OUTPUT=""
declare RESULT
RESULT=$EXIT_UNKNOWN

set_result() {
  RESULT=$1
}

set_output() {
  if [ $1 -ne 0 ]; then
    OUTPUT+="[CRITICAL] $2"
  else
    OUTPUT+="[OK] $2"
  fi
}

do_exit() {
  echo $OUTPUT
  exit $RESULT
}

check_drift() {
  if [ $(echo "$1 > $THRESHOLD_CRITICAL" |bc -l) -eq 1 ]; then
    set_result $EXIT_CRITICAL
    set_output $EXIT_CRITICAL "NTP timedritf is greather than $THRESHOLD_CRITICAL seconds"
    do_exit $EXIT_CRITICAL
  else
    set_result 0
    set_output 0 "NTP timedritf is smaller than $THRESHOLD_CRITICAL seconds"
  fi
}


if [ $(ps -ef | grep ^chrony | wc -l) -gt 0 ]; then
  if [ $(chronyc sources|grep "Number of sources = 0$"|wc -l) -eq 1 ]; then
      set_result $EXIT_CRITICAL
      set_output $EXIT_CRITICAL "There are no NTP sources configured"
      do_exit
  else
    DRIFT=$(chronyc tracking | grep 'Last offset' | awk '{print $4}' | tr -d '+' | tr -d '-')
    check_drift $DRIFT
    do_exit
  fi
elif [ $(ps -ef | grep ^ntp | wc -l) -gt 0 ]; then
  if [ $(ntpq -pn | grep -F '*' | awk '{print $1}' | cut -d "*" -f 2 | wc -l) -eq 0 ]; then
    set_result $EXIT_CRITICAL
    set_output $EXIT_CRITICAL "There are no NTP sources configured"
    do_exit
  else
    DRIFT=$(ntpq -pn | grep -A 1 ^= | tail -n1 | awk '{print $(NF-1)}' | tr -d '+' | tr -d '-')
    check_drift $DRIFT
    do_exit
  fi
elif [ $(ps -ef | grep ^ntp | wc -l) -eq 0 ] && [ $(ps -ef | grep ^chrony | wc -l) -eq 0 ]; then
  set_result $EXIT_CRITICAL
  set_output $EXIT_CRITICAL "ntpd or chronyd are not running"
  do_exit
else
  set_result $EXIT_UNKNOWN
  set_output $EXIT_UNKNOWN "Unable to obtain NTP time drift"
  do_exit
fi
