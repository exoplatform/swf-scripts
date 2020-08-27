#!/bin/bash

if [ -z "${SERVER_URL}" ]; then
    echo "Error: SERVER_URL must not be empty."
    exit 1
fi

if [ -z "${COUNT}" ] || [ "${COUNT}" -lt 1 ]; then
    echo "Error: COUNT must be greater than 0."
    exit 1
fi

if [ ! -z "${COUNT}" ] && [ "${COUNT}" -gt 3000 ]; then
    echo "Error: Only 3000 is allowed to create users/spaces."
    exit 1
fi

if [ -z "${START_FROM}" ] || [ "${START_FROM}" -lt 0 ]; then
    echo "Error: START_FROM must be positive."
    exit 1
fi

if [[ ! "${TYPE}" =~ ^(spaces|users)$ ]]; then
    echo "Error: TYPE must be spaces or users."
    exit 1
fi

if [ -z "${ADMIN_USERNAME}" ]; then
    echo "Using \"root\" as default admin username"
fi

if [ -z "${ADMIN_PASSWORD}" ]; then
    echo "Using \"PASSWORD\" as default admin password"
fi

if [ -z "${USE_AVATARS}" ]; then
    USE_AVATARS="false"
fi

if [ -z "${USE_FORMALNAMES}" ]; then
    USE_FORMALNAMES="false"
fi

if [ -z "${USE_TRUEUSERNAMES}" ]; then
    USE_TRUEUSERNAMES="false"
fi

if [ -z "${USERS_PASSWORD}" ]; then
    USERS_PASSWORD="123456"
fi

set -e
if wget --spider "https://${SERVER_URL}" &>/dev/null; then
    baseurl="https://${SERVER_URL}"
else
    baseurl="http://${SERVER_URL}"
fi
url="$baseurl/rest/private/v1/social/users"
auth="${ADMIN_USERNAME}:${ADMIN_PASSWORD}"
line='--------------------------------------------------------------------'
if [ "${TYPE}" = "users" ]; then
    if [ -z "${PREFIX}" ]; then
        PREFIX="user"
    fi
    maxIndex=$((${COUNT} + ${START_FROM} - 1))
    counter=1
    userIndex=${START_FROM}
    until [ $userIndex -gt $maxIndex ]; do
        if ${USE_FORMALNAMES}; then
            trycount=1
            personJson=""
            set +e
            while [ -z "$personJson" ] && [ $trycount -le 3 ]; do
                personJson=$(wget -qO- https://randomuser.me/api/)
                if [ -z "$personJson" ]; then
                    echo "Warning: Could not get random user details! Retry ($trycount/3)"
                fi
                ((trycount++))
            done
            set -e
            [ -z "$personJson" ] && echo "Error: Failed to get user details from Random User Rest Api" && return
            firstname=$(echo $personJson | jq '.results[0].name.first' | tr -d '"')
            lastname=$(echo $personJson | jq '.results[0].name.last' | tr -d '"')
            echo $firstname | grep -qP "^[a-zA-Z éèçà]+$" || continue
            echo $lastname | grep -qP "^[a-zA-Z éèçà]+$" || continue
        else
            firstname=$(head -c 500 /dev/urandom | tr -dc "a-z" | fold -w 6 | head -n 1)
            lastname=$(head -c 500 /dev/urandom | tr -dc "a-z" | fold -w 6 | head -n 1)
        fi
        data="{\"id\": \"$userIndex\","
        username="${PREFIX}$userIndex"
        $USE_TRUEUSERNAMES && username="$(echo $firstname.$lastname | sed 's/./\L&/g' | sed -E 's/\s+/./g' | sed -e 's/ç/c/g' -e 's/à/a/g' -e 's/é/e/g' -e 's/è/e/g')"
        data+="\"username\": \"$username\","
        data+="\"lastname\": \"$lastname\","
        data+="\"firstname\": \"$firstname\","
        data+="\"fullname\": \"$username\","
        data+="\"password\": \"$USERS_PASSWORD\","
        data+="\"email\": \"$username@exomail.org\"}"
        curlCmd="curl -s -L -w '%{response_code}' -X POST -u "$auth" -H \"Content-Type: application/json\" --data '$data' $url | grep -o  '[1-4][0-9][0-9]'"
        outputmsg="$(printf '%-6s' $counter/${COUNT}:) ID=\"$username\", Full Name=\"$firstname $lastname\" "
        printf "%-80s" "$outputmsg"
        httprs=$(eval $curlCmd)
        if [[ "$httprs" =~ "200" ]]; then echo "[ OK ]"; else echo "[ Fail ]"; fi
        if [[ "$httprs" =~ "200" ]] && ${USE_AVATARS}; then
            printf "Avatar..."
            uploadId=$(date +"%s")
            curl -s -o /tmp/$uploadId.jpg $(echo $personJson | jq '.results[0].picture.large' | tr -d '"')
            uploadCMD="curl -s -L -w '%{response_code}' -X POST '$baseurl/portal/upload?uploadId=$uploadId&action=upload' -F upload=@/tmp/$uploadId.jpg  | grep -o  '[1-4][0-9][0-9]'"
            uploadHTTPRS=$(eval $uploadCMD)
            if [[ "$uploadHTTPRS" =~ "200" ]]; then
                printf "[ Uploaded ]..."
            else
                echo "[ Fail ]"
                continue
            fi
            updateCMD="curl -s -L -w '%{response_code}' -XPATCH -u '$username:$USERS_PASSWORD' '$baseurl/rest/private/v1/social/users/$username' --data 'name=avatar&value=$uploadId' | grep -o  '[1-4][0-9][0-9]'"
            updateHTTPRS=$(eval $updateCMD)
            if [[ "$updateHTTPRS" =~ "204" ]]; then
                echo "[ Updated ]..."
            else
                echo "[ Fail ]"
            fi
            set +e
            rm /tmp/$uploadId.jpg &>/dev/null
            set -e
        fi
        userIndex=$(($userIndex + 1))
        ((counter++))
    done
elif [ "${TYPE}" = "spaces" ]; then
    if [ -z "${PREFIX}" ]; then
        PREFIX="space"
    fi
    maxIndex=$((${COUNT} + ${START_FROM} - 1))
    counter=1
    spaceIndex=${START_FROM}
    url="${baseurl}/rest/private/v1/social/spaces"
    until [ $spaceIndex -gt $maxIndex ]; do
        displayName=$(head -c 500 /dev/urandom | tr -dc "a-z" | fold -w 6 | head -n 1)
        data="{\"displayName\": \"$displayName\","
        data+="\"description\": \"${PREFIX}$spaceIndex\","
        data+="\"visibility\": \"public\","
        data+="\"subscription\": \"open\"}"
        curlCmd="curl -s -L -w '%{response_code}' -X POST -u "$auth" -H \"Content-Type: application/json\" --data '$data' $url | grep -o  '[1-9][0-9][0-9]'"
        httprs=$(eval $curlCmd)
        outputmsg="$(printf '%-6s' $counter/${COUNT}:) Display Name=\"$displayName\" "
        printf "%-80s" "$outputmsg"
        if [[ "$httprs" =~ "200" ]]; then echo "[ OK ]"; else echo "[ Fail ]"; fi
        spaceIndex=$(($spaceIndex + 1))
        ((counter++))
    done
fi
