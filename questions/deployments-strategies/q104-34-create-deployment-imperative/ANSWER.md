# q104-34-create-deployment-imperative: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#create-deployment

```sh
kubectl create deployment frontend --image=nginx:1.25-alpine --replicas=3 \
  -n q104-34-create-deployment-imperative

kubectl label deployment frontend clusterdrill-question=q104-34-create-deployment-imperative \
  -n q104-34-create-deployment-imperative

kubectl rollout status deployment/frontend -n q104-34-create-deployment-imperative --timeout=60s
```
