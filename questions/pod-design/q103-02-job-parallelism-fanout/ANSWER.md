# q103-02: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs

**Approach A - Fastest (exam default).** Generate the boilerplate, add the two fields that aren't
flags:

```text
kubectl create job render-fanout -n q103-02-job-parallelism-fanout --image=busybox:1.36 \
  --dry-run=client -o yaml -- sleep 3 > /tmp/render-fanout.yaml
vim /tmp/render-fanout.yaml
/^spec:<Enter>
O  completions: 9<Enter>  parallelism: 3<Esc>
:wq
kubectl apply -f /tmp/render-fanout.yaml
```

**Approach B - Alternative.** Write the whole manifest in one shot if you're already confident in
its exact shape. This is what's actually executed below for automated verification:

```sh
kubectl apply -n q103-02-job-parallelism-fanout -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: render-fanout
  labels:
    clusterdrill-question: q103-02-job-parallelism-fanout
spec:
  completions: 9
  parallelism: 3
  template:
    metadata:
      labels:
        clusterdrill-question: q103-02-job-parallelism-fanout
    spec:
      restartPolicy: Never
      containers:
        - name: render-fanout
          image: busybox:1.36
          command: ["sleep", "3"]
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - generator + edit | low (two fields) | low (only the diff is hand-typed) | high - same pattern for any new Job/Pod |
| B - hand-written manifest | high (full manifest) | medium (indentation typed live) | low - re-derive the shape each time |
