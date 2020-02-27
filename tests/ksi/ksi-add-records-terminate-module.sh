#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh


if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
	"Verifying... failed"
	"(Error: Block 1 is unsigned)"
	"904.02.02='Block closed due to sudden closure of lmsig_ksi-ls12 module.'"
	"911.02.02='Block closed due to sudden closure of lmsig_ksi-ls12 module.'"
)

recordCount=40
files=(
"$outPath/log1$nameSuffix"
"$outPath/log2$nameSuffix"
)

check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cd $extraOpt -N $recordCount" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify -d --continue-on-fail --ver-int  $filename 2>&1)
  res[$i]=${res[$i]}$(grepTlv "911.02.02" "${filename}.logsig")
  res[$i]=${res[$i]}$(grepTlv "904.02.02" "${filename}.logsig")
  i+=1
done


verifyPattern "${res[@]}"

exit_test
