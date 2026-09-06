# q102-13: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl apply -n q102-13-init-container-migration-gate -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: migrated-app
  labels:
    clusterdrill-question: q102-13-init-container-migration-gate
spec:
  initContainers:
    - name: run-migration
      image: busybox:1.36
      command: ["sh", "-c", "echo migrated > /status/migration.done"]
      volumeMounts:
        - name: status-vol
          mountPath: /status
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "cat /status/migration.done && sleep 3600"]
      volumeMounts:
        - name: status-vol
          mountPath: /status
  volumes:
    - name: status-vol
      emptyDir: {}
EOF
```
