ARG BASE_IMAGE_VERSION

FROM alpine:${BASE_IMAGE_VERSION} as FETCHER

USER root

ARG KUSTOMIZE_VERSION=v4.4.1
ARG KUSTIMIZE_HELM_PLUGIN=v0.9.2

# Kustomize https://github.com/kubernetes-sigs/kustomize
RUN wget -O- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/kustomize

# Khelm https://github.com/mgoltzsche/khelm
RUN mkdir -p /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer && \
    wget -O- https://github.com/mgoltzsche/helm-kustomize-plugin/releases/download/${KUSTIMIZE_HELM_PLUGIN}/helm-kustomize-plugin > /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer && \
    chmod u+x /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer

# Gosu https://github.com/tianon/gosu/blob/master/hub/Dockerfile.alpine
# TODO

FROM alpine:${BASE_IMAGE_VERSION}

USER root
ARG RUN_AS_USER=gitpod

### Git ###
RUN apk add --no-cache \
  zsh \
  git \
  docker \
  starship

### Gitpod user ###
RUN adduser --disabled-password --shell /bin/zsh --uid 33333 ${RUN_AS_USER}

ENV HOME=/home/gitpod
WORKDIR $HOME

COPY --from=FETCHER /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=FETCHER /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer /home/${RUN_AS_USER}/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer

USER gitpod

# Init zsh
RUN echo 'eval "$(starship init zsh)"' > .zshrc