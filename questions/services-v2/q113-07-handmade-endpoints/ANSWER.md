# q113-07-handmade-endpoints: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors

```sh
QUESTION_ID=q113-07-handmade-endpoints

LEGACY_IP=$(kubectl get pod legacy -n "$QUESTION_ID" -o jsonpath='{.status.podIP}')

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: legacy-svc
spec:
  ports:
    - name: http
      port: 80
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: legacy-svc-1
  labels:
    kubernetes.io/service-name: legacy-svc
addressType: IPv4
ports:
  - name: http
    port: 80
    protocol: TCP
endpoints:
  - addresses: ["$LEGACY_IP"]
EOF

kubectl run tmp-q113-07-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  wget -qO- -T 3 legacy-svc
```

A Service with no `spec.selector` gets no automatically-managed endpoints at all - you supply
them yourself, as an EndpointSlice tied to the Service purely by the
`kubernetes.io/service-name` label (not by name or owner reference). The EndpointSlice's own
`ports[].name` must match the Service's `ports[].name`, the same way a selector-based Service
matches a container port by name. This is how you put a stable in-cluster name in front of
anything with a routable IP but no Kubernetes-native way to register itself - a legacy VM, an
external database. Nothing here keeps the IP current automatically: if the target moves, you
edit the EndpointSlice yourself.
