. ${srcdir:=.}/diag.sh init

outPath=ksi/out
ksiSignUrl="ksi+tcp://ksigw.test.ee.guardtime.com:8080/gt-signingservice"
ksiSignUser="anon"
ksiSignKey="anon"
defaultUserInfo="-S $ksiSignUrl -U $ksiSignUser -K $ksiSignKey"


mkdir -p $outPath


cleanOutFiles() {
	local array=("$@")

	for filename in "${array[@]}"; do
	  rm -f $filename ${filename}.logsig
	  rm -rf ${filename}.logsig.parts
	done
}

callTestFunc() {
	local options="$1"
	shift
	local array=("$@")
	local outFileArgs=""
	
	for filename in "${array[@]}"; do
	  outFileArgs="$outFileArgs -f $filename"
	done
	
	echo "Command called: './ksi-test $defaultUserInfo $options $useroptions $outFileArgs'"

	# This test tool will return rsyslog test case compatible exit codes.
	./ksi-test $defaultUserInfo $options $useroptions $outFileArgs
	if [[ $? != 0 ]]; then
		error_exit $?
	fi
}


# list of strings...
verifyPattern() {
	local array=("$@")

	for resStr in "${array[@]}"; do
		verify_pattern_list "$resStr" "${testPatterns[@]}"
	done
}

integrateAll() {
	local array=("$@")

	for filename in "${array[@]}"; do
	  logksi integrate $filename
	  if [[ $? != 0 ]]; then
		error_exit 1
	  fi
	done
}

# pattern, filename
grepTlv() {
	printf "$1=\'$(gttlvgrep -r -H 8 ${1} ${2} | tr -d '\0')\'"
}