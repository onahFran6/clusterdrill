# q102-07: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl apply -n q102-07-localhost-networking-multi-container -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-with-healthcheck
  labels:
    clusterdrill-question: q102-07-localhost-networking-multi-container
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
    - name: healthchecker
      image: busybox:1.36
      command: ["sh", "-c", "while true; do wget -q -O- http://localhost:80 || true; sleep 5; done"]
EOF
```
