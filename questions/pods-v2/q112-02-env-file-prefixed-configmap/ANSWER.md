# q112-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables

```sh
NS=q112-02-env-file-prefixed-configmap

kubectl create configmap shop-config \
  --from-env-file="$HOME/practice-work/$NS/shop.env" \
  -n "$NS"
kubectl label configmap shop-config "clusterdrill-question=$NS" -n "$NS"

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: shop
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: shop
      image: nginx:1.27
      envFrom:
        - prefix: SHOP_
          configMapRef:
            name: shop-config
EOF

kubectl wait --for=condition=Ready pod/shop -n "$NS" --timeout=60s
```

`--from-env-file=` reads the file line by line, one key per line. `--from-file=shop.env` would
instead create a single key named `shop.env` holding the whole file, which `envFrom` would turn
into a useless env var name. Keys that aren't valid env var names are skipped by `envFrom` with
an event, not an error.
