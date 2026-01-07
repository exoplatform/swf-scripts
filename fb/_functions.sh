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

get_maven_property() {
    mvn -f "$1/pom.xml" -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=$2 | grep -v '\[' 2>/dev/null
}

change_maven_project_version() {
  mvn -f "$1/pom.xml" -q versions:set -DgenerateBackupPoms=false  -DgroupId=$2 -DartifactId=$3 -DnewVersion=$4  &>/dev/null
}

print_help() {
  cat <<EOF
**** Feature Branch Manager ****** 
 ** Created by eXo SWF / ITOP Team

Usage:      $0 -j|--jira ITOP_XXXX -c|--config <configuration_file.json> -a|--action <create|delete> -b|--featurebranch <[Feature/]xxxxxxx>

Config File Sample:

    [
        {
          "git_organization": "exo-xxxxx,
          "git_repository": "eXo-Testing", 
          "git_base_branch": "stable/xxxxxx", // Optional, Default [create]: default branch
          "update": "true or false" // Optional, Default: false, [Caution] overwrite remote branch
        },
        {
          "git_organization": "exo-yyyyy,
           ....
           .... 
        }
    ]

Mandatory commands: git, jq, maven (mvn)            
EOF
}
