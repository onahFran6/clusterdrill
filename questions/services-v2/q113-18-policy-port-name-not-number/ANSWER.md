# q113-18-policy-port-name-not-number: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#targeting-a-named-port

```sh
QUESTION_ID=q113-18-policy-port-name-not-number

kubectl patch deployment web -n "$QUESTION_ID" --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/ports","value":[{"name":"http","containerPort":80}]}]'
kubectl rollout status deployment/web -n "$QUESTION_ID"

kubectl patch networkpolicy allow-client -n "$QUESTION_ID" --type=json \
  -p='[{"op":"replace","path":"/spec/ingress/0/ports/0/port","value":"http"}]'
```

A NetworkPolicy is enforced at the pod, after the Service has already DNAT'd `web-svc:8080` down
to `podIP:80` - policy ports are always pod ports, never Service ports. The broken policy allowed
8080 (the Service's port), which the packet is never actually addressed to once it reaches `web`.
A named policy port is resolved against each selected pod's own container ports, which is why the
Deployment needed the name added first: naming it `http` means a future container-port change
only needs updating in one place, the Deployment, instead of also chasing down every policy that
referenced the old number.
