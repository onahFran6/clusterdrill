# q101-46-fix-stuck-rollout-bad-readiness-probe: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes

```sh
kubectl describe pod -l app=web-front -n q101-46-fix-stuck-rollout-bad-readiness-probe
kubectl get events -n q101-46-fix-stuck-rollout-bad-readiness-probe --sort-by='.lastTimestamp'

kubectl get deployment web-front -n q101-46-fix-stuck-rollout-bad-readiness-probe \
  -o yaml > /tmp/web-front.yaml

sed -i.bak 's#path: /this-path-does-not-exist#path: /#' /tmp/web-front.yaml

kubectl apply -f /tmp/web-front.yaml -n q101-46-fix-stuck-rollout-bad-readiness-probe

kubectl rollout status deployment/web-front \
  -n q101-46-fix-stuck-rollout-bad-readiness-probe --timeout=90s

rm -f /tmp/web-front.yaml /tmp/web-front.yaml.bak
```
