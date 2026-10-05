# q103-38: Split a container's command into command and args correctly

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-38-job-command-args-split-fix`

A pod manifest is at `~/practice-work/q103-38-job-command-args-split-fix/word-counter.yaml` in
your terminal's working directory. It has not been applied. Its container `command` is a single
array element, `wc -l /etc/hostname`, so the container never runs `wc`.

Fix `word-counter.yaml` so the container actually runs `wc -l /etc/hostname` - split that single
broken argv element into a real program name plus its separate arguments. Apply it. The pod must
reach phase `Succeeded`, and its logs must show `wc -l` output for `/etc/hostname`.

## Hint

Search kubernetes.io/docs for **"define command argument container"** - the "Define a Command and
Arguments for a Container" task page explains that `command` and `args` map to a container
image's `ENTRYPOINT` and `CMD`, and that each is a list of separate argv elements, not one shell
string. Kubernetes runs `command` as exec, so one element named `wc -l /etc/hostname` is a
program name that does not exist.
