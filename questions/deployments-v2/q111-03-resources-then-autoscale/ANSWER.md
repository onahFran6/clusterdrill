# q111-03: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_autoscale/

```sh
kubectl set resources deployment ingest -n q111-03-resources-then-autoscale \
  --requests=cpu=200m,memory=128Mi --limits=cpu=500m,memory=256Mi
kubectl rollout status deployment/ingest -n q111-03-resources-then-autoscale --timeout=60s

kubectl autoscale deployment ingest -n q111-03-resources-then-autoscale \
  --min=2 --max=6 --cpu-percent=70
```

Utilisation is measured against the container's own **request**, so an HPA on a Deployment
without CPU requests can't compute anything - that's why resources have to be set first. `TARGETS`
shows `<unknown>` until metrics-server has data for this Deployment, which is fine; the grader
only checks the HPA's configured target, not a live reading. Once an HPA owns the replica count,
drop `replicas` from any manifest you reapply later, or every `kubectl apply` resets it.
