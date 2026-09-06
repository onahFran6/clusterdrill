# q102-23-adapter-container-wrong-command-format: Adapter container transforms format but wrong output field name

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-23-adapter-container-wrong-command-format`

A Pod named `legacy-bridge` already exists in this namespace with a main
container `producer` (image `busybox:1.36`) that continuously writes raw
pipe-delimited lines like `user1|200|/api` to a shared `emptyDir` file at
`/data/raw.log`, and an adapter container `json-adapter` (image
`busybox:1.36`) that is supposed to read `raw.log` and write each line as a
JSON object to `/data/out.json` with the keys `user`, `status`, and `path`.

The `json-adapter` container's command was seeded with a bug: it writes the
numeric field under the key `code` instead of `status`, so downstream
consumers that expect a `status` key never find one.

You cannot edit `containers[].command` on a running Pod in place (it is
immutable). Fix this by deleting and recreating the `legacy-bridge` Pod with
a corrected `json-adapter` command, keeping the `producer` container, the
shared `emptyDir` volume, and both containers' images unchanged. The fixed
`json-adapter` must continuously append one JSON line per input line to
`/data/out.json`, and each JSON line must contain exactly the keys `user`,
`status`, and `path`, parsed from the corresponding pipe-delimited fields in
`raw.log`, with `status` holding the numeric value (not a key named `code`).

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section describes the adapter container pattern this task is based on.
