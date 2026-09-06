# q110-09: Satisfy a CRD's required field and enum constraint

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-09-crd-validation-required`

`setup.sh` registered a CRD named `ticketrequests.support.clusterdrill.io` (kind
`TicketRequest`, group `support.clusterdrill.io/v1`, namespaced). Its schema makes
`spec.priority` a **required** string restricted to one of `low`, `medium`, or `high` - the API
server rejects anything else.

Create a `TicketRequest` named `outage-1` in namespace `q110-09-crd-validation-required` with
`spec.priority` set to `high`.

## Hint

Search kubernetes.io/docs for **"validation schema publishing"** - the CRD structural schemas
page covers `required` and `enum` in `openAPIV3Schema`, and what happens when a submitted
object violates either one.

