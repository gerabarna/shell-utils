#!/usr/bin/env zsh

function path() {
	local help="
Description:
	Path edit convenience utility
Usage: 	
	path [options] [directory paths]
	In case no arguments are supplied the tool simply prints the current contents of the PATH variable.
	If no options provided but arguments are present the -a option is assumed. For other operations please see the options.
Options:
	-a
		Append the supplied paths at the end, after other contents of the PATH variable.
		The operation removes any duplication of the path. (default)
	-p
		Prepend the supplied paths before the contents of the PATH variable. The operation removes any duplication of the path.
	-r
		Remove the supplied path from the PATH variable, wherever it may be in it.
	-s
		Silent mode. Supresses the printing of the PATH variable after the modifications were applied on it
	-l
		Print PATH as a multiline list. Replaces the output of -v mode (cannot combine)
	-v
		Verbose mode. prints the resulting path on the console.
		If no arguments and parameters are supplied this mode is assumed.
		Replaces the output of -l mode (cannot combine)
"
	# set default operation modes (append silently)
	local mode="append";
	local echoMode="false";

	OPTIND=1
	while getopts "aprlhv" opt; do
		case $opt in
			a) mode="append";;
			p) mode="prepend";;
			r) mode="strip";;
			l) echoMode="list";;
			v) echoMode=true;;
			h)
				echo "$help"
				return 0;;
			*)
				>&2 echo "$help"
				return 2;;
		esac
	done

	# this is stupid but without the echo it does not seem to work in zsh...
	shift $(echo $((OPTIND - 1)))
	OPTIND=1

	# if no arguments were supplied, just echo the path end exit
	if (( 0 == $# )); then
		case "$echoMode" in
			list)
				echo $PATH | tr ':' '\n';;
			*)
				echo $PATH;;
		esac
		return 0
	fi

	local new_paths=$(printf "%s:" "$@")
	new_paths=${new_paths%?}

	local element
	# lets make sure the same path does not get appendend multiple times, strip whatever happens
	for element in "$@"; do
		PATH=$(sed "s|:$element:|:|g; s|^$element:||g; s|:$element$||g" <<< $PATH )
	done

	case "$mode" in
		append)
			export PATH="$PATH:$new_paths";;
		prepend)
			export PATH="$new_paths:$PATH";;
	esac
	case "$echoMode" in
		true)
			echo $PATH;;
		list)
			echo $PATH | tr ':' '\n';;
	esac
}
