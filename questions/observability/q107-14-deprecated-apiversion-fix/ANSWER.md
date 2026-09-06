# q107-14: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.35/#cronjob-v1-batch

```sh
sed -i.bak 's|apiVersion: batch/v1beta1|apiVersion: batch/v1|' $HOME/practice-work/q107-14-deprecated-apiversion-fix/q107-14-cronjob.yaml

kubectl apply -f $HOME/practice-work/q107-14-deprecated-apiversion-fix/q107-14-cronjob.yaml
```
