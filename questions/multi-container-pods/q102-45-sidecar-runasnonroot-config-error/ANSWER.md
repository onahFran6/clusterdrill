# q102-45: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl delete pod hardened-app -n q102-45-sidecar-runasnonroot-config-error --ignore-not-found --wait=true

kubectl apply -n q102-45-sidecar-runasnonroot-config-error -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hardened-app
  labels:
    clusterdrill-question: q102-45-sidecar-runasnonroot-config-error
spec:
  securityContext:
    runAsNonRoot: true
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      securityContext:
        runAsUser: 1000
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
      securityContext:
        runAsUser: 1000
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
