# q101-33-hpa-fights-manual-scale: reference solution

Doc: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#autoscaling-on-multiple-metrics-and-custom-metrics

The HorizontalPodAutoscaler `email-worker` has `minReplicas: 3`, so every time it reconciles it
enforces that floor and scales `email-worker` back up regardless of any manual `kubectl scale`.
Lower `minReplicas` imperatively with `kubectl patch`, then re-issue the scale-down - with the
floor gone, it sticks.

```sh
kubectl patch hpa email-worker -n q101-33-hpa-fights-manual-scale \
  --type merge -p '{"spec":{"minReplicas":1}}'

kubectl scale deployment/email-worker -n q101-33-hpa-fights-manual-scale --replicas=1
```
