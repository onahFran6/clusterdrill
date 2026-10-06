# q111-11: When maxSurge 0 isn't enough

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-11-recreate-strategy-no-overlap`

Team Ceres's `ledger` Deployment (seeded, `redis:7.2-alpine`, 2 replicas) runs a schema migration
on start-up, and two versions running together corrupt the data. Someone already set
`maxSurge: 0` to prevent that (seeded), but last week's upgrade still corrupted the schema. Short
downtime during upgrades is acceptable.

- Change `ledger` so an upgrade can never run old and new pods at the same time.
- Upgrade it to `redis:7.4-alpine`.
- Be able to explain in one line why `maxSurge: 0` alone didn't prevent the overlap last time.

## Hint

Search kubernetes.io/docs for **"Recreate Deployment"**. Walk through the first step of a
rolling update with 2 replicas, `maxSurge: 0` and `maxUnavailable: 1`: one old pod goes away and
one new pod starts - what's still running right next to it? Switching the strategy's `type` alone
through `kubectl edit` produces a validation error; one whole field has to go with it.
