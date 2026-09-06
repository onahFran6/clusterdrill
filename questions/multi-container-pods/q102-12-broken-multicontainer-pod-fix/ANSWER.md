# q102-12: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/

```sh
kubectl delete pod broken-app -n q102-12-broken-multicontainer-pod-fix --ignore-not-found --wait=true

kubectl apply -n q102-12-broken-multicontainer-pod-fix -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
  labels:
    clusterdrill-question: q102-12-broken-multicontainer-pod-fix
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo hello >> /cache/data.txt; sleep 5; done"]
      volumeMounts:
        - name: cache-vol
          mountPath: /cache
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "tail -f /cache/data.txt"]
      volumeMounts:
        - name: cache-vol
          mountPath: /cache
  volumes:
    - name: cache-vol
      emptyDir: {}
    - name: empty-vol
      emptyDir: {}
EOF
```
