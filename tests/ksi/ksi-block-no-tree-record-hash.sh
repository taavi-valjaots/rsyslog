#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

testPatterns=(
"[{]M[}]"
"Block no.   1: processing block signature data... ok"
"Finalizing log signature... ok"
"Block no.   1: Meta-record value: 'Block closed due to file closure"
)


recordCount=2
files=(
"$outPath/log-no-tree-record-hash$nameSuffix"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cdx $extraOpt -N $recordCount" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --hex-to-str --ver-int -ddd $filename 2>&1)
  i+=1
done

verifyPattern "${res[@]}"

exit_test
