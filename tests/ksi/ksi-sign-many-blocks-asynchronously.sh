#!/bin/bash

# This test adds 512 records filling many blocks in very short time. This will create a need
# to sign multiple blocks at once. 2s pause is taken to let the signing to be complete. After
# that, file is closed and resulting files are integrated into log signature. Resulting signature
# must be fully signed with 128 + 1 blocks.

. ${srcdir:=.}/ksi/ksi-test-common.sh


testPatterns=(
"Verifying... ok"
"Count of blocks: *129"
"Count of record hashes: *512"
"Count of meta-records: *1"

"Block closed due to file closure"
)

# Note that masking is used and every record actually adds
# 2 nodes into tree.
blockLevelLimit=3
recordCount=512
files=(
"$outPath/log_long_small_blocks"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-acx -L $blockLevelLimit -N $recordCount -W 2" "${files[@]}"
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
