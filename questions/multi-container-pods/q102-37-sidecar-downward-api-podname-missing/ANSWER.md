# q102-37: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/

```sh
kubectl delete pod tagged-shipper -n q102-37-sidecar-downward-api-podname-missing --ignore-not-found --wait=true

kubectl apply -n q102-37-sidecar-downward-api-podname-missing -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: tagged-shipper
  labels:
    clusterdrill-question: q102-37-sidecar-downward-api-podname-missing
spec:
  containers:
    - name: app
      image: busybox:1.36
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      command: ["sh", "-c", "mkdir -p /logs; echo \"\$POD_NAME: request handled\" >> /logs/app.log; while true; do sleep 3600; done"]
      volumeMounts:
        - name: logs
          mountPath: /logs
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: shipper
      image: busybox:1.36
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      command: ["sh", "-c", "i=0; while [ \$i -lt 60 ]; do if [ -f /logs/app.log ]; then echo \"[\${POD_NAME:-unknown-pod}] \$(cat /logs/app.log)\" > /logs/shipped.log; fi; i=\$((i+1)); sleep 3; done; while true; do sleep 3600; done"]
      volumeMounts:
        - name: logs
          mountPath: /logs
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: logs
      emptyDir: {}
EOF
```
