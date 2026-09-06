# q105-50-secret-env-vs-volume-rotation: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#mounted-secrets-are-updated-automatically

```sh
kubectl patch secret db-creds -n q105-50-secret-env-vs-volume-rotation \
  --type=merge \
  -p "{\"data\":{\"PASSWORD\":\"$(printf '%s' 'rotated-pw-99' | base64)\"}}"

# Wait for kubelet's periodic volume resync (up to ~1 minute) to pick up
# the new value in vol-reader's mounted file. No pod/container action
# needed - this happens automatically for volume-mounted Secrets.
sleep 75
```
