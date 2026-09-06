# q108-06: Record a Service's live backing pod count from its EndpointSlice

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-06-inspect-endpointslices`

`setup.sh` already created a Deployment named `order-api` (image `httpd:2.4-alpine`, 4 replicas,
container port `80`, pod-template label `app=order-api`) and a ClusterIP Service named
`order-api-svc` selecting it, both in namespace `q108-06-inspect-endpointslices`. The Service
already routes traffic correctly - this task is about reading, not creating, networking objects.

Every Service automatically gets a matching `EndpointSlice` object (the modern, scalable
replacement for the older `Endpoints` API) that lists the ready pod IPs actually backing it.

Without changing any existing object, create a ConfigMap named `order-api-endpoint-report` in the
same namespace with a single key `ready-count` whose value is the number of **ready** addresses
currently listed across `order-api-svc`'s EndpointSlice(s) - this should equal the Deployment's
replica count once every pod is Ready.

## Hint

Search kubernetes.io/docs for **"EndpointSlices"** - the EndpointSlices concept page shows the
`kubernetes.io/service-name` label used to find the EndpointSlice(s) that belong to a given
Service, and the `endpoints[].conditions.ready` field per address.
