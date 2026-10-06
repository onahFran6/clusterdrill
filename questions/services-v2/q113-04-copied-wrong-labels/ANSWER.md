# q113-04-copied-wrong-labels: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
QUESTION_ID=q113-04-copied-wrong-labels

kubectl get endpointslices -n "$QUESTION_ID" -l kubernetes.io/service-name=ledger-svc   # 0 addresses
kubectl get pods -n "$QUESTION_ID" --show-labels                                        # app=ledger-api,tier=backend

kubectl set selector service ledger-svc -n "$QUESTION_ID" 'app=ledger-api,tier=backend'
kubectl patch service ledger-svc -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'

sleep 3   # endpoints need a moment to populate after the selector fix
kubectl run tmp-q113-04-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  wget -qO- -T 3 ledger-svc
```

A Service matches **pod** labels, which come from the Deployment's `spec.template.metadata.labels`
- its own top-level `metadata.labels` never reach the pods, so copying from there produced a
selector that matched nothing. After fixing only the selector you would get endpoints but
`connection refused`, which is what points at the port being wrong too: the container listens on
80, not the 8080 the Service originally forwarded to.
