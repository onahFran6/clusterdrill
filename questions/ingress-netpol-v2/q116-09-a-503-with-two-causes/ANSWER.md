# q116-09-a-503-with-two-causes: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#name-based-virtual-hosting

```sh
QUESTION_ID="q116-09-a-503-with-two-causes"
WRONG_NS="${QUESTION_ID}-wrong"

kubectl delete ingress eclipse -n "$WRONG_NS"

kubectl create ingress eclipse -n "$QUESTION_ID" --class=nginx \
  --rule="eclipse.local/*=web-svc:80"

kubectl set selector svc web-svc app=web -n "$QUESTION_ID"
```
