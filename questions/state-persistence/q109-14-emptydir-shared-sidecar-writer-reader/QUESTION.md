# q109-14: Share an emptyDir volume between two containers in one Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-14-emptydir-shared-sidecar-writer-reader`

`setup.sh` created namespace `q109-14-emptydir-shared-sidecar-writer-reader` but no resources yet.

Create a Pod named `relay` with two containers that share one `emptyDir` volume named
`shared-data`, both mounting it at `/data`:

- container `writer` (image `busybox:1.36`) writes the text `hello` to `/data/msg.txt`
  and then sleeps (e.g. for an hour) so the Pod stays running.
- container `reader` (image `busybox:1.36`) just sleeps (e.g. for an hour) so it can be
  exec'd into later.

The grader will exec into the `reader` container and run `cat /data/msg.txt`, expecting
the output to be exactly `hello`.

## Hint

Search kubernetes.io/docs for **"emptyDir"** - the Volumes concept page's "Communication
between containers" example shows exactly how two containers in the same Pod share one
emptyDir volume via matching `volumeMounts`.
