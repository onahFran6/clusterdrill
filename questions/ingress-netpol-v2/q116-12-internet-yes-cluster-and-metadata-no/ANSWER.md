# q116-12-internet-yes-cluster-and-metadata-no: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-ipblock-selectors

```sh
QUESTION_ID="q116-12-internet-yes-cluster-and-metadata-no"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: fetcher-egress
spec:
  podSelector:
    matchLabels:
      app: fetcher
  policyTypes: ["Egress"]
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
              - 169.254.169.254/32
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF
```
