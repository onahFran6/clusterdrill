# q110-53: reference solution

Doc: https://helm.sh/docs/helm/helm_install/#helm-install

```sh
helm install web questions/helm-crds/q110-53-helm-set-nested-and-set-string/chart \
  -n q110-53-helm-set-nested-and-set-string \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=app.example.com \
  --set resources.limits.cpu=500m \
  --set-string extra.buildFlag=true \
  --wait
```
