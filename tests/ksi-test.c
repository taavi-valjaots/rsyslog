#include "config.h"
#include <signal.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include "rsyslog.h"
#include "lib_ksils12.h"


static int isOpenedFileCountOk(int expectedCount, int isAsync);
static void usge(void);

enum {
	// EXIT_SUCCESS = 0,
	// EXIT_FAILURE = 1,
	EXIT_SKIP_TEST = 77,
	EXIT_TEST_BENCH = 100
};

int
main(int argc, char *argv[]) {
	int res = 1;
	int exitCode = EXIT_FAILURE;
	int opt = 0;
	rsksictx rsksi = NULL;
	char command[1024];
	char commandRet[0xffff];
	int strLen = 0;
	char *aggrUrl = NULL;
	char *aggrUser = NULL;
	char *aggrKey = NULL;
	uint32_t blockTimeLimit = 0;
	uint32_t recordAmount = 0;
	uint8_t blockLevelLimit = 0;
	int mode = LOGSIG_SYNCHRONOUS;
	int keepRecordHashes = 0;
	int keepTreeHashes = 0;
	char *hashAlgo = "default";
	char *hmackAlgo = "default";
	int debug = 0;
	int destructOpenedFiles = 0;
	int timetowait = 0;
	FILE *fp[1024];
	char *logFileName[1024];
	ksifile outKsifile[1024];
	int outFileCount = 0;
	int checkOpenedFiles = 0;
	int checkIfIsDisabled = 0;
	int isModuleFailure = 0;
	int isAsyncMode = 0;
	const char *randomSource = NULL;
	char *debugFile = NULL;
	int i = 0;
	int n = 0;


	/* Parse command line. */
	while((opt = getopt(argc, argv, "f:S:U:K:H:M:N:L:T:W:R:D:arstxcd")) != -1) {
		switch (opt) {
			case 'f':
				if (outFileCount == sizeof(fp)/sizeof(FILE*)) {
					res = 1;
					fprintf(stderr, "Error: Input file count exceeds %i.\n", outFileCount);
					exitCode = EXIT_TEST_BENCH;
					goto finalize;
				}

				if (optarg == NULL || optarg[0] == '\0') {
					res = 1;
					fprintf(stderr, "Error: Unexpected file name '%s'.\n", optarg);
					exitCode = EXIT_TEST_BENCH;
					goto finalize;
				}

				outKsifile[outFileCount] = NULL;
				logFileName[outFileCount] = optarg;
				fp[outFileCount] = fopen(optarg, "w");
				if (fp[outFileCount] == NULL) {
					res = 1;
					fprintf(stderr, "Error: Unable to open file '%s' for writing log to.\n", optarg);
					exitCode = EXIT_TEST_BENCH;
					goto finalize;
				}

				outFileCount++;
			break;

			case 'S':
				aggrUrl = optarg;
			break;

			case 'U':
				aggrUser = optarg;
			break;

			case 'K':
				aggrKey = optarg;
			break;

			case 'H':
				hashAlgo = optarg;
			break;

			case 'M':
				hmackAlgo = optarg;
			break;

			case 'N':
				recordAmount = atoi(optarg);
			break;

			case 'L':
				blockLevelLimit = atoi(optarg);
			break;

			case 'T':
				blockTimeLimit = atoi(optarg);
			break;

			case 'W':
				timetowait = atoi(optarg);
			break;

			case 'R':
				randomSource = optarg;
			break;

			case 'D':
				debugFile = optarg;
			break;

			case 'a':
				mode = LOGSIG_ASYNCHRONOUS;
				isAsyncMode = 1;
			break;

			case 'r':
				keepRecordHashes = 1;
			break;

			case 't':
				keepTreeHashes = 1;
			break;

			case 'x':
				destructOpenedFiles = 1;
			break;

			case 'c':
				checkOpenedFiles = 1;
			break;

			case 's':
				checkIfIsDisabled = 1;
			break;

			case 'd':
				debug = 1;
			break;

			default:
				usge();
				exit(1);
			break;
		}
	}

	/* Some debug info. */
	if (debug) {
		fprintf(stderr, "Aggregator:\n"
			            " URL:                '%s'\n"
						" User:               '%s'\n"
						" Key:                '%s'.\n", aggrUrl, aggrUser, aggrKey);
		fprintf(stderr, "Hashing:             '%s'.\n", hashAlgo);
		fprintf(stderr, "HMACK:               '%s'.\n", hmackAlgo);
		fprintf(stderr, "Options:\n"
						" Block level limit:  %i\n"
						" Block time limit:   %i\n"
						" Keep record hashes: %i\n"
						" Keep tree hashes:   %i\n"
						" Random source:      %s\n"
						" Debug file:         %s\n"
						" Is async:           %i\n", blockLevelLimit, blockTimeLimit, keepRecordHashes, keepTreeHashes, randomSource, debugFile, isAsyncMode);

		fprintf(stderr, "\n\n");
	}


	/* Create new rsyslog KSI object. */
	if (debug) fprintf(stderr, "Constructing module..\n");
	rsksi = rsksiCtxNew();
	if (rsksi == NULL) {
		res = 1;
		fprintf(stderr, "Error: Unable to create rsksictx object.\n");
		goto finalize;
	}

	res = rsksiSetAggregator(rsksi, aggrUrl, aggrUser, aggrKey);
	if (res != KSI_OK) {
		fprintf(stderr, "Error: Unable to set KSI aggregator:\n"
			            "        -S '%s'\n"
						"        -U '%s'\n"
						"        -K '%s'", aggrUrl, aggrUser, aggrKey);
		goto finalize;
	}

	res = rsksiSetHashFunction(rsksi, hashAlgo);
	if (res != KSI_OK) {
		fprintf(stderr, "Error: Unable to set KSI hash algorithm '%s'.\n", hashAlgo);
		goto finalize;
	}

	res = rsksiSetHmacFunction(rsksi, hmackAlgo);
	if (res != KSI_OK) {
		fprintf(stderr, "Error: Unable to set KSI HMACK algorithm '%s'.\n", hmackAlgo);
		goto finalize;
	}



	rsksiSetBlockLevelLimit(rsksi, blockLevelLimit);
	rsksiSetBlockTimeLimit(rsksi, blockTimeLimit);
	rsksiSetKeepRecordHashes(rsksi, keepRecordHashes);
	rsksiSetKeepTreeHashes(rsksi, keepTreeHashes);
	rsksiSetSyncMode(rsksi, mode);

	if (randomSource != NULL) {
			rsksiSetRandomSource(rsksi, randomSource);
	}

	if (debugFile != NULL) {
		res = rsksiSetDebugFile(rsksi, debugFile);
		if (res != KSI_OK) {
			fprintf(stderr, "Error: Unable to open debug file '%s'.\n", debugFile);
			goto finalize;
		}

		rsksi->debugLevel = KSI_LOG_DEBUG;
	}

	if (debug) fprintf(stderr, "Initializing module..\n");
	res = rsksiInitModule(rsksi);
	if (res != KSI_OK) {
		isModuleFailure = 1;
		fprintf(stderr, "Error: Unable to init KSI module.");
		goto finalize;
	}

	if (debug) fprintf(stderr, "Opening files..\n");
	for (i = 0; i < outFileCount; i++) {
		if (debug) fprintf(stderr, "  Opening file '%s'\n", logFileName[i]);
		outKsifile[i] = rsksiCtxOpenFile(rsksi, logFileName[i]);

		if (outKsifile[i] == NULL) {
			res = 1;
			fprintf(stderr, "Error: Unable to open ksifile for log file '%s'.\n", logFileName[i]);
			goto finalize;
		}

		sigblkInitKSI(outKsifile[i]);
	}

	if (debug) fprintf(stderr, "Writing records..\n");
	for (n = 0; n < recordAmount; n++) {
		for (i = 0; i < outFileCount; i++) {
			char logLine[1024];

			snprintf(logLine, sizeof(logLine), "%s:%i message", logFileName[i], n + 1);
			fprintf(fp[i], "%s\n", logLine);

			res = sigblkAddRecordKSI(outKsifile[i], logLine, strlen(logLine));
			if (res != KSI_OK) {
				res = 1;
				fprintf(stderr, "Error: Unable to add record of log file '%s'.\n", logFileName[i]);
				goto finalize;
			}
		}
	}

	if (checkOpenedFiles) {
		/* This is more like sanity check to see if this test function works. */
		if (debug) fprintf(stderr, "Checking if all files are opened..\n");
		if (!isOpenedFileCountOk(outFileCount * (1 + isAsyncMode), isAsyncMode)) {
			res = 1;
			goto finalize;
		}
	}

	if (destructOpenedFiles) {
		if (debug) fprintf(stderr, "Destructing files..\n");
		for (i = 0; i < outFileCount; i++) {
			if (debug) fprintf(stderr, "  Destructing files '%s.logsig.parts'\n", logFileName[i]);
			res = rsksifileDestruct(outKsifile[i]);
			if (res != KSI_OK) {
				fprintf(stderr, "Error: Unable to destruct ksifile for log file '%s'.\n", logFileName[i]);
				goto finalize;
			}

			outKsifile[i] = NULL;
		}
	}

	if (timetowait > 0) {
		if (debug) fprintf(stderr, "Waiting..\n");
		sleep(timetowait);
	}

	if (debug) fprintf(stderr, "Closing module..\n");
	rsksiCtxDel(rsksi);
	rsksi = NULL;

	if (checkOpenedFiles) {
		if (debug) fprintf(stderr, "Checking if opened files are closed..\n");
		if (!isOpenedFileCountOk(0, isAsyncMode)) {
			res = 1;
			goto finalize;
		}
	}

	if (debug) fprintf(stderr, "Done!\n");
	res = 0;
	exitCode = EXIT_SUCCESS;

finalize:
	if (rsksi != NULL && isModuleFailure && checkIfIsDisabled) {
		if (debug) fprintf(stderr, "Check if module is disabled..\n");
		if (rsksi->disabled) {
			exitCode = EXIT_SUCCESS;
		} else {
			exitCode = EXIT_FAILURE;
		}
	}


	for (i = 0; i < outFileCount; i++) {
		fclose(fp[i]);
		fp[i] = NULL;
	}

	if (res != 0) {
		fprintf(stderr, "\nError: %i (%x).\n", res, res);
	}

	rsksiCtxDel(rsksi);

	return exitCode;
}

