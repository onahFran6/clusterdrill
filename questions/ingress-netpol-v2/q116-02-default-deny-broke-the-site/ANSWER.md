# q116-02-default-deny-broke-the-site: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/

```sh
QUESTION_ID="q116-02-default-deny-broke-the-site"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
spec:
  podSelector:
    matchLabels:
      app: site
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - protocol: TCP
          port: 5678
EOF
```
