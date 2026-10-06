# q103-13: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/

**Approach A - Fastest (exam default).** See exactly which pod the combined selector matches
before committing the label - a mistake in the selector is visible immediately instead of
silently labeling the wrong pod.

```sh
kubectl get pods -n q103-13-get-pods-multi-label-selector -l tier=frontend,env=prod

kubectl label pod frontend-a -n q103-13-get-pods-multi-label-selector verified=true
```

**Approach B - Alternative.** Label directly by selector in one command - prefer this once
you're confident the selector is exactly right and want to save a step:

```text
kubectl label pods -n q103-13-get-pods-multi-label-selector -l tier=frontend,env=prod verified=true
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - get then label by name | medium (2 commands) | low (match seen before labeling) | high |
| B - label directly by selector | low (1 command) | medium (a wrong selector silently mislabels) | high |
