# q110-49-crd-json-patch-array-append: Append to a custom resource's array field without clobbering it

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-49-crd-json-patch-array-append`

`setup.sh` already registered a CustomResourceDefinition `playlists.media.clusterdrill.io`
(kind `Playlist`, plural `playlists`, group `media.clusterdrill.io/v1`, namespaced) with a
`spec.tracks` array field, and created an instance `mix1` in namespace
`q110-49-crd-json-patch-array-append` with `spec.tracks: ["song-a", "song-b"]`.

Unlike a built-in resource (which supports strategic merge patches that know how to merge list
fields by key), a plain `kubectl patch` against a custom resource is rejected outright - CRDs
only support `application/json-patch+json` (`--type json`), `application/merge-patch+json`
(`--type merge`, which **replaces** the whole array wholesale, losing the existing entries), or
server-side apply.

Append `"song-c"` to the **end** of `mix1`'s `spec.tracks` list, preserving the existing two
entries in their original order, using a JSON Patch `add` operation with the `-` end-of-array
index (`kubectl patch ... --type json -p '[{"op":"add","path":"/spec/tracks/-","value":"song-c"}]'`)
- the only patch type here that can append without needing to first read and resend the entire
array yourself.

## Hint

Search kubernetes.io/docs for **"JSON Patch" "append"** - the JSON Patch RFC (linked from
kubectl's patch documentation) defines the special `-` array index as "one past the last
element," letting an `add` operation append to an array's end without knowing its current
length, and explains why a merge patch (`--type merge`) cannot do the same for arrays - it
replaces them entirely.
