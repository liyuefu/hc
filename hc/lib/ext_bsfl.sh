#!/usr/bin/env bash
#######functions from other libs. such as pure-bash-bible, lobash 
####### https://github.com/liyuefu/pure-bash-bible#####
####### https://github.com/adoyle-h/lobash
dirname() {
    # Usage: dirname "path"
    local tmp=${1:-.}

    [[ $tmp != *[!/]* ]] && {
        printf '/\n'
        return
    }

    tmp=${tmp%%"${tmp##*[!/]}"}

    [[ $tmp != */* ]] && {
        printf '.\n'
        return
    }

    tmp=${tmp%/*}
    tmp=${tmp%%"${tmp##*[!/]}"}

    printf '%s\n' "${tmp:-/}"
}

basename() {
    # Usage: basename "path" ["suffix"]
    local tmp

    tmp=${1%"${1##*[!/]}"}
    tmp=${tmp##*/}
    tmp=${tmp%"${2/"$tmp"}"}

    printf '%s\n' "${tmp:-/}"
}

###################str function ################
# ---
# Category: String
# Since: 0.5.0
# Usage: str_replace <string> <pattern> <replace>
# Description: The first longest match of `<pattern>` is replaced with `<replace>`.
# ---

str_replace() {
  local pattern=${2:-}
  if [[ $pattern =~ ^'#' ]]; then pattern="\\$pattern" ; fi
  if [[ $pattern =~ ^'%' ]]; then pattern="\\$pattern" ; fi
  echo "${1/$pattern/${3:-}}"
}

# ---
# Category: String
# Since: 0.5.0
# Usage: str_replace_all <string> <pattern> <replace>
# Description: All matches of `<pattern>` are replaced with `<replace>`.
# ---

str_replace_all() {
  echo "${1//${2:-}/${3:-}}"
}


# ---
# Category: String
# Since: 0.5.0
# Usage: str_replace_last <string> <pattern> <replace>
# Description: The first longest match of `<pattern>` is replaced with `<replace>`. But it matches from the end of string to the head.
# ---

str_replace_last() {
  echo "${1/%${2:-}/${3:-}}"
}

# ---
# Category: Condition
# Since: 0.3.0
# Usage: is_dir <path>
# Description: Detect `<path>` is whether a directory or not.
# Description: Return 0 (true) or 1 (false). This function should never throw exception error.
# ---

is_dir() {
  [[ -d ${1:-} ]]
}


# ---
# Category: Condition
# Since: 0.6.0
# Usage: is_empty_dir <path>
# Description: Test `<path>` is whether a empty directory or not. If directory not found, it returns false.
# Description: Return 0 (true) or 1 (false). This function should never throw exception error.
# ---

is_empty_dir() {
  [[ -d ${1:-} ]] && [[ -z $(ls -A "${1:-}") ]]
}


# ---
# Category: String
# Since: 0.1.0
# Usage: match "string" "regex" [index=1]
# Description: Return matched part of string. Return empty string if no matched. Support capturing groups.
# ---

match() {
  [[ ${3:-} == 0 ]] && echo "index cannot be 0" >&2 && return 3

  if [[ $1 =~ $2 ]]; then
    if (( ${#BASH_REMATCH[@]} > 1 )); then
      printf '%s\n' "${BASH_REMATCH[${3:-1}]}"
    else
      echo ''
    fi
  else
    echo ''
  fi
}


# ---
# Category: Condition
# Since: 0.3.1
# Usage: str_include <string> <sub-string>
# Description: Return `true` or `false`. Check if a string includes given match string.
# ---

# shellcheck disable=SC2076

str_include() {
  [[ ${2:-} == '' ]] && return 0
  [[ "${1:-}" =~ "${2:-}" ]]
}


# ---
# Category: String
# Since: 0.1.0
# Usage: str_len <string>
# Description: Return the byte length of string.
# ---

str_len() {
  [[ -z ${1:-} ]] && echo 0 && return

  local old_lang old_lc_all bytlen
  [[ -n ${LC_ALL:-} ]] && old_lc_all=$LC_ALL
  [[ -n ${LANG:-} ]] && old_lang=$LANG

  LANG=C LC_ALL=C
  bytlen=${#1}
  printf -- '%s\n' "$bytlen"

  [[ -n ${old_lang:-} ]] && LANG=$old_lang
  if [[ -n ${old_lc_all:-} ]]; then
    LC_ALL=$old_lc_all
  fi
}


# ---
# Category: Condition
# Since: 0.3.1
# Usage: start_with <string> <match>
# Description: Check if a string starts with given match string.
# Description: Return 0 (true) or 1 (false). This function should never throw exception error.
# ---

start_with() {
  [[ $1 =~ ^"$2" ]]
}

# ---
# Category: Condition
# Since: 0.3.1
# Usage: end_with <string> <match>
# Description: Return 0 (true) or 1 (false). This function should never throw exception error.
# ---

end_with() {
  [[ $1 =~ "$2"$ ]]
}

# ---
# Category: string
# Usage: extract <string> <start-string> <end-string>
# Description: Return string between <start-string> and <end-string> .
# ---

extract()
{
  local string="$1"
  local start="$2"
  local end="$3"
  cat > ./str_between.sed <<EOF
  s|.*${start}\([^\]*\)${end}.*$|\1|p
EOF
  echo ${string} | sed -n -f ./str_between.sed
}
###########################input#######################
# ---
# Category: Prompt
# Since: 0.2.0
# Usage: ask_input [<message>='Ask Input:'] [<default>]
# Description: Print a message and read user input from stdin.
# Description: If `<default>` provided, return it when user type empty.
# ---

ask_input() {
  local answer prompt
  local default=${2:-}
  if (( $# < 2 )); then
    prompt="${1:-Ask Input:} "
  else
    prompt="${1:-Ask Input:} (Default: $default) "
  fi

  read -rp "$prompt" answer
  printf '%s\n' "${answer:-$default}"
}


# file exists and not empty
file_exists_and_not_empty() {
  if [[ -f "$1" ]] && [[ -s "$1" ]]; then
    return 0;
  else
    return 1;
  fi
}
