# q103-25: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode

```sh
# completionMode is immutable once a Job exists - delete and recreate it.
kubectl delete job indexed-writer -n q103-25-job-indexed-completion-mode --wait=true

# Quoted heredoc ('EOF') on purpose: nothing inside should be expanded by
# this outer shell, including ${JOB_COMPLETION_INDEX} - that variable is
# for the container's own embedded shell script, injected by Kubernetes at
# pod-start time, not by this apply.
kubectl apply -n q103-25-job-indexed-completion-mode -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-writer
  labels:
    clusterdrill-question: q103-25-job-indexed-completion-mode
spec:
  completionMode: Indexed
  completions: 3
  parallelism: 3
  template:
    metadata:
      labels:
        clusterdrill-question: q103-25-job-indexed-completion-mode
    spec:
      restartPolicy: Never
      containers:
        - name: writer
          image: busybox:1.36
          command: ["sh", "-c", "echo \"${JOB_COMPLETION_INDEX}\" > /data/output-${JOB_COMPLETION_INDEX}.txt; sleep 2"]
          volumeMounts:
            - name: shared
              mountPath: /data
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-output
EOF

kubectl wait --for=condition=Complete job/indexed-writer -n q103-25-job-indexed-completion-mode --timeout=180s
```
