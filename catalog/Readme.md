# How to transfer a new catalog

## Configuration

* Create a ``$HOME/.catalog.env`` file with this content :

```
CATALOG_SCRIPT_URL=https://script....
CATALOG_HOST=...
CATALOG_PATH=...
```

## Command

```
./catalog.sh -o operation [-e env] [-c customer]
```
* -o : [mandatory] the operation to be performed: VIEW or VALIDATE are accepted
* -e : [optional] Generate the catalog for a specific environment (hosting|acceptance)
* -c : [optional] Generate the catalog for a specific customer

Example :
```bash
$ ./catalog.sh -o VALIDATE
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
[sudo] password for myuser:
Copying list.json to 20200207_111708-list.json
`/srv/.../list.json' -> `/srv/.../20200207_111708-list.json'
`/tmp/list-new.json' -> `/srv/.../list.json'
removed `/tmp/list-new.json'
Connection to xxx.exoplatform.org closed.
Catalog updated
```
