# q111-16: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl patch deployment menu -n q111-16-readiness-probe-blocks-rollout --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/"}]'

kubectl rollout status deployment/menu -n q111-16-readiness-probe-blocks-rollout --timeout=60s
```

For 3 replicas the defaults are `maxUnavailable` = floor(0.75) = 0 and `maxSurge` = ceil(0.75) =
1: one new pod is allowed to exist on top of the 3 old ones, but zero old pods may ever become
unavailable. With the probe hitting `/healthz` (a 404 on stock nginx), the one new pod starts but
never turns Ready, so the controller can never remove an old pod either - the rollout stalls with
no outage, just stuck forever. Fixing the probe's path is a template change, so it creates
another revision; the broken ReplicaSet is scaled back to 0 once the new one is fully Ready.
