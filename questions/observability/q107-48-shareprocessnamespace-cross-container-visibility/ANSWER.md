# q107-48-shareprocessnamespace-cross-container-visibility: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

`shareProcessNamespace` is set at Pod creation time and cannot be patched onto a running Pod -
delete and recreate it.

```sh
kubectl delete pod monitored-app -n q107-48-shareprocessnamespace-cross-container-visibility --wait=true

kubectl apply -n q107-48-shareprocessnamespace-cross-container-visibility -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: monitored-app
  labels:
    app: monitored-app
spec:
  shareProcessNamespace: true
  containers:
    - name: main-app
      image: busybox:1.36
      command: ["sh", "-c", "exec sleep 424242"]
    - name: watchdog
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/monitored-app -n q107-48-shareprocessnamespace-cross-container-visibility --timeout=60s

kubectl exec monitored-app -n q107-48-shareprocessnamespace-cross-container-visibility -c watchdog -- ps
```
