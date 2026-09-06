# q102-21-sidecar-missing-shared-mountpath: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod audit-logger -n q102-21-sidecar-missing-shared-mountpath --ignore-not-found --wait=true

kubectl apply -n q102-21-sidecar-missing-shared-mountpath -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: audit-logger
  labels:
    clusterdrill-question: q102-21-sidecar-missing-shared-mountpath
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \$(date -u) audit event >> /var/log/audit/app.log; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: audit-vol
          mountPath: /var/log/audit
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "while true; do if [ -f /var/log/audit/app.log ]; then tail -f /var/log/audit/app.log; else echo waiting for file; sleep 5; fi; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: audit-vol
          mountPath: /var/log/audit
  volumes:
    - name: audit-vol
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/audit-logger -n q102-21-sidecar-missing-shared-mountpath --timeout=60s
```
