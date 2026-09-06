# q108-35-kubectl-expose-pod-imperative: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose

```sh
kubectl expose pod cache-proxy -n q108-35-kubectl-expose-pod-imperative \
  --name=cache-proxy-svc --port=6379 --target-port=6379
```
