#!/bin/bash

# ksi-const-random.sh tests if random source can be specified as a file. If file
# is accepted, tree built should aggregate to constant value that is also
# tested. This is first block and its input hash must be zero hash. This test
# must create .ksistate file that holds the vale of the previous block. This
# file is used in ksi-const-random-next-block.sh. 

. ${srcdir:=.}/ksi/ksi-test-common.sh

testPatterns=(
"[{]M[}]"
"input hash: SHA-256:0000000000000000000000000000000000000000000000000000000000000000"
"output hash: SHA-256:0e8d62780cfc34384f84ca9de28edd7e3f2391739a640fce9eff6d20596808a5"
"Block no.   1: processing block signature data... ok"
"Finalizing log signature... ok"
"Block no.   1: Meta-record value: 'Block closed due to file closure"
)


randomSource=${srcdir:=.}/ksi/const-string
recordCount=4
files=(
"$outPath/log-const-random"
)



# Huvitav, kuidas responsi ei õnnestu failina ette anda.

check_command_available "logksi -h"
cleanOutFiles "${files[@]}"
callTestFunc "-cdxa -N $recordCount -H SHA256 -R $randomSource -D $outPath/ksi.log" "${files[@]}"
integrateAll "${files[@]}"

# gttlvdump -Pp out/log-static-sign.logsig.parts/blocks.dat | grep TLV.0903
logksi verify --ver-int -dd out/log-static-sign


# Note that exit code of verify is ignored as its output
# is verified in the next step.
declare -i i=0

for filename in "${files[@]}"; do
  res[$i]=$(logksi verify --hex-to-str --ver-int -ddd $filename 2>&1) || true
  i+=1
done

verifyPattern "${res[@]}"

exit_test
