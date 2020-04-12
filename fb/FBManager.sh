#!/bin/bash

# Arguments
# 1: Configuration file JSON Format See help description
# 2: Action: create / delete Feature Branch
# 3: Feature Branch Name: word "feature/" will be added automatically in case of unset

# EXIT CODES
# 0 -- OK
# 1 -- Missing arguments or commands
# 2 -- Wrong provided argument
# 3 -- Missing mandatory information in the configuration file
# 4 -- Wrong provided information or insufficient privileges
# 5 -- Inability to perform action due to insufficient privileges
####
protected_branches_list_regex="^(master|develop|stable\/[0-9.-_a-zA-Z]+)$"
####

scrdir=$(dirname $(realpath $0))
. ${scrdir}/_functions.sh
if [ -z "$1" ] || [[ $1 =~ ^-(h|-help)$ ]]; then
    print_help
    exit 0
fi
assert_command git
assert_command jq
assert_command mvn
if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo_err "Config file is missing or invalid"
    exit 1
fi
config_file=$(realpath $1)
if ! validate_json ${config_file} >/dev/null; then #Suppress only plain message
    echo_err "Config file is not a valid JSON file!"
    exit 2
else
    echo_ok "Config file \"$1\" is a valid JSON file"
fi
shift
if [[ ! "$1" =~ ^(create|delete)$ ]]; then
    echo_err "Wrong or Missing action! only create or delete are accepted!"
    exit 2
else
    echo_ok "Action \"$1\" will be performed"
fi
action=$1
shift
if [ -z "$1" ]; then
    echo_err "Missing Feature Branch name!!"
    exit 2
fi
featurebranch=$1
[[ "${featurebranch}" =~ ^Feature ]] || featurebranch="feature/${featurebranch}"

