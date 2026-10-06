# q103-41: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/

**Approach A - Fastest (exam default).** Open the file in vim, jump to the bad value, swap it -
visible before you save:

```text
vim ~/practice-work/q103-41-topologyspreadconstraint-invalid-maxskew-fix/spread-worker.yaml
/maxSkew: 0<Enter>
ciw1<Esc>
:wq
kubectl apply -f ~/practice-work/q103-41-topologyspreadconstraint-invalid-maxskew-fix/spread-worker.yaml
```

**Approach B - Alternative.** A `sed` one-liner - fine since there's exactly one occurrence, but
riskier on a file with more than one similar value. This is also what's actually executed below
for automated verification:

```sh
NS=q103-41-topologyspreadconstraint-invalid-maxskew-fix
MANIFEST="$HOME/practice-work/$NS/spread-worker.yaml"

sed -i.bak 's/maxSkew: 0/maxSkew: 1/' "$MANIFEST"

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/spread-worker -n "$NS" --timeout=60s
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - vim | low | low (visible before save) | high - any field fix |
| B - sed | lowest | higher on multi-match files | medium - simple 1-liners only |
