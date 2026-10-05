# q109-12: A PersistentVolumeClaim won't bind to the only volume available to it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-12-pvc-request-too-large`

Neutrino Computing Center's detector calibration job needs output storage. In namespace
`q109-12-pvc-request-too-large` you will find:

- a PersistentVolume named `q109-12-small-pv` (`hostPath`-backed, storage class
  `manual-q109-12`)
- a PersistentVolumeClaim named `oversized-claim` requesting storage class `manual-q109-12`,
  stuck `Pending` since it was applied

Get `oversized-claim` bound to `q109-12-small-pv` - the only volume available to it. Do not
modify the PersistentVolume, and do not request less than `100Mi`.

## Hint

Run `kubectl describe pvc/oversized-claim` for why it hasn't bound, then check
`kubectl get pv q109-12-small-pv -o wide` for what's actually on offer. The Persistent Volumes
concept page has sections on both "Binding" and "Expanding Persistent Volume Claims" - one
explains the rule the control plane binds by, the other explains a limit on which direction a
claim's request can move.
