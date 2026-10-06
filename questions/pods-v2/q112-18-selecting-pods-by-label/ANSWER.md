# q112-18: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors

```sh
NS=q112-18-selecting-pods-by-label

kubectl label pods -n "$NS" -l 'env=prod,tier in (web,api)' release=r42
kubectl annotate pod web-1 -n "$NS" owner=team-iapetus
kubectl label pods -n "$NS" -l temp temp-

kubectl get pods -n "$NS" -l 'env=prod,tier!=db' -o name
# api-1, batch-1, cache-1, web-1
```

`tier!=db` also matches Pods with no `tier` label at all, so `batch-1` is included even though it
never had a `tier`. To require the label to exist first, the selector would need to be
`'env=prod,tier,tier!=db'` instead. Quoting a set-based selector matters here - without it, the
shell would try to glob-expand the parentheses or treat the comma as a separate argument.
