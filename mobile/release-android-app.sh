#!/bin/bash

# --> Mandatory CI Parameter
if [[ ! "${OPERATION}" =~ ^(beta|store)$ ]]; then
    echo "Error! Only beta or store is accepted to perform application release"
    exit 1
fi
# <---

# --> Default values. Can be overwrided by CI Job
[ -z "${IMAGE_NAME}" ] && IMAGE_NAME="exoplatform/ci:fastlane-gradle6-android"
[ -z "${STORAGE_URL}" ] && STORAGE_URL='https://storage.exoplatform.org/private/android/'
# <---

# Mandatory Job Parameters/args
set -u
echo "Generating keystore..."
cat >keystore.properties <<EOF
storeFile=/src/eXoPlatform.keystore
storePassword=${STORE_PASSWORD}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASSWORD}
EOF
echo "Done."
# <--
set +u
set -e
echo "Cloning exo-android repository, branch/tag: ${GIT_BRANCH:-develop}"
git clone -b ${GIT_BRANCH:-develop} https://github.com/exoplatform/exo-android
echo "Starting container based on ${IMAGE_NAME} image..."
sudo docker run --rm -v ${PWD}/exo-android:/src \
    -v ${PWD}/keystore.properties:/srv/ciagent/workspace/keystore.properties \
    -e APPALOOSA_EXO_STORE_ID=${APPALOOSA_EXO_STORE_ID:-} \
    -e APPALOOSA_EXO_API_TOKEN=${APPALOOSA_EXO_API_TOKEN:-} \
    ${IMAGE_NAME} android ${OPERATION} || [ "${OPERATION}" = "store" ]
if [ "${OPERATION}" = "store" ]; then
    aabfile=$(find exo-android/app/build/outputs/bundle/store/release -maxdepth 1 -name *.aab | head -n 1)
    curl -T ${aabfile} "${STORAGE_URL}" # May contain credentials to be hidden by Jenkins
    echo "AAB has been released! You can download it from https://storage.exoplatform.org/private/android/$(basename ${aabfile})"
fi
