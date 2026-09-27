# q110-09: Create a valid TicketRequest

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-09-crd-validation-required`

A CRD named `ticketrequests.support.clusterdrill.io` (kind `TicketRequest`, group
`support.clusterdrill.io/v1`, namespaced) is already registered. Its schema requires
`spec.priority` to be one of `low`, `medium`, or `high`.

Create a `TicketRequest` named `outage-1` in namespace `q110-09-crd-validation-required` with
`spec.priority` set to `high`.

## Hint

Search kubernetes.io/docs for **"validation schema publishing"** - the CRD structural schemas
page covers `required` and `enum` in `openAPIV3Schema`, and what happens when a submitted
object violates either one (the API server rejects it).
