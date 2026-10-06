# q113-19-service-down-three-faults: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/

```sh
QUESTION_ID=q113-19-service-down-three-faults

kubectl exec client -n "$QUESTION_ID" -- wget -qO- -T 3 orders-svc              # fails immediately
kubectl get endpointslices -n "$QUESTION_ID" -l kubernetes.io/service-name=orders-svc   # no endpoints
kubectl get pods -n "$QUESTION_ID" --show-labels                               # app=orders, not app=order

kubectl set selector service orders-svc -n "$QUESTION_ID" app=orders
kubectl patch service orders-svc -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'

kubectl exec client -n "$QUESTION_ID" -- wget -qO- -T 3 orders-svc              # download timed out

kubectl patch networkpolicy allow-client -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"app":"client"}}]'

sleep 3   # endpoints need a moment to settle after the selector/targetPort fix
kubectl exec client -n "$QUESTION_ID" -- wget -qO- -T 3 orders-svc              # nginx page
```

Three faults, one at each layer: the Service's selector (`app=order`, a typo for `app=orders`,
so there were no endpoints at all); the Service's `targetPort` (8080, when nginx actually
listens on 80, so endpoints existed but nothing answered); and the NetworkPolicy's `from`
selector (`role: client`, but the pod carries `app: client`, a different key entirely). On a
cluster that enforces NetworkPolicy, that third fault would show up as a timeout rather than a
refusal - a useful signal on its own, since "no endpoints" and "nothing listening" both fail
immediately, while a dropped packet waits for the connection to time out.
