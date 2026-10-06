# q114-09: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

```sh
NS=q114-09-once-per-node-or-pod

for m in rwo:ReadWriteOnce rwop:ReadWriteOncePod; do
  name="${m%%:*}"
  mode="${m#*:}"
  cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: c-$name
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: manual-q114-09
  volumeName: q114-09-$name
  accessModes: ["$mode"]
  resources:
    requests:
      storage: 1Gi
EOF
done

p() {
  cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: $1
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: d
      persistentVolumeClaim:
        claimName: $2
  containers:
    - name: c
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: d
          mountPath: /data
EOF
}

p a1 c-rwo
p a2 c-rwo
p b1 c-rwop
sleep 5
p b2 c-rwop
sleep 10

kubectl get pods -n "$NS" --no-headers | awk '{print $1, $3}'
kubectl describe pod b2 -n "$NS" | grep -A3 Events | tail -n 2
```

`ReadWriteOnce` limits mounting to one **node**, so any number of pods on that node can share it -
`a1` and `a2` are both `Running`. `ReadWriteOncePod` limits it to one **pod** in the whole
cluster, enforced by the scheduler - `b2` stays `Pending` with an event naming the conflicting
pod. Creating `b1` and `b2` at the same time would race the scheduler and could flip which one
lands `Pending`, which is why `b1` goes first and gets a moment to actually start.
