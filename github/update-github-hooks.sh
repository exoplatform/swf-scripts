#!/bin/bash -eu

#curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/exoplatform/repos?per_page=100&page=1" | ruby -rjson update-github-hooks.rb
#curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/exoplatform/repos?per_page=100&page=2" | ruby -rjson update-github-hooks.rb
curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/exodev/repos?per_page=100" | ruby -rjson update-github-hooks.rb
#curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/exo-addons/repos?per_page=100" | ruby -rjson update-github-hooks.rb
#curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/exo-puppet/repos?per_page=100" | ruby -rjson update-github-hooks.rb