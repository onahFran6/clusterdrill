# q106-14: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl get pod legacy-worker -n q106-14-block-privilege-escalation -o json \
  | jq '.spec.containers[0].securityContext.allowPrivilegeEscalation = false' \
  | kubectl replace --force -f -

kubectl wait --for=condition=Ready pod/legacy-worker -n q106-14-block-privilege-escalation --timeout=60s
```
