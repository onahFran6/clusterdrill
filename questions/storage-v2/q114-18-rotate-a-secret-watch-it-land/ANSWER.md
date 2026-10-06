# q114-18: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#mounted-secrets-are-updated-automatically

```sh
NS=q114-18-rotate-a-secret-watch-it-land

kubectl rollout status deployment/api -n "$NS" --timeout=60s

kubectl create secret generic api-token -n "$NS" --from-literal=value=v2 \
  --dry-run=client -o yaml | kubectl apply -f -

sleep 15
kubectl exec deploy/api -n "$NS" -- tail -n 1 /audit/log   # env=v1 file=v2 (not graded - pre-restart)

kubectl rollout restart deployment/api -n "$NS"
kubectl rollout status deployment/api -n "$NS" --timeout=60s
sleep 6
kubectl exec deploy/api -n "$NS" -- tail -n 1 /audit/log   # env=v2 file=v2
kubectl exec deploy/api -n "$NS" -- wc -l /audit/log
```

A mounted Secret file is refreshed by the kubelet within about a minute, unless mounted with
`subPath`. An env var is fixed the moment the container starts, so it only catches up after the
restart. The claim is what keeps the audit trail intact across that restart - on an `emptyDir` it
would have been lost with the old pod.
