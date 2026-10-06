# q113-01-expose-deployment-different-port: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/

```sh
QUESTION_ID=q113-01-expose-deployment-different-port

kubectl expose deployment catalog -n "$QUESTION_ID" \
  --name=catalog-svc --port=8080 --target-port=80

kubectl run tmp-q113-01-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  wget -qO- "catalog-svc.$QUESTION_ID.svc.cluster.local:8080"
```

`port` is what clients connect to; `targetPort` is where the pods actually listen. `kubectl
expose` copies the Deployment's pod-template labels into the new Service's selector automatically,
so it already matches `catalog`'s pods without any extra flag.
