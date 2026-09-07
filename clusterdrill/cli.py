"""Safe host-side lifecycle commands for the local Minikube appliance."""
from __future__ import annotations

import argparse
import base64
import json
import platform
import re
import secrets
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence

from clusterdrill.release import DEV_IMAGE, installed_version, resolve_default_image

PROFILE = "clusterdrill"
NAMESPACE = "clusterdrill-system"
SERVICE = "clusterdrill"
DEPLOYMENT = "clusterdrill-web"
DEFAULT_CPUS = 4
DEFAULT_MEMORY_GIB = 8
# A future multi-node local-path profile will need more than 1. Today
# `local init` only ever starts a
# single-node Minikube profile, so 1 is the only node count `local doctor`
# can meaningfully check against.
REQUIRED_NODE_COUNT = 1
ROOT = Path(__file__).resolve().parents[1]
# Packaged as clusterdrill package data (pyproject.toml's
# [tool.setuptools.package-data]) rather than resolved relative to ROOT, so
# these are found whether running from a source checkout or a pip-installed
# clusterdrill - unlike WEB_DIR below, which still needs ROOT.
MANIFESTS_DIR = Path(__file__).resolve().parent / "manifests"
MANIFEST = MANIFESTS_DIR / "local-appliance.yaml"
# Optional Helm install path - see helm/clusterdrill-chart/README.md for
# the full contract. Packaged the same way as MANIFESTS_DIR above, not
# resolved relative to ROOT.
HELM_CHART_DIR = Path(__file__).resolve().parent / "helm" / "clusterdrill-chart"
HELM_RELEASE_NAME = "clusterdrill"
HELM_SECRET_NAME = "clusterdrill-web-auth"
# Must match web/users.py's own _USER_LABEL_SELECTOR - this package isn't
# installed alongside web/ (pyproject.toml only packages `clusterdrill`),
# so _has_existing_accounts below queries the label directly via kubectl
# rather than importing that module, the same pattern installed_password()
# already uses for the login Secret itself.
USER_ACCOUNT_LABEL_SELECTOR = "clusterdrill-kind=user"
# The local-path compatibility profile's vendored, digest-pinned
# copy of rancher/local-path-provisioner's own deploy manifest - pinned
# rather than applied via `minikube addons enable storage-provisioner-rancher`
# because that addon tracks a moving, unpinned image tag.
LOCAL_PATH_MANIFEST = MANIFESTS_DIR / "local-path-provisioner.yaml"
LOCAL_PATH_NAMESPACE = "local-path-storage"
STORAGE_PROFILES = ("minikube", "local-path")
DEFAULT_STORAGE_PROFILE = "minikube"
# Fixed lookup table: the only two
# provisioners this appliance ever installs itself. Anything else (a
# cluster with no default class, or a third-party class this appliance
# didn't create) maps to None ("unknown"), which fails closed for any
# question that declares a storage_profile requirement.
PROVISIONER_TO_STORAGE_PROFILE = {
    "k8s.io/minikube-hostpath": "minikube",
    "rancher.io/local-path": "local-path",
}
# The question bank (web/questions.py) is a plain script-style module, not
# an installed package - the running web app itself imports it the same
# way (`from questions import bank`, see web/app.py), by having `web/` on
# sys.path directly rather than as a package. Match that convention here
# instead of reimplementing discover_questions' folder-walking/eligibility
# logic in this file.
WEB_DIR = ROOT / "web"

# kubectl/RBAC checks `local install` (render_manifest/local_install below)
# will need once it actually mutates the cluster - verified here, read-only,
# before that mutation ever runs. Keep in sync with clusterdrill/manifests/local-appliance.yaml's
# resource kinds.
INSTALL_PERMISSIONS: tuple[tuple[str, str, bool], ...] = (
    ("create", "namespaces", False),
    ("create", "clusterroles", False),
    ("create", "clusterrolebindings", False),
    ("create", "serviceaccounts", True),
    ("create", "secrets", True),
    ("create", "deployments", True),
    ("create", "services", True),
)


class CommandError(RuntimeError):
    pass


def run(command: Sequence[str], *, capture: bool = False, check: bool = True) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(list(command), text=True, capture_output=capture, check=check)
    except FileNotFoundError as exc:
        raise CommandError(f"Required command not found: {command[0]}") from exc
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or "").strip()
        raise CommandError(detail or f"Command failed: {' '.join(command)}") from exc


