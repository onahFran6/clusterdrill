# q103-28: Combine an equality clause and a set-based clause in one selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-28-combined-matchlabels-matchexpressions-selector`

Seven pods already exist in namespace `q103-28-combined-matchlabels-matchexpressions-selector`,
each with a `tier` label and an `env` label:

- `worker-staging` - `tier=worker`, `env=staging`
- `worker-prod` - `tier=worker`, `env=prod`
- `worker-prod-2` - `tier=worker`, `env=prod`
- `worker-dev` - `tier=worker`, `env=dev`
- `worker-test` - `tier=worker`, `env=test`
- `web-staging` - `tier=web`, `env=staging`
- `web-prod` - `tier=web`, `env=prod`

Select every pod that is **both** `tier=worker` **and** has `env` of `staging` or `prod`.

Using one selector that combines `tier=worker` with `env in (staging,prod)`, label each matching
pod (and only those pods) with `promote=true`. Do not change any pod's existing `tier` or `env`
label.

## Hint

Search kubernetes.io/docs for **"label selectors set-based requirement"** - the Labels and
Selectors concept page shows that a comma between requirements always means AND, whether both
sides are equality-based, both are set-based, or one of each. `kubectl get pods -l` takes that
expression in one command.
