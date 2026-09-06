# q104-26-poddisruptionbudget-minavailable: reference solution

Doc: https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget

```sh
kubectl apply -n q104-26-poddisruptionbudget-minavailable -f - <<'EOF'
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: checkout-svc-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: checkout-svc
EOF
```
