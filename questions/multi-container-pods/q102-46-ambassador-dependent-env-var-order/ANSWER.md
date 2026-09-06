# q102-46: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-dependent-environment-variable/

```sh
kubectl delete pod ambassador-target -n q102-46-ambassador-dependent-env-var-order --ignore-not-found --wait=true

kubectl apply -n q102-46-ambassador-dependent-env-var-order -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-target
  labels:
    clusterdrill-question: q102-46-ambassador-dependent-env-var-order
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
      command: ["sh", "-c", "mkdir -p /report; echo \"$TARGET_ADDR\" > /report/target.txt; while true; do sleep 3600; done"]
      env:
        - name: BACKEND_HOST
          value: primary-api
        - name: BACKEND_PORT
          value: "9090"
        - name: TARGET_ADDR
          value: "$(BACKEND_HOST):$(BACKEND_PORT)"
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
