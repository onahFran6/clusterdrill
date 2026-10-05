# q103-37: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/

**Approach A - Fastest (exam default).** One combined selector on `kubectl label` directly -
fewest keystrokes, one command, nothing to pipe:

```sh
kubectl label pods -n q103-37-combined-fieldselector-labelselector-bulk-label \
  --field-selector=status.phase=Running \
  -l tier=batch \
  synced=true
```

**Approach B - Alternative.** List matching names first, then label them - useful when you want
to eyeball exactly which pods will be touched before committing:

```text
kubectl get pods -n q103-37-combined-fieldselector-labelselector-bulk-label \
  --field-selector=status.phase=Running -l tier=batch -o name
kubectl label -n q103-37-combined-fieldselector-labelselector-bulk-label \
  $(kubectl get pods -n q103-37-combined-fieldselector-labelselector-bulk-label \
    --field-selector=status.phase=Running -l tier=batch -o name) synced=true
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - one combined command | low | low | high |
| B - get, eyeball, then label | higher | low (you see the list first) | medium |
