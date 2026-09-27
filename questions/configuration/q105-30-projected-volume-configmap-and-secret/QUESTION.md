# q105-30: Combine a ConfigMap and a Secret into one projected volume

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-30-projected-volume-configmap-and-secret`

A ConfigMap named `app-settings` (key `app.conf`), a Secret named `app-secret-key` (key
`secret.key`), and a Pod named `combiner` already exist in namespace
`q105-30-projected-volume-configmap-and-secret`. The `combiner` pod is stuck in
`ContainerCreating` - its projected volume points at names that do not match the real ConfigMap
and Secret.

Fix the pod so both keys show up as files under the single mount path `/etc/combined`:
`/etc/combined/app.conf` and `/etc/combined/secret.key`. Do not change the ConfigMap's or Secret's
contents. Recreating the `combiner` pod (same name, same mount path) is fine. Get it to
`Running`/`Ready`.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Projected Volumes concept page shows
the exact `sources` list syntax for combining a `configMap` source and a `secret` source under one
volume.