void
LogError(const int iErrno, const int iErrCode, const char *fmt, ... )
{
	return;
}

static int
run_command_return_buf(const char *command, char *buf, size_t buf_len)
{
	int ret = -1;
	FILE *fp = NULL;
	char path[1035];

	/* Open the command for reading. */
	fp = popen(command, "r");
		if (fp == NULL) {
		goto finalize;
	}

	ret = fread(buf, sizeof(char), buf_len, fp);
	if (ret > 0) {
		buf[ret-1] = '\0';
	} else {
		buf[0] = '\0';
	}

finalize:

	pclose(fp);
	return ret;
}

static int
isOpenedFileCountOk(int expectedCount, int isAsync) {
	pid_t pid = 0;
	char command[1024];
	char commandRet[0xffff];
	size_t strLen = 0;
	int c = 0;

	/* Get the PID of the running process. */
	pid = getpid();


	if (isAsync) {
		snprintf(command, sizeof(command), "lsof -p %lu | grep logsig.parts | wc -l", pid);
	} else {
		snprintf(command, sizeof(command), "lsof -p %lu | grep logsig | wc -l", pid);
	}

	strLen = run_command_return_buf(command, commandRet, sizeof(commandRet));
	if (strLen == 0) {
		fprintf(stderr, "Error: No bytes returned by command!\n");
		return 0;
	}

	c = atoi(commandRet);
	if (c != expectedCount) {
		fprintf(stderr, "Error: Expected file count is %i, but actual count is %i!\n", expectedCount, c);
		return 0;
	}

	return 1;
}

