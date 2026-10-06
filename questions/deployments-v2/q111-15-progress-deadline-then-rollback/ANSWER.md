# q111-15: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment

```sh
NS=q111-15-progress-deadline-then-rollback

kubectl patch deployment ring -n "$NS" -p '{"spec":{"progressDeadlineSeconds":60}}'
kubectl rollout status deployment/ring -n "$NS" --timeout=120s || true

kubectl rollout undo deployment/ring -n "$NS"
kubectl rollout status deployment/ring -n "$NS" --timeout=60s
```

`progressDeadlineSeconds` only makes Kubernetes **report** failure faster: once the deadline
passes with no progress, the Deployment's `Progressing` condition flips to `False` with reason
`ProgressDeadlineExceeded`, and `rollout status` exits non-zero so a pipeline can react - this is
why the command above tolerates that non-zero exit rather than treating it as a script failure.
Kubernetes never rolls back a Deployment on its own, deadline or not; a plain `rollout undo`
back to the previous revision is the right fix here since that previous revision is the one that
was actually working.
