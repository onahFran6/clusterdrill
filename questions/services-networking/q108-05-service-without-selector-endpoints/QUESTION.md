# q108-05: Point a selector-less Service at an external IP via manual Endpoints

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-05-service-without-selector-endpoints`

A legacy database runs outside the cluster at IP `10.240.0.55` on port `5432`. The platform team
wants in-cluster workloads to reach it through the normal Service DNS name `legacy-db`, exactly
as if it were a regular in-cluster Service, without running an ExternalName CNAME and without any
pod in this namespace serving that traffic.

In namespace `q108-05-service-without-selector-endpoints`:

1. Create a Service named `legacy-db` on port `5432` with **no selector**.
2. Create an Endpoints object also named `legacy-db` (Kubernetes matches Endpoints to a Service by
   matching name) that points at address `10.240.0.55` on port `5432`.

## Hint

Search kubernetes.io/docs for **"Services without selectors"** - the Service concept page shows
that a Service with no selector needs a manually-created Endpoints (or EndpointSlice) object of
the same name to route traffic anywhere.
