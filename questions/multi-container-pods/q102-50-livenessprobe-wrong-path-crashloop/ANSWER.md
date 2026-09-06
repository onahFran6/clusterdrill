# q102-50: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/

```sh
kubectl delete pod false-alarm-app -n q102-50-livenessprobe-wrong-path-crashloop --ignore-not-found --wait=true

kubectl apply -n q102-50-livenessprobe-wrong-path-crashloop -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: false-alarm-app
  labels:
    clusterdrill-question: q102-50-livenessprobe-wrong-path-crashloop
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do touch /tmp/healthy; sleep 2; done"]
      livenessProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/healthy"]
        periodSeconds: 3
        failureThreshold: 1
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar
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
