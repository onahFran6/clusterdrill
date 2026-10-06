# q113-08-cross-namespace-dns: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#services

```sh
QUESTION_ID=q113-08-cross-namespace-dns

kubectl logs deploy/frontend -n "$QUESTION_ID" --tail=2        # ... call failed
kubectl exec deploy/frontend -n "$QUESTION_ID" -- cat /etc/resolv.conf  # search <namespace>.svc.cluster.local ...

kubectl set env deployment/frontend -n "$QUESTION_ID" \
  BACKEND_URL="http://backend.$QUESTION_ID.svc.cluster.local:80"
kubectl rollout status deployment/frontend -n "$QUESTION_ID"
sleep 10
kubectl logs deployment/frontend -n "$QUESTION_ID" --tail=1     # backend says hi
```

A Service's DNS name is only ever qualified by the namespace it actually lives in - the seeded
value named a namespace (`pollux`) that doesn't exist here, which fails exactly like any other
nonexistent name. The bare name `backend` (resolving in the pod's own namespace, via its
`resolv.conf` search list) would work too; the full `backend.$QUESTION_ID.svc.cluster.local` form
is never ambiguous, which is the safer habit across namespaces. NetworkPolicies, not DNS, are what
actually block traffic between namespaces when that's the real intent.
