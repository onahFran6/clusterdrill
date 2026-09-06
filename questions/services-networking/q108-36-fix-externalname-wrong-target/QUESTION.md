# q108-36-fix-externalname-wrong-target: Fix an ExternalName Service pointing at the wrong host

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-36-fix-externalname-wrong-target`

`setup.sh` already created a Service named `legacy-api-svc` of type `ExternalName` in namespace
`q108-36-fix-externalname-wrong-target`. It is supposed to let in-cluster clients reach the
external hostname `api.internal.example.com` simply by resolving `legacy-api-svc`'s cluster-local
DNS name, but whoever created it typed the wrong external hostname:
`old-legacy-host.example.internal`.

Fix the Service so its `spec.externalName` is exactly `api.internal.example.com`. Do not change
the Service's `type`, `name`, or any other field.

## Hint

Search kubernetes.io/docs for **"ExternalName"** - the Service concept page's ExternalName
section shows `spec.externalName` as the single field that maps the Service's DNS name to an
external hostname via a `CNAME` record.
