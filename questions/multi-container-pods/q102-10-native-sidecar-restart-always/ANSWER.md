# q102-10: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

```sh
kubectl apply -n q102-10-native-sidecar-restart-always -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: native-sidecar-app
  labels:
    clusterdrill-question: q102-10-native-sidecar-restart-always
spec:
  initContainers:
    - name: sidecar-log-agent
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo agent running; sleep 5; done"]
      restartPolicy: Always
  containers:
    - name: main
      image: nginx:1.27-alpine
EOF
```
