# q102-47: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl delete pod hardened-lock-app -n q102-47-readonlyrootfs-sidecar-needs-scratch-volume --ignore-not-found --wait=true

kubectl apply -n q102-47-readonlyrootfs-sidecar-needs-scratch-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hardened-lock-app
  labels:
    clusterdrill-question: q102-47-readonlyrootfs-sidecar-needs-scratch-volume
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: lock-manager
      image: busybox:1.36
      securityContext:
        readOnlyRootFilesystem: true
      command: ["sh", "-c", "while true; do echo locked > /tmp/lock.txt 2>/dev/null || true; sleep 5; done"]
      volumeMounts:
        - name: scratch
          mountPath: /tmp
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: scratch
      emptyDir: {}
EOF
```
