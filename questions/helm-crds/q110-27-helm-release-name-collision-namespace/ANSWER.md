# q110-27: reference solution

Doc: https://helm.sh/docs/helm/helm_upgrade/

```sh
helm upgrade core \
  questions/helm-crds/q110-27-helm-release-name-collision-namespace/chart-v2 \
  -n q110-27-helm-release-name-collision-namespace --wait
```
