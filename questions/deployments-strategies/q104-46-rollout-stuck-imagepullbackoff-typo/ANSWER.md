# q104-46-rollout-stuck-imagepullbackoff-typo: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-image

```sh
kubectl set image deployment/auth-service auth-service=redis:7.2-alpine \
  -n q104-46-rollout-stuck-imagepullbackoff-typo

kubectl rollout status deployment/auth-service -n q104-46-rollout-stuck-imagepullbackoff-typo --timeout=90s
```
