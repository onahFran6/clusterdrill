# q107-37-custom-columns-extraction: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/#custom-columns

```sh
mkdir -p "$HOME/practice-work/q107-37-custom-columns-extraction"

kubectl get pods -n q107-37-custom-columns-extraction \
  -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image --no-headers \
  > "$HOME/practice-work/q107-37-custom-columns-extraction/fleet-images.txt"
```
