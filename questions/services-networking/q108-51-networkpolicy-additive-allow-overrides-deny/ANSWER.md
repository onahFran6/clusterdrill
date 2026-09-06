# q108-51-networkpolicy-additive-allow-overrides-deny: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q108-51-networkpolicy-additive-allow-overrides-deny -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-all-ingress
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - {}
EOF
```

`api-deny-all-ingress` is left untouched. Both policies now select `app=api` - since
NetworkPolicies are additive, the pod's effective ingress rules are the union of the two, and
`api-allow-all-ingress`'s single unrestricted rule (`- {}`, no `from`/`ports` keys) allows traffic
from any source on any port regardless of the other policy's own empty rule list.
