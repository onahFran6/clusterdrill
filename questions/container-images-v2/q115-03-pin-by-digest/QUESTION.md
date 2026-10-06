# q115-03: Pin what's running by digest

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q115-03-pin-by-digest`

Team Terra's Deployment `web` runs `nginx:1.27`, already rolled out at 2 replicas. Tags can be
moved to new builds, and an audit requires production to run exactly the bytes it runs today.

- Find the exact image digest the running `web` pods actually use
  (`status.containerStatuses[].imageID`, not the spec's own tag).
  `(ungraded, Task narrative only)` predict whether the tag `nginx:1.27` could ever point to a
  different digest in the future before you look.
- Change Deployment `web` to reference that digest instead of the tag, and confirm the new pods
  resolve to the same digest.

## Hint

Search kubernetes.io/docs for **"Images"** and the section on image digests
(`name@sha256:...`). A Pod's `spec` shows what was asked for; its container `status` shows what
was actually pulled. `kubectl set image` on a Deployment's pod template is a normal, mutable
patch - no `replace --force` needed here.
