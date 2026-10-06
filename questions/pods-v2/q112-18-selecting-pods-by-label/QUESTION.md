# q112-18: Selecting Pods by label

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-18-selecting-pods-by-label`

This namespace has six Pods (seeded) with mixed labels. Some housekeeping is needed:

- In **one command**, add label `release=r42` to every Pod with `env=prod` whose `tier` is `web`
  or `api`.
- Annotate Pod `web-1` with `owner=team-iapetus`.
- In **one command**, remove the `temp` label from every Pod that has it.
- `(ungraded)` Before you query, predict whether `batch-1` - which has no `tier` label at all -
  matches a `tier!=db` selector. Then run `kubectl get pods -l 'env=prod,tier!=db'` yourself and
  check your prediction.

## Hint

Search kubernetes.io/docs for **"Label selectors"**. Selectors support `in (a,b)`, `!=`, and a
bare key that matches "has this label at all". A trailing `-` on a `kubectl label` key removes
that label.
