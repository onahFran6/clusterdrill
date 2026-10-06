# q116-05-the-default-class-came-too-late: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#default-ingress-class

```sh
QUESTION_ID="q116-05-the-default-class-came-too-late"

kubectl annotate ingressclass q116-05-ingress-class \
  ingressclass.kubernetes.io/is-default-class=true --overwrite

# The default-class admission step only fires for an object that does not
# already carry an explicit spec.ingressClassName - "pulsar" may already
# have one baked in from whatever class used to be the default at the
# moment it was first created, so that field has to go too, not just the
# usual server-managed metadata, before a plain delete+recreate can pick up
# the new default.
kubectl get ingress pulsar -n "$QUESTION_ID" -o json \
  | jq 'del(.spec.ingressClassName, .status, .metadata.uid, .metadata.resourceVersion,
            .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields,
            .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")' \
  | kubectl replace --force -f -
```
