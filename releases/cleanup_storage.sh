#!/bin/bash -eu
# This Jenkins job script to clean up old CI/CD releases on storage server

if [ -z "${RELEASES_DIR:-}" ]; then 
  echo "Error! This job requires RELEASES_DIR variable to be set! Abort"
  exit 1
fi

if [ -z "${RELEASES_URL:-}" ]; then 
  echo "Error! This job requires RELEASES_URL variable to be set! Abort"
  exit 1
fi

if [ -z "${STORAGE_CRED:-}" ]; then 
  echo "Error! This job requires STORAGE_CRED secret variable to be set! Abort"
  exit 1
fi

currentmonth=$(date +%Y-%m )
CURRENT_MONTH=$(date -d "$currentmonth-15 last month" '+%m') # Previous month -> OK with trailing 0 for digits lower than 10
CURRENT_YEAR=$(date -d "$currentmonth-15 last month" '+%Y') # Previous year if month = 1
CICD_SUFFIX=${CURRENT_YEAR}${CURRENT_MONTH}

echo "Cleaning up release with suffix containing: ${CICD_SUFFIX}..."
pushd ${RELEASES_DIR}
find -name "*-${CICD_SUFFIX}*" -type d -printf '%P\n' | xargs -r -L 1 -I {} curl -H "Authorization: Basic ${STORAGE_CRED}" -XDELETE  "${RELEASES_URL}/private/releases/{}/"
echo "Cleanup done."