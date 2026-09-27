# q110-12: Record the Playlist with the highest trackCount

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-12-crd-jsonpath-field`

A CRD (kind `Playlist`, plural `playlists`, group `music.clusterdrill.io/v1`) is already
registered, and three `Playlist` instances exist in namespace
`q110-12-crd-jsonpath-field`: `road-trip`, `focus`, and `workout`, each with a different
`spec.trackCount`.

Find the name of the Playlist with the highest `spec.trackCount`, then create a ConfigMap
named `inspected-playlist` in the same namespace with a key `winner` set to that Playlist's
name. Prefer a single `kubectl get ... -o jsonpath` command over a scripting loop.

## Hint

Search kubernetes.io/docs for **"jsonpath support"** - the kubectl JSONPath reference page
shows how to project a field across every item in a list with `{.items[*].fieldName}`, which is
what `kubectl get playlists -o jsonpath=...` needs to read `spec.trackCount` from all three at
once.
