SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)


${SCRIPTDIR}/replaceInFile.sh $1 $2 "pom.xml -not -wholename \"*/target/*\""
