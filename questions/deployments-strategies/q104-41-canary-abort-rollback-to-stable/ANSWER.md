# q104-41-canary-abort-rollback-to-stable: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale

```sh
kubectl scale deployment/search-canary --replicas=0 -n q104-41-canary-abort-rollback-to-stable
kubectl scale deployment/search-stable --replicas=10 -n q104-41-canary-abort-rollback-to-stable

kubectl rollout status deployment/search-stable -n q104-41-canary-abort-rollback-to-stable --timeout=60s
```
