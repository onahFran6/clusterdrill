# q108-06: Record a Service's live backing pod count from its EndpointSlice

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-06-inspect-endpointslices`

A Deployment named `order-api` (image `httpd:2.4-alpine`, 4 replicas,
container port `80`, pod-template label `app=order-api`) and a ClusterIP Service named
`order-api-svc` selecting it already exist in namespace `q108-06-inspect-endpointslices`. The
Service already routes traffic correctly. Do not change any existing object.

Create a ConfigMap named `order-api-endpoint-report` in the same namespace with a single key
`ready-count` whose value is the number of **ready** addresses currently listed across
`order-api-svc`'s EndpointSlice(s). Once every pod is Ready, that count equals the Deployment's
replica count.

## Hint

Search kubernetes.io/docs for **"EndpointSlices"** - the EndpointSlices concept page shows that
every Service gets an EndpointSlice (the replacement for the older Endpoints API) labeled
`kubernetes.io/service-name`. Count addresses whose `endpoints[].conditions.ready` is true.
