# q106-13: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-13-readonly-root-filesystem -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: immutable-app
spec:
  containers:
    - name: immutable-app
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        readOnlyRootFilesystem: true
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      emptyDir: {}
EOF
```
