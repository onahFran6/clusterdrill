# q103-05: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-patterns

**Approach A - Fastest (exam default).** Short enough to write as one manifest in place - no
field here follows a boilerplate default worth generating separately.

```sh
kubectl apply -n q103-05-job-work-queue-parallelism -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-workers
  labels:
    clusterdrill-question: q103-05-job-work-queue-parallelism
spec:
  parallelism: 4
  template:
    metadata:
      labels:
        clusterdrill-question: q103-05-job-work-queue-parallelism
    spec:
      restartPolicy: Never
      containers:
        - name: queue-workers
          image: busybox:1.36
          command: ["sh", "-c", "sleep 2 && exit 0"]
EOF
```

**Approach B - Alternative.** Generate the container skeleton instead of typing it, then merge in
the one field the generator can't set - prefer this on a longer spec where retyping the whole
container block risks a typo:

```text
kubectl create job queue-workers --image=busybox:1.36 --dry-run=client -o yaml \
  -- sh -c "sleep 2 && exit 0" \
  | kubectl patch --local -f - --type merge -p '{"spec":{"parallelism":4}}' -o yaml \
  | kubectl apply -n q103-05-job-work-queue-parallelism -f -
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - hand-written manifest | low (short spec) | low | medium |
| B - generator + local patch | medium (patch JSON) | low | high (scales to longer specs) |
