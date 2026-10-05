# q103-17: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#clean-up-finished-jobs-automatically

**Approach A - Fastest (exam default).** Short enough to write as one manifest in place.

```sh
kubectl apply -n q103-17-job-ttl-after-finished -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: self-cleaning
  labels:
    clusterdrill-question: q103-17-job-ttl-after-finished
spec:
  ttlSecondsAfterFinished: 10
  template:
    metadata:
      labels:
        clusterdrill-question: q103-17-job-ttl-after-finished
    spec:
      restartPolicy: Never
      containers:
        - name: self-cleaning
          image: busybox:1.36
          command: ["echo", "done"]
EOF
```

**Approach B - Alternative.** Generate the container skeleton instead of typing it, then merge in
the one field the generator can't set - prefer this when you'd rather not retype `image`/`command`
by hand:

```text
kubectl create job self-cleaning --image=busybox:1.36 --dry-run=client -o yaml \
  -- echo done \
  | kubectl patch --local -f - --type merge -p '{"spec":{"ttlSecondsAfterFinished":10}}' -o yaml \
  | kubectl apply -n q103-17-job-ttl-after-finished -f -
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - hand-written manifest | low (short spec) | low | medium |
| B - generator + local patch | medium (patch JSON) | low | high (scales to longer specs) |
