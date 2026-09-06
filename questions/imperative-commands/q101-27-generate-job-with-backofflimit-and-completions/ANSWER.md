# q101-27-generate-job-with-backofflimit-and-completions: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs

```sh
NAMESPACE="q101-27-generate-job-with-backofflimit-and-completions"

# kubectl create job has no --completions/--parallelism/--backoff-limit
# flags, so generate the manifest client-side first...
kubectl create job batch-verify \
  --image=busybox:1.36 \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml \
  -- sh -c "echo verifying && exit 0" > /tmp/batch-verify-job.yaml

# ...then edit in the three missing fields (sed here stands in for
# opening the file in an editor and adding the lines under spec:).
sed -i.bak '/^spec:/a\
  completions: 4\
  parallelism: 2\
  backoffLimit: 1
' /tmp/batch-verify-job.yaml

kubectl apply -f /tmp/batch-verify-job.yaml -n "$NAMESPACE"

kubectl wait --for=condition=complete job/batch-verify -n "$NAMESPACE" --timeout=120s

rm -f /tmp/batch-verify-job.yaml /tmp/batch-verify-job.yaml.bak
```
