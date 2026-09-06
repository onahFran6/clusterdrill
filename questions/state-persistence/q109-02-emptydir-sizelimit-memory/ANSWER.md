# q109-02: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
NS=q109-02-emptydir-sizelimit-memory

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: cache
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: fast-cache
          mountPath: /cache
  volumes:
    - name: fast-cache
      emptyDir:
        medium: Memory
        sizeLimit: 64Mi
EOF

kubectl wait --for=condition=Ready pod/cache-pod -n "$NS" --timeout=60s
```
