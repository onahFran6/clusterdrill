# q107-39: Diagnose which of several init containers is actually blocking startup

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-39-multiple-init-containers-sequential-failure`

A Pod named `report-builder` already exists with three init containers, `create-workdir`,
`fetch-config`, and `validate-config`, plus a main container `report-builder` (image
`nginx:1.25-alpine`). The Pod is stuck at `Init`.

Find which init container is failing, fix only that one so it exits successfully, and get the Pod
to `Running` and Ready. Do not change the other two init containers or the main container. Do not
assume the first init container is the one that failed.

## Hint

Search kubernetes.io/docs for **"init containers detailed behavior"** - the init containers
concept page explains that init containers run sequentially, one completing before the next
starts, so a Pod stuck at `Init:N/M` requires checking each init container's own status and logs,
not just the first one.
