# q104-08: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_resume/

```sh
kubectl rollout resume deployment/reporting -n q104-08-resume-paused-rollout

kubectl rollout status deployment/reporting -n q104-08-resume-paused-rollout --timeout=60s

# Give the old ReplicaSet's pods a moment to finish terminating after the
# rollout reports done - rollout status can return slightly before the last
# old pod is actually gone.
for i in $(seq 1 30); do
  old="$(kubectl get pods -n q104-08-resume-paused-rollout -l app=reporting \
    -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | grep -c 'nginx:1.24-alpine')"
  [ "$old" = "0" ] && break
  sleep 1
done
```
