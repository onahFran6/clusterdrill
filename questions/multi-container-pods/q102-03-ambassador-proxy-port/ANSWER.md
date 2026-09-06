# q102-03: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl apply -n q102-03-ambassador-proxy-port -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ambassador
  labels:
    clusterdrill-question: q102-03-ambassador-proxy-port
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do wget -q -T 2 -O - localhost:6380 || true; sleep 5; done"]
    - name: ambassador
      image: alpine:3.20
      command: ["sh", "-c", "apk add --no-cache socat && socat TCP-LISTEN:6380,fork TCP:redis-external:6379"]
EOF
```
