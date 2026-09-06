# q108-48-networkpolicy-multi-tier-chained-egress-diagnosis: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource

```sh
kubectl patch networkpolicy backend-to-database-egress \
  -n q108-48-networkpolicy-multi-tier-chained-egress-diagnosis \
  --type json \
  -p '[{"op":"replace","path":"/spec/egress/0/to/0/podSelector/matchLabels/tier","value":"database"}]'
```
