#
#	Argument parsing module.
#




#
#	Declare module initialization configuration.
#

declare MODULE_INIT='shd_mod_args_init';
declare MODULE_PRIORITY=10;




#
#	Declare system arguments and their handlers.
#

declare -A SYSTEM_ARGUMENT_TYPES=(
	[v]=flag
	[h]=flag
);
export SYSTEM_ARGUMENT_TYPES;

declare -A SYSTEM_ARGUMENT_MESSAGES=(
	[v]='Increase verbosity by one notch.'
	[h]='Show this help message.'
);

declare VERBOSITY=0;
shd_arghandler_v() {
	VERBOSITY=$((VERBOSITY+1));
}

declare HELP=0;
shd_arghandler_h() {
	HELP=1;
}




#
#	Declare optional user-supplied arguments.
#

declare ARGUMENT_OPTIND;
declare -A ARGUMENT_TYPES=();
declare -A ARGUMENT_MESSAGES=();




#
#	Main argument parsing function.
#

shd_arguments_parse() {
	local PROGRAM="${1}"; shift;

	local ALL_ARG_TYPES;
	declare -A ALL_ARG_TYPES=();
	if ((SHD_BASH)); then
		for ARG in "${!ARGUMENT_TYPES[@]}"; do
			ALL_ARG_TYPES[${ARG}]="${ARGUMENT_TYPES[${ARG}]}";
		done;
		for ARG in "${!SYSTEM_ARGUMENT_TYPES[@]}"; do
			ALL_ARG_TYPES[${ARG}]="${SYSTEM_ARGUMENT_TYPES[${ARG}]}";
		done;
	elif ((SHD_ZSH)); then
		for ARG in "${(@k)ARGUMENT_TYPES[@]}"; do
			ALL_ARG_TYPES[${ARG}]="${ARGUMENT_TYPES[${ARG}]}";
		done;
		for ARG in "${(@k)SYSTEM_ARGUMENT_TYPES[@]}"; do
			ALL_ARG_TYPES[${ARG}]="${SYSTEM_ARGUMENT_TYPES[${ARG}]}";
		done;
	fi;

	# Generate the options string to pass to getopts.
	local GETOPTS_ARGS='';
	if ((SHD_BASH)); then
		for ARG in "${!ALL_ARG_TYPES[@]}"; do
			GETOPTS_ARGS+="${ARG}";

			case "${ALL_ARG_TYPES[${ARG}]}" in
				value)
					GETOPTS_ARGS+=':';
					;;
				*)
					;;
			esac;
		done;
	elif ((SHD_ZSH)); then
		for ARG in "${(@k)ALL_ARG_TYPES[@]}"; do
			GETOPTS_ARGS+="${ARG}";

			case "${ALL_ARG_TYPES[${ARG}]}" in
				value)
					GETOPTS_ARGS+=':';
					;;
				*)
					;;
			esac;
		done;
	fi;

	# Parse options. For each found option, run the arghandler.
	while getopts "${GETOPTS_ARGS}" OPT "${@}"; do
		if ! shd_function_exists "shd_arghandler_${OPT}"; then
			shd_log_error 'Missing arghandler for option:' "-${OPT}";
			continue;
		fi;

		"shd_arghandler_${OPT}" "${OPTARG}";
	done;
}




#
#	Usage/help message generator.
#

shd_arguments_usage() {
	local PROGRAM="${1}"; shift;

	local SYS_OPT='';
	if [ ${#SYSTEM_ARGUMENT_TYPES[@]} -gt 0 ]; then
		SYS_OPT=' [system option...]';
	fi;

	local CMD_OPT='';
	if [ ${#ARGUMENT_TYPES[@]} -gt 0 ]; then
		CMD_OPT=' [command option...]';
	fi;
	if [ -n "${ARGUMENT_OPTIND-}" ]; then
		CMD_OPT+=" ${ARGUMENT_OPTIND}";
	fi;

	echo "Usage: ${PROGRAM}${SYS_OPT} <command>${CMD_OPT}";

	if [ ${#SYSTEM_ARGUMENT_MESSAGES[@]} -gt 0 ]; then
		echo;
		echo 'System options:';
		if ((SHD_BASH)); then
			for ARG in "${!SYSTEM_ARGUMENT_MESSAGES[@]}"; do
				echo "  -${ARG}  ${SYSTEM_ARGUMENT_MESSAGES[${ARG}]}";
			done;
		elif ((SHD_ZSH)); then
			for ARG in "${(@k)SYSTEM_ARGUMENT_MESSAGES[@]}"; do
				echo "  -${ARG}  ${SYSTEM_ARGUMENT_MESSAGES[${ARG}]}";
			done;
		fi;
	fi;

	if [ ${#ARGUMENT_MESSAGES[@]} -gt 0 ]; then
		echo;
		echo 'Command options:';
		if ((SHD_BASH)); then
			for ARG in "${!ARGUMENT_MESSAGES[@]}"; do
				echo "  -${ARG}  ${ARGUMENT_MESSAGES[${ARG}]}";
			done;
		elif ((SHD_ZSH)); then
			for ARG in "${(@k)ARGUMENT_MESSAGES[@]}"; do
				echo "  -${ARG}  ${ARGUMENT_MESSAGES[${ARG}]}";
			done;
		fi;
	fi;
}




#
#	Module initialization function.
#

shd_mod_args_init() {
	local PROGRAM="${1}"; shift;

	shd_arguments_parse "${PROGRAM}" "${@}";

	if ((HELP)); then
		shd_arguments_usage "${PROGRAM}";
		exit 0;
	fi;
}
