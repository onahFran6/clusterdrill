# q109-11: Grow a PersistentVolumeClaim in place

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-11-pvc-resize-allow-expansion`

A StorageClass named `expandable-q109-11` already exists (provisioner
`k8s.io/minikube-hostpath`, `allowVolumeExpansion: true`), and a PersistentVolumeClaim named
`growing-claim` in namespace `q109-11-pvc-resize-allow-expansion` is bound at `1Gi` against
that storage class.

Without deleting or recreating the PVC, edit `growing-claim` so `spec.resources.requests.storage`
is `2Gi` instead of `1Gi`.

## Hint

Search kubernetes.io/docs for **"resizing persistent volume claim"** - the Persistent Volumes
concept page's section on expanding PVCs shows the exact `kubectl edit` / `kubectl patch`
workflow, and that `allowVolumeExpansion` on the StorageClass is what makes it possible. The
field to change is `spec.resources.requests.storage`. On this cluster's `hostPath`
provisioner, `status.capacity` can lag or never converge without a full CSI driver.
