# q102-02: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl apply -n q102-02-init-container-wait-for-service -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    clusterdrill-question: q102-02-init-container-wait-for-service
spec:
  initContainers:
    - name: wait-for-db
      image: busybox:1.36
      command: ["sh", "-c", "until nslookup user-db; do sleep 2; done"]
  containers:
    - name: main
      image: nginx:1.27-alpine
EOF
```
