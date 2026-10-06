# q113-03-one-service-two-ports: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#multi-port-services

```sh
QUESTION_ID=q113-03-one-service-two-ports

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: shop-svc
spec:
  selector:
    app: shop
  ports:
    - name: web
      port: 80
      targetPort: http
    - name: metrics
      port: 9100
      targetPort: metrics
EOF

kubectl run tmp-q113-03-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  wget -qO- shop-svc:9100
```

Without a `name` on each entry, a multi-port Service fails admission with
`spec.ports[0].name: Required value`. A Service port's own name (here `web`/`metrics`) and the
container port name it targets (`http`/`metrics`) are independent - `targetPort` can be any string
that matches a `name` under some container's `ports[]`, regardless of what the Service calls that
port itself.
