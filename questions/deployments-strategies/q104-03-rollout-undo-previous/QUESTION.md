# q104-03: Undo a bad rollout back to the previous revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-03-rollout-undo-previous`

`setup.sh` already created a Deployment named `search` in namespace `q104-03-rollout-undo-previous`
with 3 replicas, and it has already been rolled out twice: revision 1 ran image
`nginx:1.24-alpine`, and revision 2 (the current, live one) rolled out a broken image
`nginx:1.25-alpine-does-not-exist` that cannot be pulled.

Roll `search` back to the previous working revision so all 3 replicas become ready again on
`nginx:1.24-alpine`, without hand-typing the image name yourself.

## Hint

Search kubernetes.io/docs for **"kubectl rollout undo"** - the `kubectl rollout` command
reference documents `undo` for reverting a Deployment to an earlier ReplicaSet revision.
