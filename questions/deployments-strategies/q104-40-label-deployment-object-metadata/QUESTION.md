# q104-40: Label the Deployment object, not its pod template

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-40-label-deployment-object-metadata`

A Deployment named `notifications` (image `nginx:1.25-alpine`, 2 replicas) already exists in
namespace `q104-40-label-deployment-object-metadata` and is fully rolled out with both replicas
Ready.

Add the label `team=growth` to the Deployment resource's own metadata (`.metadata.labels`) - not
to `.spec.template.metadata.labels`. When you're done, `notifications`'s pod template labels must
be unchanged, and both replicas must still be Ready.

## Hint

Search kubernetes.io/docs for **"kubectl label"** - the `kubectl label` command reference shows
how to add a label directly to a resource's own metadata, distinct from that resource's pod
template labels (which only `.spec.template.metadata.labels` controls). Labeling the object
itself does not change the pod template, so it must not create a new ReplicaSet or restart pods.
