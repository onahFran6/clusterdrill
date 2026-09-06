# q102-09: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

```sh
kubectl apply -n q102-09-shared-process-namespace-debug -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: debuggable-app
  labels:
    clusterdrill-question: q102-09-shared-process-namespace-debug
spec:
  shareProcessNamespace: true
  containers:
    - name: main
      image: nginx:1.27-alpine
    - name: debugger
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF
```
