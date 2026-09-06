# q101-13: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_cronjob/

```sh
kubectl create cronjob heartbeat \
  --image=busybox:1.36 \
  --schedule="*/5 * * * *" \
  -n q101-13-create-cronjob-imperative \
  -- echo heartbeat
```
