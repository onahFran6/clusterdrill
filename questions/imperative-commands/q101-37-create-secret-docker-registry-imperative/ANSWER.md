# q101-37-create-secret-docker-registry-imperative: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line

```sh
kubectl create secret docker-registry registry-cred \
  -n q101-37-create-secret-docker-registry-imperative \
  --docker-server=registry.example.com \
  --docker-username=svc-deploy \
  --docker-password='sup3r-secret!' \
  --docker-email=svc-deploy@example.com
```
