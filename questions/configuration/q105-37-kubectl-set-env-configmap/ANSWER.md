# q105-37-kubectl-set-env-configmap: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_set_env/

```sh
kubectl set env deployment/web-frontend --from=configmap/feature-flags -n q105-37-kubectl-set-env-configmap

kubectl rollout status deployment/web-frontend -n q105-37-kubectl-set-env-configmap --timeout=60s
```
