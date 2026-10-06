# q115-01: From docker run to a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q115-01-docker-run-to-pod-yaml`

Team Vulcan has run their cache with this command for years:

```sh
docker run -d --name cache \
  -e MODE=fast -e MAX_ITEMS=64 \
  -p 9090:8080 \
  -v cache-data:/data \
  --user 101 --memory 128m --cpus 0.5 \
  --restart unless-stopped \
  nginxinc/nginx-unprivileged:1.27-alpine
```

- Create the equivalent Pod `cache` in this namespace - nothing is pre-seeded besides the
  namespace. Use pod-lifetime storage for `/data`.
- `(ungraded, Task narrative only)` reach it from your own machine on local port 9090 with
  `kubectl port-forward`, without creating a Service.

## Hint

Search kubernetes.io/docs for **"Define Environment Variables for a Container"**,
**"emptyDir"**, and the Pod `securityContext` field reference. Map each `docker run` flag to its
Pod equivalent: `-e` to `env`, `-v` to a volume + mount, `--user` to `securityContext.runAsUser`,
`--memory`/`--cpus` to `resources.limits`, `-p`'s container side to `containerPort`, and
`--restart unless-stopped` to the closest real `restartPolicy`.
