# q104-39-set-resources-triggers-rollout: Update container resources with kubectl set resources

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-39-set-resources-triggers-rollout`

`setup.sh` already created a Deployment named `image-worker` (container name `image-worker`,
image `busybox:1.36`, command `sleep 3600`, 2 replicas) in namespace
`q104-39-set-resources-triggers-rollout`, with no resource requests/limits set on the container
(it only has the namespace's default `LimitRange` values), and it is already fully rolled out with
both replicas Ready.

Using `kubectl set resources`, set the `image-worker` container's requests to `cpu=100m,
memory=100Mi` and limits to `cpu=200m, memory=200Mi`. This changes the pod template, so it
triggers a new rollout on its own. Wait until both replicas are Ready again on the updated
template.

## Hint

Search kubernetes.io/docs for **"kubectl set resources"** - the `kubectl set resources` command
reference shows the `--requests` and `--limits` flags for updating a container's resource
requirements directly on a running Deployment.
