# q111-09: Convert a Pod into a Deployment

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-09-pod-to-deployment-conversion`

Team Pluto runs a single bare Pod, `holy-api` (seeded, a `busybox:1.36` sleep loop, env
`CACHE_KEY=prod-cache`). When its node went down last week, nothing recreated it.

- Convert it into Deployment `holy-api` with **3** replicas, keeping the container exactly as it
  is.
- The container must not be privileged and must not allow privilege escalation.
- Pods must run as ServiceAccount `holy-sa`, which doesn't exist yet.
- Delete the original bare Pod.

## Hint

Search kubernetes.io/docs for **"Configure a Security Context for a Pod or Container"**. Scaffold
a Deployment with `--dry-run=client`, then move the Pod's own `spec` fields under
`template.spec` and its labels under `template.metadata.labels`. `allowPrivilegeEscalation` and
`privileged` live at the container level, not the pod level - where does `serviceAccountName`
go instead? Create the ServiceAccount before the Deployment, or the ReplicaSet creates zero pods.
