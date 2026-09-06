# q104-35-basic-image-update-set-image: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-image

```sh
kubectl set image deployment/web-cache web-cache=redis:7.4-alpine \
  -n q104-35-basic-image-update-set-image

kubectl rollout status deployment/web-cache -n q104-35-basic-image-update-set-image --timeout=60s
```
