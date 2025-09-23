#!/usr/bin/env zsh

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

declare -A PATHMOD_KNOWN_PATHS
export PATHMOD_KNOWN_PATHS

function _pathmod_loop_args(){
	local options=$1; shift
	local key=$1; shift
	local mods=${PATHMOD_KNOWN_PATHS[$key]}
	if [[ -z "$mods" ]]; then
		>&2 echo "Unknown mod=$key"
		return 2
	fi
	# we need to allow multiple paths for a single key -> its a space separated list
	local interpreter=$(ps -p $$ -o comm=)
	if [[ $interpreter == *"zsh" ]]; then
		mods_array=("${(@s/ /)mods}")
	else
		read -r -a mods_array <<< "$mods"
	fi
	for mod in "${mods_array[@]}"; do
		path $options $mod
	done
}

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
	local interpreter=$(ps -p $$ -o comm=)
	case "$1" in
		load)
			shift
			for key in "$@"; do
				_pathmod_loop_args -p "$key"

				if [[ $interpreter == *"zsh" ]]; then
					#eval "rehash" # bash will complain if rehash is without eval
					rehash
				else
					hash -r
				fi

			done
			;;
		unload)
			shift
			for key in "$@"; do
				_pathmod_loop_args -r "$key"
				hash -r
			done
			;;
		add)
			shift
			key=$1; shift
			PATHMOD_KNOWN_PATHS[$key]="$@"
			;;
		list)
			if [[ $interpreter == *"zsh" ]]; then
				for key in "${(k)PATHMOD_KNOWN_PATHS[@]}"; do
					echo "$key: ${PATHMOD_KNOWN_PATHS[$key]}"
				done
			else
				for key in "${!PATHMOD_KNOWN_PATHS[@]}"; do
					echo "$key: ${PATHMOD_KNOWN_PATHS[$key]}"
				done
			fi

			;;
		*)
			>&2 echo "$help"
			return 1;;
	esac
}
