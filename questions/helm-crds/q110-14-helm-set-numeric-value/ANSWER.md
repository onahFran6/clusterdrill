# q110-14: reference solution

Doc: https://helm.sh/docs/helm/helm_install/

```sh
helm install grid questions/helm-crds/q110-14-helm-set-numeric-value/chart \
  -n q110-14-helm-set-numeric-value --set replicaCount=4 --wait
```
