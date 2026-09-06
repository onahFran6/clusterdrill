# q108-14: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
kubectl apply -n q108-14-networkpolicy-allow-ingress-from-pods -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payments-api-allow-frontend
spec:
  podSelector:
    matchLabels:
      app: payments-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web-frontend
      ports:
        - protocol: TCP
          port: 8080
EOF
```
