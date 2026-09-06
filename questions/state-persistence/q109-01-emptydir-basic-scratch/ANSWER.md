# q109-01: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
NS=q109-01-emptydir-basic-scratch

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: render-worker
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: scratch
          mountPath: /var/scratch
  volumes:
    - name: scratch
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/render-worker -n "$NS" --timeout=60s
```
