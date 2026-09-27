# q104-30: Update a Deployment image using the real container name

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-30-diagnose-wrong-container-name-in-set-image`

A Deployment named `search-api` already exists in namespace
`q104-30-diagnose-wrong-container-name-in-set-image` with 2 replicas of image
`nginx:1.25-alpine`. A teammate tried to bump the image with:

```
kubectl set image deployment/search-api webapp=nginx:1.26-alpine -n q104-30-diagnose-wrong-container-name-in-set-image
```

That command failed. Inspect the Deployment, find the container name that actually exists, and
update that container's image to `nginx:1.26-alpine`. Confirm the Deployment reaches 2 ready
replicas again.

## Hint

Search kubernetes.io/docs for **"kubectl set image"** - combine it with
`kubectl get deployment ... -o jsonpath='{.spec.template.spec.containers[*].name}'` to list a
Deployment's actual container names before guessing one. The `container=image` argument must
match a real container name on the pod template.
