# q112-07: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode

```sh
NS=q112-07-storageclass-waitforfirstconsumer

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logs-pvc
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
EOF

kubectl get pvc logs-pvc -n "$NS"
kubectl describe pvc logs-pvc -n "$NS" | tail -5
kubectl get sc

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: logger
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: logs
      persistentVolumeClaim:
        claimName: logs-pvc
  containers:
    - name: logger
      image: busybox:1.36
      command: ["sh", "-c", "while true; do date >> /logs/run.log; sleep 5; done"]
      volumeMounts:
        - name: logs
          mountPath: /logs
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/logs-pvc -n "$NS" --timeout=60s
```

Leaving `storageClassName` out of the PVC is how you ask for the cluster's default class, not an
oversight. A default class with `volumeBindingMode: WaitForFirstConsumer` deliberately delays
provisioning until the scheduler has picked a node for a Pod using the claim, so the volume gets
created where that Pod can actually reach it - a `Pending` claim with that exact event in its
description is healthy, not broken.
