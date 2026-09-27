# q104-39: Set container resource requests and limits

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-39-set-resources-triggers-rollout`

A Deployment named `image-worker` (container name `image-worker`, image `busybox:1.36`,
command `sleep 3600`, 2 replicas) already exists in namespace
`q104-39-set-resources-triggers-rollout`, with no resource requests/limits set on the container
(it only has the namespace's default `LimitRange` values), and is fully rolled out with both
replicas Ready.

Using `kubectl set resources`, set the `image-worker` container's requests to `cpu=100m,
memory=100Mi` and limits to `cpu=200m, memory=200Mi`. Wait until both replicas are Ready again
on the updated template.

## Hint

Search kubernetes.io/docs for **"kubectl set resources"** - the `kubectl set resources` command
reference shows the `--requests` and `--limits` flags for updating a container's resource
requirements on a running Deployment. Changing those fields updates the pod template and
triggers a new rollout on its own.
