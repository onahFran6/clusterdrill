# q104-43-multi-container-both-images-single-rollout: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-image

```sh
kubectl set image deployment/edge-proxy \
  proxy=nginx:1.25-alpine sidecar-logger=busybox:1.36 \
  -n q104-43-multi-container-both-images-single-rollout

kubectl rollout status deployment/edge-proxy -n q104-43-multi-container-both-images-single-rollout --timeout=60s
```
