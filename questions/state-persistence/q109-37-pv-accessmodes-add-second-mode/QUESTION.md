# q109-37-pv-accessmodes-add-second-mode: Add a second access mode to an existing PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-37-pv-accessmodes-add-second-mode`

`setup.sh` already created a PersistentVolume named `shared-docs-pv` (capacity `500Mi`,
`hostPath`-backed at `/mnt/q109-37-docs`, storage class name `""`) with a single access mode,
`ReadWriteOnce`. The docs team now also wants other pods to be able to mount this same volume
read-only at the same time, which `ReadWriteOnce` alone does not allow.

A PersistentVolume's `accessModes` is a **list** - add `ReadOnlyMany` as a second entry
alongside the existing `ReadWriteOnce`, so the volume advertises both. `accessModes` cannot be
patched on an existing PersistentVolume - delete and recreate `shared-docs-pv` with both access
modes, keeping the same capacity (`500Mi`), the same `hostPath` (`/mnt/q109-37-docs`), and the
same storage class name (`""`).

## Hint

Search kubernetes.io/docs for **"persistentvolume accessModes"** - the Persistent Volumes
concept page's Access Modes section shows `spec.accessModes` as a list that may name more than
one mode a single PersistentVolume supports, distinct from a PersistentVolumeClaim (which
requests exactly one mode it needs).
