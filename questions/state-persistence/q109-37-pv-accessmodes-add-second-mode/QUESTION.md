# q109-37-pv-accessmodes-add-second-mode: Add a second access mode to an existing PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-37-pv-accessmodes-add-second-mode`

A PersistentVolume named `shared-docs-pv` already exists (capacity `500Mi`, `hostPath`-backed
at `/mnt/q109-37-docs`, storage class name `""`) with a single access mode, `ReadWriteOnce`.

The volume must advertise both `ReadWriteOnce` and `ReadOnlyMany`. Keep the same capacity
(`500Mi`), the same `hostPath` (`/mnt/q109-37-docs`), and the same storage class name (`""`).

## Hint

Search kubernetes.io/docs for **"persistentvolume accessModes"** - the Persistent Volumes
concept page's Access Modes section shows `spec.accessModes` as a list that may name more than
one mode a single PersistentVolume supports. `ReadWriteOnce` alone does not let other pods
mount the volume read-only at the same time. `accessModes` cannot be patched on an existing
PersistentVolume, so delete and recreate `shared-docs-pv` with both modes.
