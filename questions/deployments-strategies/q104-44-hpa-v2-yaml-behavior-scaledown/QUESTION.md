# q104-44-hpa-v2-yaml-behavior-scaledown: Author an autoscaling/v2 HPA with a scale-down stabilization window

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-44-hpa-v2-yaml-behavior-scaledown`

`setup.sh` already created a Deployment named `render-farm` (image `nginx:1.25-alpine`, 3
replicas, each container already requesting `cpu: 100m`) in namespace
`q104-44-hpa-v2-yaml-behavior-scaledown`.

Write a `HorizontalPodAutoscaler` manifest (not `kubectl autoscale` - this needs a field `kubectl
autoscale` can't set) named `render-farm-hpa` using `apiVersion: autoscaling/v2` that:

- targets Deployment `render-farm`
- keeps replicas between `3` and `10`
- scales on average CPU utilization with a target of `70%`
- sets `spec.behavior.scaleDown.stabilizationWindowSeconds` to `120`, so a brief traffic dip
  doesn't immediately scale replicas back down

## Hint

Search kubernetes.io/docs for **"horizontal pod autoscaler scaling policies"** - the HPA concept
page's "Configurable scaling behavior" section shows `spec.behavior.scaleDown.stabilizationWindowSeconds`,
a `v2`-only field for damping how quickly the HPA reacts to a drop in load.
