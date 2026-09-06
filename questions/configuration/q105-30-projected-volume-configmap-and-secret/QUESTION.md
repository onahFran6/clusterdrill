# q105-30-projected-volume-configmap-and-secret: Combine a ConfigMap and a Secret into one projected volume

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-30-projected-volume-configmap-and-secret`

`setup.sh` already created a ConfigMap named `app-settings` (key `app.conf`), a Secret named
`app-secret-key` (key `secret.key`), and a pod named `combiner` in namespace
`q105-30-projected-volume-configmap-and-secret`. The `combiner` pod is stuck in
`ContainerCreating` because its single **projected volume** lists sources that reference a
misspelled ConfigMap name and a misspelled Secret name - neither matches an object that actually
exists.

Fix the projected volume's `sources` in the pod so it references the real `app-settings` ConfigMap
and the real `app-secret-key` Secret, without changing the ConfigMap's or Secret's contents. Both
keys must show up as files under the single mount path `/etc/combined`: `/etc/combined/app.conf`
and `/etc/combined/secret.key`. Since a running pod's volumes are immutable, you will need to
recreate the `combiner` pod (same name, same mount path) with a corrected projected volume
definition, and get it to `Running`/`Ready`.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Projected Volumes concept page shows
the exact `sources` list syntax for combining a `configMap` source and a `secret` source under one
volume.
