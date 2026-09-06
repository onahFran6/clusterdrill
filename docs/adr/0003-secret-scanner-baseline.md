# ADR 0003: Secret-scanner baseline for learner fixtures

**Status:** Accepted

## Context

The question bank teaches Kubernetes Secret handling, so several fixtures
deliberately create objects that *look* like real credentials: an SSH
private key file for a `kubernetes.io/ssh-auth` Secret, a base64
`dockerconfigjson` auth blob for a registry-pull Secret, and a handful of
plain API-token-shaped strings used as opaque test values. A local scan
with [gitleaks](https://github.com/gitleaks/gitleaks) 8.30.1
(`gitleaks detect --source practice-bank --no-git` - chosen because it
needs no account or API key, unlike this repo's actual CI-enforced
scanner, GitGuardian) found six such findings. This ADR is the review
record: what each finding was, what changed, and why one remains.

## Decision

### Five findings fixed - four by using obviously synthetic values, one by dropping an unused field

Four were arbitrary opaque strings (an env var value, a `stringData` key)
with no structural requirement to look secret-shaped - the exercise only
needs *a* string there, not one with any particular entropy. Each was
replaced with a low-entropy, self-describing placeholder, and every
`check.sh`/`ANSWER.md`/`QUESTION.md` reference to the old value was updated
to match:

| File | Old value | New value |
| --- | --- | --- |
| `questions/configuration/q105-26-diagnose-crashloop-missing-secret-key/setup.sh` | `tok-9f83ac2e1b` | `sample-token-value` |
| `questions/configuration/q105-30-projected-volume-configmap-and-secret/setup.sh` | `s3cr3t-9f2ac71` | `sample-secret-value` |
| `questions/multi-container-pods/q102-32-sidecar-secret-env-typo/setup.sh` | `tok-9f3ac2e1` | `sample-reporter-token` |
| `questions/security/q106-35-secret-from-literal-two-keys/check.sh` (+ `ANSWER.md`, `QUESTION.md`) | `secondary-key-456` | `backup-key-124` |

The fifth, `questions/configuration/q105-32-secret-type-mismatch-imagepull-broken/setup.sh`,
looked at first like it belonged in the "cannot change" category below:
its seed data's `dockerconfigjson` `auth` field is `base64(username:password)`
by definition, and swapping in several different low-entropy passwords
(`sample-pw`, `demo-password`, etc.) still tripped gitleaks's
`generic-api-key` rule every time - the base64 encoding itself carries
enough entropy regardless of content. It was allowlisted on that basis
and the PR opened, at which point **GitGuardian** (this repo's actual
CI-enforced scanner - a separate tool from gitleaks, sharing no
allowlist with it) flagged the same line and failed the check, since
`.gitleaksignore` only suppresses gitleaks, not GitGuardian. Re-reading
`check.sh` at that point showed the fix didn't need an exception at all:
`check.sh` only ever asserts `.auths[...].username`, never `.auth` - and
the candidate's own fix replaces this Secret outright with
`kubectl create secret docker-registry` (which computes its own `auth`
field), so the seed data's `auth` field was pure dead weight. Dropping it
from the seed JSON removed the finding entirely, for both scanners, with
no behavior change to either script.

### One finding kept, documented here, and allowlisted in `.gitleaksignore`

| File | Line | Rule | Justification | Owner | Removal condition |
| --- | --- | --- | --- | --- | --- |
| `questions/configuration/q105-22-secret-ssh-auth-type/setup.sh` | 24 | `private-key` | The question is specifically about creating a `kubernetes.io/ssh-auth` Secret from a private-key file. `gitleaks`'s `private-key` rule matches the literal `-----BEGIN OPENSSH PRIVATE KEY-----` PEM header, not the key body - any syntactically-plausible SSH key file trips it regardless of content. The body here is already a placeholder string, not real key material (see the file's own preceding comment). GitGuardian does not flag this one (its private-key detector requires a plausible key body, which this placeholder isn't), so no GitGuardian-side exception is needed. | practice-bank maintainer (@onahFran6) | Remove this line if the question is rewritten to source the key file from outside `setup.sh` in a way gitleaks doesn't scan (unlikely to ever be worth doing), or if the question is retired. |

## Consequences

- `gitleaks detect --source . --no-git` (run from `practice-bank/`) now
  reports zero unreviewed findings - the one remaining is suppressed by
  `.gitleaksignore`, which points back to this ADR.
- GitGuardian (the CI check that actually gates merges) is clean with no
  exception needed anywhere.
- Anyone extending the bank with a new Secret-handling question should
  default to obviously-synthetic values (dictionary words, not
  hex-looking tokens), check whether every field they're adding is
  actually asserted by `check.sh` before assuming it's required, and only
  reach for a documented scanner exception - a new row in this table plus
  a fingerprint in `.gitleaksignore` - when the exercise truly cannot
  avoid a secret-shaped payload.
- No question's `setup.sh`, `check.sh`, or `ANSWER.md` behavior changed -
  every value swap above kept `check.sh`'s assertions and every visible
  document reference in sync with the new value, and the dropped `auth`
  field was never read by anything.
