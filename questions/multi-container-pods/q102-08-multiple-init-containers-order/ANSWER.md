# q102-08: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

```sh
kubectl apply -n q102-08-multiple-init-containers-order -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ordered-init-app
  labels:
    clusterdrill-question: q102-08-multiple-init-containers-order
spec:
  initContainers:
    - name: init-first
      image: busybox:1.36
      command: ["sh", "-c", "touch /work/first-done"]
      volumeMounts:
        - name: work-vol
          mountPath: /work
    - name: init-second
      image: busybox:1.36
      command: ["sh", "-c", "test -f /work/first-done && touch /work/second-done"]
      volumeMounts:
        - name: work-vol
          mountPath: /work
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: work-vol
          mountPath: /work
  volumes:
    - name: work-vol
      emptyDir: {}
EOF
```
