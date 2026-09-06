# q101-16: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

```sh
kubectl run custom-cmd --image=busybox:1.36 \
  -n q101-16-run-pod-command-args \
  -- sh -c "echo hello-ckad && sleep 3600"

kubectl wait --for=condition=Ready pod/custom-cmd -n q101-16-run-pod-command-args --timeout=60s
```
