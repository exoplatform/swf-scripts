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

create_view_template() {
	mkdir -p ~/.jira.d/templates
	cat <<EOF >~/.jira.d/templates/catalog_view
{{/* view template */ -}}
issue: {{ .key }} 
{{if .fields.created -}} 
created: {{ .fields.created | age }} ago
{{end -}}
{{if .fields.status -}}
status: {{ .fields.status.name }}
{{end -}}
summary: {{ .fields.summary }}
EOF

}

display_jira_issue() {
	jira view -t catalog_view $1
}

comment_jira_issue() {
	jira comment --noedit $1 -m "$(cat $2)"
}

resolve_jira_issue() {
	jira resolve $1
}

RESOLVE_ISSUE=false
CUSTOMER=''
ENVIRONMENT=''
JIRA_ID=''

while getopts "rc:e:j:" opt; do
	case $opt in
	r)
		echo "Jira issue will be resolved"
		RESOLVE_ISSUE=true
		;;
	c)
		CUSTOMER=${OPTARG}
		echo "Catalog will be generated for customer ${CUSTOMER}"
		;;
	e)
		ENVIRONMENT=${OPTARG}
		echo "Catalog will be generated for environment ${ENVIRONMENT}"
		;;
	j)
		JIRA_ID=${OPTARG}
		echo "Jira issue : ${JIRA_ID}"
		;;
	esac
done

if [ -z "${JIRA_ID}" ]; then
	echo "You must provide a -j <issue> parameter"
	exit 1
fi

create_view_template

display_jira_issue ${JIRA_ID}

read -p "Is this correct (Y/n) ? " response
response=${response:-Y}

if [ "$response" != "y" -a "$response" != "Y" ]; then
	echo "Aborting catalog update"
	exit 1
fi

echo "Downloading new catalog...."
REQ_PARAMS='catalog=official&show=snapshot'
CATALOG_FILE_NAME="list.json"
if [ -n "${CUSTOMER}" ]; then
	if [ -z "${ENVIRONMENT}" ]; then
		echo "You must provide an environment (acceptance|hosting)"
		exit 1
	fi
	REQ_PARAMS="&customer=${CUSTOMER}&catalog=${ENVIRONMENT}"
	CATALOG_FILE_NAME="${ENVIRONMENT}-${CUSTOMER}-list.json"
fi
curl -f -L "${CATALOG_URL}/exec?${REQ_PARAMS}" >/tmp/list-new.json
echo "Download old catalog..."
if ! scp ${CATALOG_HOST}:${CATALOG_PATH}/${CATALOG_FILE_NAME} /tmp/list-old.json; then
  echo Unable to find old remote catalog
  
  read -p "Continue (Y/n) ? " response
  response=${response:-Y}

  if [ "$response" != "y" -a "$response" != "Y" ]; then
    echo "Aborting..." 
    exit 1
  else
    rm -f /tmp/list-old.json
    touch /tmp/list-old.json
  fi
fi

echo "Comparing catalogs...."
set +e
diff -U3 /tmp/list-old.json /tmp/list-new.json >/tmp/list.diff
set -e
echo "Preparing commit message..."
if [ -n "${CUSTOMER}" ]; then
	echo "${CUSTOMER} - ${ENVIRONMENT} - catalog updated :" >/tmp/comment
else
	echo "catalog updated :" >/tmp/comment
fi
echo "{noformat}" >>/tmp/comment
cat /tmp/list.diff >>/tmp/comment
echo "{noformat}" >>/tmp/comment
less /tmp/comment

read -p "Update catalog (Y/n) ? " response
response=${response:-Y}

if [ "$response" == "y" -o "$response" == "Y" ]; then
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
	echo "Comment jira issue ${JIRA_ID}"
	comment_jira_issue $JIRA_ID /tmp/comment

	if [ "${RESOLVE_ISSUE}" = "true" ]; then
		echo "Changing status of ${JIRA_ID} to resolved ..."
		resolve_jira_issue $JIRA_ID
	fi

fi
