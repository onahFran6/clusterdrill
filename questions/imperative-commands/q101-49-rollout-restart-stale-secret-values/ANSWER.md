# q101-49-rollout-restart-stale-secret-values: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout

```sh
# Confirm the drift first:
kubectl get secret billing-creds -n q101-49-rollout-restart-stale-secret-values \
  -o jsonpath='{.data.API_TOKEN}' | base64 -d
POD=$(kubectl get pods -n q101-49-rollout-restart-stale-secret-values -l app=billing-sync -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n q101-49-rollout-restart-stale-secret-values "$POD" -- sh -c 'echo $API_TOKEN'

kubectl rollout restart deployment/billing-sync \
  -n q101-49-rollout-restart-stale-secret-values

kubectl rollout status deployment/billing-sync \
  -n q101-49-rollout-restart-stale-secret-values --timeout=60s
```
