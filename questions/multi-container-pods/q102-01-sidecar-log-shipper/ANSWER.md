# q102-01: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod writer-app -n q102-01-sidecar-log-shipper --ignore-not-found --wait=true

kubectl apply -n q102-01-sidecar-log-shipper -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: writer-app
  labels:
    clusterdrill-question: q102-01-sidecar-log-shipper
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \$(date -u) hello from writer >> /var/log/app/output.log; sleep 5; done"]
      volumeMounts:
        - name: log-data
          mountPath: /var/log/app
    - name: log-shipper
      image: busybox:1.36
      command: ["sh", "-c", "tail -f /var/log/app/output.log"]
      volumeMounts:
        - name: log-data
          mountPath: /var/log/app
          readOnly: true
  volumes:
    - name: log-data
      emptyDir: {}
EOF
```
