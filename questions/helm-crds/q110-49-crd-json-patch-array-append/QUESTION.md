# q110-49-crd-json-patch-array-append: Append to a custom resource's array field without clobbering it

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-49-crd-json-patch-array-append`

A CustomResourceDefinition `playlists.media.clusterdrill.io` (kind `Playlist`, plural
`playlists`, group `media.clusterdrill.io/v1`, namespaced) is installed with a `spec.tracks`
array field. Instance `mix1` in this namespace has `spec.tracks: ["song-a", "song-b"]`.

Append `"song-c"` to the end of `mix1`'s `spec.tracks`, preserving the existing two entries in
order. A merge-style patch that replaces the whole array is not acceptable - the final list must
be exactly `["song-a", "song-b", "song-c"]`.

## Hint

Search kubernetes.io/docs for **"JSON Patch" "append"** - the JSON Patch RFC (linked from
kubectl's patch documentation) defines the special `-` array index as "one past the last
element," letting an `add` operation append to an array's end without knowing its current
length, and explains why a merge patch (`--type merge`) cannot do the same for arrays - it
replaces them entirely.
