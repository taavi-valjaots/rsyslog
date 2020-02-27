#!/bin/bash

# This test adds 8 records filling one block. Second block will be empty. As the
# module is closed, empty block must be left unchanged.

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"Verifying... ok"
"Count of blocks: *1"
"Count of record hashes: *8"

# Check that metada is not present.
"911.02.02=''"
)

# Note that masking is used and every record actually adds
# 2 nodes into tree.
blockLevelLimit=4
recordCount=8
files=(
"$outPath/log-lvl_limit_exact1$nameSuffix"
"$outPath/log-lvl_limit_exact2$nameSuffix"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cd $extraOpt -L $blockLevelLimit -N $recordCount -W 2" "${files[@]}"
integrateAll "${files[@]}"
#./ksi-test -S ksi+tcp://ksigw.test.ee.guardtime.com:8080/gt-signingservice -U anon -K anon -ac -L 4 -N 8 -W 2   -f out/log-lvl_limit_exact1 -f out/log-lvl_limit_exact2


declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int -d $filename 2>&1)
  res[$i]=${res[$i]}911.02.02=\'$(gttlvgrep -r -H 8 911.02.02 ${filename}.logsig | tr -d '\0')\'
  i+=1
done

verifyPattern "${res[@]}"

exit_test
