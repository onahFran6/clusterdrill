# q109-17: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/

```sh
NS=q109-17-downwardapi-volume-pod-metadata

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: self-aware
  labels:
    app: self-aware
    tier: frontend
    clusterdrill-question: $NS
spec:
  containers:
    - name: self-aware
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
  volumes:
    - name: podinfo
      downwardAPI:
        items:
          - path: "podname"
            fieldRef:
              fieldPath: metadata.name
          - path: "labels"
            fieldRef:
              fieldPath: metadata.labels
EOF

kubectl wait --for=condition=Ready pod/self-aware -n "$NS" --timeout=60s
```
