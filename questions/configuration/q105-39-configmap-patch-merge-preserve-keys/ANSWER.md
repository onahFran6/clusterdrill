# q105-39-configmap-patch-merge-preserve-keys: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/

```sh
kubectl patch configmap app-settings -n q105-39-configmap-patch-merge-preserve-keys \
  --type=merge \
  -p '{"data":{"MAX_RETRIES":"5"}}'
```
