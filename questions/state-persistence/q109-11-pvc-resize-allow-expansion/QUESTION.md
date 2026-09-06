# q109-11: Grow a PersistentVolumeClaim in place

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-11-pvc-resize-allow-expansion`

`setup.sh` already created a StorageClass named `expandable-q109-11` (provisioner
`k8s.io/minikube-hostpath`, `allowVolumeExpansion: true`) and a PersistentVolumeClaim named
`growing-claim` in namespace `q109-11-pvc-resize-allow-expansion`, bound at `1Gi` against that
storage class.

The application using this claim is running out of space. Without deleting or recreating the
PVC, edit `growing-claim` so it requests `2Gi` instead of `1Gi`.

Note: a PVC's requested size (`spec.resources.requests.storage`) is what you control and what
gets graded here - the underlying `status.capacity` on some storage plugins (including this
cluster's `hostPath`-backed one) can lag behind or never converge outside a full CSI driver,
which is a real-world quirk of this local cluster's provisioner, not something the exam expects
you to work around.

## Hint

Search kubernetes.io/docs for **"resizing persistent volume claim"** - the Persistent Volumes
concept page's section on expanding PVCs shows the exact `kubectl edit` / `kubectl patch`
workflow, and that `allowVolumeExpansion` on the StorageClass is what makes it possible at all.
