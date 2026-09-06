# q101-19: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

```sh
kubectl run sized-app --image=nginx:1.25-alpine \
  -n q101-19-run-pod-resource-limits \
  --overrides='{"spec":{"containers":[{"name":"sized-app","image":"nginx:1.25-alpine","resources":{"requests":{"cpu":"100m","memory":"64Mi"},"limits":{"cpu":"250m","memory":"128Mi"}}}]}}'
```
