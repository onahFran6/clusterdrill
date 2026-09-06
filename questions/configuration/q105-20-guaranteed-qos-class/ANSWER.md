# q105-20: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/

```sh
kubectl delete pod critical-job -n q105-20-guaranteed-qos-class

kubectl apply -n q105-20-guaranteed-qos-class -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: critical-job
  labels:
    app: critical-job
spec:
  containers:
    - name: critical-job
      image: nginx:1.25-alpine
      resources:
        requests:
          cpu: "300m"
          memory: "256Mi"
        limits:
          cpu: "300m"
          memory: "256Mi"
EOF

kubectl wait --for=condition=Ready pod/critical-job -n q105-20-guaranteed-qos-class --timeout=60s
```
