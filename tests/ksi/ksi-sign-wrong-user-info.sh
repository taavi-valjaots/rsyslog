#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"Verifying... failed"
"Count of blocks: *1"

"The request could not be authenticated"
)


recordCount=2
files=(
"$outPath/log-wrog-user-info$nameSuffix"
)


check_command_available "logksi -h"
check_command_available "gttlvgrep -h"

cleanOutFiles "${files[@]}"
callTestFunc "-cdx $extraOpt -N $recordCount -K wrongkey" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int --continue-on-fail -d $filename 2>&1)
  res[$i]=${res[$i]}$(gttlvgrep -r -H 8 904.02.02 ${filename}.logsig | tr -d '\0')
  i+=1
done

verifyPattern "${res[@]}"

exit_test
