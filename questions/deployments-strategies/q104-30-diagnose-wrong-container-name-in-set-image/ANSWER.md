# q104-30-diagnose-wrong-container-name-in-set-image: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-image

```sh
kubectl get deployment search-api -n q104-30-diagnose-wrong-container-name-in-set-image \
  -o jsonpath='{.spec.template.spec.containers[*].name}'

kubectl set image deployment/search-api \
  search-api=nginx:1.26-alpine \
  -n q104-30-diagnose-wrong-container-name-in-set-image

kubectl rollout status deployment/search-api \
  -n q104-30-diagnose-wrong-container-name-in-set-image --timeout=60s
```
