# q114-03: Which size wins?

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-03-which-size-wins`

Three `Available` PersistentVolumes already exist in StorageClass `manual-q114-03`:
`q114-03-1g` (1Gi), `q114-03-5g` (5Gi) and `q114-03-10g` (10Gi).

- `(ungraded)` Predict which PV will bind before you create anything.
- Create PVC `danube-claim` requesting **2Gi** (`ReadWriteOnce`, StorageClass `manual-q114-03`, no
  selector).

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Binding" section. The controller
won't give you a PV smaller than you asked for. Among the ones big enough, which does it choose?
Does the bound claim report what it asked for, or what it got?
