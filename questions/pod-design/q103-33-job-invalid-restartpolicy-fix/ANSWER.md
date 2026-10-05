# q103-33: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-template

**Approach A - Fastest (exam default).** Open the file in vim, jump to the bad value, swap it -
the change is visible on screen before you save, and this is the reflex you reuse for any
one-field YAML fix:

```text
vim ~/practice-work/q103-33-job-invalid-restartpolicy-fix/broken-once.yaml
/Always<Enter>
ciwNever<Esc>
:wq
kubectl apply -f ~/practice-work/q103-33-job-invalid-restartpolicy-fix/broken-once.yaml
```

**Approach B - Alternative.** A `sed` one-liner - fine here since there's exactly one occurrence
to replace, but riskier on a file with more than one similar value since it can't show you the
diff before it writes. This is also what's actually executed below for automated verification:

```sh
NS=q103-33-job-invalid-restartpolicy-fix
MANIFEST="$HOME/practice-work/$NS/broken-once.yaml"

sed -i.bak 's/restartPolicy: Always/restartPolicy: Never/' "$MANIFEST"

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Complete job/broken-once -n "$NS" --timeout=60s
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim | low | low (visible before save) | high - any field fix |
| B - sed | lowest | higher on multi-match files | medium - simple 1-liners only |
