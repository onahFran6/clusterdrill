# q101-45-fix-imagepullbackoff-wrong-tag: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

```sh
kubectl describe pod/worker-app -n q101-45-fix-imagepullbackoff-wrong-tag
kubectl get events -n q101-45-fix-imagepullbackoff-wrong-tag --sort-by='.lastTimestamp'

kubectl delete pod worker-app -n q101-45-fix-imagepullbackoff-wrong-tag

kubectl apply -n q101-45-fix-imagepullbackoff-wrong-tag -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker-app
  labels:
    app: worker-app
spec:
  serviceAccountName: ci-deploy
  containers:
    - name: worker-app
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/worker-app \
  -n q101-45-fix-imagepullbackoff-wrong-tag --timeout=60s
```
