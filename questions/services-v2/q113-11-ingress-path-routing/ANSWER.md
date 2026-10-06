# q113-11-ingress-path-routing: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#simple-fanout

```sh
QUESTION_ID=q113-11-ingress-path-routing

kubectl create ingress capella -n "$QUESTION_ID" --class=nginx \
  --rule="capella.local/shop*=shop-svc:80" \
  --rule="capella.local/api*=api-svc:80"
```

A trailing `*` on a `kubectl create ingress --rule` path produces `pathType: Prefix`. Because both
rules share the same host, `kubectl create ingress` merges them into one `rules[]` entry with two
`http.paths` entries rather than two separate host blocks - that's the shape a real ingress-nginx
controller (or any other) expects for "two paths, one host". The backend always names the
**Service** port, not the container port behind it.
