# q103-28: Combine an equality clause and a set-based clause in one selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-28-combined-matchlabels-matchexpressions-selector`

`setup.sh` already created seven pods in namespace
`q103-28-combined-matchlabels-matchexpressions-selector`, each carrying a `tier` label and an `env`
label:

- `worker-staging` - `tier=worker`, `env=staging`
- `worker-prod` - `tier=worker`, `env=prod`
- `worker-prod-2` - `tier=worker`, `env=prod`
- `worker-dev` - `tier=worker`, `env=dev`
- `worker-test` - `tier=worker`, `env=test`
- `web-staging` - `tier=web`, `env=staging`
- `web-prod` - `tier=web`, `env=prod`

You need to find the pods that are running the `worker` tier in an environment that has already
been promoted past `dev` - specifically, every pod that is **both** `tier=worker` **and** has an
`env` of either `staging` or `prod`.

Using a **single** `kubectl get pods` command whose selector combines an equality-based
requirement (`tier=worker`) with a set-based requirement (`env in (staging,prod)`) in the same
`-l`/`--selector` expression, find exactly that set of pods. Then label each of those pods (and
only those pods) with `promote=true`. Do not add `promote=true` to any pod that fails either
requirement, and do not change any pod's existing `tier` or `env` label.

## Hint

Search kubernetes.io/docs for **"label selectors set-based requirement"** - the Labels and
Selectors concept page shows that a comma between requirements always means AND, whether both
sides are equality-based, both are set-based, or - as here - one of each.
