# q118-08: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#init-containers-in-use)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-08-wait-for-the-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: seed
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  template:
    spec:
      restartPolicy: Never
      initContainers:
      - name: wait-db
        image: busybox:1.36
        command:
        - sh
        - -c
        - until nslookup db.$NS.svc.cluster.local; do echo waiting; sleep 2; done
      containers:
      - name: seed
        image: busybox:1.36
        command:
        - echo
        - seeding db
YAML
kubectl get pods -n "$NS" -l job-name=seed
kubectl create service clusterip db -n "$NS" --tcp=5432:5432
kubectl wait -n "$NS" --for=condition=complete job/seed --timeout=120s
kubectl logs job/seed -c seed -n "$NS"
```
