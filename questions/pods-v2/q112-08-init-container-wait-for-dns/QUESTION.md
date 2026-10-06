# q112-08: Start only when the database exists

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-08-init-container-wait-for-dns`

This namespace's `api` Pod must never start before its database Service exists.

- Create Pod `api` (`nginx:1.27`) with an init container `wait-db` (`busybox:1.36`) that loops
  until the DNS name `db.<this namespace>.svc.cluster.local` resolves - build that FQDN against
  this namespace's own real name (shown in the **Namespace** field above), not a made-up one.
- `(ungraded)` Before the Service exists, check the Pod's STATUS column - what does it show while
  an init container is still running?
- Create ClusterIP Service `db` on TCP port **5432** (no backing pods needed) and confirm `api`
  becomes Running.

## Hint

Search kubernetes.io/docs for **"Init Containers"**. Write the loop as
`until <check>; do ...; done`. Does a Service with no endpoints still get a DNS record? There is
an imperative command (`kubectl create service clusterip`) that creates a Service without any
Deployment behind it.
