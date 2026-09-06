# q101-22-create-pod-multiple-ports-imperative: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/

```sh
kubectl run multiport-app --image=nginx:1.25-alpine \
  -n q101-22-create-pod-multiple-ports-imperative \
  --overrides='{"spec":{"containers":[{"name":"multiport-app","image":"nginx:1.25-alpine","ports":[{"containerPort":8080,"name":"http"},{"containerPort":8443,"name":"https"}]}]}}'
```
