# q101-32-json-patch-remove-env-var-by-index: Remove one environment variable by index with a JSON Patch

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-32-json-patch-remove-env-var-by-index`

In namespace `q101-32-json-patch-remove-env-var-by-index`, a pod named `api-worker` is running a
single container with five environment variables, in this exact order:

- `APP_ENV=production`
- `LOG_LEVEL=info`
- `LEGACY_API_URL=http://old-api.internal:8080`
- `MAX_RETRIES=5`
- `CACHE_TTL=300`

`LEGACY_API_URL` points at a service that was decommissioned last quarter and must be removed
entirely - not blanked out to an empty string, not renamed, gone from the env list. The other
four variables must keep their exact original order, names, and values.

A running pod's `spec.containers[*].env` is immutable - the API server rejects any attempt to
patch it on the live object directly, and rewriting the whole `env` list by hand risks silently
reordering or dropping one of the variables you're supposed to keep untouched. Use a JSON Patch
`remove` operation targeting the exact array index of `LEGACY_API_URL` (`--type=json` with a path
like `/spec/containers/0/env/2`) against a local copy of the pod's manifest, then recreate the pod
from that patched manifest.

End state: pod `api-worker` in this namespace, `Running` and `Ready`, with exactly four
environment variables - `APP_ENV`, `LOG_LEVEL`, `MAX_RETRIES`, `CACHE_TTL` - in that order, each
holding its original value, and no trace of `LEGACY_API_URL` anywhere in the env list.

## Hint

Search kubernetes.io/docs for **"update API objects in place using kubectl patch"** - the
`kubectl patch` page's JSON Patch section shows the `remove` operation syntax for deleting one
element out of an array by its index.
