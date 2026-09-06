# q102-11: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl apply -n q102-11-init-container-permission-fix -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  labels:
    clusterdrill-question: q102-11-init-container-permission-fix
spec:
  initContainers:
    - name: fix-permissions
      image: busybox:1.36
      command: ["sh", "-c", "chown -R 1000:1000 /data && chmod -R 755 /data"]
      volumeMounts:
        - name: data-vol
          mountPath: /data
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "touch /data/test.txt && sleep 3600"]
      securityContext:
        runAsUser: 1000
      volumeMounts:
        - name: data-vol
          mountPath: /data
  volumes:
    - name: data-vol
      emptyDir: {}
EOF
```
