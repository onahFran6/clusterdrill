# q114-14: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#volume-claim-templates

```sh
NS=q114-14-a-claim-for-every-replica

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kv
  labels:
    clusterdrill-question: $NS
spec:
  clusterIP: None
  selector:
    app: kv
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kv
  labels:
    clusterdrill-question: $NS
spec:
  serviceName: kv
  replicas: 2
  selector:
    matchLabels:
      app: kv
  template:
    metadata:
      labels:
        app: kv
        clusterdrill-question: $NS
    spec:
      containers:
        - name: kv
          image: busybox:1.36
          command: ["sh", "-c", "[ -f /data/id ] || hostname > /data/id; sleep 3600"]
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Mi
EOF

kubectl rollout status statefulset/kv -n "$NS" --timeout=60s
kubectl get pvc -n "$NS"                                    # data-kv-0, data-kv-1

kubectl delete pod kv-0 -n "$NS"
kubectl wait --for=condition=Ready pod/kv-0 -n "$NS" --timeout=60s
kubectl exec kv-0 -n "$NS" -- cat /data/id                  # kv-0

kubectl scale statefulset kv -n "$NS" --replicas=1
sleep 5
kubectl get pvc -n "$NS" -o name                             # data-kv-0, data-kv-1 - both still there
```

A recreated `kv-0` reattaches to its own `data-kv-0` claim, so identity and data stay together.
Scaling down keeps every claim by default, so scaling back up restores each replica's data
exactly as it left it; `persistentVolumeClaimRetentionPolicy` is the field that would change that.
