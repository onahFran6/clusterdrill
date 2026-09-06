# q108-39-networkpolicy-default-deny-all-egress: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-egress-traffic

```sh
kubectl apply -n q108-39-networkpolicy-default-deny-all-egress -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: worker-deny-egress
spec:
  podSelector:
    matchLabels:
      app: worker
  policyTypes:
    - Egress
EOF
```
