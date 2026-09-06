# q101-43-copy-file-into-running-pod: Copy a local file into a running pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-43-copy-file-into-running-pod`

`setup.sh` already created a running Pod named `archive-box` (image `busybox:1.36`, container name
`archive-box`) in namespace `q101-43-copy-file-into-running-pod`, and dropped a local file at
`~/practice-work/q101-43-copy-file-into-running-pod/manifest.txt` containing:

```
build=482
channel=stable
```

Using `kubectl cp`, copy that local file into the running container at path `/data/manifest.txt`
(the `/data` directory already exists in the container). Do not use `kubectl exec` with a
heredoc/redirect to recreate the file's contents - the task is specifically to practice `kubectl cp`.

## Hint

Search kubernetes.io/docs for **"kubectl cp"** - the kubectl reference documents copying files
and directories to and from containers with `kubectl cp <local-path> <namespace>/<pod>:<remote-path>`.
