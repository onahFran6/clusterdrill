# q105-25-configmap-command-line-args: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#define-a-command-and-arguments-when-you-create-a-pod

```sh
kubectl delete pod greeter -n q105-25-configmap-command-line-args

kubectl apply -n q105-25-configmap-command-line-args -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: greeter
  labels:
    app: greeter
spec:
  containers:
    - name: greeter
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args: ["echo $(GREETING) $(TARGET) && sleep 3600"]
      env:
        - name: GREETING
          valueFrom:
            configMapKeyRef:
              name: greeter-config
              key: GREETING
        - name: TARGET
          valueFrom:
            configMapKeyRef:
              name: greeter-config
              key: TARGET
EOF

kubectl wait --for=condition=Ready pod/greeter -n q105-25-configmap-command-line-args --timeout=60s
```
