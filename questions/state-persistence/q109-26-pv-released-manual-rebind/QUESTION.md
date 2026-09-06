# q109-26-pv-released-manual-rebind: Recover a Released PersistentVolume by clearing its claimRef

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-26-pv-released-manual-rebind`

`setup.sh` created a PersistentVolume named `legacy-pv` (`hostPath` at `/tmp/ckad-legacy-pv`,
capacity `80Mi`, access mode `ReadWriteOnce`, `storageClassName: ""`, reclaim policy `Retain`)
and a PersistentVolumeClaim named `legacy-claim` that bound to it. The claim has since been
deleted, but because the reclaim policy is `Retain`, PV `legacy-pv` was not deleted - it is now
stuck in phase `Released`, holding a stale `spec.claimRef` that still points at the old
`legacy-claim`. A PV in this state will not bind to any new claim until that stale `claimRef` is
cleared.

Recover the volume:

1. Edit/patch PersistentVolume `legacy-pv` to remove its `spec.claimRef` entirely, so the PV
   returns to phase `Available`. Do not delete or recreate the PV.
2. Create a new PersistentVolumeClaim named `recovered-claim` in this namespace that requests
   `80Mi` of storage, access mode `ReadWriteOnce`, and `storageClassName: ""`, so it binds to the
   now-available `legacy-pv`.

When you are done, `recovered-claim` must be `Bound` to `legacy-pv`.

## Hint

Search kubernetes.io/docs for **"persistent volume released claimref"** - the Persistent Volumes
concept page's "Reclaiming" section covers manually recovering a `Retain`-policy volume that is
stuck `Released` by clearing `spec.claimRef` so it becomes `Available` again.
