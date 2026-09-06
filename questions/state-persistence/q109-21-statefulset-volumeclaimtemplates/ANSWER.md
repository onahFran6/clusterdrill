# q109-21: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#volume-claim-templates

```sh
QUESTION_ID="q109-21-statefulset-volumeclaimtemplates"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db
  replicas: 2
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - name: db
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: data
              mountPath: /var/lib/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Mi
EOF

kubectl rollout status statefulset/db -n "$QUESTION_ID" --timeout=120s
```
