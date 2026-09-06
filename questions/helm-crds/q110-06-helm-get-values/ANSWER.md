# q110-06: reference solution

Doc: https://helm.sh/docs/helm/helm_get_values/

```sh
VALUE=$(helm get values cache-1 -n q110-06-helm-get-values -o json | grep -o '"maxMemoryMb":[0-9]*' | cut -d: -f2)
kubectl create configmap inspected-values -n q110-06-helm-get-values --from-literal=maxMemoryMb="$VALUE"
```
