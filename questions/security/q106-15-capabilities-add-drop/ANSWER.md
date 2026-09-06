# q106-15: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-15-capabilities-add-drop -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: net-tool
spec:
  containers:
    - name: net-tool
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        capabilities:
          drop: ["ALL"]
          add: ["NET_BIND_SERVICE"]
EOF
```
