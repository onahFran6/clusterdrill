# q103-01: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#controlling-parallelism

**Approach A - Fastest (exam default).** Generate the boilerplate, add the one field that isn't
a flag - far less typing than a hand-written manifest, and the diff is visible before you apply:

```text
kubectl create job digest-batch -n q103-01-job-fixed-completions --image=busybox:1.36 \
  --dry-run=client -o yaml -- sha256sum /etc/hostname > /tmp/digest-batch.yaml
vim /tmp/digest-batch.yaml
/^spec:<Enter>
O  completions: 6<Esc>
:wq
kubectl apply -f /tmp/digest-batch.yaml
```

**Approach B - Alternative.** Write the whole manifest in one shot if you're already confident in
its exact shape. This is what's actually executed below for automated verification:

```sh
kubectl apply -n q103-01-job-fixed-completions -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: digest-batch
  labels:
    clusterdrill-question: q103-01-job-fixed-completions
spec:
  completions: 6
  template:
    metadata:
      labels:
        clusterdrill-question: q103-01-job-fixed-completions
    spec:
      restartPolicy: Never
      containers:
        - name: digest-batch
          image: busybox:1.36
          command: ["sha256sum", "/etc/hostname"]
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - generator + edit | low (one field) | low (only the diff is hand-typed) | high - same pattern for any new Job/Pod |
| B - hand-written manifest | high (full manifest) | medium (indentation typed live) | low - re-derive the shape each time |
