# q104-01: Create a Deployment that updates without dropping capacity

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-01-create-deployment-strategy`

Write a Deployment named `checkout` in namespace `q104-01-create-deployment-strategy`
that runs `4` replicas of image `nginx:1.25-alpine` behind the pod label `app=checkout`. The
Deployment must use the `RollingUpdate` strategy type explicitly, with `maxSurge` set to `1` and
`maxUnavailable` set to `0`. Apply it so all 4 replicas become ready.

## Hint

Search kubernetes.io/docs for **"deployment rolling update maxSurge maxUnavailable"** - the
Deployment concept page's "Rolling Update Deployment" section documents both fields under
`spec.strategy.rollingUpdate`. With `maxUnavailable: 0`, a new pod must come up before an old
one is allowed to go down.
