#!/bin/bash -eu
# Script to test eXo Platform upgrades

PLF_VERSION_BASE=4.4.2_2
PLF_VERSION_NEW=4.4_latest

export DB_TYPE=mysql
export DB_VERSION=5.7.13

failed=false

function startAll() {
  export PLF_VERSION=$1
  
  echo "####### Starting PLF ${PLF_VERSION}..."
  docker-compose up -d
}

function stopPLF() {
  echo "####### Stopping PLF ${PLF_VERSION}..."
  docker-compose rm -s -f exo
}

function stopAll() {
  echo "####### Stopping PLF ${PLF_VERSION}..."
  docker-compose rm -s -f
}

function monitorLogs() {
  # Empty result file
  echo "" > result
  # variable used in while loop to know if the startup has failed
  localFailed=false
  docker-compose logs -f exo | while read line
  do
    echo "$line"
    if [[ "$line" == *"Server startup"* ]]
    then
      if [ "$localFailed" = false ] ; then
        echo "####### Server started successfully !"
      fi
      break
    fi

    if [[ "$line" == *"ERROR"* ]]
    then
      # mark startup as fail, but do not exit in order to have full logs
      localFailed=true
      # store the failure in a temp file because we cannot directly update 'failed' variable since the while loop is executed in a sub-shell
      echo "true" > result
    fi
  done

  tmpFailed=`cat result`
  if [ "$tmpFailed" = true ] ; then
    failed=true
  fi
}

# first PLF version
startAll ${PLF_VERSION_BASE}
monitorLogs
stopPLF

# check for errors
if [ "$failed" = true ] ; then
  echo "####### Error during startup of the first PLF !"
  stopAll
  exit 1
fi

# new PLF version
startAll ${PLF_VERSION_NEW}
monitorLogs
stopAll

# check for errors
if [ "$failed" = false ] ; then
  echo "####### PLF upgrade successful !"
  exit 0
else
  echo "####### Error during startup of the new PLF !"
  exit 1
fi