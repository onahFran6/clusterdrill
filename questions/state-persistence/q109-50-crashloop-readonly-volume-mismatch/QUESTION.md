# q109-50-crashloop-readonly-volume-mismatch: Fix a CrashLoop caused by a read-only root filesystem with no writable volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-50-crashloop-readonly-volume-mismatch`

`setup.sh` already created a Pod named `session-tracker` in namespace
`q109-50-crashloop-readonly-volume-mismatch`. Its container sets
`securityContext.readOnlyRootFilesystem: true` (a real security hardening requirement this task
must keep) and runs `sh -c "echo start > /var/run/app/session.pid && sleep 3600"` - but the Pod
has **no volume at all**, so `/var/run/app/` doesn't exist as writable space; the container
fails immediately with a read-only filesystem error and crash-loops.

Do not remove `readOnlyRootFilesystem: true` - instead, add an `emptyDir` volume named
`app-run` mounted at exactly `/var/run/app` (the one path the app actually needs to write to),
so the rest of the filesystem stays read-only but that one directory is writable.

## Hint

Search kubernetes.io/docs for **"readOnlyRootFilesystem"** - the "Configure a Security Context
for a Pod or Container" page explains that a container with `readOnlyRootFilesystem: true`
still needs an explicit writable volume mounted at any path the application actually writes to -
the security setting doesn't make an exception for a handful of files, it locks down
everything not covered by a mount.
