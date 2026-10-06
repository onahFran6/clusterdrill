# q114-02: Pending because of an access mode

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-02-pending-access-mode`

Claim `amazon-pvc` has been `Pending` all morning, though PV `q114-02-pv` is `Available` with
plenty of space.

- `(ungraded)` Find the reason the claim can't bind (`kubectl describe pvc`/`kubectl get pv`).
- Fix `amazon-pvc` so it binds to `q114-02-pv`. The claim must keep its name.

## Hint

Compare the claim and the PV field by field: class, size, access modes. The PV must offer every
mode the claim asks for. Try editing the claim's access mode in place and read the error - search
kubernetes.io/docs for **"Persistent Volumes"**, the note on which PVC fields can be expanded
after creation.
