#! /bin/echo "This script should be sourced and not executed directly"

function java-swap() {
  if [[ -z "$1" ]]; then
      echo "ERROR: Please supply the desired Java alternative number as an argument." >&2
      echo "Current installed alternatives:"
      update-alternatives --list java
      return 1
  fi

  version="$1"
  local java_target=$(update-alternatives --list java | grep -e "-$version-")

  if [[ -x "$java_target" ]]; then
      # Remove the trailing '/bin/java' part to get the JDK HOME path
      local java_bin=$(dirname "$java_target")
      local java_home=$(dirname "$java_bin")

      path -r "$(path -f 'java')"
      path -p "$java_bin"

      export JAVA_HOME="$java_home"
      export JDK_HOME="$java_home"

      echo "Java environment updated to $java_home"
      return 0
  else
      echo "ERROR: Java binary not found at $java_target" >&2
      return 1
  fi
}