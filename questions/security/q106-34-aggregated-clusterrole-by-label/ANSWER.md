# q106-34: reference solution

Doc: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles

```sh
kubectl create clusterrole q106-34-pod-reader \
  --verb=get --verb=list \
  --resource=pods

kubectl label clusterrole q106-34-pod-reader \
  rbac.example.com/aggregate-to-q106-34-monitoring=true \
  clusterdrill-question=q106-34-aggregated-clusterrole-by-label

# Aggregation is asynchronous - give the controller a moment to notice the
# label match and fold q106-34-pod-reader's rules into
# q106-34-monitoring-aggregate.rules before relying on it.
sleep 5
```
