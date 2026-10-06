# q114-05: Get the data back after deleting the claim

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-05-get-data-back-after-delete`

Pod `writer` and its claim were deleted by mistake. PV `q114-05-pv` uses the `Retain` reclaim
policy, and the data is still on it.

- `(ungraded)` Note the PV's current phase.
- Remove its stale `claimRef`. Create PVC `rhine-new` bound to it via `volumeName`. Create Pod
  `reader` (`busybox:1.36`) that prints `/data/msg`.

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Retain" reclaim policy section. A
`Released` PV still remembers its old claim, so no new claim can bind to it. Which field holds
that memory? Remove it, and the PV becomes `Available` again.
