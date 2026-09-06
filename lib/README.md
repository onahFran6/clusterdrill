# practice-bank/lib

Shared shell libraries used across the practice bank's tooling and
per-question `setup.sh`/`check.sh` scripts. Nothing here should assume a
specific cluster target - any dedicated disposable cluster that passes
`clusterdrill doctor`'s preflight is supported, not just the local
Minikube appliance.

## `bootstrap-minikube.sh`

Gets a local minikube cluster ready for authoring and running
`verify-question.sh` against. This is the day-to-day dev target for all
M1 content tickets.

```bash
practice-bank/lib/bootstrap-minikube.sh
```

Idempotent - safe to re-run against an already-running cluster.
Starts (or reuses) a `clusterdrill` minikube profile with 2 CPUs / 4GB memory by default.
Enables the `ingress` and `metrics-server` addons when needed.
Retries once if an enable call fails, such as during a slow first-time image pull.
Confirms `kubectl` is pointed at the profile and prints `kubectl get nodes`.
Override the profile name, CPU/memory, driver, or Kubernetes version via environment variables.
See the script header for variable names and details.

Requires `minikube` and `kubectl` to already be installed - it does not
install either, and exits with a clear error if one is missing.

A self-test with faked binaries lives in `tests/bootstrap-minikube_test.sh`.
Run it with `tests/bootstrap-minikube_test.sh`.
