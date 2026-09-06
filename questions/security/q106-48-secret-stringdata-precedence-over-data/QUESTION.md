# q106-48: Update one Secret key using stringData without disturbing the rest

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-48-secret-stringdata-precedence-over-data`

`setup.sh` already created a Secret named `app-secret` with two keys in `data`: `API_TOKEN`
(`token-abc`) and `PASSWORD` (`stale-pw`). Update `PASSWORD` to `fresh-pw` using a `stringData`
patch (plaintext, not manually base64-encoded) - without touching `API_TOKEN`, which must keep its
original value.

## Hint

Search kubernetes.io/docs for **"restriction precedence rules for stringData"** - the Secrets
concept page explains that `stringData` is write-only and, for any key present in both `data` and
`stringData` on the same request, the API server keeps the `stringData` value.
