# q109-11: A PersistentVolumeClaim is running out of room

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-11-pvc-needs-more-storage`

Spectra Observatory's overnight capture job writes raw sensor frames to a PersistentVolumeClaim
named `growing-claim` in namespace `q109-11-pvc-needs-more-storage`. The claim is bound against
StorageClass `expandable-q109-11` at **1Gi**, and tonight's capture is about to overflow it.

Increase `growing-claim`'s requested storage to **2Gi** without deleting or recreating the claim -
the frames already written must stay in place.

## Hint

Search kubernetes.io/docs for **"resizing persistent volume claim"** - the Persistent Volumes
concept page covers which StorageClasses allow it and which single spec field you change to grow
a bound claim. Check whether `expandable-q109-11` allows it with `kubectl get storageclass -o yaml`
before you touch the claim. Note: on this cluster's `hostPath` provisioner, the claim's reported
capacity in `status` may never catch up to what you request - that's expected here.
