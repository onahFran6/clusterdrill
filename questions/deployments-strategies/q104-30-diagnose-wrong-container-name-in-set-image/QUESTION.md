# q104-30-diagnose-wrong-container-name-in-set-image: Find the real container name before updating its image

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-30-diagnose-wrong-container-name-in-set-image`

`setup.sh` already created a Deployment named `search-api` (2 replicas, image `nginx:1.25-alpine`)
in namespace `q104-30-diagnose-wrong-container-name-in-set-image`. A teammate asked you to update
its image to `nginx:1.26-alpine` by running:

```
kubectl set image deployment/search-api webapp=nginx:1.26-alpine -n q104-30-diagnose-wrong-container-name-in-set-image
```

That command fails with an error, because `webapp` is not this Deployment's actual container name
(it's a guess, copied from a different service).

Inspect the Deployment to find its real container name, then update **that** container's image to
`nginx:1.26-alpine`, and confirm the Deployment reaches 2 ready replicas again.

## Hint

Search kubernetes.io/docs for **"kubectl set image"** - and combine it with
`kubectl get deployment ... -o jsonpath='{.spec.template.spec.containers[*].name}'` to list a
Deployment's actual container names before guessing one.
