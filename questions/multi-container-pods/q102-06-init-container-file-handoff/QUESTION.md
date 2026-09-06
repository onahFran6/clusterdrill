# q102-06: Init container file handoff

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-06-init-container-file-handoff`

Create a Pod named `configured-app` in this namespace with:

- An init container named `generate-config` (image `busybox:1.36`) that writes
  a file `/config/app.conf` containing the line `mode=production` into a
  shared `emptyDir` volume named `config-vol`, then exits successfully.
- A main container named `main` (image `busybox:1.36`) that mounts the same
  `config-vol` volume at `/config` and runs a command that reads
  `/config/app.conf` and then keeps the container running, e.g.
  `sh -c "cat /config/app.conf && sleep 3600"`.

The init container must run to completion and produce the config file
*before* the main container starts, demonstrating how init containers can
prepare data for the main workload via a shared volume.

## Hint

Search kubernetes.io/docs for **"init containers"** - the "Creating a Pod
that has an Init Container" example shows how init containers share volumes
with app containers.
