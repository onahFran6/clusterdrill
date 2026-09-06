# q108-47-networkpolicy-podselector-matchexpressions-notin: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements

```sh
kubectl patch networkpolicy worker-pool-restrict-egress \
  -n q108-47-networkpolicy-podselector-matchexpressions-notin \
  --type json \
  -p '[
    {"op":"remove","path":"/spec/egress/0/to/0/podSelector/matchLabels"},
    {"op":"add","path":"/spec/egress/0/to/0/podSelector/matchExpressions","value":[
      {"key":"tier","operator":"NotIn","values":["legacy"]}
    ]}
  ]'
```
