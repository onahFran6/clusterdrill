# q118-20: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-20-cronjob-behind-deny-all${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: reporter
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/15 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: reporter
            image: busybox:1.36
            command:
            - wget
            - -qO-
            - -T
            - '5'
            - report-svc:8080
        metadata:
          labels:
            app: reporter
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: reporter-egress
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  podSelector:
    matchLabels:
      app: reporter
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: report
    ports:
    - protocol: TCP
      port: 8080
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: report-from-reporter
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  podSelector:
    matchLabels:
      app: report
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: reporter
    ports:
    - protocol: TCP
      port: 8080
YAML
kubectl create job reporter-now -n "$NS" --from=cronjob/reporter
kubectl wait -n "$NS" --for=condition=complete job/reporter-now --timeout=120s
kubectl logs job/reporter-now -n "$NS"
```

The supported-cluster contract does not require a policy-enforcing CNI.
The grader checks the two policies and separately checks the working manual run; it cannot prove that other is blocked on a CNI that ignores NetworkPolicies.
