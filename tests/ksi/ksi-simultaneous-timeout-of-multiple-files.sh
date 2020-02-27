#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh


if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
  "Verifying... ok"
  "Count of blocks: *1"
  "Count of record hashes: *40"


# There must only be one meta-data record caused by timeout.
  "Count of meta-records: *1"
  "911.02.02='Block closed due to reaching time limit 3'"
)

recordCount=40
blockTimeout=3
files=(
"$outPath/log_multi_timeout0$nameSuffix"
"$outPath/log_multi_timeout1$nameSuffix"
"$outPath/log_multi_timeout2$nameSuffix"
"$outPath/log_multi_timeout3$nameSuffix"
"$outPath/log_multi_timeout4$nameSuffix"
"$outPath/log_multi_timeout5$nameSuffix"
"$outPath/log_multi_timeout6$nameSuffix"
"$outPath/log_multi_timeout7$nameSuffix"
"$outPath/log_multi_timeout8$nameSuffix"
"$outPath/log_multi_timeout9$nameSuffix"
)


check_command_available "logksi -h"
check_command_available "gttlvgrep -h"

cleanOutFiles "${files[@]}"
callTestFunc "-cd $extraOpt -N $recordCount -T $blockTimeout -W $(( blockTimeout + 2 ))" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int -d $filename 2>&1)
  res[$i]=${res[$i]}$(grepTlv "911.02.02" "${filename}.logsig")
  i+=1
done

verifyPattern "${res[@]}"

exit_test
