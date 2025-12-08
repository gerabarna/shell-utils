#! /bin/echo "This script should be sourced and not executed directly"

function path() {
  local help="
Usage: 	
	path [-o <arg>]... [-o] [<arg>]...
	In case no arguments are supplied the tool simply prints the current contents of the PATH variable.
	If no options provided but arguments are present the -a option is assumed. For other operations please see the options.
	options with arguments are repeatable and respect declaration order.
Options:
	-a | --append <path>...
		Append the supplied paths at the end, after other contents of the PATH variable.
		The operation removes any duplication of the path. (default)
	-p | --prepend <path>...
		Prepend the supplied paths before the contents of the PATH variable. The operation removes any duplication of the path.
	-r | --remove | --strip <path>...
		Remove the supplied path from the PATH variable, wherever it may be in it.
	-l | --list
		Print PATH as a multiline list. Replaces the output of -v mode (cannot combine)
	-f | --find <grep pattern>...
		Find and pretty print related items in path
	-v
		Verbose mode. prints the resulting path on the console.
		If no arguments and parameters are supplied this mode is assumed.
		Replaces the output of -l mode (cannot combine)
"
	OPTS=$(getopt -o a:p:r:f:lvh --long append:,prepend:,remove:,find:,list,verbose,help -n 'script' -- "$@")
	if [ $? != 0 ] ; then
		echo "$help" >&2
		return 1;
	fi
	eval set -- "$OPTS"

	local append=()
	local prepend=()
	local remove=()
	local find=()
	echoMode="false"
	while true; do
		case "$1" in
			-a | --append)
				append+=("$2")
				remove+=("$2")
				shift 2;;
			-p | --prepend)
				prepend+=("$2")
				remove+=("$2")
				shift 2;;
			-r | --remove | --strip)
				remove+=("$2")
				shift 2;;
			-f | --find)
				echoMode="find"
				find+=("$2")
				shift 2;;
			-l | --list) echoMode="list"; shift;;
			-v | --verbose) echoMode=true; shift;;
			-h | --help)
				printf "Description:\n	Path edit convenience utility \n$help"
				return 0;;
			--)
				shift;
				break;;
		esac
	done

  append+=("$@") # if no options are supplied treat args as 'append'

	local element
	# lets make sure the same path does not get appendend multiple times, strip whatever happens
	for element in "${remove[@]}"; do
		PATH=$(sed "s|:$element:|:|g; s|^$element:||g; s|:$element$||g" <<< $PATH )
	done
	for element in "${append[@]}"; do
  	export PATH="$PATH:$element";
  done
	for element in "${prepend[@]}"; do
  	export PATH="$element:$PATH";
  done
	case "$echoMode" in
		find)
			for element in "${find[@]}"; do
				echo $PATH | tr ':' '\n' | grep "$element";
			done;;
		true)
			echo $PATH;;
		list)
			echo $PATH | tr ':' '\n';;
	esac
}
