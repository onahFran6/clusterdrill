# q103-41: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/

```sh
NS=q103-41-topologyspreadconstraint-invalid-maxskew-fix
MANIFEST="$HOME/practice-work/$NS/spread-worker.yaml"

sed -i.bak 's/maxSkew: 0/maxSkew: 1/' "$MANIFEST"

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/spread-worker -n "$NS" --timeout=60s
```
