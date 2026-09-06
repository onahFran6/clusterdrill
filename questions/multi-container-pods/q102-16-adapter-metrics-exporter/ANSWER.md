# q102-16: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod metrics-app -n q102-16-adapter-metrics-exporter --ignore-not-found --wait=true

kubectl apply -n q102-16-adapter-metrics-exporter -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metrics-app
  labels:
    clusterdrill-question: q102-16-adapter-metrics-exporter
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo requests_total:42 > /metrics/raw.txt; sleep 5; done"]
      volumeMounts:
        - name: metrics-vol
          mountPath: /metrics
    - name: metrics-adapter
      image: busybox:1.36
      command: ["sh", "-c", "while true; do if [ -f /metrics/raw.txt ]; then sed 's/:/ /' /metrics/raw.txt >> /metrics/prometheus.txt; fi; sleep 5; done"]
      volumeMounts:
        - name: metrics-vol
          mountPath: /metrics
  volumes:
    - name: metrics-vol
      emptyDir: {}
EOF
```
