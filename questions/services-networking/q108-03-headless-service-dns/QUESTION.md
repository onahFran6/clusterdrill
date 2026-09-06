# q108-03: Create a headless Service for direct pod-to-pod DNS

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-03-headless-service-dns`

`setup.sh` already created a Deployment named `cache-node` (image `redis:7-alpine`, 3 replicas,
container port `6379`, pod-template label `app=cache-node`) in namespace
`q108-03-headless-service-dns`.

The application team wants DNS lookups against the Service name to return the individual pod IPs
directly (one A/AAAA record per ready pod), instead of a single load-balanced cluster IP.

Write a Service manifest named `cache-node-headless` that:

- selects pods with label `app=cache-node`
- listens on port `6379` and forwards to container port `6379`
- is headless (no cluster IP is allocated)

## Hint

Search kubernetes.io/docs for **"headless Services"** - the Service concept page explains that
setting `clusterIP: None` produces a Service with no single virtual IP, so DNS resolves the
Service name to the set of pod IPs instead.
