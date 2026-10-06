# q111-14: Config files, secret files and pod identity

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-14-config-secret-volumes-and-downward-api`

Team Aurora's `gateway` Deployment (seeded, stock `nginx:1.27`, 2 replicas) needs ConfigMap
`gateway-conf` (seeded, key `default.conf`) and Secret `gateway-key` (seeded, key `api.key`)
wired in:

- nginx must use `gateway-conf`'s `default.conf` as `/etc/nginx/conf.d/default.conf`.
- The Secret must appear as files under `/etc/gateway`, read-only, readable only by the file's
  owner.
- Env vars `POD_NAME` and `NODE_NAME` must hold the pod's own name and the node it runs on.

## Hint

Search kubernetes.io/docs for **"Expose Pod Information to Containers Through Environment
Variables"**. "Readable only by the owner" is a file mode - which volume field sets it, and what
octal value is that in YAML? The pod's own name and node come from the Downward API, a different
mechanism from ConfigMap/Secret env vars.
