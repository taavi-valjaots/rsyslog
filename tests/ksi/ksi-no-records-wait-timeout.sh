#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
  "Verifying... ok"
  "Count of blocks: *1"
  "Count of record hashes: *0"


# There must only be one meta-data record caused by timeout.
  "Count of meta-records: *1"
  "Block closed due to reaching time limit 3"
)

blockTimeout=3
files=(
"$outPath/log_no_rec_timeout1$nameSuffix"
"$outPath/log_no_rec_timeout2$nameSuffix"
)


check_command_available "logksi -h"
check_command_available "gttlvgrep -h"

cleanOutFiles "${files[@]}"
callTestFunc "-cd $extraOpt -T $blockTimeout -W $(( blockTimeout + 2 ))" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int -d $filename 2>&1)
  res[$i]=${res[$i]}$(gttlvgrep -r -H 8 911[0].02.02 ${filename}.logsig | tr -d '\0')
  i+=1
done

verifyPattern "${res[@]}"

exit_test
