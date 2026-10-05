# q109-10: A PersistentVolumeClaim never leaves Pending

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-10-pvc-pending-shared-directory`

Vector Bioinformatics Lab's alignment pipeline writes intermediate results to a volume before a
summarization job reads them. In namespace `q109-10-pvc-pending-shared-directory` you will find:

- a PersistentVolume named `q109-10-shared-pv` (`hostPath`-backed, storage class
  `manual-q109-10`)
- a PersistentVolumeClaim named `shared-claim` requesting storage class `manual-q109-10`, stuck
  `Pending` since it was created

Get `shared-claim` bound to `q109-10-shared-pv`.

Do not modify the PersistentVolume. Keep the claim's name, namespace, and storage class.

## Hint

Run `kubectl describe pvc/shared-claim` and read the Events for why it hasn't bound, then compare
`kubectl get pv,pvc -o wide` for the two objects side by side. The Persistent Volumes concept page's
"Access Modes" section explains what a PV must offer for a claim to bind to it.
