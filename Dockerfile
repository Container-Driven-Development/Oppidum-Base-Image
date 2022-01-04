ARG BASE_IMAGE_VERSION

# Based on https://github.com/gitpod-io/workspace-images/blob/master/base/Dockerfile and https://github.com/gitpod-io/workspace-images/blob/master/full/Dockerfile

FROM alpine:${BASE_IMAGE_VERSION} as FETCHER

USER root

ARG KUSTOMIZE_VERSION=v4.4.1
ARG KUSTIMIZE_HELM_PLUGIN=v0.9.2

RUN mkdir /tmp/completion

# Kustomize https://github.com/kubernetes-sigs/kustomize
RUN wget -O- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/kustomize
RUN kustomize completion zsh > /tmp/completion/_kustomize

# Khelm https://github.com/mgoltzsche/khelm
RUN mkdir -p /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer && \
    wget -O- https://github.com/mgoltzsche/helm-kustomize-plugin/releases/download/${KUSTIMIZE_HELM_PLUGIN}/helm-kustomize-plugin > /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer && \
    chmod u+x /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer

# Gosu https://github.com/tianon/gosu/blob/master/hub/Dockerfile.alpine
# TODO

ADD https://raw.githubusercontent.com/perlpunk/shell-completions/6af9f7cd5db837680aef453ca6ded1a3dd219eae/zsh/_jq /tmp/completion/_jq


RUN chmod 644 /tmp/completion/*

FROM alpine:${BASE_IMAGE_VERSION}

USER root
ARG RUN_AS_USER=gitpod
ENV LANG=en_US.UTF-8

### Packages ###
RUN apk add --no-cache \
  zsh \
  git \
  curl \
  make \
  jq \
  python3 \
  py3-pip \
  docker \
  starship \
  terraform

### PIP ###
RUN pip3 install --no-cache-dir awscli

### Gitpod user ###
RUN adduser --disabled-password --shell /bin/zsh --uid 33333 ${RUN_AS_USER}

ENV HOME=/home/gitpod
WORKDIR $HOME

COPY --from=FETCHER /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=FETCHER /tmp/completion/_kustomize /usr/share/zsh/site-functions/_kustomize
COPY --from=FETCHER /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer /home/${RUN_AS_USER}/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer
COPY --from=FETCHER /tmp/completion/_jq /usr/share/zsh/site-functions/_jq

USER gitpod

# Init zsh
COPY .zshrc /home/${RUN_AS_USER}/