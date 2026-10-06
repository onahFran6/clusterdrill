# q113-16-egress-without-breaking-dns: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#targeting-a-range-of-ports

```sh
QUESTION_ID=q113-16-egress-without-breaking-dns

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-egress
spec:
  podSelector:
    matchLabels: { app: backend }
  policyTypes: ["Egress"]
  egress:
    - to:
        - podSelector:
            matchLabels: { app: db }
      ports:
        - { protocol: TCP, port: 5432 }
    - to:
        - namespaceSelector:
            matchLabels: { kubernetes.io/metadata.name: kube-system }
          podSelector:
            matchLabels: { k8s-app: kube-dns }
      ports:
        - { protocol: UDP, port: 53 }
        - { protocol: TCP, port: 53 }
EOF
```

Without the second rule, every DNS lookup would fail, so even `db-svc` would look "down" though
port 5432 is actually allowed - the Service name never resolves to try it. Egress rules match the
**pod** behind a Service, since by the time a policy is evaluated, a Service IP has already been
DNAT'd to a real pod IP. The DNS rule's single `to` entry combines `namespaceSelector` and
`podSelector` on the *same* peer (AND, not two separate list items), matching exactly one set of
pods: the DNS pods, in the `kube-system` namespace. Confirm the actual label your cluster's DNS
pods carry with `kubectl -n kube-system get pods --show-labels` - `k8s-app: kube-dns` is
overwhelmingly common but not guaranteed on every distribution.
