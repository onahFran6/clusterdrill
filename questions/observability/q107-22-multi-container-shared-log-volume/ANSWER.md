# q107-22: reference solution

Doc: https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/

```sh
# Investigate (read-only, informational):
#   kubectl logs audit-logger -n q107-22-multi-container-shared-log-volume -c shipper --previous

# A container's command is immutable on a running Pod, so fix it by
# deleting and recreating the pod with the corrected 'shipper' command -
# the 'writer' container and both volume mounts are left untouched.
kubectl delete pod audit-logger -n q107-22-multi-container-shared-log-volume --wait=true

kubectl apply -n q107-22-multi-container-shared-log-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: audit-logger
  labels:
    clusterdrill-question: q107-22-multi-container-shared-log-volume
spec:
  volumes:
    - name: logs
      emptyDir: {}
  containers:
    - name: writer
      image: busybox:1.36
      command:
        - sh
        - -c
        - "while true; do date >> /var/log/app/audit.log; sleep 2; done"
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
    - name: shipper
      image: busybox:1.36
      command:
        - sh
        - -c
        - "tail -f /logs/audit.log"
      volumeMounts:
        - name: logs
          mountPath: /logs
EOF

kubectl wait --for=condition=Ready pod/audit-logger -n q107-22-multi-container-shared-log-volume --timeout=120s
```
