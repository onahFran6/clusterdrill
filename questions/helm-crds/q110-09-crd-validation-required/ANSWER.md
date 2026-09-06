# q110-09: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/

```sh
kubectl apply -n q110-09-crd-validation-required -f - <<'EOF'
apiVersion: support.clusterdrill.io/v1
kind: TicketRequest
metadata:
  name: outage-1
spec:
  priority: high
EOF
```
