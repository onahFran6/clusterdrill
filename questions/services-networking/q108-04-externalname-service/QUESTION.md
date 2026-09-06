# q108-04: Alias an external hostname with an ExternalName Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-04-externalname-service`

An application in namespace `q108-04-externalname-service` needs to reach a managed database at
the external hostname `db.internal.example.com`, but the application's config already hardcodes
the in-cluster name `billing-db` and cannot be changed.

Create a Service named `billing-db` in this namespace that maps the in-cluster DNS name
`billing-db.q108-04-externalname-service.svc.cluster.local` to the external hostname
`db.internal.example.com`, without creating any selector, pod, or proxying rule - this Service
type only creates a DNS alias (a CNAME record).

## Hint

Search kubernetes.io/docs for **"ExternalName"** - the Service concept page's ExternalName
section shows the exact `spec.type` and `spec.externalName` fields needed, with no `selector` or
`ports` at all.
