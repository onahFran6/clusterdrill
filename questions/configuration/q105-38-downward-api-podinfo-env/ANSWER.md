# q105-38-downward-api-podinfo-env: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/#the-downward-api

```sh
kubectl apply -n q105-38-downward-api-podinfo-env -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: info-reporter
  labels:
    app: info-reporter
    clusterdrill-question: q105-38-downward-api-podinfo-env
spec:
  containers:
    - name: info-reporter
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: MY_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
EOF

kubectl wait --for=condition=Ready pod/info-reporter -n q105-38-downward-api-podinfo-env --timeout=60s
```
