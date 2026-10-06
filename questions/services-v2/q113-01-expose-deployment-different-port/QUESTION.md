# q113-01: Expose a Deployment on a different port

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-01-expose-deployment-different-port`

Team Sirius runs Deployment `catalog` (`nginx:1.27`, 3 replicas, container port 80). Other teams
expect to reach it on port **8080**.

- Create ClusterIP Service `catalog-svc` that listens on port 8080 and forwards to the
  containers' port 80.
- From a temporary pod, request the Service by its fully qualified DNS name
  (`<service>.<namespace>.svc.cluster.local`, using this namespace).

## Hint

Search kubernetes.io/docs for **"kubectl expose"** - the Service concept page's example takes the
Service port and the target port as separate flags, and the Service name doesn't have to match
the Deployment's name. A Service's full DNS name follows the pattern
`<service>.<namespace>.svc.<cluster-domain>`.
