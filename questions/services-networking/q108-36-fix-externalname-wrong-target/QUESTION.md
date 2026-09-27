# q108-36: Fix an ExternalName Service pointing at the wrong host

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-36-fix-externalname-wrong-target`

A Service named `legacy-api-svc` of type `ExternalName` already exists in namespace
`q108-36-fix-externalname-wrong-target`. It is supposed to let in-cluster clients reach
`api.internal.example.com` by resolving `legacy-api-svc`'s cluster-local DNS name, but
`spec.externalName` is set to a different hostname.

Fix the Service so its `spec.externalName` is exactly `api.internal.example.com`. Do not change
the Service's `type`, `name`, or any other field.

## Hint

Search kubernetes.io/docs for **"ExternalName"** - the Service concept page's ExternalName
section shows `spec.externalName` as the field that maps the Service's DNS name to an external
hostname via a CNAME record. Inspect the current value before you change it.
