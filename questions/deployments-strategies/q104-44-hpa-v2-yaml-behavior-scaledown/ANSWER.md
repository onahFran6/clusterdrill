# q104-44-hpa-v2-yaml-behavior-scaledown: reference solution

Doc: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior

```sh
kubectl apply -n q104-44-hpa-v2-yaml-behavior-scaledown -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: render-farm-hpa
  labels:
    clusterdrill-question: q104-44-hpa-v2-yaml-behavior-scaledown
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: render-farm
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 120
EOF
```
