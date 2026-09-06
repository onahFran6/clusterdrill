# q104-09: Identify and label the active ReplicaSet behind a Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-09-replicaset-ownership-inspect`

`setup.sh` already created a Deployment named `sessions` (image `nginx:1.25-alpine`, 3 replicas)
in namespace `q104-09-replicaset-ownership-inspect`. A Deployment never manages pods directly - it
owns a ReplicaSet, which owns the pods.

Find the single ReplicaSet that `sessions` currently owns and is actively scaled to 3 replicas
(there may be old, scaled-to-0 ReplicaSets left behind from earlier revisions - ignore those), and
add the label `active=true` to that one ReplicaSet object, without changing anything else about
it.

## Hint

Search kubernetes.io/docs for **"deployment replicaset relationship owner reference"** - the
ReplicaSet concept page and the Deployment concept page both explain how a Deployment's
`ownerReferences` link its ReplicaSets together, and how only one is scaled up at a time once a
rollout completes.
