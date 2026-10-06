# q114-13: One folder per replica

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-13-one-folder-per-replica`

Deployment `logger` (3 replicas) writes to `/logs/app.log` on shared claim `logs`. All three
replicas write to the **same** file and collide.

- Change `logger` so each replica's `/logs` is its own folder on the claim, named after the pod,
  **without changing the app's command**.
- Add env `POD_NAME` from the Downward API (`metadata.name`) and mount with
  `subPathExpr: $(POD_NAME)` instead of a fixed `subPath`.

## Hint

Search kubernetes.io/docs for **"subPathExpr"** on the Volumes concept page. `subPath` is a fixed
string, so every replica would get the same folder - a sibling field expands `$(VAR)` from the
container's own env. Which Downward API field holds the Pod's name?
