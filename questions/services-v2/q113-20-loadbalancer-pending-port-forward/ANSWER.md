# q113-20-loadbalancer-pending-port-forward: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer

```sh
QUESTION_ID=q113-20-loadbalancer-pending-port-forward

kubectl patch service gate -n "$QUESTION_ID" -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get service gate -n "$QUESTION_ID"   # EXTERNAL-IP stays <pending> - no LB provider here

# (ungraded, demonstrated here the same way the candidate would do it themselves)
kubectl port-forward service/gate -n "$QUESTION_ID" 8080:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 2
curl -s localhost:8080 | grep '<title>'
kill "$PF_PID"
```

A pending LoadBalancer still works as a NodePort and as a ClusterIP underneath it - that's the
graded part, and it's real regardless of whether any cloud ever provisions the top layer.
`kubectl port-forward service/...` picks one pod behind the Service and tunnels straight to it
through the API server and kubelet, bypassing the Service's own load balancing entirely - useful
for confirming the app itself works, but not a substitute for testing the Service's routing, and
never a way to verify a NetworkPolicy's effect.
