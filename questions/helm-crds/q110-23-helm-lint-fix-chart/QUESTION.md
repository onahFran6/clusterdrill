# q110-23: Fix a Helm chart that fails helm lint before installing

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-23-helm-lint-fix-chart`

`setup.sh` staged a broken local Helm chart named `checkup` on disk at
`questions/helm-crds/q110-23-helm-lint-fix-chart/chart` (relative to the `practice-bank/`
directory). Two problems make it broken:

1. `chart/Chart.yaml` is missing the required `version` field.
2. `chart/templates/deployment.yaml` references `.Values.image`, but
   `chart/values.yaml` only defines `img: nginx:1.25-alpine` - the keys don't match, so the
   rendered Deployment's container image is empty.

Running `helm lint questions/helm-crds/q110-23-helm-lint-fix-chart/chart` currently reports
an error.

Fix the chart files on disk so that `helm lint` on that chart passes with no errors:

- Add a non-empty `version:` field to `Chart.yaml` (e.g. `0.1.0`).
- Make the values key and the template reference agree with each other, so the chart
  renders `nginx:1.25-alpine` as the container image - either rename `values.yaml`'s key to
  `image`, or change the template to reference `.Values.img`.

Then install the fixed chart into namespace `q110-23-helm-lint-fix-chart` as release
`fixed`, using the chart's own defaults (do not pass `--set`).

## Hint

Search kubernetes.io/docs for **"helm lint"** - the Helm chart template guide covers
authoring `Chart.yaml`'s required fields and how `.Values` lookups in templates must match
the keys actually defined in `values.yaml`.
