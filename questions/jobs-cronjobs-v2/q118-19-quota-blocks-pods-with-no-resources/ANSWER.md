# q118-19: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-19-quota-blocks-pods-with-no-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: digest
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/1 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: digest
            image: busybox:1.36
            command:
            - echo
            - digest done
            resources:
              requests:
                cpu: 50m
                memory: 32Mi
              limits:
                cpu: 100m
                memory: 64Mi
YAML
kubectl delete jobs --all -n "$NS"
kubectl create job digest-now -n "$NS" --from=cronjob/digest
kubectl wait -n "$NS" --for=condition=complete job/digest-now --timeout=120s
kubectl describe quota compute -n "$NS"
```

This namespace deliberately has no LimitRange to fill missing requests and limits.
Quota usage drops when Pods finish, so the grader checks the actual resource fields and successful run instead of transient usage.
