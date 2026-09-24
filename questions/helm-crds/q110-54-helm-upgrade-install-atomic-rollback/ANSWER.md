# q110-54: reference solution

Doc: https://helm.sh/docs/helm/helm_upgrade/#options

```sh
helm upgrade --install api questions/helm-crds/q110-54-helm-upgrade-install-atomic-rollback/chart \
  -n q110-54-helm-upgrade-install-atomic-rollback \
  --set image=nginx:this-tag-does-not-exist \
  --atomic --wait --timeout 60s || true
```
