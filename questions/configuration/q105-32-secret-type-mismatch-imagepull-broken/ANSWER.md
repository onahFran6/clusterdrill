# q105-32-secret-type-mismatch-imagepull-broken: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

```sh
kubectl delete secret registry-cred -n q105-32-secret-type-mismatch-imagepull-broken

kubectl create secret docker-registry registry-cred \
  --docker-server=registry.example.internal \
  --docker-username=svc-deploy \
  --docker-password=sample-registry-password \
  --docker-email=svc-deploy@example.internal \
  -n q105-32-secret-type-mismatch-imagepull-broken

kubectl rollout restart deployment/private-app -n q105-32-secret-type-mismatch-imagepull-broken

kubectl rollout status deployment/private-app -n q105-32-secret-type-mismatch-imagepull-broken --timeout=60s
```
