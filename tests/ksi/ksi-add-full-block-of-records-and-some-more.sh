#!/bin/bash

# This test adds 8 records filling one block. One single record is added into next block.
# Firs block should be closed without metadata, second block should be closed as the filename
# was closed.


. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"Verifying... ok"
"Count of blocks: *2"
"Count of record hashes: *9"
"Count of meta-records: *1"

"Block closed due to file closure"
)

# Note that masking is used and every record actually adds
# 2 nodes into tree.
blockLevelLimit=4
recordCount=9
files=(
"$outPath/log_lvl_limit_full_block_and_some_more1$nameSuffix"
"$outPath/log_lvl_limit_full_block_and_some_more2$nameSuffix"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cxd $extraOpt -L $blockLevelLimit -N $recordCount -W 2" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int -d $filename 2>&1)
  res[$i]=${res[$i]}$(gttlvgrep -r -H 8 911.02.02 ${filename}.logsig | tr -d '\0')
  i+=1
done

verifyPattern "${res[@]}"

exit_test
