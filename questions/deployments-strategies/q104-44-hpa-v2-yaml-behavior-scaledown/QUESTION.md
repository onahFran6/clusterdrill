# q104-44: Author a v2 HPA with scale-down stabilization

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-44-hpa-v2-yaml-behavior-scaledown`

A Deployment named `render-farm` (image `nginx:1.25-alpine`, 3 replicas, each container already
requesting `cpu: 100m`) already exists in namespace `q104-44-hpa-v2-yaml-behavior-scaledown`.

Create a HorizontalPodAutoscaler named `render-farm-hpa` with `apiVersion: autoscaling/v2` that
targets Deployment `render-farm`, keeps replicas between `3` and `10`, scales on average CPU
utilization of `70%`, and sets `spec.behavior.scaleDown.stabilizationWindowSeconds` to `120`.
Author it as a manifest - `kubectl autoscale` cannot set the behavior field.

## Hint

Search kubernetes.io/docs for **"horizontal pod autoscaler scaling policies"** - the HPA concept
page's "Configurable scaling behavior" section shows
`spec.behavior.scaleDown.stabilizationWindowSeconds`, a `v2`-only field that damps how quickly
the HPA scales replicas back down after a brief traffic dip.
