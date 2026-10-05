# q103-14: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_delete/

**Approach A - Fastest (exam default).** Preview which pods the selector matches before an
irreversible bulk delete - a wrong selector shows up as an obviously wrong list instead of
silently deleting the wrong pods:

```sh
kubectl get pods -n q103-14-delete-pods-by-selector -l lifecycle=scratch

kubectl delete pods -n q103-14-delete-pods-by-selector -l lifecycle=scratch
```

**Approach B - Alternative.** Skip the preview and delete directly - prefer this once you're
confident of the selector and want to save a command:

```text
kubectl delete pods -n q103-14-delete-pods-by-selector -l lifecycle=scratch
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - preview then delete | medium (2 commands) | low (matches seen before deleting) | high |
| B - delete directly | low (1 command) | medium (wrong selector is irreversible and silent) | high |
