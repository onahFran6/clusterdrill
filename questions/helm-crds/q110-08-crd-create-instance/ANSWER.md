# q110-08: reference solution

Doc: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/

```sh
kubectl apply -n q110-08-crd-create-instance -f - <<'EOF'
apiVersion: gadgets.clusterdrill.io/v1
kind: Widget
metadata:
  name: gizmo
spec:
  color: blue
  weightGrams: 150
EOF
```
