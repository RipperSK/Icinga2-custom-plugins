#!/bin/sh

# How to recognize a "real" filesystem type in /proc/filesystems
REAL_FSTYPE_MATCH='((NF==1)&&($1!="iso9660")&&($1!="overlay")&&($1!="tmpfs")&&($1!="nsfs")&&($1!="kubelet")&&($1!="cgroup")&&($1!="autofs")&&($1!="rpc_pipefs")&&($1!="tracefs")&&($1!="sysfs")&&($1!="proc")&&($1!="binfmt_misc")&&($1!="pstore")&&($1!="bpf")&&($1!="securityfs")&&($1!="debugfs")&&($1!="mqueue")&&($1!="devpts")&&($1!="hugetlbfs"))'

# How to recognize a candidate "real" filesystem in /proc/mounts
REAL_FILESYS_MATCH='^/[^ ]* /'

# How to recognize a "real" filesystem that is mounted R/O
RO_FILESYSTEM_MATCH='[ ,]ro[, ]'

# How to recognize a "real" filesystem *explicitly* set to R/W
RW_FILESYSTEM_MATCH='[ ,]rw[, ]'

# Collect the kernel's "real" filesystem types from /proc/filesystems
REAL_FST=`awk '{ if '"$REAL_FSTYPE_MATCH"' printf "($3==\"%s\")||",$1; }' /proc/filesystems`
REAL_FST_C=`awk '{ if '"$REAL_FSTYPE_MATCH"' c++; } END { printf "%u\n",c; }' /proc/filesystems`
ANY_FST_C=`awk '{ c++; } END { printf "%u\n",c; }' /proc/filesystems`
UNREAL_FST_C=`expr $ANY_FST_C - $REAL_FST_C`

# Scan kernel's mount data straight out of /proc/mounts
RO_FSES=`grep "$REAL_FILESYS_MATCH" /proc/mounts | awk "{ if (${REAL_FST}(0==1)) print; }" | \
   grep "$RO_FILESYSTEM_MATCH" | sed -e 's/ [0-9][0-9]* [0-9][0-9]* *$/ ;/' | tr '\n' ' '`
RO_FSES_C=`grep "$REAL_FILESYS_MATCH" /proc/mounts | awk "{ if (${REAL_FST}(0==1)) print; }" | \
   grep -c "$RO_FILESYSTEM_MATCH"`
RW_FSES_C=`grep "$REAL_FILESYS_MATCH" /proc/mounts | awk "{ if (${REAL_FST}(0==1)) print; }" | \
   grep -c "$RW_FILESYSTEM_MATCH"`
REAL_FSES=`grep "$REAL_FILESYS_MATCH" /proc/mounts | awk "{ if (${REAL_FST}(0==1)) print \\\$2; }" | sort | tr '\n' ' '`
REAL_FSES_C=`grep "$REAL_FILESYS_MATCH" /proc/mounts | awk "{ if (${REAL_FST}(0==1)) print; }" | wc -l`
IMPLICIT_C=`expr $REAL_FSES_C - $RW_FSES_C - $RO_FSES_C`
PREREAL_FSES_C=`grep -c "$REAL_FILESYS_MATCH" /proc/mounts`
ANY_FSES_C=`grep -c . /proc/mounts`

# Prepare statistics
STATS="types_all=$ANY_FST_C;;;0; types_nodev=$UNREAL_FST_C;;;0;$ANY_FST_C types_real=$REAL_FST_C;;;0;$ANY_FST_C"
STATS="$STATS fses_all=$ANY_FSES_C;;;0; fses_prefiltered=$PREREAL_FSES_C;;;0;$ANY_FSES_C fses_real=$REAL_FSES_C;;;0;$PREREAL_FSES_C"
STATS="$STATS ro=$RO_FSES_C;1;1;0;$REAL_FSES_C rw_explicit=$RW_FSES_C;;;0;$REAL_FSES_C rw_implicit=$IMPLICIT_C;;;0;$REAL_FSES_C"

# Output and exit
if [ $RO_FSES_C -gt 0 ]; then
   echo "CRITICAL: Found $RO_FSES_C readonly filesystems: $RO_FSES|$STATS"
   exit 2
else
   echo "OK: No filesystems mounted readonly (found: $REAL_FSES)|$STATS"
   exit 0
fi
