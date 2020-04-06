wkdir="/tmp/fbmgnfactory"

echo_err() {
  echo "$(date +'%d/%m/%y %H:%M:%S') |  Error | $*" >>/dev/stderr
}

echo_ok() {
  echo "$(date +'%d/%m/%y %H:%M:%S') |  INFO  | $*"
}

echo_warn() {
  echo "$(date +'%d/%m/%y %H:%M:%S') |  WARN  | $*"
}

exit_with_cleanup() {
 rm -rf $wkdir &>/dev/null
 exit $1
}

validate_json() {
  cat $1 | jq type
}

assert_command() {
  if ! hash $1 &>/dev/null; then 
     echo_err "$1 is not installed !"
     exit 1
  fi
}

valid_repo() {
  [ ! -z "$1" ] && [ ! -z "$(git ls-remote --heads $1 2>/dev/null)" ]
}

print_help() {
  cat <<EOF
**** Feature Branch Manager ****** 
 ** Created by eXo SWF / ITOP Team

Usage:      $0 <configuration_file.json> <action> 

Actions:    create, delete

Config File Sample:

    [
        {
          "name": "Feature/xxxxxxx", 
          "git_organization": "exo-xxxxx,
          "git_repository": "eXo-Testing", 
          "git_base_branch": "stable/xxxxxx", // Optional, Default [create]: default branch
          "update": "true or false" // Optional, Default: false, [Caution] overwrite remote branch
        },
        {
          "name": "Feature/xxxxxxx",
           ....
           .... 
        }
    ]

Mandatory commands: git, jq            
EOF
}
