# q107-11: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container

```sh
kubectl debug -n q107-11-debug-ephemeral-container payments-api \
  -it \
  --image=busybox:1.36 \
  --target=payments-api \
  --container=debugger \
  -- sh -c "echo ephemeral debug container attached"
```
