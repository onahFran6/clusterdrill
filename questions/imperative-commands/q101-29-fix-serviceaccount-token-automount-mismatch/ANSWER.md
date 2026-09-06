# q101-29-fix-serviceaccount-token-automount-mismatch: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting

```sh
kubectl delete pod introspector -n q101-29-fix-serviceaccount-token-automount-mismatch --ignore-not-found

kubectl run introspector \
  --image=bitnami/kubectl:latest \
  -n q101-29-fix-serviceaccount-token-automount-mismatch \
  --overrides='{"spec":{"serviceAccountName":"reader-sa","automountServiceAccountToken":true}}' \
  --command -- sleep 3600

kubectl wait --for=condition=Ready pod/introspector \
  -n q101-29-fix-serviceaccount-token-automount-mismatch --timeout=60s

kubectl exec introspector -n q101-29-fix-serviceaccount-token-automount-mismatch -- \
  kubectl auth can-i list pods
```
