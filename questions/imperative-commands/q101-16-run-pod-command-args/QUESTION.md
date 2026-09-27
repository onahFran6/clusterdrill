# q101-16: Override a container's command and arguments

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-16-run-pod-command-args`

In namespace `q101-16-run-pod-command-args`, create a Pod named `custom-cmd` running image
`busybox:1.36` whose container runs:

```
sh -c "echo hello-ckad && sleep 3600"
```

Use a single imperative `kubectl run` command with a command override - no manifest authored by
hand. The Pod should end up `Running`.

## Hint

Search kubernetes.io/docs for **"kubectl run command arguments"** - the "Define a Command and
Arguments for a Container" task page shows the exact syntax for passing a command after `--` in
`kubectl run`.
