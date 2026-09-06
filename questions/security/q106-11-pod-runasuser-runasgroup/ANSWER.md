# q106-11: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-11-pod-runasuser-runasgroup -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
```
