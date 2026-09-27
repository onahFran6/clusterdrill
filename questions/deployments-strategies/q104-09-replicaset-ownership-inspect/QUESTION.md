# q104-09: Identify and label the active ReplicaSet behind a Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-09-replicaset-ownership-inspect`

A Deployment named `sessions` (image `nginx:1.25-alpine`, 3 replicas) already exists in
namespace `q104-09-replicaset-ownership-inspect`.

Find the single ReplicaSet that `sessions` currently owns and is actively scaled to 3 replicas
(there may be old, scaled-to-0 ReplicaSets left behind from earlier revisions - ignore those), and
add the label `active=true` to that one ReplicaSet object, without changing anything else about
it.

## Hint

Search kubernetes.io/docs for **"deployment replicaset relationship owner reference"** - a
Deployment never manages pods directly; it owns ReplicaSets, and only one is scaled up at a time
once a rollout completes. The ReplicaSet and Deployment concept pages both explain the
`ownerReferences` link.
