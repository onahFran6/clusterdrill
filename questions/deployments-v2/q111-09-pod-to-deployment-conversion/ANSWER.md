# q111-09: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl create serviceaccount holy-sa -n q111-09-pod-to-deployment-conversion

cat <<'EOF' | kubectl apply -n q111-09-pod-to-deployment-conversion -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holy-api
  labels:
    clusterdrill-question: q111-09-pod-to-deployment-conversion
spec:
  replicas: 3
  selector:
    matchLabels:
      id: holy-api
  template:
    metadata:
      labels:
        id: holy-api
        clusterdrill-question: q111-09-pod-to-deployment-conversion
    spec:
      serviceAccountName: holy-sa
      containers:
        - name: holy-api
          image: busybox:1.36
          command: ["sh", "-c", "while true; do date; sleep 10; done"]
          env:
            - name: CACHE_KEY
              value: prod-cache
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
EOF

kubectl delete pod holy-api -n q111-09-pod-to-deployment-conversion --force --grace-period=0
kubectl rollout status deployment/holy-api -n q111-09-pod-to-deployment-conversion --timeout=60s
```

`holy-sa` must exist *before* the Deployment, or the ReplicaSet's admission check on
`serviceAccountName` rejects every pod it tries to create. `allowPrivilegeEscalation` and
`privileged` exist only at the container level, never in the pod-level `securityContext`.
Deleting the original bare Pod doesn't touch the Deployment's own pods - its ReplicaSet only ever
owns pods carrying its own `pod-template-hash` label, never the hand-created one.
