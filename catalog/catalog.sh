#!/bin/bash -eu

set +u
if [ ! -f "$HOME/.catalog.env" ]; then
	echo "[ERROR] The configuration file ${HOME}/.catalog.env not found"
	echo "Check the Readme.md file for more information"
	exit 1
fi

source ~/.catalog.env

if [ -z "${CATALOG_URL}" ]; then
	echo "[ERROR] No CATALOG_URL property found in the configuration file"
	echo "Check the Readme.md file for more information"
	exit 1
fi
set -u

CUSTOMER=''
ENVIRONMENT=''
OPERATION=''

while getopts "c:e:o:" opt; do
	case $opt in
	c)
		CUSTOMER=${OPTARG}
		echo "Catalog will be generated for customer ${CUSTOMER}"
		;;
	e)
		ENVIRONMENT=${OPTARG}
		echo "Catalog will be generated for environment ${ENVIRONMENT}"
		;;
	o)
		OPERATION=${OPTARG}
		;;
	*)
		echo "Unsupported option -${opt}"
		exit 1
		;;
	esac
done

REQ_PARAMS='catalog=official&show=snapshot'
CATALOG_FILE_NAME="list.json"
if [ -n "${CUSTOMER}" ]; then
	if [ -z "${ENVIRONMENT}" ]; then
		echo "You must provide an environment (acceptance|hosting)"
		exit 1
	fi
	REQ_PARAMS="&customer=${CUSTOMER}&catalog=${ENVIRONMENT}"
	CATALOG_FILE_NAME="${ENVIRONMENT}-${CUSTOMER}-list.json"
elif [ -n "${ENVIRONMENT}" ]; then
	REQ_PARAMS="&catalog=${ENVIRONMENT}"
	CATALOG_FILE_NAME="${ENVIRONMENT}-list.json"
fi

if [[ ! ${OPERATION} =~ ^(VIEW|VALIDATE)$ ]]; then
	echo "You must provide an operation (VIEW|VALIDATE)"
	exit 1
fi
echo "Operation ${OPERATION} will be performed by user: $USER"

echo "Downloading new catalog...."
curl -f -L "${CATALOG_URL}/exec?${REQ_PARAMS}" >/tmp/list-new.json
echo "Download old catalog..."
if ! scp ${CATALOG_HOST}:${CATALOG_PATH}/${CATALOG_FILE_NAME} /tmp/list-old.json; then
	echo Unable to find old remote catalog
	rm -f /tmp/list-old.json
	touch /tmp/list-old.json
fi

echo "Comparing catalogs...."
set +e
diff -U3 /tmp/list-old.json /tmp/list-new.json >/tmp/list.diff
set -e
if [ ! -s /tmp/list.diff ]; then
	echo "Catalog is up to date"
	exit
fi
cat /tmp/list.diff
if [ ${OPERATION} == "VALIDATE" ]; then
	echo "Updating catalog...."
	echo "   Uploading new catalog..."
	scp /tmp/list-new.json ${CATALOG_HOST}:/tmp/list-new.json
	echo "   Preparing script ..."

	OLD_NAME=$(date +%Y%m%d_%H%M%S-${CATALOG_FILE_NAME})

	cat <<EOF >/tmp/update_catalog.sh
#!/bin/bash -eu

echo Copying ${CATALOG_FILE_NAME} to ${OLD_NAME}
if [ -e "${CATALOG_PATH}/${CATALOG_FILE_NAME}" ]; then
  cp -v ${CATALOG_PATH}/${CATALOG_FILE_NAME} ${CATALOG_PATH}/${OLD_NAME}
else
  echo "Previous catalog file ${CATALOG_PATH}/${CATALOG_FILE_NAME} not found"
fi

mv -v /tmp/list-new.json ${CATALOG_PATH}/${CATALOG_FILE_NAME}
chown www-data: ${CATALOG_PATH}/${CATALOG_FILE_NAME}
EOF
	echo "   Copying script ..."
	scp -C /tmp/update_catalog.sh ${CATALOG_HOST}:
	echo "   Changing script permissions..."
	ssh ${CATALOG_HOST} chmod u+x update_catalog.sh
	echo "   Executing script..."
	ssh -t ${CATALOG_HOST} sudo ./update_catalog.sh
	echo "Catalog updated"
fi
