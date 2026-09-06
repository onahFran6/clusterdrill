# q106-16: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-16-fsgroup-shared-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: shared-writer
spec:
  securityContext:
    fsGroup: 2000
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
    - name: reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      emptyDir: {}
EOF
```
