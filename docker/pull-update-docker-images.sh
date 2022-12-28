#!/bin/bash -eu

### -> Workaround script to prevent dockerhub unused docker images deletion.
### -> To Keep images safe. docker hub's Pro license is required. 
### Requires 'jq': https://stedolan.github.io/jq/

### Required Global environments
# DOCKER_USERNAME="xxxxxxx"
# DOCKER_TOKEN_PASSWORD="d35bed0f-8355-43f3-87ba-xxxxxxxxxxxxxx"
# ORGS_LIST="exoplatform meedsio"

print_info() {
    printf "$(date '+%Y-%m-%d %H:%M:%S') | INFO | $1"
}
# Aquire token
print_info "Aquiring Dockerhub Token..."
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_USERNAME}'", "password": "'${DOCKER_TOKEN_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
echo "OK"
print_info "Getting docker images..."
FULL_IMAGE_LIST=""
for org in ${ORGS_LIST}; do
    # get list of repositories for the user account
    REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${org}/?page_size=100 | jq -r '.results|.[]|.name')
    # build a list of all images & tags
    for repo in ${REPO_LIST}; do
        # Get tags for repo
        [[ "$repo" =~ ^(exo|meeds|chat-server)$ ]] || continue
        IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${org}/${repo}/tags/?page_size=100 | jq -r '.results|.[]|.name')
        # build a list of images from tags
        for tag in ${IMAGE_TAGS}; do
            [[ "$tag" =~ .*(-(M|RC)[0-9]+|develop|latest) ]] && continue
            # add each tag to list
            FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${org}/${repo}:${tag}"
        done
    done
done
echo "OK"
print_info "Docker images gethering has finished:\n  Count: $(wc -w <<< $FULL_IMAGE_LIST)\n"
# Starting pull imagees
for image in ${FULL_IMAGE_LIST}; do
    [[ $image =~ '([0-9]{8,})|(M|CP|RC[0-9]{2})' ]] && continue
    print_info "Pulling \"$image\" image..."
    sudo docker pull $image &>/dev/null
    echo "OK"
    print_info "Checking if \"$image\" image was used before..."
    if sudo docker ps -a | awk '{print $2}' | grep -q $image; then
        echo "Used -> Skipped."
    else
        echo "Not Used."
        print_info "Removing \"$image\" image..."
        sudo docker image rm $image &>/dev/null && echo "OK"
    fi
done
print_info "Finished.\n"