# q107-26-node-pressure-eviction-diagnosis: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

```sh
kubectl get pod log-spooler -n q107-26-node-pressure-eviction-diagnosis
kubectl describe pod log-spooler -n q107-26-node-pressure-eviction-diagnosis

kubectl delete pod log-spooler -n q107-26-node-pressure-eviction-diagnosis --ignore-not-found

kubectl apply -n q107-26-node-pressure-eviction-diagnosis -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-spooler
  labels:
    app: log-spooler
    clusterdrill-question: q107-26-node-pressure-eviction-diagnosis
spec:
  containers:
    - name: log-spooler
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      emptyDir:
        sizeLimit: 500Mi
EOF

kubectl wait --for=condition=Ready pod/log-spooler -n q107-26-node-pressure-eviction-diagnosis --timeout=60s
```
