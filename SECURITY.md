# Security policy

## Reporting a vulnerability

Please report security vulnerabilities privately, not as a public GitHub
issue - use
[GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
feature on this repository (the "Report a vulnerability" button under the
Security tab). This opens a private draft security advisory visible only to
you and the maintainers, so the issue isn't disclosed before a fix is
available.

Include, if you can:

- What kind of vulnerability it is (e.g. RBAC over-grant, injection, auth
  bypass, path traversal).
- The affected file(s) or component (`web/` app, `clusterdrill` CLI, a
  specific manifest in `clusterdrill/manifests/`).
- Steps to reproduce, or a minimal proof of concept.
- The version or commit you tested against.

## Response expectations

This is a single-maintainer project maintained outside of paid working
hours - please expect an initial acknowledgement within 5 business days,
not immediate response. A fix or mitigation timeline will be communicated
once the report is triaged; there's no fixed SLA, but valid reports are
prioritized over other work.

## Scope

In scope: the `clusterdrill` CLI, the `web/` application, the manifests
under `clusterdrill/manifests/`, and the Dockerfile/build process.

Out of scope: vulnerabilities in third-party dependencies themselves
(report those upstream - see [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)
for what's vendored and where); the learner exercise content under
`questions/` (a deliberately broken Secret or RBAC rule in a *question
fixture* is the point of the exercise, not a vulnerability - see
[`CONTRIBUTING.md`](CONTRIBUTING.md) if you're unsure whether something
you found is a fixture or a real bug).

## Supported versions

This project does not yet have a stable release line with parallel
security-patch support - only the latest published version receives
fixes. This section will be updated if that changes.
