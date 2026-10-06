# q114-09: Once per node, or once per pod?

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-09-once-per-node-or-pod`

PVs `q114-09-rwo` (`ReadWriteOnce`) and `q114-09-rwop` (`ReadWriteOncePod`) already exist, both
1Gi in StorageClass `manual-q114-09`.

- Create claims `c-rwo`/`c-rwop` bound via `volumeName` to the matching PV.
- Create Pods `a1`/`a2` (`busybox:1.36`) both using `c-rwo`, and `b1` then (after a short pause)
  `b2` both using `c-rwop`, all on this single-node cluster.
- `(ungraded)` Predict each Pod's STATUS before checking.

## Hint

Search kubernetes.io/docs for **"ReadWriteOncePod"** on the Persistent Volumes concept page - is
"Once" in `ReadWriteOnce` about nodes, or about pods? `ReadWriteOncePod` exists because of the
answer. Create `b1` and let it start before you create `b2`.
