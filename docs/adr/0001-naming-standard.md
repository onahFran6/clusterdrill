# ADR 0001: ClusterDrill naming standard

**Status:** Accepted

## Context

ClusterDrill has not yet had a public release. This is the first point at
which its names become compatibility surfaces: once a namespace, CRD group,
environment variable, or CLI flag ships in a release, changing it breaks
anyone who has already installed it. This ADR freezes those names before
that happens, so there is no migration debt to carry into v1.

Two different kinds of names are in play, and this project treats them
differently on purpose:

- **Operational identifiers** - namespaces, CRD groups, resource names,
  labels, annotations, environment variables, CLI flags, filesystem paths,
  and browser storage keys. These are read by scripts, tooling, and other
  people's automation. They must be descriptive and boring: a stranger
  should be able to guess what `CLUSTERDRILL_SESSION_SECRET` does without
  reading a naming guide.
- **Human-facing names** - release codenames, learning-track names,
  optional documentation section titles, and similar. These are read by
  people, not parsed by tools, and can afford to be memorable.

## Decision

### Product and repositories

`ClusterDrill` is the product name. `clusterdrill` is the repository,
Python package, container image repository, and CLI command name.
`clusterdrill-lab` is the name of the separate repository that provisions a
disposable learning cluster and installs a released ClusterDrill artifact.

### Operational identifiers are functional, descriptive, and lowercase

| Surface | Standard | Example |
| --- | --- | --- |
| Kubernetes namespace | Functional RFC 1123 DNS label. | `clusterdrill-system` |
| Kubernetes workload names | Functional and consistently prefixed. | `clusterdrill-web` |
| Standard Kubernetes labels | The documented `app.kubernetes.io/*` set. | `app.kubernetes.io/name: clusterdrill` |
| Environment variables | Stable, uppercase product prefix. | `CLUSTERDRILL_SESSION_SECRET` |
| Local filesystem and browser storage | Stable lowercase product prefix. | `.clusterdrill/`, `clusterdrill-layout-columns` |
| Default Minikube profile | `clusterdrill`. | `clusterdrill` |
| Helm chart and default release name | `clusterdrill`. | `clusterdrill` |

Kubernetes object and namespace names follow the standard [Kubernetes
object-name DNS constraints](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/).
Labels use the recommended [`app.kubernetes.io/*` common-labels
convention](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
wherever applicable.

**Greek-inspired mythology names (for example `praxis`) are never used for
namespaces, CRD groups, environment variables, labels, filesystem paths, or
command flags.** Those are long-lived compatibility surfaces that must
explain themselves without a naming guide. The Greek-inspired theme is
reserved for optional, human-facing names only - a release codename or a
learning-track title, never anything a script or another operator's
automation has to parse or type.

### CRD groups and custom label/annotation prefixes require a confirmed, owned domain

A Kubernetes CRD group and any custom label or annotation prefix must come
from a domain the project owner actually controls, verified before it is
assigned - never an unverified or merely-available domain string, and never
reused from an earlier private, unpublished placeholder.

**No such domain is confirmed for the v1 release.** Until one is confirmed:

- No new CRD may be published under a project-owned API group.
- No new label or annotation may use a project-owned domain prefix.
- Any existing CRD or label that currently uses an unverified placeholder
  domain must be redesigned to avoid a project-owned group or prefix before
  it ships publicly - for example, by moving that data out of a CRD and
  into a mechanism that needs no custom API group - rather than carrying
  the placeholder forward into a public release.

A human maintainer confirms domain ownership before any CRD group or custom
prefix is (re)introduced. This ADR does not itself grant that approval.

### Migration behavior

ClusterDrill has not had a public release before this naming standard was
adopted. There is therefore no external installation to migrate and no
backward-compatibility obligation toward any pre-release name. Every
operational identifier in the v1 release is the name defined here from the
start, not a renamed or aliased legacy identifier.

## Consequences

- Every public compatibility surface - namespace, CRD group (once one
  exists), label, annotation, environment variable, CLI flag, filesystem
  path, and browser storage key - has exactly one approved name, defined
  above.
- Renaming any operational identifier after the v1 release is a breaking
  change for existing installs and needs its own migration plan; renaming
  one before v1 ships is free and expected wherever the current source
  still uses a pre-standard name.
- Greek-inspired names stay confined to optional, human-facing surfaces and
  never leak into anything a script or another operator has to type or
  parse.
