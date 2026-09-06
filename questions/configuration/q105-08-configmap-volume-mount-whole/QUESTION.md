# q105-08: Mount an entire ConfigMap as a volume of files

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-08-configmap-volume-mount-whole`

`setup.sh` already created a ConfigMap named `app-config` with two keys, `app.properties` and
`logging.properties`, plus a running pod named `report-service` (image `nginx:1.25-alpine`), in
namespace `q105-08-configmap-volume-mount-whole`.

Edit the pod so its container mounts the **entire** `app-config` ConfigMap as a volume at
`/etc/app-config`, so both `app.properties` and `logging.properties` appear as separate files
under that directory - do not use individual `items` entries to select only one key. The pod
will need to be recreated for the mount to take effect.

## Hint

Search kubernetes.io/docs for **"populate a volume with configmap data"** - the Configure a Pod
to Use a ConfigMap task shows how mounting a ConfigMap as a volume creates one file per key.
