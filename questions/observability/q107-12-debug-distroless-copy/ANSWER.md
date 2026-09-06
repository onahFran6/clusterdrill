# q107-12: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#copying-a-pod-while-adding-a-new-container

```sh
kubectl debug -n q107-12-debug-distroless-copy minimal-svc \
  -it \
  --image=busybox:1.36 \
  --copy-to=minimal-svc-debug \
  --container=debugger \
  -- sh -c "echo debug copy ready"
```
