# q107-39: Diagnose which of several init containers is actually blocking startup

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-39-multiple-init-containers-sequential-failure`

`setup.sh` already created a Pod named `report-builder` with three init containers -
`create-workdir`, `fetch-config`, `validate-config` - that run in that order, plus a main
container `report-builder` (image `nginx:1.25-alpine`). The Pod is stuck at `Init`. Diagnose which
one of the three init containers is actually failing (don't assume it's the first one just because
the Pod never gets further), fix only that one so it exits successfully, and get the Pod to
`Running`/Ready - without changing the other two init containers or the main container.

## Hint

Search kubernetes.io/docs for **"init containers detailed behavior"** - the init containers
concept page explains that init containers run sequentially, one completing before the next
starts, so a Pod stuck at `Init:N/M` requires checking each init container's own status/logs (not
just the first) to find which one is actually broken.
