# q101-32: Remove one environment variable from a Pod by array index

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-32-json-patch-remove-env-var-by-index`

In namespace `q101-32-json-patch-remove-env-var-by-index`, a Pod named `api-worker` is running a
single container with five environment variables, in this exact order:

- `APP_ENV=production`
- `LOG_LEVEL=info`
- `LEGACY_API_URL=http://old-api.internal:8080`
- `MAX_RETRIES=5`
- `CACHE_TTL=300`

`LEGACY_API_URL` must be removed entirely - not blanked to an empty string, not renamed. The other
four variables must keep their exact original order, names, and values.

A running Pod's `spec.containers[*].env` is immutable. Use a JSON Patch `remove` operation
targeting the array index of `LEGACY_API_URL` against a local copy of the Pod's manifest, then
recreate the Pod from that patched manifest.

End state: Pod `api-worker` in this namespace, `Running` and `Ready`, with exactly four
environment variables - `APP_ENV`, `LOG_LEVEL`, `MAX_RETRIES`, `CACHE_TTL` - in that order, each
holding its original value, and no trace of `LEGACY_API_URL` in the env list.

## Hint

Search kubernetes.io/docs for **"update API objects in place using kubectl patch"** - the
`kubectl patch` page's JSON Patch section shows the `remove` operation syntax for deleting one
element out of an array by its index.
