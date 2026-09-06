# q110-02: reference solution

Doc: https://helm.sh/docs/helm/helm_install/

```sh
helm install ctr questions/helm-crds/q110-02-helm-set-override/chart \
  -n q110-02-helm-set-override --set replicaCount=3 --wait
```
