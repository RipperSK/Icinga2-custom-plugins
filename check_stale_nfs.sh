#!/bin/bash

# For debugging
#set -x

EXIT_OK=0
EXIT_WARNING=1
EXIT_CRITICAL=2
EXIT_UNKNOWN=3

OUTPUT=""
ERROR_OUTPUT=""
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

MOUNTS="$(mount -t nfs;mount -t nfs3;mount -t nfs4)"
MOUNT_POINTS=$(echo -e "$MOUNTS \n"|grep -v ^$|awk '{print $3}')

if [ -z "$MOUNT_POINTS" ]; then
        OUTPUT="[OK] No nfs mounts"
        set_result 0
else
        for i in $MOUNT_POINTS;do
                timeout 1 stat -t "$i" > /dev/null
                TMP_RESULT=$?
                set_result $TMP_RESULT
                set_output $TMP_RESULT "$i"
        done
fi

if [ -n "$ERROR_OUTPUT" ]; then
        echo -e "$ERROR_OUTPUT"
fi
if [ -n "$OUTPUT" ]; then
        echo -e "$OUTPUT"
fi

exit $RESULT
