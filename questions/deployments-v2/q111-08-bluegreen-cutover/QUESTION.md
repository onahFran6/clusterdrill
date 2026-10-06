# q111-08: Blue/green without leaking traffic

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-08-bluegreen-cutover`

Team Juno serves its portal through Service `portal` (seeded, selector `app=portal`, port 80),
backed by Deployment `portal-blue` (seeded, 3 replicas, pod labels `app=portal, color=blue`).
Their next release must be fully running and checked before a single customer request reaches
it.

- Create Deployment `portal-green`, a copy of blue with pod label `color: green` and image
  `nginx:1.27`. No customer traffic may reach green until the cut-over.
- Cut Service `portal` over to green only.
- Keep `portal-blue` around for rollback, with zero running pods.
- Confirm the Service's final selector once the cut-over is complete.

## Hint

Search kubernetes.io/docs for **"service selector label"**. Read the Service's selector before
creating anything: with only `app=portal`, would green pods be picked up as soon as they
started? Pin the Service to blue explicitly first, then create green, then cut over, then scale
blue down last - order matters here more than any single command.
