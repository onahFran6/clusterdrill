# q106-40-serviceaccount-automount-pod-override-true: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting

```sh
kubectl apply -n q106-40-serviceaccount-automount-pod-override-true -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: token-client
  labels:
    app: token-client
spec:
  serviceAccountName: token-needer
  automountServiceAccountToken: true
  containers:
    - name: token-client
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/token-client -n q106-40-serviceaccount-automount-pod-override-true --timeout=60s
```
