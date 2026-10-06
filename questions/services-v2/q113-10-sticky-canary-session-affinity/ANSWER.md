# q113-10-sticky-canary-session-affinity: reference solution

Doc: https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity

```sh
QUESTION_ID=q113-10-sticky-canary-session-affinity

kubectl get endpointslices -n "$QUESTION_ID" -l kubernetes.io/service-name=whoami   # 5 addresses

kubectl patch service whoami -n "$QUESTION_ID" -p \
  '{"spec":{"sessionAffinity":"ClientIP","sessionAffinityConfig":{"clientIP":{"timeoutSeconds":600}}}}'

sleep 3
kubectl run tmp-q113-10-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  sh -c 'for i in $(seq 10); do wget -qO- whoami; done | sort -u | wc -l'
```

Before the patch, 10 requests from one client would usually hit several different pods, since
kube-proxy load-balances every connection independently. `ClientIP` affinity pins each client IP
to the one backend it first landed on for the life of the timeout, so the 80/20 stable/canary
split now applies per **client**, not per request - a client behind a shared NAT IP still sees
only one version for the whole session. New clients (a different source IP) still land fresh
according to the same 4:1 endpoint ratio.
