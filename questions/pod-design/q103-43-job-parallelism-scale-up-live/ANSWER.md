# q103-43: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#controlling-parallelism

`kubectl scale job/... --replicas=N` looks tempting (same reflex as Deployments) but batch/v1
Jobs on this cluster expose no `scale` subresource - it 404s. `kubectl patch` (or `kubectl edit`)
is the one real path here.

```sh
NS=q103-43-job-parallelism-scale-up-live

kubectl patch job speedy-batch -n "$NS" --type merge -p '{"spec":{"parallelism":3}}'

kubectl wait --for=condition=Complete job/speedy-batch -n "$NS" --timeout=120s
```
