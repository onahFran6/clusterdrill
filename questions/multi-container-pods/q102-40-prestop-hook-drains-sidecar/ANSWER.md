# q102-40: reference solution

Doc: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/

```sh
kubectl delete pod batching-shipper -n q102-40-prestop-hook-drains-sidecar --ignore-not-found --wait=true

kubectl apply -n q102-40-prestop-hook-drains-sidecar -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batching-shipper
  labels:
    clusterdrill-question: q102-40-prestop-hook-drains-sidecar
spec:
  terminationGracePeriodSeconds: 20
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
    - name: log-shipper
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; touch /data/buffer.log; while true; do sleep 30; cat /data/buffer.log >> /data/shipped.log; > /data/buffer.log; done"]
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "cat /data/buffer.log >> /data/shipped.log"]
      volumeMounts:
        - name: data
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: data
      emptyDir: {}
EOF
```
