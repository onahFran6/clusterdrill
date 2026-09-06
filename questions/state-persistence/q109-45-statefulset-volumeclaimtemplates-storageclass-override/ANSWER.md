# q109-45-statefulset-volumeclaimtemplates-storageclass-override: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#stable-storage

```sh
kubectl apply -n q109-45-statefulset-volumeclaimtemplates-storageclass-override -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ledger
spec:
  serviceName: ledger
  replicas: 2
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
    spec:
      containers:
        - name: ledger
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /var/lib/ledger
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: retained-storage
        resources:
          requests:
            storage: 100Mi
EOF

kubectl rollout status statefulset/ledger \
  -n q109-45-statefulset-volumeclaimtemplates-storageclass-override --timeout=120s
```
