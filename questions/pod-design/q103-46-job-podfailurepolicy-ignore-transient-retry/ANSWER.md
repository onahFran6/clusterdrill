# q103-46: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-failure-policy

```sh
NS=q103-46-job-podfailurepolicy-ignore-transient-retry

kubectl delete job heartbeat-sync -n "$NS" --wait=true

kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: heartbeat-sync
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 1
  podFailurePolicy:
    rules:
      - action: Ignore
        onExitCodes:
          containerName: heartbeat-sync
          operator: In
          values: [75]
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      restartPolicy: Never
      volumes:
        - name: state
          persistentVolumeClaim:
            claimName: heartbeat-state
      containers:
        - name: heartbeat-sync
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              COUNT_FILE=/data/attempts
              [ -f "\$COUNT_FILE" ] || echo 0 > "\$COUNT_FILE"
              N=\$(( \$(cat "\$COUNT_FILE") + 1 ))
              echo "\$N" > "\$COUNT_FILE"
              if [ "\$N" -le 2 ]; then
                echo "dependency not ready yet (attempt \$N)"
                exit 75
              fi
              echo "dependency ready, syncing"
              exit 0
          volumeMounts:
            - name: state
              mountPath: /data
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Complete job/heartbeat-sync -n "$NS" --timeout=120s
```
