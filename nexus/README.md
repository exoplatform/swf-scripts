### Nexus Cleanup script

This script clean CI/CD release to free up nexus server disk's space. 

Before proceeding with cleanup. This script requires the following environment variables:

- `NEXUS_ADMIN`: Nexus administrator username
- `NEXUS_PASSWORD`: Nexus administrator password
- `NEXUS_URL`: Nexus URL (eg https://repository.exoplatform.org)

```bash
export NEXUS_ADMIN='xxxxxxxx'
read -s NEXUS_PASSWORD
export NEXUS_PASSWORD
export NEXUS_URL=https://repository.exoplatform.org
```

Update `CURRENT_MONTH` property which CI/CD version month to removed

```bash
CURRENT_MONTH="07"
```
:warning: Keeping `0` as padding character + String interpretation are stricly required! 

To perform a dry-run operation, remove the following sublock
```bash
 -exec rm -rvf {} \; 2>/dev/null || true
```
for all `find` instructions.

Refer to the server via SSH and execute the script.
```bash
./cleanup.sh | tee -a cleanup.log
```

No further action is required, rebuild metadata and indexes are triggered by the script.

## Recommendations:

- It is prefered to run this script during less nexus activity (CI, Release etc ...)
- Check CI/CD deployment status before launching the cleanup to avoid deployed version removal. 

## To-DO:

Automate this feature with Jenkins or Github actions (via SSH Connection).

