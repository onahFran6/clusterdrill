# q111-20: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
NS=q111-20-expose-by-named-port

kubectl patch deployment beam -n "$NS" --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/ports","value":[{"name":"http","containerPort":80}]}]'
kubectl rollout status deployment/beam -n "$NS" --timeout=60s

kubectl expose deployment beam -n "$NS" --port=8080 --target-port=http
```

`kubectl expose` copies the Deployment's pod-selector labels for you, so the Service
automatically matches all 3 `beam` pods. A named target port is resolved per pod at the port
name, not a fixed number - if the container later moves to a different port while keeping the
name `http`, the Service needs no change at all. This is also how a canary can expose a
different container port than stable under the same Service, as long as both name it `http`.
