# q101-06: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_deployment/

```sh
kubectl create deployment api-server \
  --image=nginx:1.25-alpine \
  --replicas=3 \
  -n q101-06-create-deployment-imperative

kubectl rollout status deployment/api-server -n q101-06-create-deployment-imperative --timeout=60s
```
