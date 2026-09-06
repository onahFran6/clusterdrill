# q102-14: Distinct resource requests/limits per container

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-14-sidecar-distinct-resources`

Create a Pod named `resource-aware-app` with two containers, each with its
own resource requests and limits:

- Main container named `main` (image `nginx:1.27-alpine`) with:
  - requests: `cpu: 100m`, `memory: 64Mi`
  - limits: `cpu: 250m`, `memory: 128Mi`
- Sidecar container named `metrics-sidecar` (image `busybox:1.36`, command
  `sleep 3600`) with:
  - requests: `cpu: 50m`, `memory: 32Mi`
  - limits: `cpu: 100m`, `memory: 64Mi`

This demonstrates that each container in a multi-container Pod gets its
own independent `resources` block - the Pod's total requested/limited
resources are the sum across all of its containers.

## Hint

Search kubernetes.io/docs for **"resource requests and limits of Pod and
Container"** - the Assign Memory/CPU Resources task pages show the
per-container `resources.requests` / `resources.limits` fields this task
uses.
