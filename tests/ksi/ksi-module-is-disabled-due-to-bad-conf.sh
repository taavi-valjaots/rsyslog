#!/bin/bash

# This test checks if KSI module is disabled due to bad configuration.
# (Check is activated with option -s).

. ${srcdir:=.}/ksi/ksi-test-common.sh

if [[ $1 == "async" ]]; then
	nameSuffix="-async"
	extraOpt="-a"	
fi

recordCount=2
files=(
"$outPath/dummylog$nameSuffix"
)


check_command_available "logksi -h"
cleanOutFiles "${files[@]}"

# Bad URL format.
callTestFunc "-ds $extraOpt -S invalidurlformat -N $recordCount" "${files[@]}"
cleanOutFiles "${files[@]}"

callTestFunc "-ds $extraOpt -S plah://thiswillnotwork -U plah -K plah -N $recordCount" "${files[@]}"
cleanOutFiles "${files[@]}"

# TODO:
# TODO:
# TODO:
# TODO:

# Bad level limit.
# With level 1 one record can exist.
# With level 0 (no records are added)
#callTestFunc "-as -L 0 -N $recordCount" "${files[@]}"
#cleanOutFiles "${files[@]}"


exit_test
