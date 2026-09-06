# q105-29-immutable-configmap-rollout-swap: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

```sh
kubectl apply -n q105-29-immutable-configmap-rollout-swap -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v2
data:
  LOG_LEVEL: "debug"
immutable: true
EOF

kubectl patch deployment worker -n q105-29-immutable-configmap-rollout-swap --type strategic -p '
spec:
  template:
    spec:
      volumes:
        - name: app-config
          configMap:
            name: app-config-v2
'

kubectl rollout status deployment/worker -n q105-29-immutable-configmap-rollout-swap --timeout=120s
```
