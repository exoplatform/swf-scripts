# Weekly version management

This tools is managing weekly versions on ITOP projects.
Can be used for the following projects :
* ITOP
* SWF
* ACC
* RELEASE
* ACCOUNTS
* QAF
* DOCKER

Actions :
* Create a new weekly version name ``<project>-YYYY-W<week number> (current)``
* Move all issues not closed associated to the previous version to the new one
* Remove the `` (current)`` string from the current version
* Release the current version

## Usage

```
export GO111MODULE=on
go run new_version.go [--username username] [--password password] [jira project key]
```


## Status


[X] Create new version
[X] Migrate issues from previous version to the new one
[X] Update and release the previous version
[]  Archive versions older than 1 year
[]  Use environment variable to retrieve username and password (make the tools usable on jenkins)
[]  Docker image
