# q108-26-networkpolicy-default-deny-all-ingress: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-ingress-traffic

```sh
kubectl apply -n q108-26-networkpolicy-default-deny-all-ingress -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress
EOF
```
