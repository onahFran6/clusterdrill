# q104-11: Cut a Service over from blue to green

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-11-blue-green-service-switch`

`setup.sh` already created two separate Deployments in namespace
`q104-11-blue-green-service-switch`:

- `web-blue` (3 replicas, image `nginx:1.24-alpine`, pod label `app=web`, `version=blue`) - the
  current live version
- `web-green` (3 replicas, image `nginx:1.25-alpine`, pod label `app=web`, `version=green`) - the
  new version, already running and fully ready, but not receiving any traffic yet

A Service named `web-svc` currently routes to the blue Deployment's pods via the selector
`app=web, version=blue`.

Perform a blue/green cutover: change `web-svc`'s selector so it routes to the green Deployment's
pods instead (`app=web, version=green`), without touching either Deployment. This is the entire
mechanism - the switch is instant because it only changes which pods the Service's endpoints
point at.

## Hint

Search kubernetes.io/docs for **"service selector label"** - the Service concept page explains
how a Service's `spec.selector` determines its Endpoints, and how changing it re-targets traffic
immediately without redeploying anything.