def require_binary(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise CommandError(f"{name} is not installed or not on PATH.")
    return path


def profile_running() -> bool:
    result = run(["minikube", "status", "--profile", PROFILE, "--format", "{{.Host}}"], capture=True, check=False)
    return result.returncode == 0 and result.stdout.strip() == "Running"


def docker_healthy() -> bool:
    return run(["docker", "info", "--format", "{{.ServerVersion}}"], capture=True, check=False).returncode == 0


def docker_capacity() -> tuple[int, int]:
    """Return Docker Desktop's CPU count and a conservative usable GiB value."""
    cpus = int(run(["docker", "info", "--format", "{{.NCPU}}"], capture=True).stdout.strip())
    memory_bytes = int(run(["docker", "info", "--format", "{{.MemTotal}}"], capture=True).stdout.strip())
    # Keep 1 GiB available for Docker's own VM and Kubernetes system pods.
    usable_gib = max(2, (memory_bytes // (1024 ** 3)) - 1)
    return max(1, min(DEFAULT_CPUS, cpus)), min(DEFAULT_MEMORY_GIB, usable_gib)


def profile_context() -> str:
    # A Minikube profile's kubeconfig context has the same name as the
    # profile. Do not use `minikube kubectl` here: that wrapper can wait for
    # an interactive download even when the host kubectl is already present.
    return PROFILE


def profile_kubectl(*args: str, capture: bool = False) -> subprocess.CompletedProcess[str]:
    if not profile_running():
        raise CommandError(
            f"Minikube profile '{PROFILE}' is not running. Run 'clusterdrill local init' first."
        )
    # An explicit context on every call avoids modifying the user's selected
    # kubectl context, including when a command fails halfway through.
    return run(["kubectl", "--context", PROFILE, *args], capture=capture)


def kubectl_client_version() -> str | None:
    result = run(["kubectl", "version", "--client", "--output", "json"], capture=True, check=False)
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout).get("clientVersion", {}).get("gitVersion")
    except json.JSONDecodeError:
        return None


def kubectl_server_version() -> str | None:
    # check=False: this is informational, not a hard prerequisite - a
    # transiently unreachable API server shouldn't crash `local doctor`.
    result = run(["kubectl", "--context", PROFILE, "version", "--output", "json"], capture=True, check=False)
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout).get("serverVersion", {}).get("gitVersion")
    except json.JSONDecodeError:
        return None


def minikube_profile_config() -> dict | None:
    """Return `minikube profile list`'s Config block for PROFILE, or None if
    the profile doesn't exist yet. Works whether or not the profile is
    currently running - a stopped profile still has a recorded driver and
    node configuration."""
    result = run(["minikube", "profile", "list", "--output", "json"], capture=True, check=False)
    if result.returncode != 0:
        return None
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None
    for entry in (*data.get("valid", []), *data.get("invalid", [])):
        if entry.get("Name") == PROFILE:
            return entry.get("Config") or {}
    return None


def default_storage_class() -> dict | None:
    """Read-only: the StorageClass annotated is-default-class=true, or None
    if none is marked default. Used by both `local doctor` (report only)
    and `local_init`'s local-path setup (to find "standard" and demote it) -
    never mutates anything itself."""
    result = run(["kubectl", "--context", PROFILE, "get", "storageclass", "-o", "json"], capture=True, check=False)
    if result.returncode != 0:
        return None
    try:
        items = json.loads(result.stdout).get("items", [])
    except json.JSONDecodeError:
        return None
    for item in items:
        annotations = (item.get("metadata") or {}).get("annotations") or {}
        if annotations.get("storageclass.kubernetes.io/is-default-class") == "true":
            return item
    return None


def apply_local_path_provisioner() -> None:
    """Install the pinned Rancher provisioner
    and make its `local-path` class the cluster default, demoting whichever
    class was previously default (Minikube's `standard`) without deleting
    it - static-PV questions and q109-30 still need `standard` to exist."""
    if not LOCAL_PATH_MANIFEST.is_file():
        raise CommandError(f"Packaged local-path manifest is missing: {LOCAL_PATH_MANIFEST}")
    previous_default = default_storage_class()
    proc = subprocess.run(
        ["kubectl", "--context", PROFILE, "apply", "-f", "-"],
        input=LOCAL_PATH_MANIFEST.read_text(), text=True,
    )
    if proc.returncode:
        raise CommandError("Could not apply the local-path-provisioner manifest.")
    profile_kubectl(
        "rollout", "status", "deployment/local-path-provisioner",
        "--namespace", LOCAL_PATH_NAMESPACE, "--timeout", "3m",
    )
    if previous_default is not None:
        previous_name = previous_default["metadata"]["name"]
        if previous_name != "local-path":
            profile_kubectl(
                "patch", "storageclass", previous_name, "--type", "merge",
                "-p", '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}',
            )
    profile_kubectl(
        "patch", "storageclass", "local-path", "--type", "merge",
        "-p", '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}',
    )


def check_install_permissions() -> list[str]:
    """Read-only `kubectl auth can-i` checks for every verb+resource
    `local_install`'s manifest apply will need, so a permission problem is
    caught by `local doctor` instead of failing partway through a real
    mutation."""
    problems: list[str] = []
    for verb, resource, namespaced in INSTALL_PERMISSIONS:
        command = ["kubectl", "--context", PROFILE, "auth", "can-i", verb, resource]
        if namespaced:
            command += ["--namespace", NAMESPACE]
        result = run(command, capture=True, check=False)
        allowed = result.returncode == 0 and result.stdout.strip().lower().startswith("yes")
        print(f"can-i {verb} {resource}: {'yes' if allowed else 'no'}")
        if not allowed:
            problems.append(
                f"The current kubectl identity cannot '{verb} {resource}'. "
                "'clusterdrill local install' will fail; fix cluster RBAC or Docker Desktop's Kubernetes access first."
            )
    return problems


def _import_question_bank():
    """Import web/questions.py's QuestionBank, or None when it isn't
    available - the normal case for a real pip-installed clusterdrill,
    which doesn't bundle question content: the questions a learner actually
    sees live inside the deployed appliance image, fixed at build/publish
    time, not on the CLI's own host machine. This report only means
    anything when running from a source checkout (a contributor
    sanity-checking content before building an image) - the ~12MB question
    bank is deliberately not bundled into the pip package itself."""
    if not WEB_DIR.is_dir():
        return None
    if str(WEB_DIR) not in sys.path:
        sys.path.insert(0, str(WEB_DIR))
    try:
        import questions
    except ImportError:
        return None
    return questions


def question_bank_report() -> tuple[int, int] | None:
    """Return (excluded_count, incomplete_count) for the bundled question
    bank, or None when the question bank isn't available (see
    _import_question_bank). Uses REQUIRED_NODE_COUNT and
    DEFAULT_STORAGE_PROFILE rather than the live cluster's actual node
    count/storage profile, so this reports the same thing whether or not
    the profile is running yet - a real preflight, not just a
    running-cluster check."""
    questions = _import_question_bank()
    if questions is None:
        return None
    web_bank = questions.QuestionBank()
    web_bank.set_node_count(REQUIRED_NODE_COUNT)
    web_bank.set_storage_profile(DEFAULT_STORAGE_PROFILE)
    return web_bank.excluded_count, questions.count_incomplete_question_dirs(web_bank.questions_dir)


def storage_profile_exclusion_message(active_profile: str | None) -> str | None:
    """How many
    questions require a storage profile other than the one actually
    running, and the precise command to fix it. None if there's nothing to
    report - no mismatched questions, active_profile is unknown (the "no
    default StorageClass" issue in `local doctor`'s own output already
    covers that case; a second,
    more specific message would be misleading since there's no single
    "recreate with X" fix when the class itself is broken/missing), or the
    question bank isn't available (see _import_question_bank)."""
    if active_profile is None:
        return None
    questions = _import_question_bank()
    if questions is None:
        return None

    web_bank = questions.QuestionBank()
    required_profiles = {q.storage_profile for q in web_bank.questions if q.storage_profile is not None}
    required_profiles.discard(active_profile)
    if not required_profiles:
        return None
    # Every question in the current bank that declares a requirement
    # declares the same one profile - report the first (only, today) mismatched one
    # rather than building a multi-profile message nothing yet needs.
    required_profile = sorted(required_profiles)[0]
    count = sum(
        1 for q in web_bank.questions
        if q.storage_profile == required_profile and not q.is_storage_eligible_for(active_profile)
    )
    if count == 0:
        return None
    return (
        f"{count} question(s) require the '{required_profile}' storage profile, but this appliance is "
        f"running '{active_profile}'. Recreate it with: clusterdrill local destroy && clusterdrill local "
        f"init --storage-profile {required_profile}"
    )


def local_doctor(_: argparse.Namespace) -> int:
    issues: list[str] = []
    system = platform.system()
    machine = platform.machine().lower()
    print(f"Host: {system} {machine}")
    if system not in {"Darwin", "Linux"}:
        issues.append("Only macOS and Ubuntu Linux are supported for the local appliance.")
    if machine not in {"arm64", "aarch64", "x86_64", "amd64"}:
        issues.append(f"Unsupported architecture: {machine}")

    for binary in ("docker", "kubectl", "minikube"):
        path = shutil.which(binary)
        print(f"{binary}: {path or 'not found'}")
        if path is None:
            issues.append(f"Install {binary} and re-run this command.")
    if shutil.which("docker") and not docker_healthy():
        issues.append("Docker is installed but not healthy. Start Docker Desktop or Docker Engine first.")
    if shutil.which("minikube"):
        version = run(["minikube", "version", "--short"], capture=True, check=False)
        print(f"Minikube version: {version.stdout.strip() or 'unavailable'}")
    if shutil.which("kubectl"):
        print(f"kubectl client version: {kubectl_client_version() or 'unavailable'}")

    profile_config = minikube_profile_config() if shutil.which("minikube") else None
    if profile_config is not None:
        driver = profile_config.get("Driver")
        print(f"Profile driver: {driver or 'unknown'}")
        if driver != "docker":
            issues.append(
                f"Profile '{PROFILE}' uses the '{driver}' driver, not 'docker'. "
                "Run 'clusterdrill local destroy' then 'clusterdrill local init' to recreate it."
            )
        configured_nodes = len(profile_config.get("Nodes") or [])
        print(f"Profile configured node count: {configured_nodes}")
        if configured_nodes < REQUIRED_NODE_COUNT:
            issues.append(
                f"Profile '{PROFILE}' is configured with {configured_nodes} node(s), fewer than the "
                f"required {REQUIRED_NODE_COUNT}. Run 'clusterdrill local destroy' then 'clusterdrill local init' "
                "to recreate it."
            )

    if shutil.which("docker") and docker_healthy():
        cpus, memory_gib = docker_capacity()
        print(f"Docker capacity: {cpus} CPUs, {memory_gib} GiB RAM")

    running = shutil.which("minikube") is not None and profile_running()
    print(f"Profile '{PROFILE}': {'running' if running else 'not created or stopped'}")
    if running:
        context = profile_context()
        nodes = profile_kubectl("get", "nodes", "--no-headers", capture=True).stdout.splitlines()
        print(f"Profile context: {context}")
        print(f"Node count: {len(nodes)}")
        storage_class = default_storage_class()
        active_storage_profile: str | None = None
        if storage_class is None:
            print("Default StorageClass: none marked default")
            print("Storage provisioner: unknown")
            print("Storage profile: unknown")
            issues.append(
                "No StorageClass is marked as the cluster default. Dynamic provisioning and every "
                "requirements.storage_profile question will fail. Run 'kubectl get storageclass' to inspect it, "
                "or 'clusterdrill local destroy && clusterdrill local init' to recreate the default profile."
            )
        else:
            provisioner = storage_class.get("provisioner", "unknown")
            active_storage_profile = PROVISIONER_TO_STORAGE_PROFILE.get(provisioner)
            print(f"Default StorageClass: {storage_class['metadata']['name']}")
            print(f"Storage provisioner: {provisioner}")
            print(f"Storage profile: {active_storage_profile or 'unknown'}")
            print(f"Volume binding mode: {storage_class.get('volumeBindingMode') or 'Immediate'}")
            print(f"Reclaim policy: {storage_class.get('reclaimPolicy', 'unavailable')}")
            print(f"Volume expansion: {'supported' if storage_class.get('allowVolumeExpansion') else 'not supported'}")
        # Informational, not an issue/exit-1 condition - like the "Question
        # bank: N excluded" line below, a storage-profile mismatch means
        # some questions aren't available under this profile, not that the
        # appliance itself is broken.
        exclusion_message = storage_profile_exclusion_message(active_storage_profile)
        if exclusion_message:
            print(exclusion_message)
        print(f"kubectl server version: {kubectl_server_version() or 'unavailable'}")
        issues.extend(check_install_permissions())
    else:
        print("Run 'clusterdrill local init' to create the isolated profile.")

    report = question_bank_report()
    if report is not None:
        excluded, incomplete = report
        print(
            f"Question bank: {excluded} excluded (need more than {REQUIRED_NODE_COUNT} node(s)), "
            f"{incomplete} incomplete (missing QUESTION.md or check.sh)"
        )

    if issues:
        print("\nProblems:")
        for issue in issues:
            print(f"- {issue}")
        return 1
    print("\nLocal appliance prerequisites are ready.")
    return 0


def local_bootstrap(args: argparse.Namespace) -> int:
    if shutil.which("minikube"):
        print("Minikube is already installed; no bootstrap action is needed.")
        return 0
    if not args.install_prerequisites:
        raise CommandError("Minikube is absent. Re-run with --install-prerequisites to acknowledge installation.")
    if platform.system() != "Darwin":
        raise CommandError("Automatic Minikube installation is currently implemented only for macOS. See https://minikube.sigs.k8s.io/docs/start/ for Ubuntu.")
    if not docker_healthy():
        raise CommandError("Docker is unavailable or unhealthy. Install/start Docker first; ClusterDrill will not modify it.")
    if shutil.which("brew") is None:
        raise CommandError("Homebrew is required for the macOS installer. Install Minikube manually from https://minikube.sigs.k8s.io/docs/start/.")
    run(["brew", "install", "minikube"])
    require_binary("minikube")
    run(["minikube", "version"])
    print("Minikube installed and verified.")
    return 0


def local_init(args: argparse.Namespace) -> int:
    require_binary("minikube")
    require_binary("docker")
    require_binary("kubectl")
    if not docker_healthy():
        raise CommandError("Docker is unavailable or unhealthy. Start Docker first; ClusterDrill will not modify it.")
    storage_profile = args.storage_profile or DEFAULT_STORAGE_PROFILE
    recommended_cpus, recommended_memory_gib = docker_capacity()
    cpus = args.cpus if args.cpus is not None else recommended_cpus
    memory = args.memory if args.memory is not None else f"{recommended_memory_gib}g"
    previous_context = run(["kubectl", "config", "current-context"], capture=True, check=False).stdout.strip()
    command = [
        "minikube", "start", "--profile", PROFILE, "--driver", "docker",
        f"--cpus={cpus}", f"--memory={memory}",
    ]
    run(command)
    if not profile_running():
        raise CommandError(f"Minikube reported success but profile '{PROFILE}' is not running.")
    # A cluster-creation-time choice, not a
    # live toggle - switching profile on an existing appliance means
    # destroy + init again, matching how --cpus/--memory are also only
    # adjustable at (re-)creation.
    if storage_profile == "local-path":
        apply_local_path_provisioner()
    # `minikube start` selects its context as a side effect. Put the original
    # context back immediately, even though subsequent operations use --context.
    if previous_context and previous_context != PROFILE:
        run(["kubectl", "config", "use-context", previous_context], check=False)
    print(f"Profile '{PROFILE}' is ready with {cpus} CPUs and {memory} memory, storage profile '{storage_profile}'.")
    return 0


def render_manifest(image: str, password: str, version: str | None = None) -> str:
    """`version` feeds the app.kubernetes.io/version label (see
    docs/adr/0002-kubernetes-metadata-conventions.md) - defaults to the
    installed clusterdrill package version, falling back to "dev" for an
    unpublished source checkout the same way DEV_IMAGE does for the image."""
    if not MANIFEST.is_file():
        raise CommandError(f"Packaged manifest is missing: {MANIFEST}")
    if version is None:
        version = installed_version() or "dev"
    return (MANIFEST.read_text()
            .replace("${CLUSTERDRILL_IMAGE}", image)
            .replace("${CLUSTERDRILL_PASSWORD}", password)
            .replace("${CLUSTERDRILL_VERSION}", version))


def installed_password() -> str | None:
    result = run(
        ["kubectl", "--context", PROFILE, "get", "secret", "clusterdrill-web-auth", "--namespace", NAMESPACE,
         "-o", "jsonpath={.data.password}"],
        capture=True, check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return base64.b64decode(result.stdout.strip()).decode()


def remove_shared_cluster_user_rbac() -> None:
    """Remove retired shared-cluster terminal identities from this profile.

    Earlier local installs created one ServiceAccount per web user and gave
    each identity cluster-scoped RBAC permissions. That model is unsafe for
    an appliance which teaches ClusterRoleBinding creation, because any such
    identity can escalate. These names are pre-rename literals matching what
    that earlier code actually created on-cluster (not a naming choice made
    here), so removal during local installation is safe for upgraded
    profiles too regardless of this project's current naming.
    """
    profile_kubectl("delete", "namespace", "ckad-practice-system", "--ignore-not-found", "--wait=true")
    bindings = profile_kubectl("get", "clusterrolebindings", "-o", "json", capture=True)
    for item in json.loads(bindings.stdout).get("items", []):
        name = item.get("metadata", {}).get("name", "")
        if name.startswith("ckad-practice-cluster-scoped-access-"):
            profile_kubectl("delete", "clusterrolebinding", name, "--ignore-not-found")
    profile_kubectl(
        "delete", "clusterrole", "ckad-practice-cluster-scoped-access", "--ignore-not-found"
    )


def _resolve_install_image(args: argparse.Namespace) -> str:
    image = args.image
    if image is None:
        image = resolve_default_image()
        if image == DEV_IMAGE:
            print(f"No published release digest for this installed version; defaulting to the local development image {DEV_IMAGE}.")
    return image


def _has_existing_accounts() -> bool:
    result = run(
        ["kubectl", "--context", PROFILE, "get", "secret", "-n", NAMESPACE,
         "-l", USER_ACCOUNT_LABEL_SELECTOR, "-o", "name"],
        capture=True, check=False,
    )
    return result.returncode == 0 and bool(result.stdout.strip())


def _resolve_install_password(args: argparse.Namespace) -> tuple[str, bool]:
    """Returns (password, is_login_password).

    is_login_password is False only in the drift case this handles: the
    login Secret is missing (existing_password is None) but at least one
    account already exists. web/users.py's ensure_bootstrap_admin() only
    ever seeds a password when zero accounts exist - once an account is
    there, it never rehashes an existing account's password from this
    Secret (a Secret anyone with cluster access could otherwise edit and
    restart the pod to silently take over an account). A freshly generated
    value in that state gets written to the Secret (keeping the password
    gate itself enabled) but is not, and will never become, any account's
    real login password - the caller must not print it as one.
    """
    existing_password = installed_password()
    if not args.no_password and existing_password and args.password and args.password != existing_password:
        raise CommandError("The appliance already has a login password. Refusing to change it because existing accounts retain their current password hash.")
    if args.no_password:
        return "", True
    if existing_password:
        return existing_password, True
    password = args.password or secrets.token_urlsafe(24)
    return password, not _has_existing_accounts()


def _print_install_password_result(args: argparse.Namespace, password: str, password_is_usable: bool) -> None:
    if args.no_password:
        print("Password gate: disabled")
    elif password_is_usable:
        print(f"Local login password: {password}")
    else:
        print(
            "This appliance already has account(s), but its login Secret was "
            "missing or out of sync - a new value was written to keep the "
            "password gate enabled, but it was NOT applied to any existing "
            "account (an account's password is only ever changed by logging "
            "in and using it, never silently overwritten by reinstall). Log "
            "in with an existing account's own password."
        )


def local_install(args: argparse.Namespace) -> int:
    require_binary("kubectl")
    require_binary("minikube")
    if not profile_running():
        raise CommandError(f"Profile '{PROFILE}' is not running. Run 'clusterdrill local init' first.")
    remove_shared_cluster_user_rbac()
    if args.installer == "helm":
        return local_install_helm(args)
    image = _resolve_install_image(args)
    if "@sha256:" not in image and not image.startswith("clusterdrill:"):
        raise CommandError("Refusing a mutable release image. Supply an image pinned with @sha256:, or use a clusterdrill:<tag> development image.")
    password, password_is_usable = _resolve_install_password(args)
    manifest = render_manifest(image, password)
    # apply needs stdin, so use a direct subprocess with the same explicit context.
    proc = subprocess.run(["kubectl", "--context", PROFILE, "apply", "-f", "-"], input=manifest, text=True)
    if proc.returncode:
        raise CommandError("Could not apply the ClusterDrill appliance manifest.")
    # Environment values sourced from the password Secret are read only at
    # container start. Restart so `--no-password` and a first generated
    # password take effect immediately, rather than leaving a stale pod.
    profile_kubectl("rollout", "restart", f"deployment/{DEPLOYMENT}", "--namespace", NAMESPACE)
    profile_kubectl("rollout", "status", f"deployment/{DEPLOYMENT}", "--namespace", NAMESPACE, "--timeout", args.timeout)
    print(f"Installed {image} into {NAMESPACE} on profile '{PROFILE}'.")
    _print_install_password_result(args, password, password_is_usable)
    return 0


def local_install_helm(args: argparse.Namespace) -> int:
    """The optional Helm install path - same preflight, image resolution,
    and password rules as local_install above, but hands the rendered
    resources to `helm upgrade --install` against helm/clusterdrill-chart/
    instead of a direct `kubectl apply`.

    The chart never creates the namespace or the password Secret itself
    (see that directory's own README) - upsert both via kubectl first,
    exactly the same upsert semantics `kubectl apply` already gives the
    raw-manifest path, before Helm ever runs. A namespace the chart's own
    templates *didn't* also try to manage is deliberate: Helm refuses to
    "adopt" a pre-existing resource (like this namespace, created outside
    Helm) into a release unless it already carries Helm's own tracking
    annotations - found the hard way, via a real live install, when the
    chart's first draft did define its own Namespace template.
    """
    require_binary("helm")
    image = _resolve_install_image(args)
    if "@sha256:" not in image:
        raise CommandError(
            "--installer=helm requires an image pinned with @sha256: - a clusterdrill:dev "
            "development image isn't supported this way; use the default manifest installer instead."
        )
    repository, digest = image.split("@", 1)
    password, password_is_usable = _resolve_install_password(args)

    namespace_yaml = run(
        ["kubectl", "create", "namespace", NAMESPACE, "--dry-run=client", "-o", "yaml"], capture=True
    ).stdout
    proc = subprocess.run(["kubectl", "--context", PROFILE, "apply", "-f", "-"], input=namespace_yaml, text=True)
    if proc.returncode:
        raise CommandError(f"Could not create/update the {NAMESPACE} namespace.")
    secret_yaml = run(
        ["kubectl", "create", "secret", "generic", HELM_SECRET_NAME, "--namespace", NAMESPACE,
         f"--from-literal=password={password}", "--dry-run=client", "-o", "yaml"],
        capture=True,
    ).stdout
    proc = subprocess.run(["kubectl", "--context", PROFILE, "apply", "-f", "-"], input=secret_yaml, text=True)
    if proc.returncode:
        raise CommandError("Could not create/update the password Secret.")

    proc = subprocess.run([
        "helm", "upgrade", "--install", HELM_RELEASE_NAME, str(HELM_CHART_DIR),
        "--kube-context", PROFILE, "--namespace", NAMESPACE, "--create-namespace",
        "--set", f"image.repository={repository}",
        "--set", f"image.digest={digest}",
        "--set", f"auth.existingSecretName={HELM_SECRET_NAME}",
    ])
    if proc.returncode:
        raise CommandError("helm upgrade --install failed.")
    # Same reasoning as local_install: a password-only change needs an
    # explicit restart to actually take effect on the running Pod.
    profile_kubectl("rollout", "restart", f"deployment/{DEPLOYMENT}", "--namespace", NAMESPACE)
    profile_kubectl("rollout", "status", f"deployment/{DEPLOYMENT}", "--namespace", NAMESPACE, "--timeout", args.timeout)
    print(f"Installed {image} into {NAMESPACE} on profile '{PROFILE}' via Helm release '{HELM_RELEASE_NAME}'.")
    _print_install_password_result(args, password, password_is_usable)
    return 0


def local_url(_: argparse.Namespace) -> int:
    if not profile_running():
        raise CommandError(f"Profile '{PROFILE}' is not running. Run 'clusterdrill local init' first.")
    process, url = start_service_url()
    print(url)
    if process.poll() is None:
        print("Keeping the Minikube service tunnel open. Closing this command ends the local URL.")
        try:
            return process.wait()
        except KeyboardInterrupt:
            process.terminate()
            return 130
    return 0


def start_service_url() -> tuple[subprocess.Popen[str], str]:
    """Return a loopback-only service tunnel and retain its owning process.

    `minikube service --url` needs a NodePort service. The appliance uses
    ClusterIP so it never exposes its powerful in-cluster identity through
    the node network, therefore the CLI owns a kubectl port-forward instead.
    A leading colon asks kubectl to select a free local port.
    """
    process = subprocess.Popen(
        [
            "kubectl", "--context", PROFILE, "port-forward", "--address", "127.0.0.1",
            f"service/{SERVICE}", ":8000", "--namespace", NAMESPACE,
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    line = process.stdout.readline().strip()
    match = re.search(r"Forwarding from 127\.0\.0\.1:(\d+)", line)
    if match is None:
        stderr = process.stderr.read().strip() if process.stderr else ""
        process.wait(timeout=5)
        raise CommandError(stderr or "kubectl did not return a port-forward URL.")
    return process, f"http://127.0.0.1:{match.group(1)}"


def local_smoke_test(args: argparse.Namespace) -> int:
    import http.cookiejar
    import urllib.parse
    import urllib.request

    profile_kubectl("rollout", "status", f"deployment/{DEPLOYMENT}", "--namespace", NAMESPACE, "--timeout", args.timeout)
    tunnel, url = start_service_url()
    try:
        with urllib.request.urlopen(f"{url}/healthz", timeout=20) as response:
            if response.status != 200:
                raise CommandError(f"Health check returned HTTP {response.status}.")
        password = installed_password()
        cookies = http.cookiejar.CookieJar()
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookies))
        if password:
            login_data = urllib.parse.urlencode({"username": "admin", "password": password, "next": "/topics"}).encode()
            request = urllib.request.Request(f"{url}/login", data=login_data)
        else:
            request = urllib.request.Request(f"{url}/topics")
        with opener.open(request, timeout=20) as response:
            if response.status != 200 or b"Topics" not in response.read():
                raise CommandError("Login verification failed.")
    except OSError as exc:
        raise CommandError(f"Health check failed for {url}: {exc}") from exc
    finally:
        if tunnel.poll() is None:
            tunnel.terminate()
            tunnel.wait(timeout=5)
    print(f"Smoke test passed: {url}/healthz")
    return 0


def local_destroy(args: argparse.Namespace) -> int:
    if not args.yes:
        answer = input(f"Delete only Minikube profile '{PROFILE}'? [y/N] ").strip().lower()
        if answer not in {"y", "yes"}:
            print("Cancelled.")
            return 0
    run(["minikube", "delete", "--profile", PROFILE])
    print(f"Deleted only Minikube profile '{PROFILE}'.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="clusterdrill")
    local = parser.add_subparsers(dest="area", required=True).add_parser("local", help="manage the isolated local Minikube appliance")
    commands = local.add_subparsers(dest="command", required=True)
    doctor = commands.add_parser("doctor", help="check local prerequisites without changing anything")
    doctor.set_defaults(handler=local_doctor)
    bootstrap = commands.add_parser("bootstrap", help="install Minikube only after acknowledgement")
    bootstrap.add_argument("--install-prerequisites", action="store_true")
    bootstrap.set_defaults(handler=local_bootstrap)
    init = commands.add_parser("init", help="create or reuse only the clusterdrill Minikube profile")
    init.add_argument("--cpus", type=int, help="override the Docker-aware CPU recommendation")
    init.add_argument("--memory", help="override the Docker-aware memory recommendation, e.g. 6g")
    init.add_argument(
        "--storage-profile", choices=STORAGE_PROFILES, default=DEFAULT_STORAGE_PROFILE,
        help="storage compatibility profile - 'minikube' (default) or 'local-path' (pinned Rancher local-path-provisioner)",
    )
    init.set_defaults(handler=local_init)
    install = commands.add_parser("install", help="deploy the appliance to the clusterdrill profile")
    install.add_argument(
        "--image", default=None,
        help="image reference to deploy; defaults to the release digest paired with the "
             "installed package version, falling back to clusterdrill:dev when none is published",
    )
    password_group = install.add_mutually_exclusive_group()
    password_group.add_argument("--password", help="set the local UI password (a secure password is generated by default)")
    password_group.add_argument("--no-password", action="store_true", help="disable the password gate for a localhost-only personal drill")
    install.add_argument("--timeout", default="5m")
    install.add_argument(
        "--installer", choices=("manifests", "helm"), default="manifests",
        help="'manifests' (default) applies clusterdrill/manifests/local-appliance.yaml directly; "
             "'helm' uses the optional Helm chart instead - see helm/clusterdrill-chart/README.md",
    )
    install.set_defaults(handler=local_install)
    url = commands.add_parser("url", help="open and supervise the local service URL")
    url.set_defaults(handler=local_url)
    smoke = commands.add_parser("smoke-test", help="verify the deployed health endpoint")
    smoke.add_argument("--timeout", default="5m")
    smoke.set_defaults(handler=local_smoke_test)
    destroy = commands.add_parser("destroy", help="delete only the clusterdrill profile")
    destroy.add_argument("--yes", action="store_true", help="skip the interactive confirmation")
    destroy.set_defaults(handler=local_destroy)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.handler(args)
    except CommandError as exc:
        print(f"clusterdrill: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
