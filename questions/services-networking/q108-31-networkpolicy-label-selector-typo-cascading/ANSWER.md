# q108-31-networkpolicy-label-selector-typo-cascading: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource

```sh
kubectl patch networkpolicy allow-api-to-cache -n q108-31-networkpolicy-label-selector-typo-cascading \
  --type json \
  -p '[{"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels/tier","value":"api"}]'
```
