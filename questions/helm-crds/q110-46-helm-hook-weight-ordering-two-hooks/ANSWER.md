# q110-46-helm-hook-weight-ordering-two-hooks: reference solution

Doc: https://helm.sh/docs/topics/charts_hooks/#hook-weights

```sh
CHART=questions/helm-crds/q110-46-helm-hook-weight-ordering-two-hooks/chart

sed -i.bak 's/"helm.sh\/hook-weight": "10"/"helm.sh\/hook-weight": "5"/' \
  "$CHART/templates/hook-seed.yaml"
sed -i.bak 's/"helm.sh\/hook-weight": "5"/"helm.sh\/hook-weight": "10"/' \
  "$CHART/templates/hook-verify.yaml"
rm -f "$CHART/templates/"*.bak

helm install demo "$CHART" -n q110-46-helm-hook-weight-ordering-two-hooks --timeout 30s
```
