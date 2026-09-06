# q102-49: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/

```sh
kubectl delete pod crashy-worker -n q102-49-termination-message-policy-hides-crash-reason --ignore-not-found --wait=true

kubectl apply -n q102-49-termination-message-policy-hides-crash-reason -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: crashy-worker
  labels:
    clusterdrill-question: q102-49-termination-message-policy-hides-crash-reason
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "echo 'FATAL: config file missing at /etc/app/config.yaml'; sleep 2; exit 1"]
      terminationMessagePolicy: FallbackToLogsOnError
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
