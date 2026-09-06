# q110-33-helm-set-string-flag: reference solution

Doc: https://helm.sh/docs/helm/helm_install/

```sh
helm install demo questions/helm-crds/q110-33-helm-set-string-flag/chart \
  -n q110-33-helm-set-string-flag \
  --set-string legacyMode=false \
  --wait
```
