# q101-43-copy-file-into-running-pod: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#cp

```sh
kubectl cp \
  "$HOME/practice-work/q101-43-copy-file-into-running-pod/manifest.txt" \
  q101-43-copy-file-into-running-pod/archive-box:/data/manifest.txt \
  -c archive-box
```
