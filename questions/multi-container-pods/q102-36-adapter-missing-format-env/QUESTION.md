# q102-36: Make an adapter convert CSV instead of passthrough

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-36-adapter-missing-format-env`

A Pod named `format-adapter` already exists in this namespace with two
containers sharing one `emptyDir` volume named `shared`, mounted at `/data`
in both:

- `source` (busybox:1.36) writes a raw CSV line, `sensor-7,42.5`, to
  `/data/raw.csv`.
- `adapter` (busybox:1.36) is supposed to read `/data/raw.csv` and convert it
  into JSON at `/data/out.json`. Its script only does the CSV-to-JSON
  conversion when its own `SOURCE_FORMAT` environment variable equals `csv` -
  otherwise it falls through to a passthrough branch that copies the raw line
  unchanged.

`kubectl get pod format-adapter` shows `2/2 Running`, but `/data/out.json`
contains the raw string `sensor-7,42.5` instead of converted JSON.

Add the environment variable `SOURCE_FORMAT=csv` to `adapter`'s container
spec. A container's `env` list is immutable on a running Pod - delete and
recreate `format-adapter` with the fix applied, keeping every other field
unchanged. Do not change either container's image or command. Once fixed,
`/data/out.json` inside `adapter` must contain exactly:

```
{"name":"sensor-7","value":42.5}
```

## Hint

Search kubernetes.io/docs for **"define environment variables for a
container"** - the Pods task page shows how a container's `env` list sets
values a running process reads to change its own behavior, and what
happens when an expected one is simply missing.
