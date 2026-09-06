# q108-19: Diagnose and fix a Service with zero endpoints

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-19-fix-broken-service-selector`

`setup.sh` already created a Deployment named `notification-worker` (image `httpd:2.4-alpine`, 2
replicas, container port `80`) in namespace `q108-19-fix-broken-service-selector`, along with a
Service named `notification-worker-svc` that is supposed to front it. A support ticket reports
that the Service resolves but every request times out.

Investigate why `notification-worker-svc` has no ready endpoints even though the Deployment's pods
are `Running`, then fix the root cause **on the Service** (do not change the Deployment's
pod-template labels) so that `kubectl get endpoints notification-worker-svc` lists the pods' IPs.

## Hint

Search kubernetes.io/docs for **"Service"** - the Service concept page's "How Services work"
section explains that a Service's `spec.selector` must exactly match the pod template's labels for
Endpoints/EndpointSlices to be populated at all; a typo or mismatched value silently yields zero
endpoints instead of an error.
