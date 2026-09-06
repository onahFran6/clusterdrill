# q108-43-service-internaltrafficpolicy-local: Restrict a Service to same-node internal traffic

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-43-service-internaltrafficpolicy-local`

`setup.sh` already created a Deployment named `metrics-sidecar` (2 replicas, pod-template label
`app=metrics-sidecar`) and a `ClusterIP` Service named `metrics-sidecar-svc` in namespace
`q108-43-service-internaltrafficpolicy-local`. Other pods on the same node are meant to call this
Service and always land on the local replica (avoiding a cross-node network hop for a
latency-sensitive sidecar pattern), but the Service currently uses the default internal traffic
routing, which may send a request to a replica on any node.

Fix the Service so **in-cluster** callers are only ever routed to an endpoint on the same node
they're calling from, without changing anything else about the Service.

## Hint

Search kubernetes.io/docs for **"internalTrafficPolicy"** - the Service concept page's Traffic
Policies section shows `spec.internalTrafficPolicy: Local` as the field that restricts
in-cluster (as opposed to external) traffic to node-local endpoints only - distinct from
`externalTrafficPolicy`, which governs traffic arriving from outside the cluster.
