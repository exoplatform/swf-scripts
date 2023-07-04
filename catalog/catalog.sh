#!/bin/bash -eu

set +u

if [ -z "${CATALOG_SCRIPT_URL}" ]; then
	echo "[ERROR] No value for CATALOG_SCRIPT_URL environment variable"
	echo "Check the Readme.md file for more information"
	exit 1
fi

if [ -z "${CATALOG_PATH}" ]; then
	echo "[ERROR] No value for CATALOG_PATH environment variable"
	echo "Check the Readme.md file for more information"
	exit 1
fi

[ "${ENVIRONMENT}" == "DEFAULT" ] && ENVIRONMENT=""
[ -z "${CUSTOMER}" ] && CUSTOMER=""
[ -z "${BUILD_URL}" ] && BUILD_URL=""

shopt -s nocasematch
TASK_TITLE=""
if [ -z "${TASK_ID}" ] || [[ ! "${TASK_ID}" =~ ^(ta(sk)?-)?[0-9]+$ ]]; then
	TASK_ID=""
else
	TASK_ID=$(echo "${TASK_ID}" | tr -dc '0-9')
	TASK_TITLE=$(curl -s -L -u $TRIBE_AGENT_USERNAME:$TRIBE_AGENT_PASSWORD "$TRIBE_TASK_REST_PREFIXE_URL/logs/${TASK_ID}" 2>/dev/null | jq .[0].task.title | tr -d '"')
	[ -z "${TASK_TITLE}" ] || echo "Task title: "${TASK_TITLE}
fi

set -u
REQ_PARAMS='catalog=official&show=snapshot'
CATALOG_FILE_NAME="list.json"
if [ -n "${CUSTOMER}" ]; then
	if [ -z "${ENVIRONMENT}" ] || [[ ! ${ENVIRONMENT} =~ ^(acceptance|hosting|meeds)$ ]]; then
		echo "You must provide a valid environment (acceptance|hosting|meeds)"
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
curl -f -L "${CATALOG_SCRIPT_URL}/exec?${REQ_PARAMS}" >/tmp/list-new.json
if ! cat /tmp/list-new.json | jq '.' >/dev/null; then
  echo "Invalid new catalog! please check gapp script!"
  exit 1
fi
echo "Backing up old catalog..."
if ! cp -vf ${CATALOG_PATH}/${CATALOG_FILE_NAME} /tmp/list-old.json; then
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
	echo "   Preparing script ..."
	OLD_NAME=$(date +%Y%m%d_%H%M%S-${CATALOG_FILE_NAME})
	gpg -b --armor --passphrase ${GPG_PASSWORD} --batch /tmp/list-new.json
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
[ -f /tmp/list-new.json.asc ] && mv -v /tmp/list-new.json.asc ${CATALOG_PATH}/${CATALOG_FILE_NAME}.asc
[ -f ${CATALOG_PATH}/${CATALOG_FILE_NAME}.asc ] && chown www-data: ${CATALOG_PATH}/${CATALOG_FILE_NAME}.asc
EOF
	echo "   Changing script permissions..."
	chmod u+x /tmp/update_catalog.sh
	echo "   Executing script..."
	sudo /tmp/update_catalog.sh
	rm /tmp/update_catalog.sh
	echo "Catalog updated"
	if [ ! -z "${TASK_TITLE}" ]; then
		echo "Posting commments to task #${TASK_ID}..."
		rm -f /tmp/splittedComment*
		rm -f /tmp/formattedComment*
		# Check if comment split is needed or not according to },{ occurences
		jsonItemsLength=$(grep -o '},{' /tmp/list.diff | wc -l)
		if [ ${jsonItemsLength} -gt "1" ]; then
			if [ ${jsonItemsLength} -lt "10" ]; then
				awk '{print $0 > "/tmp/splittedComment" NR}' RS='},{' /tmp/list.diff
				splittedCommentsLength=$(ls /tmp/splittedComment* | wc -l)
				j=1
				set -e
				echo -e "<pre>\n$(cat /tmp/splittedComment1)" >/tmp/splittedComment1
				echo -e "$(cat /tmp/splittedComment${splittedCommentsLength} | head -n 2)\n</pre>" >/tmp/splittedComment${splittedCommentsLength}
				for i in $(seq 2 $((${splittedCommentsLength} - 1))); do
					echo "$(cat /tmp/splittedComment1)},{" >/tmp/formattedComment$j
					echo "$(cat /tmp/splittedComment$i)},{" >>/tmp/formattedComment$j
					cat /tmp/splittedComment${splittedCommentsLength} >>/tmp/formattedComment$j
					sed -i "s/\"/'/g" /tmp/formattedComment$j
					sed -ir '/^\s*$/d' /tmp/formattedComment$j
					sed -i 's/$/<br>/' /tmp/formattedComment$j
					sed -i 's/pre><br>/pre>/g' /tmp/formattedComment$j
					printf "Posting comment #$j..."
					curl -s -L -u $TRIBE_AGENT_USERNAME:$TRIBE_AGENT_PASSWORD -XPOST --data-urlencode "@/tmp/formattedComment$j" "$TRIBE_TASK_REST_PREFIXE_URL/comments/${TASK_ID}" &>/dev/null && echo "OK" || echo "ERROR"
					((j++))
				done
			elif [ ! -z "${BUILD_URL}" ]; then
				echo "The number of JSON elements exceeds 10, Posting the CI Build URL instead."
				echo "Catalog Updated - CI Build URL: ${BUILD_URL}console" >/tmp/formattedComment
				printf "Posting comment..."
				curl -s -L -u $TRIBE_AGENT_USERNAME:$TRIBE_AGENT_PASSWORD -XPOST --data-urlencode "@/tmp/formattedComment" "$TRIBE_TASK_REST_PREFIXE_URL/comments/${TASK_ID}" &>/dev/null && echo "OK" || echo "ERROR"
			fi
		else
			set -e
			echo -e "<pre>\n$(cat /tmp/list.diff)" >/tmp/formattedComment
			sed -i "s/\"/'/g" /tmp/formattedComment
			sed -ir '/^\s*$/d' /tmp/formattedComment
			sed -i 's/$/<br>/' /tmp/formattedComment
			echo "</pre>" >> /tmp/formattedComment
			printf "Posting comment..."
			curl -s -L -u $TRIBE_AGENT_USERNAME:$TRIBE_AGENT_PASSWORD -XPOST --data-urlencode "@/tmp/formattedComment" "$TRIBE_TASK_REST_PREFIXE_URL/comments/${TASK_ID}" &>/dev/null && echo "OK" || echo "ERROR"
		fi
		set +e
		rm -f /tmp/splittedComment*
		rm -f /tmp/formattedComment*
	fi
fi
