# syntax=docker/dockerfile:1
# Digest-pinned multi-arch index (not a single-platform manifest digest) -
# resolves to python:3.12-slim as of this pin, but immune to the upstream
# tag being silently repointed at a different image later (I02/R15).
FROM python:3.12-slim@sha256:a6e34c598f2467ed0e9a8d349809fcd8b5c603269512df273a0bb1784edc11b1

# Debian's default /bin/sh (dash) doesn't support -o pipefail, so a piped
# RUN command's exit code is only ever the last command's - a failed `curl`
# upstream of `sha256sum -c` below would silently report success. bash
# ships in this base image already; pipefail here makes every checksum
# verification below actually fail closed on a broken pipe, not just a
# failed check (hadolint DL4006).
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETARCH
ARG KUBECTL_VERSION=v1.33.13
ARG TTYD_VERSION=1.7.7
ARG HELM_VERSION=v4.3.0

# Every downloaded binary/tarball below is verified against its upstream-
# published checksum before being trusted (I02/R15) - a plain --fail only
# protects against an HTTP error, not a compromised CDN or a MITM silently
# substituting a different artifact for the one actually reviewed/pinned
# by {KUBECTL,TTYD,HELM}_VERSION above.
#
# apt-get upgrade (not just install): pulls whatever Debian has already
# shipped to trixie-security for the base image's own packages as of build
# time, rather than only ever getting OS security fixes on the next full
# python:3.12-slim tag/digest bump (R15 - a fresh scan of this image before
# this line showed ~123 of its 157 high findings were base-OS packages, not
# anything this project's own code pulls in).
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl nano vim tmux jq \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --output /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && curl --fail --location --output /tmp/kubectl.sha256 \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256" \
    && echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/kubectl \
    && rm -f /tmp/kubectl.sha256 \
    && case "$TARGETARCH" in amd64) ttyd_arch=x86_64 ;; arm64) ttyd_arch=aarch64 ;; *) exit 1 ;; esac \
    && curl --fail --location --output /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ttyd_arch}" \
    && curl --fail --location --output /tmp/ttyd.sha256sums \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/SHA256SUMS" \
    && grep -E "  ttyd\.${ttyd_arch}\$" /tmp/ttyd.sha256sums | awk '{print $1 "  /usr/local/bin/ttyd"}' | sha256sum -c - \
    && chmod 0755 /usr/local/bin/ttyd \
    && rm -f /tmp/ttyd.sha256sums \
    && helm_tarball="helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && curl --fail --location --output "/tmp/${helm_tarball}" \
      "https://get.helm.sh/${helm_tarball}" \
    && curl --fail --location --output "/tmp/${helm_tarball}.sha256sum" \
      "https://get.helm.sh/${helm_tarball}.sha256sum" \
    && awk '{print $1 "  /tmp/'"${helm_tarball}"'"}' "/tmp/${helm_tarball}.sha256sum" | sha256sum -c - \
    && tar -xzf "/tmp/${helm_tarball}" -C /tmp \
    && mv "/tmp/linux-${TARGETARCH}/helm" /usr/local/bin/helm \
    && chmod 0755 /usr/local/bin/helm \
    && rm -rf "/tmp/${helm_tarball}" "/tmp/${helm_tarball}.sha256sum" "/tmp/linux-${TARGETARCH}"

RUN useradd --create-home --uid 10001 --shell /bin/bash clusterdrill
WORKDIR /opt/clusterdrill
COPY web/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY --chown=clusterdrill:clusterdrill lib ./lib
COPY --chown=clusterdrill:clusterdrill questions ./questions
COPY --chown=clusterdrill:clusterdrill web ./web
COPY --chown=clusterdrill:clusterdrill deploy/entrypoint.sh /usr/local/bin/clusterdrill-entrypoint
COPY deploy/bin/k /usr/local/bin/k
COPY deploy/clusterdrill-aliases.sh /etc/profile.d/clusterdrill-aliases.sh
COPY deploy/vimrc.local /etc/vim/vimrc.local
RUN chmod 0755 /usr/local/bin/clusterdrill-entrypoint \
    && chmod 0755 /usr/local/bin/k \
    && chmod 0644 /etc/profile.d/clusterdrill-aliases.sh \
    && chmod 0644 /etc/vim/vimrc.local \
    && find web -type d -name __pycache__ -prune -exec rm -rf {} + \
    && find lib -name '*.sh' -exec chmod 0755 {} + \
    && find questions -name '*.sh' -exec chmod 0755 {} +

ENV HOME=/home/clusterdrill \
    PYTHONUNBUFFERED=1
USER 10001:10001
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/clusterdrill-entrypoint"]
