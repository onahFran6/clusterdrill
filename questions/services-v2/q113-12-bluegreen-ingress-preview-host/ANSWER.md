# q113-12-bluegreen-ingress-preview-host: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend

```sh
QUESTION_ID=q113-12-bluegreen-ingress-preview-host

kubectl create ingress procyon -n "$QUESTION_ID" --class=nginx \
  --rule="procyon.local/*=blue-svc:80" \
  --rule="preview.procyon.local/*=green-svc:80" \
  --default-backend=fallback-svc:80

# ... after checking the preview, cut the main host over:
kubectl patch ingress procyon -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"green-svc"}]'
```

Two different hosts stay as two separate `rules[]` entries (unlike same-host paths, which merge
into one entry's `http.paths`). This is blue/green at the Ingress layer: the cut-over is one field
on the main host's rule, and rollback is the exact same patch pointed back at `blue-svc`. Check
`kubectl get ingress procyon -o yaml` for the rule order before patching by index - nothing
guarantees `rules[0]` is the main host rather than the preview one.
