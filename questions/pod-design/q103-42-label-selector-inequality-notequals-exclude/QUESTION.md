# q103-42: Exclude pods by label value using an inequality selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-42-label-selector-inequality-notequals-exclude`

`setup.sh` already created five pods in namespace
`q103-42-label-selector-inequality-notequals-exclude`, each carrying an `env` label:

- `svc-dev` - `env=dev`
- `svc-staging` - `env=staging`
- `svc-prod-1` - `env=prod`
- `svc-prod-2` - `env=prod`
- `svc-canary` - `env=canary`

A maintenance window is starting, and every pod **except** the production ones needs to be marked
for it - production stays untouched. Rather than listing every non-prod environment value by hand
(`dev`, `staging`, `canary`, and whatever else might exist), use the equality-based **inequality**
operator so the selector automatically covers any environment that isn't `prod`, present or
future.

Using a **single** `kubectl label pods` command whose selector is `env!=prod`, add the label
`maintenance-window=true` to exactly `svc-dev`, `svc-staging`, and `svc-canary`. Do not add that
label to either `svc-prod-1` or `svc-prod-2`, and do not change any pod's existing `env` label.

## Hint

Search kubernetes.io/docs for **"label selectors equality-based requirement"** - the Labels and
Selectors concept page shows that equality-based requirements support both `=`/`==` and `!=`, and
that `!=` matches every value except the one given.
