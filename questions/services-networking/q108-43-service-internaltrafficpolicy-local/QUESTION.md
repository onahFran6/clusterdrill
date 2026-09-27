# q108-43: Restrict a Service to same-node internal traffic

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-43-service-internaltrafficpolicy-local`

A Deployment named `metrics-sidecar` (2 replicas, pod-template label
`app=metrics-sidecar`) and a `ClusterIP` Service named `metrics-sidecar-svc` already exist in
namespace `q108-43-service-internaltrafficpolicy-local`. Other pods on the same node should call
this Service and always land on the local replica. The Service currently may send a request to a
replica on any node.

Fix the Service so **in-cluster** callers are only ever routed to an endpoint on the same node
they're calling from. Do not change anything else about the Service.

## Hint

Search kubernetes.io/docs for **"internalTrafficPolicy"** - the Service concept page's Traffic
Policies section shows `spec.internalTrafficPolicy: Local`, which restricts in-cluster traffic to
node-local endpoints. That field is separate from `externalTrafficPolicy`, which governs traffic
arriving from outside the cluster.
