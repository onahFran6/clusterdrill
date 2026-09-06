# q105-49-downwardapi-volume-podinfo: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/#store-pod-fields

```sh
kubectl apply -n q105-49-downwardapi-volume-podinfo -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metadata-exporter
  labels:
    role: exporter
    tier: backend
    clusterdrill-question: q105-49-downwardapi-volume-podinfo
  annotations:
    build.info/version: "3.2.1"
spec:
  containers:
    - name: metadata-exporter
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
  volumes:
    - name: podinfo
      downwardAPI:
        items:
          - path: "pod-name"
            fieldRef:
              fieldPath: metadata.name
          - path: "labels"
            fieldRef:
              fieldPath: metadata.labels
          - path: "annotations"
            fieldRef:
              fieldPath: metadata.annotations
EOF

kubectl wait --for=condition=Ready pod/metadata-exporter -n q105-49-downwardapi-volume-podinfo --timeout=60s
```
