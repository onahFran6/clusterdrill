# q101-12: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_job/

```sh
kubectl create job hash-once \
  --image=busybox:1.36 \
  -n q101-12-create-job-imperative \
  -- sha256sum /etc/hostname

kubectl wait --for=condition=complete job/hash-once -n q101-12-create-job-imperative --timeout=60s
```
