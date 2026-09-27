# q106-48: Update one Secret key using stringData without disturbing the rest

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-48-secret-stringdata-precedence-over-data`

A Secret named `app-secret` already exists with two `data` keys: `API_TOKEN` (`token-abc`) and
`PASSWORD` (`stale-pw`).

Update `PASSWORD` to `fresh-pw` with a `stringData` patch (plaintext, not base64 you encode
yourself). Do not change `API_TOKEN`.

## Hint

Search kubernetes.io/docs for **"restriction precedence rules for stringData"** - the Secrets
concept page explains that `stringData` is write-only. On one request, if a key appears in both
`data` and `stringData`, the API server keeps the `stringData` value. Other keys left out of the
patch stay as they are.
