# q101-35: Create a ConfigMap from a file on disk

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-35-create-configmap-from-file`

A file already exists at `~/practice-work/q101-35-create-configmap-from-file/app.properties`
containing:

```
log.level=warn
cache.enabled=true
```

In namespace `q101-35-create-configmap-from-file`, create a ConfigMap named `app-props` whose data
comes from that file, using a single imperative `kubectl create configmap --from-file` command (no
manifest authored by hand). The ConfigMap's key must be the file's own basename (`app.properties`),
with the file's exact contents as the value.

## Hint

Search kubernetes.io/docs for **"create configmaps from files"** - the ConfigMaps concept page's
"Create a ConfigMap from a file" section shows the `--from-file` flag and how the key defaults to
the file's basename.
