# q111-18: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
kubectl set resources deployment oven -n q111-18-limitrange-largest-allowed \
  --requests=memory=512Mi --limits=memory=512Mi

kubectl rollout status deployment/oven -n q111-18-limitrange-largest-allowed --timeout=60s
```

`kubectl describe rs -l app=oven` shows the actual rejection: "maximum memory usage per
Container is 512Mi, but limit is 1Gi" - a LimitRange enforces its bounds at admission, so a pod
exceeding `max` is rejected outright and the ReplicaSet never gets to create one. 512Mi is the
largest value this namespace's LimitRange allows for both request and limit at once. `bread`'s
Deployment spec still shows no resources at all - only its actual running pod has
`requests.memory: 128Mi` / `limits.memory: 256Mi`, because a LimitRange fills in missing values
for new pods at admission time; it never retroactively changes a Deployment's own manifest, and
it never touches pods that already existed before the LimitRange was added.
