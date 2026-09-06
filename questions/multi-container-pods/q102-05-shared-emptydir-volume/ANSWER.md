# q102-05: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
kubectl apply -n q102-05-shared-emptydir-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: shared-vol-demo
  labels:
    clusterdrill-question: q102-05-shared-emptydir-volume
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo hello from producer >> /producer-data/message.txt; sleep 5; done"]
      volumeMounts:
        - name: shared
          mountPath: /producer-data
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "touch /consumer-data/message.txt; tail -f /consumer-data/message.txt"]
      volumeMounts:
        - name: shared
          mountPath: /consumer-data
  volumes:
    - name: shared
      emptyDir: {}
EOF
```
