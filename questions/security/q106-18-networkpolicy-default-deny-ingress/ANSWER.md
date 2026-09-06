# q106-18: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q106-18-networkpolicy-default-deny-ingress -f - <<EOF
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
