# How to transfer a new catalog

## Configuration

* Install the [go_jira](https://github.com/go-jira/jira/releases) tool
* Configure ``go_jira`` by creating a ``$HOME/.jira.d/config.yml`` file :

```
endpoint: https://jira.exoplatform.org
user: ...
```

* Create a ``$HOME/.catalog.env`` file with this content :

```
CATALOG_SCRIPT_URL=https://script....
CATALOG_HOST=...
CATALOG_PATH=...
```

## Command

```
./catalog.sh -j JIRA_ID [-r] [-e env] [-c customer]
```
* JIRA_ID : [mandatory] the jira issue asking for the catalog update
* -r : [optional] Change the status of the issue to resolve after the catalog is updated (The initial status of the jira must be IN_PROGRESS)
* -e : [optional] Generate the catalog for a specific environment (hosting|acceptance)
* -c : [optional] Generate the catalog for a specific customer

Example :
```bash
$ ./catalog.sh -j XXXX-4653
Jira issue : XXXX-4653
issue: XXXX-4653
created: 20 hours ago
status: In Progress
summary: Release PLF 6.0.0-M18
Is this correct (Y/n) ?
Downloading new catalog....
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   557    0   557    0     0     54      0 --:--:--  0:00:10 --:--:--   139
100 2658k    0 2658k    0     0   244k      0 --:--:--  0:00:10 --:--:-- 7032k
Download old catalog...
list.json                                                                                          100% 2633KB   4.0MB/s   00:00
Comparing catalogs....
Preparing commit message...
Update catalog (Y/n) ? y
Updating catalog....
   Uploading new catalog...
list-new.json                                                                                      100% 2658KB   5.8MB/s   00:00
   Preparing script ...
   Copying script ...
update_catalog.sh                                                                                  100%  424    32.9KB/s   00:00
   Changing script permissions...
   Executing script...
[sudo] password for myuser:
Copying list.json to 20200207_111708-list.json
`/srv/.../list.json' -> `/srv/.../20200207_111708-list.json'
`/tmp/list-new.json' -> `/srv/.../list.json'
removed `/tmp/list-new.json'
Connection to xxx.exoplatform.org closed.
Catalog updated
Comment jira issue XXXX-4653
OK ITOP-4653 https://jira.exoplatform.org/browse/XXXX-4653
Changing status of XXXX-4653 to resolved ...
OK ITOP-4654 https://jira.exoplatform.org/browse/XXXX-4653
```
