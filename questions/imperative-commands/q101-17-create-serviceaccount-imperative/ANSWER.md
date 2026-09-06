# q101-17: reference solution

Doc: https://kubernetes.io/docs/concepts/security/service-accounts/

```sh
kubectl create serviceaccount deploy-bot -n q101-17-create-serviceaccount-imperative

kubectl run bot-runner --image=busybox:1.36 \
  -n q101-17-create-serviceaccount-imperative \
  --overrides='{"spec":{"serviceAccountName":"deploy-bot"}}' \
  -- sleep 3600
```
