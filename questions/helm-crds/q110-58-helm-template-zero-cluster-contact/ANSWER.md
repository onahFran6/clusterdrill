# q110-58: reference solution

Doc: https://helm.sh/docs/helm/helm_template/

```sh
mkdir -p ~/practice-work/q110-58-helm-template-zero-cluster-contact

helm template renderjob questions/helm-crds/q110-58-helm-template-zero-cluster-contact/chart \
  --set replicaCount=4 \
  > ~/practice-work/q110-58-helm-template-zero-cluster-contact/rendered.yaml
```
