#! /bin/echo "This script should be sourced and not executed directly"

#make sure path.sh was sourced, as we rely on it
if ! type path &> /dev/null ; then
	interpreter=$(ps -p $$ -o comm=)
	if [[ $interpreter == *"zsh" ]]; then
		source_dir="${0:h}"
	else
		source_dir=$(dirname ${BASH_SOURCE[0]})
	fi
	path_script_path="$source_dir/path.sh"
	if [[ -e "$path_script_path" ]]; then
		source "$path_script_path"
	else
		>&2 echo "path function not found, and could not source path.sh from expected path=$path_script_path"
	fi
	unset source_dir interpreter path_script_path
fi

[[ ! -v PATHMOD_KNOWN_PATHS ]] && declare PATHMOD_KNOWN_PATHS; export PATHMOD_KNOWN_PATHS

function pathmod() {
	local help="
Description:
	Path modification utility. The primary purpose of the script is to allow quickly adding/removing known subpaths via easy-to-remember keys from the PATH without having to lookup the actual paths
Synopsis:
	pathmod [command] ....
	In case no arguments are supplied the tool simply prints the current contents of the PATH variable. If no options provided but arguments are present the -a option is assumed. For other operations please see the options.
Commands:
	load [...]
		append the paths corresponding to the supplied keys to the PATH and add them to the known commands
	unload [...]
		remove the paths corresponding to the supplied keys from the PATH and remove them from the terminal command list
	add [key] [path]
		add a new key-path pair to the known list of keys
	list
		list all known key-path pairs
"
	local mode="$1";
	shift
	
	local entry_delimiter="|"
	local key_value_delimiter=":"

	if [[ "$mode" == "add" ]]; then
		argument_key=$1
		shift
		argument_value=$(tr ' ' "$key_value_delimiter" <<< "$@")

		unset new_path
		while read -r next_path; do
			local key=$(cut -d"$key_value_delimiter" -f1 <<< "$next_path")
			local value=${next_path#*"$key_value_delimiter"}
			if [[ ! "$key" == "$argument_key" ]] && [[ ! "$key" == "" ]]; then
				[[ -n $new_path ]] && new_path="$new_path$entry_delimiter"
				new_path="$new_path$key$key_value_delimiter$value";
			fi
		done < <(tr "$entry_delimiter" '\n' <<< "$PATHMOD_KNOWN_PATHS")

		[[ -n $new_path ]] && new_path="$new_path$entry_delimiter"
		PATHMOD_KNOWN_PATHS="$new_path$argument_key$key_value_delimiter$argument_value"
		export PATHMOD_KNOWN_PATHS
		return 0
	fi

	while read -r next_path; do
		local key=$(cut -d"$key_value_delimiter" -f1 <<< "$next_path")
		local value=${next_path#*"$key_value_delimiter"}
    if [[ -z $value ]]; then
        continue;
    fi
		case "$mode" in
			load)
				for argument_key in "$@"; do
					if [[ "$argument_key" == "$key" ]]; then
						eval path -p $(sed "s|$key_value_delimiter| -p |g" <<< $value)
					fi
				done;;
			unload)
				for argument_key in "$@"; do
					[[ "$argument_key" == "$key" ]] && eval path -r $(sed "s|$key_value_delimiter| -r |g" <<< $value)
				done;;
			list) echo "$key:$value";;
			*)
				>&2 echo "$help"
				return 1;;
		esac
	done < <(tr "$entry_delimiter" '\n' <<< "$PATHMOD_KNOWN_PATHS")
}
