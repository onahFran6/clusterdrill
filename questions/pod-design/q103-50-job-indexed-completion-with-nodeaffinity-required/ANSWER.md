# q103-50: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode

**Approach A - Fastest (exam default).** Rewrite the whole file from a known-good manifest -
two separate insertions (a top-level field and a nested affinity block) is more than enough
chances to misplace one by hand-splicing the existing file:

```sh
NS=q103-50-job-indexed-completion-with-nodeaffinity-required
MANIFEST="$HOME/practice-work/$NS/sharded-worker.yaml"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

cat > "$MANIFEST" <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: sharded-worker
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  completionMode: Indexed
  completions: 3
  parallelism: 3
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - $TARGET_NODE
      restartPolicy: Never
      containers:
        - name: sharded-worker
          image: busybox:1.36
          command: ["sh", "-c", "echo \"index \$JOB_COMPLETION_INDEX\""]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
YAML

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Complete job/sharded-worker -n "$NS" --timeout=90s
```

**Approach B - Alternative.** Edit the existing file in place in vim, inserting the two missing
pieces where the `# TODO` comments mark them - faster if you're confident about both insertion
points and their indentation:

```text
vim ~/practice-work/q103-50-job-indexed-completion-with-nodeaffinity-required/sharded-worker.yaml
/completions:<Enter>
O  completionMode: Indexed<Esc>
/restartPolicy: Never<Enter>
O      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - <this cluster's node name, from `kubectl get nodes`>
<Esc>
:wq
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - rewrite whole file | medium (paste) | low - structure is correct by construction | high - same pattern for any deeply-nested block |
| B - vim in-place edit | low (only the two insertions) | medium - two separate insertion points to get right | high - the general "edit existing file" reflex |
