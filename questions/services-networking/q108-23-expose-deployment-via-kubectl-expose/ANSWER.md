# q108-23-expose-deployment-via-kubectl-expose: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose

```sh
kubectl expose deployment billing-worker \
  --name=billing-worker-svc \
  --port=443 \
  --target-port=8443 \
  --type=ClusterIP \
  -n q108-23-expose-deployment-via-kubectl-expose

kubectl wait --for=jsonpath='{.subsets[0].addresses[0].ip}' \
  endpoints/billing-worker-svc -n q108-23-expose-deployment-via-kubectl-expose --timeout=60s
```
