# q109-14: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
NS=q109-14-emptydir-shared-sidecar-writer-reader

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: relay
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "echo hello > /data/msg.txt && sleep 3600"]
      volumeMounts:
        - name: shared-data
          mountPath: /data
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: shared-data
          mountPath: /data
  volumes:
    - name: shared-data
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/relay -n "$NS" --timeout=60s
```
