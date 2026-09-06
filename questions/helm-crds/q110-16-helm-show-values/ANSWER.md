# q110-16: reference solution

Doc: https://helm.sh/docs/helm/helm_show_values/

```sh
REGION=$(helm show values questions/helm-crds/q110-16-helm-show-values/chart | grep -oE '^region: .*' | cut -d' ' -f2)
kubectl create configmap chart-defaults -n q110-16-helm-show-values --from-literal=region="$REGION"
```
