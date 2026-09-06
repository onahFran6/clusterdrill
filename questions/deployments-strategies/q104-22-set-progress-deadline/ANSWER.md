# q104-22-set-progress-deadline: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#progress-deadline-seconds

```sh
kubectl patch deployment image-resizer -n q104-22-set-progress-deadline \
  --type merge -p '{"spec":{"progressDeadlineSeconds":120}}'
```
