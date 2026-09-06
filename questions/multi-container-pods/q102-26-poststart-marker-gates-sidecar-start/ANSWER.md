# q102-26-poststart-marker-gates-sidecar-start: reference solution

Doc: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/

```sh
kubectl delete pod staged-app -n q102-26-poststart-marker-gates-sidecar-start --ignore-not-found --wait=true

kubectl apply -n q102-26-poststart-marker-gates-sidecar-start -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: staged-app
  labels:
    clusterdrill-question: q102-26-poststart-marker-gates-sidecar-start
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "touch /shared/app.log; while true; do echo \"\$(date -u) app heartbeat\" >> /shared/app.log; sleep 5; done"]
      lifecycle:
        postStart:
          exec:
            command: ["sh", "-c", "sleep 2 && echo ready > /shared/ready"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared
          mountPath: /shared
    - name: log-tailer
      image: busybox:1.36
      command: ["sh", "-c", "until [ -f /shared/ready ]; do sleep 2; done; touch /shared/log-tailer-active; tail -f /shared/app.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared
          mountPath: /shared
  volumes:
    - name: shared
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/staged-app -n q102-26-poststart-marker-gates-sidecar-start --timeout=60s
```
