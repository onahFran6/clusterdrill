# q113-02: A fixed NodePort

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-02-fixed-nodeport`

Team Vega's external load balancer is hard-wired to port **30090** on every node. Deployment
`web` (`nginx:1.27`, 2 replicas) already exists.

- Create Service `web-np` for Deployment `web` so it is reachable on port 30090 of every node,
  and on port 80 inside the cluster.

## Hint

Search kubernetes.io/docs for **"NodePort" Service type** - `kubectl expose` cannot set a
specific node port, so generate YAML with `--dry-run=client -o yaml` and add it by hand. The
Service concept page states which range a node port must fall in.
