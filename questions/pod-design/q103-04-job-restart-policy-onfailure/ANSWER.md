# q103-04: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-template

**Approach A - Fastest (exam default).** The generator defaults to `restartPolicy: Never` - seeing
that default on screen and having to change it is a useful forcing function for this exact
discernment:

```text
kubectl create job retry-in-place -n q103-04-job-restart-policy-onfailure --image=busybox:1.36 \
  --dry-run=client -o yaml -- sh -c "exit 1" > /tmp/retry-in-place.yaml
vim /tmp/retry-in-place.yaml
/Never<Enter>
ciwOnFailure<Esc>
/^spec:<Enter>
O  backoffLimit: 3<Esc>
:wq
kubectl apply -f /tmp/retry-in-place.yaml
```

**Approach B - Alternative.** Write the whole manifest in one shot if you're already confident in
its exact shape. This is what's actually executed below for automated verification:

```sh
kubectl apply -n q103-04-job-restart-policy-onfailure -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-in-place
  labels:
    clusterdrill-question: q103-04-job-restart-policy-onfailure
spec:
  backoffLimit: 3
  template:
    metadata:
      labels:
        clusterdrill-question: q103-04-job-restart-policy-onfailure
    spec:
      restartPolicy: OnFailure
      containers:
        - name: retry-in-place
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - generator + edit | low (two fields) | low (default value is visible, so the change is too) | high - same pattern for any new Job/Pod |
| B - hand-written manifest | high (full manifest) | medium (indentation typed live) | low - re-derive the shape each time |
