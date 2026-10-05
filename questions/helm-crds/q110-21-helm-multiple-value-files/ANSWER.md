# q110-21-helm-multiple-value-files: reference solution

Doc: https://helm.sh/docs/helm/helm_install/

```sh
helm install stack $HOME/practice-work/q110-21-helm-multiple-value-files/chart \
  -n q110-21-helm-multiple-value-files \
  -f $HOME/practice-work/q110-21-helm-multiple-value-files/overrides/prod-values.yaml \
  --wait --timeout 60s
```
