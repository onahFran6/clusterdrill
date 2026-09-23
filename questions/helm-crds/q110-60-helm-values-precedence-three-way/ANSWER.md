# q110-60: reference solution

Doc: https://helm.sh/docs/helm/helm_install/#helm-install

```sh
helm install threeway questions/helm-crds/q110-60-helm-values-precedence-three-way/chart \
  -n q110-60-helm-values-precedence-three-way \
  -f questions/helm-crds/q110-60-helm-values-precedence-three-way/chart-values/override-values.yaml \
  --set replicaCount=5 \
  --set extra.featureFlag=true \
  --set-string extra.featureFlag=true \
  --wait
```

`replicaCount` lands at `5`: `--set` always outranks a `-f` values file, regardless of which
one appears first on the command line. `extra.featureFlag` lands as the literal string
`"true"`: Helm's fixed precedence tier is chart defaults < `-f` files (in the order given) <
`--set` (in the order given) < `--set-string` (in the order given) < `--set-file` - so
`--set-string` always wins over a plain `--set` for the same key, regardless of which one is
written first.
