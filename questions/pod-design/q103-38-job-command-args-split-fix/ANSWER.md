# q103-38: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

**Approach A - Fastest (exam default).** Open the existing file in vim and split the one broken
line in place - you don't retype the fields that were already correct:

```text
vim ~/practice-work/q103-38-job-command-args-split-fix/word-counter.yaml
/command<Enter>
ciw["wc"]<Esc>
o      args: ["-l", "/etc/hostname"]<Esc>
:wq
kubectl apply -f ~/practice-work/q103-38-job-command-args-split-fix/word-counter.yaml
```

**Approach B - Alternative.** Regenerate the whole manifest from a known-good template - safer
when you're not confident editing the broken file in place won't leave stray YAML behind. This
is what's actually executed below for automated verification:

```sh
NS=q103-38-job-command-args-split-fix
MANIFEST="$HOME/practice-work/$NS/word-counter.yaml"

cat > "$MANIFEST" <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: word-counter
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  restartPolicy: Never
  containers:
    - name: word-counter
      image: busybox:1.36
      command: ["wc"]
      args: ["-l", "/etc/hostname"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
YAML

kubectl apply -f "$MANIFEST"

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/word-counter -n "$NS" --timeout=60s
kubectl logs word-counter -n "$NS"
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim, edit in place | low | low (visible before save) | high - any broken field |
| B - regenerate whole file | high | low but easy to drop an unrelated field | medium |
