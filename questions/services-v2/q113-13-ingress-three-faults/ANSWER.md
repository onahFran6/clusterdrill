# q113-13-ingress-three-faults: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class

```sh
QUESTION_ID=q113-13-ingress-three-faults

kubectl get ingress portal -n "$QUESTION_ID"           # CLASS <none>
kubectl describe ingress portal -n "$QUESTION_ID"       # portal-service:8080 (<error: services "portal-service" not found>)

kubectl patch ingress portal -n "$QUESTION_ID" --type=json -p='[
  {"op": "add", "path": "/spec/ingressClassName", "value": "nginx"},
  {"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "portal-svc"},
  {"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/port/number", "value": 80}
]'
```

In order: no `ingressClassName` and no default IngressClass means no controller ever serves this
object at all, which answers like the controller itself doesn't exist (404 at the edge); once
that's fixed, a rule matching but naming a Service that doesn't exist (`portal-service`, a typo
for `portal-svc`) fails backend resolution (503); and even once the name is right, the wrong
backend port (8080, when the Service only listens on 80) fails the same way. An Ingress backend
always names the **Service**'s own port, never a container port directly.