static void
usge(void) {
	fprintf(stderr, "ksi-test [-S url] [-U usr] [-K key] [-H algo] [-M algo] [-N count] [-R file]\n");
	fprintf(stderr, "         [-D file] [-L level limit] [-T time limit] [-arstxcd] [-f file]...\n\n");

	fprintf(stderr, "Options:\n");
	fprintf(stderr, " -S <URL>  - KSI service URL. Use file:// to provide static data\n");
	fprintf(stderr, " -U <str>  - KSI service user.\n");
	fprintf(stderr, " -K <str>  - KSI service key.\n");
	fprintf(stderr, " -H <str>  - Hash algorithm name.\n");
	fprintf(stderr, " -M <str>  - HMACK algorithm name.\n");
	fprintf(stderr, " -R <str>  - Source of random (e.g. file).\n");
	fprintf(stderr, " -f <path> - log file to add those log lines to KSI.\n");

	fprintf(stderr, " -N <int>  - How many records to generate and add to log files.\n");
	fprintf(stderr, " -L <int>  - Block Level limit.\n");
	fprintf(stderr, " -T <int>  - Block Time limit.\n");
	fprintf(stderr, " -W <int>  - How many seconds to wait when all the records have been added until\n");
	fprintf(stderr, "             proceeding to closing the module. This can be used to test timeout.\n");
	fprintf(stderr, " -D <path> - Debug file.\n");


	fprintf(stderr, " -a        - Asynchronous signing.\n");
	fprintf(stderr, " -r        - Keep record hashes.\n");
	fprintf(stderr, " -t        - Keep tree hashes.\n");
	fprintf(stderr, " -x        - Destruct opened files before module close.\n");
	fprintf(stderr, " -c        - Check if all files opened by module are closed.\n");
	fprintf(stderr, " -s        - Check if module initialization fails. If expected\n");
	fprintf(stderr, "             failure occurs, EXIT_SUCCESS is returned. \n");
	fprintf(stderr, " -d        - Debug info to stderr.\n");

	return;
}
