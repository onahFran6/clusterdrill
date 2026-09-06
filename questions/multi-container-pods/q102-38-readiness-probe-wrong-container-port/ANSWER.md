# q102-38: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

```sh
kubectl delete pod probe-mixup -n q102-38-readiness-probe-wrong-container-port --ignore-not-found --wait=true

kubectl apply -n q102-38-readiness-probe-wrong-container-port -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: probe-mixup
  labels:
    clusterdrill-question: q102-38-readiness-probe-wrong-container-port
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
      readinessProbe:
        tcpSocket:
          port: 80
        periodSeconds: 3
        failureThreshold: 2
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar-metrics
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
