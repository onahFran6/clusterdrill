# q108-44-networkpolicy-ipblock-cidr-except: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-ipblock-selectors

```sh
kubectl apply -n q108-44-networkpolicy-ipblock-cidr-except -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: analytics-restrict-egress-cidr
spec:
  podSelector:
    matchLabels:
      app: analytics
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
            except:
              - 10.0.5.0/24
EOF
```
