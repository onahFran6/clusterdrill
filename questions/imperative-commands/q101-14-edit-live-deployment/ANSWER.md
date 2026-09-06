# q101-14: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_edit/

`kubectl edit` opens an interactive editor, so the non-interactive equivalent below (`kubectl
patch`) is what `kubectl edit` sends to the API server on save - same live-object-mutation effect
the task asks for.

```sh
kubectl patch deployment live-edit -n q101-14-edit-live-deployment \
  --type=merge -p '{"spec":{"replicas":4}}'

kubectl rollout status deployment/live-edit -n q101-14-edit-live-deployment --timeout=60s
```
