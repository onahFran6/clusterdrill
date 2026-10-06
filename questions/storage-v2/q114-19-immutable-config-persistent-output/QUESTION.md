# q114-19: Immutable config, persistent output

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-19-immutable-config-persistent-output`

Deployment `render` reads its template from immutable ConfigMap `render-v1` (key `greeting`) and
appends one rendered line per run to `/out/history` on claim `render-out`.

- `(ungraded)` Try editing `render-v1`'s `greeting` from `hello` to `bonjour` directly, and read
  the error.
- Ship the change properly: create a **new** immutable ConfigMap `render-v2` (`greeting: bonjour`)
  and repoint `render`'s volume at it, triggering a fresh rollout that appends a second line with
  the new greeting. Keep the history on the claim.

## Hint

Search kubernetes.io/docs for **"immutable ConfigMaps"** on the ConfigMaps concept page - an
immutable ConfigMap can only be replaced, never edited in place. Versioned names are the intended
pattern: create the next version, point the Deployment at it, and the template change triggers
the rollout for you.
