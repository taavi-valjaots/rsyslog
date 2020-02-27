#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"Verifying... failed"
"Count of blocks: *1"

"904.02.02='Network error.'"
)


recordCount=1
defaultUserInfo="-S ksi+tcp://this-url-does-not-exist:8080 -U wrong-user -K wrong-key"
files=(
"$outPath/log-sign-network-error$nameSuffix"
)


check_command_available "logksi -h"
check_command_available "gttlvgrep -h"

cleanOutFiles "${files[@]}"
callTestFunc "-rxd $extraOpt -N $recordCount" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int --continue-on-fail -d $filename 2>&1)
  res[$i]=${res[$i]}$(grepTlv "904.02.02" "${filename}.logsig")
  i+=1
done

verifyPattern "${res[@]}"

exit_test
