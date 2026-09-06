# q102-27: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

```sh
kubectl delete pod gated-app -n q102-27-native-sidecar-startupprobe-gates-main --ignore-not-found

kubectl apply -n q102-27-native-sidecar-startupprobe-gates-main -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gated-app
  labels:
    clusterdrill-question: q102-27-native-sidecar-startupprobe-gates-main
spec:
  initContainers:
    - name: cache-warmer
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /var/run/warmer; sleep 3; touch /var/run/warmer/ready; while true; do sleep 30; done"]
      restartPolicy: Always
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /var/run/warmer/ready"]
        periodSeconds: 2
        failureThreshold: 10
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: web
      image: nginx:1.27-alpine
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Running \
  pod/gated-app -n q102-27-native-sidecar-startupprobe-gates-main --timeout=90s
```
