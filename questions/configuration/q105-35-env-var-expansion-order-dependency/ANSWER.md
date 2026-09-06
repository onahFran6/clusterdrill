# q105-35-env-var-expansion-order-dependency: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/

```sh
kubectl delete pod path-builder -n q105-35-env-var-expansion-order-dependency

kubectl apply -n q105-35-env-var-expansion-order-dependency -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: path-builder
  labels:
    app: path-builder
spec:
  containers:
    - name: builder
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      env:
        - name: BASE_DIR
          value: "/data"
        - name: REGION
          valueFrom:
            configMapKeyRef:
              name: region-config
              key: REGION
        - name: ARCHIVE_PATH
          value: "\$(BASE_DIR)/\$(REGION)/archive"
        - name: FINAL_PATH
          value: "\$(ARCHIVE_PATH)/current"
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/path-builder -n q105-35-env-var-expansion-order-dependency --timeout=60s
```
