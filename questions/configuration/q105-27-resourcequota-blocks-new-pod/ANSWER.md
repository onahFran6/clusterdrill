# q105-27-resourcequota-blocks-new-pod: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits

```sh
kubectl apply -n q105-27-resourcequota-blocks-new-pod -f ~/sidecar-job.yaml
kubectl get replicaset -n q105-27-resourcequota-blocks-new-pod -l app=sidecar-job
kubectl describe replicaset -n q105-27-resourcequota-blocks-new-pod -l app=sidecar-job

cat > ~/sidecar-job.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidecar-job
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidecar-job
  template:
    metadata:
      labels:
        app: sidecar-job
    spec:
      containers:
        - name: sidecar-job
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: "100m"
              memory: "112Mi"
            limits:
              cpu: "100m"
              memory: "112Mi"
EOF

kubectl apply -n q105-27-resourcequota-blocks-new-pod -f ~/sidecar-job.yaml
kubectl rollout status deployment/sidecar-job -n q105-27-resourcequota-blocks-new-pod --timeout=60s
```
