#
#	Sheldon bootstrapper.
#
#	Requires two variables to be set:
#		- SHELDON_SELF: to specify where Sheldon lives
#		- SHELDON_ROOT: to specify where the project lives that uses Sheldon
#




#
#	Check if we have a valid SHELDON_SELF so we can bootstrap properly.
#

if [ -z "${SHELDON_SELF}" ]; then
	echo 'SHELDON_SELF not set.' >&2;
	exit 1;
fi;

if [ ! -d "${SHELDON_SELF}" ]; then
	echo 'SHELDON_SELF does not point to a valid directory.' >&2;
	exit 1;
fi;

if [ ! -f "${SHELDON_SELF}/bootstrap.sh" ]; then
	echo 'SHELDON_SELF does not seem to point to a valid Sheldon source directory.' >&2;
	exit 1;
fi;




#
#	Check shell.
#

declare SHD_SHELL=`realpath "/proc/$$/exe"`;
declare SHD_SHELL_BASE=`basename "${SHD_SHELL}"`;

unset VAR; declare -u VAR;
case "${SHD_SHELL_BASE}" in
	zsh|bash)
		VAR="SHD_${SHD_SHELL_BASE}";
		declare -i "${VAR}"=1;
		;;
	*)
		echo 'Shell not supported:' "${SHD_SHELL}" >&2;
		exit 1;
		;;
esac;
unset VAR;




#
#	Check if we have commands installed and available in our PATH that we need for bootstrapping.
#

MISSING=();

for NEED in realpath find sort awk; do
	if ! which "${NEED}" >/dev/null 2>&1; then
		MISSING+=("${NEED}");
	fi;
done;

if [ ${#MISSING[@]} -gt 0 ]; then
	echo 'Sheldon cannot run without the following commands available:' "${MISSING[@]}" >&2;
	exit 1;
fi;

unset MISSING;




#
#	We seem to have found ourselves or a valid copy of ourselves, let's initialize.
#

declare SHD_ROOT=`realpath "${SHELDON_SELF}"`;
declare -A SHD_MODULES_LOADED=();
declare -A SHD_MODULE_INITIALIZERS=();




#
#	And declare some bootstrapping functions.
#

shd_module_register() {
	local MODULE_PATH="${1}"; shift;

	if ((!SHD_MODULES_LOADED[${MODULE_PATH}])); then
		SHD_MODULES_LOADED[${MODULE_PATH}]=1;
		return 0;
	else
		return 1;
	fi;
}

shd_function_exists() {
	local FUN;
	for FUN in "${@}"; do
		if ! declare -f "${FUN}" >/dev/null 2>&1; then
			return 1;
		fi;
	done;

	return 0;
}




#
#	Let's load the rest.
#

for SHD_MODULE in `find "${SHD_ROOT}" -mindepth 2 -type f -not -executable -name '*.sh'`; do
	if shd_module_register "${SHD_MODULE}"; then
		unset \
			MODULE_INIT \
			MODULE_PRIORITY;

		. "${SHD_MODULE}";

		if [ ${#MODULE_INIT} -eq 0 ]; then
			# Continue, no module initializer specified.
			continue;
		fi;

		if [ $((MODULE_PRIORITY)) -lt 1 ]; then
			echo 'Invalid module initialization priority specified:' "$((MODULE_PRIORITY))" >&2;
			exit 1;
		fi;

		if ! shd_function_exists "${MODULE_INIT}"; then
			echo 'Module initialization function does not exist:' "${MODULE_INIT}" >&2;
			exit 1;
		fi;

		if [ $((SHD_MODULE_INITIALIZERS[${MODULE_INIT}])) -gt 0 ]; then
			echo 'Function name already used before, refusing to bootstrap. Function:' "${MODULE_INIT}" >&2;
			exit 1;
		fi;

		# Register module initializer priority.
		SHD_MODULE_INITIALIZERS[${MODULE_INIT}]=$((MODULE_PRIORITY));
	fi;
done;




#
#	Fire module initialization functions.
#
#	Sorts registered initializers by priority, from low to high, and executes them after having double-checked if the functions really exist.
#
#	Since while loops that take input create a subshell, nothing would end up being really initialized, so we work ourselves around that.
#	Aside from that, Zsh and Bash both have different flavors of looping through associative arrays, hence the "double" implementation.
#

declare FUNCTION;
while read LINE; do
	FUNCTION=`echo "${LINE}" | awk '{ print $2; };'`;

	if ! shd_function_exists "${FUNCTION}"; then
		echo 'Huh? Function does not exist:' "${FUNCTION}";
	fi;

	"${FUNCTION}" "${0}" "${@}";
done < <(
	declare -i PRIORITY=0;

	if ((SHD_BASH)); then
		for FUN in "${!SHD_MODULE_INITIALIZERS[@]}"; do
			PRIORITY=$((SHD_MODULE_INITIALIZERS[${FUN}]));
			echo "$((PRIORITY)) ${FUN}";
		done;
	elif ((SHD_ZSH)); then
		for FUN in "${(@k)SHD_MODULE_INITIALIZERS[@]}"; do
			PRIORITY=$((SHD_MODULE_INITIALIZERS[${FUN}]));
			echo "$((PRIORITY)) ${FUN}";
		done;
	fi | sort -n;

	unset PRIORITY;
);
