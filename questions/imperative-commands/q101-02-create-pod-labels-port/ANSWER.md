# q101-02: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/

```sh
kubectl run label-demo --image=httpd:2.4-alpine \
  --labels=app=label-demo,tier=frontend \
  --port=8080 \
  -n q101-02-create-pod-labels-port
```
