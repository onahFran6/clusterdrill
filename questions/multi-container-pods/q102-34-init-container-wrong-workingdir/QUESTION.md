# q102-34: Fix an init handoff whose file never reaches the main container

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-34-init-container-wrong-workingdir`

A Pod named `handoff-app` already exists in this namespace with an init
container `stager` and a main container `consumer`, sharing one `emptyDir`
volume named `stage-data`:

- `stager` (busybox:1.36) mounts `stage-data` at `/stage` and runs
  `echo shipment-ready-778 > handoff.txt` - note the relative filename, with
  no leading `/`. Where that file lands depends on `stager`'s `workingDir`.
- `consumer` (busybox:1.36) mounts the same `stage-data` volume at `/consume`
  and expects `/consume/handoff.txt`.

`stager` exits `0` and the Pod shows `2/2 Running`, but `/consume/handoff.txt`
never exists inside `consumer`.

Fix `stager`'s `workingDir` so `handoff.txt` is written into the shared
`stage-data` volume. Do not change either container's image, do not change the
command, and do not make the filename an absolute path - `workingDir` is the
fix. This field is immutable on a running Pod - delete and recreate
`handoff-app` with the fix applied, keeping every other field unchanged. Once
fixed, `/consume/handoff.txt` inside `consumer` must contain exactly
`shipment-ready-778`.

## Hint

Search kubernetes.io/docs for **"workingDir"** - the Pod spec API reference
for `Container` documents the `workingDir` field: the container's working
directory, which determines where a command's relative-path file
operations actually land.
