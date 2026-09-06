# q103-38: Split a container's command into command and args correctly

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-38-job-command-args-split-fix`

`setup.sh` wrote a pod manifest to
`~/practice-work/q103-38-job-command-args-split-fix/word-counter.yaml` in your terminal's working
directory, but never applied it. As written, its single container has:

```yaml
command: ["wc -l /etc/hostname"]
```

That is **one** array element containing the whole string `wc -l /etc/hostname`, not a program name
followed by separate arguments. Kubernetes runs `command` as an exec argv list, not through a
shell, so the container runtime tries to execute a program literally named `wc -l /etc/hostname`
(with spaces in the name) and fails immediately - it never runs `wc` at all.

Fix `word-counter.yaml` so it correctly calls `wc` with the `-l` flag against `/etc/hostname`,
using **both** fields the way Kubernetes expects them to be split:

- `command: ["wc"]` - the program to run (overrides the image's `ENTRYPOINT`)
- `args: ["-l", "/etc/hostname"]` - the arguments passed to it (overrides the image's `CMD`)

Then apply it. The pod must reach phase `Succeeded`, and its logs must show `wc -l`'s output for
`/etc/hostname`.

## Hint

Search kubernetes.io/docs for **"define command argument container"** - the "Define a Command and
Arguments for a Container" task page explains that `command` and `args` in the Pod spec map to a
container image's `ENTRYPOINT` and `CMD`, and that each is a list of separate argv elements, not a
single shell string.
