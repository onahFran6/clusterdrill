# q101-08: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_set/kubectl_set_image/

```sh
kubectl set image deployment/image-rollout app=nginx:1.25-alpine -n q101-08-set-image-deployment
kubectl rollout status deployment/image-rollout -n q101-08-set-image-deployment --timeout=60s
```
