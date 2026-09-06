# q110-12: Read a CRD-backed field across instances with jsonpath

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-12-crd-jsonpath-field`

`setup.sh` registered a CRD (kind `Playlist`, plural `playlists`, group
`music.clusterdrill.io/v1`) and created three `Playlist` instances in namespace
`q110-12-crd-jsonpath-field`: `road-trip`, `focus`, and `workout`, each with a different
`spec.trackCount`.

Using `kubectl get playlists -o jsonpath` (a single command, no scripting loop), find the name
of the Playlist with the **highest** `spec.trackCount`, then record your answer by creating a
ConfigMap named `inspected-playlist` in the same namespace with a key `winner` set to that
Playlist's name.

## Hint

Search kubernetes.io/docs for **"jsonpath support"** - the kubectl JSONPath reference page
shows how to project a field across every item in a list with `{.items[*].fieldName}`, which is
what `kubectl get playlists -o jsonpath=...` needs to read `spec.trackCount` from all three at
once.

