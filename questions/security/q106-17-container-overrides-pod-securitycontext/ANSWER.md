# q106-17: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-17-container-overrides-pod-securitycontext -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: mixed-uid
spec:
  securityContext:
    runAsUser: 1000
  containers:
    - name: standard
      image: busybox:1.36
      command: ["sleep", "3600"]
    - name: special
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        runAsUser: 2000
EOF
```
