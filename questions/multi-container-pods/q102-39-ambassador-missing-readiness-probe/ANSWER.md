# q102-39: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

```sh
kubectl delete pod ambassador-app -n q102-39-ambassador-missing-readiness-probe --ignore-not-found --wait=true

kubectl apply -n q102-39-ambassador-missing-readiness-probe -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-app
  labels:
    clusterdrill-question: q102-39-ambassador-missing-readiness-probe
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: ambassador
      image: busybox:1.36
      command: ["sh", "-c", "sleep 4; nc -lk -p 8080 -e true"]
      ports:
        - containerPort: 8080
      readinessProbe:
        tcpSocket:
          port: 8080
        periodSeconds: 3
        failureThreshold: 2
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
