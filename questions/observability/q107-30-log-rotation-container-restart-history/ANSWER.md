# q107-30-log-rotation-container-restart-history: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-states

```sh
mkdir -p "$HOME/practice-work/q107-30-log-rotation-container-restart-history"

EXIT_CODE=$(kubectl get pod flaky-migrator -n q107-30-log-rotation-container-restart-history \
  -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}')

LAST_LOG=$(kubectl logs flaky-migrator -n q107-30-log-rotation-container-restart-history --previous | tail -1)

cat > "$HOME/practice-work/q107-30-log-rotation-container-restart-history/migrator-diagnosis.txt" <<EOF
exit_code=$EXIT_CODE
last_log=$LAST_LOG
EOF
```
