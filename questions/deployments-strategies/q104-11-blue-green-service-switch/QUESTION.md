# q104-11: Cut a Service over from blue to green

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-11-blue-green-service-switch`

You'll find two Deployments in namespace `q104-11-blue-green-service-switch`:

- `web-blue` (3 replicas, image `nginx:1.24-alpine`, pod labels `app=web`, `version=blue`) - currently live
- `web-green` (3 replicas, image `nginx:1.25-alpine`, pod labels `app=web`, `version=green`) - ready, but not receiving traffic

A Service named `web-svc` currently selects `app=web, version=blue`. Change `web-svc`'s selector so it routes to the green pods (`app=web, version=green`) instead. Do not modify either Deployment.

## Hint

Search kubernetes.io/docs for **"service selector label"** - the Service concept page explains
how a Service's `spec.selector` determines its Endpoints. Changing the selector re-targets
traffic immediately without touching the Deployments - that cutover is the whole blue/green
switch in this pattern.
