# q113-06-externalname-points-outside: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#externalname

```sh
QUESTION_ID=q113-06-externalname-points-outside

kubectl create service externalname payments -n "$QUESTION_ID" --external-name=example.com

kubectl run tmp-q113-06-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  nslookup "payments.$QUESTION_ID.svc.cluster.local"
```

An ExternalName Service returns a CNAME record and nothing else - it has no selector, no
endpoints, and no port mapping. HTTPS through it can still fail on certificate checks, because the
client asked for `payments` while the server's own certificate names `example.com`. When payments
eventually moves in-cluster, this gets replaced by a normal Service of the same name - callers
never need to change.
