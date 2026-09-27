# q109-26-pv-released-manual-rebind: Recover a Released PersistentVolume by clearing its claimRef

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-26-pv-released-manual-rebind`

A PersistentVolume named `legacy-pv` already exists (`hostPath` at `/tmp/ckad-legacy-pv`,
capacity `80Mi`, access mode `ReadWriteOnce`, `storageClassName: ""`, reclaim policy `Retain`).
It is stuck in phase `Released` after claim `legacy-claim` was deleted, and `spec.claimRef`
still points at that claim.

Recover the volume:

1. Remove `spec.claimRef` from PersistentVolume `legacy-pv` so the PV returns to phase
   `Available`. Do not delete or recreate the PV.
2. Create a new PersistentVolumeClaim named `recovered-claim` in this namespace that requests
   `80Mi` of storage, access mode `ReadWriteOnce`, and `storageClassName: ""`, so it binds to
   `legacy-pv`.

When you are done, `recovered-claim` must be `Bound` to `legacy-pv`.

## Hint

Search kubernetes.io/docs for **"persistent volume released claimref"** - the Persistent Volumes
concept page's "Reclaiming" section covers manually recovering a `Retain`-policy volume that is
stuck `Released`. A PV in that state will not bind to a new claim until the stale `claimRef` is
cleared.
