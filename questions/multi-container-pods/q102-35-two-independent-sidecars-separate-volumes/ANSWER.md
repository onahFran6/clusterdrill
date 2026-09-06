# q102-35: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
kubectl apply -n q102-35-two-independent-sidecars-separate-volumes -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: scratch-pad
  labels:
    clusterdrill-question: q102-35-two-independent-sidecars-separate-volumes
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
    - name: cache-a
      image: busybox:1.36
      command: ["sh", "-c", "echo cache-a > /cache/owner.txt; while true; do sleep 3600; done"]
      volumeMounts:
        - name: cache-a-data
          mountPath: /cache
    - name: cache-b
      image: busybox:1.36
      command: ["sh", "-c", "echo cache-b > /cache/owner.txt; while true; do sleep 3600; done"]
      volumeMounts:
        - name: cache-b-data
          mountPath: /cache
  volumes:
    - name: cache-a-data
      emptyDir: {}
    - name: cache-b-data
      emptyDir: {}
EOF
```
