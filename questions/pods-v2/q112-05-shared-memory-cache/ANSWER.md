# q112-05: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
NS=q112-05-shared-memory-cache

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: cache-pair
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: cache
      emptyDir:
        medium: Memory
        sizeLimit: 64Mi
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do date > /cache/now; sleep 2; done"]
      volumeMounts:
        - name: cache
          mountPath: /cache
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "while true; do cat /cache/now; sleep 5; done"]
      volumeMounts:
        - name: cache
          mountPath: /cache
EOF

kubectl wait --for=condition=Ready pod/cache-pair -n "$NS" --timeout=60s
```

`emptyDir.medium: Memory` backs the volume with `tmpfs` instead of the node's disk, and
`sizeLimit` caps it - files written there count against the container's memory limit, not disk
quota. Without `-c <name>`, `kubectl logs` on a multi-container Pod fails and lists the container
names instead.
