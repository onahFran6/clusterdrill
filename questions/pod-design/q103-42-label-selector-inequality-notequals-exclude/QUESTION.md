# q103-42: Exclude pods by label value using an inequality selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-42-label-selector-inequality-notequals-exclude`

Atlas Scientific Computing is about to take its shared compute fleet down for maintenance, but
production workloads must keep running undisturbed. Five pods already exist in namespace
`q103-42-label-selector-inequality-notequals-exclude`, each with an `env` label:

- `svc-dev` - `env=dev`
- `svc-staging` - `env=staging`
- `svc-prod-1` - `env=prod`
- `svc-prod-2` - `env=prod`
- `svc-canary` - `env=canary`

In one `kubectl label pods` command driven by a label selector (not by naming each pod), add
`maintenance-window=true` to every pod whose `env` is not `prod` - that's exactly `svc-dev`,
`svc-staging`, and `svc-canary`. Do not add that label to `svc-prod-1` or `svc-prod-2`, and do
not change any pod's existing `env` label.

## Hint

Search kubernetes.io/docs for **"label selectors equality-based requirement"** - the Labels and
Selectors concept page shows that equality-based requirements support both `=`/`==` and `!=`, and
that `!=` matches every value except the one given, including values that are not listed in the
task.
