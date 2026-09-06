# q102-48: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

```sh
kubectl delete pod chained-sidecars-app -n q102-48-chained-native-sidecars-startup-order --ignore-not-found --wait=true

kubectl apply -n q102-48-chained-native-sidecars-startup-order -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: chained-sidecars-app
  labels:
    clusterdrill-question: q102-48-chained-native-sidecars-startup-order
spec:
  initContainers:
    - name: cache-warmer
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "sleep 3; mkdir -p /run/warm; touch /run/warm/ready; while true; do sleep 3600; done"]
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /run/warm/ready"]
        periodSeconds: 2
        failureThreshold: 5
      volumeMounts:
        - name: warm-signal
          mountPath: /run/warm
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: index-builder
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /run/warm/ready"]
        periodSeconds: 2
        failureThreshold: 5
      volumeMounts:
        - name: warm-signal
          mountPath: /run/warm
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
  volumes:
    - name: warm-signal
      emptyDir: {}
EOF
```
