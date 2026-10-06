# q112-03: One Secret, two ways in

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-03-secret-two-ways-in`

A database client in this namespace needs credentials. Secret `db-creds` (keys `user` and
`password`) is already seeded here.

- Create Pod `db-client` (`busybox:1.36`, running `sleep 3600`) with env var `DB_USER` sourced
  from the Secret's `user` key.
- Only the `password` key may reach the Pod, and only as a file: `/etc/db/pass.txt`, mode `0400`,
  mounted read-only.

## Hint

Search kubernetes.io/docs for **"secretKeyRef"** and **"Projecting Secret keys to specific file
paths"**. A Secret volume's `items` list chooses which keys show up and lets you rename each
one's path. `secretKeyRef` under `env` picks a single key for an env var; `envFrom`/`secretRef`
would import the whole Secret instead, which is not what this task wants.
