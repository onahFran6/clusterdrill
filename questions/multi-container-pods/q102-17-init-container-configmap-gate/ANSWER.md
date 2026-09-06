# q102-17: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables

```sh
kubectl apply -n q102-17-init-container-configmap-gate -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    clusterdrill-question: q102-17-init-container-configmap-gate
data:
  APP_MODE: production
EOF

kubectl apply -n q102-17-init-container-configmap-gate -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: configmap-gated-app
  labels:
    clusterdrill-question: q102-17-init-container-configmap-gate
spec:
  initContainers:
    - name: wait-for-config
      image: busybox:1.36
      command: ["sh", "-c", "echo config check ok"]
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      envFrom:
        - configMapRef:
            name: app-config
EOF
```
