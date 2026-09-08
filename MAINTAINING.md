# Maintaining ClusterDrill

This is a plain-English guide to the three GitHub Actions workflows in
`.github/workflows/` and how they fit together. If you've ever looked at
the Actions tab and weren't sure why something ran, didn't run, or
"failed" for a reason that turned out not to matter - read this first.

## The three workflows, in one sentence each

- **`pr-quality-gate.yml`** - the pre-merge check for regular code/content
  changes: lints, unit tests, builds and scans the container image, and
  runs real install smoke tests (raw manifest and Helm) against a
  disposable Minikube cluster spun up fresh inside the CI job itself.
  Runs on every pull request and every push to `main`.
- **`release-please.yml`** - decides *when* a new version exists and
  *what number* it gets, purely from your commit messages. It never
  builds or publishes anything itself.
- **`release-image.yml`** - once a version has been decided, actually
  builds and publishes it: the container image, the Helm chart, and the
  Python wheel.

## What "release-please" actually is

`release-please` is [an open-source tool from
Google](https://github.com/googleapis/release-please) that a lot of
projects use, which is why the workflow is named after it rather than
something clusterdrill-specific - if you ever need to look up how it
behaves, search for "release-please", not "clusterdrill release-please".
What it does, concretely:

1. It reads every commit merged to `main` since the last release.
2. Commits must use a [Conventional
   Commits](https://www.conventionalcommits.org/) prefix - `feat:`,
   `fix:`, `chore:`, `docs:`, etc. (see `AGENTS.md`'s "Commits & PRs"
   section). A `feat:` bumps the minor version, a `fix:` bumps the
   patch version, anything else doesn't bump the version at all.
3. It maintains **one standing pull request** (branch
   `release-please--branches--main`) that always reflects "here's what
   the next release would look like" - title like `chore(main): release
   0.1.4`, with the version bump and `CHANGELOG.md` entry already
   written. Every new commit to `main` updates this same PR rather than
   opening a new one.
4. **You merging that PR is the actual "cut a release" action.** The
   moment it merges, `release-please-action` tags the merge commit
   (`v0.1.4`), creates a real GitHub Release for it, and - the important
   bit - kicks off `release-image.yml` to actually build and publish
   that version (see "How release-please hands off to release-image.yml"
   below for why that handoff needs an extra step instead of "just
   happening").

So: **nothing gets published until you merge that one PR.** It's safe to
leave it open indefinitely while more commits land - it just keeps
updating itself.

## What `release-image.yml` does once triggered

Given a tag (e.g. `v0.1.4`), in order:

1. Builds the container image for both `linux/amd64` and `linux/arm64`
   (using QEMU emulation for the arm64 leg, since GitHub's runners are
   amd64-only) and pushes it to `docker.io/w00dson/clusterdrill:0.1.4`.
2. Packages the Helm chart (`clusterdrill/helm/clusterdrill-chart/`) with
   that exact image baked in as the default, and pushes it to
   `oci://registry-1.docker.io/w00dson/clusterdrill-chart:0.1.4`.
3. Builds the Python wheel and attaches it to the `v0.1.4` GitHub
   Release.
4. Opens a small PR against `main` recording the real image digest into
   `clusterdrill/release_manifest.json` and
   `clusterdrill/helm/clusterdrill-chart/values.yaml` - this is what lets
   `clusterdrill local install` (no `--image` flag) and a plain `helm
   install` of the published chart resolve the right image automatically
   for that version, from here on.

Steps 1-3 are "publish the artifacts" - once they're done, `v0.1.4` is
really live on Docker Hub and GitHub Releases, nothing else is needed for
someone to install it by version number. Step 4 is bookkeeping: it makes
the *next* `git clone` of this repo agree with what's actually published,
and needs a human to merge it (see below for why it's a PR, not a direct
commit).

## A GitHub Actions restriction you'll see mentioned twice - understand it once

**When a GitHub Actions workflow uses the default `GITHUB_TOKEN` to push a
tag or open a pull request, that action does not trigger any other
workflow.** This is a deliberate, documented GitHub safeguard against
infinite workflow-triggering loops. `workflow_dispatch` (a manually- or
programmatically-requested run) is the one documented exception.

This shows up in two places here:

1. **`release-please.yml` → `release-image.yml`.** When
   `release-please-action` tags a release, that tag-push can't trigger
   `release-image.yml`'s own `on: push: tags` the normal way. So
   `release-image.yml` doesn't listen for tag pushes at all - it only
   accepts `workflow_dispatch` with an explicit `tag` input, and
   `release-please.yml` calls `gh workflow run release-image.yml -f
   tag=<tag>` itself right after a release is created, as its own
   explicit step.
2. **The manifest-update PR never gets a real `pr-quality-gate.yml` run.**
   Step 4 above opens its PR using the same default `GITHUB_TOKEN`, so
   GitHub won't run `pr-quality-gate.yml`'s `pull_request` check on it
   either. **This is expected - it will always show as having no CI run,
   and that's not something to debug.** Instead, `release-image.yml`
   validates the digest itself (format, and a real `docker manifest
   inspect` pull check) *before* opening the PR - see the "Validate the
   digest before recording it" step in that workflow. That PR's content
   is narrow and mechanical enough (a digest string, a repository string)
   that this inline check is the real verification; the full
   Minikube/Helm smoke-test suite in `pr-quality-gate.yml` would be
   pointless overkill for it even if it could run.

If you ever see a workflow "not firing" or a PR with no CI check and it
traces back to an automated push/PR-open by `github-actions[bot]`, this
is almost certainly why - check for a `workflow_dispatch` handoff or an
inline validation step before assuming something's newly broken.

## A separate, unrelated reason `helm-install-smoke-test` sometimes skips itself

This one isn't about `GITHUB_TOKEN` - it's about timing. `release-please`'s
own standing release PR bumps `pyproject.toml`'s version *before*
`release-image.yml` has built anything for that version. On that PR (and
briefly on `main` right after it merges, until the follow-up
digest-recording PR lands), no published digest exists yet for the
version that's currently checked out. The Helm chart correctly refuses a
mutable `clusterdrill:dev` fallback, so this job is structurally unable
to pass in that window - not a one-off bug, a permanent, expected
consequence of the version bump happening before the build. Rather than
red-X every release-please PR forever, `pr-quality-gate.yml`'s
`helm-install-smoke-test` job checks for this up front and skips itself
cleanly (with a plain log message) instead of failing. If you see it
skipped rather than passed, that's this - not something to chase.

## Testing the pipeline without touching a real release

`release-image.yml` can be run by hand against any branch with a
throwaway tag, without needing a real GitHub Release to exist:

```sh
gh workflow run release-image.yml --ref dev -f tag=v0.0.0-test1
```

This really builds and pushes the image and chart (so you're testing the
actual mechanics, not a simulation) under that throwaway version string.
It automatically skips the wheel-upload step and the manifest-update PR
if `v0.0.0-test1` doesn't correspond to a real GitHub Release - so a test
run can't leave a stray PR or a bogus `release_manifest.json` entry
behind. Clean up the test tag/image from Docker Hub afterward if you
don't want it cluttering the repository listing.

## Manually backfilling a release

If `release-image.yml` fails or was never triggered for a tag that
already exists (check `gh run list --workflow=release-image.yml`), rerun
it directly:

```sh
gh workflow run release-image.yml --ref main -f tag=v0.1.4
```

Then review and merge the manifest-update PR it opens, same as any other
release.

## Prerequisite: Docker Hub credentials

`release-image.yml` needs `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as
repo secrets to push anything. Check they exist with `gh secret list`;
create a Docker Hub access token and add them with `gh secret set` if
not.
