# q104-37-set-env-var-triggers-rollout: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-env

```sh
kubectl set env deployment/worker LOG_LEVEL=debug -n q104-37-set-env-var-triggers-rollout

kubectl rollout status deployment/worker -n q104-37-set-env-var-triggers-rollout --timeout=60s
```
