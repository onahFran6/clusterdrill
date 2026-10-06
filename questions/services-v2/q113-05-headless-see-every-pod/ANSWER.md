# q113-05-headless-see-every-pod: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services

```sh
QUESTION_ID=q113-05-headless-see-every-pod

kubectl expose deployment cache -n "$QUESTION_ID" --name=cache-headless --port=80 --cluster-ip=None

kubectl run tmp-q113-05-fn --rm -i --restart=Never --image=busybox:1.36 -n "$QUESTION_ID" -- \
  sh -c 'nslookup cache-svc; echo ---; nslookup cache-headless; exit 0'
```

A headless Service has no virtual IP and no kube-proxy load balancing. DNS returns every Ready
pod's own IP directly, and the client library picks one itself - `cache-svc` still resolves to its
single ClusterIP, while `cache-headless` resolves to all 3 pod IPs. StatefulSets use exactly this
mechanism to give each of their pods a stable, individually addressable DNS name.
