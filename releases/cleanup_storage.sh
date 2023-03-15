#!/bin/bash -eu
# This Jenkins job script to clean up old CI/CD releases on storage server

if [ -z "${RELEASES_DIR:-}" ]; then 
  echo "Error! This job requires RELEASES_DIR variable to be set! Abort"
  exit 1
fi

currentmonth=$(date +%Y-%m )
CURRENT_MONTH=$(date -d "$currentmonth-15 last month" '+%m') # Previous month -> OK with trailing 0 for digits lower than 10
CURRENT_YEAR=$(date -d "$currentmonth-15 last month" '+%Y') # Previous year if month = 1
CICD_SUFFIX=${CURRENT_YEAR}${CURRENT_MONTH}

echo "Cleaning up release with suffix containing: ${CICD_SUFFIX}..."
find ${RELEASES_DIR} -name "*-${CICD_SUFFIX}*" -type d | xargs -r rm -rvf
echo "Cleanup done."