# q102-06: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl apply -n q102-06-init-container-file-handoff -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-app
  labels:
    clusterdrill-question: q102-06-init-container-file-handoff
spec:
  initContainers:
    - name: generate-config
      image: busybox:1.36
      command: ["sh", "-c", "echo mode=production > /config/app.conf"]
      volumeMounts:
        - name: config-vol
          mountPath: /config
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "cat /config/app.conf && sleep 3600"]
      volumeMounts:
        - name: config-vol
          mountPath: /config
  volumes:
    - name: config-vol
      emptyDir: {}
EOF
```
