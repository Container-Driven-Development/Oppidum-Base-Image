ARG FETCHER_IMAGE_VERSION
ARG BASE_IMAGE_VERSION

# Based on https://github.com/gitpod-io/workspace-images/blob/master/base/Dockerfile and https://github.com/gitpod-io/workspace-images/blob/master/full/Dockerfile

FROM alpine:${FETCHER_IMAGE_VERSION} as FETCHER

LABEL org.opencontainers.image.source https://github.com/Container-Driven-Development/Oppidum-DevOps-Blueprint

RUN apk --no-cache add unzip

USER root

ENV KUSTOMIZE_VERSION=v4.4.1
ENV KUSTIMIZE_HELM_PLUGIN=v0.9.2
ENV STARSHIP_VERSION=v1.1.1
ENV DOCKER_VERSION=20.10.9
ENV TERRAFORM_VERSION=1.1.2

RUN mkdir /tmp/completion

# Kustomize https://github.com/kubernetes-sigs/kustomize
RUN wget -O- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/kustomize
RUN kustomize completion zsh > /tmp/completion/_kustomize

# Khelm https://github.com/mgoltzsche/khelm
RUN mkdir -p /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer && \
  wget -O- https://github.com/mgoltzsche/helm-kustomize-plugin/releases/download/${KUSTIMIZE_HELM_PLUGIN}/helm-kustomize-plugin > /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer && \
  chmod u+x /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer

ADD https://raw.githubusercontent.com/perlpunk/shell-completions/6af9f7cd5db837680aef453ca6ded1a3dd219eae/zsh/_jq /tmp/completion/_jq

# Starship https://github.com/starship/starship
RUN wget -O- https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/starship

# Terrraform https://github.com/starship/starship
RUN wget -O- https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/starship

# Docker https://github.com/moby/moby
RUN wget -O- https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/docker

# Terraform https://github.com/hashicorp/terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /tmp
RUN chmod +x /tmp/terraform

# AWS CLI
RUN wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
RUN unzip awscli-exe-linux-x86_64.zip -d /tmp
RUN /tmp/aws/install --bin-dir /tmp/aws-cli-bin

RUN chmod 644 /tmp/completion/*

################################################
FROM gitpod/workspace-base:${BASE_IMAGE_VERSION}

ENV RUN_AS_USER=gitpod
ENV SHELL=zsh

USER root

## Packages ###
RUN apt-get update && apt-get install -y \
  python3-pip \
  docker.io \
  && rm -rf /var/lib/apt/lists/*

### PIP ###
RUN pip3 install --no-cache-dir awscli

COPY --from=FETCHER /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=FETCHER /tmp/completion/_kustomize /usr/share/zsh/site-functions/_kustomize
COPY --from=FETCHER /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer /home/${RUN_AS_USER}/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer
COPY --from=FETCHER /tmp/completion/_jq /usr/share/zsh/site-functions/_jq
COPY --from=FETCHER /usr/local/bin/starship /usr/local/bin/starship
COPY --from=FETCHER /usr/local/bin/docker/docker /usr/local/bin/docker
COPY --from=FETCHER /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=FETCHER /tmp/aws-cli-bin/ /usr/local/bin/
COPY --from=FETCHER /tmp/terraform /usr/local/bin/

RUN chsh -s /usr/bin/zsh ${RUN_AS_USER}

USER gitpod

# Init zsh
COPY .zshrc /home/${RUN_AS_USER}/
