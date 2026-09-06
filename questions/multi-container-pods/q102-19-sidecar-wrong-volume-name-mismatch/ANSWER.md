# q102-19: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/

```sh
kubectl delete pod metrics-pair -n q102-19-sidecar-wrong-volume-name-mismatch --ignore-not-found --wait=true

kubectl apply -n q102-19-sidecar-wrong-volume-name-mismatch -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metrics-pair
  labels:
    clusterdrill-question: q102-19-sidecar-wrong-volume-name-mismatch
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo metric >> /var/writer/metrics.log; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /var/writer
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "tail -f /var/sidecar/metrics.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /var/sidecar
  volumes:
    - name: shared-data
      emptyDir: {}
EOF
```
