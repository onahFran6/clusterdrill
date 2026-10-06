# q114-19: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

```sh
NS=q114-19-immutable-config-persistent-output

kubectl patch cm render-v1 -n "$NS" -p '{"data":{"greeting":"bonjour"}}' || true
# ... field is immutable when `immutable` is set

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: render-v2
  labels:
    clusterdrill-question: $NS
immutable: true
data:
  greeting: bonjour
EOF

kubectl patch deployment render -n "$NS" --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"render-v2"}]'

kubectl rollout status deployment/render -n "$NS" --timeout=60s
kubectl exec deploy/render -n "$NS" -- tail -n 2 /out/history
```

Immutable ConfigMaps protect against accidental live edits and spare the kubelet from watching
for changes. Changing the name in the pod template creates a new revision, so `rollout undo`
still goes back to `render-v1` - keep the old version around until you no longer need that
rollback path.
