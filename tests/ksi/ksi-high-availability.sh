#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"Verifying... ok"
"Count of blocks: *1"
"Count of record hashes: *2"
"Count of meta-records: *1"
)


recordCount=2
files=(
"$outPath/log-with-record-hash$nameSuffix"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cdx $extraOpt -N $recordCount -S 'ksi+tcp://plahh:8080|randomstring|${ksiSignUrl}|ksi+tcp://plahh:8080|randomstring' " "${files[@]}"
integrateAll "${files[@]}"

# Note that exit code of verify is ignored as its output
# is verified in the next step.
declare -i i=0

for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --hex-to-str --ver-int -d $filename 2>&1) || true
  i+=1
done


verifyPattern "${res[@]}"

exit_test
