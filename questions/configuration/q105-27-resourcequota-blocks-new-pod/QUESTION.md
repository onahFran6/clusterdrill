# q105-27-resourcequota-blocks-new-pod: Diagnose a ResourceQuota blocking a new pod and right-size requests

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-27-resourcequota-blocks-new-pod`

Namespace `q105-27-resourcequota-blocks-new-pod` has a `ResourceQuota` named `compute-quota` that
caps the namespace's total `requests.cpu` at `500m` and `requests.memory` at `512Mi`. A Deployment
named `primary` (1 replica) already runs there, with its container requesting `cpu: 400m` and
`memory: 400Mi` - do not change `primary`'s replica count or resource requests.

A second Deployment manifest is sitting on disk at `~/sidecar-job.yaml`, requesting `cpu: 300m` and
`memory: 200Mi` per container. Applying it as-is will be rejected by `compute-quota`, because the
namespace does not have that much headroom left.

Diagnose why the new Deployment's Pods cannot be created (its ReplicaSet's events will show the
quota rejection), then edit `~/sidecar-job.yaml` so its container's resource requests fit inside
the quota's **remaining** budget - at most `cpu: 100m` and `memory: 112Mi` - and apply it as a
Deployment named `sidecar-job`. When you're done, both `primary` and `sidecar-job` must be running
with 1/1 ready replicas, and `compute-quota`'s used `requests.cpu`/`requests.memory` must stay
within its hard limits.

## Hint

Search kubernetes.io/docs for **"resource quota"** - the Resource Quotas concept page's
"Viewing and Setting Quotas" section shows how a Pod creation is rejected and reported as an event
on its ReplicaSet/Deployment when it would exceed a namespace's `requests.cpu`/`requests.memory`.
