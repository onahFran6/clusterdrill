# q104-28-multi-container-pod-partial-image-update: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#set-image

```sh
kubectl set image deployment/edge-proxy \
  sidecar-agent=busybox:1.36.1 \
  -n q104-28-multi-container-pod-partial-image-update

kubectl rollout status deployment/edge-proxy \
  -n q104-28-multi-container-pod-partial-image-update --timeout=60s
```
