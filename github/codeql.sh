#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Tribe Space Activity

modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template.json")

body=""
plf_range=""
echo "Done. Performing action..."
for module in $(echo "${modules}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${module} | base64 --decode | jq -r ${1}
    }
    item=$(_jq '.name')
    org=$(_jq '.git_organization')
    version=$(_jq '.release.version')
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    [ "${item}" = "community-website" ] && continue
    [[ "${version}" =~ .*-\$\{release-version\}$ ]] || continue
    git clone git@github.com:${org}/$item >/dev/null
    pushd $item &>/dev/null
    git checkout security/codeql &>/dev/null || git checkout -b security/codeql &>/dev/null
    git rebase origin/develop >/dev/null
    git push origin security/codeql:security/codeql --force-with-lease >/dev/null
    if [ -f .github/workflows/codeql-analysis.yml ]; then
        echo "Report: https://github.com/${org}/${item}/security/code-scanning?query=branch%3Asecurity%2Fcodeql++is%3Aopen+"
        echo "==========="
    fi
    popd &>/dev/null
done
