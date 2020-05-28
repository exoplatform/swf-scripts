# How to transfer a new catalog

## Desclaimer

The following script should be executed by the CI Agent.

## Configuration

* The following environment variables must be defined in the CI Job / Jenkins Slave configuration

```
CATALOG_SCRIPT_URL=https://script....
CATALOG_PATH=...
TRIBE_AGENT_USERNAME=...
TRIBE_AGENT_PASSWORD=...
TRIBE_TASK_REST_PREFIXE_URL=https://community.exoplatform.com/rest/private/tasks (without "/" at the end)
```

* Specify the following environment variables as CI Build parameters
```
OPERATION: [Mandatory] Specify the operation to be performed, accpeted values are: VIEW|VALIDATE
             - VIEW: Display the catalog file changes without applying new changes to the catalog.
             - VALIDATE: Perform the VIEW operation with applying new changes to the catalog.
ENVIRONMENT : [Optional] Specify the catalog environment, accepted values are: acceptance|hosting 
CUSTOMER : [Optional] Specify the customer ID
TASK_ID: [Optional] Specify the eXo Tribe Task ID, catalog file difference will be commented to the specified task.
```

## Command

```
export CATALOG_SCRIPT_URL=https://script....
export CATALOG_PATH=/srv/....
export OPERATION=VALIDATE
./catalog.sh
```

Example :
```bash
$ ./catalog.sh
Downloading new catalog....
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   557    0   557    0     0     54      0 --:--:--  0:00:10 --:--:--   139
100 2658k    0 2658k    0     0   244k      0 --:--:--  0:00:10 --:--:-- 7032k
Download old catalog...
list.json                                                                                          100% 2633KB   4.0MB/s   00:00
Comparing catalogs....
Updating catalog....
   Uploading new catalog...
list-new.json                                                                                      100% 2658KB   5.8MB/s   00:00
   Preparing script ...
   Copying script ...
update_catalog.sh                                                                                  100%  424    32.9KB/s   00:00
   Changing script permissions...
   Executing script...
[sudo] password for ciagent:
Copying list.json to 20200207_111708-list.json
`/srv/.../list.json' -> `/srv/.../20200207_111708-list.json'
`/tmp/list-new.json' -> `/srv/.../list.json'
removed `/tmp/list-new.json'
Connection to xxx.exoplatform.org closed.
Catalog updated
```
