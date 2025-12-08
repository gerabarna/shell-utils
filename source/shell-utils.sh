#! /bin/echo "This script should be sourced and not executed directly"

# This script is intended to handle smart sourcing all other sourced scripts so users don't need to source all files
# manually
# Please note that by default most files are sourced in a LAZY fashion. Meaning they just have a placeholder
# which ensures they are sourced before the first usage of the specific script, the sourcing does not occur until than.

if [[ -z $BASH_SOURCE ]]; then
	script_path="${(%):-%x}"
else
	script_path="${BASH_SOURCE[0]}"
fi

script_name=$(basename "$script_path")
containing_folder=$(dirname "$script_path" | xargs realpath)

scripts=()
saved_IFS=$IFS
while IFS= read -r -d '' file_path; do
	simple_name=$(basename "$file_path")
	if [[ ! "$script_name" == *$simple_name ]]; then
    scripts+=("$file_path")
  fi
done < <(find "$containing_folder" -maxdepth 1 -type f -print0)
IFS=$saved_IFS
unset saved_IFS

for script in "${scripts[@]}"; do
	name=$(basename "$script")
	if [[ "$name" == *.sh ]]; then
		name=${name%.sh}
	fi
	case $name in
		pathmod)
			. "$script" ;;
		*)
				eval "function $name() {
      		unset -f $name
      		source $script
      		$name "'"$@"'"
      	}"
	esac
done

unset scripts script script_name containing_folder