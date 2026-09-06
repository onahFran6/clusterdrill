# q106-21-drop-all-capabilities-explicit: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl get pod audit-agent -n q106-21-drop-all-capabilities-explicit -o json \
  | jq '.spec.containers[0].securityContext.capabilities.drop = ["ALL"]' \
  | kubectl replace --force -f -

kubectl wait --for=condition=Ready pod/audit-agent -n q106-21-drop-all-capabilities-explicit --timeout=60s
```