maventag=$(echo ${featurebranch} | sed -E 's|^(f\|F)eature/||g')
#Check for illegal characteres like / etc 
if [[ ! "${maventag}" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo_err "Feature branch \"${featurebranch}\" contains illegal characters!"
    exit 3
fi

shift
echo_ok "Feature Branch is \"${featurebranch}\""
start_time=$(date +%s)
rm -rf ${wkdir}* &>/dev/null #Cleanup
for el in $(cat ${config_file} | jq -c '.[]'); do
    ## Args Parsing
    if ! eval $(echo $el | jq -r '. | to_entries | .[] | .key + "=\"" + .value + "\""') &>/dev/null; then
        echo_err "Could not convert the followig JSON Object to Bash variables!"
        echo $el | jq
        exit 3
    fi

    ## Args Common Checks
    if [ -z "${git_organization}" ]; then
        echo_err "Github organization is not specified!"
        exit 3
    fi

    if [ -z "${git_repository}" ]; then
        echo_err "Github repository is not specified!"
        exit 3
    fi

    ## Prepare repository
    full_repo_name="${git_organization}/${git_repository}"
    ssh_url="git@github.com:${full_repo_name}.git"

    ## Check Repository existance and access privileges
    if ! valid_repo ${ssh_url}; then
        echo_err "Repository ${full_repo_name} is not exist or insufficient privileges!"
        exit 4
    fi

    ## Clone Repository
    echo_ok "Cloning ${full_repo_name}"
    local_repo_path="${wkdir}/${full_repo_name}"
    [ -e ${local_repo_path} ] && rm -rf ${local_repo_path} &>/dev/null #Cleanup
    if ! git clone ${ssh_url} ${local_repo_path} &>/dev/null; then
        echo_err "Could not clone ${full_repo_name} !"
        exit_with_cleanup 4
    fi

    ## Check if the repository is successfully cloned
    if [ ! -d ${local_repo_path} ] || [ ! -d "${local_repo_path}/.git" ]; then
        echo_err "Local repository ${full_repo_name} is not created !"
        exit_with_cleanup 4
    else
        echo_ok "Repository ${full_repo_name} is successfully cloned !"
    fi

    ## Function Live Definition Make code below more redeable
    r_git() {
        git --git-dir=${local_repo_path}/.git --work-tree=${local_repo_path} $*
    }

    ## Check if update is unset if yes, use false as default value
    [ -z "${update}" ] && update="false"

    ## Perform Feature Branch Creation
    if [[ $action == "create" ]]; then

        ## Check if base branch is unset if yes, use default branch as base one
        [ -z "${git_base_branch}" ] && git_base_branch=$(r_git symbolic-ref --short HEAD)

        ## Check if feature branch is already exist in the Git Repository [ Remote Check ]
        if [ ! -z "$(r_git ls-remote --heads origin ${featurebranch})" ]; then
            if [[ ${update} == "false" ]]; then
                echo_err "Branch \"${featurebranch}\" already exist!"
            fi
            if [[ ${update} == "true" ]]; then
                echo_warn "Update Mode is Enabled!"
            else
                exit_with_cleanup 5
            fi
        fi

        current_branch=$(r_git rev-parse --abbrev-ref HEAD)
        #Default branch protection
        if [[ "${featurebranch}" == "${current_branch}" ]]; then
            echo_err "Could not recreate the default branch \"${featurebranch}\"!"
            exit_with_cleanup 4
        fi
        ## Check if the current branch is the selected base branch if not, check out to it
        if [[ "${git_base_branch}" != "${current_branch}" ]]; then
            if ! r_git checkout ${git_base_branch} &>/dev/null; then
                echo_err "Could not checkout to branch \"${git_base_branch}\" !"
                exit_with_cleanup 5
            fi
            echo_ok "Checked out to base branch \"${git_base_branch}\""
        else
            echo_ok "Already on base branch \"${git_base_branch}\""
        fi

        # Add Force flag for the git push and remove branch as precaution
        force_flag=""
        [[ ${update} == "true" ]] && force_flag="-f"
        r_git branch -D ${featurebranch} &>/dev/null

        # Create feature branch locally and push to the remote
        if r_git checkout -b "${featurebranch}" 2>/dev/null; then
            echo_ok "Branch \"${featurebranch}\" has been created locally"
        else
            echo_err "Could not create branch \"${featurebranch}\"!"
            exit_with_cleanup 5
        fi

        # Apply changes to Maven Project
        if [ -f "${local_repo_path}/pom.xml" ]; then
            project_artifactId=$(get_maven_property "${local_repo_path}" "project.artifactId")
            project_groupId=$(get_maven_property "${local_repo_path}" "project.groupId")
            project_version=$(get_maven_property "${local_repo_path}" "project.version")
            new_project_version=$(echo ${project_version} | sed "s|-SNAPSHOT|-${maventag}-SNAPSHOT|g")
            echo_ok "Maven Project Informations:"
            echo "***"
            echo "       ArtifactId: ${project_artifactId}"
            echo "          GroupId: ${project_groupId}"
            echo "          Version: ${project_version}"
            echo "      New version: ${new_project_version}"
            echo "***"
            if change_maven_project_version "${local_repo_path}" ${project_groupId} ${project_artifactId} ${new_project_version}; then
                echo_ok "Maven Project version changed to ${new_project_version}"
            else
                echo_err "Could not change project version to ${new_project_version}"
                exit_with_cleanup 4
            fi
            r_git add $(find ${local_repo_path} -name pom.xml | xargs)
            if ! echo "Create Feature Branch ${featurebranch}" | r_git commit -F -; then
                echo_err "Could not commit on the ${featurebranch} branch!"
                exit_with_cleanup 4
            fi
        fi

        if ! r_git push origin "${featurebranch}" ${force_flag} 2>/dev/null; then
            echo_err "Could not push on the ${featurebranch} branch!"
            exit_with_cleanup 4
        else
            echo_ok "Branch ${featurebranch} has been created"
        fi

    ## Perform Feature Branch Deletion
    elif [[ $action == "delete" ]]; then
        # Default Branch Protection
        current_branch=$(r_git rev-parse --abbrev-ref HEAD)
        if [[ "${featurebranch}" == "${current_branch}" ]]; then
            echo_err "Could not delete default branch \"${featurebranch}\"!"
            exit_with_cleanup 4
        fi
        ## Check if feature branch is already exist in the Git Repository [ Remote Check ]
        if [ ! -z "$(r_git ls-remote --heads origin ${featurebranch})" ]; then
            echo_ok "Branch \"${featurebranch}\" exist"
            if r_git push origin :${featurebranch}; then
                echo_ok "Branch \"${featurebranch}\" has been deleted!"
            else
                echo_err "Could not delete branch \"${featurebranch}\"!"
                exit_with_cleanup 5
            fi
        else
            echo_ok "Branch \"${featurebranch}\" does not exist"
        fi
    fi
    ## Mandatory Common cleanup process for the next iteration
    rm -rf $(dirname ${local_repo_path}) &>/dev/null #Global Cleanup : dirname = organization folder
    unset name git_base_branch git_organization git_repository update force_flag
done
echo_ok "Finished in $(date -ud "@$(($(date +%s) - $start_time))" +%T)."
