#!/usr/bin/env bash

# For debugging
#set -x

EXIT_OK=0
EXIT_WARNING=1
EXIT_CRITICAL=2
EXIT_UNKOWN=3

OUTPUT=""
ERROR_OUTPUT=""
declare -g RESULT
RESULT=$EXIT_OK

set_result() {
	if [ $1 -gt $RESULT ]; then
		RESULT=$EXIT_CRITICAL
	fi
}

set_output() {
	if [ $1 -ne 0 ]; then
		ERROR_OUTPUT+="[CRITICAL] $2 seems to be stale"
		ERROR_OUTPUT+='\n'
	else
		OUTPUT+="[OK] $2 seems to be fine"
		OUTPUT+='\n'
	fi
}

while read _ _ mount _; do
	echo $mount
	read -t1 < <(stat -t "$mount")
	TMP_RESULT=$?
	set_result $TMP_RESULT
	set_output $TMP_RESULT "$mount"
done < <(mount -t nfs)

if [ -n "$ERROR_OUTPUT" ]; then
	echo -e "$ERROR_OUTPUT"
fi
if [ -n "$OUTPUT" ]; then
	echo -e "$OUTPUT"
fi

exit $RESULT
