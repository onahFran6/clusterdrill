# q113-06: A Service that points outside the cluster

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-06-externalname-points-outside`

Team Polaris's apps call `payments`, which is currently hosted outside Kubernetes at
`example.com`. When payments eventually moves into the cluster, the apps' configuration must not
need to change.

- Create Service `payments` that resolves to `example.com` through DNS, with no proxying.

## Hint

Search kubernetes.io/docs for **"ExternalName"** - the Service concept page's ExternalName
section covers the one Service type that is purely a DNS alias. `kubectl create service` has a
subcommand for it. Which DNS record type does it produce?
