# q109-50-crashloop-readonly-volume-mismatch: Fix a CrashLoop caused by a read-only root filesystem with no writable volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-50-crashloop-readonly-volume-mismatch`

A Pod named `session-tracker` already exists in namespace
`q109-50-crashloop-readonly-volume-mismatch`. Its container sets
`securityContext.readOnlyRootFilesystem: true` and runs
`sh -c "echo start > /var/run/app/session.pid && sleep 3600"`. The container crash-loops.

Keep `readOnlyRootFilesystem: true`, the image, and the command. Add an `emptyDir` volume
named `app-run` mounted at `/var/run/app`.

## Hint

Search kubernetes.io/docs for **"readOnlyRootFilesystem"** - the "Configure a Security Context
for a Pod or Container" page explains that a container with `readOnlyRootFilesystem: true`
still needs an explicit writable volume at any path the application writes to. This Pod has
no volume, so `/var/run/app/` is not writable and the command fails immediately.
