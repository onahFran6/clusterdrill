# q113-02-fixed-nodeport: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

```sh
QUESTION_ID=q113-02-fixed-nodeport

kubectl expose deployment web -n "$QUESTION_ID" \
  --name=web-np --type=NodePort --port=80 --dry-run=client -o yaml > /tmp/web-np.yaml
# edit /tmp/web-np.yaml: add `nodePort: 30090` under spec.ports[0]
sed -i.bak '/targetPort: 80/a\
    nodePort: 30090' /tmp/web-np.yaml
kubectl apply -f /tmp/web-np.yaml

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | awk '{print $1}')
sleep 5   # the NodePort iptables/ipvs rule needs a moment to propagate
kubectl run tmp-q113-02-fn --rm -i --restart=Never --image=curlimages/curl:8.10.1 -n "$QUESTION_ID" -- \
  curl -s -o /dev/null -w '%{http_code}' "http://$NODE_IP:30090"
```

A NodePort Service is also a ClusterIP Service, so `web-np:80` still works inside the cluster.
Node ports must fall in `30000-32767` by default, and a port already claimed by another Service
is rejected.
