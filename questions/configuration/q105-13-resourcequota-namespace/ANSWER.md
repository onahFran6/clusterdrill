# q105-13: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/

```sh
kubectl apply -n q105-13-resourcequota-namespace -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
spec:
  hard:
    requests.cpu: "1"
    requests.memory: "1Gi"
    limits.cpu: "2"
    limits.memory: "2Gi"
    pods: "5"
EOF
```
