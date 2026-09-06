# q105-44-limitrange-ephemeral-storage: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
kubectl apply -n q105-44-limitrange-ephemeral-storage -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: storage-limits
  labels:
    clusterdrill-question: q105-44-limitrange-ephemeral-storage
spec:
  limits:
    - type: Container
      default:
        ephemeral-storage: "500Mi"
      defaultRequest:
        ephemeral-storage: "100Mi"
      min:
        ephemeral-storage: "50Mi"
      max:
        ephemeral-storage: "1Gi"
EOF

kubectl apply -n q105-44-limitrange-ephemeral-storage -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: scratch-worker
  labels:
    app: scratch-worker
    clusterdrill-question: q105-44-limitrange-ephemeral-storage
spec:
  containers:
    - name: scratch-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/scratch-worker -n q105-44-limitrange-ephemeral-storage --timeout=60s
```
