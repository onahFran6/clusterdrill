# q110-31-crd-cel-cross-field-validation: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#validation-rules

Discover the rule (either works):

```sh
kubectl get crd budgets.finance.clusterdrill.io -o yaml | grep -A2 x-kubernetes-validations
```

Shows the rule `self.reserved <= self.limit`, message `reserved must not exceed limit` - so the
largest valid `reserved` for `limit: 500` is `500` itself (the rule is `<=`, not `<`).

```sh
kubectl apply -n q110-31-crd-cel-cross-field-validation -f - <<EOF
apiVersion: finance.clusterdrill.io/v1
kind: Budget
metadata:
  name: q4-cap
spec:
  limit: 500
  reserved: 500
EOF
```
