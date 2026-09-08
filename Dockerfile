# syntax=docker/dockerfile:1
FROM python:3.12-slim

ARG TARGETARCH
ARG KUBECTL_VERSION=v1.33.9
ARG TTYD_VERSION=1.7.7

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl nano vim tmux \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --output /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && chmod 0755 /usr/local/bin/kubectl \
    && case "$TARGETARCH" in amd64) ttyd_arch=x86_64 ;; arm64) ttyd_arch=aarch64 ;; *) exit 1 ;; esac \
    && curl --fail --location --output /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ttyd_arch}" \
    && chmod 0755 /usr/local/bin/ttyd

RUN useradd --create-home --uid 10001 --shell /bin/bash clusterdrill
WORKDIR /opt/clusterdrill
COPY web/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY --chown=clusterdrill:clusterdrill lib ./lib
COPY --chown=clusterdrill:clusterdrill questions ./questions
COPY --chown=clusterdrill:clusterdrill web ./web
COPY --chown=clusterdrill:clusterdrill deploy/entrypoint.sh /usr/local/bin/clusterdrill-entrypoint
COPY deploy/clusterdrill-aliases.sh /etc/profile.d/clusterdrill-aliases.sh
RUN chmod 0755 /usr/local/bin/clusterdrill-entrypoint \
    && chmod 0644 /etc/profile.d/clusterdrill-aliases.sh \
    && find web -type d -name __pycache__ -prune -exec rm -rf {} + \
    && find lib -name '*.sh' -exec chmod 0755 {} + \
    && find questions -name '*.sh' -exec chmod 0755 {} +

ENV HOME=/home/clusterdrill \
    PYTHONUNBUFFERED=1
USER 10001:10001
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/clusterdrill-entrypoint"]
