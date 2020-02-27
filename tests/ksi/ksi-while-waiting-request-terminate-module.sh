#!/bin/bash

. ${srcdir:=.}/ksi/ksi-test-common.sh


testPatterns=(
  "Verifying... failed"
  "Count of blocks: *2"
  "Count of meta-records: *2"
#  "Count of record hashes: *0"  // Fix this when logksi is fixed. 


  "911[[]0[]].02.02='Block closed due to reaching time limit 2'"
  "911[[]1[]].02.02='Block closed due to reaching time limit 2'"
  "904.02.02='Signing not finished due to sudden closure of lmsig_ksi-ls12 module.'"
)

blockTimeout=2
files=(
"$outPath/log_no_rec_timeout_short1"
"$outPath/log_no_rec_timeout_short2"
)


check_command_available "logksi -h"
check_command_available "gttlvgrep -h"

cleanOutFiles "${files[@]}"
callTestFunc "-acr -T $blockTimeout -W $(( blockTimeout + 1 ))" "${files[@]}"
integrateAll "${files[@]}"


# Note that exit code of verify is ignored as its output is verified in the next step.
declare -i i=0
for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --ver-int --continue-on-fail -d $filename 2>&1)
  res[$i]=${res[$i]}$(grepTlv "911[0].02.02" "${filename}.logsig")
  res[$i]=${res[$i]}$(grepTlv "911[1].02.02" "${filename}.logsig")  
  res[$i]=${res[$i]}$(grepTlv "904.02.02" "${filename}.logsig")
  i+=1
done

verifyPattern "${res[@]}"

exit_test
