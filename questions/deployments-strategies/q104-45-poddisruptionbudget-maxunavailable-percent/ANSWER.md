# q104-45-poddisruptionbudget-maxunavailable-percent: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#specifying-a-poddisruptionbudget

```sh
kubectl apply -n q104-45-poddisruptionbudget-maxunavailable-percent -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: catalog-svc-pdb
  labels:
    clusterdrill-question: q104-45-poddisruptionbudget-maxunavailable-percent
spec:
  maxUnavailable: "40%"
  selector:
    matchLabels:
      app: catalog-svc
EOF
```
