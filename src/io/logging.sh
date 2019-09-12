#
#	Logging module.
#




#
#	Declare logging specifications.
#

# Logging targets.
declare SHD_LOGTARGET_STD='/dev/stdout';
declare SHD_LOGTARGET_ERR='/dev/stderr';

# Logging levels and specifications.
declare -A SHD_LOGLEVEL_SPEC=(
	[error]=-2
	[warning]=-1
	[info]=0
	[verbose]=1
	[debug]=2
);




#
#	Main logging function.
#

shd_log_write() {
	# Fetch the level we should write at.
	local LEVEL="${1}"; shift;

	# Undefined level?
	if [ -z "${SHD_LOGLEVEL_SPEC[${LEVEL}]-}" ]; then
		echo 'Invalid log level:' "${LEVEL}" >&2;
		return 1;
	fi;

	# Verbosity too low?
	local LEVEL_VERBOSITY=$((SHD_LOGLEVEL_SPEC[${LEVEL}]));
	if [ $((VERBOSITY)) -lt $((LEVEL_VERBOSITY)) ]; then
		return 0;
	fi;

	# Don't print newlines?
	local N;
	if [ "${1}" = '-n' ]; then
		N="${1}";
		shift;
	fi;

	# Determine logging target.
	local TARGET="${SHD_LOGTARGET_STD}";
	if [ $((LEVEL_VERBOSITY)) -lt 0 ]; then
		TARGET="${SHD_LOGTARGET_ERR}";
	fi;

	# Write! :^)
	echo ${N} "${@}" > "${TARGET}";
}




#
#	Level-restricted logging functions.
#

shd_log_error() {
	shd_log_write 'error' "${@}";
}

shd_log_warning() {
	shd_log_write 'warning' "${@}";
}

shd_log_info() {
	shd_log_write 'info' "${@}";
}

shd_log_verbose() {
	shd_log_write 'verbose' "${@}";
}

shd_log_debug() {
	shd_log_write 'debug' "${@}";
}
