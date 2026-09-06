# q104-40-label-deployment-object-metadata: Label the Deployment object itself, not its pod template

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-40-label-deployment-object-metadata`

`setup.sh` already created a Deployment named `notifications` (image `nginx:1.25-alpine`, 2
replicas) in namespace `q104-40-label-deployment-object-metadata`, and it is already fully rolled
out with both replicas Ready.

Add the label `team=growth` to the **Deployment resource's own metadata** (`.metadata.labels`),
for tracking which team owns it - not to `.spec.template.metadata.labels` (the pod template).
Since this only touches the Deployment object's own metadata and not its pod template, it must not
create a new ReplicaSet or restart any pods: when you're done, `notifications`'s pod template
labels must be unchanged, and both replicas must still be the same Ready pods as before.

## Hint

Search kubernetes.io/docs for **"kubectl label"** - the `kubectl label` command reference shows
how to add a label directly to a resource's own metadata, distinct from that resource's pod
template labels (which only `.spec.template.metadata.labels` controls).
