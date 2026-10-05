# q103-06: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup

**Approach A - Fastest (exam default).** Generate the boilerplate, add the one field that isn't a
flag:

```text
kubectl create job long-runner -n q103-06-job-active-deadline-seconds --image=busybox:1.36 \
  --dry-run=client -o yaml -- sleep 120 > /tmp/long-runner.yaml
vim /tmp/long-runner.yaml
/^spec:<Enter>
O  activeDeadlineSeconds: 5<Esc>
:wq
kubectl apply -f /tmp/long-runner.yaml
```

**Approach B - Alternative.** Write the whole manifest in one shot if you're already confident in
its exact shape. This is what's actually executed below for automated verification:

```sh
kubectl apply -n q103-06-job-active-deadline-seconds -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: long-runner
  labels:
    clusterdrill-question: q103-06-job-active-deadline-seconds
spec:
  activeDeadlineSeconds: 5
  template:
    metadata:
      labels:
        clusterdrill-question: q103-06-job-active-deadline-seconds
    spec:
      restartPolicy: Never
      containers:
        - name: long-runner
          image: busybox:1.36
          command: ["sleep", "120"]
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - generator + edit | low (one field) | low (only the diff is hand-typed) | high - same pattern for any new Job/Pod |
| B - hand-written manifest | high (full manifest) | medium (indentation typed live) | low - re-derive the shape each time |
